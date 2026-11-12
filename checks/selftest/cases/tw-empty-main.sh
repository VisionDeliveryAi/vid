#!/bin/sh
# Purpose: selftest case — a skeleton on an empty code repository (v0.26.10.28.2, R3, F-001), on the ticket writer's toy and the fake gh. A code
# repository with no branch at all syncs main=none, and the skeleton is written and published with base=none, its body saying the dev side starts
# main; a step ticket on main=none is refused. A failed read is refused and records nothing. Heads with no main sync main=absent: the skeleton and a
# step are refused. Once main exists, the skeleton's amendment takes main's commit. The dev manager starts main on base: none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-empty-main: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; WR=$CHECKS/writer.sh
git init -q --bare "$T/empty.git"; git -C "$T/empty.git" symbolic-ref HEAD refs/heads/main; echo "$T/empty.git" > "$T/gh/remote"
syncs() { grep -c '^sync ' .vid/tw/log 2>/dev/null || echo 0; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
# empty: main=none, the skeleton out with base=none
sh "$GS" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed on an empty repository'; grep '^sync ' .vid/tw/log | tail -n 1 | grep -q '^sync main=none open=' || fail "the sync: $(grep '^sync ' .vid/tw/log | tail -n 1)"
tw_start S01; tw_post skeleton || { cat "$T/werr" "$T/post" > "$T/out" 2>/dev/null || true; fail 'the skeleton was refused on an empty repository'; }
grep -qx -- '- base: none' "$TW_F" && grep -q ' base=none ' "${TW_F%.md}.meta" || fail 'the skeleton does not carry base none'
grep -qx 'The code repository is empty: start main with your first commit, then work from it.' "$TW_F" || fail 'the skeleton does not say to start main'
[ -n "$TW_N" ] && grep -q "^published $TW_N kind=skeleton " .vid/tw/log || fail 'the skeleton was not published'; SK=$TW_N
# a step ticket on main=none is refused
printf 'step-start step=S02 plan=x at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; tw_hand 'engines alpha'
RC=0; sh "$WR" write step S02 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'no base: the code repository is empty, and only the skeleton starts main' "$T/out" || fail "a step on main=none: exit $RC"
# a failed read: refused, nothing recorded
n=$(syncs); echo "$T/nowhere.git" > "$T/gh/remote"; RC=0; sh "$GS" tw-sync > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q 'could not be read' "$T/out" || fail "a failed read: exit $RC"
[ "$(syncs)" = "$n" ] || fail 'a failed read recorded a sync'; echo "$T/empty.git" > "$T/gh/remote"
# heads but no main: main=absent, the skeleton and the step refused
git clone -q "$T/empty.git" "$T/d" 2>/dev/null; git -C "$T/d" checkout -q -b other; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m x; git -C "$T/d" push -q origin other 2>/dev/null
sh "$GS" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed with heads but no main'; grep '^sync ' .vid/tw/log | tail -n 1 | grep -q '^sync main=absent ' || fail "heads but no main: $(grep '^sync ' .vid/tw/log | tail -n 1)"
for w in 'skeleton' 'step S02'; do RC=0; sh "$WR" write $w > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "no base: the code repository's main is not known (absent)" "$T/out" || fail "write $w on main=absent: exit $RC"; done
# main started: the skeleton's amendment takes main's commit
git -C "$T/d" checkout -q -b main; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m 'the first commit'; git -C "$T/d" push -q origin main 2>/dev/null; MC=$(git -C "$T/d" rev-parse HEAD)
sh "$GS" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed once main exists'; grep '^sync ' .vid/tw/log | tail -n 1 | grep -q "^sync main=$MC " || fail 'the sync does not name main'
F=$(sh "$WR" write amend "$SK" 2> "$T/out") || fail "the amendment of the skeleton was refused: $(cat "$T/out")"; grep -q " base=$MC " "${F%.md}.meta" && grep -qx -- "- base: $MC" "$F" || fail "the amendment's base: $(head -n 1 "${F%.md}.meta")"
! grep -q 'The code repository is empty' "$F" || fail 'the amendment still says the repository is empty'
# the dev manager starts main on base: none
grep -q "A skeleton's \`base: none\` (v0.26.10.28.2, R3) is an empty code repository: first push main's" "$CHECKS/../devagent/agents/dev-manager.md" 2>/dev/null || [ ! -d "$CHECKS/../devagent" ] || fail 'the dev manager does not start main'
echo 'tw-empty-main: ok'
