#!/bin/sh
# Purpose: selftest case — closure is a partition and "complete" is computed
# (v0.9.3 spec 3.13, R18; §7 case 7, first half). A toy repository under
# `grammar: 0.9.3` with a fixture results reader and current receipts.
# Convicts unless `metrics.sh closure` puts one owner-decision row and one
# held row in contract ambiguity, one `test` breach in invalid test
# evidence, one red row in unfinished implementation, names one deploy-owed
# row and counts one `later` item — each unmet row exactly once — and
# `completion` says "not complete"; with every row met but one open
# VID-QUESTION → strict-gaps 1, "not complete"; the same for one open
# `Q<n>` line in RUN-STATE (v0.9.5 3.1, §7 case 23); with every row met but one
# seam `credentials: held | probe: owed` no client touches → the inventory
# court names it OWED, strict-gaps 1, "not complete"; with everything met
# → "complete, 1 rows at deploy, 1 later", the `completion` event recorded
# and RUN-STATE's `run:` set to complete. Env: CHECKS.
set -eu
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'   # v0.9.5 3.11: every event line ends ` at=<UTC>`
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors app tests/invariants .vid/ledger-results
cp "$CHECKS/coverage.sh" "$CHECKS/inventory.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
printf '# Purpose: ledger (fixture)\n' > tests/invariants/t.py
item() { printf 'REQ-%s | functional | T1 | Item %s. | fail-if: it is not | serves: x | phase: %s\n' "$1" "$1" "${2:-pilot}"; }
row() { printf 'ROW-%s | behavior | REQ-%s | n/a | n/a | row %s | REQ-%s | %s\n' "$1" "$1" "$1" "$1" "${2:-tests/invariants/t.py}"; }
state() { # $1=item ids (pilot) $2=extra inventory lines
  { printf '# Toy\n\n## Items\n\n```vid-prd\n'; for i in $1; do item "$i"; done; item 006 later; printf '```\n'; } > PRD.md
  { printf '# Purpose: toy —'; for i in $1; do printf ' REQ-%s' "$i"; done; printf '\n'; } > app/main.py
  { printf '# toy\n```vid-inventory\ngrammar: 0.9.3\n'; printf '%s\n' "$2"; printf '```\n'; } > INVENTORY.md
  g add -A && g commit -qm state; S=$(git rev-parse --short=12 HEAD)
  { echo '<r>'; for i in 001 002 004 005 007; do printf '<case name="tests/invariants/t.py::t[ROW-%s]" status="passed" time="0.1"/>\n' "$i"; done
    printf '<case name="tests/invariants/t.py::t[ROW-003]" status="failed" time="0.1"/>\n'; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"
}
fail() { echo "closure: $*" >&2; sh checks/metrics.sh completion >&2 || true; exit 1; }
state '001 002 003 004 007' "$(row 001 'owed: owner-decision — OQ-1'; row 002; row 003; row 004; row 005 'owed: paid by /vid deploy gate 2 — the platform worker consumes it'; row 007)"
cat > .vid/metrics-events <<EV
verdict slice=1 row=ROW-002 result=BREACHED class=test brief=b1 quoted-at=$S
verdict slice=1 row=ROW-004 result=BREACHED class=product brief=b1 quoted-at=$S
verdict slice=2 row=ROW-004 result=BREACHED class=product brief=b2 quoted-at=$S
verdict slice=1 row=ROW-007 result=KEPT class=product brief=b1 quoted-at=$S
EV
CL=$(sh checks/metrics.sh closure)
[ "$(printf '%s\n' "$CL" | grep -c '^closure ')" -eq 5 ] || fail 'not five lines'
printf '%s\n' "$CL" | grep -qx 'closure contract-ambiguity n=2 ROW-001 ROW-004' || fail 'contract ambiguity'
printf '%s\n' "$CL" | grep -qx 'closure invalid-test-evidence n=1 ROW-002' || fail 'invalid test evidence'
printf '%s\n' "$CL" | grep -qx 'closure unfinished-implementation n=1 ROW-003' || fail 'unfinished implementation'
printf '%s\n' "$CL" | grep -qx 'closure deploy-owed n=1 ROW-005' || fail 'deploy-owed'
printf '%s\n' "$CL" | grep -qx 'closure later n=1' || fail 'later'
# each unmet row once: the partition sums to the headline's unmet count
sh checks/metrics.sh | sed -n 2p | grep -q '(unmet 4;' || fail 'the headline unmet count is not the partition'
sh checks/metrics.sh completion | grep -q '^not complete — unmet 4' || fail 'completion did not say not complete'
# everything met
mkdir -p .vid; printf 'run: active\nslice: 3 closed    since: 2026-09-23T10:00:00Z    commit: x\n\nprose\n' > .vid/RUN-STATE.md
state '007' "$(row 005 'owed: paid by /vid deploy gate 2 — the platform worker consumes it'; row 007)"
OUT=$(sh checks/metrics.sh completion --record)
printf '%s\n' "$OUT" | grep -qx 'completion unmet=0 strict-gaps=0' || fail "the met state: $OUT"
printf '%s\n' "$OUT" | grep -qx 'complete, 1 rows at deploy, 1 later' || fail 'the complete line'
grep -qxE "completion unmet=0 strict-gaps=0 $ATRE" .vid/metrics-events || fail 'the completion event was not recorded'
grep -qx 'run: complete' .vid/RUN-STATE.md || fail 'RUN-STATE was not set to complete'
# one open VID-QUESTION
printf '# VID-QUESTION: (OQ-9) is the digest weekly?\n' >> app/main.py
sh checks/metrics.sh completion | grep -qx 'completion unmet=0 strict-gaps=1' || fail 'an open question is not a strict gap'
sh checks/metrics.sh completion | grep -q '^not complete' || fail 'an open question left it complete'
g checkout -q -- app/main.py
# v0.9.5 (3.1, §7 case 23): an open develop question — a Q<n> line in RUN-STATE — is a strict gap
printf 'run: active\nsession: S1\nquestions: 1 open · next Q2\nslice: 3 closed    since: 2026-09-23T10:00:00Z    commit: x\n\n## Open product questions\n\n- Q1 · asked 2026-09-25T10:00:00Z · gates all remaining work · Is the digest weekly?\n' > .vid/RUN-STATE.md
sh checks/metrics.sh completion | grep -qx 'completion unmet=0 strict-gaps=1' || fail 'an open Q1 is not a strict gap'
sh checks/metrics.sh completion | grep -q '^not complete' || fail 'an open Q1 left it complete'
printf 'run: active\nsession: S1\nquestions: - · next Q2\nslice: 3 closed    since: 2026-09-23T10:00:00Z    commit: x\n\n## Open product questions\n\n' > .vid/RUN-STATE.md
sh checks/metrics.sh completion | grep -qx 'completion unmet=0 strict-gaps=0' || fail 'an answered question left a strict gap'
# one owed seam no client touches
B=$(git rev-parse HEAD)
state '007' "$(row 005 'owed: paid by /vid deploy gate 2 — the platform worker consumes it'; row 007; echo 'seam | SEAM-001 | mailer | receipts | chosen: D-001 | credentials: held | probe: owed | evidence: owed | quirks: none yet')"
sh checks/inventory.sh --report | grep -q '^OWED  SEAM-001 (mailer) — probe: owed' || fail 'the inventory court does not name the owed seam'
sh checks/inventory.sh --report | grep -q 'seam-probes=1)' || fail 'the summary does not count it'
sh checks/metrics.sh completion | grep -qx 'completion unmet=0 strict-gaps=1' || fail 'an owed seam is not a strict gap'
# gated: the same seam under a 0.9.2 block is no debt (0.9.2's reading)
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md
sh checks/inventory.sh --report | grep -q 'OWED  SEAM-001' && fail 'the owed seam was debt under a 0.9.2 block'
exit 0
