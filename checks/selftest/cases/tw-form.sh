#!/bin/sh
# Purpose: selftest case — the ticket's form, W3 and F1 (v0.26.10.12.3 R3, §1.1). On TW's toy:
# `writer.sh write` refuses a step never admitted, a step ticket before any engines are handed in, and any ticket before
# a sync names the code repository's main. The skeleton ticket holds, in order, the header (the plan's hash read from
# the plan-change event's own hash= field, never one inside its why; the base, the code repository's main; the export,
# the spec repository's main), the step (its plan line, the shared: line, its modules' rows and those it may call),
# stage 0's rows as their inventory lines, the requirements with the answers they cite, the decisions, rules, laws
# ("none: the project has no CLAUDE.md"), non-goals, the stack and hosting quoted, the grading checklist and the
# records, golden sets, history, further reading (the spec repository by name, then one quoted line per path of the
# export), roles and asks: T1, T3 with the engines and test environments asked, T4, T5, no T2.
# A step ticket (S02) holds every item of a step ticket: its rows less the fields a ticket leaves out (ROW-013's and
# HOS-001's test paths and proved-red stamps), the primary engine alone, regression and faulted rows, rows a ruling
# reached ("none"), test lessons, and the asks T1–T5 with a protection row's forbidden-effect line, a seam's probe, a
# rule's covered places, a difference's stand-in and the process rows. With a CLAUDE.md the laws quote its Import law,
# never its placement block. A ticket over 60,000 bytes goes out in parts, each at most 60,000, joining back to the
# whole; tw-post posts the body and the parts as comments, one issue. A stale export is refused by tw-post. A stale
# file (fix 2, the demo's #10) is refused, naming what moved, with no GitHub write: a posted ticket's file posted again
# (its work no longer owed) or as an amendment, a file written before a plan change, and one written before an
# export. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-form: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
order() { grep '^## ' "$1" | sed 's/^## //' | paste -sd '|' -; }
# refusals before the records exist
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
if sh "$W" write skeleton > "$T/out" 2>&1; then fail 'the skeleton was written before its admission'; fi; grep -q 'S01 was never admitted' "$T/out" || fail 'the missing admission is not named'
# a why that holds hash= does not mislead the header
sh "$CHECKS/plan.sh" change other 'kept as it is; hash=0123456789ab only in words' --trigger initial --expect 'nothing moves' > "$T/out" 2>&1 || fail 'the plan change was refused'
PH=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p')
tw_start S01 || fail 'S01 was refused'
if sh "$W" write skeleton > "$T/out" 2>&1; then fail 'a ticket was written before any sync'; fi; grep -q 'tw-sync first' "$T/out" || fail 'the missing sync is not named'
sh "$GS" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'; tw_post skeleton || fail 'the skeleton ticket was refused'; S=$TW_F
[ "$(order "$S")" = 'Header|The step|Rows|Requirements|Decisions|Rules that bear on these rows|Laws|Non-goals|The stack and hosting|Grading checklist and records|Golden sets|History|Further reading|Roles|Asks' ] || fail "the skeleton's sections are $(order "$S")"
grep -qx -- "- plan: $PH" "$S" && ! grep -q '0123456789ab' "$S" || fail "the header's plan is not the recorded hash $PH"
grep -qx -- "- base: $(git -C "$T/code.git" rev-parse refs/heads/main)" "$S" || fail "the base is not the code repository's main"
E=$(git -C "$T/gh/repos/owner%code-spec/remote.git" rev-parse refs/heads/main); grep -qx -- "- export: $E" "$S" || fail "the export is not the spec repository's main"
# the further reading: the spec repository by name, then one quoted line per path of the export
sec "$S" 'Further reading' | grep -qx "The spec repository, https://github.com/owner/code-spec, at the export $E; each of its files, by its path there:" || fail 'the further reading does not name the spec repository and its export'
git -C "$T/gh/repos/owner%code-spec/remote.git" ls-tree -r --name-only "$E" > "$T/xp"; [ "$(grep -c . "$T/xp")" -ge 5 ] || fail 'the export holds too few paths to read'
sec "$S" 'Further reading' | sed -n 's/^> //p' | cmp -s - "$T/xp" || fail "the further reading is not one line per exported path: $(sec "$S" 'Further reading' | sed -n 's/^> //p' | paste -sd ' ' -)"
grep -qx -- '- rows: ROW-003 ROW-004' "$S" && grep -qx "> $(grep '^ROW-003 ' INVENTORY.md)" "$S" && grep -qx "> $(grep '^ROW-004 ' INVENTORY.md)" "$S" || fail "stage 0's rows are not their inventory lines"
sec "$S" 'The step' | grep -q '^> step S01 | name: save a search' && sec "$S" 'The step' | grep -qx '> shared: web' && sec "$S" 'The step' | grep -q '^> | digest | the morning digest' || fail 'the step section lacks its line, the shared line or its modules'
sec "$S" Requirements | grep -q '^> REQ-001 | functional' && sec "$S" Requirements | grep -q '^> A-001 | human' || fail 'the requirements or the answers they cite are missing'
sec "$S" Laws | grep -qx 'none: the project has no CLAUDE.md' || fail 'the laws do not say the project has no CLAUDE.md'
sec "$S" 'Non-goals' | grep -q '^> NG-001 | non_goal' || fail 'the non-goal is missing'
sec "$S" 'The stack and hosting' | grep -q '^> | web | one small web framework' && sec "$S" 'The stack and hosting' | grep -q '^> platform: one small hosting platform' || fail 'the stack or hosting is not quoted'
sec "$S" 'Grading checklist and records' | grep -q 'Digest repeats' && sec "$S" 'Grading checklist and records' | grep -q '^> difference | DIF-003 ' || fail 'the checklist or the records are missing'
A=$(sec "$S" Asks); for t in T1 T3 T4 T5; do printf '%s\n' "$A" | grep -q "^- $t " || fail "the skeleton does not ask $t"; done
! printf '%s\n' "$A" | grep -q '^- T2 ' && printf '%s\n' "$A" | grep -q 'declares the engines, the primary first, and how many test environments' || fail 'the skeleton asks T2, or not for the engines and test environments'
printf '%s\n' "$A" | grep -q 'ViD results format 1' || fail 'the results format is not named'
# a step ticket: engines first
tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; tw_hand 'closed S01'; tw_hand 'candidate 0'; tw_close 1; sh "$GS" tw-sync > /dev/null 2>&1
tw_start S02 || fail 'S02 was refused'
if sh "$W" write step S02 > "$T/out" 2>&1; then fail 'a step ticket was written before the engines are known'; fi; grep -q 'no engines line' "$T/out" || fail 'the missing engines are not named'
tw_hand 'engines chromium firefox'; tw_post step S02 || fail 'the step ticket was refused'; P=$TW_F
# a stale file is never posted (fix 2, the demo's #10): each refusal names what moved, and GitHub sees no write
ghw() { grep -c '^gh issue \(create\|edit\|comment\|close\)\|^gh api' "$T/gh/log" || true; }
stale() { _n=$(ghw); if sh "$GS" tw-post $3 "$1" > "$T/out" 2>&1; then fail "a stale file was posted: $1"; fi
  grep -q "stale — $2" "$T/out" && grep -q 'nothing posted' "$T/out" || fail "the refusal does not name what moved ($2)"; [ "$(ghw)" = "$_n" ] || fail "tw-post wrote to GitHub for a stale file: $1"; }
