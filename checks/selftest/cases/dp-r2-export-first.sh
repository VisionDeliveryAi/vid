#!/bin/sh
# Purpose: selftest case — the round's next exports before it posts any owed ask (0.26.10.29.5, DP-1 R2), so a grade asked after a
# merge reads that merge's decisions. checks/round.sh next, the real round with stand-ins for what it calls (github.sh, close.sh,
# writer.sh, plan.sh and the rest each record their call in order): with a stage's grade ask owed, `github.sh spec-export` comes
# before `close.sh ask --stage 1`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r2-export-first: $*" >&2; cat "$T/out" "$T/p/.vid/order" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks" "$T/p/.vid/tw"; cd "$T/p"
cp "$CHECKS/round.sh" "$CHECKS/lib.sh" "$CHECKS/event.sh" checks/
stub() { printf '#!/bin/sh\n# Purpose: a stand-in for checks/%s.sh, recording its call\necho "%s $*" >> .vid/order\n%s\nexit 0\n' "$1" "$1" "${2:-}" > "checks/$1.sh"; }
stub github 'case $1 in tw-sync) echo "ViD github: sync main=none open tickets none" ;; esac'
stub close 'case $1 in owed) echo "stage 1" ;; esac'
stub writer; stub grade; stub walk; stub queue; stub decide; stub decisions
printf '#!/bin/sh\n# Purpose: a stand-in for checks/plan.sh, refusing every start\necho "plan $*" >> .vid/order\nexit 1\n' > checks/plan.sh
printf 'run: active\nsession: S1\nmode: tickets\nstage: 1\n\n## The plan\n\n```vid-plan\nstep S01 | name: one | modules: app | builds-on: - | rows: ROW-001\n```\n' > .vid/RUN-STATE.md
printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
RC=0; sh checks/round.sh next > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "next exited $RC"
grep -q '^close ask --stage 1$' .vid/order || fail 'the owed grade ask was not asked'
e=$(grep -n '^github spec-export' .vid/order | head -n 1 | cut -d: -f1); a=$(grep -n '^close ask --stage 1$' .vid/order | head -n 1 | cut -d: -f1)
[ -n "$e" ] && [ "$e" -lt "$a" ] || fail "the export does not come before the owed ask: $(tr '\n' ';' < .vid/order)"
exit 0
