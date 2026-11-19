#!/bin/sh
# Purpose: selftest case — the completion report's section 8, "the decisions ViD made on the owner's behalf" (0.26.10.29.5, DP-1 R4),
# checks/end.sh complete on a bare record set (unmet, so the report is written and nothing else). It lists every answer not given by
# the owner, as the stage facts read them: the queue's answers by a delegate, RM and a stand-in, RM's held-row ruling and the round's
# own stand-in ruling; and the DECISIONS.md lines with origin: proposal. It leaves out the owner's answers and rulings, a later head's
# undo, a landing's reset, the hold's second record, and every DECISIONS.md line without origin: proposal. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r4-completion-behalf: $*" >&2; cat "$T/s8" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q; g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p .vid/tw .vid/decide/queue .vid/round; printf '# Run state\n\nrun: active\nstage: 1\n' > .vid/RUN-STATE.md; : > .vid/tw/handed; printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md; printf '.vid/\n' > .gitignore   # 0.26.11.1.2 (R6): an INVENTORY.md with no rows, so the plan's rows read empty, never unreadable
{ printf '# Decisions\n\n'
  printf -- '- **D-001** cursor pagination | why: the dev side chose it | enforced: ticket 4 | scope: project | origin: dev-side\n'
  printf -- '- **D-002** a digest at eight in the morning | why: the owner skipped the choice | enforced: convention | scope: project | origin: proposal\n'
  printf -- '- **D-003** amounts in minor units | why: exactness | enforced: convention | scope: project\n'; } > DECISIONS.md
printf '# PRD\n' > PRD.md; g add -A; g commit -qm root
{ printf '2026-11-11T10:00:00Z\tquestion:5:1\t-\tthe owner own words\towner\tanswered\n'
  printf '2026-11-11T10:01:00Z\tquestion:6:1\t-\tseven days, as the spec says\tdelegate\tdelegated\n'
  printf '2026-11-11T10:02:00Z\tfinding:7:1\tno\tas built is fine\tRM\truled\n'
  printf '2026-11-11T10:03:00Z\tquestion:8:1\t-\tthe round answered for an absent answerer\tstand-in\tdelegated\n'
  printf '2026-11-11T10:04:00Z\theld:ROW-005\ta\t\tRM\taccept\n'
  printf '2026-11-11T10:05:00Z\tcontrol:hold\toff\tbuild on\tdelegate\tdone\n'; } > .vid/decide/queue/answers
printf 'held:ROW-005\tQ3\n' > .vid/decide/queue/ids
{ printf '2026-11-11T10:04:00Z\tROW-005\taccept\t\tRM\n'
  printf '2026-11-11T10:07:00Z\tROW-009-T1\tlimit\t\tstand-in\n'
  printf '2026-11-11T10:08:00Z\tROW-001\taccept\tyes\towner\n'
  printf '2026-11-11T10:09:00Z\tROW-002\tundone\ta later head failed it\tdecide\n'
  printf '2026-11-11T10:10:00Z\tROW-003\treset\tlanded at abc\tSP\n'; } > .vid/decide/rulings
sh "$CHECKS/end.sh" complete > /dev/null 2>&1 || true; [ -f .vid/decide/completion.md ] || fail 'no completion report'
awk '/^## 8\. / { on = 1; next } /^## / { on = 0 } on && /^- /' .vid/decide/completion.md > "$T/s8"
for i in question:6:1 finding:7:1 question:8:1 ROW-005 ROW-009-T1 D-002; do grep -qF -- "$i" "$T/s8" || fail "section 8 misses $i"; done
for i in question:5:1 control:hold ROW-001 ROW-002 ROW-003 D-001 D-003; do ! grep -qF -- "$i" "$T/s8" || fail "section 8 lists $i, the owner's, a reset or undo, the hold's second record, or a decision without origin: proposal"; done
[ "$(grep -c . "$T/s8")" = 6 ] || fail "section 8 is not six lines"
grep -q 'ROW-005.*by RM' "$T/s8" && grep -q 'ROW-009-T1.*by stand-in' "$T/s8" && grep -q 'question:6:1.*by delegate' "$T/s8" || fail 'a line of section 8 does not say who gave it'
exit 0
