#!/bin/sh
# Purpose: selftest case — the re-plan's analysis writes the proposal and its page and nothing else (GM-3 U3; its case
# manual-analyse). On the form fixture's toy (fixtures/form.sh), S02 posted as ticket N; ROW-021 added to INVENTORY.md and committed
# (a landing, by hand), so it is pending; the call's read made. The candidate puts ROW-021 in a new step S06, with its change, the
# not-taken trigger left alone with why, and the review of the rows ViD added (none). First a candidate that takes ROW-013 out of
# S02: refused (exit 1), naming rule-2, and no proposal or page. Then the good one: `replan.sh analyse --candidate <dir>` exits 0;
# .vid/next/proposal/ holds the block as the candidate wrote it, the target (HEAD), the hash `replan.sh hash` prints, S06 to publish,
# its change, the review, the not-taken trigger left alone; .vid/pages/REPLAN-PAGE.html exists and names the block's hash and S06.
# Both times ViD's records (.vid/, but the proposal and the page), the commit and the working tree, and the fake GitHub (its every
# file, its call log among them) are byte for byte as before. Then the hash reads only the log's ticket lines (published, amended,
# withdrawn): a line of another kind appended to .vid/tw/log leaves `replan.sh hash` as it was; an amended line changes it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-analyse: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-021 landed'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 && grep -q "^pending${TB}added${TB}ROW-021\$" "$T/out" || fail 'ROW-021 is not pending'
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
# snap <file>: every file of .vid/ but the proposal and its page, the commit, the working tree's status, and every file of the fake GitHub
snap() { { find .vid -type f ! -path '.vid/next/proposal/*' ! -path .vid/pages/REPLAN-PAGE.html | sort | while IFS= read -r f; do cksum "$f"; done
  git rev-parse HEAD; git status --porcelain; find "$FAKEGH" -type f | sort | while IFS= read -r f; do cksum "$f"; done; } > "$1"; }
C=$T/cand; mkdir -p "$C"
blk | sed -e '/^step S05 /{p;s/.*/step S06 | name: the day of the last digest | modules: digest | builds-on: S02 | rows: ROW-021 | lane: devagent/;}' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;}' > "$C/block"
printf 'S06\tscope-change\tcommit:%s\tROW-021 is built and tested in a step of its own\n' "$(git rev-parse --short HEAD)" > "$C/changes"
printf 'trigger\tnot-taken #%s\tthe team takes it in its own time; no plan change helps it\n' "$N" > "$C/left"
printf 'none\n' > "$C/review"
snap "$T/s0"
# refused: ROW-013 taken out of S02, nothing written
B=$T/bad; mkdir -p "$B"; sed -e 's/^\(step S02 .*\) ROW-013 /\1 /' -e 's/^\(step S06 .*rows:\) /\1 ROW-013 /' "$C/block" > "$B/block"; cp "$C/left" "$C/review" "$B/"
{ cat "$C/changes"; printf 'S02\tscope-change\tcommit:%s\tROW-013 moves to S06\n' "$(git rev-parse --short HEAD)"; } > "$B/changes"
RC=0; pt_placed "$B/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$B" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'rule-2 ROW-013' "$T/out" || fail "the analysis of a candidate taking ROW-013 out of #$N exited $RC, or named no rule-2 breach"
[ ! -e .vid/next/proposal ] && [ ! -e .vid/pages/REPLAN-PAGE.html ] || fail 'the refused analysis wrote a proposal or a page'
snap "$T/s1"; cmp -s "$T/s0" "$T/s1" || { diff "$T/s0" "$T/s1" > "$T/out"; fail 'the refused analysis changed a record, the commit, the tree or the fake GitHub'; }
# the analysis
RC=0; pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the analysis exited $RC"
P=.vid/next/proposal
cmp -s "$C/block" "$P/block" || fail 'the proposal does not hold the block as the candidate wrote it'
[ "$(cat "$P/target")" = "$(git rev-parse HEAD)" ] || fail 'the proposal does not name HEAD as its target'
H=$(sh "$CHECKS/replan.sh" hash) && [ -n "$H" ] && [ "$(cat "$P/hash")" = "$H" ] || fail "the proposal's hash is not the one replan.sh hash prints ($H)"
grep -qx S06 "$P/publish" || fail 'the proposal does not publish S06'
grep -q "^S06${TB}scope-change${TB}" "$P/changes" || fail "the proposal does not hold S06's change"
grep -qx none "$P/review" || fail 'the proposal does not hold the review'
grep -q "^trigger${TB}not-taken #$N${TB}" "$P/left" || fail 'the proposal does not leave the not-taken trigger alone with why'
BH=$(cat "$P/block-hash") && [ -n "$BH" ] || fail 'the proposal names no block hash'
[ -f .vid/pages/REPLAN-PAGE.html ] && grep -q "$BH" .vid/pages/REPLAN-PAGE.html && grep -q S06 .vid/pages/REPLAN-PAGE.html || fail "the page is missing, or does not name the block's hash and S06"
snap "$T/s2"; cmp -s "$T/s0" "$T/s2" || { diff "$T/s0" "$T/s2" > "$T/out"; fail 'the analysis changed a record, the commit, the tree or the fake GitHub'; }
# the hash: of the log, the ticket lines alone
printf 'asked %s kind=decide at=2026-11-20T09:00:00Z\n' "$N" >> .vid/tw/log
[ "$(sh "$CHECKS/replan.sh" hash)" = "$H" ] || fail 'a log line that is no ticket line changed the hash'
grep "^published $N " .vid/tw/log | sed 's/^published /amended /; s/ at=[^ ]*/ at=2026-11-20T09:01:00Z/' >> .vid/tw/log
[ "$(sh "$CHECKS/replan.sh" hash)" != "$H" ] || fail 'an amended line in the log left the hash as it was'
exit 0
