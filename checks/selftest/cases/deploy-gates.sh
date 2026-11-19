#!/bin/sh
# Purpose: selftest case — deploy's gate record (v0.9.6.2 spec 3.5, R5; §6
# case 19), and develop's production gate that refuses (0.26.11.1.2,
# R2). In a scratch project (the toy product of fixtures/stages.sh), every
# record-only call of checks/deploy-gate.sh — gates 1 and 2, end, skipped,
# confirm, rollback — writes its event through checks/event.sh and exits 0
# with nothing else recorded. `3 start` refuses (exit 1, one line naming the
# missing fact, nothing written) in order: no gate-2 pass; a gate-2 pass on
# another commit; no ready production check for the commit; gate 1 not
# passed since it, or its last record a fail; no cutover yes for the commit
# after gate 1 (a migration yes, or a yes for another commit, does not
# count; a no after the yes cancels it); a row owed to gate 1 unpaid
# (a gate-3 row is not); `stages.sh debt` failing; a second start with no
# new cutover yes; a first-deploy skip with a gate-3 start recorded, or with
# a production row in the deploy log. It writes the start once all five
# facts hold: after a law commit moved HEAD past the gate-2 pass, with a
# migration no after the cutover yes, and for the commit named in full, in
# short, or by a tag. `stages.sh debt --target production` prints the owed
# lines alone, with HEAD past the pass, for the tag's stage or every stage.
# DG, DE and RECORDS.md no longer say the gate never refuses (DE and
# RECORDS.md where they are). A call that does not parse writes nothing.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "deploy-gates: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/metrics-events >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks/lib"; cd "$T/p"; git init -q
[ -f "$CHECKS/deploy-gate.sh" ] || fail 'no checks/deploy-gate.sh'
for _f in deploy-gate.sh event.sh plan.sh run.sh stages.sh prd.sh eol.sh lib/wsl.sh; do [ ! -f "$CHECKS/$_f" ] || cp "$CHECKS/$_f" "checks/$_f"; done
printf '.vid/\n' > .gitignore; st_prd; st_inv
g add -A; g commit -qm 'the toy product'; P0=$(git rev-parse --short=12 HEAD)
printf 'two\n' > app.txt; g add app.txt; g commit -qm 'the candidate'; C=$(git rev-parse --short=12 HEAD); CF=$(git rev-parse HEAD)
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
EV=.vid/metrics-events
dg() { sh checks/deploy-gate.sh "$@" > "$T/out" 2>&1 || fail "deploy-gate.sh $* exited non-zero"; }
last() { tail -n 1 "$EV" | grep -qxE "$1 $ATRE" || fail "not written: $1"; }
nr() { if [ -f "$EV" ]; then grep -c . "$EV" || true; else echo 0; fi; }
# ref <why> [<candidate>]: 3 start refused, exit 1, one line naming why, nothing written
ref() { _n=$(nr); _rc=0; sh checks/deploy-gate.sh 3 start --candidate "${2:-$C}" --env production > "$T/out" 2>&1 || _rc=$?
  [ "$_rc" = 1 ] || fail "3 start was not refused (exit $_rc) when: $1"
  [ "$(grep -c . "$T/out")" = 1 ] && grep -q "^deploy-gate: refused — .*$1" "$T/out" || fail "the refusal does not name: $1"
  [ "$(nr)" = "$_n" ] || fail "a refusal wrote an event ($1)"; }
# ok3 [<candidate>]: 3 start written
ok3() { sh checks/deploy-gate.sh 3 start --candidate "${1:-$C}" --env production > "$T/out" 2>&1 || fail "3 start for ${1:-$C} was refused"
  last "deploy-gate gate=3 state=start candidate=${1:-$C} env=production"; }
pass2() { dg 2 start --candidate "$1" --env staging; dg 2 end --result pass; }
check() { printf 'deploy-check target=production sha=%s tests=full base=- regraded=0 result=ready at=2026-11-19T10:00:00Z\n' "$1" >> "$EV"; }
yes3() { dg confirm answer --what "cutover $1: deploy v1 to prod? migration: no; providers changing: none" --result "${2:-yes}"; }
born() { awk -v l="$1" '/^```$/ && !d { print l; d = 1 } { print }' INVENTORY.md > inv && mv inv INVENTORY.md; }

