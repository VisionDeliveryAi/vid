#!/bin/sh
# Purpose: selftest case — the commit-msg hook must reject a message with no
# Decisions: line. Exits 0 only if the court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"   # v0.9.6.2: a refusal writes an event in the current directory's run; never the project's
printf 'a change with no decisions line\n' > "$T/msg"
if sh "$CHECKS/hooks/commit-msg" "$T/msg" >/dev/null 2>&1; then exit 1; fi
exit 0
