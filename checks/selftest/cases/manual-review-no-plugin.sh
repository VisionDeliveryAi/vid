#!/bin/sh
# Purpose: selftest case — ViD's own review recorded in a project with no plugin beside its checks/ (FB-3 A1.4), as the vid-accept-step
# skill's "The review" writes each call, on GitHub manual's toy and the fake gh (fixtures/accept.sh, review.sh). checks/ alone is copied
# into the project. A record with an open line and no plugin root is refused, the pass not found, and saves nothing; as the skill writes
# it, with the root, it is recorded and the second reviewer's brief is made, then sorted. No prepare, record, sorted or due of the three
# skills that make a review is written without the root. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_PLUGIN_ROOT 2>/dev/null || true
PR=$(cd "$CHECKS/.." && pwd); SK=$PR/skills/vid-accept-step/SKILL.md; [ -f "$PR/skills/vid-accept-step/passes/review.md" ] || exit 77
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"; . "$CHECKS/selftest/fixtures/review.sh"
fail() { echo "manual-review-no-plugin: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# call <action>: the skill's own command for it, the id in place, run as the session runs it: the root named in the skill's words alone
call() { c=$(grep -oE '`[^`]*sh checks/review\.sh '"$1"' [^`]*`' "$SK" | head -n 1 | tr -d '`' | sed "s|step-<n> <c12>|step-$n $h|; s|<id>|$id|g"); [ -n "$c" ] || fail "the skill names no $1"; RC=0; CLAUDE_PLUGIN_ROOT=$PR; ( eval "$c" ) > "$T/out" 2>&1 || RC=$?; unset CLAUDE_PLUGIN_ROOT; }
ac_project "$T/p" || fail 'the toy could not be made'; n=$AC_N; cp -R "$CHECKS" checks; [ ! -d skills ] || fail 'the toy holds skills'
rv_pr merge b1 "ticket: #$n" app/a.txt a; C=$RV_M; h=$(printf %.12s "$C"); id=step-$n-$h; ac_head "$C"
sh checks/github.sh results-fetch > "$T/out" 2>&1 && sh checks/round.sh read > "$T/out" 2>&1 || fail 'the fetch failed'
call prepare; [ "$RC" = 0 ] && grep -q "^brief $id " "$T/out" || fail 'prepare, as the skill writes it, failed'
W=.vid/round/review/$id; R=.vid/decide/review; printf 'ROW-001 kept — seen\nROW-012 unclear — which page?\n' > "$W/grade.txt"
RC=0; sh checks/review.sh record "$id" "$W/grade.txt" > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q "pass is not found" "$T/out" && [ ! -e "$R/grade-$id-1" ] || fail 'a record with no pass to find saved the grade, or was not refused'
! git --git-dir=.vid/code rev-parse -q --verify "refs/heads/vid-results/grade-$id-1" > /dev/null 2>&1 || fail 'the refused record left a report'
call record; [ "$RC" = 0 ] && grep -qx "to-sort 1 $W/sort-brief.md" "$T/out" && [ -f "$R/grade-$id-1/grade.txt" ] && [ -f "$R/grade-$id-1/prs" ] && grep -q 'ROW-012 unclear' "$W/sort-brief.md" || fail 'record, as the skill writes it, did not record and make the second reviewer'"'"'s brief'
printf 'ROW-012 drop it — no one can — ROW-012 unclear — which page?\n' > "$W/sorted.txt"; call sorted; [ "$RC" = 0 ] && grep -qx "recorded $id" "$T/out" || fail 'sorted, as the skill writes it, failed'
for s in vid-accept-step vid-stage-close vid-grade; do grep -oE '`[^`]*sh checks/review\.sh (prepare|record|sorted|due)[^`]*`' "$PR/skills/$s/SKILL.md" > "$T/out" || fail "$s names no review call"; grep -v '^`CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review' "$T/out" > "$T/b" || :; [ ! -s "$T/b" ] || { cp "$T/b" "$T/out"; fail "$s writes a call without the plugin's root"; }; done
exit 0
