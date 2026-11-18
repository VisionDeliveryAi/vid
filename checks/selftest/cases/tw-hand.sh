#!/bin/sh
# Purpose: selftest case — every ticket ViD publishes is on the record, whoever calls the writer (0.26.10.29.2 R12), checks/github.sh
# tw-hand on TW's toy, a copy of it, and the fake gh. The run's folder (A) saves its records; a copy (B) falls behind when A admits S02
# and S03 and saves. In B: a bare withdrawal is refused, its records not the saved head; a hand-call refuses while B holds a record not
# yet saved, naming it, and leaves no lock; then a hand-call restores, writes, posts and saves S02's ticket and frees the lock it took,
# and A, restoring, sees the ticket. A takes the run's lock: B's hand-call is refused, naming the holder, nothing posted. A call in the
# run's own session borrows the lock: it posts and saves S03's ticket and leaves the lock the run's, which it can still renew. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-hand: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; SR=$T/gh/repos/owner%code-spec/remote.git; A=$T/toy; B=$T/b
tw_skel || fail 'the skeleton round failed'; sh "$GS" state-save > "$T/out" 2>&1 || fail 'the first save failed'; cp -R "$A" "$B"
saved() { git --git-dir="$SR" show refs/heads/vid-state/records:tw/log 2>/dev/null; }; lock() { git --git-dir="$SR" show refs/heads/vid-state/lock:lock 2>/dev/null | sed -n 's/^session: //p'; }
issues() { ls "$T/gh/issues" | grep -c .; }
# a git that, once each, reads no lock (as if read just before another call took it), fails the read of the saved records' head, or
# (armed with a ticket's number) lets folder B save between a hand-call's check of the saved head and its save: at the second
# read of that head once the ticket's amendment is in the log; and a gh whose next issue comment fails
RG=$(command -v git); mkdir -p "$T/shim"; cat > "$T/shim/git" <<EOF
#!/bin/sh
if [ "\$1" = ls-remote ] && [ "\${3:-}" = refs/heads/vid-state/lock ] && [ -f "$T/shim/empty-lock" ]; then rm -f "$T/shim/empty-lock"; exit 0; fi
if [ "\$1" = ls-remote ] && [ "\${3:-}" = refs/heads/vid-state/records ] && [ -f "$T/shim/fail-records" ]; then rm -f "$T/shim/fail-records"; exit 128; fi
if [ "\$1" = ls-remote ] && [ "\${3:-}" = refs/heads/vid-state/records ] && [ -f "$T/shim/move-head" ] && grep -q "^amended \$(cat "$T/shim/move-head") " .vid/tw/log 2>/dev/null; then
  echo x >> "$T/shim/moves"; if [ "\$(grep -c . "$T/shim/moves")" = 2 ]; then rm -f "$T/shim/move-head"
    ( cd "$T/b" && echo 'note by=self-test-2' >> .vid/metrics-events && sh "$CHECKS/github.sh" state-save ) > "$T/shim/moved.out" 2>&1; fi; fi
