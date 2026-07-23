# airev

**AI code review before you push — using the AI CLI you already have logged in.**

No API keys. No accounts. No code leaves your machine. `airev` is a thin wrapper
that pipes your `git diff` into the AI CLI you already use (`claude` / `codex` /
`gemini` / `copilot`) and prints a severity-graded review right before you push —
so you catch the obvious stuff before a human reviewer does.

Advisory by default (never blocks your push); opt into a gate when you want one.

![airev reviewing a diff on git push](demo.gif)

```
── airev review (cli=claude, range=main...HEAD) ──
[P0] auth.py:42  hardcoded API secret — remove and load from env; rotate the key
[P1] db.py:17    query built via f-string with user input — SQL injection risk
[P1] util.py:5   get_first() raises IndexError on empty list — no guard
[P2] util.py:1   module name shadows stdlib `math`
──────────────────────────────────────────
```

## Why airev

- **Zero secrets** — reuses your logged-in AI CLI; nothing to configure, nothing to leak.
- **Local** — your diff is reviewed on your machine, not uploaded to a service.
- **Non-blocking** — advisory by default; `--gate` only if *you* want it to fail on P0/P1.
- **Cross-model** — have `codex` review what `claude` wrote (any mix); results merge into one list.
- **Beyond a static diff** — `--deep` verifies each finding, `--with-tests` runs your suite,
  `airev fix` loops until it's clean.
- **Yours to tune** — review rules live in a versioned `.airev/guidelines.md` per repo.
- **Pick your CLI** — `--cli claude` (or codex/gemini/copilot); autodetects if unset.

## What it does

| Command | What it does |
|---|---|
| `airev init` | install the pre-push hook + `.airev/guidelines.md` + `.airev.conf` |
| `airev review` | review pending changes, severity-graded `[P0]`/`[P1]`/`[P2]` |
| `airev review --deep` | two-pass — review, then verify each finding actually holds |
| `airev review --with-tests` | run the test suite; feed real failures into the review |
| `airev review --cli a,b [--merge]` | cross-model review with several CLIs (optionally de-duped) |
| `airev review --gate` · `--json` | block on `[P0]`/`[P1]` · machine-readable output (for CI) |
| `airev fix` | let claude/codex fix the findings, re-review, loop until clean |
| `airev last` · `airev upgrade` | re-read the last review · update airev in place |

Flags compose — e.g. `airev fix --with-tests --deep`, or
`airev review --cli claude,codex --merge --gate`.

## Quickstart

```bash
# 1) install (single file, no sudo). Lands in a dir already on your PATH when
#    possible, so `airev` works right away. (If it prints an "open a new
#    terminal" note, do that — it just added ~/.local/bin to your PATH.)
curl -fsSL https://raw.githubusercontent.com/Dshuishui/airev/main/install.sh | bash

# 2) in a repo you want reviewed
cd your-repo
airev init            # installs the pre-push hook + .airev/guidelines.md + .airev.conf

# 3) just work — on `git push` it reviews your changes *before* they go up
```

Also packaged for **npm** (`npm install -g airev`) and **Homebrew**
(`brew install Dshuishui/tap/airev`) — see [PUBLISHING.md](PUBLISHING.md) for the
release steps behind them.

On push, airev reviews the diff first and **streams the findings live**. When they
reach your threshold it asks `Push anyway? [y/N]` — answer `N` to abort, fix, and
push again; `y` to proceed. You decide *when* it stops to ask via `CONFIRM_LEVEL`
(`p0` / `p1` / `any` — default `any`, so even a `[P2]` nit prompts). A clean diff
(`LGTM`) pushes straight through. Every review is saved locally:

```bash
airev last          # re-read the last review (kept in .git/, never committed)
```

Prefer not to pipe to bash? It's one file — download it and put it on your PATH:

```bash
curl -fsSL https://raw.githubusercontent.com/Dshuishui/airev/main/airev -o ~/.local/bin/airev
chmod +x ~/.local/bin/airev
```

Requires one AI CLI already installed and logged in (`claude`, `codex`, `gemini`, or `copilot`).

Review on demand (no push needed):

```bash
airev review --cli claude            # review pending changes now
airev review --base origin/main      # choose the diff base
airev review --gate                  # exit non-zero on [P0]/[P1] (block push)
airev review --deep                  # two-pass: review, then verify each finding
```

`--deep` runs a second pass that re-examines the diff against the first pass —
keeping only findings it can back with a concrete failing input, adding any it
missed, and merging duplicates (wider context, ~2× the calls). Use it when a
change is subtle and you want the extra rigor; the fast single pass stays the
default for the pre-push gate.

```bash
airev review --with-tests            # run the suite, feed the results into the review
```

`--with-tests` actually *runs* your tests and hands the result to the review, so a
real failure gets tied to the changed lines that caused it (execution, not just
static reasoning). The command comes from `TEST_CMD` in `.airev.conf`, or is
autodetected (`npm test`, `make test`, `go test ./...`, `cargo test`, `pytest`).
Combine with `--deep` for the most thorough pass.

## Cross-model review (several CLIs)

The model that helped write a change shares its own blind spots — so let a *different*
model review it. Configure more than one reviewer and airev runs each, labelling who
found what; `--gate` / `--json` / `--confirm` all act on the **union**:

```bash
airev review --cli claude,codex          # review with both, once
```
```ini
# .airev.conf — make it the default for this repo
REVIEWERS="claude codex"
```
```
── claude ──
[P1] db.py:17  query built from user input — parameterize it
── codex ──
[P0] db.py:17  raw string concat into SQL — injection (codex caught the severity)
```

