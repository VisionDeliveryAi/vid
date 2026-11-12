#!/bin/sh
# Purpose: selftest case — the share's build over many files (0.26.10.28.9, S1). A made-up home of 160 records and a session with 45
# subagents (each with its .meta.json), over 250 files. Convicts unless: a private key with no END in one file does not swallow the
# next file; an empty file is in the bundle, empty; a file with a NUL past its first 64 KB and a file whose last byte is a NUL (no
# final newline) are left out as binary and listed; a file with no final newline is in the bundle, redacted; INDEX.md has a row for
# every subagent with its description; and the build starts at most 400 programs (each counted by a wrapper on PATH that logs it
# and runs the real one), where one program a file would start thousands. Then, as 4e7bb9c builds them: a file with a non-ASCII
# name kept; a source listed twice written under both names; left-out rows in the list's order; a description cut as cut -c1-120
# cuts it; a logs folder that is a git repository read whole, with no row leaving it out; a session named through a linked
# folder and .. read where the system finds it; a folder holding a .git link to nowhere kept, as 4e7bb9c kept it; an author named
# Vid leaving the records in; a project folder whose name holds a
# double quote built. Made-up values alone. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-bulk: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; export HOME="$T/h/$U/wren"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; export USERNAME=wren
printf '[user]\n\temail = wren@example.test\n\tname = Wren\n' > "$T/gitconfig"; export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
export VID_SHARE_HOST=box-z1
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
i=0; while [ $i -lt 160 ]; do printf 'record %d\nkey password=hunter2bulk%d\nplain line\n' $i $i > .vid/notes/r$i.md; i=$((i + 1)); done
printf -- '-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEAbulkbulkbulkbulkbulkbulkbulk\n' > .vid/notes/a-key.md
printf 'after the key, kept\n' > .vid/notes/b-after.md
: > .vid/notes/empty.md
awk 'BEGIN { for (i = 0; i < 1200; i++) printf "line %04d of a long record, nothing in it at all here\n", i }' > .vid/notes/nul64.md
printf 'x\000y\n' >> .vid/notes/nul64.md
printf 'line\nend\000' > .vid/notes/tailnul.md
printf 'no final newline, token=nofinalnl1234' > .vid/notes/nonl.md
D=$CLAUDE_CONFIG_DIR/projects/-proj; mkdir -p "$D/S-b/subagents"
printf '{"type":"user","timestamp":"2026-11-06T10:00:00Z","content":"start"}\n' > "$D/S-b.jsonl"
i=0; while [ $i -lt 45 ]; do
  printf '{"type":"assistant","timestamp":"2026-11-06T10:%02d:00Z","message":{"id":"msg_b%d","model":"m-1","usage":{"input_tokens":%d,"output_tokens":2}}}\n' $i $i $i > "$D/S-b/subagents/agent-a$i.jsonl"
  printf '{"agentType":"general","description":"task %d of the bulk"}\n' $i > "$D/S-b/subagents/agent-a$i.meta.json"; i=$((i + 1)); done