exec "$RG" "\$@"
EOF
printf '#!/bin/sh\nif [ "$1 $2" = "issue comment" ] && [ -f "%s/shim/fail-comment" ]; then rm -f "%s/shim/fail-comment"; echo "fake gh: the comment failed" >&2; exit 1; fi\nexec "%s/bin/gh" "$@"\n' "$T" "$T" "$T" > "$T/shim/gh"; chmod +x "$T/shim/git" "$T/shim/gh"
# the run admits S02 and S03 and saves: B is behind
cd "$A"; tw_start S02 && tw_start S03 || fail 'S02 or S03 was refused'; sh "$GS" state-save > "$T/out" 2>&1 || fail "A's save failed"
cd "$B"; RC=0; sh "$GS" tw-close 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "not the saved records' head" "$T/out" || fail 'a withdrawal went ahead from a folder behind the saved records'
# a failed read of the saved head refuses; with no state-at here while records are saved, a bare act refuses too
: > "$T/shim/fail-records"; RC=0; PATH="$T/shim:$PATH" sh "$GS" tw-close 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "head could not be read" "$T/out" || fail 'a failed read of the saved head let a withdrawal through'
mv .vid/state-at "$T/sa"; RC=0; sh "$GS" tw-close 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'holds no saved state' "$T/out" || fail 'a folder with no saved state went ahead while records are saved'; mv "$T/sa" .vid/state-at
# a record not yet saved, while behind: refused, naming it, and no lock left
cp .vid/metrics-events "$T/me"; echo 'note by=self-test' >> .vid/metrics-events
RC=0; CLAUDE_CODE_SESSION_ID=owner-b sh "$GS" tw-hand write step S02 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'metrics-events' "$T/out" || fail 'an unsaved record was not named'
! grep -q 'Save or drop' "$T/out" && grep -q 'restore' "$T/out" || fail "the refusal tells the owner to save from a folder behind: $(cat "$T/out")"
[ -z "$(lock)" ] || fail "a refused hand-call left the lock held by $(lock)"; cp "$T/me" .vid/metrics-events
# the hand-call: restored, written, posted and saved; the lock it took freed
CLAUDE_CODE_SESSION_ID=owner-b sh "$GS" tw-hand write step S02 > "$T/out" 2>&1 || fail 'the hand-call failed'; N=$(sed -n 's/^ViD github: published ticket #\([0-9]*\).*/\1/p' "$T/out")
[ -n "$N" ] && grep -q "^published $N kind=step step=S02 " .vid/tw/log || fail 'no S02 ticket published'; saved | grep -q "^published $N kind=step step=S02 " || fail 'the ticket is not in the saved records'
saved | grep -q '^published 1 kind=skeleton ' || fail 'the saved records lost what the run saved before'; [ -z "$(lock)" ] || fail "the lock is still held by $(lock)"
cd "$A"; sh "$GS" state-restore > "$T/out" 2>&1 || fail "A's restore failed"; grep -q "^published $N kind=step step=S02 " .vid/tw/log || fail 'the run does not see the hand-called ticket'
# the run's lock held: a hand-call elsewhere refused, naming the holder, nothing posted
CLAUDE_CODE_SESSION_ID=run-a sh "$GS" lock-take run-a > "$T/out" 2>&1 || fail 'the run could not take its lock'; cd "$B"; I=$(issues)
RC=0; CLAUDE_CODE_SESSION_ID=owner-b sh "$GS" tw-hand write step S03 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'run-a' "$T/out" || fail "a hand-call went ahead under another session's lock"
[ "$(issues)" = "$I" ] && [ "$(lock)" = run-a ] || fail 'the refused hand-call posted, or took the lock'
# a bare post, B at the saved head, refused while the run's lock is another session's
sh "$GS" state-restore > "$T/out" 2>&1 || fail "B's restore failed"; FB=$(sh "$CHECKS/writer.sh" write step S03 2> "$T/out") || fail "B could not write S03's ticket"
RC=0; CLAUDE_CODE_SESSION_ID=owner-b sh "$GS" tw-post "$FB" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'held by run-a' "$T/out" && [ "$(issues)" = "$I" ] || fail "a bare post went ahead under another session's lock"
# a call in the run's own session borrows the lock: posted and saved, the lock still the run's
cd "$A"; CLAUDE_CODE_SESSION_ID=run-a sh "$GS" tw-hand write step S03 > "$T/out" 2>&1 || fail 'the call in the run session failed'; N3=$(sed -n 's/^ViD github: published ticket #\([0-9]*\).*/\1/p' "$T/out")
[ -n "$N3" ] && saved | grep -q "^published $N3 kind=step step=S03 " || fail "S03's ticket is not in the saved records"
[ "$(lock)" = run-a ] || fail "the run's lock was freed or taken: $(lock)"; CLAUDE_CODE_SESSION_ID=run-a sh "$GS" lock-renew > "$T/out" 2>&1 || fail 'the run could not renew its lock'
# a stale copy of the run's folder, in its session, borrows the lock but saves nothing over the newer records
cp -R "$A" "$T/d"; echo 'note by=self-test' >> .vid/metrics-events; sh "$GS" state-save > "$T/out" 2>&1 || fail "A's save failed"; H2=$(git --git-dir="$SR" rev-parse refs/heads/vid-state/records)
cd "$T/d"; RC=0; CLAUDE_CODE_SESSION_ID=run-a sh "$GS" tw-hand write amend "$N" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'a stale folder borrowing the lock acted'
[ "$(git --git-dir="$SR" rev-parse refs/heads/vid-state/records)" = "$H2" ] || fail 'a stale folder saved over the newer records'
# the run's session takes its lock between a hand-call's read and its take: the hand-call never frees it
cd "$A"; : > "$T/shim/empty-lock"; RC=0; PATH="$T/shim:$PATH" CLAUDE_CODE_SESSION_ID=run-a sh "$GS" tw-hand write amend "$N" > "$T/out" 2>&1 || RC=$?
[ "$(lock)" = run-a ] || fail "a hand-call freed the lock its own session held: $(cat "$T/out")"
# an amendment whose comment fails once the issue's body is replaced: nothing recorded, and the hand-call says the issue may be changed
pt_rs 's/^\(step S02 .*\)ROW-013 /\1/'; pt_rs 's/^\(step S04 .*rows: \)/\1ROW-013 /'
sh "$CHECKS/plan.sh" change rows 'ROW-013 waits for S04' --trigger scope-change --evidence "ticket:$N" --expect 'S02 ships without it' > "$T/out" 2>&1 || fail 'the plan change was refused'
: > "$T/shim/fail-comment"; RC=0; PATH="$T/shim:$PATH" CLAUDE_CODE_SESSION_ID=run-a sh "$GS" tw-hand write amend "$N" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && [ ! -f "$T/shim/fail-comment" ] && ! grep -q "^amended $N " .vid/tw/log || fail "a failed amendment was recorded, or the comment never failed: $(cat "$T/out")"
grep -q 'may already be changed' "$T/out" && ! grep -q 'nothing posted' "$T/out" || fail "a hand-call that changed the issue says: $(tail -n 1 "$T/out")"
# folder B saves between the hand-call's check of the saved head and its save: the save refuses, and B's records stand
echo "$N" > "$T/shim/move-head"; RC=0; PATH="$T/shim:$PATH" CLAUDE_CODE_SESSION_ID=run-a sh "$GS" tw-hand write amend "$N" > "$T/out" 2>&1 || RC=$?
grep -q "^amended $N " .vid/tw/log && [ ! -f "$T/shim/move-head" ] || fail "the amendment was not posted, or the saved head never moved: $(cat "$T/out")"
git --git-dir="$SR" show refs/heads/vid-state/records:metrics-events | grep -q 'note by=self-test-2' || fail 'a hand-call saved over the records another folder saved between its check and its save'
[ "$RC" = 1 ] || fail 'a hand-call whose save was refused reported success'
exit 0