# fact 1: the newest gate-2 pass names the commit
ref 'no gate-2 pass is recorded'
pass2 "$P0"; ref "the newest gate-2 pass is on $P0, not on the candidate $C"
dg 2 start --candidate "$C" --env staging; dg 2 end --result fail; ref "the newest gate-2 pass is on $P0"
pass2 "$C"
# fact 2: a ready production check for it
ref 'no ready production check names'
check "$P0"; ref 'no ready production check names'
check "$C"
# fact 3: gate 1 for it, after the check
ref 'gate 1 has not passed'
dg 1 start --candidate "$C" --env rehearsal; dg 1 end --result fail; ref "gate 1's last record for $C is a fail"
dg 1 start --candidate "$C" --env rehearsal; dg 1 end --result pass; dg 1 start --candidate "$C" --env rehearsal; dg 1 end --result fail
ref "gate 1's last record for $C is a fail"
dg 1 start --candidate "$P0" --env rehearsal; dg 1 end --result pass; ref "gate 1's last record for $C is a fail"
dg 1 start --candidate "$C" --env rehearsal; dg 1 end --result pass
# a later end with no new start still belongs to the last start's commit
dg 1 end --result fail; ref "gate 1's last record for $C is a fail"
dg 1 start --candidate "$C" --env rehearsal; dg 1 end --result pass
# fact 4: the owner's cutover yes for it, after gate 1
ref 'no cutover yes'
dg confirm answer --what "migration for $C: run it now?" --result yes; ref 'no cutover yes'
yes3 "$P0"; ref 'no cutover yes'
yes3 "$C"; yes3 "$C" no; ref 'no cutover yes'
yes3 "$C"; dg confirm answer --what "migration for $C: keep the old column?" --result no
# a result= word inside the quoted question is not the answer
dg confirm answer --what "cutover $C: result=yes expected; proceed?" --result no; ref 'no cutover yes'
yes3 "$C"
# fact 5: no row owed to gate 1 or 2 unpaid; a law commit since the gate-2 pass moves HEAD
born 'ROW-008 | behavior | REQ-001 | anonymous | n/a | the backup restores | REQ-001 | owed: paid by /vid deploy gate 1 — a restored backup'
born 'ROW-009 | behavior | REQ-002 | anonymous | n/a | one real mail | REQ-002 | owed: paid by /vid deploy gate 2 — one real mail | paid-at: gate-2 2026-11-19 v0.1'
born 'ROW-010 | behavior | REQ-002 | anonymous | n/a | the live smoke | REQ-002 | owed: paid by /vid deploy gate 3 — the smoke'
g commit -qam 'three rows owed to the deploy'
[ "$(git rev-parse --short=12 HEAD)" != "$C" ] || fail 'HEAD did not move'
ref 'ROW-008 gate 1 is unpaid'
sh checks/stages.sh debt --target production > "$T/out" 2>&1 || fail 'stages.sh debt failed with HEAD past the gate-2 pass'
printf 'owed: ROW-008 gate 1\nowed: ROW-010 gate 3\n' | cmp -s - "$T/out" || fail "stages.sh debt printed other lines than the debt: $(cat "$T/out")"
mv INVENTORY.md inv.keep; ref 'the deploy debt cannot be read (checks/stages.sh debt)'; mv inv.keep INVENTORY.md
sed 's#^\(ROW-008 .*a restored backup\)$#\1 | paid-at: gate-1 2026-11-19 v0.1#' INVENTORY.md > inv && mv inv INVENTORY.md; g commit -qam 'ROW-008 paid at gate 1'
# all five hold: written, a gate-3 row unpaid and a migration no after the yes notwithstanding
ok3
# a second start needs a new cutover yes after the last one; the commit in full, in short, by a tag
ref 'no cutover yes'
yes3 "$CF"; ok3 "$CF"
yes3 "$C"; ok3 "$(git rev-parse --short=7 "$C")"
g tag v1 "$C"; yes3 v1; ok3 v1
g tag -a -m 'release two' v2 "$C"; yes3 "$C"; ok3 v2
ref "the newest gate-2 pass is on $C, not on the candidate $P0" "$P0"

