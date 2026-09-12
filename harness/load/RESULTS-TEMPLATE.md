# Capacity Report — <ENVIRONMENT> — <DATE>

**Run by:** <name> · **Stack:** <what was running, how many nodes> ·
**Commit:** <sha> · **Hardware:** <cpu/ram> · **Endpoint mix:** <LOAD_ENDPOINTS summary>

## Headline numbers

| Scenario | Result | p99 at that point | Bottleneck named |
|----------|--------|-------------------|------------------|
| Steady state (RATE=__) | sustained / degraded | __ ms | |
| Ramp to breakpoint | breakpoint at __ req/s | __ ms | |
| Mixed blend | breakpoint at __ req/s | __ ms | |
| Rate-limit flood | 429s: __% · 5xx: __ · neighbour p99 delta: __ ms | | |
| Soak (__ h) | memory drift: __ · connection floor: __ | | PASS / FAIL |

**One-line capacity statement:**

> On <node spec>, the service sustains ~__ req/s of the mix above at p99 < __ ms.

State the mix in the sentence. A request-rate number without the shape of the
traffic behind it is not reproducible.

## Ranked bottleneck list → follow-up work

1.
2.
3.

## Evidence

- k6 summaries: `results/<run>/summary.json`
- Server metrics: `results/<run>/server-metrics.csv`
- Traces / dashboards: <links, if the stack has them>

## Notes and anomalies

<Anything that would change how these numbers should be read: a noisy host, a
cold cache, a warm-up stage discarded, a scenario that had to be cut short.>
