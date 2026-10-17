#!/bin/sh
# Purpose: selftest case — the design-vs-PRD consistency pass (v0.9.1 spec
# 3.3), static half. (1) design-join.sh refuses a DESIGN-AMENDMENT-BRIEF.md
# that is not closed — an unruled line, or a `PRD wins` / `both change`
# line not landed — and passes a closed one, an absent one, and a
# `design wins` line merely ruled; a brief without its machine block fails
# closed. (2) In the plugin repository: every calibration pack under
# skills/vid-design/selftest/fixtures/ joins clean against its manifest and
# carries an expected.md, the shared PRD is court-green, and pass-check.sh
# convicts a known-bad output and acquits a known-good one — so the
# checker is never vacuous. The stochastic half (a fresh agent reviews, the
# checker judges) runs procedurally and lands in the build notes, never
# here. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '# brief\n```vid-design-manifest\nP01 | default | REQ-001\n```\n' > DESIGN-BRIEF.md
mkdir -p design/screens
printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<section>{{ title }}</section>\n' > design/screens/p01.html
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1          # the pack alone joins clean
amend() { printf '# amendment brief\n```vid-design-amendments\n%s\n```\n' "$1" > DESIGN-AMENDMENT-BRIEF.md; }
amend 'D-01 | P01/default | REQ-001 | canvas says: two titles | row says: one title | ruling: - | status: open'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 && exit 1          # an unruled line refuses
amend 'D-01 | P01/default | REQ-001 | canvas says: two titles | row says: one title | ruling: PRD wins | status: ruled'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 && exit 1          # PRD wins, not landed, refuses
amend 'D-01 | P01/default | REQ-001 | canvas says: two titles | row says: one title | ruling: both change | status: ruled'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 && exit 1          # both change, not landed, refuses
amend 'D-01 | P01/default | REQ-001 | canvas says: two titles | row says: one title | ruling: PRD wins | status: landed
D-02 | P01/default | REQ-001 | canvas says: a subtitle | row says: no subtitle named | ruling: design wins | status: ruled
D-03 | P01/default | REQ-001 | canvas says: grey title | row says: nothing on colour | ruling: not a disagreement | status: ruled'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1          # closed brief passes
printf '# amendment brief without its block\n' > DESIGN-AMENDMENT-BRIEF.md
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 && exit 1          # no block fails closed
rm DESIGN-AMENDMENT-BRIEF.md
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1          # no brief: nothing to refuse

# --- the calibration packs (plugin repository only) ---
CAL="$CHECKS/../skills/vid-design/selftest"
if [ -d "$CAL" ]; then
  sh "$CHECKS/prd.sh" "$CAL/fixtures/shortlink-PRD.md" >/dev/null 2>&1 || { echo 'design-consistency: the shared fixture PRD is not court-green'; exit 1; }
  for fx in forbidden-control clean-pack two-round configured-value; do
    [ -f "$CAL/fixtures/$fx/expected.md" ] || { echo "design-consistency: pack $fx has no expected.md"; exit 1; }
    ( cd "$CAL/fixtures/$fx" && sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 ) || { echo "design-consistency: pack $fx does not join clean"; exit 1; }
  done
  [ -f "$CAL/fixtures/two-round/delta/p03.html" ] || { echo 'design-consistency: two-round has no delta canvas'; exit 1; }
  printf '```vid-design-disagreements\n```\n' > "$T/empty.md"
  printf '```vid-design-disagreements\nP03/default · REQ-006, NG-001 · canvas says: an Edit target control beside Remove · row says: one Remove control; no editing of a target\n```\n' > "$T/a.md"
  printf '```vid-design-disagreements\nP03/default · P02/default · canvas says: footer address help@shortlink.example · canvas says: footer address support@shortlink.example\n```\n' > "$T/b.md"
  printf 'no block\n' > "$T/none.md"
  sh "$CAL/pass-check.sh" "$CAL/fixtures/forbidden-control" "$T/a.md" >/dev/null 2>&1 || exit 1      # the one line acquits the forbidden control
  sh "$CAL/pass-check.sh" "$CAL/fixtures/forbidden-control" "$T/empty.md" >/dev/null 2>&1 && exit 1  # silence convicts it
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-pack" "$T/empty.md" >/dev/null 2>&1 || exit 1         # the empty block acquits the clean pack
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-pack" "$T/a.md" >/dev/null 2>&1 && exit 1             # a line convicts it
  sh "$CAL/pass-check.sh" "$CAL/fixtures/two-round" "$T/b.md" >/dev/null 2>&1 || exit 1              # the class-b line acquits the two-round pack
  sh "$CAL/pass-check.sh" "$CAL/fixtures/two-round" "$T/a.md" >/dev/null 2>&1 && exit 1              # a class-a line on it convicts
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-pack" "$T/none.md" >/dev/null 2>&1 && exit 1          # no block is no verdict — fails closed
  # class (c), v0.9.2 3.13: the configured-value pack reads its own PRD (court-green); its one class-(c) line acquits, silence and a class-(a) line convict
  sh "$CHECKS/prd.sh" "$CAL/fixtures/configured-value/PRD.md" >/dev/null 2>&1 || { echo 'design-consistency: the configured-value PRD is not court-green'; exit 1; }
  printf '```vid-design-disagreements\nP03/default · REQ-025 · canvas asserts: support@shortlink.example in the footer · row makes it: operator-entered at deployment (A-016)\n```\n' > "$T/c.md"
  sh "$CAL/pass-check.sh" "$CAL/fixtures/configured-value" "$T/c.md" >/dev/null 2>&1 || exit 1        # the class-(c) line acquits
  sh "$CAL/pass-check.sh" "$CAL/fixtures/configured-value" "$T/empty.md" >/dev/null 2>&1 && exit 1    # silence convicts
  sh "$CAL/pass-check.sh" "$CAL/fixtures/configured-value" "$T/a.md" >/dev/null 2>&1 && exit 1        # a class-(a) line on the wrong item convicts
fi
exit 0
