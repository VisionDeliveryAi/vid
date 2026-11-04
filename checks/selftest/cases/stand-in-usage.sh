#!/bin/sh
# Purpose: selftest case — the stand-in's work can be counted (v0.26.10.9 spec R22, R23; §5 stand-in-usage). On an
# empty code repository, the stand-in's root commit (`github.sh push main`), its claim commits (`claim`) and the
# approver's merges (`review`, then `merge`, through the fake gh) carry their Stand-in: trailers; main is the root plus
# two merges whose merged branches hold the agents' own untrailered commits, and `git log --first-parent main` finds
# 0 commits without a trailer (the agents' commits, off the first-parent line, have none). `github.sh session --verb`
# writes one line to .git/vid/sessions — the session id and the transcript path, from the session's projects folder —
# and nothing under any .vid/; in a folder holding .vid/, the stand-in refuses. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "stand-in-usage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
gh_fake; gh_worker "$T/w1" || fail 'the clone failed'
( cd "$T/w1" && sh "$CHECKS/github.sh" push main --worker 1 ) > "$T/out" 2>&1 || fail 'the root commit was refused'
gh_vid "$T/vid"; V=$(pwd -P)
for r in REQ-001 REQ-002; do sh checks/ticket.sh skeleton-body --req "$r" --out ".vid/tickets/sk-$r.md" > /dev/null 2>&1; sh checks/github.sh publish --ticket ".vid/tickets/sk-$r.md" > /dev/null 2>&1 || fail "the ticket for $r was not published"; done
EV0=$(wc -l < .vid/metrics-events)
gh_worker "$T/wa" || fail "the approver's clone failed"
cd "$T/w1"; git checkout -q main 2>/dev/null || true
for i in 1 2; do
  N=$(sh "$CHECKS/github.sh" next-ticket --worker 1 | sed -n 's/^next //p'); [ -n "$N" ] || fail "no ticket for round $i"
  sh "$CHECKS/github.sh" claim "$N" --worker 1 > "$T/out" 2>&1 || fail "the claim of #$N failed"
  git fetch -q origin; git checkout -q -b "vid/$N" "origin/vid/$N"
  printf 'part %s\n' "$i" > "s$i.txt"; git add "s$i.txt"; git commit -qm "an agent's commit $i"; printf 'more\n' >> "s$i.txt"; git commit -qam "an agent's commit $i, again"
  gh_skel_block "$N" > "$T/pr.md"; sh "$CHECKS/github.sh" push "vid/$N" --pr "$T/pr.md" > "$T/out" 2>&1 || fail "the pull request for #$N failed"
  P=$(ls "$T/gh/prs" | sort -n | tail -n 1); gh_ci "$(git rev-parse HEAD)" "$((100 + i))" 1 success
  ( cd "$T/wa" && sh "$CHECKS/github.sh" review "$P" && sh "$CHECKS/github.sh" merge "$P" ) > "$T/out" 2>&1 || fail "the review and merge of #$P failed"
  git checkout -q main; git fetch -q origin; git merge -q --ff-only origin/main
done
git -C "$T/code.git" log --first-parent --format=%H main > "$T/fp"; [ "$(grep -c . "$T/fp")" = 3 ] || fail "main's first-parent line is not the root and two merges"
NO=0; for c in $(cat "$T/fp"); do git -C "$T/code.git" log -1 --format=%B "$c" | grep -q '^Stand-in: ' || NO=$((NO + 1)); done
[ "$NO" = 0 ] || fail "$NO first-parent commits on main without a Stand-in: trailer"
git -C "$T/code.git" log -1 --format=%B "$(tail -n 1 "$T/fp")" | grep -qx 'Stand-in: worker-1' || fail 'the root lacks its trailer'
for c in $(sed '$d' "$T/fp"); do git -C "$T/code.git" log -1 --format=%B "$c" | grep -qx 'Stand-in: approver' || fail "the merge $c lacks the approver's trailer"; done
AG=$(git -C "$T/code.git" log --format='%s%n%b' main | grep -c "an agent's commit" || true); [ "$AG" -ge 4 ] || fail 'the agents commits are not in the history'
git -C "$T/code.git" log --format=%B --grep="an agent's commit" main | grep -q 'Stand-in:' && fail "an agent's commit carries a trailer — the count would prove nothing"
git -C "$T/code.git" log --format=%B --grep='^claim #' main | grep -c 'Stand-in: worker-1' | grep -qx 2 || fail 'the two claim commits lack their trailers'
# the sessions file
E=$(pwd -P | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$T/home/.claude/projects/$E"; printf '{}\n' > "$T/home/.claude/projects/$E/sess-123.jsonl"
HOME=$T/home sh "$CHECKS/github.sh" session --verb ticket-implement > "$T/out" 2>&1 || fail 'session failed'
[ "$(grep -c . .git/vid/sessions)" = 1 ] && grep -q "^verb=ticket-implement session=sess-123 transcript=$T/home/.claude/projects/$E/sess-123.jsonl at=" .git/vid/sessions || fail "the sessions line is wrong: $(cat .git/vid/sessions)"
[ ! -e "$T/w1/.vid" ] && [ ! -e "$T/wa/.vid" ] || fail 'the stand-in wrote a .vid/'
[ "$(wc -l < "$V/.vid/metrics-events")" = "$EV0" ] || fail "the stand-in wrote into the planner's records"
cd "$V"; if HOME=$T/home sh "$CHECKS/github.sh" session --verb ticket-implement > "$T/out" 2>&1; then fail 'the stand-in ran in a folder holding .vid/'; fi
grep -q 'refused' "$T/out" || fail 'the refusal does not say so'
exit 0
