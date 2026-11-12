#!/bin/sh
# Purpose: selftest case — a conversation still being written while the share is built (0.26.10.28.9, S2). The live session's
# transcript grows by a line at every program the build starts (a wrapper on PATH appends it, then runs the real program), as a
# session that is still running writes. Convicts unless the transcript is in the bundle, unzips, and is not left out: the build
# reads one copy of it, never its size twice. Made-up values alone. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-growth: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; export HOME="$T/h/$U/wren"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; export USERNAME=wren
printf '[user]\n\temail = wren@example.test\n\tname = Wren\n' > "$T/gitconfig"; export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
export VID_SHARE_HOST=box-z1
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'a note\n' > .vid/notes/n.md
D=$CLAUDE_CONFIG_DIR/projects/-proj; mkdir -p "$D"; G=$D/S-g.jsonl
printf '{"type":"user","timestamp":"2026-11-06T10:00:00Z","content":"start"}\n' > "$G"
printf 'session id=S-g source=startup transcript=%s at=2026-11-06T10:00:00Z\n' "$G" > .vid/metrics-events
mkdir -p "$T/w"
for p in awk sed grep cat tr wc sort mkdir mv cp rm gzip dirname basename cut find head tail tar date git hostname uname mktemp dd xargs sh ls; do
  r=$(command -v "$p" 2>/dev/null) || continue; case "$r" in /*) ;; *) continue ;; esac
  printf '#!/bin/sh\nprintf "%%s\\n" "{\\"type\\":\\"assistant\\",\\"content\\":\\"still writing\\"}" >> "%s"\nexec "%s" "$@"\n' "$G" "$r" > "$T/w/$p"; chmod +x "$T/w/$p"
done
PATH="$T/w:$PATH" sh checks/share.sh build --run 2026-11-g > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-g
[ -f "$B/conversations/S-g/S-g.jsonl.gz" ] || fail "the growing transcript is not in the bundle: $(grep -o '"conversations/S-g[^]]*' "$B/MANIFEST.json" | head -n 1)"
gzip -dc "$B/conversations/S-g/S-g.jsonl.gz" | head -n 1 | grep -q '"content":"start"' || fail 'the growing transcript does not unzip to its first line'
if grep -F '"conversations/S-g/S-g.jsonl' "$B/MANIFEST.json" | grep -q binary; then fail 'the growing transcript is listed as left out'; fi
echo 'share-growth: ok'
