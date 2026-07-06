#!/bin/zsh
# Behavioral checks against the running map. Usage: zsh tests/e2e.sh [BASE]
# Start the server first: make serve &
set -u
BASE="${1:-http://localhost:8789}"
pass=0; fail=0
ok(){ echo "PASS $1"; pass=$((pass+1)); }
bad(){ echo "FAIL $1"; fail=$((fail+1)); }

code(){ curl -s -o /dev/null -w '%{http_code}' "$BASE$1"; }

# 1) pages + every baked artifact serve 200
for p in / /methodology.html; do
  [ "$(code $p)" = "200" ] && ok "GET $p" || bad "GET $p"
done
for f in meta.json answers.json congestion.json prices.json reliability.json \
         outages.json market_anchors.json demand_anchors.json \
         congestion_premium.json chokepoints.geojson dc_sites.geojson sual.geojson; do
  [ "$(code /data/$f)" = "200" ] && ok "GET /data/$f" || bad "GET /data/$f"
done

# 2) structural JSON assertions
python3 - "$BASE" <<'PY'
import json, sys, urllib.request
base = sys.argv[1]
def get(p):
    with urllib.request.urlopen(base + p) as r:
        return json.load(r)
checks = []
ans = get("/data/answers.json")
checks.append(("answers has q1/q2/q3", all(k in ans for k in ("q1","q2","q3"))))
ck = get("/data/chokepoints.geojson")
checks.append(("5 chokepoint features", len(ck["features"]) == 5))
dc = get("/data/dc_sites.geojson")
checks.append(("14 dc features", len(dc["features"]) == 14))
cong = get("/data/congestion.json")
checks.append(("league present", len(cong.get("league", [])) >= 10))
html = urllib.request.urlopen(base + "/").read().decode()
checks.append(("page mentions the three questions",
               "Can the grid handle" in json.dumps(ans) and "gridbill-ph" in html))
checks.append(("disclaimer on page", "legitimate explanations" in html))
bad = [n for n, c in checks if not c]
for n, c in checks:
    print(("PASS " if c else "FAIL ") + n)
sys.exit(1 if bad else 0)
PY
[ $? -eq 0 ] && ok "json structural block" || bad "json structural block"

# 3) browser block (only if agent-browser is installed)
strip(){ tail -1 | sed $'s/\x1b\\[[0-9;]*m//g' | tr -d '"\\'; }
if command -v agent-browser >/dev/null 2>&1; then
  agent-browser close >/dev/null 2>&1; sleep 2
  agent-browser open "$BASE/" >/dev/null 2>&1; sleep 6
  R=$(agent-browser eval 'const d=window.__diag||{};[d.ready,d.chokepoints,d.dcs,d.league>0,d.mode].join("|")' 2>/dev/null | strip)
  echo "diag: $R"
  [[ "$R" == true\|5\|14\|true\|* ]] && ok "browser __diag ready+layers" || bad "browser __diag ($R)"
  agent-browser eval 'document.querySelector("[data-mode=price]").click()' >/dev/null 2>&1
  sleep 1
  M=$(agent-browser eval '(window.__diag||{}).mode' 2>/dev/null | strip)
  [[ "$M" == "price" ]] && ok "mode switch to price" || bad "mode switch ($M)"
  agent-browser close >/dev/null 2>&1
else
  echo "SKIP browser block (agent-browser not installed)"
fi

echo "e2e: $pass pass, $fail fail"
exit $([ $fail -eq 0 ] && echo 0 || echo 1)
