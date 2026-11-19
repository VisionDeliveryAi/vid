#!/bin/sh
# Purpose: selftest case — a PRD answer ViD proposed itself is "decided for you" (0.26.10.29.5, DP-1 R4), checks/close.sh summary and
# close-stage on a bare record set. Each answer row marked model_proposed that PRD.md's history adds since the newest close is a stage
# fact, read as the facts read DECISIONS.md's; one added before the close, and a human answer, are not. The summary check refuses a
# summary that leaves it out. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r4-facts-model-proposed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q; g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p .vid/tw .vid/decide/queue .vid/round; printf '# Run state\n\nrun: active\nstage: 1\n' > .vid/RUN-STATE.md; : > .vid/tw/handed; printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md; printf '.vid/\n' > .gitignore   # 0.26.11.1.2 (R6): an INVENTORY.md with no rows, so the plan's rows read empty, never unreadable
printf '# Decisions\n' > DECISIONS.md
printf '# PRD\n\n```vid-prd-answers\nA-001 | model_proposed | 2026-11-01 | Q: - | A: a week | settles: REQ-001\n```\n' > PRD.md
g add -A; ( GIT_COMMITTER_DATE=2026-11-01T00:00:00Z GIT_AUTHOR_DATE=2026-11-01T00:00:00Z; export GIT_COMMITTER_DATE GIT_AUTHOR_DATE; g commit -qm root )   # before the close; in a subshell, as sh keeps an assignment before a function
sed 's/^```$/A-002 | model_proposed | 2026-11-11 | Q: - | A: seven days | settles: REQ-002\nA-003 | human | 2026-11-11 | Q: x | A: ten | settles: REQ-003\n```/' PRD.md > "$T/p" && cp "$T/p" PRD.md
grep -q '^A-002 | model_proposed' PRD.md && grep -q '^A-003 | human' PRD.md || fail 'the answers were not added'
g commit -qam 'the door adds two answers'
X=$(git rev-parse HEAD); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/w1"; printf 'commit\t%s\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"
: > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; : > "$F/cs/passed"; echo 'no walk: this stage has no screens and no journey' > "$F/w1/none"
printf 'stage-closed n=0 sha=000000000000 at=2026-11-10T00:00:00Z\n' > .vid/metrics-events
sh "$CHECKS/close.sh" summary --stage 1 > "$T/out" 2>&1 || fail 'the summary failed'
awk -F'\t' '$1 == "decided" { print $2 }' "$F/facts.txt" | sort > "$T/ids"
grep -qxF A-002 "$T/ids" || fail "the facts miss A-002, a model_proposed answer added since the close: $(paste -sd ' ' "$T/ids")"
! grep -qxF A-001 "$T/ids" || fail 'the facts hold A-001, added before the close'; ! grep -qxF A-003 "$T/ids" || fail "the facts hold A-003, the owner's own answer"
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** nothing · no walk: this stage has no screens and no journey\n' > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^summary-refused 1 the summary misses the decision A-002$' "$T/out" || fail 'a summary without A-002 was not refused'
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** a week became seven days (A-002) · no walk: this stage has no screens and no journey\n' > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^stage-closed 1 at [0-9a-f]*$' "$T/out" || fail 'a summary naming A-002 did not close the stage'
exit 0
