#!/bin/sh
# Purpose: selftest case — the brief checker (v0.9.3 spec 3.1, R1, R2; §7
# case 1). The brief-verdict fixture committed into a scratch repository,
# briefs written against its commits. Convicts unless checks/brief.sh:
# passes a well-formed grader brief (slice, end-grade and fix briefs, a
# legacy reversion in the withheld form); convicts a ROW line differing by
# one word (naming the row), a PRD item differing from the effective row, a
# paraphrased law, a missing header field, a grader brief without the
# independence paragraph, with item 7, a .vid/verdicts/ path, a result=
# token, a legacy reason verbatim, or without the read exclusion; convicts a
# builder brief without item 7 for a row that has an attempt record and
# passes it with the record quoted; passes a test-author brief at init
# quoting rows only in the working tree, and one quoting a row absent
# everywhere with `pending-birth:` (convicted without); holds an item that
# exists only in the working tree to `pending-append:`; reads a legacy
# `### REQ-NNN` block; with `--at HEAD` sees no difference after a
# `proved-red` stamp on an unrelated row and the difference after an
# obligation edit on a quoted row; records `brief-check` events; and
# metrics.sh counts a verdict naming an unchecked brief after `slice-open`
# in `verdicts-without-brief` and never a legacy verdict. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
cp -R "$CHECKS/selftest/fixtures/brief-verdict/tree/." .
mkdir -p checks; cp "$CHECKS/brief.sh" "$CHECKS/prd.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
g add -A && g commit -qm root; Q=$(git rev-parse --short=12 HEAD)
HDRP='Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.'
row() { grep "^$1 " INVENTORY.md; }
item() { grep "^$1 " PRD.md; }
brief() { # $1=role $2=slice $3=extra header $4=section-7 text $5=tail text
  printf 'role: %s    slice: %s\nquoted-at: %s\nreceives: items 1–6    must not receive: item 7, .vid/verdicts/\n%s\n' "$1" "$2" "$Q" "$3"
  case "$1" in grader|test-author) printf '%s\n\n' "$HDRP" ;; esac
  printf '## 1 rows\n%s\n%s\n' "$(row ROW-102)" "$(row ROW-103)"
  printf '## 2 items\n%s\n%s\n' "$(item REQ-002)" "$(item REQ-003)"
  d=$(grep '^- \*\*D-005\*\*' DECISIONS.md); [ "$1" = grader ] && d=${d%% | why:*}   # v0.9.7.0.5: a grader gets the rule part
  printf '## 3 decisions\n%s\n' "$d"
  printf '## 4 laws\n%s\n' "$(grep '^- The ledger runs ONLY' CLAUDE.md)"
  printf '## 5 start and receipt\nstart: %s    receipt: .vid/ledger-results/%s.full.xml\n' "$Q" "$Q"
  printf '## 6 test requests\nsh checks/test.sh request --type iterate --role orchestrator --rows ROW-001 --why "a disputed result" -- tests/invariants/links.sh\n'   # v0.9.7.0.2: section 6 lists requests
  [ -n "$4" ] && printf '## 7 attempt record\n%s\n' "$4"
  printf '%s\n## 8 further reading (optional)\nPRD.md · DECISIONS.md · ARCHITECTURE.md\n' "$5"
}
EXCL='Do not read under `.vid/` beyond the receipt named above.'
ok() { sh checks/brief.sh "$@" >out.txt 2>&1 || { echo "brief: acquittal expected — $*" >&2; cat out.txt >&2; exit 1; }; }
no() { if sh checks/brief.sh "$1" >out.txt 2>&1; then echo "brief: conviction expected — $2" >&2; cat "$1" >&2; exit 1; fi; grep -qF -- "$3" out.txt || { echo "brief: $2 — not named as '$3'" >&2; cat out.txt >&2; exit 1; }; }
mkdir -p .vid/briefs/7
# a well-formed grader brief, in three verbs' slices
for sl in 7 end-grade fix-2026-09-23; do
  brief grader "$sl" '' '' "$EXCL
ROW-105's sibling: owed: reverted — (detail withheld from graders)" > ".vid/briefs/7/grader-$sl.md"
  ok ".vid/briefs/7/grader-$sl.md"
