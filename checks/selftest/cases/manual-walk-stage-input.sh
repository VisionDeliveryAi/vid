#!/bin/sh
# Purpose: selftest case — the walk's stage scope is read at the applied commit in GitHub manual (GM-4 E12, GM M3; walk.sh's stg). On
# the writer's toy, stage 1's walk due (CS passed, D1 read), with PRD.md, INVENTORY.md and STAGES.md each changed after .vid/tw/applied:
# walk.sh brief --stage 1 runs from a copy of checks/ whose stages.sh records, for each call walk.sh makes, the PRD.md, INVENTORY.md
# and STAGES.md it is handed, then runs the real stages.sh. At least one such call is made, and each is handed the applied
# versions, never the pending ones. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-walk-stage-input: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the copy of checks/: its stages.sh a wrapper of the real one, recording the walk's calls
cp -R "$CHECKS" "$T/ck"; STG_LOG=$T/calls; REAL=$CHECKS; export STG_LOG REAL
cat > "$T/ck/stages.sh" <<'WR'
#!/bin/sh
case $(ps -o command= -p "$PPID" 2>/dev/null) in *walk.sh*)
  { printf 'call %s\n' "$*"; for f in PRD.md INVENTORY.md STAGES.md; do printf '%s %s\n' "$f" "$( { cksum < "$f"; } 2>/dev/null | cut -d' ' -f1)"; done; } >> "$STG_LOG" ;; esac
exec sh "$REAL/stages.sh" "$@"
WR
tw_toy "$T/toy"; mkdir -p .vid/round .vid/decide
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied; A=$(cat .vid/tw/applied)
# pending: a requirement, a row and a stage placement, each after the applied commit
awk '{ print } /^REQ-001 \| / { print "REQ-099 | functional | T1 | A digest names its sender. | fail-if: a digest names no sender | serves: trust | authority: authoritative | source: seed | covers: DIM-notifications | phase: pilot | feature: FEAT-01" }' PRD.md > P.x && mv P.x PRD.md
awk '{ print } /^ROW-020 \| / { print "ROW-099 | behavior | REQ-099 | anonymous | n/a | A digest names its sender. Fails if a digest names no sender. | REQ-099 | owed: spec-only — first stage | origin: REQ-099" }' INVENTORY.md > I.x && mv I.x INVENTORY.md
awk '{ print } /^row: ROW-004 -> STAGE-0/ { print "row: ROW-001 -> STAGE-2" }' STAGES.md > S.x && mv S.x STAGES.md
g add PRD.md INVENTORY.md STAGES.md; g commit -qm 'a requirement, a row and a placement, not applied'
for f in PRD.md INVENTORY.md STAGES.md; do a=$(git show "$A:$f" | cksum | cut -d' ' -f1); [ "$a" != "$(cksum < "$f" | cut -d' ' -f1)" ] || fail "the toy left $f as applied"; echo "$f $a"; done > "$T/applied"
# stage 1's walk due: its candidate's ask, CS passed, D1 read
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p "$K/cs" "$K/d1" "$T/wk"
printf 'issue\t9\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$K/ask"; echo "$X" > "$K/commit"
printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$K/cs/ask"; : > "$K/cs/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$K/d1/read"
RC=0; VID_WALK_TMP=$T/wk sh "$T/ck/walk.sh" brief --stage 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the walk brief exited $RC"
grep -q '^# The walk' "$(tail -n 1 "$T/out")/brief.md" || fail 'no walk brief'
[ -s "$STG_LOG" ] && grep -q '^call scope ' "$STG_LOG" || fail 'the walk made no stage-scope call'
awk '$1 == "call" { c = $0; next } { print c "\t" $0 }' "$STG_LOG" | while IFS="$(printf '\t')" read -r c l; do
  grep -qxF "$l" "$T/applied" || { printf '%s: %s\n' "$c" "$l" > "$T/out"; cat "$STG_LOG" >> "$T/out"; exit 1; }; done || fail "a stage-scope call of the walk was handed a file other than the applied one (above; applied: $(paste -sd ' ' "$T/applied"))"
exit 0
