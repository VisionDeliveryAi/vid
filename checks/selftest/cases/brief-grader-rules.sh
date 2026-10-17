#!/bin/sh
# Purpose: selftest case — a grader gets a decision's rule, never its why
# (v0.9.7.0.5 spec 3.4, R5; §6 W-6). The brief-verdict fixture committed
# into a scratch repository. Convicts unless checks/brief.sh: refuses a
# grader brief whose section 3 quotes a whole decision line (` | why:`
# included), naming it; refuses a rule that is not the rule part of a
# decision line — a reworded one, and a truncated one (the rule is matched
# whole); passes a grader brief quoting the rule part, the line up to
# ` | why:`; passes a fixer brief quoting the whole line; and applies the
# same rule under `--at HEAD`, the observer's read. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
cp -R "$CHECKS/selftest/fixtures/brief-verdict/tree/." .
mkdir -p checks; cp "$CHECKS/brief.sh" "$CHECKS/prd.sh" checks/
printf '.vid/\n' > .gitignore
g add -A && g commit -qm root; Q=$(git rev-parse --short=12 HEAD)
HDR=$(sed -n "s/^HDR='\(.*\)'$/\1/p" checks/brief.sh)
EXCL='Do not read under `.vid/` beyond the receipt named above.'
WHOLE=$(grep '^- \*\*D-005\*\*' DECISIONS.md)
RULE=${WHOLE%% | why:*}
brief() { # $1=role $2=the section-3 line
  printf 'role: %s    slice: 7\nquoted-at: %s\nreceives: items 1–6    must not receive: item 7\n\n' "$1" "$Q"
  [ "$1" = grader ] && printf '%s\n\n%s\n\n' "$HDR" "$EXCL"
  printf '## 1 rows\n%s\n## 3 decisions\n%s\n## 5 start and receipt\nstart: %s\n' "$(grep '^ROW-102 ' INVENTORY.md)" "$2" "$Q"
}
ok() { sh checks/brief.sh "$@" >out.txt 2>&1 || { echo "brief-grader-rules: acquittal expected — $*" >&2; cat out.txt >&2; exit 1; }; }
no() { if sh checks/brief.sh "$1" >out.txt 2>&1; then echo "brief-grader-rules: conviction expected — $2" >&2; exit 1; fi; grep -qF -- "$3" out.txt || { echo "brief-grader-rules: $2 — not named as '$3'" >&2; cat out.txt >&2; exit 1; }; }
[ "$RULE" != "$WHOLE" ] || { echo 'brief-grader-rules: the fixture decision has no why' >&2; exit 1; }
brief grader "$WHOLE" > g1.md; no g1.md 'a grader brief with a whole decision line' "a grader gets a decision's rule, never its why"
grep -qF -- "$WHOLE" out.txt || { echo 'brief-grader-rules: the refusal does not name the line' >&2; exit 1; }
brief grader "- **D-005** a refused scheme answers \"refused\"" > g2.md; no g2.md 'a reworded rule' 'not the rule part of a decision line'
brief grader "${RULE% *}" > g3.md; no g3.md 'a truncated rule' 'not the rule part of a decision line'
brief grader "$RULE" > g4.md; ok g4.md
brief fixer "$WHOLE" > f1.md; ok f1.md
brief fixer "$RULE" > f2.md; no f2.md 'a fixer brief with the rule only' 'not present verbatim in DECISIONS.md'
# the observer's read (--at HEAD) applies the same rule
sed 's/^\(ROW-101 .*\)$/\1 | proved-red: '"$Q"'/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'stamp ROW-101'
ok g4.md --at HEAD
if sh checks/brief.sh g1.md --at HEAD >out.txt 2>&1; then echo 'brief-grader-rules: --at HEAD passed a whole decision line in a grader brief' >&2; exit 1; fi
grep -qF "never its why" out.txt || { cat out.txt >&2; exit 1; }
exit 0
