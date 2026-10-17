#!/bin/sh
# Purpose: selftest case — section 6 is the real request command (v0.9.7.1 spec 3.2c, R2). The brief-write
# fixture with bw_builder. Convicts unless `write` refuses a builder brief and a fixer brief without --selection
# (naming it, writing nothing), and a grader brief given one; a builder brief's section 6 is `sh checks/test.sh
# request --type iterate --role builder --rows ROW-104,ROW-120 --try 2-builder-1 --why "<fill in>" --
# tests/invariants/surfaces.sh tests/invariants/links.sh` then the wait line; and with --deployed-selection
# the command ends `--deployed-selection <it>`; and, when the harness declares deployed-selector:, a builder brief
# for a (process) row is refused without --deployed-selection, naming the row (rehearsal R-2). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-command: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
for r in builder fixer; do
  if sh checks/brief.sh write --role $r --slice 2 --step S2 --rows ROW-104 > "$T/wout" 2>&1; then fail "a $r brief without --selection was written"; fi
  grep -qF -- '--selection' "$T/wout" || fail "the $r refusal does not name --selection"
done
[ ! -d .vid/briefs/2 ] || [ -z "$(ls .vid/briefs/2)" ] || fail 'a refused brief left a file'
if sh checks/brief.sh write --role grader --slice 2 --rows ROW-104 --receipt x --selection a > "$T/wout" 2>&1; then fail 'a grader brief took --selection'; fi
bw_write --role builder --slice 2 --step S2 --rows ROW-104,ROW-120 --selection 'tests/invariants/surfaces.sh tests/invariants/links.sh' || fail 'a builder brief was refused'
B=$(bw_out)
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$B"; }
sec 6 | grep -qxF 'sh checks/test.sh request --type iterate --role builder --rows ROW-104,ROW-120 --try 2-builder-1 --why "<fill in>" -- tests/invariants/surfaces.sh tests/invariants/links.sh' || fail "section 6 is not the real command: $(sec 6)"
sec 6 | grep -qxF 'sh checks/test.sh wait <ticket>' || fail 'section 6 has no wait'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --selection a --deployed-selection 'd1 d2' || fail 'a builder brief with a deployed selection was refused'
awk '/^## [0-9]/ { on = ($2 == 6); next } on' "$(bw_out)" | grep -qxF 'sh checks/test.sh request --type iterate --role builder --rows ROW-104 --try 2-builder-2 --why "<fill in>" -- a --deployed-selection d1 d2' || fail 'the deployed selection is not in the command'
# rehearsal R-2: a row only a deployed run credits (here a (process) row; the harness declares deployed-selector:)
printf 'x-vid-harness:\n  deployed-selector: -m deployed\n' > docker-compose.test.yml
sed 's#^\(ROW-104 | [^|]*| [^|]*| \)anonymous#\1(process)#' INVENTORY.md > INVENTORY.new && mv INVENTORY.new INVENTORY.md
grep -q '^ROW-104 | [^|]*| [^|]*| (process)' INVENTORY.md || fail 'fixture: ROW-104 is not a (process) row'
g add -A && g commit -qm 'a (process) row, a deployed selector'
if sh checks/brief.sh write --role builder --slice 2 --step S2 --rows ROW-104 --selection a > "$T/wout" 2>&1; then fail 'a brief for a row only a deployed run credits was written without its deployed selection'; fi
grep -qF -- 'ROW-104: only a deployed run credits it' "$T/wout" && grep -qF -- '--deployed-selection' "$T/wout" || fail 'the refusal does not name the row and --deployed-selection'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --selection a --deployed-selection d || fail 'the brief with its deployed selection was refused'
exit 0
