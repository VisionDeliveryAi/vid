#!/bin/sh
# Purpose: selftest case — the mark on a replaced decision line, written by /vid incorporate's helper (IR I2). On a toy
# project, `incorporate.sh mark <old> <new>` puts `| replaced-by: <new>` in the old line's rule part, right before ` | why:`,
# and changes none of its words. An old line with no label the commit hook accepts is labelled first, by
# `decisions.sh apply` on a proposals file holding that line alone, so no other unlabelled line is labelled (the label
# given with --label, else `scope: project`); a well-labelled line is marked without a labelling pass. A second mark
# extends the ids in the order added; an id already there changes nothing. Refused: a new id DECISIONS.md lacks, an old
# id it lacks, the same id twice, a line with no ` | why:` field. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "incorporate-mark: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q
printf '.vid/\nout\nd1\nd2\n' > .gitignore
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | an item is stored once\nREQ-002 | functional | T1 | a run is written whole\n```\n' > PRD.md
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | items | (process) | n/a | an item is stored once | REQ-001 | owed: spec-only — ticket\nROW-002 | behavior | runs | (process) | n/a | a run is written whole | REQ-002 | owed: spec-only — ticket\n```\n' > INVENTORY.md
printf '# Architecture\n\n| Module | Owns |\n|---|---|\n| `feed/store` | the stored items |\n' > ARCHITECTURE.md
cat > DECISIONS.md <<'X'
# DECISIONS

## Log

- **D-001** items are keyed by their source id | why: one key | enforced: convention | applies-to: REQ-001
- **D-002** each run writes a table of its own | why: runs stay apart | enforced: convention
- **D-003** times are kept in UTC | why: one clock | enforced: convention
- **D-004** a run's notes have no reason given | enforced: convention
X
g add -A && g commit -qm toy
# the amendment's new lines, in the working tree
printf -- '- **D-005** every run writes one shared table | why: the record | enforced: convention | applies-to: REQ-002\n- **D-006** the shared table has one writer | why: the record | enforced: convention | applies-to: REQ-002\n' >> DECISIONS.md
H=$CHECKS/incorporate.sh
# an unlabelled line: labelled alone, then marked; its words kept
sh "$H" mark D-002 D-005 > "$T/out" 2>&1 || fail 'mark of the unlabelled D-002 was refused'
grep -qxF -- '- **D-002** each run writes a table of its own | replaced-by: D-005 | why: runs stay apart | enforced: convention | scope: project' DECISIONS.md || fail "D-002 is not labelled and marked as the form says: $(grep -F 'D-002**' DECISIONS.md)"
grep -qxF -- '- **D-003** times are kept in UTC | why: one clock | enforced: convention' DECISIONS.md || fail 'D-003, another unlabelled line, was changed'
[ "$(grep -c . .vid/decision-labels.applied)" = 1 ] && grep -q '^D-002	scope: project	' .vid/decision-labels.applied || fail 'the labelling pass did not label D-002 alone'
# a second mark extends the ids, in the order added; an id there already changes nothing
sh "$H" mark D-002 D-006 > "$T/out" 2>&1 || fail 'a second mark on D-002 was refused'
grep -qxF -- '- **D-002** each run writes a table of its own | replaced-by: D-005, D-006 | why: runs stay apart | enforced: convention | scope: project' DECISIONS.md || fail "the second mark does not extend the first: $(grep -F 'D-002**' DECISIONS.md)"
cp DECISIONS.md "$T/d1"
sh "$H" mark D-002 D-005 > "$T/out" 2>&1 || fail 'a mark naming an id already there was refused'
cmp -s DECISIONS.md "$T/d1" || fail 'a mark naming an id already there changed DECISIONS.md'
# a well-labelled line: marked, with no labelling pass
sh "$H" mark D-001 D-005 > "$T/out" 2>&1 || fail 'mark of the labelled D-001 was refused'
grep -qxF -- '- **D-001** items are keyed by their source id | replaced-by: D-005 | why: one key | enforced: convention | applies-to: REQ-001' DECISIONS.md || fail "D-001 is not marked as the form says: $(grep -F 'D-001**' DECISIONS.md)"
[ "$(grep -c . .vid/decision-labels.applied)" = 1 ] || fail 'a well-labelled line went through the labelling pass'
# --label: the label the labelling pass writes, when the old line has none
sh "$H" mark D-003 D-006 --label 'applies-to: REQ-001' > "$T/out" 2>&1 || fail 'mark with --label was refused'
grep -qxF -- '- **D-003** times are kept in UTC | replaced-by: D-006 | why: one clock | enforced: convention | applies-to: REQ-001' DECISIONS.md || fail "D-003 is not labelled with the label given: $(grep -F 'D-003**' DECISIONS.md)"
# the refusals, each leaving DECISIONS.md as it was
cp DECISIONS.md "$T/d2"
for a in 'D-002 D-009' 'D-009 D-005' 'D-005 D-005' 'D-004 D-005'; do
  # shellcheck disable=SC2086
  if sh "$H" mark $a > "$T/out" 2>&1; then fail "mark $a was not refused"; fi
  grep -q 'refused' "$T/out" || fail "mark $a gave no refusal"
  cmp -s DECISIONS.md "$T/d2" || fail "the refused mark $a changed DECISIONS.md"
done
echo 'incorporate-mark: ok'
