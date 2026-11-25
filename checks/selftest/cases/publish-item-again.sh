#!/bin/sh
# Purpose: selftest case — a publish pull request the owner ended is an item again once what stands on it changed (FB-5 C2). On GitHub
# manual's toy a read holds an open pull request of the owner's with nothing on it: one item, `publish:<n>`. The owner marks it done: no read
# that says the same brings it back. A read in which a person asks for changes does, as a new item, the old one staying done; a read in which
# it is open no more closes that one. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "publish-item-again: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/backlog >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings; mkdir -p .vid/round
B=.vid/decide/queue/backlog; QS=$CHECKS/queue.sh
rd() { printf 'ticket\t3\tOPEN\t-\t2026-11-19T09:00:00Z\n' > .vid/round/read; for x; do printf "$x\n" >> .vid/round/read; done; sh "$QS" list > "$T/out" 2>&1 || fail 'queue.sh list failed'; }
op() { awk -F'\t' '$3 != "done" { print $1 ":" $2 }' "$B" | paste -sd ' ' -; }
P='open\t9\t-\tabc1\tfalse\t\t0\t0\t2026-11-20T09:00:00Z\t-\tdev'; U='publish\t9\tpush\tdev\t2026-11-20T09:00:00Z'
C='publish\t9\tstate\tana\tCHANGES_REQUESTED\t2026-11-20T10:00:00Z\tafter'
rd "$P" "$U"; [ "$(op | tr ' ' '\n' | grep -c ':publish:9$')" = 1 ] || fail "the open items are $(op)"
I=$(op | tr ' ' '\n' | sed -n 's/:publish:9$//p'); sh "$QS" backlog set "$I" --state 'done' > "$T/out" 2>&1 || fail 'the owner could not mark it done'
rd "$P" "$U"; ! op | grep -q 'publish:9' || fail 'an ended publish came back with nothing changed'
rd "$P" "$U" "$C"; [ "$(op | tr ' ' '\n' | grep -c ':publish:9$')" = 1 ] || fail 'a request for changes after its end is no item'
awk -F'\t' -v i="$I" '$1 == i && $3 == "done" { f = 1 } END { exit !f }' "$B" || fail 'the ended item is open again'
rd; ! op | grep -q 'publish:9' || fail 'a read in which it is open no more left it open'
echo 'publish-item-again: ok'
