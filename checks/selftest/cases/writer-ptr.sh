#!/bin/sh
# Purpose: selftest case — GM-4 F10's writer part: writer.sh's ptr, the rule for a pointer into ViD's records, is callable by
# another script, so no script writes it again. `sh writer.sh ptr` prints the awk functions ptr(<line>) and unptr(<line>), for a
# caller to prepend to its awk program as lib.sh's PROF is; it reads no project and writes nothing. Prepended, unptr writes a
# .vid/ path, a checks/<file> path and a claude.ai artifact link "(ViD's records)" and leaves a product's own src/checks/ path and
# the words "health checks/alarms" as they are; writer.sh defines ptr once, the functions its own check refuses by. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "writer-ptr: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"
sh "$CHECKS/writer.sh" ptr > "$T/f" 2> "$T/out" || fail 'writer.sh ptr failed'
[ -z "$(ls -A "$T" | grep -v -e '^f$' -e '^out$')" ] || fail 'writer.sh ptr wrote a file'
printf '%s\n' 'see .vid/tw/log for it' 'run checks/github.sh first' 'the page claude.ai/code/artifact/AbC123xyz' 'in src/checks/foo.py' 'the health checks/alarms' > "$T/in"
awk "$(cat "$T/f")"' { print unptr($0) }' "$T/in" > "$T/o" || fail 'the functions do not run in awk'
printf '%s\n' "see (ViD's records) for it" "run (ViD's records) first" "the page (ViD's records)" 'in src/checks/foo.py' 'the health checks/alarms' > "$T/want"
cmp -s "$T/o" "$T/want" || { diff "$T/want" "$T/o" > "$T/out" || :; fail 'unptr did not write the pointers as the writer writes them'; }
[ "$(grep -c 'function ptr(' "$CHECKS/writer.sh")" = 1 ] || fail 'writer.sh defines ptr more than once'
echo 'writer-ptr: ok'
