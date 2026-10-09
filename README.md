# e2e replay cache — model-swap blind spot · minimal reproduction

Reproduces the behavior reported to [tester-army/e2e](https://github.com/tester-army/e2e)
(v0.18.0): swapping the model under the **same** agent entry replays the cache
silently — zero model calls, all green, no warning — while the console header
prints the new model that never ran. `report.json` carries no model identity at
all. Documented design choice (`docs/cache.mdx`: "Changing the model does not
[cause a miss]"); this package demonstrates the consequence.

Verified on 3 independent setups, 2026-10-09 (every matrix cell consistent).

## Requirements

- Node 20+, npm
- An OpenAI-compatible endpoint with **two distinct tool-capable models**
  (verified: Kimi coding gateway `k3-agent`/`k2d8-preview`, also `k3`/`kimi-for-coding`)

## Quick start

```bash
npm install

# 1. serve the app under test
python3 -m http.server 4173 --directory app &

# 2. credentials + the two model ids
export LLM_BASE_URL=https://api.moonshot.cn/v1   # or your OpenAI-compatible endpoint
export LLM_API_KEY=<key>
export E2E_MODEL=<model-a-id>
export E2E_MODEL_B=<model-b-id>

# 3. full matrix (~9 model calls, ~45k tokens with prompt caching)
chmod +x run-experiments.sh && ./run-experiments.sh
```

If the Playwright browser download fails in your network:

```bash
PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx @e2e-dev/web install chromium
```

## What to expect

| Step | Expected |
|---|---|
| A1 first run | pass, `Cache 1 missed`, AI line with tokens/calls → recording written |
| A2 second run | pass, `Cache 1 replayed`, **no AI line** (~1s, zero model calls) |
| **B model swap** | pass, `Cache 1 replayed`, **no AI line, no warning**; header prints model B; `report.json` usage shows `modelTokens: 0` and contains no model name |
| C `--agent b` control | `Cache 1 missed`, model B really runs (AI line present) — proves the key tracks the *agent entry*, not the model |
| D fault + `--strict-cache` | **exit 2**, `REPLAY_STALE ... (target-not-found)`, zero model calls, attribution at action granularity |
| D repair / restore | agent takes over (`handed off`), re-records; after restoring the app one more `handed off`, then stable `replayed` |

## Layout

- `app/index.html` — single-file todo app (input + "Add" button + `role=status`); `app/index.html.healthy` is the pre-fault backup
- `e2e.config.ts` — model id intentionally read from `E2E_MODEL` env var
- `tests/todo.e2e.ts` — one `agent.act` + two locator assertions
- `run-experiments.sh` — the full matrix with expected results echoed
- `results/` — created on run; all raw logs land here
