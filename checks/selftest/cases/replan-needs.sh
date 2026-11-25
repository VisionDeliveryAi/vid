#!/bin/sh
# Purpose: selftest case — everything an analysis or an apply needs is said at once and first (FB-4 A3, A4). On the form fixture's toy in
# GitHub manual, S02 posted as #N and S03 as #M: the read is the call before's, ARCHITECTURE.md is uncommitted, STAGES.md at HEAD is refused
# by the stage court, the handed record is out of form, #N's recorded writing is gone, #M is closed and not accepted, the call's stage is
# off, no engines line is on record, the settings hold no labels-prefix: and name an issue form HEAD does not hold. One `replan.sh scope`
# prints, first, one `needs <what> missing <analysis|apply> <who> <words>` line for each, with its command, then refuses as it did, in the
# same words. Then each is cured: the same lines say met (spec: the two commits, and that no export is read), scope's own lines follow as
# before, exit 0, and no line asks an export. A read with parts GitHub could not give is missing, by each part. A missing need of the
# apply alone refuses nothing. With layout: one no spec-repo is asked, and spec-publish: hand says the team publishes after the apply.
# With no applied version the list comes before the refusal. Without .vid/round/folder no folder line is printed; with it, where lib.sh
# holds B1's foldersay, met while the folder holds the applied version's spec, missing in the context line's words while it holds another's,
# and none while that line is quiet. Nothing in GitHub auto. The skills say it: vid-replan's step 1, its direct call's read, and the apply's sentence. Env: CHECKS.
# selftest-limit: 1800 s
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-needs: $*" >&2; cat "$T/out" "$T/err" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
scope() { RC=0; sh "$CHECKS/replan.sh" scope "$@" > "$T/out" 2> "$T/err" || RC=$?; }
# nd <what> <met|missing> <analysis|apply> <who> [<words it holds>]: one line of it, so
nd() { [ "$(grep -c "^needs$TB$1$TB" "$T/out")" = 1 ] || fail "scope does not print one needs $1 line"
  grep "^needs$TB$1$TB$2$TB$3$TB$4$TB" "$T/out" > "$T/l" || fail "the $1 line is not $2, for the $3, supplied by $4"; [ $# -lt 5 ] || grep -qF -- "$5" "$T/l" || fail "the $1 line does not say: $5"; }
first() { awk -F'\t' '$1 != "needs" { x = 1; next } x { exit 1 }' "$T/out" || fail 'a needs line comes after another line'; grep -q '^needs' "$T/out" || fail 'no needs line'; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; M=$FM_N
H0=$(git rev-parse HEAD); mkdir -p "$T/kept"; cp .vid/tw/settings .vid/tw/handed .vid/metrics-events STAGES.md ARCHITECTURE.md ".vid/tw/out/issue-$N.md" "$T/kept/"
# everything missing at once
echo CLOSED > "$FAKEGH/issues/$M/state"; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
grep -q "^ticket$TB$M${TB}CLOSED$TB" .vid/round/read || fail "the toy's read does not show #$M closed"
cp .vid/round/read .vid/round/read.prev; touch -t 202601010000 .vid/round/read
sed 's/^STAGE-2 |.*/&\nSTAGE-2 | Again | features: FEAT-02/' STAGES.md > "$T/st" && cat "$T/st" > STAGES.md; g commit -qam 'a cut the stage court refuses'; H1=$(git rev-parse HEAD)
sh "$CHECKS/stages.sh" check --work > "$T/out" 2>&1 && fail 'the toy has no cut the stage court refuses'
printf '\nOne line more.\n' >> ARCHITECTURE.md; printf 'row ROW-001 nonsense\n' > .vid/tw/handed; rm ".vid/tw/out/issue-$N.md"
printf 'stage name=plan state=end session=S1 at=2026-11-24T09:00:00Z\n' >> .vid/metrics-events; ! sh "$CHECKS/plan.sh" gate > /dev/null 2>&1 || fail "the toy's stage could not be turned off"
sed -e '/^labels-prefix:/d' -e 's#^issue-form:.*#issue-form: forms/none.md#' "$T/kept/settings" > .vid/tw/settings
scope; [ "$RC" = 1 ] && grep -q 'the spec files in the working tree differ' "$T/err" || fail "with the architecture uncommitted scope exited $RC, or not in the words it had"
first; ! grep -qv '^needs' "$T/out" || fail 'a refused scope printed more than its list'
nd read missing analysis ViD "the call before's"; grep -qF '/vid:vid-read' "$T/l" || fail 'the read line does not name its command'
nd spec missing analysis owner ARCHITECTURE.md; grep -q 'STAGES\.md' "$T/l" || fail "the spec line does not name the stage court's refusal"
nd records missing analysis ViD '.vid/tw/handed'; grep -qF "writing $N" "$T/l" || fail "the records line does not name #$N's writing"
nd accepted missing analysis owner "#$M"; grep -qF '/vid:vid-accept-step <n> <commit> accepted "<words>"' "$T/l" || fail 'the accepted line does not name its command'
nd call missing apply ViD 'vid-connect'
nd engines missing apply owner '/vid:vid-accept-step engines "<primary> <other>…" "<words>"'
nd settings missing apply owner 'labels-prefix'; grep -qF 'sh checks/planner.sh setup' "$T/l" && grep -qF 'forms/none.md' "$T/l" || fail 'the settings line does not name the issue form, or its command'
! grep -qi 'not ratified' "$T/l" || fail 'the settings line asks the ratification, which the apply makes'
! grep -q "^needs$TB\(folder\|publish\)$TB" "$T/out" || fail 'a folder or publish line is printed with neither'
# each cured: the same lines met, scope's own after them
cp "$T/kept/settings" .vid/tw/settings; cp "$T/kept/handed" .vid/tw/handed; cp "$T/kept/metrics-events" .vid/metrics-events; cp "$T/kept/issue-$N.md" ".vid/tw/out/issue-$N.md"; cp "$T/kept/ARCHITECTURE.md" ARCHITECTURE.md
cp "$T/kept/STAGES.md" STAGES.md; g commit -qam 'the cut as it was'; H2=$(git rev-parse HEAD); echo OPEN > "$FAKEGH/issues/$M/state"; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
scope; [ "$RC" = 0 ] || fail "with all met scope exited $RC"; first
for k in read spec records accepted; do case $k in spec|accepted) w=owner ;; *) w=ViD ;; esac; nd "$k" met analysis "$w"; done; nd call met apply ViD; nd engines met apply owner; nd settings met apply owner
grep "^needs${TB}spec$TB" "$T/out" | grep -qF "read at HEAD $(printf %.12s "$H2"), the team has $(printf %.12s "$H0"); no export is read" || fail 'the spec line does not name the two commits, and that no export is read'
! grep -q "^needs$TB[a-z]*${TB}missing" "$T/out" || fail 'a need is missing with all met'
sed '/^needs/d' "$T/out" > "$T/rest"; printf 'target\t%s\napplied\t%s\n' "$H2" "$H0" > "$T/hd"; sed -n 1,2p "$T/rest" | cmp -s - "$T/hd" || fail "scope's own lines do not follow the list as before"
[ "$(tail -n 1 "$T/rest")" = "review${TB}needed" ] || fail "scope's last line is not its review line"
# a part of the read GitHub could not give, by its part
cp .vid/round/read "$T/rd"; printf 'unread\tbody\t%s\tthe body could not be read\n' "$N" >> .vid/round/read; scope; [ "$RC" = 1 ] || fail 'an unread part no longer refuses'; nd read missing analysis ViD "body $N"; nd records met analysis ViD; # two parts, both named in one run; a due part is not the read's
printf 'unread\tticket\t%s\tthe ticket could not be read\nunread\tdue\t-\twhat is owed could not be read\n' "$M" >> .vid/round/read; scope; [ "$RC" = 1 ] || fail 'two unread parts no longer refuse'; nd read missing analysis ViD "body $N"; nd read missing analysis ViD "ticket $M"; ! grep -q 'unread due' "$T/l" || fail 'the read line names a due part'; cp "$T/rd" .vid/round/read
# no read kept at all
rm -f .vid/round/read; scope; [ "$RC" = 1 ] || fail 'no read kept no longer refuses'; nd read missing analysis ViD 'no read kept'; cp "$T/rd" .vid/round/read
# the apply's missing alone: said, nothing refused
sed '/^engines /d' "$T/kept/handed" > .vid/tw/handed; scope; [ "$RC" = 0 ] || fail 'a missing need of the apply refuses the analysis'; nd engines missing apply owner; nd records met analysis ViD; cp "$T/kept/handed" .vid/tw/handed
# layout: one
{ sed -e '/^spec-repo:/d' "$T/kept/settings"; printf 'layout: one\n'; } > .vid/tw/settings; scope; [ "$RC" = 0 ] || fail "with layout: one scope exited $RC"; nd settings met apply owner; ! grep -q "^needs${TB}publish" "$T/out" || fail "ViD's own publish is said to be the team's"
printf 'spec-publish: hand\n' >> .vid/tw/settings; scope; [ "$RC" = 0 ] || fail "with spec-publish: hand scope exited $RC"; nd publish missing apply team 'after the apply'
# the folder read kept (FB-4 B1), where lib.sh reads it: it holds the applied version's files; another commit's, in the context line's words,
# scope going on; nothing while that line is quiet, ViD's own publish owed
if grep -q '^foldersay()' "$CHECKS/lib.sh"; then { sed -e '/^spec-repo:/d' "$T/kept/settings"; printf 'layout: one\nspec-path: upstream/spec\n'; } > .vid/tw/settings
  kept() { { printf 'main\t%s\towner/code\tupstream/spec\n' "$(git rev-parse "$1")"; for f in PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md INVENTORY.md STAGES.md; do ! git cat-file -e "$1:$f" 2> /dev/null || printf '%s\t%s\n' "$(git rev-parse "$1:$f")" "$f"; done; } > .vid/round/folder; }
  kept "$H0"; scope; [ "$RC" = 0 ] || fail "with the folder holding the applied version scope exited $RC"; nd folder met analysis owner "$(printf %.12s "$H0")"; first
  kept "$H1"; scope; [ "$RC" = 0 ] || fail "with the folder holding another commit's spec scope exited $RC"; nd folder missing analysis owner "$(printf %.12s "$H1")"; first
  sh "$CHECKS/next.sh" triggers 2> /dev/null | sed -n "s/^context${TB}folder$TB//p" > "$T/ctx"; [ -s "$T/ctx" ] && [ "$(cut -f6 "$T/l")" = "$(cat "$T/ctx")" ] || fail "the folder line's words are not the context line's"
  echo 0123456789ab > .vid/tw/spec-owed; scope; [ "$RC" = 0 ] || fail "with the folder's publish owed scope exited $RC"; ! grep -q "^needs${TB}folder$TB" "$T/out" || fail 'a folder line is printed while the context line is quiet'; rm -f .vid/tw/spec-owed .vid/round/folder
else echo 'replan-needs: no foldersay in lib.sh here, the folder scenes not run'; fi
cp "$T/kept/settings" .vid/tw/settings; sed '/^spec-repo:/d' "$T/kept/settings" > .vid/tw/settings; scope; nd settings missing apply owner 'setup spec-repo'; cp "$T/kept/settings" .vid/tw/settings
# no applied version: the list, then today's refusal
cp .vid/tw/applied "$T/kept/applied"; echo none > .vid/tw/applied; scope; [ "$RC" = 1 ] && grep -q 'no applied version' "$T/err" || fail 'with no applied version scope does not refuse in the words it had'; first; nd spec missing analysis owner '/vid:vid-mode manual'; nd engines met apply owner; cp "$T/kept/applied" .vid/tw/applied
[ ! -f .vid/round/folder ] || fail 'the toy keeps a folder read'
# GitHub auto: nothing of it
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-24T09:00:00Z\n' >> .vid/plan/setup; sed 's/^github-mode:.*/github-mode: auto/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
scope; [ "$RC" = 1 ] && [ ! -s "$T/out" ] || fail 'in GitHub auto scope prints more than its refusal'
# the skills
S=$CHECKS/../skills/vid-replan/SKILL.md; [ -f "$S" ] || { echo 'replan-needs: ok'; exit 0; }; : > "$T/out"; : > "$T/err"
awk '/^1\. \*\*What it covers/ { f = 1 } /^2\. \*\*The candidate/ { f = 0 } f' "$S" > "$T/s1"; grep -qF '`needs' "$T/s1" && grep -q 'missing' "$T/s1" && grep -q 'before any candidate' "$T/s1" || fail 'vid-replan step 1 does not say the needs lines'
awk '/^\*\*Called by the owner/ { f = 1 } f && /^$/ { exit } f' "$S" | grep -qF 'vid-read' || fail 'a direct call in manual does not read first'
awk '/^\*\*The apply,/ { f = 1 } f && /^$/ { exit } f' "$S" | grep -qF '`needs' || fail "the apply's sentence does not say the missing lines"
grep -qF 'needs' "$CHECKS/../skills/vid-next/SKILL.md" || fail 'vid-next does not name the lines'
echo 'replan-needs: ok'
