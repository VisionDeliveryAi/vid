#!/bin/sh
# Purpose: selftest case — in GitHub manual the team gets the applied version, in the export and in every ticket (GM-2 T1).
# On the ticket writer's toy (fixtures/tw-toy.sh) switched to manual, its applied version the commit holding the issue form
# `issue-form:` names, a design note and a CLAUDE.md with an Import law: then, committed after the applied commit, a pending
# reset (ROW-001 restated), an added difference row (DIF-004), a decision added (D-005, naming ROW-001), and PRD.md,
# BASELINE.md's stack, ARCHITECTURE.md's hosting, GRADING-CHECKLIST.md, STAGES.md, the Import law and the golden set each
# changed, every changed line marked "since the applied version". The export holds each of its files as the applied commit
# holds it, TEST-DIFFERENCES.md cut from the applied INVENTORY.md, and the issue form as HEAD holds it; the written step
# ticket for S02 quotes ROW-001's applied text, the skeleton's quotes the applied law, stack and hosting, S05's the applied
# golden set, and none holds D-005 or a marked line. Files the fake spec repository's main holds that no export put there
# (REGISTER.md and design/NOTES.md, pushed by hand after the export) do not make a ticket stale at tw-post; a ticket written
# before the form changed at HEAD, with no export since, is refused there, naming the export's own paths, and nothing is
# posted; after the next export both files are still there, byte for byte, beside the new form and the applied design note;
# once issue-form: names another file, the export puts it there and takes out the form an earlier export put there, the two
# files kept. A commit under ViD's own author that is no export (design/SHARED.md, as a share pushes) is kept the same way.
# Outside manual the export is today's: HEAD's text, its own paths alone. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-export-applied: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
M='since the applied version'
tw_toy "$T/toy"
# the stand-in's records a step ticket needs, and S01 closed, so S02 is admitted in either mode
for l in 'engines chromium firefox' 'row ROW-003 accepted' 'row ROW-004 accepted' 'closed S01' 'candidate 0' 'staged 0'; do tw_hand "$l"; done
printf 'state-repo: owner/vid-state\nissue-form: forms/issue.md\n' >> .vid/tw/settings
gh repo create owner/code-spec --private > /dev/null; gh repo create owner/vid-state --private > /dev/null
form() { printf '# {name}\n\n{full-ticket}\n\n## %s\n\n{tests}\n\n{blocked-by}\n{not-yet-ticketed}\n{fakes}\n' "$1" > forms/issue.md; }
mkdir -p forms design; form Tests; printf '# Screens\n\nS01, the saved state.\n' > design/screens.md
printf '# JobDigest\n\n## Import law\n\n- Each module imports another only through its public surface.\n' > CLAUDE.md
g add forms design CLAUDE.md; g commit -qm 'the issue form, a design note and the laws'
# GitHub manual, its applied version this commit
AP=$(git rev-parse HEAD); printf '%s\n' "$AP" > .vid/tw/applied
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
# the owner's pending changes, committed after the applied commit
ed_() { sed "$1" "$2" > "$T/i" && cat "$T/i" > "$2"; }
ed_ "s/Each saved search gets one digest a day, holding only jobs it has not sent before\./Each saved search gets one digest a day, $M./" INVENTORY.md
awk -v m="$M" '{ print } /^difference \| DIF-003 /{ print "difference | DIF-004 | the clock | a fixed clock | the real clock | the digest hour " m " | paying-step: close run" }' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
printf -- '- **D-005** ROW-001 sends the digest at seven, %s | why: the owner asked | enforced: convention\n' "$M" >> DECISIONS.md
ed_ "s/^\(REQ-001 | functional | T1 | A subscriber receives one digest per saved search per day\)/\1, $M/" PRD.md
ed_ "s/^\(| data | one relational database\)/\1 $M/" BASELINE.md
ed_ "s/^\(platform: one small hosting platform\)/\1 $M/" ARCHITECTURE.md
printf -- '- **Digest hours.** Check the digest hour, %s.\n' "$M" >> GRADING-CHECKLIST.md
ed_ "s/^STAGE-1 | The daily digest |/STAGE-1 | The daily digest $M |/" STAGES.md
printf -- '- Each import is listed in the module table, %s.\n' "$M" >> CLAUDE.md
GS=tests/invariants/golden/synonyms.golden; printf 'plumber | Pipe fitter %s | - | Plumbing supplies\n' "$M" >> "$GS"
g commit -qam 'the pending changes'
for f in INVENTORY.md DECISIONS.md PRD.md BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md STAGES.md CLAUDE.md "$GS"; do grep -q "$M" "$f" || fail "the toy's $f holds no pending change"; done
# the export
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the export failed in manual'
SG=.vid/spec.git; E1=$(git --git-dir="$SG" rev-parse refs/heads/main)
for f in PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md; do
  [ "$(git --git-dir="$SG" rev-parse "$E1:$f" 2>/dev/null)" = "$(git rev-parse "$AP:$f")" ] || fail "the export's $f is not the applied commit's"; done
