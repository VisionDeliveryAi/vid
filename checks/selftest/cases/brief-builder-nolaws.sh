#!/bin/sh
# Purpose: selftest case — a builder brief carries no CLAUDE.md laws (v0.9.7.0.7 spec 3.2, R6; §6
# B-4). The brief-write fixture with bw_builder. Convicts unless a written builder brief has no
# section 4 and no line of CLAUDE.md's law sections; and, with a law section removed from CLAUDE.md,
# the builder brief is still written (it quotes none) while a fixer brief is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-nolaws: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
B=$(bw_out)
grep -qE '^## 4([^0-9]|$)' "$B" && fail 'the builder brief carries section 4'
grep -qxF -- '- Every import crosses a seam the table declares.' "$B" && fail 'the builder brief quotes a CLAUDE.md law'
awk '/^## Import law/ { skip = 1; next } skip && /^## / { skip = 0 } !skip' CLAUDE.md > CLAUDE.new && mv CLAUDE.new CLAUDE.md
g commit -qam 'no import law'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'a builder brief was refused for a law section it never quotes'
if bw_write --role fixer --slice 2 --step S2 --rows ROW-104; then fail 'a fixer brief was written without its law section'; fi
grep -qF "no '## Import law' section" "$T/wout" || fail 'the fixer refusal does not name the missing law section'
exit 0
