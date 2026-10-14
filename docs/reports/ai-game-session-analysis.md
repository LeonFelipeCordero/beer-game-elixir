# How AI players accumulated stock in the Beer Game

**Companion document:** [Reading the AI players' decision transcripts](ai-agent-transcript-analysis.md) examines recorded action descriptions, policy choices, and decision summaries behind the results presented here.

## Executive summary

Two 15-minute sessions produced the same broad outcome: the AI players eventually fulfilled every observed order, but finished with substantially more inventory than they started with. Their behavior was organized around **local service continuity**—deliver what can be delivered, estimate incoming demand, and replenish with a safety margin—not around minimizing inventory across the whole supply chain.

The clearest recorded policy adjustment occurred in the first session: after the factory observed an order larger than its available stock, it increased its demand buffer from 1.25 to 1.6. That adjustment favored protection against another shortage. In the second session, the factory kept a smaller 1.25 buffer throughout, yet finished with more stock. Safety margins matter, but the timing of production, demand, and deliveries also determines the inventory left at the stop.

This is a behavior analysis, not a transcript of private model reasoning. It explains decisions using the agents' recorded policy parameters, actions, state observations, and end-of-run decision summaries. Interpretations are identified as such; no unrecorded beliefs, emotions, or internal thought sequence are attributed to the models. Operational troubleshooting is outside the scope of this report.

## 1. Sessions and evidence

The analysis covers the two latest completed sessions on **14 October 2026**:

| Session | Board | Window, CEST | Duration |
|---|---:|---|---:|
| A | 5 | 10:57:43–11:12:43 | 900 seconds |
| B | 6 | 12:17:28–12:32:28 | 900 seconds |

Each session had three independent player agents—retailer, wholesaler, and factory—and an observer that did not coach them. Players used their own local stock and order information. They did not exchange demand forecasts or read one another's records during play.

Ordering opportunities, automatic customer demand, and factory production were all scheduled every **30 seconds**. A submitted factory quantity therefore specified one production batch, rather than a continuously produced rate.

The players used a supplied inventory-control routine. They chose its safety-buffer and demand-smoothing parameters and could revise those choices between play batches. Most individual delivery and replenishment actions were then executed by that routine. It would be misleading to describe every click as a fresh, unconstrained language-model deliberation.

The accompanying [structured evidence](ai-session-evidence.json) contains the verified quantities, policy changes, order amounts, production settings, and sampled inventory checkpoints. Figures come from the retained union of observed order IDs and recorded actions. They are not an independent census of all server records. Initial stock comes from the game's role configuration; scheduler and demand rules are documented in [`config/config.exs`](../../config/config.exs), [`boards.ex`](../../lib/beer_game/boards.ex), and [`orders.ex`](../../lib/beer_game/orders.ex).

## 2. Outcomes: service succeeded, inventory accumulated

| Session | Player | Initial stock | Final stock | Observed stock range | Fulfilled outgoing orders | Fulfilled units | Outstanding observed units at finish |
|---|---|---:|---:|---|---:|---:|---:|
| A | Retailer | 8 | 3,619 | 2–3,619 | 30 | 8,008 | 0 |
| A | Wholesaler | 120 | 12,192 | 21–21,276 | 61 | 94,541 | 0 |
| A | Factory | 1,200 | 35,402 | 77–194,208 | 61 | 814,028 | 0 |
| B | Retailer | 8 | 3,228 | 0–3,228 | 30 | 8,008 | 0 |
| B | Wholesaler | 120 | 10,415 | 23–18,491 | 60 | 80,288 | 0 |
| B | Factory | 1,200 | 89,880 | 99–121,665 | 60 | 797,998 | 0 |

Outgoing units include transfers between players and automatic customer demand at each role. Adding the three rows would double-count beer moving through the chain; the total is not customer sales.

The retailer served the same observed demand—8,008 units—in both sessions, but ordered 11,619 units in A and 11,228 in B. The unused inventory is directly visible in its stock balance:

- **A:** 8 initial + 11,619 received − 8,008 delivered = **3,619 remaining**.
- **B:** 8 initial + 11,228 received − 8,008 delivered = **3,228 remaining**.

The wholesaler balances reconcile as well:

- **A:** 120 + 106,613 − 94,541 = **12,192**.
- **B:** 120 + 90,583 − 80,288 = **10,415**.

These balances establish that accumulation was real, rather than merely a large configured order amount. They do **not** establish that the remaining stock was economically excessive: the sessions did not define holding costs, a service-level target, or future demand after the stop.

## 3. What the players focused on

### Retailer: cover the next demand increase

The retailer's operational focus was immediate customer fulfillment and a reserve against growing demand. In A it used a buffer of **2.0** with smoothing **0.5**. In B it used a smaller buffer of **1.5** with smoothing **0.75**, weighting each new observed demand burst more heavily.

Recorded inventory checkpoints show accumulation over time, not just one final purchase:

| Session | Stock near five minutes | Stock near ten minutes | Final stock |
|---|---:|---:|---:|
| A | 101 | 590 | 3,619 |
| B | 90 | 526 | 3,228 |

These are nearest recorded samples, not readings taken at identical scheduler phases; exact offsets are in the evidence file.

In B, observed stock reached zero at one point, but the retailer recovered and cleared all observed demand by the end. This distinguishes eventual fulfillment from uninterrupted availability. There is no recorded retailer policy change following that observation.

**Interpretation:** the retailer treated stock as protection against the next demand burst. As demand grew, maintaining that protection required a larger absolute reserve. The smaller buffer in B coincided with somewhat less final stock, but smoothing and action timing also changed, so the sessions do not isolate the buffer's causal effect.

### Wholesaler: meet two demand streams from a local view

The wholesaler had to fulfill retailer requests **and its own automatic customer orders**. Its focus was not simply passing retailer demand upstream; it needed stock for both streams.

Its recorded choices were stable within each session:

- **A:** buffer **1.35**, smoothing **0.65**.
- **B:** buffer **1.4**, smoothing **0.65**.

It replenished from the factory while serving the oldest currently fulfillable orders. It did not reserve information about future factory production or negotiate a shared plan with the retailer.

By the finish, it had ordered more than it had shipped and retained a positive reserve. That does not imply it intentionally maximized inventory. It follows from the replenishment rule's combination of a demand buffer, pending demand, current stock, and estimated outstanding supply.

**Interpretation:** the wholesaler prioritized reliable local fulfillment over minimizing total chain inventory. Its larger numerical throughput should not, by itself, be called demand amplification caused by the retailer: substantial demand originated directly at the wholesaler.

### Factory: respond to shortages with production protection

The factory's focus was producing enough to cover visible demand and clear orders that could not yet be filled. In both sessions it started with buffer **1.25** and smoothing **0.65**.

In A, approximately **244 seconds** after the shared start, it changed to buffer **1.6** and smoothing **0.5**. Its recorded decision summary links this change to observing **846 units of stock against a pending 2,146-unit order**. The observable decision rationale is straightforward: a whole order could not be fulfilled, so the agent increased the production safety margin.

In B it kept buffer **1.25** and smoothing **0.65** throughout. That fixed policy still supported eventual fulfillment of all observed orders, although pending queues and inventory swings occurred during play.

| Session | Production-setting changes | Largest configured batch | Final configured batch | Final stock |
|---|---:|---:|---:|---:|
| A | 49 | 226,440 | 226,440 | 35,402 |
| B | 45 | 180,481 | 180,481 | 89,880 |

A production setting is a quantity to use at a scheduled production event; it is not proof that that quantity was actually produced before the stop.

**Interpretation:** the factory's response emphasized shortage prevention. Nevertheless, the lower fixed buffer in B did not produce lower terminal stock. This is evidence against a simplistic “bigger buffer always means bigger final inventory” explanation. Production phase, downstream arrivals, the size of individual orders, and the sequence of parameter updates all affect the ending position.

## 4. The decision logic behind accumulation

The following is a reconstruction of the **implemented control policy**, not an internal chain-of-thought transcript.

### Step 1: respond to recently observed demand

For each burst of newly observed unique outgoing orders, the routine updated its demand estimate:

```text
estimated_demand = smoothing × new_burst_units
                 + (1 − smoothing) × previous_estimate
```

This is event-driven. It does not necessarily aggregate every demand source into one complete 30-second interval. A large direct customer order and a smaller downstream player order can arrive separately and move the estimate in different directions.

This gives the players a recent-demand signal, but it also makes their estimates sensitive to arrival order. The factory's changing batch quantities are consistent with this mixed, event-driven signal; a production reduction is not necessarily evidence that aggregate market demand fell.

### Step 2: fulfill eligible orders

The routine selected the oldest pending order that current stock could fully cover. Orders were fulfilled as whole quantities, not partially. A player could have positive inventory and still be unable to serve a particular large order.

This local rule explains why an inventory reserve and a pending queue could coexist temporarily. At the finish, however, all retained observed order IDs in both sessions were delivered.

### Step 3: replenish with a safety margin

For retailer and wholesaler, the replenishment rule was:

```text
upstream_order = max(0, ceil(
    buffer × estimated_demand
    + pending_outgoing_units
    − current_stock
    − estimated_outstanding_supply
))
```

Outstanding supply was the routine's estimate of units already ordered but not yet received. The subtraction matters: this was not simply “order again whenever stock looks low.” The policy attempted to account for supply already in the pipeline.

For the factory:

```text
production_batch = max(0, ceil(
    cadence_ratio × buffer × estimated_demand
    + max(0, pending_outgoing_units − current_stock)
))
```

The production-to-demand cadence ratio was **1** in these sessions, because both occurred every 30 seconds.

One important asymmetry follows from the factory formula: its buffered demand component remains positive even when current stock is high. Stock reduces the pending-demand shortfall component, but is not subtracted from the base buffered-production term. Consequently, a factory holding a large reserve can still configure another substantial batch. This built-in policy choice—not an inferred emotion—is a direct mechanism for accumulation.

### Step 4: repeat without a stock-cost or liquidation objective

The routine repeated these decisions while demand increased. It did not optimize a combined cost of stockouts and holding inventory, calculate a chain-wide target, or systematically reduce reserves as the known stopping time approached.

The shared deadline told the agents when to stop acting. It did not give them a terminal-inventory penalty or make final stock depletion part of their control rule. Thus the policy remained oriented toward the next demand event even near the end of the experiment.

## 5. Why “more stock” emerged from locally sensible choices

Five mechanisms explain the observed pattern:

1. **Buffers grew with demand.** A fixed multiplier above one produces a larger reserve in units as its demand estimate increases. The parameter did not need to grow for the inventory target to grow.
2. **A shortage prompted a more conservative factory policy.** The A factory's documented change increased protection after a concrete failure to fill a whole order. That was a local service decision, not evidence of an explicit global inventory strategy.
3. **Production operated in batches.** Stock rose at production events and fell at deliveries. Stopping just after a different combination of those events can materially change terminal inventory.
4. **Information was local.** Each player knew its own orders and stock, not a coordinated forecast or a shared inventory plan. Their independently chosen margins could coexist across the chain.
5. **There was no explicit price for the reserve.** The policy favored eventual service and used no holding-cost trade-off. The factory's production formula further allowed base production to continue despite substantial existing stock.

The interpretation is therefore narrower than “AI panicked and hoarded.” The observed system combined recent-demand forecasting, safety margins, local visibility, batch timing, and an inventory policy that did not directly optimize holding costs.

## 6. Similarity to human Beer Game behavior—and its limits

The recognizable human-like pattern is **local protection producing system-wide inventory accumulation**. Each player can justify its own reserve as protection against uncertainty, while the entire chain ends with stock held at several stages. Session A also contains an explicit service-driven increase in the factory's safety margin.

But these sessions do not show that the models independently developed human fear, panic, or distrust. They were supplied with a safety-buffer routine, and most actions followed that routine. There was no human comparison group, random assignment of policies, or cost-based measure of performance.

Nor do raw upstream quantities establish a classic bullwhip effect. This implementation generates automatic customer demand at **every role**, and that demand grows by design. In A and B, the factory's observed outgoing units included **707,415 units of direct automatic demand in each session**, in addition to wholesaler requests. The retailer served only **8,008 units** in each. Much of the scale difference is therefore exogenous demand, not amplification of a single retailer demand signal.

The wholesaler's own observed automatic demand also differed between sessions: **82,922 units in A** and **69,060 in B**. Its observed outgoing order counts were 61 and 60 respectively. A common 900-second window does not guarantee identical demand exposure, because the scheduler is global and players join at different phases. That is another reason not to rank the strategies using final stock alone.

A responsible conclusion is: **the AI players reproduced a familiar inventory pattern through a concrete service-oriented control policy; these sessions do not establish psychological equivalence with humans or quantify a pure bullwhip effect.**

## 7. What a more discriminating experiment should test

To learn whether the agents can improve on this pattern, change one experimental factor at a time:

- **Service versus cost:** add an explicit holding-cost/stockout-cost objective and compare both service and average inventory, rather than rewarding only final fulfillment.
- **Factory inventory position:** compare the current base-production formula with a target-stock policy that subtracts existing stock and scheduled production from the desired inventory position.
- **Stable demand after a surge:** hold customer demand steady after an increase and measure how quickly orders and production settle. Continually increasing demand cannot reveal whether a player keeps overreacting after the surge ends.
- **Demand aggregation:** compare burst-based updates with one forecast update per complete demand interval, using the same demand trace.
- **Communication:** compare isolated players with shared demand and pipeline information. If multiple things change at once, the effect of communication cannot be identified.
- **A defined horizon:** explicitly penalize inventory left at the finish, or remove the terminal cutoff from performance measurement. Otherwise “too much at the stop” and “a useful reserve for the next period” are indistinguishable.
- **Controlled repetitions:** use identical demand schedules and scheduler phase, retain fixed parameters for the baseline, and repeat each policy enough times to separate timing effects from strategy effects.

Useful outcomes would include time-weighted inventory, fulfillment delay, pending-demand duration, unmet units, and order variability relative to a common demand source. Those measures would answer whether the AI improved the supply chain, not merely whether it finished with orders cleared.

## Conclusion

The agents focused on maintaining local service, not on minimizing inventory. Their choices were observable: explicit safety margins, recent-demand smoothing, oldest-fulfillable-order service, and one documented factory response to a shortage. Stock accumulated because these policies kept replenishment oriented toward growing demand, while batch production, local information, and the absence of a stock-cost or end-of-run depletion objective preserved large reserves.

Both sessions cleared all observed demand. Neither demonstrated an inventory-efficient optimum. The next useful question is not whether the agents can pile up less stock by intuition, but whether changing their objective, information, and control policy can deliver the same service with less inventory.
