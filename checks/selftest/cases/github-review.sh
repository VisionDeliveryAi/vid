#!/bin/sh
# Purpose: selftest case — the stand-in approver's checks (v0.26.10.9 spec R23; §5 github-review). A feature ticket for
# step A and its pull request (fixtures/tickets.sh gh_feature): `review --list` lists it; `github.sh review` passes the good one, printing one
# line per check (CI green on the head, the ticket's test unchanged, paths inside the modules and shared paths, the
# block ok); then each refusal on its own, by name: the head's CI red; the ticket's test changed; a path outside the
# step's modules and the shared paths; a block without ci: on a pass. A correction sent in a ticket comment is the
# test's new standard. Found by R-1 and kept: an approver's clone with no origin/main still refuses the outside path;
# a branch that merged origin/main is judged on its own changes only. The skeleton ticket's paths are free, and its
# merged pull request is imported before the vid-code block names a ci-workflow (its block's line). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "github-review: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; gh_feature || fail 'the feature ticket and its pull request were not made'
rv() { ( cd "$T/wa" && sh "$CHECKS/github.sh" review "$P" ) > "$T/out" 2>&1; }
newhead() { ( cd "$T/w1" && sh "$CHECKS/github.sh" push "vid/$N" > /dev/null 2>&1 ); gh_ci "$(git -C "$T/w1" rev-parse HEAD)" "$1" 1 success; }
( cd "$T/wa" && sh "$CHECKS/github.sh" review --list ) > "$T/out" 2>&1; grep -qx "pr $P vid/$N head=$HEAD1" "$T/out" || fail 'review --list does not list the open pull request'
rv || fail 'the good pull request was refused'
for l in "review: ci green on $HEAD1" 'review: test unchanged — tests/invariants/test_a.py' 'review: paths inside the modules and shared paths' 'review: block ok'; do grep -qxF "$l" "$T/out" || fail "no line '$l'"; done
grep -q " result=ok " "$T/wa/.git/vid/reviews/$P" && grep -q "head=$HEAD1" "$T/wa/.git/vid/reviews/$P" || fail 'the reviewed head is not kept'
# CI red
sed "s/^201 1 $HEAD1 CI push completed success$/201 1 $HEAD1 CI push completed failure/" "$T/gh/runs" > "$T/r" && mv "$T/r" "$T/gh/runs"
if rv; then fail 'a red CI passed'; fi; grep -qxF "review: ci not green on $HEAD1" "$T/out" || fail 'the red CI is not named'
gh_ci "$HEAD1" 202 1 success; sed "/^201 1 /d" "$T/gh/runs" > "$T/r" && mv "$T/r" "$T/gh/runs"; rv || fail 'the pull request is not good again'
# a ticket test changed
( cd "$T/w1" && printf '# weakened\n' >> tests/invariants/test_a.py && git commit -qam 'weaken the test' ); newhead 203
if rv; then fail 'a changed ticket test passed'; fi; grep -qxF 'review: test changed — tests/invariants/test_a.py' "$T/out" || fail 'the changed test is not named'
# the correction last sent makes it the standard
cp "$T/w1/tests/invariants/test_a.py" "$T/cor"; { printf 'vid: answered — the corrected test follows.\n\n#### tests/invariants/test_a.py\n\n````\n'; cat "$T/cor"; printf '````\n'; } > "$T/c.md"
( cd "$V" && sh checks/github.sh comment "$N" --body-file "$T/c.md" > /dev/null ) || fail 'the correction could not be sent'
rv || fail 'the test matching the correction last sent was refused'
( cd "$T/w1" && git revert --no-edit HEAD > /dev/null ); newhead 204
if rv; then fail 'the original test passed after a correction was sent'; fi
mkdir -p "$T/gh/issues/$N/comments"; rm -f "$T/gh/issues/$N/comments/"*; rv || fail 'the pull request is not good again after the correction was withdrawn'
# a path outside the step
( cd "$T/w1" && mkdir -p app/other && printf 'x\n' > app/other/x.txt && git add app && git commit -qm 'outside' ); newhead 205
git -C "$T/wa" update-ref -d refs/remotes/origin/main   # R-1 (F4): an approver's clone made while the repository was empty has no origin/main
if rv; then fail 'a path outside the step passed (with no origin/main in the clone)'; fi; grep -qxF 'review: paths outside the step — app/other/x.txt' "$T/out" || fail 'the outside path is not named'
( cd "$T/w1" && git revert --no-edit HEAD > /dev/null ); newhead 206; rv || fail 'the pull request is not good again'
tk_dev 'another ticket, merged on main' app/notes/n.txt 'notes'   # R-1 (F3): the branch then merges origin/main, as a resume does
( cd "$T/w1" && git fetch -q origin && git merge -q --no-edit origin/main ); newhead 207
rv || fail 'a branch that merged origin/main was judged on main'"'"'s changes'; grep -qxF 'review: paths inside the modules and shared paths' "$T/out" || fail 'the merged branch'"'"'s paths are not inside'
# a bad block
gh_feat_block "$N" | sed 's/   ci: 201//' > "$T/bad.md"; cp "$T/bad.md" "$T/gh/prs/$P/body"
if rv; then fail 'a bad block passed'; fi; grep -qxF 'review: block refused —' "$T/out" && grep -q 'ROW-001: a pass names its CI run' "$T/out" || fail 'the bad block is not named'
gh_feat_block "$N" > "$T/gh/prs/$P/body"; rv || fail 'the pull request is not good again'
# the skeleton ticket: any path
cd "$V"; sh checks/ticket.sh skeleton-body --req REQ-001 > /dev/null 2>&1 && sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > /dev/null 2>&1 || fail 'the skeleton ticket was not published'
NS=$(awk '$1 == "ticket" && / kind=skeleton / { sub(/number=/, "", $2); print $2 }' .vid/tickets/map)
( cd "$T/w1" && git checkout -q main && [ "$(sh "$CHECKS/github.sh" next-ticket --worker 1)" = "next $NS" ] && sh "$CHECKS/github.sh" claim "$NS" --worker 1 > /dev/null && git fetch -q origin &&
  git checkout -q -b "vid/$NS" "origin/vid/$NS" && mkdir -p .github/workflows src && printf 'ci\n' > .github/workflows/ci.yml && printf 'x\n' > src/a.txt && git add -A && git commit -qm skeleton ) || fail 'the skeleton work failed'
