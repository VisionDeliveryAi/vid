#!/bin/sh
# Purpose: selftest case — the compulsory re-read (v0.9.7.0.6 spec 3.8,
# R11; §6 C-4, C-5), on hook inputs shaped as Claude Code sends them. Needs
# the plugin's hooks/ beside checks/. Convicts unless hooks.json registers
# hooks/reread.sh for PreToolUse (every tool) and PostToolUse (Read); and,
# after the page: a main-session Bash call is denied with the documented
# deny output, naming the unpaid paths and the debt file; Read is allowed;
# a read whose response is truncated pays nothing; a failed read
# (PostToolUseFailure) pays nothing; reads covering 1–400 and 402–814 leave
# the file unpaid and adding 401 pays it; one complete response pays a
# file; two parallel paying reads both count, and after the last listed
# file the debt file is gone and Bash is allowed; an agent's call is
# allowed and an agent's read pays nothing; two sessions — S1 compacts, S2
# resumes — S1 stays denied while S2 pays and is freed; a debt at home H
# holds a main-session call whose cwd is a linked worktree resolving to H;
# malformed input, no debt file and a non-ViD directory are allowed; and
# `observe.sh resume` prints each session's owed line while its file
# stands, and not after. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reread
. "$CHECKS/selftest/fixtures/reread-lib.sh"
J=$(tr -d ' \n' < "$HD/hooks.json")
printf '%s' "$J" | grep -q '"PreToolUse":\[{"hooks":\[{"type":"command","command":"sh\\"${CLAUDE_PLUGIN_ROOT}/hooks/reread.sh\\""' || fail 'hooks.json does not register reread.sh for every PreToolUse'
printf '%s' "$J" | grep -q '"PostToolUse":\[{"matcher":"Read","hooks":\[{"type":"command","command":"sh\\"${CLAUDE_PLUGIN_ROOT}/hooks/reread.sh\\""' || fail 'hooks.json does not register reread.sh for PostToolUse Read'
OW="$H/.vid/reread-owed.S1"
owed() { (cd "$H" && sh checks/observe.sh resume) | grep "^resume: rules re-read owed by session $1 " || true; }
# no debt yet: allowed
pre Bash; allowed 'a call with no debt file'
page compact
pre Bash; denied 'Bash after the page'
for f in "$DV" "$TM" "$VV" "$VB"; do grep -qF "$f" "$T/pre.out" || fail "the refusal does not name $f"; done
grep -qF "The owner can delete $OW from another terminal to lift this." "$T/pre.out" || fail 'the refusal does not name the debt file'
grep -q '"hookEventName":"PreToolUse"' "$T/pre.out" && grep -q '"permissionDecisionReason":"ViD: your copy of this run' "$T/pre.out" || fail 'the deny output is not the documented form'
pre Read; allowed 'Read while the debt stands'
# C-5: the owed line while the file stands
owed S1 | grep -q "since 20[0-9-]*T[0-9:]*Z: $DV, $TM, $VV, $VB$" || fail "resume does not print S1's owed line: $(owed S1)"
# a truncated response and a failed read pay nothing
rd "$DV" 1 814 S1 "$H" '' truncated
printf '{"session_id":"S1","cwd":"%s","hook_event_name":"PostToolUseFailure","tool_name":"Read","tool_input":{"file_path":"%s"},"error":"no such file"}' "$H" "$DV" | sh "$PR/hooks/reread.sh"
grep -q '^cover ' "$OW" && fail 'a truncated or failed read paid'
# 1–400 and 402–814 leave the file unpaid; 401 pays it
rd "$DV" 1 400; rd "$DV" 402 413
pre Bash; denied 'Bash with line 401 unread'; grep -qF "$DV" "$T/pre.out" || fail 'the gap did not keep develop unpaid'
rd "$DV" 401 1; pre Bash; denied 'Bash with two files unread'
grep -qF "$DV" "$T/pre.out" && fail 'line 401 did not pay develop'
# an agent's read pays nothing; an agent's call is allowed
rd "$TM" 1 300 S1 "$H" a77; grep -q "^cover $TM " "$OW" && fail "an agent's read paid"
pre Bash S1 "$H" a77; allowed "an agent's call"
# two parallel paying reads both count; then the debt file is gone and Bash is allowed
rd "$TM" 1 300 & P1=$!; rd "$VV" 1 120 & P2=$!; rd "$VB" 1 150 & P3=$!; wait $P1; wait $P2; wait $P3
[ ! -e "$OW" ] || fail 'the debt file stands after every file was paid'
pre Bash; allowed 'Bash after every file was paid'
[ -z "$(owed S1)" ] || fail 'resume still prints S1 owed after paying'
# two sessions: S1 compacts, S2 resumes; S2 paying frees S2 only
page compact S1; page resume S2
for f in "$DV" "$TM" "$VV" "$VB"; do rd "$f" 1 "$(grep -c '' "$f")" S2; done
[ ! -e "$H/.vid/reread-owed.S2" ] || fail 'S2 did not pay'
pre Bash S2; allowed 'S2 after paying'
pre Bash S1; denied "S1 after S2 paid"
[ -n "$(owed S1)" ] && [ -z "$(owed S2)" ] || fail 'resume does not show S1 owed and S2 paid'
# another home: a linked worktree whose .vid/home names H
( cd "$H" && git worktree add -q "$T/W" -b w ); mkdir -p "$T/W/.vid"; printf '%s\n' "$H" > "$T/W/.vid/home"
pre Bash S1 "$T/W"; denied 'a main-session call from a linked worktree resolving to H'
# malformed input, a non-ViD directory: allowed
printf '{"session_id":"S1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":' "$H" | sh "$PR/hooks/reread.sh" > "$T/pre.out"; allowed 'malformed input'
mkdir -p "$T/plain"; ( cd "$T/plain" && git init -q ); pre Bash S1 "$T/plain"; allowed 'a non-ViD directory'
exit 0