# a first deploy: gate 1 skipped, while no gate-3 start and no production row are recorded
rm -f "$EV"; pass2 "$C"; check "$C"; dg 1 skipped --reason first-deploy; yes3 "$C"; ok3
yes3 "$C"; ref 'gate 1 was skipped as a first deploy, but a gate-3 start is recorded'
rm -f "$EV"; printf '# Deployment\n\n## Deploy log (append-only)\n\n| Version | Date | Commit | Migration | Backup ref | Previous build |\n|---|---|---|---|---|---|\n| v0.1 | 2026-11-19 | %s | no | - | - |\n' "$P0" > DEPLOYMENT.md
pass2 "$C"; check "$C"; dg 1 skipped --reason first-deploy; yes3 "$C"; ref "the deploy log holds a production row ($P0)"
rm -f DEPLOYMENT.md

# stages.sh debt in a staged project: the tag's stage at the gate-2 pass's commit, else every stage
born 'ROW-011 | behavior | REQ-004 | anonymous | n/a | the share smoke | REQ-004 | owed: paid by /vid deploy gate 2 — a real share'
st_cut; g add -A; g commit -qm 'the cut, and a stage-2 row owed to gate 2'; S1=$(git rev-parse --short=12 HEAD)
rm -f "$EV"; pass2 "$S1"
sh checks/stages.sh debt --target production > "$T/out" 2>&1 || fail 'stages.sh debt failed in a staged project'
printf 'owed: ROW-010 gate 3\nowed: ROW-011 gate 2\n' | cmp -s - "$T/out" || fail "with no stage tag, debt is not every stage's: $(cat "$T/out")"
g tag -a -m 'stage 1' vid/stage-1 "$S1"; printf 'later\n' > later.txt; g add later.txt; g commit -qm 'after the close'
sh checks/stages.sh debt --target production > "$T/out" 2>&1 || fail 'stages.sh debt failed with a stage tag'
printf 'owed: ROW-010 gate 3\n' | cmp -s - "$T/out" || fail "with vid/stage-1 at the pass, debt is not stage 1's: $(cat "$T/out")"
rm -f "$EV"; _rc=0; sh checks/stages.sh debt --target production > "$T/out" 2>&1 || _rc=$?
[ "$_rc" = 1 ] && grep -q '^debt: refused — no gate-2 pass is recorded' "$T/out" || fail 'stages.sh debt with no gate-2 pass did not exit 1'

# the record-only calls: written, never refused, with nothing else recorded
rm -f "$EV"
dg 1 skipped --reason first-deploy; last 'deploy-gate gate=1 state=skipped reason=first-deploy'
dg 1 start --candidate 0123456789ab --env rehearsal; last 'deploy-gate gate=1 state=start candidate=0123456789ab env=rehearsal'
dg 1 end --result fail; last 'deploy-gate gate=1 state=end result=fail'
dg confirm ask --what 'deploy v1 to prod? migration: no'; last 'deploy-confirm state=ask what="deploy v1 to prod\? migration: no"'
dg confirm answer --what 'deploy v1 to prod? migration: no' --result yes; last 'deploy-confirm state=answer what="deploy v1 to prod\? migration: no" result=yes'
dg 3 end --result fail --rollback-target v0; last 'deploy-gate gate=3 state=end result=fail rollback-target=v0'
dg rollback --gate 3 --why 'the smoke failed'; last 'deploy-rollback gate=3 why="the smoke failed"'
dg 2 start --candidate 0123456789ab --env staging; dg 2 end --result pass; last 'deploy-gate gate=2 state=end result=pass'
N=$(nr)
if sh checks/deploy-gate.sh 4 start --candidate x --env y 2>/dev/null; then fail 'gate 4 parsed'; fi
if sh checks/deploy-gate.sh confirm answer --what x --result maybe 2>/dev/null; then fail 'a result other than yes or no parsed'; fi
[ "$(nr)" -eq "$N" ] || fail 'a call that does not parse wrote something'

# the words: no "never refuses" left
: > "$T/out"
! tr '\n' ' ' < "$CHECKS/deploy-gate.sh" | grep -qi 'never[ #]*refuses' || fail 'deploy-gate.sh still says it never refuses'
if [ -f "$CHECKS/../RECORDS.md" ] && [ -f "$CHECKS/../skills/vid-deploy/SKILL.md" ]; then
  ! grep '^| `deploy-gate` ' "$CHECKS/../RECORDS.md" | grep -qi 'never refused' || fail "RECORDS.md's deploy-gate row still says never refused"
  ! tr '\n' ' ' < "$CHECKS/../skills/vid-deploy/SKILL.md" | grep -qi 'never  *refuses' || fail 'vid-deploy still says the script never refuses'
fi
exit 0
