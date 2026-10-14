# AI player decisions: what the records show

Most players kept a buffered service policy unchanged. Factory A made the clearest recorded adjustment: shortage observed, reserve raised. The records support that account—not a story about panic or deliberate hoarding.

[Results and policy formulas](ai-game-session-analysis.md) · [Transcript evidence](ai-transcript-evidence.json)

## Evidence limits

Six player transcripts cover runs A (board 5) and B (board 6), completed on 14 October 2026. Sources: public action labels, tool arguments, returned observations, and post-game summaries. The observer checked outcomes, not motives.

Most records are browser actions and results, not decision explanations. Only three players left nonempty final responses; streamed public prose repeated final responses rather than adding in-play rationale.

Read evidence as **statements** (what players said), **choices** (parameters executed), or **interpretation** (our explanation). No private reasoning reconstructed. Quotes below are verbatim public labels or post-game statements. Times are rounded from the shared start; action times mark invocation, not completion. Troubleshooting excluded.

## Retailer: keep the reserve

| Run | Buffer / smoothing, unchanged | Selected public action labels |
|---|---|---|
| A | 2.0 / 0.5 | 7:43: “Continuing retailer service without changing policy”; 8:34: “Maintaining retailer stock as demand grows”; 11:07: “Serving retailer demand in the final minutes” |
| B | 1.5 / 0.75 | 1:49: “Maintain the retailer inventory buffer”; 6:56: “Respond to rising retailer demand” |

Neither retailer explained its initial parameter values in a final response.

**Interpretation:** reserve maintenance, not repeated strategy changes. Rising demand made the routine order more even with a fixed buffer. Late labels still emphasized service, but do not prove the player considered and rejected stock liquidation.

Both cleared observed demand and finished with large reserves; see [results](ai-game-session-analysis.md#results).

## Wholesaler: serve orders, account for incoming supply

| Run | Buffer / smoothing, unchanged | Selected public action labels |
|---|---|---|
| A | 1.35 / 0.65 | 4:18: “Continue replenishment and oldest-order service”; 5:59: “Maintain supply against rising visible demand”; 11:54: “Process visible demand without duplicate ordering” |
| B | 1.4 / 0.65 | 0:06: “Serve demand with a moderate reserve”; 5:12: “Serve pending demand as supply arrives”; 11:11: “Continue wholesaler inventory balancing” |

A's post-game summary:

> “Served oldest enabled pending orders first, and replenished using demand estimate, stock, pending demand, and outstanding supply.”

**Interpretation:** local fulfillment with a reserve, accounting for supply already ordered. “Moderate” describes intent, not measured cost efficiency. Neither run changed parameters or documented a shared stock target or holding-cost comparison.

## Factory A: shortage → larger buffer

| Elapsed | Recorded event |
|---|---|
| 3:07 | “Serve factory demand and inspect current inventory”; buffer 1.25, smoothing 0.65 |
| ~3:53 | Returned state: 846 stock units; order #962 required 2,146; delivery unavailable |
| 4:04 | “Increase reserve for observed factory stock shortage”; buffer changed to 1.6, smoothing to 0.5 |
| 8:31 | “Continue successful reserve policy at factory”; revised parameters retained through finish |

Post-game statement:

> “An earlier stock shortage prompted a higher reserve policy.”

The label, parameter change, and final statement agree: protection increased after an unfillable order. Lower smoothing also reduced each new burst's weight, so the buffer's effect cannot be isolated.

“Successful” was the player's assessment, not proof of optimal inventory. All observed orders cleared, but substantial stock remained. No evidence supports a psychological explanation such as fear or panic.

## Factory B: new quantities, same policy

Buffer **1.25**, smoothing **0.65** throughout. Labels included “Adjust factory production to observed demand” at 4:23 and “Continue factory deliveries with demand smoothing” at 11:13.

Post-game statements:

> “The fixed buffer maintained eventual fulfillment of all observed orders but did not eliminate temporary shortages or large inventory swings.”

> “Temporary pending demand peaked at 68,516 units in snapshots; this was not a shortage-free run.”

Production quantities changed through the routine; safety parameters did not. The final response acknowledged temporary shortages, but no in-play cost objective or policy revision was recorded.

## Takeaway

The visible pattern: observe local state, run the chosen policy, check results; factory A revised it after a shortage. Models selected parameters; the routine made most individual delivery and ordering decisions.

Reserve and service language supports the [stock-accumulation explanation](ai-game-session-analysis.md#why-stock-grew). None of the six gameplay traces documents a holding-cost comparison, shared stock-minimization plan, or pre-finish stock reduction. That means **not documented**, not proof of what players privately considered.

Factory B kept the smaller buffer yet ended with more stock than A. Final inventory alone cannot reveal intent; policy mechanics, demand exposure, and batch timing still matter.

Initial parameter motives mostly remain unknown. For future runs, request a short public summary at initialization and each policy change: relevant observation, objective, action, trade-off. No private chain-of-thought needed.
