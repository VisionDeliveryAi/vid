#!/bin/sh
# Purpose: selftest case — the grader names the fault as a patch (v0.9.8 spec 3.4, R4). A grader brief carries `### Fault
# proof`: the rows in scope — the protected row (the plan's protected: line), a row repaired after a weak test (a
# BREACHED class=test on record), and no other unless drawn one in ten — each with why, the faults folder (made), the
# `fault: ROW-<id> | target= | control= | patch=` return line and that the grader runs nothing; the check passes it. The
# proof is the grader's patch exactly: a faulted run on anything else is inconclusive (fault-tree). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-patch-from-grader: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; pf_repo "$T/repo"; rows s1 3 3
printf '# CLAUDE.md\n\n## Placement rules\n\n- p\n\n## Ledger and docs laws\n\n- l\n\n## Import law\n\n- i\n\n## Law-change rule\n\n- c\n' > CLAUDE.md
printf '# DECISIONS\n' > DECISIONS.md; printf '# PRD\n' > PRD.md; commit_all records
printf 'verdict slice=1 row=ROW-002 result=BREACHED class=test brief=b0 quoted-at=x at=%s\n' "$(utcnow)" >> .vid/metrics-events
mkdir -p .vid/ledger-results; printf '<report/>\n' > .vid/ledger-results/r.xml
CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role grader --slice 1 --rows ROW-001,ROW-002,ROW-003 --receipt r.xml > "$T/out" 2>&1 || fail 'the grader brief was refused'
B=$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1)
awk '/^### Fault proof/ { on = 1; next } on && /^## / { exit } on' "$B" > "$T/fp"
grep -qx 'ROW-001 protected' "$T/fp" || fail 'the protected row is not in scope'
grep -qx 'ROW-002 repaired' "$T/fp" || fail 'the row repaired after a weak test is not in scope'
D=$(printf '%s\n' "$B" | sed 's/\.md$/.faults/'); [ -d "$D" ] || fail "no faults folder $D"
grep -qF "    fault: ROW-<id> | target=<case id> | control=<case id> | patch=$D/<ROW-id>.patch" "$T/fp" || fail 'the section lacks the fault return line'
grep -qF 'You run nothing' "$T/fp" || fail 'the section does not say the grader runs nothing'
awk '/^ROW-/ { if ($2 !~ /^(protected|journey|repaired|sample)$/) bad = 1 } END { exit bad }' "$T/fp" || fail 'a row in scope gives no reason'
Q3=$(sed -n 's/^quoted-at: //p' "$B"); if [ $(( $(printf '%s %s' ROW-003 "$Q3" | cksum | cut -d' ' -f1) % 10 )) -eq 0 ]; then W3='ROW-003 sample'; else W3=''; fi
[ "$(grep '^ROW-003' "$T/fp" || true)" = "$W3" ] || fail "ROW-003's place is not the one-in-ten draw ('$W3')"
# the proof is the grader's patch, exactly
FT=$(pf_fault); H=$(git rev-parse --short=12 HEAD)
pf_rcpt "$H.proof.sel-1.run-c.xml" "$Q" inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-r.xml" "$Q" inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-c.xml" "$H.proof.sel-2.run-r.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=fault-tree' ] || fail "a faulted run without the patch: $(pf_last)"
exit 0
