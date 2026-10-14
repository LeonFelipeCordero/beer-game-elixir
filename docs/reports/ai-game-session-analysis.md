# AI Beer Game: orders cleared, stock grew

Two 15-minute runs cleared all observed orders but ended with large reserves. Players used a supplied service-first routine, not an inventory-cost optimizer. The clearest policy change: factory A raised its buffer after a shortage.

Lower buffer did not guarantee lower final stock. Factory B kept a smaller buffer yet finished with more stock than A. Batch timing and demand exposure matter too.

[Decision transcripts](ai-agent-transcript-analysis.md) · [Data](ai-session-evidence.json) · [Playing tools](../../skills/beer-game-elixir/README.md)

## Runs

Both completed on 14 October 2026. Three independent players per run; local stock and orders only, no shared forecasts. The observer did not coach them.

| Run | Board | Window, CEST | Duration |
|---|---:|---|---:|
| A | 5 | 10:57:43–11:12:43 | 900 seconds |
| B | 6 | 12:17:28–12:32:28 | 900 seconds |

Orders, automatic customer demand, and factory production ran every 30 seconds. Factory settings specified batches, not continuous production rates. Models chose buffer and smoothing parameters; the routine handled most deliveries and replenishment.

Figures cover retained observed order IDs and actions, not a full server census. Initial stock and game rules: [config](../../config/config.exs), [boards](../../lib/beer_game/boards.ex), [orders](../../lib/beer_game/orders.ex). This report uses recorded behavior, not private reasoning. Troubleshooting excluded.

## Results

| Run | Player | Initial stock | Final stock | Observed stock range | Orders fulfilled | Units delivered | Observed units outstanding at finish |
|---|---|---:|---:|---|---:|---:|---:|
| A | Retailer | 8 | 3,619 | 2–3,619 | 30 | 8,008 | 0 |
| A | Wholesaler | 120 | 12,192 | 21–21,276 | 61 | 94,541 | 0 |
| A | Factory | 1,200 | 35,402 | 77–194,208 | 61 | 814,028 | 0 |
| B | Retailer | 8 | 3,228 | 0–3,228 | 30 | 8,008 | 0 |
| B | Wholesaler | 120 | 10,415 | 23–18,491 | 60 | 80,288 | 0 |
| B | Factory | 1,200 | 89,880 | 99–121,665 | 60 | 797,998 | 0 |

Delivered units include player transfers and direct customer demand. Do not sum rows as customer sales: transfers would be counted twice. Orders cleared by the finish does not mean shortage-free service; retailer B hit zero stock.

Stock balances confirm accumulation:

| Run / player | Initial + received − delivered = remaining |
|---|---|
| A retailer | 8 + 11,619 − 8,008 = 3,619 |
| B retailer | 8 + 11,228 − 8,008 = 3,228 |
| A wholesaler | 120 + 106,613 − 94,541 = 12,192 |
| B wholesaler | 120 + 90,583 − 80,288 = 10,415 |

No holding cost, service target, or post-stop demand was defined. Large reserves alone do not prove waste.

## Player choices

| Player | Run A: buffer / smoothing | Run B: buffer / smoothing |
|---|---|---|
| Retailer | 2.0 / 0.5 | 1.5 / 0.75 |
| Wholesaler | 1.35 / 0.65 | 1.4 / 0.65 |
| Factory | 1.25 / 0.65 → 1.6 / 0.5 | 1.25 / 0.65 |

Only factory A changed parameters. Around 4:04, it raised its buffer after seeing 846 stock units against a 2,146-unit order. Both buffer and smoothing changed, so their effects cannot be separated.

Retailer stock grew across sampled checkpoints: **101 → 590 → 3,619** in A; **90 → 526 → 3,228** in B, near five minutes, ten minutes, and finish. Samples occurred at different scheduler phases; exact offsets are in the data.

Wholesalers served retailer requests plus their own customer demand. Their fixed policies accounted for pending orders and incoming supply, without a shared chain-wide plan.

Factory A changed its production setting 49 times; B, 45 times. Largest and final configured batches were **226,440** in A and **180,481** in B. A setting does not prove that batch ran before the stop.

## Why stock grew

The routine updated demand on each newly observed order burst:

```text
estimated_demand = smoothing × new_burst_units
                 + (1 − smoothing) × previous_estimate
```

Bursts were not complete 30-second demand totals. Separate customer and player orders could move the estimate differently depending on arrival order.

Deliveries used the oldest pending order that stock could fully cover. No partial deliveries: positive stock could coexist with an unfillable large order.

Retailer and wholesaler replenishment:

```text
upstream_order = max(0, ceil(
    buffer × estimated_demand + pending_outgoing_units
    − current_stock − estimated_outstanding_supply
))
```

Factory production:

```text
production_batch = max(0, ceil(
    cadence_ratio × buffer × estimated_demand
    + max(0, pending_outgoing_units − current_stock)
))
```

Cadence ratio was 1. **Factory stock reduced only the pending-order shortfall, not base buffered production.** A large reserve could therefore coexist with another large batch.

Fixed buffers grew in units as demand rose. Local forecasts, batch timing, and the factory formula sustained reserves. The routine had no holding-cost trade-off or rule to drain stock before the deadline.

## What this does not prove

Not evidence of panic or hoarding: most actions followed the supplied routine. No human comparison group or cost-based score.

Not a clean bullwhip test: automatic customer demand grew at every role. Factory direct demand alone was **707,415 units per run**, versus **8,008** at each retailer. Upstream volume was not solely amplified retailer demand.

Runs also had different demand exposure. Wholesaler direct demand was **82,922** in A versus **69,060** in B. Global scheduling and different join phases mean equal run lengths need not yield equal orders. Final stock alone cannot rank the policies.

## Next test

Use identical demand traces and scheduler phases; repeat runs and change one factor at a time. Compare holding/stockout costs, a factory rule that subtracts existing stock and scheduled production, interval-based forecasts, shared information, and demand held steady after a surge. Define whether final reserves carry a penalty.

Measure average inventory, fulfillment delay, pending-demand duration, unmet units, and order variability against a common demand source. Goal: same service, less stock—not merely a smaller balance at an arbitrary stop.
