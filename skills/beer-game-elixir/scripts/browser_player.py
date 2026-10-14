"""Executed inside browser_exec, which injects the browser helper names."""
import json, time, math
from pathlib import Path
from typing import Any, Callable

# Annotations only: browser_exec supplies the actual bindings at execution time.
new_tab: Callable[..., Any]
wait_for_load: Callable[..., Any]
js: Callable[..., Any]
cdp: Callable[..., Any]
goto_url: Callable[..., Any]

ROLES = ('retailer', 'wholesaler', 'factory', 'observer')

def emit(run_dir, role, event):
    event = dict(event, ts=time.time(), role=role)
    with (Path(run_dir) / (role + '.jsonl')).open('a') as f:
        f.write(json.dumps(event) + '\n')
    return event

def setup_agent(run_dir, role, board_url):
    Path(run_dir).mkdir(parents=True, exist_ok=True)
    new_tab(board_url + '/player')
    wait_for_load()
    time.sleep(2)
    if role != 'observer':
        selector = 'button[phx-value-role="' + role + '"]'
        if not js('Boolean(document.querySelector(' + json.dumps(selector) + '))'):
            raise RuntimeError('Role unavailable: ' + role)
        js('document.querySelector(' + json.dumps(selector) + ').click()')
        time.sleep(2)
        text = js('document.body.innerText')
        if 'role ' + role not in text.lower():
            raise RuntimeError('Join failed: ' + text)
    emit(run_dir, role, {'kind':'ready', 'url':js('location.href'), 'text':js('document.body.innerText')})
    (Path(run_dir)/(role+'.ready')).write_text(str(time.time()))
    print('Ready:', role)

def wait_for_start(run_dir):
    p = Path(run_dir)
    limit = time.time() + 180
    while not (p/'window.json').exists():
        if all((p/(r+'.ready')).exists() for r in ROLES):
            try:
                (p/'start.lock').mkdir()
                now = time.time() + 2
                (p/'window.json').write_text(json.dumps({'start':now, 'end':now+900}))
            except FileExistsError:
                pass
        if time.time() > limit:
            raise RuntimeError('Four-agent readiness timeout')
        time.sleep(1)
    window = json.loads((p/'window.json').read_text())
    time.sleep(max(0, window['start']-time.time()))
    return window

def snapshot():
    return js('''(() => {
      const tables = Array.from(document.querySelectorAll('table'));
      const rows = t => {
        if (!t) return [];
        const unique = new Map();
        for (const r of t.querySelectorAll('tbody tr')) {
          const c = Array.from(r.querySelectorAll('th,td')).map(x=>x.innerText.trim());
          const action = c.slice(3).join(' ').trim();
          let status = c[2].toUpperCase();
          if (!status && /^(Deliver|No Stock|Not enough stock)$/i.test(action)) status='PENDING';
          if (!status && /^Already delivered$/i.test(action)) status='DELIVERED';
          const o = {id:Number(c[0].replace('#','')), amount:Number(c[1]), state:status, action, enabled:!!r.querySelector('button[phx-click="deliver_order"]:not([disabled])')};
          const prev=unique.get(o.id);
          if (!prev || prev.state!=='DELIVERED') unique.set(o.id,o);
        }
        return Array.from(unique.values());
      };
      const modern = document.querySelectorAll('.inventory-values dd');
      const c=modern.length ? modern : tables[0]?.querySelectorAll('tbody td');
      return {url:location.href, stock:Number(c?.[0]?.innerText), last:Number(c?.[1]?.innerText), amount:Number(document.querySelector('input[name="amount"]')?.value), can_order:!!document.querySelector('form[phx-submit="create_order"] input[type="submit"]'), incoming:rows(modern.length ? tables[0] : tables[1]), outgoing:rows(modern.length ? tables[1] : tables[2]), text:document.body.innerText};
    })()''')

def set_quantity(value):
    expr='(() => {const e=document.querySelector("input[name=amount]");if(!e) throw new Error("Quantity field missing");Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,"value").set.call(e,'+json.dumps(str(value))+');e.dispatchEvent(new Event("input",{bubbles:true}));e.dispatchEvent(new Event("change",{bubbles:true}));return e.value;})()'
    observed=js(expr)
    if str(observed)!=str(value): raise RuntimeError('Quantity input verification failed')

