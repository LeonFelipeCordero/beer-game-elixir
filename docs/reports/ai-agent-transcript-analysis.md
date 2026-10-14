# Reading the AI players' decision transcripts

**Companion to:** [How AI players accumulated stock in the Beer Game](ai-game-session-analysis.md). That report contains outcomes, inventory balances, and the control-policy equations. This document focuses on what the agents actually recorded while playing and what those records justify saying about their decisions.

## Scope: recorded rationale, not an invented inner monologue

This analysis covers sessions A (board 5) and B (board 6), both completed on 14 October 2026. It examines the six player worker transcripts, their public tool-call descriptions and parameters, returned observations, and agent-authored post-game summaries. The non-coaching observer is a source of outcome verification, not an explanation of the players' motives.

The transcripts do **not** contain a continuous public narrative explaining each decision. Most of the evidence is a repeated sequence of browser actions and results. Where streamed public prose exists, it reproduces the final response rather than providing an additional in-play explanation. Three player transcripts have nonempty final responses; the other three end with empty response text.

The report therefore separates three kinds of evidence:

- **Explicit statement:** an agent-authored action label or decision summary says what it intended to do.
- **Executed choice:** tool arguments show the policy it actually selected or retained.
- **Interpretation:** an analyst connects those choices to likely operational priorities. This is not quoted as something the agent privately thought.

Quotes below are verbatim public action descriptions or identified post-game statements. There is no reconstructed private chain of thought. Technical and operational difficulties are outside this document's scope.

Selected transcript excerpts, timestamps, parameter choices, and coverage information are preserved in [the transcript evidence file](ai-transcript-evidence.json). Times below are rounded elapsed times from the shared start; action-call timestamps mark invocation, not the end of the ensuing play interval.

## 1. Retailer: preserve a reserve while demand grows

### What it explicitly recorded

In session A, the retailer's descriptions included:

| Elapsed time | Public action description |
|---|---|
| 7:43 | “Continuing retailer service without changing policy” |
| 8:34 | “Maintaining retailer stock as demand grows” |
| 11:07 | “Serving retailer demand in the final minutes” |

Every recorded play-batch invocation used **buffer 2.0, smoothing 0.5**. In session B it consistently used **buffer 1.5, smoothing 0.75**, with descriptions such as:

- At 1:49: “Maintain the retailer inventory buffer”.
- At 6:56: “Respond to rising retailer demand”.

Neither retailer transcript contains a nonempty final explanation of why it chose those initial parameter values. We can identify the choice, its persistence, and the stated operational focus; we cannot attribute a more detailed rationale to the agent.

### Decision-level interpretation

The labels frame stock as a reserve to maintain and demand as something to keep responding to. The executed choices support **policy persistence** rather than repeated strategic reconsideration: a buffer was selected and reused throughout each session.

As demand increased, the routine changed order quantities without the agent needing to change its buffer. Thus continuing an unchanged policy could still produce increasingly large replenishment orders and inventory. The phrase “without changing policy” is especially useful evidence: growth in quantities should not be mistaken for a new agent decision to become more conservative at every stage.

The late-session wording still emphasizes service, not reducing inventory before the finish. This is consistent with a continuing replenishment objective. It does not prove that the agent consciously considered—and rejected—a liquidation strategy; no such discussion appears in the public record.

