#!/bin/sh
# Purpose: selftest case — a new decision line carries a label (v0.9.7.3 spec 3.1, R1). Under the real hook with stub
# courts: a new line with neither `| applies-to:` nor `| scope: project` is refused (by=decisions-label in hook-times);
# `scope:` with anything but project, and a line carrying both labels, are refused; `| scope: project` passes; an
# unlabelled legacy line already at HEAD is not refused while it is unchanged. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "decision-label-required: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\nrule | RULE-001 | sessions expire | grep x | 0 | owed: census-armed — later | origin: REQ-001\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** legacy, unlabelled | why: old | enforced: convention\n' > DECISIONS.md
g add -A && g commit -qm 'legacy decisions'
# try <line>: append it to DECISIONS.md, stage, run the hook; the outcome; the file restored
try() { cp DECISIONS.md "$T/.vid/dec"; printf '%s\n' "$1" >> DECISIONS.md; g add DECISIONS.md
  if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then r=pass; else r=refused; fi
  cp "$T/.vid/dec" DECISIONS.md; g add DECISIONS.md; echo "$r"; }
[ "$(try '- **D-002** sessions last a day | why: support load | enforced: convention')" = refused ] || fail 'a new unlabelled line passed'
grep -q 'no label' "$T/.vid/out" || fail 'the refusal does not say the line has no label'
tail -n 1 .vid/hook-times | grep -q ' by=decisions-label ' || fail 'hook-times does not name decisions-label'
[ "$(try '- **D-002** sessions last a day | why: support load | enforced: convention | scope: everything')" = refused ] || fail 'scope: other than project passed'
[ "$(try '- **D-002** sessions last a day | why: support load | enforced: convention | scope: project | applies-to: ROW-001')" = refused ] || fail 'a line with both labels passed'
[ "$(try '- **D-002** sessions last a day | why: support load | enforced: convention | scope: project')" = pass ] || fail 'scope: project was refused'
[ "$(try '- **D-002** sessions last a day | why: support load | enforced: convention | scope: project | origin: proposal')" = pass ] || fail 'a label followed by origin: was refused'
grep -q 'D-001' "$T/.vid/out" && fail 'the unchanged legacy line was judged'
exit 0
