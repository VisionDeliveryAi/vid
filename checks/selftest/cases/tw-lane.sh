#!/bin/sh
# Purpose: selftest case — TW stays in its lane, W10 (v0.26.10.12.3 R9). Read: checks/writer.sh
# calls no gh, clones nothing, names no .vid/code, writes no event and redirects into none of ViD's spec files or
# RUN-STATE; github.sh's tw-* subcommands clone nothing and name no .vid/code; skills/vid-tickets/SKILL.md (skipped
# where skills/ is absent, a project) names gh as no word, no ticket.sh, no .vid/code and no test path, and runs
# spec-export, tw-sync, due, write, tw-post and tw-close; copies with each planted are convicted. Run: one round of the
# skill's steps by hand on TW's toy — the gate, spec-setup, spec-export, tw-sync, due and each line it owes — leaves
# ViD's HEAD, index and tracked files as they were; .vid/tw/log holds the spec-repo, export, sync … open=, published
# and sent lines, then amended and withdrawn ones after a recorded change; a ticket closes when its issue does (the
# next sync's open= drops it); `ticket:<n>` evidence resolves in plan.sh change. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-lane: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
WR=$CHECKS/writer.sh; GS=$CHECKS/github.sh
code() { grep -nE '(^|[^a-z-])gh [a-z]|git clone|\.vid/code|event\.sh|>>?[[:space:]]*"?(PRD|INVENTORY|PLAN|STAGES|ARCHITECTURE|DECISIONS|BASELINE|GRADING-CHECKLIST|CLAUDE)\.md|>>?[[:space:]]*"?[^ ]*(RUN-STATE\.md|metrics-events)' "$1" | grep -v '^[0-9]*:[[:space:]]*#' || true; }
[ -z "$(code "$WR")" ] || { code "$WR" >&2; fail 'writer.sh calls gh, clones, reads the code, writes an event or writes a spec file'; }
for p in 'gh issue create -R x' 'git clone x y' 'printf x >> INVENTORY.md' 'echo y > .vid/RUN-STATE.md'; do { cat "$WR"; echo "  $p"; } > "$T/w.sh"; [ -n "$(code "$T/w.sh")" ] || fail "a planted \"$p\" in writer.sh is not convicted"; done
awk '/^  tw-sync\)/ { on = 1 } /^  spec-setup\)/ { on = 0 } on' "$GS" > "$T/tw.sh"; [ -s "$T/tw.sh" ] || fail "github.sh's tw-* subcommands were not found"
! grep -nE 'git clone|\.vid/code|repo clone' "$T/tw.sh" || fail "github.sh's tw-* subcommands clone or read the code"
SK=$CHECKS/../skills/vid-tickets/SKILL.md
if [ -d "$CHECKS/../skills" ]; then
  sk() { grep -nw 'gh' "$1" || true; grep -n -e 'ticket\.sh' -e '\.vid/code' "$1" || true; grep -nE '(^|[^a-z])tests?/|test_[a-z]|[._]test\.' "$1" || true; }
  [ -f "$SK" ] && [ -z "$(sk "$SK")" ] || fail 'vid-tickets is missing, or names gh, ticket.sh, the code or a test path'
  [ "$(wc -l < "$SK")" -le 120 ] || fail 'vid-tickets is over 120 lines'
  for c in 'github.sh spec-export' 'github.sh tw-sync' 'writer.sh due' 'writer.sh write' 'github.sh tw-post' 'github.sh tw-close' 'writer.sh gate'; do grep -q "$c" "$SK" || fail "vid-tickets does not run $c"; done
  for p in 'then gh issue create' 'git -C .vid/code log' 'a test under tests/acceptance'; do { cat "$SK"; echo "$p"; } > "$T/s.md"; [ -n "$(sk "$T/s.md")" ] || fail "a planted \"$p\" in the skill is not convicted"; done
fi
# a round by hand
tw_toy "$T/toy"; H0=$(git rev-parse HEAD); I0=$(git ls-files -s | git hash-object --stdin)
sh "$WR" gate > "$T/out" 2>&1 || fail 'the gate is closed on the toy'
sh "$GS" spec-setup > "$T/out" 2>&1 && sh "$GS" spec-export >> "$T/out" 2>&1 && sh "$GS" tw-sync >> "$T/out" 2>&1 || fail 'the set-up failed'
tw_start S01 || fail 'S01 was refused'
round() { sh "$GS" spec-export > /dev/null 2>&1; sh "$GS" tw-sync > /dev/null 2>&1; sh "$WR" due > "$T/due" 2>&1 || fail 'due failed'
  while read -r w a b; do case "$w" in
      withdraw) sh "$GS" tw-close "$a" > "$T/out" 2>&1 || fail "tw-close $a failed" ;;
      amend) tw_post amend "$a" || fail "amend $a failed" ;;
      new) tw_post $a $b || fail "new $a $b failed" ;;
    esac; done < "$T/due"; }
round; grep -q '^published 1 kind=skeleton step=S01 ' .vid/tw/log || fail 'the round published no skeleton'
tw_hand 'engines chromium'; tw_closed S01; tw_hand 'candidate 0'; tw_hand 'staged 0'; tw_close 1; tw_start S02 || fail 'S02 was refused'; round
for k in 'spec-repo owner/code-spec created' 'export ' 'sync main=' 'published 2 kind=step step=S02 ' 'sent ROW-001 ticket=2 hash='; do grep -q "^$k" .vid/tw/log || fail "the log lacks a $k line"; done
grep '^sync ' .vid/tw/log | tail -n 1 | grep -q ' open=- ' || fail "the closed skeleton ticket is still counted open"
sh "$GS" tw-sync > /dev/null 2>&1; grep '^sync ' .vid/tw/log | tail -n 1 | grep -q ' open=2 ' || fail 'the open ticket is not counted'
pt_rs 's/^\(step S02 .*\)ROW-012 /\1/'; pt_rs 's/^\(step S04 .*rows: \)/\1ROW-012 /'
sh "$CHECKS/plan.sh" change rows 'ROW-012 to S04' --trigger scope-change --evidence ticket:2 --expect 'S02 without it' > "$T/out" 2>&1 || fail 'ticket:2 did not resolve'
round; grep -q '^amended 2 kind=step ' .vid/tw/log || fail 'the amendment is not logged'
pt_rs 's/^step S02 | name: new jobs only, each listed once/step S06 | name: new jobs only, each listed once/'; pt_rs 's/builds-on: S02/builds-on: S06/g'
sh "$CHECKS/plan.sh" change other 'S02 withdrawn, its rows as S06' --trigger scope-change --evidence ticket:2 --expect 'S06 goes out' > "$T/out" 2>&1 || fail 'the withdrawal was not recorded'
round; grep -q '^withdrawn 2 decision=' .vid/tw/log || fail 'the withdrawal is not logged'
[ "$(git rev-parse HEAD)" = "$H0" ] && [ "$(git ls-files -s | git hash-object --stdin)" = "$I0" ] && [ -z "$(git status --porcelain)" ] || fail "the round changed ViD's HEAD, index or tracked files"
exit 0