For the numerical consequence, see the [retailer analysis in the metrics report](ai-game-session-analysis.md#3-what-the-players-focused-on): all observed customer demand was eventually fulfilled, while a large reserve remained.

## 2. Wholesaler: keep supply and fulfillment moving

### What it explicitly recorded

Session A used **buffer 1.35, smoothing 0.65** throughout. Its descriptions emphasized:

- At 4:18: “Continue replenishment and oldest-order service”.
- At 5:59: “Maintain supply against rising visible demand”.
- At 11:54: “Process visible demand without duplicate ordering”.

Here “without duplicate ordering” describes the player's stated replenishment intention: avoid requesting supply already accounted for. It is not a claim about presentation issues.

Session B retained **buffer 1.4, smoothing 0.65**. The corresponding descriptions were:

- At 0:06: “Serve demand with a moderate reserve”.
- At 5:12: “Serve pending demand as supply arrives”.
- At 11:11: “Continue wholesaler inventory balancing”.

Its session A post-game summary described the policy as:

> “Served oldest enabled pending orders first, and replenished using demand estimate, stock, pending demand, and outstanding supply.”

That is a retrospective policy description, not evidence of a new decision made during play.

### Decision-level interpretation

This is a local inventory-position perspective: incoming supply, current stock, pending obligations, and recent demand are the salient variables. “Moderate reserve” is the agent's description of its intention, not a calibrated claim that the resulting inventory was economically moderate.

The oldest-fulfillable-order rule prioritizes clearing obligations that can be met immediately. The labels about supply arriving and inventory balancing are consistent with that rule and with accounting for replenishment already in transit.

What is absent is equally important, but must be described carefully: the public record contains no discussion of holding costs, a shared chain-wide stock target, or reducing orders because the factory already held a large reserve. This supports the conclusion that those considerations are **not documented**, not that the agent privately ignored or misunderstood them.

Its stable parameter choices again show execution of an existing policy. There is no recorded within-session change analogous to the session A factory adjustment.

## 3. Factory: the clearest observation-to-policy change

The session A factory supplies the strongest explicit decision sequence in the six transcripts.

### Recorded sequence

1. **Inspect while using the original policy.** At 3:07, its public action description was “Serve factory demand and inspect current inventory”. The call still used **buffer 1.25, smoothing 0.65**.
2. **Receive a concrete shortage observation.** The returned observation at approximately 3:53 reported **846 stock units** and pending order **#962 for 2,146 units**, with delivery unavailable for insufficient stock.
3. **Increase protection.** At 4:04, the next relevant call was labeled “Increase reserve for observed factory stock shortage”. Its arguments changed to **buffer 1.6, smoothing 0.5**.
4. **Retain the revised policy.** At 8:31, a later description was “Continue successful reserve policy at factory”. Subsequent batches kept the revised parameter pair through the finish.

The factory's final response also stated:

> “An earlier stock shortage prompted a higher reserve policy.”

This retrospective explanation agrees with both the earlier public action label and the executed parameter change. That agreement makes the decision rationale considerably better supported than a motive inferred only from final inventory.

### What that sequence means—and does not mean

At the decision level, the agent encountered an inability to fulfill a whole order and chose a larger safety margin. Lowering smoothing from 0.65 to 0.5 also reduced the weight of each new demand burst in the estimate. Both parameters changed together, so the effect of increasing the reserve cannot be isolated from the change in forecast responsiveness.

Calling the reserve policy “successful” records the agent's own assessment. It is not an independent verdict that the policy minimized stock or achieved an optimal service/cost balance. The accompanying [metrics report](ai-game-session-analysis.md#2-outcomes-service-succeeded-inventory-accumulated) shows eventual fulfillment alongside substantial remaining inventory.

The supported explanation is **service-oriented adaptation to observed insufficient stock**. Descriptions such as fear, panic, or hoarding would add an unrecorded psychological explanation and are not justified.

### Session B: production changed, the safety policy did not

The session B factory used **buffer 1.25, smoothing 0.65** throughout. It described actions such as “Adjust factory production to observed demand” at 4:23 and “Continue factory deliveries with demand smoothing” at 11:13.

Its post-game summary states:

> “The fixed buffer maintained eventual fulfillment of all observed orders but did not eliminate temporary shortages or large inventory swings.”

This distinction matters: production quantities were adjusted many times by the routine, but the agent did not revise its buffer or smoothing parameters. “Adjust production” therefore cannot be read as proof of continuous high-level strategy changes.

Its final public response also distinguished clearing the queue from uninterrupted service:

> “Temporary pending demand peaked at 68,516 units in snapshots; this was not a shortage-free run.”

The factory recognized a limitation of its outcome in its retrospective account. The transcript does not show that it responded to that observation by adding an inventory-cost objective or changing its fixed safety policy during the session.

## 4. What the six traces say about the agents' attention

Across the traces, the recurring themes are service, replenishment, rising demand, eligible deliveries, and reserve maintenance. These themes appear both in short public descriptions and in the parameters passed to the routine.

The players were also concentrating on **continuing the experiment through its shared deadline**. Closing-period descriptions emphasize staying active and serving orders, not winding inventory down. Because the supplied routine did not contain a terminal-inventory objective, sustained execution preserved its service-oriented behavior near the stop.

The visible decision pattern is best described as:

> Observe local state, execute a chosen replenishment policy, check its results, and—once in the clearest recorded case—revise safety parameters after an observed shortage.

This is a high-level summary of recorded behavior, not a verbatim mental transcript. It captures the important division of labor: the model chose and occasionally revised policy parameters; the supplied routine executed most individual ordering and delivery decisions.

## 5. Connecting the transcript to accumulated stock

The transcripts provide **intent evidence** for the metrics report's explanation:

- The retailer repeatedly described reserve maintenance while keeping its policy fixed.
- The wholesaler explicitly framed its work as serving demand with a reserve and balancing supply against pending obligations.
- The session A factory explicitly increased its reserve after a shortage, then characterized continued use of that policy as successful.
- None of the six public gameplay traces documents a holding-cost comparison, a shared stock-minimization plan, or a pre-finish inventory-depletion strategy.

The control-policy equations explain how those choices generated quantities; the metrics show the resulting inventory. Neither alone supplies a complete account of the agent's internal cognition.

The evidence also prevents a misleading narrative: the session B factory retained a smaller buffer but finished with more inventory than the session A factory. The transcripts do not support “more final stock means the agent became more anxious.” Policy mechanics, demand exposure, and batch timing remain necessary parts of the explanation.

## 6. Confidence and remaining unknowns

**Strongly supported:** which parameters were selected, whether they changed, the factory's explicit shortage-to-reserve adjustment, and the service/reserve language used in public action descriptions.

**Behaviorally supported but not explicitly explained by every player:** that fixed policies were retained as inventories grew, and that operational attention stayed on fulfillment rather than terminal inventory reduction.

**Not established:** why most agents initially chose their exact parameter values; whether they considered alternative policies but did not state them; what they privately believed about other players; or any psychological similarity to human players.

For future runs, a useful improvement would be to ask each player for a **brief public decision summary** at initialization and whenever it changes policy: the observation that matters, the selected objective, the chosen action, and the expected trade-off. That would create contemporaneous explanation evidence without requesting private chain-of-thought or inventing a rationale after the outcome is known.

## Conclusion

The most defensible transcript-based account is not that every agent independently reasoned its way into hoarding. Most players selected a buffered service policy and repeatedly executed it. One factory clearly observed insufficient stock, stated its intention to increase protection, and changed its parameters accordingly. Those documented choices help explain the large reserves, while leaving many initial-choice motives unrecorded.

Read this alongside the [metrics and policy analysis](ai-game-session-analysis.md) and the [selected transcript evidence](ai-transcript-evidence.json): intent, executed choices, and numerical outcomes are complementary evidence—not interchangeable claims.
