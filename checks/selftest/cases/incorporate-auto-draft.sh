#!/bin/sh
# Purpose: selftest case — an incorporation landed in GitHub auto through checks/land.sh (IR I5, its case incorporate-auto-draft), on
# the writer's toy and the fake gh, under the real pre-commit hook (stub courts, the real decision-label join and law files). The
# skeleton's ticket is closed; S02's ticket (modules ingest and digest) is open. First, a draft that adds a module to ARCHITECTURE.md
# and a decision labelled with it passes its dry run: the architecture lands before the decisions, so the label finds the module in
# the staged module table (under the old order the hook refused it). Then the incorporation: its why begins `/vid incorporate:`, its
# map is required there and refused on any other draft; the draft adds the module, a stack line to BASELINE.md, a decision line
# labelled with the new module and with ingest (S02's), one new row in a new step and a line of PLAN.md. The map is kept beside the
# review, its counts in the count and the ask's line (`map: <c> changes, <l> left, <o> open`). On the yes it lands in four commits,
# in order: ARCHITECTURE.md and BASELINE.md; DECISIONS.md; INVENTORY.md; PLAN.md. Then the writer owes S02's open ticket its
# amendment and, once the new step is admitted, one new step ticket for the new row; the closed ticket is untouched. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "incorporate-auto-draft: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; git config user.email vid@selftest; git config user.name vid
# the courts the hook runs, stubbed; the hook, the label join and the law files real
mkdir -p checks/hooks; for c in placement conformance imports seams inventory census design-cite prd harness; do
  printf '#!/bin/sh\n# Purpose: stub court %s\nmkdir -p .ran; : > .ran/%s\necho "%s ok"\n' "$c" "$c" "$c" > "checks/$c.sh"; done
