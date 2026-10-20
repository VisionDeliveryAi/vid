#!/bin/sh
# Purpose: selftest case — a changed fail-if puts the sibling rows to confirm and wipes only the row whose own
# obligation changed (v0.26.10.3 R1–R3; §5 amend-sibling-kept). A gated toy run with the real post-commit hook: REQ-001
# has two clauses and four rows, all passing on a receipt — ROW-001 and ROW-002 KEPT, ROW-003 held (two product rounds),
# ROW-004 with a granted round allowance (a KEPT row can be neither held nor under an allowance, so those two states
# ride rows of their own). One commit changes clause 1 and ROW-001's obligation. Convicts unless: ROW-001 is reset
# (`amended … by=obligation`, its verdict gone, stale); ROW-002..004 get `law-changed … item=REQ-001` and no `amended`,
# and each keeps its row-state line (verdict, attempts, hold, allowance) and its evidence state (pass; held for ROW-003); completion counts
# ROW-002 unmet and names the three; `authority --changed` lists ROW-002 even after a commit edits its INVENTORY line;
# `authority --kept ROW-002` clears it, and completion then names two. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "amend-sibling-kept: $*" >&2; exit 1; }
prd() { # <clause 1>
  printf '# Toy — PRD\n\ngrammar: 0.9.3\n\n```vid-prd\nREQ-001 | functional | T1 | A link lasts a while and a code is short. | fail-if: %s, or a code has another length than six | serves: short links | authority: authoritative | source: A-001 | phase: pilot | plain: links expire and codes are short\n```\n' "$1"
}
plan_repo "$T/repo"
cp "$CHECKS/inventory.sh" checks/; printf '# CLAUDE.md\n\n```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
mkdir -p checks/hooks; cp "$CHECKS/hooks/post-commit" checks/hooks/; chmod +x checks/hooks/post-commit
prd 'a link works after seven days' > PRD.md
rows S1 1 4
sed 's/^\(ROW-00\([1-4]\) | behavior | s[1-4] | anon | - | \)x |/\1row \2 holds |/' INVENTORY.md > i && mv i INVENTORY.md
commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
git config core.hooksPath checks/hooks
Q=$(git rev-parse --short=12 HEAD)
{ printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$Q" "$(utcnow)"
  printf 'verdict slice=1 row=ROW-002 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$Q" "$(utcnow)"
  printf 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=b1 quoted-at=%s at=%s\n' "$Q" "$(utcnow)"
  printf 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=b2 quoted-at=%s at=%s\n' "$Q" "$(utcnow)"
  printf 'verdict slice=1 row=ROW-004 result=BREACHED class=product brief=b1 quoted-at=%s at=%s\n' "$Q" "$(utcnow)"
  printf 'reissued row=ROW-004 why=A-002 rounds=2 at=%s\n' "$(utcnow)"; } >> .vid/metrics-events
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed
for r in ROW-001 ROW-002 ROW-004; do [ "$(state $r)" = pass ] || fail "$r is $(state $r) before the change, not pass"; done
[ "$(state ROW-003)" = held ] || fail "ROW-003 reads $(state ROW-003) before the change, not held"   # the evidence reader shows a held row held
sh checks/metrics.sh row-state --table | sort > "$T/before"
awk -F'\t' '$1 == "ROW-003" && $5 == "bound"' "$T/before" | grep -q . || fail "ROW-003 is not held before the change: $(grep ROW-003 "$T/before")"
awk -F'\t' '$1 == "ROW-004" && $11 == 2' "$T/before" | grep -q . || fail "ROW-004 has no allowance of 2 before the change: $(grep ROW-004 "$T/before")"
# the change: clause 1 of REQ-001 and ROW-001's own obligation, one commit
prd 'a link works after three days' > PRD.md
sed 's/| row 1 holds |/| row 1 holds for three days |/' INVENTORY.md > i && mv i INVENTORY.md
commit_all 'clause 1 and ROW-001' > "$T/hook.out" 2>&1 || fail 'the change did not commit'
L=$(git rev-parse --short=12 HEAD)
grep -q "^amended row=ROW-001 sha=$L by=obligation " .vid/metrics-events || fail 'ROW-001 was not reset by its own obligation'
for r in ROW-002 ROW-003 ROW-004; do
  grep -q "^law-changed row=$r sha=$L item=REQ-001 at=" .vid/metrics-events || fail "no law-changed for $r"
  grep -q "^amended row=$r " .vid/metrics-events && fail "$r was wiped by its parent's fail-if"
