#!/bin/sh
# Purpose: selftest case — a call says which spec the folder holds (FB-4 B1). On GitHub manual's toy with `layout: one`, the team's main
# holds the first commit's PRD.md and ARCHITECTURE.md in upstream/vid and the applied version is the second commit. After
# `next.sh read` one `context folder` line names the first commit and --applied, in `--short` too; main unmoved, the next read makes no
# GET of a tree, and main moved or spec-path: changed, one. Nothing is said while ViD's own publish is open in the read or owed
# (.vid/tw/spec-owed), and it is said again once neither is, the team's own publish (by=hand) among them; nothing when the folder
# holds the applied version. A failed read is said, leaves the kept read out, and stops no call. No file's content is read; layout
# separate and GitHub auto make no read and say nothing. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "next-folder: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); c12() { printf %.12s "$1"; }
mn_project "$T/p"; C0=$AP
sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; printf 'spec-path: upstream/vid\n' >> "$T/st"; cp "$T/st" .vid/tw/settings
{ printf 'mode: tickets\nplan: required\nrun: waiting\n\n## The plan\n\n```vid-plan\n'; cat "$T/plan.blk"; printf '```\n'; } > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/decide .vid/next; : > .vid/tw/handed; : > .vid/tw/log
tk_dev 'the spec, by hand' upstream/vid/PRD.md "$(git show "$C0:PRD.md")" upstream/vid/ARCHITECTURE.md "$(git show "$C0:ARCHITECTURE.md")"
printf '\nOne line more.\n' >> PRD.md; git commit -qam 'PRD.md: one line more'; C1=$(git rev-parse HEAD); echo "$C1" > .vid/tw/applied
rd_() { RC=0; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "next.sh read exited $RC ($1)"; }
tr_() { sh "$CHECKS/next.sh" triggers $2 > "$T/L" 2> "$T/out" || fail "next.sh triggers failed ($1)"; cp "$T/L" "$T/out"; }
F="^context${TB}folder${TB}upstream/vid "; D="$F.*holds the spec of $(c12 "$C0").*$(c12 "$C1").*--applied $(c12 "$C0")"
said() { tr_ "$1" "${2:-}"; [ "$(grep -c "$F" "$T/L")" = 1 ] && grep -q "$D" "$T/L" || fail "the folder is not said once ($1)"; }
quiet() { tr_ "$1" ''; ! grep -q "^context${TB}folder" "$T/L" || fail "the folder is said ($1)"; }
trees() { grep -c 'git/trees/' "$FAKEGH/log" || true; }
rd_ 'first'; [ ! -s "$T/out" ] || fail 'a read that passes prints a line'
said 'the folder behind'; said 'in --short' --short
n=$(trees); [ "$n" -gt 0 ] || fail 'the folder was not read by its names and ids'; rd_ 'main unmoved'; [ "$(trees)" = "$n" ] || fail 'main unmoved, the folder was read again'; said 'main unmoved'
tk_dev 'a commit of the team' app.txt x; rd_ 'main moved'; [ "$(trees)" -gt "$n" ] || fail 'main moved and the folder was not read'
! grep -q 'contents/\|git/blobs' "$FAKEGH/log" || fail "a file's content was read"
# ViD's own publish open in the read, then merged; the team's own (by=hand) is no publish of ViD's
P="spec-published pr=9 export=0123456789ab path=upstream/vid stamp=- at=2026-11-20T09:00:00Z"; printf '%s words="put it there"\n' "$P" > .vid/tw/log
cp .vid/round/read "$T/rd"; printf 'open\t9\t-\t%s\tvid-spec/0123456789ab\tno\t0\t0\t-\n' "$C1" >> .vid/round/read; quiet "ViD's own publish open"
printf '%s by=hand words="put it there"\n' "$P" > .vid/tw/log; said "the team's own publish open"
printf '%s words="by=hand here"\n' "$P" > .vid/tw/log; quiet "ViD's own publish open, the owner's words holding by=hand"
cp "$T/rd" .vid/round/read; said "ViD's own publish merged or closed"; : > .vid/tw/log
echo 0123456789ab > .vid/tw/spec-owed; quiet "ViD's publish owed"; rm .vid/tw/spec-owed
# the same owed by the newest apply's own records (its proposal's spec-publish), with no .vid/tw/spec-owed
printf '%s\t2026-11-21T09:00:00Z\tapply\n' "$C1" > .vid/tw/applied.log; mkdir -p .vid/next/applied-proposal; echo "$C1" > .vid/next/applied-proposal/target; echo y > .vid/next/applied-proposal/spec-publish; : > .vid/next/applied-proposal/publish
tr_ 'the apply left the publish owed' ''; grep -q "^trigger${TB}critical${TB}apply-owed${TB}spec-publish$TB" "$T/L" || fail 'the fixture: the publish the apply left owed is not raised'; ! grep -q "^context${TB}folder" "$T/L" || fail 'the folder is said while the apply left its publish owed'
rm -rf .vid/tw/applied.log .vid/next/applied-proposal; said 'nothing owed'
# the applied version's, then not on main, then of no commit
echo "$C0" > .vid/tw/applied; quiet 'the folder holds the applied version'; echo "$C1" > .vid/tw/applied
sed 's#^spec-path: .*#spec-path: specs/elsewhere#' .vid/tw/settings > "$T/st2"; cp "$T/st2" .vid/tw/settings; quiet 'the kept read is of another folder'; n=$(trees); rd_ 'another folder'; [ "$(trees)" -gt "$n" ] || fail 'spec-path: changed and the folder was not read'
tr_ 'not on main' ''; grep -q "^context${TB}folder${TB}specs/elsewhere is not on main.*setup spec-path" "$T/L" || fail 'a folder not on main is not said'
cp "$T/st" .vid/tw/settings; tk_dev 'a line of the team' upstream/vid/PRD.md 'the team wrote this'; rd_ 'changed there'; tr_ 'changed there' ''; grep -q "${F}on main holds no one commit's spec" "$T/L" || fail 'a folder of no one commit is not said'
# a failed read
mkdir -p "$T/wh"; printf '#!/bin/sh\nfor a; do case $a in */git/trees/*) echo "HTTP 502: the read the case makes fail" >&2; exit 1 ;; esac; done\nexec "%s" "$@"\n' "$T/bin/gh" > "$T/wh/gh"; chmod +x "$T/wh/gh"
tk_dev 'the spec, by hand, again' upstream/vid/PRD.md "$(git show "$C0:PRD.md")"; OP=$PATH; PATH="$T/wh:$PATH"; rd_ 'a failed read of the folder'; PATH=$OP
grep -q 'the folder upstream/vid could not be read.*HTTP 502' "$T/out" || fail 'a failed read of the folder is not said'; [ ! -e .vid/round/folder ] || fail 'a failed read left the kept read'
quiet 'a failed read'; rd_ 'the read after'; said 'the read after'
# layout separate, and GitHub auto
n=$(trees); sed 's/^layout: one$/layout: separate/' .vid/tw/settings > "$T/st2"; cp "$T/st2" .vid/tw/settings; rm -f .vid/round/folder; rd_ 'layout separate'; quiet 'layout separate'
cp "$T/st" .vid/tw/settings; printf 'setup-answered key=github-mode value="auto" words="the toy, auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; rd_ 'GitHub auto'; quiet 'GitHub auto'
[ "$(trees)" = "$n" ] && [ ! -e .vid/round/folder ] || fail 'layout separate or GitHub auto reads the folder'
echo 'next-folder: ok'
