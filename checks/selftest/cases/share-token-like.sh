#!/bin/sh
# Purpose: selftest case — an unknown vendor's token is redacted by its shape, and the ids a share is made of are not
# (SHARE-SCRUB §4.3.5). Two made-up mixed-case tokens with digits, one in prose of a log and one in a JSON string of a transcript
# (after a \n escape). Kept byte for byte: a 40-hex commit id, a UUID, toolu_/msg_/req_/cse_ ids, a subagent's file name
# agent-a2a1…, a run id with a timestamp, a CamelCase identifier with no digit, HTTPServer, a kebab-case file name with a date.
# The session has a subagent transcript and a tool-results file. Convicts unless both tokens are gone (token-like), every kept
# item stays, and the subagent and tool-results files are in the bundle at their own paths. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-token-like: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md
t=$(date +%s | cksum | cut -c1-4)
K1="Qm7Rt2Xk${t}PzLw9VbNc4Hd"; K2="zT4kW9pQ${t}xR2mVn8sLb6C"
KEEP='commit 3f6c2a1b9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a
session 0e4e3237-acd5-48a1-bad2-464b02fda817
ids toolu_01AbCdEfGh2345IjKlMn6789 msg_01QrStUvWx2345YzAbCd6789 req_011CVabcDEF234ghiJKL567 cse_01RaBcDeFgHiJkLmNoPq12
file agent-a2a116553ec7a598c.jsonl
run run-20261125T143000Z-sel-1222428854
name getUserByIdFactorAuthentication and HTTPServer
file report-2026-11-25-final-version-two.md'
{ echo "the key is $K1 here"; printf '%s\n' "$KEEP"; } > "$T/dev/run.log"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E/S-t/subagents" "$PR/$E/S-t/tool-results"
printf '{"type":"user","message":{"content":"line\\n%s ok"}}\n' "$K2" > "$PR/$E/S-t.jsonl"
K3="Wb5Hs8Lq${t}cP3nXv7ZmR2T"; printf '{"type":"user","message":{"content":"caf\\u00e9%s ok"}}\n' "$K3" >> "$PR/$E/S-t.jsonl"   # a \u escape right before it
printf '{"type":"assistant","message":{"content":"sub"}}\n' > "$PR/$E/S-t/subagents/agent-a2a116553ec7a598c.jsonl"
printf 'tool output\n' > "$PR/$E/S-t/tool-results/beixob00m.txt"
printf 'session id=S-t source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-t.jsonl" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-t --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-t
{ cat "$T/out"; find "$B" -type f ! -name '*.gz' -exec cat {} +; find "$B" -type f -name '*.gz' -exec sh -c 'gzip -dc "$1"' _ {} \; ; } > "$T/all"
for x in "$K1" "$K2" "$K3"; do grep -qF -- "$x" "$T/all" && fail "a token is in the bundle: $(printf '%s' "$x" | cut -c1-3)…"; done
gzip -dc "$B/logs/run.log.gz" > "$T/log"
grep -qxF 'the key is [REDACTED:token-like] here' "$T/log" || fail 'the token in prose is not token-like'
gzip -dc "$B/conversations/S-t/S-t.jsonl.gz" | grep -qF '"content":"line\n[REDACTED:token-like] ok"' || fail 'the token after a \n escape is not token-like, or the escape is cut'
printf '%s\n' "$KEEP" | while IFS= read -r k; do grep -qxF -- "$k" "$T/log" || { echo "share-token-like: a line with no token changed: $k" >&2; exit 1; }; done
[ -f "$B/conversations/S-t/subagents/agent-a2a116553ec7a598c.jsonl.gz" ] || fail 'the subagent transcript is not in the bundle at its path'
ls "$B/conversations/S-t/tool-results/" | grep -q '^beixob00m\.txt' || fail 'the tool-results file is not in the bundle at its path'
gzip -dc "$B/conversations/S-t/S-t.jsonl.gz" | python3 -I -c 'import json,sys
for l in sys.stdin: json.loads(l)' || fail 'a transcript line no longer parses as JSON (an escape cut before a token)'
echo 'share-token-like: ok'
