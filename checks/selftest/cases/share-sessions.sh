#!/bin/sh
# Purpose: selftest case — which transcripts a share takes (0.26.10.28.7, stage 3 R2). A toy project and a made-up Claude projects
# folder (CLAUDE_CONFIG_DIR): one transcript folder holding three sessions, of which the events name two (one by a `session`
# event, one only by an `agent-stop` event's subagent path), a third project's folder whose name shares the first's prefix, and a
# dev-side session in a folder of its own that no event names. Convicts unless the share takes exactly the two named sessions,
# each gzipped with its folder (a subagent and a tool result), and the dev-side session the user names by its id, and a fourth the
# user names by its exact path; the unnamed one and the prefix folder's are not taken. A `C:\…` transcript path in the events is
# read through its WSL mount (VID_SHARE_MOUNT standing in for /mnt); a `C:\…` path with nothing at its mount, and a plain path
# that does not exist, are each a conversations/MISSING.md row, named in the manifest and the summary. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-sessions: $*" >&2; cat "$T/out" >&2 2>/dev/null || true; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g')
mkdir -p "$PR/$E/S-one/subagents" "$PR/$E/S-one/tool-results" "$PR/$E/S-two/subagents" "$PR/$E-other" "$PR/-dev-side-work" "$T/elsewhere"
for s in S-one S-two S-three; do printf '{"sessionId":"%s","type":"user"}\n' "$s" > "$PR/$E/$s.jsonl"; done
printf '{"agent":"a1"}\n' > "$PR/$E/S-one/subagents/agent-a1.jsonl"; printf 'a tool result\n' > "$PR/$E/S-one/tool-results/r1.txt"
printf '{"agent":"b1"}\n' > "$PR/$E/S-two/subagents/agent-b1.jsonl"
printf '{"sessionId":"S-four"}\n' > "$PR/$E-other/S-four.jsonl"; printf '{"sessionId":"D-dev"}\n' > "$PR/-dev-side-work/D-dev.jsonl"
printf '{"sessionId":"X-path"}\n' > "$T/elsewhere/X-path.jsonl"
# a Windows Claude Code's transcript, seen under WSL at its mount
U=Users; WN='jo win'; M=$T/mnt; WD="$M/c/$U/$WN/.claude/projects/C--$U-jo-win-proj"; mkdir -p "$WD"
printf '{"sessionId":"W-win"}\n' > "$WD/W-win.jsonl"
{ printf 'session id=S-one source=startup transcript=%s vid=9.9.9 at=2026-11-04T10:00:00Z\n' "$PR/$E/S-one.jsonl"
  printf 'agent-stop session=S-two agent=b1 type=builder transcript=%s at=2026-11-04T10:05:00Z\n' "$PR/$E/S-two/subagents/agent-b1.jsonl"
  printf 'session id=W-win source=startup transcript="C:\\%s\\%s\\.claude\\projects\\C--%s-jo-win-proj\\W-win.jsonl" at=2026-11-04T11:00:00Z\n' "$U" "$WN" "$U"
  printf 'session id=W-gone source=startup transcript="C:\\%s\\%s\\.claude\\projects\\C--%s-jo-win-proj\\W-gone.jsonl" at=2026-11-04T11:10:00Z\n' "$U" "$WN" "$U"
  printf 'session id=S-lost source=startup transcript=%s at=2026-11-04T11:20:00Z\n' "$PR/$E/S-lost.jsonl"
} > .vid/metrics-events
VID_SHARE_MOUNT=$M sh checks/share.sh build --run 2026-11-s --session D-dev --session "$T/elsewhere/X-path.jsonl" > "$T/out" 2>&1 || fail 'the build failed'
B=.vid/shares/2026-11-s; C=$B/conversations
for s in S-one S-two D-dev X-path W-win; do [ -f "$C/$s/$s.jsonl.gz" ] && gzip -dc "$C/$s/$s.jsonl.gz" | grep -q "\"$s\"" || fail "$s not taken, gzipped"; done
gzip -dc "$C/S-one/subagents/agent-a1.jsonl.gz" | grep -q a1 || fail "S-one's subagent not taken"
grep -q 'a tool result' "$C/S-one/tool-results/r1.txt" || fail "S-one's tool result not taken"
gzip -dc "$C/S-two/subagents/agent-b1.jsonl.gz" | grep -q b1 || fail "S-two's subagent not taken"
for s in S-three S-four; do [ ! -e "$C/$s" ] || fail "$s taken, though no event or user names it"; done
N=$(cd "$C" && ls | grep -v '\.md$' | sort | tr '\n' ' '); [ "$N" = 'D-dev S-one S-two W-win X-path ' ] || fail "the sessions taken: $N"
grep -q '^| W-gone | .*WSL mount' "$C/MISSING.md" || fail 'the Windows path with nothing at its mount is no MISSING.md row'
grep -q '^| S-lost | .*not readable' "$C/MISSING.md" || fail 'the missing plain path is no MISSING.md row'
grep -q '"W-gone"' "$B/MANIFEST.json" && grep -q '"S-lost"' "$B/MANIFEST.json" || fail 'the manifest does not name the missing transcripts'
grep -q '^missing	W-gone	' "$B.summary" && grep -q '^missing	S-lost	' "$B.summary" || fail 'the summary does not name the missing transcripts'
echo 'share-sessions: ok'
