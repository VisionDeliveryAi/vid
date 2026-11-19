#!/bin/sh
# Purpose: selftest case — the walker is given the staging's mail and clock (0.26.11.1.2, R9, T-2 = GA-13), checks/close.sh,
# results.sh and walk.sh on the writer's toy and the fake gh (stage-seed-production.sh's set-up). The staging okay asks for `mail: <address>
# — <how to read it>` when the product sends mail and `clock: <address> — <how to move it>` when it acts on time. A D1 with neither gives the
# brief of today, its head the candidate, the staging and the sign-in lines alone; a D1 whose mail: line has no ` — ` is refused, naming it;
# one with both is read, the first of each kept, and its walk brief carries both lines after the sign-in lines. walker.md says how to use
# them, and that a journey needing mail or a wait the brief gives no way to is `not done — no inbox` or `not done — no clock`. Where
# devagent/ is beside checks/: deploy.sh writes the record's first mail: and clock: lines into staging.txt, a value starting / put on the
# staging's address, another as it is. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-walk-mail-clock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the walker's role
WM=$CHECKS/walker.md
grep -qF 'a `mail:` line' "$WM" && grep -qF 'a `clock:` line' "$WM" || fail 'walker.md does not say how to use the mail: and clock: lines'
grep -qF '`not done — no inbox`' "$WM" && grep -qF '`not done — no clock`' "$WM" || fail 'walker.md does not say what to answer with no mail: or clock: line'
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; RS=$CHECKS/results.sh; WS=$CHECKS/walk.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r" "$T/wk"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases seed=pass migrate=pass deploy=pass ready=pass)"; rr_put "$Q" staging.txt "$3"; rr_put "$Q" duties.txt "$DU"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'closed S01'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main)
ST='staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none\nseed: synthetic'
brief() { VID_WALK_TMP=$T/wk RC=0; VID_WALK_TMP=$T/wk sh "$WS" brief --stage "$1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "no brief for stage $1: $(cat "$T/out")"; BR=$(tail -n 1 "$T/out")/brief.md; }
# stage 1: the okay asks for both lines; a D1 with neither gives today's brief
K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
grep -qF 'When the product sends mail, also `mail: <address> — <how to read it>`' "$B" && grep -qF 'when it acts on time, `clock: <address> — <how to move it>`' "$B" || fail "the okay does not ask for the mail: and clock: lines: $(cat "$B")"
dp "$O" 1 "$(printf "$ST")"; fetch; cs decide --stage 1; ok '^d1 1 passed$'
mkdir -p $K/cs; printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > $K/cs/ask; : > $K/cs/passed; : > $K/cs/done
brief 1; [ "$(sed -n '1,6p' "$BR")" = "$(printf '# The walk\n\ncandidate: %s\nstaging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\n' "$X")" ] || fail "the brief with neither line is not today's: $(sed -n '1,8p' "$BR")"
! grep -qE '^(mail|clock):' "$BR" || fail 'the brief with neither line names a mail: or clock: line'
# stage 2: a mail: line with no dash is refused; both lines read, the first of each, and given to the walker
mkdir -p $K/w1; : > $K/w1/done; K2=.vid/decide/stage/2/1; mkdir -p $K2; cp $K/ask $K/commit $K2/; : > $K2/named; : > $K2/passed
cs okay --stage 2; ok '^asked [0-9]* okay stage-2$'; O2=$(sed -n 's/^asked \([0-9]*\) okay stage-2$/\1/p' "$T/out")
dp "$O2" 1 "$(printf "$ST\nmail: http://127.0.0.1:5001/_test/mail")"; fetch; sh "$RS" deploy --stage 2 > "$T/out" 2>&1
ok "^d1${TAB}refused${TAB}1${TAB}a mail: line is not <address> — <how to read it>: mail: http://127.0.0.1:5001/_test/mail\$"
dp "$O2" 1 "$(printf "$ST\nclock: http://127.0.0.1:5001/_test/clock")"; fetch; sh "$RS" deploy --stage 2 > "$T/out" 2>&1
ok "^d1${TAB}refused${TAB}1${TAB}a clock: line is not <address> — <how to move it>: clock: http://127.0.0.1:5001/_test/clock\$"
dp "$O2" 1 "$(printf "$ST\nmail: http://127.0.0.1:5001/_test/mail — open it; the newest message is first\nclock: http://127.0.0.1:5001/_test/clock — give it the time to move to\nmail: http://127.0.0.1:5001/other — a second inbox, not read")"
fetch; cs decide --stage 2; ok '^d1 2 passed$'
mkdir -p $K2/cs; cp $K/cs/ask $K2/cs/; : > $K2/cs/passed; : > $K2/cs/done
brief 2; [ "$(sed -n '5,7p' "$BR")" = "$(printf 'signin: subscriber http://127.0.0.1:5001/signin\nmail: http://127.0.0.1:5001/_test/mail — open it; the newest message is first\nclock: http://127.0.0.1:5001/_test/clock — give it the time to move to')" ] || fail "the brief does not carry the mail: and clock: lines after the sign-in lines: $(sed -n '1,9p' "$BR")"
[ "$(grep -c '^mail:' "$BR")" = 1 ] || fail 'the brief carries more than the first mail: line'
# deploy.sh, where devagent/ is beside checks/: the record's lines into staging.txt
if [ -d "$CHECKS/../devagent" ] && ! command -v nc > /dev/null 2>&1; then echo 'stage-walk-mail-clock: no nc, the deploy.sh part skipped' >&2
elif [ -d "$CHECKS/../devagent" ]; then
  DP=$CHECKS/../devagent/deployer/deploy.sh; T0=$T; T=$T0/da; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/devagent-project.sh"   # a project of its own, beside the toy
  cd "$T"; sp_project; W=$T/work; S=$W/dev-setup.txt; C=$(git -C "$T/dev" rev-parse HEAD)
  down() { sh "$DP" stop --setup "$S" --ask deploy-5 > /dev/null 2>&1 || true; }; trap 'down; rm -rf "$T0"' EXIT
  cat > "$S" <<X
repo: $T/origin.git
engines: alpha
environments: 1
ready-seconds: 5
start: [ -z "\${PORT:-}" ] || { nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"; }
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
signin: admin /_test/signin?role=admin
mail: /_test/mail — open it; the newest message is first
mail: /_test/other — a second inbox, not read
clock: https://clock.example/staging — set the time there
differs: none
X
  RC=0; sh "$DP" deploy --setup "$S" --ask deploy-5 --commit "$C" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the deploy failed ($RC)"
  git -C "$T/origin.git" show "vid-results/deploy-5-1:deploy-5-1/staging.txt" > "$T/st" || fail 'no staging.txt'
  P=$(sed -n 's|^staging: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p' "$T/st"); [ -n "$P" ] || fail "no staging: line: $(cat "$T/st")"
  [ "$(sed -n '2,4p' "$T/st")" = "$(printf 'signin: admin http://127.0.0.1:%s/_test/signin?role=admin\nmail: http://127.0.0.1:%s/_test/mail — open it; the newest message is first\nclock: https://clock.example/staging — set the time there' "$P" "$P")" ] || fail "staging.txt does not carry the record's first mail: and clock: lines: $(cat "$T/st")"
  [ "$(grep -c '^mail:' "$T/st")" = 1 ] || fail 'staging.txt carries more than the first mail: line'
  grep -qF 'mail: <address> — <how to read it>' "$DP" && grep -qF 'clock: <address> — <how to move it>' "$DP" || fail "deploy.sh's header does not list the two lines"
  grep -qF '`mail: <address> — <how to read it>`' "$CHECKS/../devagent/agents/dev-manager.md" && grep -qF '`clock: <address> — <how to move it>`' "$CHECKS/../devagent/agents/dev-manager.md" || fail "the dev manager's file does not list the two lines"
fi
exit 0
