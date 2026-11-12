#!/bin/sh
# Purpose: selftest case — the share bundle describes itself (0.26.10.28.7, stage 3 R4). A toy run with events, a session with
# two assistant messages (one streamed twice under one id) and a side-chain line, and a subagent with its meta file. Convicts
# unless: MANIFEST.json and MANIFEST.md hold no absolute path (none starting /, ~/ or a drive letter, and none of the case's
# folders), name ViD's version, and give each source relative to its root; RUN.md has FORMAT's 12 fields in their order, each
# filled or `unknown`, and no money; conversations/INDEX.md has a row for the session and the subagent with their start, end,
# model, messages and tokens (each message counted once, the side chain left out of the session's) and no money column. With
# no findings file the bundle is still written and FINDINGS.md says so; a findings file in the hand-written form and one in the
# queue's form each give FINDINGS.md's table and findings/F-NNN.md with the fields the records do not give `unrated`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-manifest: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'id=R-77\n' > .vid/run; printf 'a log\n' > "$T/dev/a.txt"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); D=$PR/$E; mkdir -p "$D/S-m/subagents"
a() { printf '{"type":"assistant","timestamp":"%s","isSidechain":%s,"message":{"id":"%s","model":"claude-opus-5-5","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}}}\n' "$@"; }
{ printf '{"type":"user","timestamp":"2026-11-08T09:59:00.000Z","isSidechain":false}\n'
  a 2026-11-08T10:00:00.000Z false msg_1 10 5 100 3; a 2026-11-08T10:00:01.000Z false msg_1 10 5 100 7
  a 2026-11-08T10:30:00.000Z false msg_2 20 0 200 9; a 2026-11-08T10:31:00.000Z true msg_side 1000 1000 1000 1000; } > "$D/S-m.jsonl"
a 2026-11-08T10:10:00.000Z true msg_a 4 1 40 2 > "$D/S-m/subagents/agent-ab1.jsonl"
printf '{"agentType":"builder","description":"build step one"}\n' > "$D/S-m/subagents/agent-ab1.meta.json"
{ printf 'session id=S-m source=startup model=claude-opus-5-5 transcript=%s vid=9.9.7 at=2026-11-08T09:59:00Z\n' "$D/S-m.jsonl"
  printf 'agent-stop session=S-m agent=ab1 type=builder transcript=%s at=2026-11-08T12:14:00Z\n' "$D/S-m/subagents/agent-ab1.jsonl"; } > .vid/metrics-events
sh checks/share.sh build --run 2026-11-m --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-m
# the manifest: no absolute path, ViD's version, sources by root
for f in MANIFEST.json MANIFEST.md; do
  [ -f "$B/$f" ] || fail "no $f"
  L=$(grep -nE '(^|[^A-Za-z0-9._-])(/[A-Za-z0-9._-]|~/)|[A-Za-z]:[\\/]' "$B/$f" | grep -v '^[0-9]*:#' || true); [ -z "$L" ] || fail "$f holds an absolute path: $L"
  for x in "$T" "$P" "$CLAUDE_CONFIG_DIR" "$HOME"; do ! grep -qF -- "$x" "$B/$f" || fail "$f names a folder of this machine"; done