done
[ "$(grep -c "^law-changed " .vid/metrics-events)" -eq 3 ] || fail 'not exactly three law-changed events'
grep -q '1 row(s) reset (own obligation changed); 3 row(s) to confirm' "$T/hook.out" || fail "the hook's closing line does not count both kinds: $(cat "$T/hook.out")"
sh checks/metrics.sh row-state --table | sort > "$T/after"
awk -F'\t' '$1 == "ROW-001" && $3 == "NONE"' "$T/after" | grep -q . || fail "ROW-001's verdict survived its own amendment: $(grep ROW-001 "$T/after")"
[ "$(state ROW-001)" = stale ] || fail "ROW-001 is $(state ROW-001), not stale after its reset"
for r in ROW-002 ROW-003 ROW-004; do
  [ "$(grep "^$r	" "$T/before")" = "$(grep "^$r	" "$T/after")" ] || fail "$r's state changed: before '$(grep "^$r	" "$T/before")' after '$(grep "^$r	" "$T/after")'"
done
for r in ROW-002 ROW-004; do [ "$(state $r)" = pass ] || fail "$r is $(state $r) after the change, not still passing"; done
[ "$(state ROW-003)" = held ] || fail "ROW-003 reads $(state ROW-003) after the change, not held as before"
# completion: a full receipt at HEAD makes ROW-002 kept; it is still counted unmet, and the three are named
cp .vid/ledger-results/r1 ".vid/ledger-results/$L.full.xml"
sh checks/metrics.sh completion > "$T/c1" 2>&1
grep -qx 'to confirm: 3 (ROW-002 ROW-003 ROW-004)' "$T/c1" || fail "completion does not name the rows to confirm: $(cat "$T/c1")"
U0=$(sh checks/metrics.sh closure | awk '$2=="contract-ambiguity"||$2=="invalid-test-evidence"||$2=="unfinished-implementation" { sub(/^n=/,"",$3); u+=$3 } END { print u+0 }')
grep -qx "completion unmet=$((U0 + 1)) .*" "$T/c1" || fail "ROW-002 (kept, to confirm) is not counted unmet once (closure $U0): $(grep '^completion ' "$T/c1")"
grep -q '^complete' "$T/c1" && fail 'completion computed complete with rows to confirm'
# the listing, after an edit to ROW-002's INVENTORY line
sh checks/brief.sh authority --changed > "$T/a1" 2>&1
grep -q '^authority-changed row=ROW-002 ' "$T/a1" || fail "authority --changed does not list ROW-002: $(cat "$T/a1")"
sed 's/^\(ROW-002 | behavior | \)s2 |/\1s2 renamed |/' INVENTORY.md > i && mv i INVENTORY.md
git diff --quiet INVENTORY.md && fail 'the line edit changed nothing'
commit_all 'ROW-002 subject' > /dev/null 2>&1 || fail 'the line edit did not commit'
sh checks/brief.sh authority --changed > "$T/a2" 2>&1
grep -qx "authority-changed row=ROW-002 since=$L what=REQ-001 to-confirm=yes" "$T/a2" || fail "an edit to ROW-002's line took it off the listing: $(cat "$T/a2")"
VID_COURT_EVENT=off sh checks/inventory.sh --report 2>/dev/null | grep -q '^authority-changed row=ROW-002 .* to-confirm=yes$' || fail 'inventory.sh --report does not list ROW-002 to confirm'
# kept clears it
sh checks/brief.sh authority --kept ROW-002 > /dev/null || fail 'authority --kept refused'
sh checks/brief.sh authority --changed | grep -q '^authority-changed row=ROW-002 ' && fail 'ROW-002 is still listed after authority --kept'
sh checks/metrics.sh to-confirm 2>/dev/null | grep -q 'row=ROW-002 ' && fail 'ROW-002 is still to confirm after authority --kept'
cp .vid/ledger-results/r1 ".vid/ledger-results/$(git rev-parse --short=12 HEAD).full.xml"
sh checks/metrics.sh completion | grep -qx 'to confirm: 2 (ROW-003 ROW-004)' || fail 'completion does not name the two left'
exit 0