stale "$P" "the ticket work moved: .* written for 'new step S02', which the round no longer owes"
stale "$P" 'the ticket work moved: .* written as a new ticket, not the amendment of #2' '--amend 2'
[ "$(order "$P")" = 'Header|The step|Rows|Requirements|Decisions|Rules that bear on these rows|Laws|Non-goals|Engines|Regression rows|Faulted rows|Rows a ruling reached|Grading checklist and records|Golden sets|History|Test lessons|Further reading|Roles|Asks' ] || fail "the step ticket's sections are $(order "$P")"
grep -q '^> ROW-013 .* | INV-001 | origin: domain property-form$' "$P" && ! grep -q 'test_feed_repeat\|proved-red\|test_hostility_dupes' "$P" || fail 'a test path or proved-red stamp was not left out'
sec "$P" Engines | grep -qx -- '- primary: chromium' && ! sec "$P" Engines | grep -q 'firefox' || fail 'the engines are not the primary alone'
sec "$P" 'Regression rows' | grep -qx -- '- ROW-003' && sec "$P" 'Regression rows' | grep -qx -- '- ROW-004' || fail "the skeleton's accepted rows are not regression rows"
sec "$P" 'Faulted rows' | grep -q '^- ROW-005-T1 ' && sec "$P" 'Faulted rows' | grep -q '^- HOS-001: ' && sec "$P" 'Faulted rows' | grep -qx '> disable: remove the merge by source id from the ingest' || fail 'the faulted rows are not as V2 says'
sec "$P" Decisions | grep -q 'D-001' && ! sec "$P" Decisions | grep -q 'D-002\|D-003\|D-004' || fail "the decisions are not develop's join"
A=$(sec "$P" Asks); for t in T1 T2 T3 T4 T5; do printf '%s\n' "$A" | grep -q "^- $t " || fail "the step ticket does not ask $t"; done
for l in 'HOS-001: its test.s failure message carries the line vid-forbidden-effect: HOS-001' 'SEAM-002: the seam.s probe' 'RULE-005: the report gives the number of places' 'DIF-002: a test difference' 'ROW-005: run with the product.s own declared processes' 'Deploy-owed rows take part in T1 and T5 only: DIF-002 SEAM-002'; do
  printf '%s\n' "$A" | grep -q -- "$l" || fail "the asks lack: $l"; done
