#!/bin/sh
# Purpose: selftest case — one round step at a time (FB-7 B2), checks/round.sh in GitHub auto on the ticket writer's toy and the fake gh. While a
# step hangs in a gh call, a step, next, asks and accept beside it each print the one line `busy: round.sh step, since <UTC>, pid <p>`, exit 5,
# and write nothing, on GitHub or under .vid; a wait looks for the round until its own limit, then prints it too, and goes on with what is left
# of that limit when the round comes free; `read` is not held. The step then ends with one decision posted and the lock gone. Two steps started
# together post one decision, with no `lock-lost`. A lock a killed step left holds no call. GitHub's lock: a renew beaten by a renew of the same
# session is renewed, by another session's take lost, by one that cannot be read again an error. In GitHub manual no call takes it or is held by
# it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(cd "$(mktemp -d)" && pwd -P); SP=''; trap '[ -z "$SP" ] || kill "$SP" 2>/dev/null || true; rm -f "$T/hang"; sleep 1; rm -rf "$T"' EXIT
HOME=$T/home; mkdir -p "$HOME"; GIT_CONFIG_GLOBAL=$T/gitconfig; export HOME GIT_CONFIG_GLOBAL; git config --global user.name a; git config --global user.email a@b
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-lock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; RO=$CHECKS/round.sh; R=owner/code
rd() { RC=0; sh "$RO" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; grep -q '^published 1$' "$T/out" || fail 'next'; rd step
# the shims: with HANG set, gh hangs in a list while $T/hang is there; with RACE set, the first look at GitHub's lock is followed by $T/race's command
mkdir -p "$T/shim"; RG=$(command -v git); RH=$(command -v gh)
printf '#!/bin/sh\ncase "$1 $2" in "pr list") while [ -n "${HANG:-}" ] && [ -f "%s/hang" ]; do : > "%s/hung"; sleep 1; done ;; esac\nexec "%s" "$@"\n' "$T" "$T" "$RH" > "$T/shim/gh"
cat > "$T/shim/git" <<G
#!/bin/sh
case "\$*" in "ls-remote "*refs/heads/vid-state/lock) if [ -f "$T/race" ]; then o=\$("$RG" "\$@"); rc=\$?; mv "$T/race" "$T/raced"; sh "$T/raced" > "$T/raced.out" 2>&1; printf '%s\n' "\$o"; exit \$rc; fi ;; esac
exec "$RG" "\$@"
G
chmod +x "$T/shim/gh" "$T/shim/git"
hung() { rm -f "$T/hung"; : > "$T/hang"; HANG=1 PATH="$T/shim:$PATH" sh "$RO" step > "$T/s1" 2>&1 & SP=$!; n=0; while [ ! -f "$T/hung" ] && [ "$n" -lt 60 ]; do sleep 1; n=$((n + 1)); done; [ -f "$T/hung" ] || fail 'the hung step never reached its call'; }
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; git -C "$W" checkout -q -b ticket-1; git -C "$W" commit -q --allow-empty -m t; git -C "$W" push -q origin ticket-1 2>/dev/null
P=$(gh pr create -R $R --head ticket-1 --base main --title t --body "$(printf 'ticket: #1\n\nDecisions: none')" | sed 's/.*\///'); H=$(git -C "$W" rev-parse HEAD)
ask() { printf 'vid: decide %s\nby: MR\n' "$H" > "$T/c"; gh pr comment "$P" -R $R --body-file "$T/c" > /dev/null; }
decs() { for f in "$T/gh/prs/$P/comments"/*; do sed -n 1p "$f"; done | grep -c "^vid: decision $H" || true; }
snap() { find .vid -type f ! -path '.vid/round/lock/*' | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; cat "$T/gh/writes"; }
busy() { grep -qE "^busy: round\\.sh $1, since [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z, pid $SP\$" "$T/out" && [ "$(grep -c . "$T/out")" = 1 ]; }
# a step hangs: every other call says so, and writes nothing
ask; hung; snap > "$T/a"
for c in step next asks 'accept 1'; do rd $c; [ "$RC" = 5 ] && busy step || fail "round.sh $c beside a hung step ($RC)"; done
s=$(date +%s); VID_WAIT_MAX=3 VID_WAIT_TICK=1 rd wait; e=$(($(date +%s) - s)); [ "$RC" = 5 ] && busy step && [ "$e" -ge 2 ] || fail "round.sh wait beside a hung step ($RC, ${e}s)"
snap > "$T/b"; cmp -s "$T/a" "$T/b" || fail "a busy call wrote: $(diff "$T/a" "$T/b" | head -n 3)"
rd read; [ "$RC" = 0 ] || fail "read was held by the round ($RC)"
# a wait that finds it free again goes on, within its own limit
VID_WAIT_MAX=40 VID_WAIT_TICK=1 sh "$RO" wait > "$T/w1" 2>&1 & WP=$!; sleep 3; rm -f "$T/hang"; wait "$SP" || { cp "$T/s1" "$T/out"; fail 'the step that hung failed'; }; SP=''
RC=0; wait "$WP" || RC=$?; cp "$T/w1" "$T/out"; [ "$RC" = 0 ] && grep -qxE 'new|timeout' "$T/w1" || fail "a wait the round came free for ($RC)"
[ "$(decs)" = 1 ] || fail "the hung step posted $(decs) decisions"; [ ! -d .vid/round/lock ] || fail 'the lock stands after its call'
# two steps started together: one decision, no lock-lost
ask; sh "$RO" step > "$T/s1" 2>&1 & a=$!; sh "$RO" step > "$T/s2" 2>&1 & b=$!; r1=0; r2=0; wait "$a" || r1=$?; wait "$b" || r2=$?
cat "$T/s1" "$T/s2" > "$T/out"; ! grep -q lock-lost "$T/out" || fail 'two steps at once: lock-lost'
case $r1$r2 in 05|50) ;; *) fail "two steps at once: exits $r1 and $r2" ;; esac
[ "$(grep -c '^busy: round\.sh step, since ' "$T/out")" = 1 ] && [ "$(grep -c "^decided $P " "$T/out")" = 1 ] || fail 'two steps at once: not one that acts and one busy'
[ "$(decs)" = 2 ] || fail "two steps at once posted $(($(decs) - 1)) decisions"
# a killed step leaves a lock that holds no call
hung; kill -9 "$SP"; wait "$SP" 2>/dev/null || true; SP=''; rm -f "$T/hang"; [ -d .vid/round/lock ] || fail 'the killed step left no lock: nothing is proved'
rd step; [ "$RC" = 0 ] && ! grep -q '^busy' "$T/out" || fail "a dead step's lock held the next ($RC)"
# GitHub's lock: beaten by the same session's renew, it is renewed; by another session, lost; not read again, an error
rw() { RC=0; CLAUDE_CODE_SESSION_ID=t PATH="$T/shim:$PATH" sh "$GS" lock-renew > "$T/out" 2>&1 || RC=$?; }
echo "cd '$T/toy' && CLAUDE_CODE_SESSION_ID=t sh '$GS' lock-renew" > "$T/race"; rw; grep -q 'the lock renewed' "$T/raced.out" || fail 'the race did not renew: nothing is proved'; [ "$RC" = 0 ] || fail "a renew of the same session read as lost ($RC)"
echo "cd '$T/toy' && CLAUDE_CODE_SESSION_ID=o VID_LOCK_COLD=0 sh '$GS' lock-take o; printf 't\n' > .vid/lock-session" > "$T/race"; rw; grep -q "the lock is o's" "$T/raced.out" || fail 'the race did not take the lock: nothing is proved'; [ "$RC" = 3 ] && grep -q 'lock is lost' "$T/out" || fail "a lock another session took was renewed ($RC)"
# GitHub manual takes no round lock, and is held by none
mkdir -p .vid/round/lock; echo "$$ $(. "$CHECKS/lib.sh"; pstamp $$)" > .vid/round/lock/h; printf 'step\n' > .vid/round/lock/what
RC=0; VID_CALLER=mode sh "$RO" asks > "$T/out" 2>&1 || RC=$?; ! grep -q '^busy' "$T/out" && [ "$RC" != 5 ] || fail 'GitHub manual was held by the round lock'; [ "$(cut -d' ' -f1 .vid/round/lock/h)" = "$$" ] || fail 'GitHub manual took the round lock'
rd asks; [ "$RC" = 5 ] || fail 'the planted lock holds nothing: nothing is proved'; rm -rf .vid/round/lock
if [ -d "$CHECKS/../skills/vid-run" ]; then grep -q '^| `busy: round\.sh <what>, since <UTC>, pid <p>` (FB-7 B2) | Look again at 1; once it has been the same for 20 minutes, tell the owner in one line what hangs and since when, and go on looking\. It stops nothing |$' "$CHECKS/../skills/vid-run/SKILL.md" || fail "vid-run's table has no busy row"; fi
echo 'round-lock: ok'