gh_skel_block "$NS" > "$T/sk.md"; ( cd "$T/w1" && sh "$CHECKS/github.sh" push "vid/$NS" --pr "$T/sk.md" > /dev/null 2>&1 ) || fail 'the skeleton pull request failed'
PS=$(ls "$T/gh/prs" | sort -n | tail -n 1); gh_ci "$(git -C "$T/w1" rev-parse HEAD)" 301 1 success
( cd "$T/wa" && sh "$CHECKS/github.sh" review "$PS" ) > "$T/out" 2>&1 || fail 'the skeleton pull request was refused'
grep -qxF 'review: paths free (the skeleton ticket)' "$T/out" || fail "the skeleton ticket's paths are not free"
# R-1 (F2): the skeleton's pull request, merged, is imported before the vid-code block names its ci-workflow
printf '<testsuites><testsuite name="t"></testsuite></testsuites>\n' > "$T/empty.xml"; mkdir -p "$T/gh/artifacts/301/vid-junit-1"; cp "$T/empty.xml" "$T/gh/artifacts/301/vid-junit-1/report.xml"
( cd "$T/wa" && sh "$CHECKS/github.sh" merge "$PS" ) > "$T/out" 2>&1 || fail 'the skeleton pull request was not merged'
git -C .vid/code fetch -q; sh checks/github.sh pull > /dev/null 2>&1
grep -q '^ci-workflow:' ARCHITECTURE.md && fail 'the toy names ci-workflow: already — the case proves nothing'
sh checks/ticket.sh import "$PS" > "$T/out" 2>&1 || fail 'the skeleton pull request was not imported before the test facts exist'
grep -q '^receipt: .*\.ci-301-1\.xml' "$T/out" && grep -q '^skeleton line: skeleton: ci-workflow: CI' "$T/out" || fail "the skeleton's receipt or its skeleton: lines are missing"
exit 0
