# airev

**AI code review before you push — using the AI CLI you already have logged in.**

No API keys. No accounts. No code leaves your machine. `airev` is a thin wrapper
that pipes your `git diff` into the AI CLI you already use (`claude` / `codex` /
`gemini` / `copilot`) and prints a severity-graded review right before you push —
so you catch the obvious stuff before a human reviewer does.

Advisory by default (never blocks your push); opt into a gate when you want one.

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
- **Yours to tune** — review rules live in a versioned `.airev/guidelines.md` per repo.
- **Pick your CLI** — `--cli claude` (or codex/gemini/copilot); autodetects if unset.

## Quickstart

```bash
# 1) install (single file, no sudo — drops into ~/.local/bin)
curl -fsSL https://raw.githubusercontent.com/Dshuishui/airev/main/install.sh | bash

# 2) in a repo you want reviewed
cd your-repo
airev init            # installs the pre-push hook + .airev/guidelines.md + .airev.conf

# 3) just work — on `git push` it reviews your changes and prints findings
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
```

## Configuration

Per-repo, created by `airev init`:

- **`.airev.conf`** — `CLI=claude`, optional `BASE=origin/main`.
- **`.airev/guidelines.md`** — the review rules (the prompt). Tune it to what your
  project cares about; it's versioned with your code.

CLI resolution order: `--cli` flag → `$AIREV_CLI` → `.airev.conf` `CLI=` → autodetect.

## How it works

`airev` never talks to an LLM API itself. It computes the diff, injects your
guidelines, and shells out to the AI CLI you already authenticated. That's the
whole trick — no keys, no vendor lock-in, and adding a new CLI is one line.

## Roadmap

- [x] v0.1 — `init` + `review`, severity grading, `--gate`, specify CLI
- [x] v0.2 — cost guards: ignore globs (`*.lock`, `dist/**`, …) + large-diff truncation (`MAX_DIFF_LINES`)
- [ ] v0.3 — JSON/CI mode, `--fix` loop, npx/brew distribution

## License

MIT
