#!/bin/sh
# Purpose: selftest case — a ticket is a builder brief carrying its tests (v0.26.10.9 spec R12; §5 ticket-brief). The
# brief writer's toy (fixtures/brief-write.sh, its builder plan in force) as a ViD repository in ticket mode, with a
# read-only copy of a local bare code repository at .vid/code, fetched after the replan session's start:
# `write --ticket` for step S1 writes `ticket: pending`, `base:` the copy's origin/main, `return: pull request`, no
# `first act:` (a fixer's ticket neither), the plan's shared: line in section 10, and section 16 with the stage, the
# step, the test file whole from ViD's copy, the instructions and the vid-return block listing the rows. It is refused
# while ViD's repository has an uncommitted change, and while the copy's last fetch is older than the session's start.
# `brief.sh <file>` refuses a section-16 test file differing by one byte from ViD's copy (the stamp re-made), and a
# brief whose base is no longer the copy's origin/main after the code repository moved. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "ticket-brief: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/vid"; bw_builder
printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n' > .vid/RUN-STATE.md
printf 'stage name=replan state=start session=S1 records=29 at=2026-10-24T10:00:00Z\n' >> .vid/metrics-events
git init -q --bare -b main "$T/code.git" 2>/dev/null || { git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; }
git clone -q "$T/code.git" "$T/dev" 2>/dev/null; ( cd "$T/dev" && git checkout -q -b main 2>/dev/null; g commit -q --allow-empty -m 'Initial commit' && git push -q origin main )
git clone -q "$T/code.git" .vid/code; git -C .vid/code fetch -q
BASE=$(git -C .vid/code rev-parse origin/main)
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 --ticket || fail 'write --ticket was refused'
B=$(bw_out); [ -f "$B" ] || fail 'no brief written'
grep -qx 'ticket: pending' "$B" && grep -qx "base: $BASE" "$B" && grep -qx 'return: pull request' "$B" || fail 'the header lacks ticket: pending, base: or return: pull request'
grep -q '^first act:' "$B" && fail 'a ticket carries a first act:'
grep -q "^return: $(pwd -P)" "$B" && fail 'a ticket names a return file'
sed -n '/^## 10 /,/^## 11 /p' "$B" | grep -qx 'shared: tests/invariants/harness.sh' || fail "section 10 does not quote the plan's shared: line"
grep -q '^## 16 ticket$' "$B" || fail 'no section 16'
sed -n '/^## 16 ticket$/,$p' "$B" > "$T/s16"
grep -q '^stage: 1    step: S1 — links$' "$T/s16" && grep -qx 'modules: app/' "$T/s16" || fail 'section 16 does not name the stage, the step and its modules'
awk '/^#### tests\/invariants\/links.sh$/ { w = 1; next } w && NF == 0 { next } w { w = 0; f = $0; on = 1; next } on && $0 == f { exit } on { print }' "$T/s16" > "$T/got"
git show HEAD:tests/invariants/links.sh | cmp -s - "$T/got" || fail 'section 16 does not carry links.sh whole'
grep -q '^### Instructions$' "$T/s16" && grep -q 'never edit, skip or weaken an\|Never edit, skip or weaken an' "$T/s16" || fail 'no instructions'
grep -q '^```vid-return$' "$T/s16" && grep -q '^  REQ-001/ROW-101   pass   ci: <run id>$' "$T/s16" && grep -q '^  REQ-002/ROW-102   pass   ci: <run id>$' "$T/s16" || fail 'the return block does not list the rows'
# a fixer's ticket has no first act either
bw_write --role fixer --slice 1 --step S1 --rows ROW-101 --ticket || fail 'a fixer ticket was refused'
F=$(bw_out); grep -q '^first act:' "$F" && fail "a fixer's ticket carries a first act:"
# refusals at write: an uncommitted change; a fetch older than the session
: > stray.txt; if bw_write --role builder --slice 1 --step S1 --rows ROW-101 --ticket; then fail 'write --ticket ran with an uncommitted change'; fi
grep -q 'uncommitted changes' "$T/wout" || fail 'the refusal does not name the uncommitted change'; rm -f stray.txt
touch -t 202001010000 "$(git -C .vid/code rev-parse --absolute-git-dir)/FETCH_HEAD"
if bw_write --role builder --slice 1 --step S1 --rows ROW-101 --ticket; then fail 'write --ticket ran on a copy not fetched in this session'; fi
grep -q 'not fetched in this session' "$T/wout" || fail 'the refusal does not name the stale fetch'
git -C .vid/code fetch -q; touch "$(git -C .vid/code rev-parse --absolute-git-dir)/FETCH_HEAD"
# the check: one byte changed in a section-16 test file, the stamp re-made
awk '/^#### tests\/invariants\/links.sh$/ { t = 1 } t && /^SURFACES|^# Purpose/ && !d { sub(/Purpose/, "Purpoze"); d = 1 } { print }' "$B" > "$T/b1"
grep -q Purpoze "$T/b1" || sed -n '/^#### tests\/invariants\/links.sh$/,+3p' "$B" >&2
grep -q Purpoze "$T/b1" || fail 'the toy edit did not apply'
awk '!/^written: brief\.sh write /' "$T/b1" > "$T/b1n"; H=$(git hash-object "$T/b1n")
awk -v h="$H" '/^written: brief\.sh write / { print "written: brief.sh write " h; next } { print }' "$T/b1" > "$T/b2"; cp "$T/b2" "$B"
if sh checks/brief.sh "$B" > "$T/wout" 2>&1; then fail 'a section-16 test file differing by one byte passed'; fi
grep -q 'section 16: tests/invariants/links.sh differs from ViD' "$T/wout" || fail 'the refusal does not name the differing file'
grep -q 'changed after writing' "$T/wout" && fail 'the stamp was not re-made — the case proves nothing'
# the code repository moves: the written brief's base is no longer origin/main
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 --ticket || fail 'the rewrite was refused'
B=$(bw_out); sh checks/brief.sh "$B" > "$T/wout" 2>&1 || fail 'a fresh ticket brief does not pass its check'
( cd "$T/dev" && g commit -q --allow-empty -m 'the skeleton' && git push -q origin main ); git -C .vid/code fetch -q
if sh checks/brief.sh "$B" > "$T/wout" 2>&1; then fail "a brief whose base is not the copy's origin/main passed"; fi
grep -q "is not the read-only copy's origin/main" "$T/wout" || fail 'the refusal does not name the base'
exit 0
