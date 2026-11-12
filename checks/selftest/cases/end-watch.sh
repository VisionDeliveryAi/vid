#!/bin/sh
# Purpose: selftest case — a false "complete" is noticed (v0.26.10.27.4, stage 8.3, R5), checks/observe.sh in ticket mode on the writer's
# toy made complete as end-complete makes it. The watcher's tick under `run: complete`, written by end.sh, raises nothing; a row then
# set failing in the handed record raises one `observe: notice` line, "the run says complete, but: <the first unmet condition>", and the
# FLAG; it changes nothing (RUN-STATE keeps run: complete). In ticket mode the loop's live test holds under run: complete. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "end-watch: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; ES=$CHECKS/end.sh; TAB=$(printf '\t'); R=owner/code
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
en() { RC=0; sh "$ES" complete "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > /dev/null 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide/stage/2/1 .vid/tw/out; : > .vid/round/read
X=$(git --git-dir="$T/code.git" rev-parse main); echo "$X" > .vid/decide/stage/2/1/commit; : > .vid/decide/stage/2/1/named; printf 'issue\t9\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\n' "$X" > .vid/decide/stage/2/1/ask
printf 'issue\t10\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\nreqs\tx\n' "$X" > .vid/decide/stage/2/1/s1ask; : > .vid/decide/stage/2/1/s1done; : > .vid/decide/stage/2/1/passed
sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$2 == "row" { print $1 }' > "$T/rows"; while read -r r; do tw_hand "row $r accepted"; done < "$T/rows"
sh "$CHECKS/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u > "$T/reqs"
while read -r q; do printf '%s\tpass\t1\n' "$q"; done < "$T/reqs" > .vid/decide/stage/2/s1
tw_hand "stage-closed 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"; sed 's/^VID-QUESTION: /RESOLVED: /' PRD.md > "$T/p" && cp "$T/p" PRD.md   # the toy's open questions answered
mkdir -p checks; ( cd "$CHECKS" && tar cf - . ) | ( cd checks && tar xf - ); printf 'mode: tickets\n' | grep -q . ; grep -q '^mode: tickets' .vid/RUN-STATE.md || fail 'the toy is not in ticket mode'
en; [ "$RC" = 0 ] || fail "not complete ($RC)"; grep -q '^run: complete$' .vid/RUN-STATE.md || fail 'no run: complete'
tick() { sh checks/observe.sh tick --now > "$T/tick.out" 2>&1 || true; }
tick; ! grep -q 'the run says complete, but' .vid/HEARTBEAT.md 2>/dev/null || fail 'a true complete raised the notice'
r=$(head -n 1 "$T/rows"); tw_hand "row $r failing"; tick
grep -q "| observe: notice — the run says complete, but: $r failing" .vid/HEARTBEAT.md || fail "no notice: $(grep 'observe:' .vid/HEARTBEAT.md 2>/dev/null | tail -n 3)"
grep -q 'observe: FLAG false-complete — the run says complete, but' .vid/HEARTBEAT.md || fail 'no FLAG'; grep -q '^run: complete$' .vid/RUN-STATE.md || fail 'the watcher changed run:'
tick; [ "$(grep -c 'observe: notice — the run says complete, but' .vid/HEARTBEAT.md)" = 1 ] || fail 'the notice was written twice'
echo 'end-watch: ok'