printf 'session id=S-b source=startup transcript=%s/S-b.jsonl at=2026-11-06T10:00:00Z\n' "$D" > .vid/metrics-events
# the counting wrappers: one a program, first on PATH
mkdir -p "$T/w"; : > "$T/progs"
for p in awk sed grep cat tr wc sort uniq mkdir mv cp rm gzip dirname basename cut find head tail tar date git hostname uname mktemp dd paste xargs tee sh ls stat touch chmod ln od cmp diff env; do
  r=$(command -v "$p" 2>/dev/null) || continue; case "$r" in /*) ;; *) continue ;; esac
  printf '#!/bin/sh\nprintf "%%s\\n" "%s" >> "%s"\nexec "%s" "$@"\n' "$p" "$T/progs" "$r" > "$T/w/$p"; chmod +x "$T/w/$p"
done
PATH="$T/w:$PATH" sh checks/share.sh build --run 2026-11-b > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
N=$(wc -l < "$T/progs" | tr -d ' ')
B=.vid/shares/2026-11-b; NF=$(find "$B" -type f | wc -l | tr -d ' '); [ "$NF" -gt 250 ] || fail "only $NF files in the bundle"
[ "$(cat "$B/records/.vid/notes/b-after.md")" = 'after the key, kept' ] || fail "the file after a key with no END was swallowed: $(cat "$B/records/.vid/notes/b-after.md")"
grep -q 'REDACTED:private-key' "$B/records/.vid/notes/a-key.md" && ! grep -q bulkbulk "$B/records/.vid/notes/a-key.md" || fail 'the key with no END is not redacted'
[ -f "$B/records/.vid/notes/empty.md" ] && [ ! -s "$B/records/.vid/notes/empty.md" ] || fail 'the empty file is not in the bundle, empty'
for f in nul64.md tailnul.md; do
  [ ! -e "$B/records/.vid/notes/$f" ] || fail "$f, which holds a NUL, is in the bundle"
  grep -q "\"records/.vid/notes/$f\", \"binary" "$B/MANIFEST.json" || fail "$f is not listed as left out, binary"
done
[ "$(cat "$B/records/.vid/notes/nonl.md")" = 'no final newline, token=[REDACTED:secret-assignment]' ] || fail "the file with no final newline: $(cat "$B/records/.vid/notes/nonl.md")"
R=$(grep -c '| task [0-9]* of the bulk |' "$B/conversations/INDEX.md" || true); [ "$R" = 45 ] || fail "INDEX.md has $R subagent rows of 45"
[ "$N" -le 400 ] || fail "the build started $N programs, over 400: $(awk '{ n[$0]++ } END { for (p in n) printf "%s %d, ", p, n[p] }' "$T/progs")"
# as 4e7bb9c built them: a file with a non-ASCII name kept; a source listed twice (the logs folder inside the records) written
# under both names; left-out rows in the list's order; a subagent's description cut as cut -c1-120 cuts it in the same locale
DS=$(awk 'BEGIN { s = "review"; for (i = 0; i < 70; i++) s = s " \303\251"; print s }')
printf '{"agentType":"general","description":"%s"}\n' "$DS" > "$D/S-b/subagents/agent-a0.meta.json"
printf 'u\n' > "$(printf '.vid/notes/caf\303\251.md')"; printf 'x\000y\n' > .vid/notes/a0.bin; printf 'not a gzip\n' > .vid/notes/b0.gz
mkdir -p .vid/d; ln -s "$T/nowhere" .vid/d/.git; printf 'd\n' > .vid/d/d.md
if locale -a 2>/dev/null | grep -qx 'en_US.UTF-8'; then export LANG=en_US.UTF-8; fi
sh checks/share.sh build --run 2026-11-b2 --logs "$P/.vid/notes" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the second build failed'; }
B=.vid/shares/2026-11-b2
[ -f "$B/$(printf 'records/.vid/notes/caf\303\251.md')" ] || fail "the file with a non-ASCII name is not in the bundle: $(grep -a caf "$B.summary")"
[ -f "$B/records/.vid/d/d.md" ] || fail 'a folder holding a .git link to nowhere is left out whole'
[ -f "$B/records/.vid/notes/r1.md" ] && [ -f "$B/logs/r1.md" ] || fail 'a source listed twice is not written under both names'
awk '/"left_out"/ { p = 1 } p && /a0\.bin|b0\.gz/ { print }' "$B/MANIFEST.json" | sed 's/^ *\["//; s/".*//' | paste -sd ' ' - > "$T/lo"
[ "$(cat "$T/lo")" = 'records/.vid/notes/a0.bin records/.vid/notes/b0.gz logs/a0.bin logs/b0.gz' ] || fail "the left-out rows are out of order: $(cat "$T/lo")"
X=$(printf '%s' "$DS" | cut -c1-120); grep -qF "| $X |" "$B/conversations/INDEX.md" || fail 'the description is not cut as cut -c1-120 cuts it'
# a logs folder that is a git repository is read whole, with no row leaving it out
mkdir -p "$T/lg/sub"; ( cd "$T/lg" && git init -q ); printf 'a log\n' > "$T/lg/x.log"; printf 'b\n' > "$T/lg/sub/b.txt"
# and a session named by a path through a linked folder and .., read where the system finds it (the link's target's parent)
mkdir -p "$T/r/other/sub"; ln -s other/sub "$T/r/link"; printf '{"type":"user","content":"linked"}\n' > "$T/r/other/S-l.jsonl"
sh checks/share.sh build --run 2026-11-b3 --logs "$T/lg" --session "$T/r/link/../S-l.jsonl" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the third build failed'; }
! grep -q '"logs/\."' .vid/shares/2026-11-b3/MANIFEST.json || fail 'the logs folder itself is listed as left out'
gzip -dc .vid/shares/2026-11-b3/conversations/S-l/S-l.jsonl.gz 2>/dev/null | grep -q linked || fail "the session named through a link and .. is not in the bundle: $(grep -o 'S-l[^]]*' .vid/shares/2026-11-b3/MANIFEST.json | head -n 2 | paste -sd ' ' -)"
[ -f .vid/shares/2026-11-b3/logs/x.log.gz ] && [ -f .vid/shares/2026-11-b3/logs/sub/b.txt ] || fail "the logs folder's files are not in the bundle"
# a project whose folder name holds a double quote builds; an author named Vid leaves the records in (.vid is no name)
printf '[user]\n\temail = vid@example.test\n\tname = Vid Novak\n' > "$T/gitconfig"
Q=$T/toy\"proj; mkdir -p "$Q/checks" "$Q/.vid"; cp "$CHECKS/share.sh" "$Q/checks/"; ( cd "$Q" && git init -q && printf 'run: active\n' > .vid/RUN-STATE.md
  sh checks/share.sh build --run 2026-11-b4 --leave-out conversations > "$T/out" 2>&1 ) || { cat "$T/out" >&2; fail 'a project folder with a double quote in its name does not build'; }
[ -f "$Q/.vid/shares/2026-11-b4/records/.vid/RUN-STATE.md" ] || fail "with an author named Vid the records are left out"
echo "share-bulk: ok ($N programs)"
