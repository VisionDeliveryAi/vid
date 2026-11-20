#!/bin/sh
# Purpose: selftest case — the run card's version line when no session event names a version (0.26.11.1.4, R8). First, a
# project whose only session event carries vid=- and whose checks/ sits beside a .claude-plugin/plugin.json naming 9.8.7.6:
# RUN.md's version line is that version with its note, `9.8.7.6, the ViD that built this share (no session event names a
# version)`, never the bare version. Then a project with no session events and no plugin.json: the line is `unknown`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-version-fallback: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
mk() { mkdir -p "$1/checks" "$1/.vid"; cp "$CHECKS/share.sh" "$1/checks/"; ( cd "$1" && git init -q ); printf 'run: active\n' > "$1/.vid/RUN-STATE.md"; printf 'id=R-80\n' > "$1/.vid/run"; }
vl() { grep '^- \*\*ViD version:\*\* ' "$1/.vid/shares/$2/RUN.md" | sed 's/^- \*\*ViD version:\*\* //'; }
# the session event names no version; the plugin beside checks/ does
mk "$T/a"; mkdir -p "$T/a/.claude-plugin"; printf '{\n  "name": "vid",\n  "version": "9.8.7.6"\n}\n' > "$T/a/.claude-plugin/plugin.json"
printf 'session id=S-a source=startup model=claude-opus-5-5 vid=- at=2026-11-08T10:00:00Z\n' > "$T/a/.vid/metrics-events"
( cd "$T/a" && sh checks/share.sh build --run 2026-11-a ) > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the first build failed'; }
[ "$(vl "$T/a" 2026-11-a)" = '9.8.7.6, the ViD that built this share (no session event names a version)' ] || fail "with plugin.json, the version line: $(vl "$T/a" 2026-11-a)"
# no session event and no plugin.json
mk "$T/b"
( cd "$T/b" && sh checks/share.sh build --run 2026-11-b ) > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the second build failed'; }
[ "$(vl "$T/b" 2026-11-b)" = unknown ] || fail "with nothing naming a version, the version line: $(vl "$T/b" 2026-11-b)"
exit 0
