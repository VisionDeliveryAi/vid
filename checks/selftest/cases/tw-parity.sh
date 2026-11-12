#!/bin/sh
# Purpose: selftest case — the ticket carries develop's builder brief, W11 (v0.26.10.12.3): a ticket does exactly what develop does. On TW's toy, TW writes S05's ticket (ROW-017
# alone) and S03's (five ROW rows, three rules, three hostility rows and a seam); in a copy of the toy outside any plan
# session, develop's own `brief.sh write --role builder` (fixtures/brief-write.sh's plugin) writes the builder brief of
# the same step and the same ROW rows, develop's writer taking ROW rows only. S05: the ticket's quoted Rows, Requirements,
# Decisions, Rules and step lines equal the brief's sections 1, 2, 3, 11 and 10, but for §1.1's named differences: the
# golden: field a ticket leaves out; the answers, which develop's builder brief does not carry; the plan's shared: line;
# §10's `plan:` line; and Amendment 1's rewrites (v0.26.10.12.3.1): no `owed: prerequisite` note, "(ViD's records)" for a
# .vid/ path or an artifact link, the owner's chosen or confirmed words and an answer's quote stated by id. S03: each ROW row's line equals section 1's; each other row's equals its inventory line less a
# one-path census, a seam's evidence path, module: and match:; sections 2, 3 and 11 hold in order within the ticket's,
# whose other lines come only from the rows develop gives no builder brief; the step lines are equal. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-parity: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; V=$(pwd -P); tw_skel || fail 'the skeleton round failed'
PH=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p')
tw_start S02 || fail 'S02 was refused'; tw_start S03 || fail 'S03 was refused'
printf 'step-start step=S05 plan=%s base=x at=2026-11-03T10:00:00Z\n' "$PH" >> .vid/metrics-events   # a stand-in admission of the stage-2 step
tw_post step S03 || fail "S03's ticket was refused"; T3=$TW_F; F5=$(sh "$CHECKS/writer.sh" write step S05 2> "$T/werr") || fail "S05's ticket was refused"
# develop's builder briefs, in a copy outside the plan session
cp -R "$V" "$T/devcopy"; cd "$T/devcopy"; printf 'stage name=plan state=end session=S1 at=2026-11-03T11:00:00Z\n' >> .vid/metrics-events
mkdir -p checks; cp "$CHECKS/brief.sh" "$CHECKS/prd.sh" "$CHECKS/plan.sh" checks/
. "$CHECKS/selftest/fixtures/brief-write.sh"; bw_plugin
brief() { sh checks/brief.sh write --role builder --slice "$1" --step "$2" --rows "$3" --selection tests > "$T/wout" 2>&1 || true; B=$(bw_out); [ -f "$B" ] || { cat "$T/wout" >&2; fail "develop wrote no builder brief for $2"; }; }
dsec() { awk -v n="$2" '/^## [0-9]/ { on = ($2 == n); next } on' "$1" | grep -v '^[[:space:]]*$' || true; }
tsec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1" | sed -n 's/^> //p'; }
treq() { awk '$0 == "## Requirements" { on = 1; next } on && /^The answers they cite:/ { exit } on' "$1" | sed -n 's/^> //p'; }
same() { cmp -s "$1" "$2" || { diff "$1" "$2" >&2; fail "$3"; }; }
a1() { sed -e 's/ | owed: prerequisite[^|]*|/ |/' -e 's/owner chose:\{0,1\} "[^"]*"\(,\{0,1\} \(and \)\{0,1\}"[^"]*"\)*/chosen by the owner/g' -e 's/owner: "[^"]*"/confirmed by the owner/g' \
  -e 's/A: "[^"]*"; /A: /g' -e "s#\(https\{0,1\}://\)\{0,1\}claude\.ai/[^ )]*artifact/[A-Za-z0-9_-]*#(ViD's records)#g" -e "s#[^ \"(),;]*\.vid/[^ \"(),;]*#(ViD's records)#g"; }   # Amendment 1's rewrites