cp "$CHECKS/hooks/pre-commit" checks/hooks/pre-commit; cp "$CHECKS/labels.sh" "$CHECKS/lawfiles" checks/
printf '.ran/\n' >> .gitignore; g add -A && g commit -qm 'the courts'; git config core.hooksPath checks/hooks
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"; N1=$(awk '$1 == "published" && / kind=skeleton / { print $2 }' .vid/tw/log | head -n 1)
tw_start S02 || fail "S02 was refused: $(cat "$T/start")"; tw_post step S02 || fail "S02's ticket: $(cat "$T/werr")"; N2=$TW_N
cksum < "$T/gh/issues/$N1/body" > "$T/n1body"; ls "$T/gh/issues/$N1/comments" | wc -l > "$T/n1com"
LS=$CHECKS/land.sh; QS=$CHECKS/queue.sh; printf 'none\n' > "$T/rv"
ld() { RC=0; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
CITE='https://github.com/owner/code/blob/0123456789abcdef0123456789abcdef01234567/records/feed-log.md'
D5="- **D-005** each feed read is written to the feed log before its jobs are stored | why: $CITE | enforced: convention | applies-to: feedlog, ingest"
module() { awk '{ print } /^\| ingest \|/ { print "| feedlog | the log of each feed read | feed reads | the read log | ingest |" }' ARCHITECTURE.md > "$T/a" && cp "$T/a" ARCHITECTURE.md
  printf '%s\n' "$D5" >> DECISIONS.md; }
# a module and a decision labelled with it, drafted alone: its dry run passes
module; ld draft --review "$T/rv" --why 'the feed log module and its rule'; [ "$RC" = 0 ] || fail "a draft adding a module and a decision labelled with it was refused at its dry run ($RC)"
ok '^draft 1$'; [ -z "$(git status --porcelain -- ARCHITECTURE.md DECISIONS.md)" ] || fail 'the draft left the tree changed'
# the incorporation, in the working tree: the module, a stack line, the decision, a new row in a new step, a PLAN.md line
module
awk '{ print } /^\| data \|/ { print "| log | an append-only log per feed | a log kept in the listings |" }' BASELINE.md > "$T/b" && cp "$T/b" BASELINE.md
awk '/^ROW-020 \|/ { print; print "ROW-021 | behavior | REQ-001 | (process) | n/a | Each feed read is in the feed log before its jobs are listed. Fails if a listed job has no read in the feed log. | REQ-001 | owed: spec-only — ticket | origin: incorporation 2026-11-19 D-005"; next } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
printf '\nThe feed log has its own step, S06.\n' >> PLAN.md
{ sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | grep -v '^shared:'; printf 'step S06 | name: the feed log | modules: feedlog | builds-on: S01 | rows: ROW-021 | lane: devagent\nneeds ROW-021 | -\n'
  sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | grep '^shared:'; } > "$T/plan"
cat > "$T/map" <<EOF
# the map of the feed log record

ARCHITECTURE.md | the module table | today: five modules | change: the feedlog module | record: the feed log is a module of its own
BASELINE.md | Stack | today: web and data | change: a log layer | record: an append-only log per feed
DECISIONS.md | D-005 | today: none | change: each read is logged before its jobs are stored | record: every read is logged first
INVENTORY.md | ROW-021 | today: none | change: a row for the log | record: a read missing from the log
PLAN.md | the prose | today: none | change: the feed log's step named | record: the log is built on its own
left: GRADING-CHECKLIST.md | Domain lines | the record names nothing a grader checks
open: how long is a feed's log kept?
EOF
W='/vid incorporate: this is a decision, take all of it'
# the map: required on an incorporation, refused on any other draft; both refusals keep the tree and make no draft
ld draft --review "$T/rv" --why "$W" --plan "$T/plan"; [ "$RC" != 0 ] && ok 'map' || fail "an incorporation with no map was drafted ($RC)"
ld draft --review "$T/rv" --why 'a change to the spec' --plan "$T/plan" --map "$T/map"; [ "$RC" != 0 ] && ok 'map' || fail "a draft that is no incorporation took a map ($RC)"
[ ! -d .vid/decide/drafts/2 ] && [ -n "$(git status --porcelain -- INVENTORY.md BASELINE.md)" ] || fail 'a refused map made a draft, or put the tree back'
ld draft --review "$T/rv" --why "$W" --plan "$T/plan" --map "$T/map"; [ "$RC" = 0 ] || fail "the incorporation was not drafted ($RC)"
ok '^draft 2$'; ok '^impact reset=0 added=1 '; ok '^map: 5 changes, 1 left, 1 open$'; ok '^words This changes 0 rows, adds 1 in S06, .*; map: 5 changes, 1 left, 1 open. Land it?$'
cmp -s "$T/map" .vid/decide/drafts/2/map && [ -f .vid/decide/drafts/2/review ] || fail 'the map is not kept beside the review'
[ -z "$(git status --porcelain -- ARCHITECTURE.md BASELINE.md DECISIONS.md INVENTORY.md PLAN.md)" ] || fail 'the draft left the tree changed'
ld count 2; ok '^map: 5 changes, 1 left, 1 open$'
# asked once, the map's counts on its line; the yes lands it in four commits, architecture first
RC=0; sh "$QS" ask draft 2 > "$T/out" 2>&1 || RC=$?; QN=$(sed -n 's/^asked \(Q[0-9]*\) draft 2$/\1/p' "$T/out"); [ -n "$QN" ] || fail 'the incorporation was not asked'
grep -q "^- $QN · .*draft 2 by SP: /vid incorporate: this is a decision, take all of it · .*; map: 5 changes, 1 left, 1 open. Land it?" .vid/RUN-STATE.md || fail "the ask's line: $(grep "^- $QN" .vid/RUN-STATE.md)"
H1=$(git rev-parse HEAD); RC=0; sh "$QS" answer "$QN" yes 'Yes, land it' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the yes did not land it ($RC)"
[ "$(git log --format=%s "$H1..HEAD" | paste -sd '|' -)" = "Land draft 2, the plan file: $W|Land draft 2, the law: $W|Land draft 2, the PRD: $W|Land draft 2, the architecture: $W" ] || fail "the commits: $(git log --oneline "$H1..HEAD")"
[ "$(git log --reverse --format=%H "$H1..HEAD" | while read -r c; do git diff-tree --no-commit-id --name-only -r "$c" | paste -sd ' ' -; done | paste -sd '|' -)" = 'ARCHITECTURE.md BASELINE.md|DECISIONS.md|INVENTORY.md|PLAN.md' ] || fail "the commits' files: $(git log --stat --oneline "$H1..HEAD")"
grep -qxF -- "$D5" DECISIONS.md && grep -q '^| feedlog |' ARCHITECTURE.md && grep -q '^| log |' BASELINE.md || fail 'the landed files lack the change'
sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail 'the gate is shut after the landing'
# the writer: S02's open ticket owes its amendment (it quotes the new decision); the new row its own step ticket; #N1 untouched
sh "$CHECKS/github.sh" spec-export > /dev/null 2>&1 || fail 'no export'; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'due failed'
ok "^amend $N2$"; ! grep -qE "^(amend|withdraw) $N1( |\$)" "$T/out" || fail "the closed ticket #$N1 is owed something: $(cat "$T/out")"
tw_start S06 || fail "S06 was refused: $(cat "$T/start")"; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'due failed'
ok "^amend $N2$"; ok '^new step S06$'; [ "$(grep -c '^new ' "$T/out")" = 1 ] || fail "more than one new ticket owed: $(cat "$T/out")"
sh "$CHECKS/writer.sh" write amend "$N2" > "$T/out" 2>&1 || fail 'the amendment was refused'; grep -qF "D-005" ".vid/tw/out/amend-$N2.md" || fail "S02's amendment does not quote the new decision"
case ",$(sed -n 1p ".vid/tw/out/amend-$N2.meta" | tr ' ' '\n' | sed -n 's/^rows=//p')," in *,ROW-021,*) fail 'the open ticket gains the new row' ;; esac
tw_post step S06 || fail "the new step's ticket: $(cat "$T/werr")"; [ "$(sed -n 1p "${TW_F%.md}.meta" | tr ' ' '\n' | sed -n 's/^rows=//p')" = ROW-021 ] || fail "the new step ticket's rows: $(sed -n 1p "${TW_F%.md}.meta")"
[ "$(cksum < "$T/gh/issues/$N1/body")" = "$(cat "$T/n1body")" ] && [ "$(ls "$T/gh/issues/$N1/comments" | wc -l)" = "$(cat "$T/n1com")" ] && grep -qx CLOSED "$T/gh/issues/$N1/state" || fail "the closed ticket #$N1 was changed"
exit 0
