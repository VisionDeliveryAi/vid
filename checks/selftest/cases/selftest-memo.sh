#!/bin/sh
# Purpose: selftest case — the law commit's self-test memo (v0.9.5 spec 3.9,
# R9; §7 case 12). A toy project: stub courts under the real hook, a copy
# of run.sh, one shipped case (listed in selftest/shipped) and one
# generated case (unlisted), each leaving a mark when it runs. Convicts
# unless: a law commit changing only INVENTORY.md rows, after one full run,
# skips the shipped case (and says so) but still runs the generated one; a
# change under checks/ runs the whole suite; so does a changed environment
# line (the locale); with git older than 2.32 the memo is neither read nor
# written; a global git setting that would make scratch commits fail —
# commit.gpgsign with a failing signer, set directly or through a
# conditional include — changes no case's outcome, serial or memoised; and,
# in the plugin repository, selftest/shipped lists exactly the shipped
# cases. v0.9.7.3 (R6): the memo is the certificate, <git common dir>/vid-selftest/<key>. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "selftest-memo: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
if [ -f "$CHECKS/../RECORDS.md" ] && [ -d "$CHECKS/../skills/vid-develop" ]; then
  ( cd "$CHECKS/selftest/cases" && ls *.sh ) | LC_ALL=C sort > "$T/cases"
  grep -v '^#' "$CHECKS/selftest/shipped" | grep -v '^$' | LC_ALL=C sort > "$T/listed"
  cmp -s "$T/cases" "$T/listed" || { diff "$T/cases" "$T/listed" >&2; fail 'selftest/shipped does not list exactly the shipped cases'; }
fi
cd "$T"; mkdir p; cd p
. "$CHECKS/selftest/fixtures/stub-courts.sh"
mkdir -p checks/selftest/cases
cp "$CHECKS/selftest/run.sh" checks/selftest/run.sh
printf '#!/bin/sh\n# Purpose: a shipped case\necho x >> "%s/shipped.ran"\nexit 0\n' "$T" > checks/selftest/cases/shipped-one.sh
printf '#!/bin/sh\n# Purpose: a generated case\necho x >> "%s/generated.ran"\nexit 0\n' "$T" > checks/selftest/cases/gen-routes.sh
printf '# Purpose: the cases the plugin ships\nshipped-one.sh\n' > checks/selftest/shipped
printf 'INVENTORY.md vid-inventory\n' > checks/lawfiles
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x\n```\n' > INVENTORY.md
g add -A && g commit -qm 'a project with a suite'
runs() { [ -f "$T/$1.ran" ] && grep -c . "$T/$1.ran" || echo 0; }
row() { printf 'ROW-%03d | behavior | REQ-001 | n/a | n/a | row %s | REQ-001 | owed: prerequisite — x\n' "$1" "$1" > "$T/r"
  awk -v r="$(cat "$T/r")" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > "$T/i" && mv "$T/i" INVENTORY.md; g add INVENTORY.md; }
law() { sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail "the law commit was refused: $1"; g commit -qm "$1" --no-verify; }
row 2; law 'first law commit'
[ "$(runs shipped)" -eq 1 ] && [ "$(runs generated)" -eq 1 ] || fail 'the first law commit did not run the whole suite'
CERT() { printf '%s/vid-selftest\n' "$(cd "$(git rev-parse --git-common-dir)" && pwd -P)"; }
[ -n "$(ls "$(CERT)" 2>/dev/null)" ] || fail 'no memo after a full pass'
row 3; law 'rows only'
grep -q "selftest: ViD's shipped checks unchanged since their last pass — skipped (memo)" "$T/out" || fail 'the rows-only law commit did not say it skipped'
[ "$(runs shipped)" -eq 1 ] || fail 'the rows-only law commit ran the shipped case'
[ "$(runs generated)" -eq 2 ] || fail 'the rows-only law commit skipped the generated case'
tail -n 1 .vid/hook-times | grep -q ' selftest=memo ' || fail 'the timing line does not say memo'
printf '# a note\n' >> checks/seams.sh; g add checks/seams.sh
VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the checks/ change was refused'; g commit -qm checks --no-verify
[ "$(runs shipped)" -eq 2 ] || fail 'a change under checks/ skipped the suite'
row 4; LC_ALL=C law 'a changed locale'
[ "$(runs shipped)" -eq 3 ] || fail 'a changed environment line skipped the suite'
# git older than 2.32: no memo read or written
REAL=$(command -v git); mkdir -p "$T/oldgit"
printf '#!/bin/sh\nif [ "$1" = --version ]; then echo "git version 2.31.0"; exit 0; fi\nexec "%s" "$@"\n' "$REAL" > "$T/oldgit/git"; chmod +x "$T/oldgit/git"
rm -rf "$(git rev-parse --git-path vid-memo)" "$(CERT)"
row 5; PATH="$T/oldgit:$PATH" law 'old git, first'
[ -z "$(ls "$(CERT)" 2>/dev/null)" ] || fail 'a memo was written under git 2.31'
row 6; PATH="$T/oldgit:$PATH" law 'old git, second'
[ "$(runs shipped)" -eq 5 ] || fail 'the suite was skipped under git 2.31'
# a hostile global configuration changes no case's outcome
mkdir -p "$T/home"
printf '[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n[includeIf "gitdir:/"]\n\tpath = %s/home/evil.gitconfig\n' "$T" > "$T/home/.gitconfig"
printf '[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n' > "$T/home/evil.gitconfig"
printf '#!/bin/sh\n# Purpose: a case of the shipped shape\nset -eu\nS=$(mktemp -d); trap '"'"'rm -rf "$S"'"'"' EXIT\ncd "$S"; git init -q; echo y > y; git add y\ngit -c user.email=vid@selftest -c user.name=vid commit -qm scratch\n' > checks/selftest/cases/shipped-one.sh
HOME="$T/home" XDG_CONFIG_HOME="$T/home" sh checks/selftest/run.sh > "$T/out" 2>&1 || fail 'a global gpgsign setting failed the serial suite'
HOME="$T/home" XDG_CONFIG_HOME="$T/home" VID_SELFTEST_UNLISTED=1 sh checks/selftest/run.sh > "$T/out" 2>&1 || fail 'a global gpgsign setting failed the memoised suite'
exit 0
