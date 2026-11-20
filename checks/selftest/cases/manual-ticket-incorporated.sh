#!/bin/sh
# Purpose: selftest case — in GitHub manual a step ticket holds an incorporation's replacements only once it is applied
# (GM-2 T1 with IR I3). On the ticket writer's toy switched to manual, D-005 (bearing on ROW-005, of S02), D-006 and D-007
# committed and that commit applied: S02's written ticket quotes D-005 and D-007 (bearing on ROW-001, also
# of S02), no mark and no D-006. The incorporation then
# marks D-005 `replaced-by: D-006, D-007`, committed after the applied commit: S02's ticket is still the applied text,
# D-005 with no mark, D-007, and no D-006. Once the incorporation's commit is the applied one, S02's ticket quotes D-005 with its
# mark, then D-006, then D-007, once each. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-ticket-incorporated: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
ids() { sed -n 's/^\(> \)*- \*\*\(D-[0-9]*\)\*\*.*/\2/p' "$1" | grep -E '^D-00[567]$' | tr '\n' ' '; }
tw_toy "$T/toy"
for l in 'engines chromium firefox' 'row ROW-003 accepted' 'row ROW-004 accepted' 'closed S01' 'candidate 0' 'staged 0'; do tw_hand "$l"; done
printf 'state-repo: owner/vid-state\nissue-form: forms/issue.md\n' >> .vid/tw/settings
gh repo create owner/code-spec --private > /dev/null; gh repo create owner/vid-state --private > /dev/null
mkdir -p forms; printf '# {name}\n\n{full-ticket}\n\n## Tests\n\n{tests}\n\n{blocked-by}\n{not-yet-ticketed}\n{fakes}\n' > forms/issue.md
cat >> DECISIONS.md <<'DEC'
- **D-005** a job read from two feeds is merged by its title alone | why: one listing | enforced: convention | applies-to: ROW-005
- **D-006** a job read from two feeds is merged by its title and its employer | why: titles repeat across employers | enforced: convention | applies-to: ROW-017
- **D-007** a merged job keeps the first feed's link | why: one source page | enforced: convention | applies-to: ROW-001
DEC
g add forms DECISIONS.md; g commit -qm 'the issue form and the decisions'
git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the export failed in manual'
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
sh "$CHECKS/plan.sh" start S02 > "$T/out" 2>&1 || fail 'S02 was not admitted'
wr() { F=$(sh "$CHECKS/writer.sh" write step S02 2> "$T/out") || fail "S02's ticket was not written ($1)"; sec "$F" Decisions > "$T/d"; cp "$F" "$T/out"; }
wr 'before the mark'
[ "$(ids "$T/d")" = 'D-005 D-007 ' ] || fail "before the mark S02's ticket does not quote D-005 and D-007 alone of the three: $(ids "$T/d")"
! grep -q 'replaced-by:' "$T/d" || fail 'before the mark the ticket holds a replaced-by mark'
# the incorporation, committed after the applied commit
sed 's#^\(- \*\*D-005\*\* a job read from two feeds is merged by its title alone\) | why:#\1 | replaced-by: D-006, D-007 | why:#' DECISIONS.md > "$T/x" && cat "$T/x" > DECISIONS.md
grep -qF 'replaced-by: D-006, D-007' DECISIONS.md || fail 'the mark did not land'
g commit -qam 'the incorporation: D-005 replaced by D-006 and D-007'
wr 'the incorporation pending'
[ "$(ids "$T/d")" = 'D-005 D-007 ' ] || fail "with the incorporation pending S02's ticket does not hold the applied decisions alone: $(ids "$T/d")"
! grep -q 'replaced-by:' "$T/d" || fail 'with the incorporation pending the ticket holds its mark'
# the incorporation applied
git rev-parse HEAD > .vid/tw/applied
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the export failed after the apply'
wr 'the incorporation applied'
[ "$(ids "$T/d")" = 'D-005 D-006 D-007 ' ] || fail "once applied S02's ticket does not quote D-005, then D-006, then D-007, once each: $(ids "$T/d")"
grep -qF 'replaced-by: D-006, D-007' "$T/d" || fail "once applied the ticket lacks D-005's mark"
exit 0
