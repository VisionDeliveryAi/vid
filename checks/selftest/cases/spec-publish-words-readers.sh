#!/bin/sh
# Purpose: selftest case — the owner's words on a `spec-published` line never change what its readers read (FB-1 B6), and the folder
# publish's unfinished call is owed in GitHub manual (FB-1 B5). The lines and .vid/tw/spec-owed are written by hand, as github.sh
# spec-publish writes them (` words="<w>"` last on the line; the file holding the export). GitHub auto: with words `publish pr=999
# please` on the newest line, the queue's spec pull request line names #41, the line's own, never #999. GitHub manual (the switched
# toy, fixtures/manual.sh): an apply that left the folder's publish owed; a `spec-published` line from before it whose words are
# `publish at=2099-01-01T00:00:00Z now` leaves `apply-owed spec-publish` listed by `next.sh triggers`; a newer line with .vid/tw/spec-owed
# standing lists it too; with the file gone, the newer line counts the publish done. And right after the switch, before any apply
# (.vid/tw/applied.log holds the switch's line alone), .vid/tw/spec-owed standing lists it on its own, its line naming the folder
# publish that did not finish and its export, never an apply. In GitHub auto the same files (the matching apply and proposal, the
# newer line, .vid/tw/spec-owed standing) list no `apply-owed spec-publish`, the round's retry being auto's; back in GitHub manual
# they list it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "spec-publish-words-readers: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); E=0123456789ab
# GitHub auto: the queue's reader of the newest spec-published line
mkdir -p "$T/a"; cd "$T/a"; git init -q; mkdir -p .vid/plan .vid/tw .vid/round
printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## Open product questions\n\n## Notes\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="auto" words="the toy, auto" at=2026-11-19T09:00:00Z\n' > .vid/plan/setup
printf 'open\t41\t-\t%s\tfalse\t-\t-\t-\t2026-11-21T09:00:00Z\n' "$E$E$E$E" > .vid/round/read
printf 'spec-published pr=41 export=%s path=upstream/vid stamp=STAMP at=2026-11-21T09:00:00Z words="publish pr=999 please"\n' "$E" > .vid/tw/log
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed in GitHub auto'
grep -q "${TB}specpr:41${TB}" "$T/ql" || { cp "$T/ql" "$T/out"; fail "the queue's spec pull request line is missing: the words on the line were read as its fields"; }
! grep -q 'specpr:999\|#999' "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the queue names pull request 999, from the words on the line'; }
# GitHub manual: the owed reader of next.sh triggers
cd "$T"; mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || { cp "$T/mo" "$T/out"; fail "the switch exited $MN_RC"; }
owed() { sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail "next.sh triggers failed ($1)"; grep -q "^trigger${TB}critical${TB}apply-owed${TB}spec-publish${TB}" "$T/tr"; }
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
echo "$E" > .vid/tw/spec-owed
owed 'before any apply' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'before any apply, with .vid/tw/spec-owed standing, next.sh triggers lists no apply-owed spec-publish'; }
grep "^trigger${TB}critical${TB}apply-owed${TB}spec-publish${TB}" "$T/tr" > "$T/ao"
grep -qF "the folder publish of export $E did not finish" "$T/ao" && ! grep -q 'the apply ' "$T/ao" || { cp "$T/ao" "$T/out"; fail 'before any apply, the owed line does not name the unfinished folder publish and its export, or claims an apply'; }
rm -f .vid/tw/spec-owed
A=$(sed -n 1p .vid/tw/applied); printf '%s\t2026-11-21T10:00:00Z\tapply\n' "$A" >> .vid/tw/applied.log
mkdir -p .vid/next/applied-proposal; echo "$A" > .vid/next/applied-proposal/target; echo "$E" > .vid/next/applied-proposal/spec-publish
cp .vid/tw/log "$T/log0"
{ cat "$T/log0"; printf 'spec-published pr=7 export=%s path=upstream/vid stamp=STAMP at=2026-11-21T09:00:00Z words="publish at=2099-01-01T00:00:00Z now"\n' "$E"; } > .vid/tw/log
owed 'an older line' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'an older spec-published line whose words hold at=2099-… counts the apply'"'"'s owed publish done'; }
{ cat "$T/log0"; printf 'spec-published pr=8 export=%s path=upstream/vid stamp=STAMP at=2026-11-21T11:00:00Z\n' "$E"; } > .vid/tw/log; echo "$E" > .vid/tw/spec-owed
owed 'spec-owed' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'with .vid/tw/spec-owed standing, next.sh triggers lists no apply-owed spec-publish'; }
rm -f .vid/tw/spec-owed
! owed 'done' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'with a newer spec-published line and no spec-owed, the publish is still owed'; }
# GitHub auto: the same files, the marker standing, list nothing; GitHub manual again: they do
echo "$E" > .vid/tw/spec-owed
printf 'setup-answered key=github-mode value="auto" words="the toy, auto again" at=2026-11-21T12:00:00Z\n' >> .vid/plan/setup
! owed 'GitHub auto' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'in GitHub auto, with a newer spec-published line and .vid/tw/spec-owed standing, next.sh triggers lists apply-owed spec-publish'; }
printf 'setup-answered key=github-mode value="manual" words="the toy, manual again" at=2026-11-21T12:10:00Z\n' >> .vid/plan/setup
owed 'GitHub manual again' || { grep '^trigger' "$T/tr" > "$T/out"; fail 'back in GitHub manual, with .vid/tw/spec-owed standing, next.sh triggers lists no apply-owed spec-publish'; }
exit 0