done
grep -q '"vid": "9.9.7"' "$B/MANIFEST.json" && grep -q 'ViD 9.9.7' "$B/MANIFEST.md" || fail "the manifest does not name ViD's version"
grep -qF '["records/.vid/", "home", ".vid",' "$B/MANIFEST.json" && grep -qF '["logs/", "logs", ".",' "$B/MANIFEST.json" && grep -qF "[\"conversations/S-m/\", \"claude-projects\", \"$E/S-m.jsonl\"," "$B/MANIFEST.json" || fail 'a source is not given relative to its root'
# RUN.md: the 12 fields in order, no money
H=$(grep '^## ' "$B/RUN.md" | tr '\n' '|'); [ "$H" = '## Project|## Run|## Dates|## Who and what|## Machines and tools|## Stand-ins|## Scope|## Outcome|## Costs|## Findings|## Open|## Links|' ] || fail "RUN.md's fields: $H"
awk '/^## / { if (h != "" && !c) { print h; exit 1 } h = $0; c = 0; next } NF { c = 1 } END { if (!c) { print h; exit 1 } }' "$B/RUN.md" > "$T/empty" || fail "a RUN.md field is neither filled nor unknown: $(cat "$T/empty")"
grep -q '^- \*\*Id:\*\* R-77$' "$B/RUN.md" && grep -q '^- \*\*Elapsed:\*\* 2h 15m$' "$B/RUN.md" && grep -q '| S-m | unknown | unknown | claude-opus-5-5 |' "$B/RUN.md" || fail 'RUN.md is not filled from the records'
grep -q 'input 34, cache read 340, cache write 6, output 18' "$B/RUN.md" || fail 'RUN.md does not give the tokens'
! grep -q '\$\|USD\|dollar\|price' "$B/RUN.md" || fail 'RUN.md gives money'
# INDEX.md: a row each, no money column
I=$B/conversations/INDEX.md
grep -qx '| S-m | 2026-11-08T09:59 | 2026-11-08T10:30 | claude-opus-5-5 | 2 | 30 | 300 | 5 | 16 | S-m/S-m.jsonl.gz |' "$I" || fail 'the session row is wrong (the side chain or a streamed message counted?)'
grep -qx '| ab1 | S-m | build step one | 2026-11-08T10:10 | 2026-11-08T10:10 | claude-opus-5-5 | 1 | 4 | 40 | 1 | 2 | S-m/subagents/agent-ab1.jsonl.gz |' "$I" || fail 'the subagent row is wrong'
! grep -qi '\$\|cost\|usd\|price\|dollar' "$I" || fail 'INDEX.md has a money column'
# no findings file: the bundle still written, FINDINGS.md says so
grep -q '^No findings file' "$B/FINDINGS.md" && [ ! -e "$B/findings" ] && [ -d "$B/records" ] || fail 'with no findings file, FINDINGS.md does not say so'
# the hand-written form
printf '# ViD findings\n\n## F-3 · The round stops when it should wait\n\n- **Seen:** 2026-11-08 · S02\n- **Where:** checks/round.sh\n- **What happened:** it stopped,\n  twice.\n- **Ask:** wait instead\n\n## F-4 · Second\n\n- **Cost:** 20 min\n' > .vid/VID-FINDINGS.md
sh checks/share.sh build --run 2026-11-f1 > "$T/out" 2>&1 || fail 'the build with findings failed'
F=.vid/shares/2026-11-f1
grep -q '^| 1 | \[F-001\](findings/F-001.md) | The round stops when it should wait | unrated | unrated | unrated | unrated | unrated |$' "$F/FINDINGS.md" || fail 'the first finding is not in the table'
grep -q '^| 2 | \[F-002\](findings/F-002.md) | Second | unrated | unrated | unrated | 20 min | unrated |$' "$F/FINDINGS.md" || fail 'the second finding is not in the table'
f=$F/findings/F-001.md; grep -q '^# F-001 · The round stops when it should wait$' "$f" && grep -q '^| Original id | F-3 in records/.vid/VID-FINDINGS.md |$' "$f" && grep -q '^| Class | unrated |$' "$f" && grep -q '^| Where | checks/round.sh |$' "$f" && grep -q '^  twice.$' "$f" && grep -q '^wait instead$' "$f" && grep -q '^| Cost | unrated |$' "$f" || fail 'F-001.md is not written from its finding'
# the queue's form
printf '# Findings\n\n## Note on the round\n- seen: 1\n- first: 2026-11-08T10:00Z\n- words: not a finding\n\n## S02: the head report\n- seen: 3\n- first: 2026-11-08T11:00Z\n- words: covers lines missed: the report could not read them\n' > .vid/VID-FINDINGS.md
sh checks/share.sh build --run 2026-11-f2 > "$T/out" 2>&1 || fail 'the build with queue findings failed'
F=.vid/shares/2026-11-f2
[ "$(grep -c '^| [0-9]' "$F/FINDINGS.md")" = 1 ] || fail 'the Note heading was not skipped'
grep -q '^| 1 | \[F-001\](findings/F-001.md) | covers lines missed | unrated |' "$F/FINDINGS.md" || fail 'the queue finding is not in the table'
grep -q '^| Seen | 2026-11-08T11:00Z · S02 · seen 3 times (queue.sh defect) |$' "$F/findings/F-001.md" || fail "the queue finding's Seen is not written"
echo 'share-manifest: ok'
