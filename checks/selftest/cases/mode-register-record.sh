#!/bin/sh
# Purpose: selftest case — the register is ViD's record and the label (FB-3 C3). Two tickets of a project's own label alone, switched
# to GitHub manual with the owner's register, #2 then written again by hand. A re-take with no flag finds both by ViD's record,
# `found register 2 tickets`, and lists #2's newer writing; with #1's issue gone from GitHub it prints `not-found #1` and goes on, #1
# kept on record; with GitHub failing on #2's read it is refused in GitHub's words, to run again; a withdrawn one is no ticket of the
# register. The switch to GitHub auto prints `unlabelled #<n>` for each open ticket on record without the label, and none for a
# labelled one, and writes nothing to the code repository. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-register-record: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
retake() { MN_RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" --words 'yes, the re-take' "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
lab() { printf 'team:alpha\n' > "$FAKEGH/issues/$1/labels"; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; lab "$N1"
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 > "$T/t2"; gh_writing "$N2" "$T/t2" comments 2; lab "$N2"
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 > "$T/t3"; gh_writing "$N3" "$T/t3" body 2; lab "$N3"
printf '%s S01\n%s S02\n%s S03\n' "$N1" "$N2" "$N3" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
printf 'withdrawn %s at=2026-11-20T09:00:00Z\n' "$N3" >> .vid/tw/log
gh_replaced "$N2"; mn_ticket "$N2" S02 step ROW-001 ROW-005 > "$T/t2b"; gh_writing "$N2" "$T/t2b" comments 2
retake
[ "$MN_RC" = 0 ] || fail "the re-take exited $MN_RC"
grep -q '^found register 2 tickets, 2 open and 0 closed ' "$T/mo" || fail 'the re-take did not find the two tickets on record'
grep -q '^found register .*\.vid/tw/log' "$T/mo" || fail 'the register does not say both its sources'
grep -q "^newer $N2 " "$T/mo" && grep -q "^amended $N2 .* taken-over=" .vid/tw/log || fail "#$N2, written again by hand, is not brought to its newest writing"
grep -q '^kept ' "$T/mo" && fail 'a ticket on record and on GitHub is kept as not in the register'

# one GitHub no longer has: said, kept on record, the call goes on
mv "$FAKEGH/issues/$N1" "$T/gone"
retake
[ "$MN_RC" = 0 ] || fail "with #$N1's issue gone the re-take exited $MN_RC"
grep -q "^not-found $N1 " "$T/mo" && grep -q '^found register 1 tickets' "$T/mo" && grep -qx "kept $N1 not in the register" "$T/mo" || fail "#$N1, gone from GitHub, is not said and kept"
cmp -s ".vid/tw/out/issue-$N1.md" "$T/t1" && grep -q "^published $N1 " .vid/tw/log || fail "#$N1's record was not kept"
mv "$T/gone" "$FAKEGH/issues/$N1"

# GitHub failing on one: refused, in its words, to run again; never `not-found`
mkdir -p "$T/w"; printf '#!/bin/sh\ncase " $* " in *" issue view %s "*) echo "HTTP 502: the read the case makes fail" >&2; exit 1 ;; esac\nexec "%s" "$@"\n' "$N2" "$T/bin/gh" > "$T/w/gh"; chmod +x "$T/w/gh"
MN_RC=0; PATH="$T/w:$PATH" sh "$CHECKS/mode.sh" manual --review "$T/review" --words 'yes, the re-take' > "$T/mo" 2>&1 || MN_RC=$?
[ "$MN_RC" = 1 ] && grep -q 'run this again' "$T/mo" && grep -q 'the read the case makes fail' "$T/mo" || fail "with GitHub failing on #$N2 the re-take exited $MN_RC, not refused in its words"
grep -q '^not-found' "$T/mo" && fail 'a failed read was called an issue GitHub no longer has'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the failed read'

# the switch to GitHub auto: one line for each open ticket on record without the label, nothing written to the code repository
printf 'vid:ticket\n' >> "$FAKEGH/issues/$N1/labels"; gh_wclear
MN_RC=0; sh "$CHECKS/mode.sh" auto --review "$T/review" --words 'yes, back to auto' > "$T/mo" 2>&1 || MN_RC=$?
[ "$MN_RC" = 0 ] || fail "the switch to GitHub auto exited $MN_RC"
[ "$(grep '^unlabelled ' "$T/mo" | cut -d' ' -f1,2)" = "unlabelled #$N2" ] || fail "the switch to auto does not say #$N2 alone is without the label"
grep -q '^owner/code ' "$FAKEGH/writes" && fail 'the switch to auto wrote to the code repository'
echo 'mode-register-record: ok'
