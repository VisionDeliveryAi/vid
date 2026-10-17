#!/bin/sh
# Purpose: selftest case — the labelling pass proposes (v0.9.7.3 spec 3.3, R3). `decisions.sh propose` lists the
# unlabelled decisions citing no ROW, REQ or RULE id (D-002, D-003, D-005, D-006 — never D-001, which cites ROW-001,
# nor the labelled D-004), each with its text hash, in a new brief .vid/briefs/labels-1.md for a general-purpose agent
# that changes no file: the return form and the items a label may name (the screen code LOGIN, DIF-001, the rule
# rows, the REQ ids rows derive from). `--all` (init's pass) adds D-001; a second pass is labels-2.md; with nothing
# left, it writes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "labels-propose: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files; g add -A && g commit -qm toy
sh checks/decisions.sh propose > .vid/out 2>&1 || fail 'propose failed'
grep -q '^propose: 4 decisions → .vid/briefs/labels-1.md$' .vid/out || fail 'not four decisions into labels-1.md'
B=.vid/briefs/labels-1.md
for d in D-002 D-003 D-005 D-006; do grep -q "^$d $(lb_hash $d) | - \*\*$d\*\*" "$B" || fail "$d is not listed with its text hash"; done
grep -q '^D-001 \|^D-004 ' "$B" && fail 'a decision citing an id, or a labelled one, is listed'
grep -q 'general-purpose' "$B" && grep -q 'you change no file' "$B" || fail 'the brief does not say who reads it and that it edits nothing'
grep -qF 'D-NNN <hash> | applies-to: <items> | sure' "$B" || fail 'the return form is missing'
grep -q 'LOGIN (1)' "$B" && grep -q 'DIF-001' "$B" && grep -q '^- RULE-001 ' "$B" && grep -q 'REQ-001 REQ-002' "$B" || fail 'the items a label may name are missing'
sh checks/decisions.sh propose --all > .vid/out 2>&1; grep -q '5 decisions → .vid/briefs/labels-2.md' .vid/out || fail '--all did not add D-001 into labels-2.md'
grep -q "^D-001 $(lb_hash D-001) " .vid/briefs/labels-2.md || fail '--all does not list D-001'
sed 's/enforced: convention$/enforced: convention | scope: project/; s#test_gone.py$#test_gone.py | scope: project#; s/| origin: proposal$/| scope: project | origin: proposal/' DECISIONS.md > x && mv x DECISIONS.md
sh checks/decisions.sh propose > .vid/out 2>&1; grep -q '^propose: no decision to label$' .vid/out || fail 'a pass with nothing to label said otherwise'
[ ! -e .vid/briefs/labels-3.md ] || fail 'a brief was written with nothing to label'
exit 0