# the laws, with a CLAUDE.md: its Import law, never its placement block
printf '# JobDigest\n\n## Placement rules\n\n```vid-placement\nweb/\n```\n\n## Import law\n\n- Every import crosses a seam the table declares.\n\n## Ledger and docs laws\n\n- ViD keeps the ledger.\n' > CLAUDE.md; g add CLAUDE.md; g commit -qm 'CLAUDE.md'
sh "$GS" spec-export > /dev/null 2>&1; tw_start S03 || fail 'S03 was refused'; F3=$(sh "$W" write step S03 2> "$T/werr") || fail 'the S03 ticket was refused'
sh "$CHECKS/plan.sh" change other 'kept as it is, again' --trigger initial --expect 'nothing moves' > "$T/out" 2>&1 || fail 'the second plan change was refused'
stale "$F3" "the plan moved: .* written for the plan $PH; the recorded plan is now"; tw_post step S03 || fail 'the S03 ticket was refused'
sec "$TW_F" Laws | grep -qx '> - Every import crosses a seam the table declares.' && ! sec "$TW_F" Laws | grep -q 'vid-placement\|web/\|ledger' || fail 'the laws are not the Import law alone'
grep -q '^> seam | SEAM-001 | the mail provider .* | evidence: tests/contract' "$TW_F" && fail "SEAM-001's evidence paths were not left out"
grep -q '^> seam | SEAM-001 .*module:\|^> seam | SEAM-001 .*match:' "$TW_F" && fail "SEAM-001's module: or match: was not left out"
# a stale export is refused; a ticket over 60,000 bytes goes out in parts
awk 'BEGIN { for (i = 1; i <= 700; i++) printf "- **D-%d** every page keeps one plain wording for the same thing, so readers learn it once and trust it after that | why: a large decision set | enforced: convention\n", 100 + i }' >> DECISIONS.md; g commit -qam 'many decisions'
tw_close 2; tw_close 3; sh "$GS" tw-sync > /dev/null 2>&1; tw_hand 'closed S02'; tw_hand 'closed S03'
tw_start S04 || fail 'S04 was refused'; F=$(sh "$W" write step S04 2> "$T/werr") || fail 'the large ticket was refused'
if sh "$GS" tw-post "$F" > "$T/out" 2>&1; then fail 'a ticket naming a stale export was posted'; fi; grep -q 'is not the spec repository.s main at ViD.s HEAD' "$T/out" || fail 'the stale export is not named'
sh "$GS" spec-export > /dev/null 2>&1; stale "$F" 'the export moved: .* written at the export [0-9a-f]*; the newest is [0-9a-f]*'
tw_post step S04 || fail 'the large ticket was refused after the export'
[ "$(wc -c < "$TW_F")" -gt 60000 ] || fail 'the toy ticket is not over 60,000 bytes'
sh "$W" parts "$TW_F" 9 "$T/parts" > "$T/pl" || fail 'parts failed'; [ "$(grep -c . "$T/pl")" -ge 2 ] || fail 'a large ticket is one part'
for p in $(cat "$T/pl"); do [ "$(wc -c < "$p")" -le 60000 ] || fail "$p is over 60,000 bytes"; sed '1,2d' "$p"; done > "$T/joined"; cmp -s "$T/joined" "$TW_F" || fail 'the parts do not join back to the ticket'
D=$T/gh/issues/$TW_N; [ "$(ls "$D/comments" | grep -c .)" = "$(( $(grep -c . "$T/pl") - 1 ))" ] && head -n 1 "$D/body" | grep -q "^Ticket #$TW_N, part 1 of " || fail 'tw-post did not post the body and the parts as comments'
exit 0
