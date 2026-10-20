#!/bin/sh
# Purpose: selftest case — an agent's usage in four kinds (v0.26.10.6 spec R17a). Needs the plugin's hooks/ beside
# checks/, so in a project it proves nothing and passes. A fixture transcript holds a streamed message's two entries
# (the first with partial output), a call with a 1-hour cache write, a `<synthetic>` entry, a progress line carrying a
# nested message, and calls of two models. Convicts unless a SubagentStop writes `agent-stop` first and then one
# `usage agent= session= tool=claude model=mixed effort= calls= input= cache-read= cache-write= cache-write-1h=
# output= scope=agent`, each message id counted once by its last entry, the synthetic and progress entries skipped;
# unless a resumed agent's second stop writes a cumulative record (its whole transcript again); unless one model
# alone reads as that model; unless a call whose 1-hour part exceeds its cache write (a transcript held one) counts
# its 1-hour part only up to its cache write; and unless a transcript not found writes agent-stop and no usage.
# Env: CHECKS.
set -eu
HD="$CHECKS/../hooks"
[ -f "$HD/stop-failure.sh" ] || exit 0
fail() { echo "usage-record-agent: $*" >&2; cat "${R:-.}/.vid/metrics-events" >&2 2>/dev/null || true; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
R="$T/run"; mkdir -p "$R/.vid" "$T/tr"; cd "$R"; git init -q
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
hook() { printf '%s' "$1" | ( cd "$T" && sh "$HD/record.sh" ); }
stop() { hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"SubagentStop\",\"agent_id\":\"$1\",\"agent_type\":\"vid:builder\",\"agent_transcript_path\":\"$2\"}"; }
A='{"type":"assistant","message":{"model":"%s","id":"%s","role":"assistant","content":[{"type":"text","text":"x"}],"usage":{"input_tokens":%d,"cache_creation_input_tokens":%d,"cache_read_input_tokens":%d,"output_tokens":%d,"cache_creation":{"ephemeral_1h_input_tokens":%d,"ephemeral_5m_input_tokens":0},"iterations":[{"input_tokens":999999,"output_tokens":999999}]}},"timestamp":"2026-10-20T10:00:00.000Z"}\n'
TR="$T/tr/agent-a1.jsonl"
{ printf '{"type":"user","message":{"role":"user","content":"brief"},"effort":"high"}\n'
  printf "$A" claude-opus-5-5 msg_1 10 100 1000 3 0       # a streamed message: the first entry's partial output
  printf "$A" claude-opus-5-5 msg_1 10 100 1000 40 0      # its last entry: counted
  printf "$A" claude-opus-5-5 msg_2 5 200 2000 7 150      # 150 of its 200 cache-write tokens for one hour
  printf "$A" '<synthetic>' msg_3 77 77 77 77 0           # skipped
  printf '{"type":"progress","data":{"message":{"type":"assistant","message":{"model":"x","id":"msg_9","usage":{"input_tokens":5000,"output_tokens":5000}}}}}\n'
  printf "$A" claude-sonnet-5 msg_4 1 0 500 2 0           # a second model: mixed
} > "$TR"
stop a1 "$TR" || fail 'the stop hook exited non-zero'
L1=$(sed -n 1p .vid/metrics-events); L2=$(sed -n 2p .vid/metrics-events)
printf '%s' "$L1" | grep -q '^agent-stop session=S1 agent=a1 ' || fail 'agent-stop is not written first'
printf '%s\n' "$L2" | grep -qxE 'usage agent=a1 session=S1 tool=claude model=mixed effort=high calls=3 input=16 cache-read=3500 cache-write=300 cache-write-1h=150 output=49 scope=agent at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' || fail "the usage record is not the transcript's sums: $L2"
# a resumed agent: its later stop covers its whole transcript, earlier runs included
printf "$A" claude-sonnet-5 msg_5 2 10 20 30 0 >> "$TR"
stop a1 "$TR"
tail -n 1 .vid/metrics-events | grep -q '^usage agent=a1 .* calls=4 input=18 cache-read=3520 cache-write=310 cache-write-1h=150 output=79 scope=agent ' || fail "the resumed agent's record is not cumulative: $(tail -n 1 .vid/metrics-events)"
# one model alone reads as that model
printf "$A" claude-opus-5-5 msg_1 1 2 3 4 0 > "$T/tr/agent-b2.jsonl"
stop b2 "$T/tr/agent-b2.jsonl"
tail -n 1 .vid/metrics-events | grep -q '^usage agent=b2 session=S1 tool=claude model=claude-opus-5-5 effort=unknown calls=1 input=1 cache-read=3 cache-write=2 cache-write-1h=0 output=4 scope=agent ' || fail "one model is not read as itself: $(tail -n 1 .vid/metrics-events)"
# a 1-hour part above its call's cache write is counted up to it
printf "$A" claude-opus-5-5 msg_1 0 0 0 0 35 > "$T/tr/agent-d4.jsonl"
stop d4 "$T/tr/agent-d4.jsonl"
tail -n 1 .vid/metrics-events | grep -q '^usage agent=d4 .* cache-write=0 cache-write-1h=0 ' || fail "a 1-hour part above its cache write: $(tail -n 1 .vid/metrics-events)"
# a transcript not found: agent-stop and no usage
N=$(grep -c '^usage ' .vid/metrics-events)
stop c3 "$T/tr/none.jsonl"
tail -n 1 .vid/metrics-events | grep -q '^agent-stop session=S1 agent=c3 ' || fail 'agent-stop is not written when the transcript is missing'
[ "$(grep -c '^usage ' .vid/metrics-events)" -eq "$N" ] || fail 'a usage record was written with no transcript'
exit 0