git --git-dir="$SG" show "$E1:TEST-DIFFERENCES.md" > "$T/td" 2>/dev/null || fail 'the export holds no TEST-DIFFERENCES.md'
grep -q 'DIF-003' "$T/td" || fail 'TEST-DIFFERENCES.md misses the applied difference rows'
! grep -q 'DIF-004' "$T/td" || fail 'TEST-DIFFERENCES.md holds the difference row added after the applied commit'
[ "$(git --git-dir="$SG" rev-parse "$E1:forms/issue.md" 2>/dev/null)" = "$(git rev-parse HEAD:forms/issue.md)" ] || fail 'the export does not carry the issue form as HEAD holds it'
git --git-dir="$SG" ls-tree -r --name-only "$E1" > "$T/xl"
while IFS= read -r p; do ! git --git-dir="$SG" show "$E1:$p" | grep -q "$M" || fail "the export's $p holds a line changed since the applied commit"; done < "$T/xl"
# a step ticket, written in manual
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'
sh "$CHECKS/plan.sh" start S02 > "$T/out" 2>&1 || fail 'S02 was not admitted'
F=$(sh "$CHECKS/writer.sh" write step S02 2> "$T/out") || fail "S02's ticket was not written"
cp "$F" "$T/out"
grep -q 'Each saved search gets one digest a day, holding only jobs it has not sent before' "$F" || fail "the ticket does not quote ROW-001's applied text"
! grep -q "$M" "$F" || fail "the ticket holds a line changed since the applied commit: $(grep "$M" "$F" | head -n 1)"
! grep -q 'D-005' "$F" || fail 'the ticket holds the decision added after the applied commit'
# the skeleton's ticket (the laws, the stack and the hosting) and S05's (its golden set)
sh "$CHECKS/plan.sh" start S01 > "$T/out" 2>&1 || fail 'S01 was not admitted'
FS=$(sh "$CHECKS/writer.sh" write skeleton 2> "$T/out") || fail "the skeleton's ticket was not written"; cp "$FS" "$T/out"
grep -q 'Each module imports another only through its public surface' "$FS" || fail "the skeleton's ticket does not quote the applied law"
grep -q '| data | one relational database |' "$FS" && grep -q 'platform: one small hosting platform' "$FS" || fail "the skeleton's ticket does not quote the applied stack and hosting"
! grep -q "$M" "$FS" || fail "the skeleton's ticket holds a line changed since the applied commit: $(grep "$M" "$FS" | head -n 1)"
sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail 'S05 was not admitted'
F5=$(sh "$CHECKS/writer.sh" write step S05 2> "$T/out") || fail "S05's ticket was not written"; cp "$F5" "$T/out"
grep -q 'electrician | Electrical technician' "$F5" || fail "S05's ticket does not quote the applied golden set"
! grep -q "$M" "$F5" || fail "S05's ticket holds a line changed since the applied commit: $(grep "$M" "$F5" | head -n 1)"
# a file the spec repository's main holds that no export put there: the ticket stays fresh, the next export keeps it
SU=$(gh repo view owner/code-spec --json url --jq .url); git clone -q "$SU" "$T/own" 2>/dev/null
printf '# The owner'"'"'s register\n\nkept by hand\n' > "$T/own/REGISTER.md"; printf '# Notes on the screens\n\nkept by hand\n' > "$T/own/design/NOTES.md"
( cd "$T/own" && g add REGISTER.md design/NOTES.md && g commit -qm 'the register' && git push -q origin HEAD:main 2>/dev/null ) || fail 'the register could not be pushed'
RB=$(git -C "$T/own" rev-parse HEAD:REGISTER.md); NB=$(git -C "$T/own" rev-parse HEAD:design/NOTES.md)
# a commit under ViD's own author that is no export (as a share's push is): its file is no export's either
printf '# A shared copy\n\nnot an export\n' > "$T/own/design/SHARED.md"
( cd "$T/own" && git add design/SHARED.md && GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git commit -qm 'ViD share of the toy' && git push -q origin HEAD:main 2>/dev/null ) || fail 'the shared copy could not be pushed'
SB=$(git -C "$T/own" rev-parse HEAD:design/SHARED.md)
sh "$CHECKS/github.sh" tw-post --words 'Yes, publish S02' "$F" > "$T/out" 2>&1 || fail 'tw-post refused the ticket once a file no export put there is on main'
sh "$CHECKS/plan.sh" start S03 > "$T/out" 2>&1 || fail 'S03 was not admitted'
F3=$(sh "$CHECKS/writer.sh" write step S03 2> "$T/out") || fail "S03's ticket was not written"
form 'The tests'; g commit -qam 'the issue form, its tests heading'
# a ticket whose export no longer holds, at its own paths, what the export would hold now: refused, nothing posted
cp .vid/tw/log "$T/log0"
if sh "$CHECKS/github.sh" tw-post --words 'Yes, publish S03' "$F3" > "$T/out" 2>&1; then fail 'tw-post posted a ticket whose export does not hold the form at HEAD'; fi
grep -q "at the export's own paths" "$T/out" || fail "the refusal does not name the export's own paths"
cmp -s .vid/tw/log "$T/log0" || fail 'the refused tw-post wrote to the log'
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the second export failed'
grep -q 'exported' "$T/out" || fail 'the second export pushed nothing with the form changed'
E2=$(git --git-dir="$SG" rev-parse refs/heads/main)
[ "$(git --git-dir="$SG" rev-parse "$E2:REGISTER.md" 2>/dev/null)" = "$RB" ] || fail 'the export removed or changed a file no export put there'
[ "$(git --git-dir="$SG" rev-parse "$E2:design/NOTES.md" 2>/dev/null)" = "$NB" ] || fail 'the export removed or changed a file under design/ no export put there'
[ "$(git --git-dir="$SG" rev-parse "$E2:design/SHARED.md" 2>/dev/null)" = "$SB" ] || fail "the export removed or changed a file a commit under ViD's author, no export, put there"
[ "$(git --git-dir="$SG" rev-parse "$E2:design/screens.md" 2>/dev/null)" = "$(git rev-parse "$AP:design/screens.md")" ] || fail "the export's design note is not the applied commit's"
[ "$(git --git-dir="$SG" rev-parse "$E2:forms/issue.md" 2>/dev/null)" = "$(git rev-parse HEAD:forms/issue.md)" ] || fail 'the second export does not carry the new form'
[ "$(git --git-dir="$SG" rev-parse "$E2:PRD.md")" = "$(git rev-parse "$AP:PRD.md")" ] || fail "the second export's PRD.md is not the applied commit's"
# issue-form: names another file: the form an earlier export put there goes, the files no export put there stay
cp forms/issue.md forms/issue-2.md; g add forms/issue-2.md; g commit -qm 'the issue form, moved'
sed 's#^issue-form: .*#issue-form: forms/issue-2.md#' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the export with the moved form failed'
E4=$(git --git-dir="$SG" rev-parse refs/heads/main); git --git-dir="$SG" ls-tree -r --name-only "$E4" > "$T/xl"
grep -qx 'forms/issue-2.md' "$T/xl" || fail 'the export does not carry the form issue-form: now names'
! grep -qx 'forms/issue.md' "$T/xl" || fail 'the export kept the form an earlier export put there'
[ "$(git --git-dir="$SG" rev-parse "$E4:REGISTER.md" 2>/dev/null)" = "$RB" ] && [ "$(git --git-dir="$SG" rev-parse "$E4:design/NOTES.md" 2>/dev/null)" = "$NB" ] || fail 'the export with the moved form removed a file no export put there'
# outside manual, today's export: HEAD's text, its own paths alone
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the export failed in auto'
E3=$(git --git-dir="$SG" rev-parse refs/heads/main)
[ "$(git --git-dir="$SG" rev-parse "$E3:PRD.md")" = "$(git rev-parse HEAD:PRD.md)" ] || fail "in auto the export's PRD.md is not HEAD's"
git --git-dir="$SG" show "$E3:TEST-DIFFERENCES.md" | grep -q 'DIF-004' || fail "in auto TEST-DIFFERENCES.md is not HEAD's"
git --git-dir="$SG" ls-tree -r --name-only "$E3" > "$T/xl"
! grep -qx 'REGISTER.md' "$T/xl" && ! grep -q '^forms/' "$T/xl" || fail "in auto the export's tree is not its own paths alone: $(paste -sd ' ' "$T/xl")"
exit 0
