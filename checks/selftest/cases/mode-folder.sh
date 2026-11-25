#!/bin/sh
# Purpose: selftest case — a take-stock says which spec the folder holds (FB-4 B1). On GitHub manual's toy (fixtures/manual.sh) with
# `layout: one` and `spec-path: upstream/vid`, the team's main holds there the first commit's PRD.md and ARCHITECTURE.md, a STAMP in a
# form of the team's and a README; ViD's HEAD is two changes of PRD.md later. The switch with --applied of the second commit says,
# before a ticket is read, that the folder holds the first one's and `--applied <it>`, is not refused, and records the second; a re-take
# with nothing given says it again; one with --applied of the first says the folder holds the applied version's. With none recorded
# and none given `need --applied` names the first commit, and nothing is recorded: ViD never takes the folder's commit itself. A
# folder not on main names the one command that names another; one of no commit says so. A failed read is said and stops nothing.
# No file's content is read, and layout separate and /vid mode auto's take-stock make no read. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-folder: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
c12() { printf %.12s "$1"; }
mn_project "$T/p"; C0=$AP
sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; printf 'spec-path: upstream/vid\n' >> "$T/st"; cp "$T/st" .vid/tw/settings
tk_dev 'the spec, by hand' upstream/vid/PRD.md "$(git show "$C0:PRD.md")" upstream/vid/ARCHITECTURE.md "$(git show "$C0:ARCHITECTURE.md")" upstream/vid/STAMP "vid $(printf %.7s "$C0")" upstream/vid/README.md 'ours'
[ "$(git -C "$T/dev" rev-parse HEAD:upstream/vid/PRD.md)" = "$(git rev-parse "$C0:PRD.md")" ] || fail 'the fixture: the folder does not hold the first commit'
printf '\nOne line more.\n' >> PRD.md; git commit -qam 'PRD.md: one line more'; C1=$(git rev-parse HEAD)
printf '\nAnother line.\n' >> PRD.md; git commit -qam 'PRD.md: another line'; C2=$(git rev-parse HEAD)
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" comments 2; printf '%s S01\n' "$N1" > "$T/register"
DIF="^folder upstream/vid on main holds the spec of $(c12 "$C0").*$(c12 "$C1").*--applied $(c12 "$C0")"
# none recorded and none given: the need line names the folder's commit, and nothing is taken
mn_switch; [ "$MN_RC" = 5 ] || fail "the switch with no applied version exited $MN_RC, not 5"
grep '^need --applied ' "$T/mo" | grep -q "upstream/vid on main holds the spec of $(c12 "$C0").*--applied $(c12 "$C0")" || fail 'the need --applied line does not name the commit the folder holds'
[ ! -s .vid/tw/applied ] || fail "the folder's commit was taken as the applied version"
# the wrong commit given
mn_switch --applied "$C1" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || fail "the switch with --applied of another commit exited $MN_RC, not 0"
[ "$(grep -c '^folder ' "$T/mo")" = 1 ] && grep -q "$DIF" "$T/mo" || fail 'the switch does not say, once, the commit the folder holds and --applied'
[ "$(sed -n 1p .vid/tw/applied)" = "$C1" ] || fail 'the commit given is not the one recorded'
f=$(grep -n '^folder ' "$T/mo" | cut -d: -f1); t=$(grep -n '^taken-over ' "$T/mo" | head -n 1 | cut -d: -f1); [ -n "$t" ] && [ "$f" -lt "$t" ] || fail 'the folder is not said before the tickets'
f=$(grep -n 'git/trees/' "$FAKEGH/log" | head -n 1 | cut -d: -f1); t=$(grep -n "issue view $N1 " "$FAKEGH/log" | tail -n 1 | cut -d: -f1); [ -n "$f" ] && [ -n "$t" ] && [ "$f" -lt "$t" ] || fail 'the folder is not read before the tickets'
! grep -q 'contents/\|git/blobs' "$FAKEGH/log" || fail "a file's content was read"
# a re-take with nothing given, then with the folder's commit
mn_switch --words 'yes, re-take'; [ "$MN_RC" = 0 ] && grep -q "$DIF" "$T/mo" || fail "a re-take does not say it again ($MN_RC)"
mn_switch --applied "$C0" --words 'yes, re-take'; [ "$MN_RC" = 0 ] && grep -q "^folder upstream/vid on main holds the spec of the applied version, $(c12 "$C0")" "$T/mo" && ! grep -q '^folder .*--applied' "$T/mo" || fail "the folder's own commit given is not said to be the folder's ($MN_RC)"
# a failed read: said, and nothing stopped
mkdir -p "$T/wh"; printf '#!/bin/sh\nfor a; do case $a in */git/trees/*) echo "HTTP 502: the read the case makes fail" >&2; exit 1 ;; esac; done\nexec "%s" "$@"\n' "$T/bin/gh" > "$T/wh/gh"; chmod +x "$T/wh/gh"
tk_dev 'a commit of the team' app.txt x; OP=$PATH; PATH="$T/wh:$PATH"; mn_switch --words 'yes, re-take'; PATH=$OP
[ "$MN_RC" = 0 ] && grep -q '^folder upstream/vid could not be read .*HTTP 502' "$T/mo" || fail "a failed read of the folder is not said, or stopped the take-stock ($MN_RC)"
# no one commit's, and not on main
tk_dev 'a line of the team' upstream/vid/PRD.md 'the team wrote this'; mn_switch --words 'yes, re-take'
[ "$MN_RC" = 0 ] && grep -q "^folder upstream/vid on main holds no one commit's spec" "$T/mo" || fail "a folder of no one commit is not said ($MN_RC)"
sed 's#^spec-path: .*#spec-path: specs/elsewhere#' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; mn_switch --words 'yes, re-take'
[ "$MN_RC" = 0 ] && grep -q '^folder specs/elsewhere is not on main.*sh checks/planner.sh setup spec-path' "$T/mo" || fail "a folder not on main is not said, with the one command ($MN_RC)"
# layout separate, and GitHub auto's take-stock: no read
sed 's/^layout: one$/layout: separate/' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; n=$(grep -c 'git/trees' "$FAKEGH/log"); mn_switch --words 'yes, re-take'
[ "$(grep -c 'git/trees' "$FAKEGH/log")" = "$n" ] && ! grep -q '^folder ' "$T/mo" || fail 'layout separate reads the folder'
sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings
printf 'setup-answered key=github-mode value="auto" words="the toy, auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
RC=0; sh "$CHECKS/mode.sh" auto --review "$T/review" > "$T/mo" 2>&1 || RC=$?; [ "$(grep -c 'git/trees' "$FAKEGH/log")" = "$n" ] && ! grep -q '^folder ' "$T/mo" || fail 'GitHub auto reads the folder'
echo 'mode-folder: ok'