done
G=.vid/briefs/7/grader-7.md
# a row differing by one word
sed 's/refused and nothing is stored/refused and nothing is kept/' "$G" > b1.md; no b1.md 'a paraphrased row' 'row ROW-102: not byte-identical'
# a Fail-if differing from the effective row
sed 's/fail-if: a target whose scheme is not http or https is accepted/fail-if: a non-web target is accepted/' "$G" > b2.md; no b2.md 'a paraphrased Fail-if' 'item REQ-002: not byte-identical'
# a paraphrased law
sed 's/^- The ledger runs ONLY via `sh checks\/test.sh`. It must be green at every commit./- Run the ledger through the wrapper./' "$G" > b3.md; no b3.md 'a paraphrased law' 'law: not a line of CLAUDE.md'
# a missing header field
sed '/^quoted-at:/d' "$G" > b4.md; no b4.md 'a missing header' "no 'quoted-at:' line"
# the grader's withholding
grep -v -e '^Spawned as a SEPARATE' -e '^authoring-session' -e '^this file lists' -e '^a re-run is never' -e '^anything the calling' -e '^Independence is a mechanism' "$G" > b5.md; no b5.md 'no paragraph' 'independence paragraph'
brief grader 7 '' 'slice 5 BREACHED class=product: ftp:// accepted' "$EXCL" > b6.md; no b6.md 'a grader with item 7' 'carries item 7'
brief grader 7 '' '' "$EXCL
see .vid/verdicts/ROW-102.md" > b7.md; no b7.md 'a verdicts path' '.vid/verdicts/ path'
brief grader 7 '' '' "$EXCL
last close: result=BREACHED" > b8.md; no b8.md 'a result token' 'result= token'
brief grader 7 '' '' "$EXCL
ROW-105's sibling: owed: reverted — \"the resolver answered 302 after expiry\"" > b9.md; no b9.md 'a legacy reason' 'a legacy reversion reason travels'
brief grader 7 '' '' '' > b10.md; no b10.md 'no read exclusion' 'no stated read exclusion'
# the attempt record travels to a builder
mkdir -p .vid/verdicts; printf 'slice 5 · BREACHED · product · ftp://example.org accepted and stored\nslice 6 · repair: _scheme_ok → allowlist, commit abc1234\n' > .vid/verdicts/ROW-102.md
brief builder 7 '' '' '' > b11.md; no b11.md 'a builder without the attempt record' 'has an attempt record'
brief builder 7 '' "$(cat .vid/verdicts/ROW-102.md)" '' > b12.md; ok b12.md
# test-author at init: rows only in the working tree, a row absent everywhere
sed 's/^ROW-108 .*/&\nROW-109 | behavior | REQ-011 | anonymous | n\/a | two codes differing only in case are two links | REQ-011 | owed: prerequisite — paid at slice 2/' INVENTORY.md > i && mv i INVENTORY.md
{ printf 'role: test-author    slice: init\nquoted-at: %s\nreceives: the rows    must not receive: application source\n\n%s\n\n## 1 rows\n%s\n' "$Q" "$HDRP" "$(row ROW-109)"; } > ta1.md; ok ta1.md
{ printf 'role: test-author    slice: init\nquoted-at: %s\nreceives: the rows    must not receive: application source\npending-birth: ROW-110\n\n%s\n\n## 1 rows\nROW-110 | behavior | REQ-013 | anonymous | n/a | the token is shown once | REQ-013 | owed: prerequisite — paid at slice 2\n' "$Q" "$HDRP"; } > ta2.md; ok ta2.md
grep -v '^pending-birth:' ta2.md > ta3.md; no ta3.md 'a row absent everywhere without pending-birth' 'not listed pending-birth:'
# an item only in the working tree: pending-append
printf '```vid-prd\nREQ-030 | functional | T1 | Deletion answers within a second. | fail-if: a deletion takes longer | serves: trust | phase: pilot\n```\n' >> PRD.md
{ printf 'role: test-author    slice: fix-2026-09-23\nquoted-at: %s\nreceives: the rows    must not receive: application source\n\n%s\n\n## 2 items\n%s\n' "$Q" "$HDRP" "$(grep '^REQ-030 ' PRD.md)"; } > ta4.md
no ta4.md 'an appended item without pending-append' 'list it pending-append:'
sed 's/^receives:/pending-append: REQ-030\nreceives:/' ta4.md > ta5.md; ok ta5.md
g checkout -q -- PRD.md INVENTORY.md
# --at HEAD: a proved-red stamp on an unrelated row changes nothing; an obligation edit on a quoted row is the difference
sed 's/^\(ROW-101 .*\)$/\1 | proved-red: '"$Q"'/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'stamp ROW-101'
ok "$G" --at HEAD
sed 's/a link older than thirty days answers 410 gone, never a redirect/a link older than thirty days answers 410 gone/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'ROW-103 obligation'
if sh checks/brief.sh "$G" --at HEAD >out.txt 2>&1; then echo 'brief: --at HEAD missed an obligation edit on a quoted row' >&2; exit 1; fi
grep -q 'row ROW-103: not byte-identical' out.txt || { cat out.txt >&2; exit 1; }
ok "$G"                                                           # at its own quoted-at it is still well-formed
# a legacy PRD block
printf '# Old\n\n### REQ-002 (T0) — web targets only\nOnly web addresses are accepted.\n**Fail-if:** a target whose scheme is not http or https is accepted.\n\n### REQ-003 (T1) — expiry\nThirty days.\n**Fail-if:** an old link redirects.\n' > PRD.md; g commit -qam 'legacy PRD'; Q=$(git rev-parse --short=12 HEAD)
{ printf 'role: grader    slice: 8\nquoted-at: %s\nreceives: items 1–6    must not receive: item 7\n\n%s\n\n## 2 items\n### REQ-002 (T0) — web targets only\nOnly web addresses are accepted.\n**Fail-if:** a target whose scheme is not http or https is accepted.\n\n%s\n' "$Q" "$HDRP" "$EXCL"; } > l1.md; ok l1.md
sed 's/is not http or https is accepted\./is not a web scheme is accepted./' l1.md > l2.md; no l2.md 'a paraphrased legacy block' "item block '### REQ-002"
# the events and the FLAG line
grep -q "^brief-check path=$G result=ok" .vid/metrics-events || { echo 'brief: no brief-check ok event' >&2; exit 1; }
grep -q '^brief-check path=b1.md result=fail' .vid/metrics-events || { echo 'brief: no brief-check fail event' >&2; exit 1; }
cat >> .vid/metrics-events <<EV
verdict slice=6 row=ROW-101 result=KEPT
slice-open slice=7 sha=$Q
verdict slice=7 row=ROW-102 result=BREACHED class=product brief=$G quoted-at=$Q
verdict slice=7 row=ROW-103 result=BREACHED class=test brief=.vid/briefs/7/grader-unchecked.md quoted-at=$Q
EV
sh checks/metrics.sh 2>/dev/null | grep -q '^honesty FLAG verdicts-without-brief n=1 ' || { echo 'brief: the unchecked brief is not counted once (the legacy verdict must not be)' >&2; sh checks/metrics.sh 2>/dev/null | grep -i brief >&2; exit 1; }
exit 0
