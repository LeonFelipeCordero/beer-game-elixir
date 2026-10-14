"""Offline tests for the packaged game helper and supervisor.

Synthetic unit fixtures are not historical game results. No browsers, model
requests, game writes, or network calls are made by these tests.
"""
import ast
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
import collections
import datetime

PACKAGE = Path(__file__).resolve().parents[1]
HELPER = PACKAGE / 'scripts/browser_player.py'
SUPERVISOR = PACKAGE / 'scripts/run_supervisor.py'
spec = importlib.util.spec_from_file_location('beer_player', HELPER)
assert spec and spec.loader
player = importlib.util.module_from_spec(spec)
spec.loader.exec_module(player)


class Clock:
    def __init__(self): self.now = 1000.0
    def time(self): return self.now
    def sleep(self, seconds): self.now += seconds


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR'))
        self.root = Path(self.temp.name)
        self.clock = Clock()
    def tearDown(self): self.temp.cleanup()
    def window(self): return {'start': 1000.0, 'end': 1100.0}

    def test_four_ready_barrier_sets_900_seconds(self):
        for role in player.ROLES: (self.root / (role+'.ready')).write_text('ready')
        with patch.object(player.time, 'time', self.clock.time), patch.object(player.time, 'sleep', self.clock.sleep):
            window = player.wait_for_start(str(self.root))
        self.assertEqual(window['end']-window['start'], 900)
        self.assertEqual(json.loads((self.root/'window.json').read_text()), window)

    def test_quantity_readback_must_match(self):
        with patch.object(player, 'js', Mock(return_value='42'), create=True):
            player.set_quantity(42)
        with patch.object(player, 'js', Mock(return_value='4'), create=True):
            with self.assertRaisesRegex(RuntimeError, 'verification failed'): player.set_quantity(42)

    def test_deadline_prevents_game_actions(self):
        snap = Mock()
        with patch.object(player, 'wait_for_start', return_value={'start':100, 'end':1000}), patch.object(player.time, 'time', self.clock.time), patch.object(player, 'snapshot', snap), contextlib.redirect_stdout(io.StringIO()):
            done = player.run_player_batch(str(self.root), 'retailer', seconds=1)
        self.assertTrue(done)
        snap.assert_not_called()

    def test_cannot_finish_before_deadline(self):
        (self.root/'window.json').write_text(json.dumps(self.window()))
        with patch.object(player.time, 'time', self.clock.time):
            with self.assertRaisesRegex(RuntimeError, 'before deadline'):
                player.finish_agent(str(self.root), 'retailer')

    def test_factory_uses_verified_cadence_ratio(self):
        (self.root/'mechanics.json').write_text(json.dumps({'demand_seconds':30,'production_seconds':30}))
        state={'text':'Role Factory','stock':10000,'outgoing':[],'incoming':[],'amount':750,'can_order':False}
        set_qty=Mock()
        with patch.object(player, 'wait_for_start', return_value=self.window()), patch.object(player.time, 'time', self.clock.time), patch.object(player.time, 'sleep', self.clock.sleep), patch.object(player, 'snapshot', return_value=state), patch.object(player, 'set_quantity', set_qty), patch.object(player, 'js', Mock(), create=True), contextlib.redirect_stdout(io.StringIO()):
            player.run_player_batch(str(self.root), 'factory', seconds=1, buffer=1.25)
        # Preserve the historical policy: high stock does not cancel base production.
        set_qty.assert_called_once_with(750)

    def test_oldest_fulfillable_order_is_delivered_once(self):
        order={'id':2,'amount':4,'state':'PENDING','enabled':True}
        before={'text':'Role Retailer','stock':8,'outgoing':[order],'incoming':[],'amount':4,'can_order':False}
        after=dict(before,stock=4,outgoing=[dict(order,state='DELIVERED',enabled=False)])
        js_mock=Mock()
        with patch.object(player, 'wait_for_start', return_value=self.window()), patch.object(player.time, 'time', self.clock.time), patch.object(player.time, 'sleep', self.clock.sleep), patch.object(player, 'snapshot', side_effect=[before,after]), patch.object(player, 'js', js_mock, create=True), contextlib.redirect_stdout(io.StringIO()):
            player.run_player_batch(str(self.root), 'retailer', seconds=1)
        self.assertEqual(js_mock.call_count,1)
        events=[json.loads(l) for l in (self.root/'retailer.jsonl').read_text().splitlines()]
        deliveries=[e for e in events if e['kind']=='delivery']
        self.assertEqual(len(deliveries),1)
        self.assertTrue(deliveries[0]['verified'])

    def test_aggregate_keeps_delivered_over_stale_pending(self):
        # Load only pure function declarations; do not run the supervisor CLI.
        tree=ast.parse(SUPERVISOR.read_text())
        functions=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[])
        env={'ROOT':self.root,'ROLES':list(player.ROLES),'BOARD':'http://localhost:4000/board/123','json':json,'collections':collections,'datetime':datetime,'time':player.time}
        exec(compile(functions,str(SUPERVISOR),'exec'),env)
        (self.root/'window.json').write_text(json.dumps({'start':0,'end':900}))
        pending={'id':1,'amount':4,'state':'PENDING','enabled':True}
        for role in player.ROLES:
            events=[]
            if role!='observer':
                events=[{'kind':'snapshot','snapshot':{'stock':8,'outgoing':[pending]}}, {'kind':'delivery','order':pending,'verified':True,'stock_after':4}, {'kind':'snapshot','snapshot':{'stock':4,'outgoing':[pending]}}]
            events += [{'kind':'final','ts':900,'snapshot':{'stock':4,'outgoing':[dict(pending,state='DELIVERED')]}}, {'kind':'disconnected','verified':True}]
            (self.root/(role+'.jsonl')).write_text(''.join(json.dumps(e)+'\n' for e in events))
        with contextlib.redirect_stdout(io.StringIO()):env['aggregate']()
        data=json.loads((self.root/'aggregate.json').read_text())
        self.assertTrue(data['complete'])
        self.assertEqual(data['roles']['retailer']['fulfilled_units'],4)
        self.assertEqual(data['roles']['retailer']['pending_units'],0)

    def test_cli_help_has_no_run_side_effects(self):
        result=subprocess.run([sys.executable,str(SUPERVISOR),'--help'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('--chromium',result.stdout)
        self.assertIn('--ozone-platform',result.stdout)


if __name__=='__main__': unittest.main()
