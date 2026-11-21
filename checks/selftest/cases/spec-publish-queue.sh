#!/bin/sh
# Purpose: selftest case — the spec's folder pull request in GitHub auto (GM-4 K13, J4; queue lane): DevAgent merges only what ViD
# accepted, so the pull request `github.sh spec-publish` opens on the code repository is the owner's to merge, and while the read
# shows the newest one open (`spec-published pr=<n> …` in .vid/tw/log, an `open <n>` line in .vid/round/read) the owner's queue holds
# one `Q<n>` line naming it and its export; an older one, still open, has none. Once the read shows it merged its line is gone; an
# answer to it is refused, since the merge on GitHub closes it. In GitHub manual the ticket names the pull request instead, and the
# queue holds no line for it. On the planner's toy, its read and log written by hand. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "spec-publish-queue: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t'); QS=$CHECKS/queue.sh
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
mkdir -p .vid/tw .vid/round; printf 'repo: owner/code\nspec-repo: owner/code-spec\nlabels-prefix:\nlayout: one\nspec-path: upstream/vid\n' > .vid/tw/settings
{ printf 'spec-published pr=7 export=0123456789ab path=upstream/vid at=2026-11-20T09:00:00Z\n'
  printf 'spec-published pr=9 export=abcdef012345 path=upstream/vid at=2026-11-21T09:00:00Z\n'; } > .vid/tw/log
H=0123456789ab0123456789ab0123456789ab0123
op() { printf 'open\t%s\t-\t%s\tfalse\t\t0\t0\t2026-11-21T09:00:00Z\t\n' "$1" "$H"; }
{ op 7; op 9; } > .vid/round/read
list() { sh "$QS" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; }
# GitHub auto, the newest open: one line naming #9 and its export; none for the older #7
list; grep "${TB}specpr:" "$T/ql" > "$T/sp" || :
[ "$(grep -c . "$T/sp")" = 1 ] || { cp "$T/ql" "$T/out"; fail "the queue holds $(grep -c . "$T/sp") lines for the spec's folder pull requests, not one"; }
grep -q "^Q[0-9][0-9]*${TB}specpr:9${TB}" "$T/sp" && grep -q '#9' "$T/sp" && grep -q 'abcdef012345' "$T/sp" && grep -q 'upstream/vid' "$T/sp" || { cp "$T/sp" "$T/out"; fail 'the line does not name pull request #9, its export and its folder'; }
Q=$(cut -f1 "$T/sp"); grep -q "^- $Q · " .vid/RUN-STATE.md || fail "the run record holds no $Q line"
RC=0; sh "$QS" answer "$Q" 'merged it' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "an answer to the folder pull request's line was taken"
# merged: the line is gone
{ op 7; printf 'merged\t9\t-\t%s\tfedcba9876543210fedcba9876543210fedcba98\t\n' "$H"; } > .vid/round/read
list; ! grep -q "${TB}specpr:" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the line stays once the read shows the pull request merged'; }
! grep -q "^- $Q · " .vid/RUN-STATE.md || fail "the run record still holds $Q once the pull request is merged"
# GitHub manual: the ticket names it, the queue holds none
printf 'spec-published pr=11 export=111111111111 path=upstream/vid at=2026-11-21T10:00:00Z\n' >> .vid/tw/log; { op 7; op 11; } > .vid/round/read
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
list; ! grep -q "${TB}specpr:" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'in GitHub manual the queue holds a line for the folder pull request'; }
exit 0
