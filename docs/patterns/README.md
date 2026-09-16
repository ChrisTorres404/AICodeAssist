# Patterns

Design notes: why a piece of the pipeline is built the way it is, and how to
rebuild the same thing somewhere else. These are explanations, not procedures —
the procedures live in [`../../core/methodology/`](../../core/methodology/README.md)
and the skills.

| Document | What it covers |
|---|---|
| [`anti-hallucination-design.md`](anti-hallucination-design.md) | Why validation is layered rather than single-pass: what each of the four layers catches, what failure produced it, why no layer works alone, and what the whole thing costs |
| [`behavioral-testing-in-ci.md`](behavioral-testing-in-ci.md) | Running behavioural suites in continuous integration against a real database, and publishing the results as a dashboard the team actually reads |

## Reading them

Each one states the problem first, in terms of a failure someone actually hit,
then the design that answers it, then the cost. Read the problem section before
deciding whether the design is worth adopting: a control that answers a failure
your project does not have is pure overhead.
