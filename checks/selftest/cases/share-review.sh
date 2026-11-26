#!/bin/sh
# Purpose: selftest case — the review page shows the user what they typed and the product data files touched, before a push
# (SHARE-SCRUB §4.5.3, §4.5.4). A main transcript holds two typed prompts (one a text-item array, one holding a made-up password
# after --password), a `!` command, a meta line, a tool result and a task notification; a subagent transcript holds its own
# prompt; Read and Write calls name seeds/users.sql, test/fixtures/a.json (twice) and src/app.ts. Convicts unless
# .vid/shares/<run>.review lists the three typed items (the password redacted) and none of the other text, lists the two data
# files with their counts and not src/app.ts, is not in the bundle, is readable by the user alone, and the summary has its review
# line and the caught-certain, caught-by-rule and not-caught lines. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-review: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md
t=$(date +%s | cksum | cut -c1-5); PW="pw${t}Kq"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E/S-v/subagents"
u() { printf '{"isSidechain":false,"type":"user","message":{"role":"user","content":%s},"timestamp":"2026-11-07T10:0%s:00Z"%s}\n' "$1" "$2" "${3:-}"; }
tool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"%s","input":{"file_path":"%s/%s"}}]}}\n' "$1" "$P" "$2"; }
{ u '"please build the login page"' 1 ',"origin":{"kind":"human"}'
  u '[{"type":"text","text":"set up with --password \"'"$PW"'\" first"}]' 2
  u '"<bash-input>ls seeds</bash-input>"' 3
  u '"<local-command-caveat>meta text here</local-command-caveat>"' 4 ',"isMeta":true'
  u '[{"tool_use_id":"toolu_01X","type":"tool_result","content":"tool output here"}]' 5
  u '"<task-notification>done</task-notification>"' 6 ',"origin":{"kind":"task-notification"}'
  tool Read seeds/users.sql; tool Write test/fixtures/a.json; tool Edit test/fixtures/a.json; tool Read src/app.ts; } > "$PR/$E/S-v.jsonl"
printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"the subagent prompt text"}}\n' > "$PR/$E/S-v/subagents/agent-a1b2c3d4e5f6a7b8c.jsonl"
printf 'session id=S-v source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-v.jsonl" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-v > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-v; R=$B.review
[ -f "$R" ] || fail 'no review page beside the bundle'
for s in 'please build the login page' 'set up with --password "[REDACTED:secret-flag]" first' 'ls seeds'; do grep -qF -- "$s" "$R" || fail "the review page does not show: $s"; done
for s in "$PW" 'meta text here' 'tool output here' 'the subagent prompt text' '<task-notification>done'; do grep -qF -- "$s" "$R" && fail "the review page shows what it must not: $(printf '%s' "$s" | cut -c1-12)…"; done
grep -q 'seeds/users.sql.*1' "$R" || fail 'the review page does not list seeds/users.sql with its count'
grep -q 'test/fixtures/a.json.*2' "$R" || fail 'the review page does not list test/fixtures/a.json with its count'
grep -qF 'src/app.ts' "$R" && fail 'the review page lists a file that is not product data'
find "$B" -name '*review*' | grep -q . && fail 'the review page is in the bundle'
case "$(ls -l "$R" | cut -c1-10)" in -rw-------|-r--------) ;; *) fail "the review page is readable by others: $(ls -l "$R" | cut -c1-10)" ;; esac
grep -q "^review	.vid/shares/2026-11-v.review	3	2$" "$B.summary" || fail "the summary's review line is not right: $(grep '^review' "$B.summary" || echo none)"
for k in caught-certain caught-by-rule not-caught; do grep -q "^$k	." "$B.summary" || fail "the summary has no $k line"; done
grep -q 'not-caught' "$B/MANIFEST.md" || grep -qi 'not caught' "$B/MANIFEST.md" || fail 'the manifest does not say what is not caught'
echo 'share-review: ok'
