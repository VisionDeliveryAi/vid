#!/bin/sh
# Purpose: selftest case — the check refuses what no ticket may hold, W4 and F1 (v0.26.10.12.3
# R8). On TW's toy every ticket of every kind written passes `writer.sh check`, the ratified lines holding a path in
# their quoted sections included (S01/saved in Rows, a census path in Rules, written as a pointer: v0.26.10.24.2). Refused, by line and word: in TW's own
# words (a planted History line) code or a test (a backtick, { and =), a file path and a runner command; a `> ` line
# outside the quoted sections; a step's name: naming a file (after a recorded rename); a fix's reason holding code and a
# runner command; PL's own row (HOS-005, origin: plan) whose free text names a file and a command, while its schema
# words (n/a, protects:, disable:, owed:, origin:) pass; a line over 60,000 bytes; in Further reading, a quoted path
# outside the export (web/app.py, INVENTORY.md), while an exported one passes. tw-post posts nothing the check
# refuses: the fake gh sees no issue write. An item taken out (the asks' T4, a section) is named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-refuse: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh; GS=$CHECKS/github.sh
tw_skel || fail 'the skeleton round failed'; SK=$TW_F
ck() { RC=0; sh "$W" check "$1" > "$T/out" 2>&1 || RC=$?; }
has() { grep -qF -- "$1" "$T/out" || fail "not refused: $1"; }
ck "$SK"; [ "$RC" = 0 ] || fail 'the skeleton ticket is refused'; grep -q '^> ROW-003 .*S01/saved' "$SK" || fail 'the skeleton does not quote ROW-003 with its marker'
tw_start S02 || fail 'S02 was refused'; tw_start S03 || fail 'S03 was refused'
tw_post step S02 || fail "S02's ticket was refused"; P=$TW_F
F3=$(sh "$W" write step S03 2> "$T/werr") || fail "S03's ticket was refused"; grep -q "^> rule | RULE-002 | .* | (ViD's records) | " "$F3" || fail 'the Rules section does not quote the census path as a pointer (v0.26.10.24.2)'
ck "$F3"; [ "$RC" = 0 ] || fail 'a rule whose census path was rewritten was refused'
# a PL ROW row's schema words (n/a, the owed: field naming its deploy gate) pass; its obligation is checked
pl() { awk -v l="> ROW-021 | behavior | REQ-005 | n/a | n/a | $1 | REQ-005 | owed: paid by /vid deploy gate 1 — the rehearsal | origin: plan REQ-005" '{ print } $0 == "## Rows" { getline; print; print l }' "$F3" > "$T/p.md"; ck "$T/p.md"; }
pl 'Saved searches survive the move. Fails if one is missing'; [ "$RC" = 0 ] || fail "a PL row's schema words were refused"
pl 'Saved searches survive the move in db/move.sql. Fails if one is missing'; [ "$RC" = 1 ] && grep -q 'a file path — db/move.sql' "$T/out" || fail "a PL row's obligation naming a file passed"
# TW's own words
plant() { awk -v l="$2" '{ print } $0 == "## History" { getline; print; print l }' "$P" > "$T/p.md"; cp "${P%.md}.meta" "$T/p.meta"; ck "$T/p.md"; [ "$RC" = 1 ] || fail "$1 was not refused"; }
plant 'a planted line' '- run the suite with --maxfail, edit web/app.py and set {retries} to x=2 in `cfg`'
has 'a runner command — --maxfail,'; has 'a file path — web/app.py'; has 'code or a test — {retries}'; has 'code or a test — x=2'; has 'code or a test — `cfg`'
grep -q '^writer: check refused — line [0-9]*: ' "$T/out" || fail 'a refusal does not name its line'
plant 'a quoted line outside the quoted sections' '> see notes.txt for it'; has 'a file path — notes.txt'
# Further reading: an exported path passes, a path outside the export is refused there (it is quoted, but not spec text)
fr() { awk -v l="$1" '{ print } $0 == "## Further reading" { getline; print; print l }' "$P" > "$T/p.md"; ck "$T/p.md"; }
fr '> PRD.md'; [ "$RC" = 0 ] || fail 'an exported path in Further reading was refused'
fr '> web/app.py'; [ "$RC" = 1 ] && grep -q 'a path outside the export [0-9a-f]* — web/app.py' "$T/out" || fail 'a path outside the export passed in Further reading'
fr '> INVENTORY.md'; [ "$RC" = 1 ] && grep -q 'a path outside the export [0-9a-f]* — INVENTORY.md' "$T/out" || fail 'INVENTORY.md, never exported, passed in Further reading'
plant 'a line over 60,000 bytes' "$(awk 'BEGIN { for (i = 0; i < 61000; i++) printf "a" }')"; has 'is longer than a part of 60,000 bytes can hold'
# tw-post posts nothing refused
plant 'the post' '- edit web/app.py'; N0=$(grep -c '^gh issue \(create\|edit\|comment\)' "$T/gh/log" || true)
if sh "$GS" tw-post "$T/p.md" > "$T/out" 2>&1; then fail 'tw-post posted a refused ticket'; fi; grep -q 'nothing posted' "$T/out" || fail 'tw-post does not say it posted nothing'
[ "$(grep -c '^gh issue \(create\|edit\|comment\)' "$T/gh/log" || true)" = "$N0" ] || fail 'tw-post wrote to GitHub for a refused ticket'
# an item taken out
grep -v '^- T4 ' "$P" > "$T/p.md"; ck "$T/p.md"; has 'item: the asks lack T4'
awk '$0 == "## Golden sets" { s = 1; next } s && /^## / { s = 0 } !s' "$P" > "$T/p.md"; ck "$T/p.md"; has 'item: the section ## Golden sets is missing'
# a step's name, RM's words, is checked
pt_rs 's/^\(step S04 | name: \)limits, backups, failures and the data move/\1limits kept in app\/limits.py/'
sh "$CHECKS/plan.sh" change other 'S04 renamed' --trigger initial --expect 'S04 named' > "$T/out" 2>&1 || fail 'the rename was refused'
tw_hand 'closed S02'; tw_hand 'closed S03'; tw_close 2; sh "$GS" tw-sync > /dev/null 2>&1; tw_start S04 || fail 'S04 was refused'
if sh "$W" write step S04 > "$T/out" 2>&1; then fail 'a step name naming a file was written'; fi; has 'a file path — app/limits.py'
# a fix's reason
tw_hand 'fix ROW-003 | the {json} body broke under --hard reloads | decision on pull request 4'
if sh "$W" write fix ROW-003 > "$T/out" 2>&1; then fail 'a fix reason holding code was written'; fi; has 'code or a test — {json}'; has 'a runner command — --hard'
# PL's own row: its free text is checked, its schema words pass
sed 's/^\(hostility | HOS-005 | \)Have the product send/\1Edit web\/mail.py, run it with --send, then have the product send/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
g commit -qam 'HOS-005 planted'; tw_ratify 'Yes, the planted row' || fail 'the planted inventory was not ratified'
sh "$GS" spec-export > /dev/null 2>&1; if sh "$W" write step S03 > "$T/out" 2>&1; then fail "PL's row naming a file and a command was written"; fi
has 'a file path — web/mail.py,'; has 'a runner command — --send,'; ! grep -q 'protects: INV-002\|owed: spec-only\|origin: plan INV-002' "$T/out" || fail "PL's schema words were refused"
exit 0