# S05: equal but for the named differences
brief 1 S05 ROW-017; B5=$B
dsec "$B5" 1 | a1 | sed -e 's/ | golden: [^|]*| / | /' -e 's/ | golden: [^|]*$//' > "$T/d1"; tsec "$F5" Rows > "$T/t1"; same "$T/d1" "$T/t1" "S05's rows are not develop's section 1 less the golden: field"
dsec "$B5" 2 | a1 > "$T/d2"; treq "$F5" > "$T/t2"; same "$T/d2" "$T/t2" "S05's requirements are not develop's section 2"
dsec "$B5" 3 | a1 > "$T/d3"; tsec "$F5" Decisions > "$T/t3"; same "$T/d3" "$T/t3" "S05's decisions are not develop's section 3"
dsec "$B5" 11 > "$T/d11"; tsec "$F5" 'Rules that bear on these rows' > "$T/t11"; same "$T/d11" "$T/t11" "S05's rules are not develop's section 11"
dsec "$B5" 10 | grep -v '^plan: ' > "$T/d10"; tsec "$F5" 'The step' | grep -v '^shared: ' > "$T/t10"; same "$T/d10" "$T/t10" "S05's step lines are not develop's section 10"
[ -s "$T/d1" ] && [ -s "$T/d2" ] && [ -s "$T/d10" ] || fail 'the S05 comparison compared nothing'
grep -q '^> shared: web$' "$F5" || fail 'the ticket lacks the plan'"'"'s shared: line'
# S03: the ROW rows against develop's section 1, the other kinds against their own inventory lines
brief 2 S03 ROW-006,ROW-007,ROW-010,ROW-014,ROW-019; B3=$B
tsec "$T3" Rows | grep '^ROW-' > "$T/t1"; dsec "$B3" 1 | a1 > "$T/d1"; same "$T/d1" "$T/t1" "S03's ROW rows are not develop's section 1"
tsec "$T3" Rows | grep -v '^ROW-' > "$T/t1o"
for id in RULE-001 RULE-002 RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005; do grep "^[a-z]* | $id |" INVENTORY.md; done |
  sed -e 's# | checks/extractors/invariant.unsubscribe.sh | # | #' -e 's# | evidence: tests/contract/[^|]*| # | #' -e 's# | module: [^|]*| # | #' -e 's# | match: [^|]*$##' > "$T/i1o"
same "$T/i1o" "$T/t1o" "S03's other rows are not their inventory lines less the fields a ticket leaves out"
within() { awk 'NR == FNR { W[++n] = $0; next } k < n && $0 == W[k + 1] { k++ } END { exit !(k == n) }' "$1" "$2" || fail "$3"; }
treq "$T3" > "$T/t2"; dsec "$B3" 2 | a1 > "$T/d2"; within "$T/d2" "$T/t2" "develop's section 2 is not, in order, within S03's requirements"
grep -vxF -f "$T/d2" "$T/t2" | cut -d'|' -f1 | tr -d ' ' > "$T/x2"; [ "$(paste -sd ' ' "$T/x2")" = 'INV-002' ] || fail "S03's requirements beyond develop's are $(paste -sd ' ' "$T/x2"), not INV-002 alone (HOS-005's)"
tsec "$T3" Decisions > "$T/t3"; dsec "$B3" 3 | a1 > "$T/d3"; within "$T/d3" "$T/t3" "develop's section 3 is not, in order, within S03's decisions"
tsec "$T3" 'Rules that bear on these rows' > "$T/t11"; dsec "$B3" 11 | sed "s# | checks/extractors/[^ ]* | # | (ViD's records) | #" > "$T/d11"; within "$T/d11" "$T/t11" "develop's section 11 is not, in order, within S03's rules"
dsec "$B3" 10 | grep -v '^plan: ' > "$T/d10"; tsec "$T3" 'The step' | grep -v '^shared: ' > "$T/t10"; same "$T/d10" "$T/t10" "S03's step lines are not develop's section 10"
exit 0