def run_player_batch(run_dir, role, seconds=180, buffer=1.25, smoothing=0.65):
    p=Path(run_dir)
    window=wait_for_start(run_dir)
    mechanics=json.loads((p/'mechanics.json').read_text()) if (p/'mechanics.json').exists() else {'demand_seconds':60,'production_seconds':120}
    production_factor=mechanics['production_seconds']/mechanics['demand_seconds']
    statefile=p/(role+'-policy.json')
    state=json.loads(statefile.read_text()) if statefile.exists() else {'seen':[], 'demand':{'retailer':4,'wholesaler':60,'factory':600}[role], 'last_set':0, 'ordered':0, 'received':0, 'stock_prev':None, 'last_snapshot':0}
    end=min(window['end'],time.time()+seconds)
    emit(run_dir,role,{'kind':'policy','buffer':buffer,'smoothing':smoothing,'window':window})
    while time.time()<end:
        s=snapshot()
        if 'role '+role not in s['text'].lower():
            emit(run_dir,role,{'kind':'error','message':'Player page lost','snapshot':s})
            break
        s['outgoing']=list({o['id']:o for o in s['outgoing']}.values())
        new=[o for o in s['outgoing'] if o['id'] not in state['seen']]
        if new:
            # CPU orders are not labeled in the UI; treat a burst as combined demand.
            burst=sum(o['amount'] for o in new)
            state['demand']=smoothing*burst+(1-smoothing)*state['demand']
            state['seen'] += [o['id'] for o in new]
        if state['stock_prev'] is not None and s['stock']>state['stock_prev']:
            state['received']+=s['stock']-state['stock_prev']
        state['stock_prev']=s['stock']
        pending=sum(o['amount'] for o in s['outgoing'] if o['state']=='PENDING')
        if time.time()-state['last_snapshot']>=10:
            emit(run_dir,role,{'kind':'snapshot','snapshot':s,'demand_estimate':state['demand']})
            state['last_snapshot']=time.time()
        enabled=sorted([o for o in s['outgoing'] if o['state']=='PENDING' and o['enabled']], key=lambda o:o['id'])
        if enabled and time.time()<window['end']:
            o=enabled[0]
            selector='button[phx-click="deliver_order"][phx-value-order_id="'+str(o['id'])+'"]'
            js('document.querySelector('+json.dumps(selector)+')?.click()')
            time.sleep(0.4)
            after=snapshot()
            row=next((x for x in after['outgoing'] if x['id']==o['id']),None)
            ok=bool(row and row['state']=='DELIVERED')
            emit(run_dir,role,{'kind':'delivery','order':o,'verified':ok,'stock_before':s['stock'],'stock_after':after['stock']})
            if ok:
                state['received']+=max(0,after['stock']+o['amount']-s['stock'])
                state['stock_prev']=after['stock']
            s=after
        if time.time()<window['end']:
            if role=='factory' and (new or time.time()-state['last_set']>mechanics['demand_seconds']):
                target=max(0,math.ceil(production_factor*state['demand']*buffer + max(0,pending-s['stock'])))
                set_quantity(target)
                if time.time()<window['end']:
                    js('document.querySelector(\'form[phx-submit="create_order"]\').requestSubmit()')
                    time.sleep(0.4)
                    after=snapshot()
                    emit(run_dir,role,{'kind':'production_setting','amount':target,'observed':after['amount']})
                    state['last_set']=time.time()
            elif role!='factory' and s['can_order']:
                outstanding=max(0,state['ordered']-state['received'])
                target=max(0,math.ceil(state['demand']*buffer + pending - s['stock'] - outstanding))
                set_quantity(target)
                if time.time()<window['end']:
                    js('document.querySelector(\'form[phx-submit="create_order"] input[type="submit"]\')?.click()')
                    time.sleep(0.5)
                    after=snapshot()
                    ok=not after['can_order']
                    emit(run_dir,role,{'kind':'order','amount':target,'verified':ok,'outstanding_before':outstanding})
                    if ok: state['ordered']+=target
        statefile.write_text(json.dumps(state))
        time.sleep(min(2,max(0,end-time.time())))
    print(json.dumps({'role':role,'now':time.time(),'end':window['end'],'remaining':max(0,window['end']-time.time()),'state':state}))
    return time.time()>=window['end']

def run_observer_batch(run_dir, seconds=180):
    p=Path(run_dir)
    window=wait_for_start(run_dir)
    end=min(window['end'],time.time()+seconds)
    while time.time()<end:
        counts={}
        for r in ROLES[:3]:
            f=p/(r+'.jsonl')
            counts[r]=len(f.read_text().splitlines()) if f.exists() else 0
        emit(run_dir,'observer',{'kind':'observation','url':js('location.href'),'lobby':js('document.body.innerText'),'log_counts':counts})
        time.sleep(min(15,max(0,end-time.time())))
    print(json.dumps({'role':'observer','remaining':max(0,window['end']-time.time())}))
    return time.time()>=window['end']

def finish_agent(run_dir,role):
    window=json.loads((Path(run_dir)/'window.json').read_text())
    if time.time()<window['end']: raise RuntimeError('Cannot finish before deadline')
    final=snapshot() if role!='observer' else {'text':js('document.body.innerText'),'url':js('location.href')}
    emit(run_dir,role,{'kind':'final','snapshot':final,'window':window})
    import base64
    screenshot=Path(run_dir)/(role+'-final.png')
    try:
        data=cdp('Page.captureScreenshot',format='png')['data']
        screenshot.write_bytes(base64.b64decode(data))
    except Exception as exc:
        emit(run_dir,role,{'kind':'screenshot_error','message':str(exc)})
        screenshot=None
    goto_url('about:blank')
    disconnected=js('location.href')=='about:blank'
    emit(run_dir,role,{'kind':'disconnected','verified':disconnected})
    print(json.dumps({'role':role,'final':final,'disconnected':disconnected,'screenshot':str(screenshot)}))