It's opt-in (N reviewers ≈ N× the calls), so the fast single reviewer stays the
default for the pre-push gate; reach for a panel on the changes that matter.

Add `--merge` to fold the panel into one de-duplicated list (an extra pass that
collapses findings about the same issue and keeps the highest severity) — handy when
reviewers overlap or you want a single clean list to post as one comment:

```bash
airev review --cli claude,codex --merge
# ...prints each reviewer's block, then a "── merged ──" consolidated list
```

`--gate` / `--json` then act on the merged list rather than the raw union.

## Review, fix, repeat

`airev fix` runs the review, hands the findings to an agentic CLI (`claude` or
`codex`) to edit the working tree, then re-reviews — looping until no `[P0]`/`[P1]`
remain (or `--max` passes). Edits are left **uncommitted** for you to read before
committing:

```bash
airev fix                 # review → fix → re-review, up to 3 passes
airev fix --max 5         # allow more passes
airev fix --with-tests    # run the suite each pass — fix until tests pass AND no P0/P1
airev fix --deep          # verified (two-pass) review each round
```

With `--with-tests`, each pass runs your suite and feeds failures into the review,
so the loop keeps fixing until the tests actually go green (not just until the model
stops complaining). `--with-tests` and `--deep` compose.

> **Note:** `airev fix` drives the agentic CLI with `claude -p --permission-mode
> acceptEdits` (or `codex exec --full-auto`) so it can edit files without a prompt
> per change. If a future CLI version renames those flags, `airev fix` will report
> "fixer failed" — adjust the two commands in `_apply_fix`. `airev review` (no edits)
> is unaffected. Edits are always left **uncommitted** for you to inspect.

## Run in CI (GitHub Actions)

Same tool, on every pull request. Copy
[`examples/github-pr-review.yml`](examples/github-pr-review.yml) to
`.github/workflows/airev.yml`, add an `ANTHROPIC_API_KEY` repo secret, and each
PR gets reviewed by Claude — findings posted as a comment, the check failing on
any `[P0]`/`[P1]`.

Locally it reuses your logged-in CLI; in CI it uses the key. `--json` gives
machine-readable output for your own tooling:

```bash
airev review --base origin/main --json
# [{"severity":"P0","finding":"auth.py:42 hardcoded secret ..."}, ...]
```

## Upgrade

```bash
airev upgrade      # pulls the latest airev over your current install
```

## Configuration

Per-repo, created by `airev init`:

- **`.airev.conf`** — `CLI=claude`, plus optional `BASE=origin/main`,
  `CONFIRM_LEVEL=p0|p1|any` (when the pre-push prompt trips), and
  `CONTEXT_LINES=20` (how much code around each hunk the model sees — more
  context means fewer false positives).
- **`.airev/guidelines.md`** — the review rules (the prompt). The built-in default
  reviews *adversarially* — it only reports a finding when it can name a concrete
  input/state that breaks the code, which keeps signal high. Tune it to what your
  project cares about; it's versioned with your code. If it's absent, airev reuses
  the house rules you already have — `AGENTS.md`, then `CLAUDE.md`, `.cursorrules`,
  or `.github/copilot-instructions.md`.

CLI resolution order: `--cli` flag → `$AIREV_CLI` → `.airev.conf` `CLI=` → autodetect.
Repeated pushes of the same diff reuse the last review from cache (`--no-cache` to force).

## Silence a false positive

Reviewed a flag and decided it's fine? Drop an `airev-ignore` marker on that line —
airev never reports it again (like `eslint-disable` / `# noqa`):

```python
password = os.getenv("PW", "")  # airev-ignore  — empty default is intentional here
```

The marker works with any CLI: it's both requested in the prompt and enforced
locally, so a finding on an `airev-ignore` line is dropped even if the model misses it.

## How it works

`airev` never talks to an LLM API itself. It computes the diff, injects your
guidelines, and shells out to the AI CLI you already authenticated. That's the
whole trick — no keys, no vendor lock-in, and adding a new CLI is one line.

## Roadmap

- [x] v0.1 — `init` + `review`, severity grading, `--gate`, specify CLI
- [x] v0.2 — cost guards: ignore globs (`*.lock`, `dist/**`, …) + large-diff truncation (`MAX_DIFF_LINES`)
- [x] v0.3 — CI mode (GitHub Actions workflow), `--json` output, `airev upgrade`
- [x] v0.4 — review *before* the push completes: prompt to fix-or-proceed, saved result (`airev last`)
- [x] v0.5 — fewer false positives (wider diff context; reuse `AGENTS.md`/`CLAUDE.md` rules;
  inline `airev-ignore` to silence accepted findings), live-streamed findings, result caching,
  choose-your-own `CONFIRM_LEVEL`, on-demand review of uncommitted work
- [x] v0.6 — `airev fix` (review → agentic fix → re-review loop)
- [x] v0.6.1 — adversarial default review prompt (report only what a concrete input can break)
- [x] v0.7 — `airev review --deep` (two-pass: review, then verify each finding)
- [x] v0.8 — `airev review --with-tests` (run the suite, feed real failures into the review)
- [x] v0.8.1 — `airev fix --with-tests` / `--deep` (fix until the suite is green and no P0/P1)
- [x] v0.9 — cross-model review: configure several CLIs (`REVIEWERS=`, `--cli claude,codex`),
  labelled per reviewer, gate on the union
- [x] v0.9.1 — `--merge` to consolidate a multi-reviewer panel into one de-duplicated list
- [ ] v1.0 — npm / brew publish (packaging ready: `package.json`, `Formula/`, `PUBLISHING.md`),
  more CLIs verified (codex/gemini)

## License

MIT
