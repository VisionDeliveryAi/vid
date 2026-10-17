#!/bin/sh
# Purpose: selftest case — the PRD court's memo (v0.9.5 spec 3.9, R9; §7
# case 11). The real PRD court on the known-good fixture, stub courts for
# the rest, under the real hook. Convicts unless: an unchanged second
# attempt prints `skipped (memo)` and times prd as `memo`; each of these
# runs the court — a staged PRD change, an unstaged PRD edit, a change under
# checks/, a changed seed file, bytes moved from the end of PRD.md to the
# start of the seed; a failed hash means no skip; a convicting edit is never
# skipped (and its passing text, restored, is); and at the installing
# commit, where HEAD carries no checks/, the memo is neither read nor
# written, so a retry after an unstaged edit makes checks/prd.sh refuse runs
# the court and is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; mkdir r; cd r
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp "$CHECKS/prd.sh" checks/prd.sh
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
g add -A && g commit -qm 'the court and the PRD'
fail() { echo "prd-memo: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
run() { sh checks/hooks/pre-commit > "$T/out" 2>&1; }
prdf() { tail -n 1 .vid/hook-times | tr ' ' '\n' | sed -n 's/^prd=//p'; }
ran() { case "$(prdf)" in [0-9]*) ;; *) fail "the court did not run: $1 (prd=$(prdf))" ;; esac; }
memo() { [ "$(prdf)" = memo ] && grep -q 'prd: unchanged since its last pass — skipped (memo)' "$T/out" || fail "no skip: $1 (prd=$(prdf))"; }
stage one; run || fail 'the first attempt was refused'; ran 'the first attempt'
[ -f "$(git rev-parse --git-path vid-memo)/prd" ] || fail 'no memo written after a pass'
stage two; run || fail 'the unchanged attempt was refused'; memo 'an unchanged second attempt'
printf '\n' >> PRD.md; g add PRD.md; run || fail 'a staged PRD change was refused'; ran 'a staged PRD change'
g commit -qm 'prd' --no-verify
printf '\n' >> PRD.md; stage three; run || fail 'an unstaged PRD edit was refused'; ran 'an unstaged PRD edit'
g add PRD.md; g commit -qm 'prd' --no-verify; stage four; run; memo 'the edit, committed'
g commit -qm 'app' --no-verify
printf '# a changed stub\n' >> checks/seams.sh; g add checks/seams.sh
VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the checks/ change was refused'; ran 'a change under checks/'
g commit -qm 'checks' --no-verify
stage five; run; memo 'after the checks/ change'
# a hash tool that fails on PRD.md alone: the key's own hash still works, so only the rule can prevent the skip
RS=$(command -v shasum || true); RS2=$(command -v sha256sum || true); mkdir -p "$T/bin"
printf '#!/bin/sh\ncase "$*" in *PRD.md*) exit 1 ;; esac\nexec "%s" "$@"\n' "${RS:-/nonexistent}" > "$T/bin/shasum"
printf '#!/bin/sh\ncase "$*" in *PRD.md*) exit 1 ;; esac\nexec "%s" "$@"\n' "${RS2:-/nonexistent}" > "$T/bin/sha256sum"
chmod +x "$T/bin/shasum" "$T/bin/sha256sum"
stage six; PATH="$T/bin:$PATH" sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the failed-hash attempt was refused'; ran 'a failed hash'
cp PRD.md "$T/good.md"
awk '!d && /^REQ-[0-9]+ \|/ && /fail-if:/ { sub(/fail-if:/, "failif:"); d = 1 } { print }' "$T/good.md" > PRD.md; g add PRD.md
if run; then fail 'a convicting edit passed'; fi; ran 'a convicting edit'
if run; then fail 'the same convicting edit passed at a retry'; fi; ran 'the same convicting edit, retried'
cp "$T/good.md" PRD.md; g add PRD.md; run || fail 'the restored text was refused'; memo 'the passing text, restored'
g commit -qm 'restored' --no-verify
# the seed in its own file
sh "$CHECKS/prd-consolidate.sh" PRD.md --date 2026-09-25 >/dev/null 2>&1 || fail 'consolidation failed'
grep -q '^Seed: SEED.md (sha256 ' PRD.md && [ -f SEED.md ] || fail 'no seed pointer (the fixture is wrong)'
g add -A; g commit -qm 'consolidated' --no-verify
stage seven; run || fail 'the consolidated PRD was refused'; ran 'the consolidated PRD'
stage eight; run; memo 'the consolidated PRD, unchanged'
cp SEED.md "$T/seed.keep"; printf 'x\n' >> SEED.md; g add SEED.md
if run; then fail 'a changed seed passed'; fi; ran 'a changed seed'
cp "$T/seed.keep" SEED.md; g add SEED.md; run; memo 'the seed restored'
cp PRD.md "$T/prd.keep"; L=$(tail -n 1 PRD.md)
sed '$d' "$T/prd.keep" > PRD.md; { printf '%s\n' "$L"; cat "$T/seed.keep"; } > SEED.md; g add PRD.md SEED.md
run || true; ran 'bytes moved from the end of PRD.md to the start of the seed'
cp "$T/prd.keep" PRD.md; cp "$T/seed.keep" SEED.md; g add PRD.md SEED.md
# the installing commit: HEAD carries no checks/
cd "$T"; mkdir i; cd i; git init -q
printf '# toy\n' > README.md; g add README.md; g commit -qm root
mkdir -p checks/hooks .ran .fail app
for c in placement conformance; do printf '#!/bin/sh\n# Purpose: stub\nexit 0\n' > "checks/$c.sh"; done
cp "$CHECKS/prd.sh" checks/prd.sh; cp "$CHECKS/hooks/pre-commit" checks/hooks/pre-commit; printf '# stub\n' > checks/lawfiles
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md; printf '.ran/\n.fail/\n.vid/\n' > .gitignore
g add -A
VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the installing attempt was refused'
[ ! -e "$(git rev-parse --git-path vid-memo)/prd" ] || fail 'a memo was written at the installing commit'
printf '#!/bin/sh\n# Purpose: the court, edited on disk and not staged\necho "prd: refused" >&2\nexit 1\n' > checks/prd.sh
if VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail 'the retry after an unstaged edit to checks/prd.sh passed'; fi
grep -q 'prd: refused' "$T/out" || fail 'the retry did not run the court'
exit 0
