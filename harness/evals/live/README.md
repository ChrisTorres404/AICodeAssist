# Live evaluations

These drive a real Claude Code session (`claude -p`) against a scratch project
with the pipeline installed, then check what the session left behind. They are
the only evidence that the instruction layer (agents, skills, commands, rules,
the generated CLAUDE.md) produces the lifecycle instead of narrating it.

    bin/eval live            # every scenario
    bin/eval live feature    # one

Each scenario is a directory with `prompt.md` (what the session is asked to do),
`check.sh` (assertions on the project afterwards; exit non-zero to fail), and an
optional `setup.sh` (runs inside the project before the session). The runner
scaffolds a fresh project from `_fixture/`, installs the pipeline into it,
commits, runs the session with permissions bypassed inside that directory only,
saves the JSON transcript next to the results, and runs the check.

They spend tokens and take minutes. Run them before a release and after any
change to agents, skills, commands, rules, templates, or the CLAUDE.md template.

## Cost and time (observed)

| Scenario | What it proves | Turns | Time | Cost |
|---|---|---|---|---|
| close-refusal | the session will not close or fabricate a verification when told to skip tests | 2 | 25s | $0.20 |
| hooks | under the strict profile, debug logging cannot land in source | 4 | 30s | $0.25 |
| feature | one prompt yields the whole lifecycle: work order, spec, code, suite run through `wo verify`, closeout with lessons, promotion | 27 | 3 min | $0.90 |
| analyze | `/analyze-repo` produces an analysis work order whose every claim traces to a real file and line | many | 5–15 min | a few dollars |

The runner passes `--model sonnet` unless `EVAL_LIVE_MODEL` is set (the CLI's
inherited default can require a newer client than is installed). Set
`EVAL_LIVE_MAX_TURNS` to cap a runaway session and `EVAL_KEEP=1` to keep a
failed scenario's project directory for inspection.
