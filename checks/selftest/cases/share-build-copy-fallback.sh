#!/bin/sh
# Purpose: selftest case — the share's build when the rename into place fails (0.26.10.29.3, R9, F55), as a folder
# synced by a cloud drive refuses a rename while it syncs. A wrapper on PATH makes every `mv` of the bundle's building
# folder fail; `share.sh build` then copies it into place and removes the building folder, says so, and completes: the
# bundle and its manifest are there, the building folder is gone, and the scan finds nothing left. Made-up values
# alone. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-build-copy-fallback: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; export HOME="$T/h/$U/wren"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; export USERNAME=wren
printf '[user]\n\temail = wren@example.test\n\tname = Wren\n' > "$T/gitconfig"; export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
export VID_SHARE_HOST=box-z1
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md; printf 'a note\n' > .vid/notes/n.md
mkdir -p "$T/w"; M=$(command -v mv)
printf '#!/bin/sh\nfor a in "$@"; do case "$a" in *.building) echo "mv: rename $a: Permission denied" >&2; exit 1 ;; esac; done\nexec "%s" "$@"\n' "$M" > "$T/w/mv"; chmod +x "$T/w/mv"
RC=0; PATH="$T/w:$PATH" sh checks/share.sh build --run 2026-11-c > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the build failed when the rename into place failed ($RC)"
B=.vid/shares/2026-11-c
[ -f "$B/MANIFEST.json" ] && [ -f "$B/records/.vid/notes/n.md" ] || fail 'the bundle was not copied into place'
[ ! -e .vid/shares/.2026-11-c.building ] || fail 'the building folder was left behind'
grep -q 'copied' "$T/out" || fail 'the build does not say it copied the bundle into place'
sh checks/share.sh scan "$B" > "$T/out" 2>&1 || fail 'the copied bundle does not scan clean'
echo 'share-build-copy-fallback: ok'
