#!/bin/sh
# Purpose: selftest case — a project's law commit runs only the project's own self-test cases (v0.26.10.12.1, F-108).
# A toy project: stub courts under the real hook, a copy of run.sh, one shipped case (listed in selftest/shipped; it
# leaves a mark, then sleeps 30 s) and one generated case (unlisted, leaves a mark). Convicts unless: a law commit
# changing only INVENTORY.md rows, and a law commit changing checks/ (a refresh), each run the generated case and never
# the shipped one, the hook's line timing both under 20 s; a global git setting that would make scratch commits fail
# (commit.gpgsign with a failing signer, set directly or through a conditional include) changes no case's outcome,
# whole suite or own cases only; and, in the plugin repository, selftest/shipped lists exactly the shipped cases.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "law-commit-own-cases: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
if [ -f "$CHECKS/../RECORDS.md" ] && [ -d "$CHECKS/../skills/vid-develop" ]; then
  ( cd "$CHECKS/selftest/cases" && ls *.sh ) | LC_ALL=C sort > "$T/cases"
  grep -v '^#' "$CHECKS/selftest/shipped" | grep -v '^$' | LC_ALL=C sort > "$T/listed"
  cmp -s "$T/cases" "$T/listed" || { diff "$T/cases" "$T/listed" >&2; fail 'selftest/shipped does not list exactly the shipped cases'; }
fi
cd "$T"; mkdir p; cd p
. "$CHECKS/selftest/fixtures/stub-courts.sh"
mkdir -p checks/selftest/cases
cp "$CHECKS/selftest/run.sh" checks/selftest/run.sh
printf '#!/bin/sh\n# Purpose: a shipped case\necho x >> "%s/shipped.ran"\nsleep 30\nexit 0\n' "$T" > checks/selftest/cases/shipped-one.sh
printf '#!/bin/sh\n# Purpose: a generated case\necho x >> "%s/generated.ran"\nexit 0\n' "$T" > checks/selftest/cases/gen-routes.sh
printf '# Purpose: the cases the plugin ships\nshipped-one.sh\n' > checks/selftest/shipped
printf 'INVENTORY.md vid-inventory\n' > checks/lawfiles
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x\n```\n' > INVENTORY.md
g add -A && g commit -qm 'a project with a suite'
runs() { [ -f "$T/$1.ran" ] && grep -c . "$T/$1.ran" || echo 0; }
quick() { _l=$(tail -n 1 .vid/hook-times); _st=$(printf '%s\n' "$_l" | sed -n 's/.* selftest=\([0-9]*\) .*/\1/p')
  [ -n "$_st" ] && [ "$_st" -lt 20 ] && [ "$(printf '%s\n' "$_l" | sed -n 's/.* seconds=\([0-9]*\) .*/\1/p')" -lt 20 ] || fail "$1 was not quick: $_l"; }
printf 'ROW-002 | behavior | REQ-001 | n/a | n/a | two | REQ-001 | owed: prerequisite — x\n' > "$T/r"
awk -v r="$(cat "$T/r")" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > "$T/i" && mv "$T/i" INVENTORY.md; g add INVENTORY.md
sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the rows law commit was refused'; g commit -qm rows --no-verify
[ "$(runs shipped)" -eq 0 ] || fail 'the rows law commit ran a shipped case'
[ "$(runs generated)" -eq 1 ] || fail 'the rows law commit did not run the generated case'
quick 'the rows law commit'
printf '# a note\n' >> checks/seams.sh; g add checks/seams.sh
VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the checks/ change was refused'; g commit -qm checks --no-verify
[ "$(runs shipped)" -eq 0 ] || fail 'a change under checks/ ran a shipped case'
[ "$(runs generated)" -eq 2 ] || fail 'a change under checks/ did not run the generated case'
quick 'the checks/ law commit'
# a hostile global configuration changes no case's outcome
mkdir -p "$T/home"
printf '[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n[includeIf "gitdir:/"]\n\tpath = %s/home/evil.gitconfig\n' "$T" > "$T/home/.gitconfig"
printf '[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n' > "$T/home/evil.gitconfig"
printf '#!/bin/sh\n# Purpose: a case of the shipped shape\nset -eu\nS=$(mktemp -d); trap '"'"'rm -rf "$S"'"'"' EXIT\ncd "$S"; git init -q; echo y > y; git add y\ngit -c user.email=vid@selftest -c user.name=vid commit -qm scratch\n' > checks/selftest/cases/shipped-one.sh
cp checks/selftest/cases/shipped-one.sh checks/selftest/cases/gen-routes.sh
HOME="$T/home" XDG_CONFIG_HOME="$T/home" sh checks/selftest/run.sh > "$T/out" 2>&1 || fail 'a global gpgsign setting failed the whole suite'
HOME="$T/home" XDG_CONFIG_HOME="$T/home" VID_SELFTEST_UNLISTED=1 sh checks/selftest/run.sh > "$T/out" 2>&1 || fail 'a global gpgsign setting failed the own cases'
exit 0
