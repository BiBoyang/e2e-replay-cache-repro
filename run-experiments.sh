#!/usr/bin/env bash
# Repro matrix for the e2e replay-cache model-swap blind spot.
# Prerequisites: deps installed, app served on :4173, LLM_BASE_URL/LLM_API_KEY set,
# E2E_MODEL / E2E_MODEL_B point at two distinct tool-capable model ids.
set -u
cd "$(dirname "$0")"
mkdir -p results

step() { echo; echo "===== $* ====="; }

step "A1 baseline live run (model A, records cache entry)"
npx e2e run 2>&1 | tee results/A1.log | grep -E "AI |Cache |passed|failed"

step "A2 replay (expect: replayed, NO AI line, ~1s)"
npx e2e run 2>&1 | tee results/A2.log | grep -E "AI |Cache |passed|failed"

step "B core experiment: same agent, model B (expect: replayed, zero model calls, no warning)"
E2E_MODEL="$E2E_MODEL_B" npx e2e run 2>&1 | tee results/B.log | grep -E "AI |Cache |passed|failed"
echo "-- report.json usage (expect modelTokens 0, maxModelCallsInStep 0):"
python3 -c "import json;u=json.load(open('.e2e/report.json'))['run']['usage'];print({k:u[k] for k in ('modelTokens','maxModelCallsInStep')})"
echo "-- report.json carries no identity of the configured model (expect 0):"
grep -c "$E2E_MODEL_B" .e2e/report.json || echo "0 matches"

step "C control: switch agent entry instead (expect: missed, model B really runs)"
npx e2e run --agent b 2>&1 | tee results/C.log | grep -E "AI |Cache |passed|failed"
npx e2e cache ls | tee results/cache-ls.txt

step "D fault injection: rename button, strict cache (expect: exit 2, REPLAY_STALE, zero model calls)"
sed -i.bak 's|<button type="submit">Add</button>|<button type="submit">Add task</button>|' app/index.html
CI=1 npx e2e run --strict-cache > results/D-strict.log 2>&1
echo "strict exit=$? (expect 2)"
grep -E "REPLAY_STALE|Cache " results/D-strict.log

step "D repair: drop strict, agent takes over (expect: handed off, test passes)"
npx e2e run 2>&1 | tee results/D-repair.log | grep -E "AI |Cache |passed|failed"

step "Restore app; two more runs (expect: handed off once, then replayed)"
mv app/index.html.bak app/index.html
npx e2e run 2>&1 | tee results/D-restore1.log | grep -E "AI |Cache |passed|failed"
npx e2e run 2>&1 | tee results/D-restore2.log | grep -E "AI |Cache |passed|failed"

echo; echo "Done. Full logs in results/. Total model cost: sum the 'AI ' lines."
