#!/bin/sh
# Purpose: selftest case — decisions linked to a module (v0.26.10.2 spec R13). The viewer fixture with view_arch and,
# at 11:40, after building started: D-002 labelled app/s3 (a module label); D-003 naming web; D-004 app.s1.api.find (a
# dotted, deeper path); D-005 app/s1/deep/index.py (a nested module's path); D-006 webhooks and xapp/s1 (longer
# names holding an id); D-007 labelled ROW-004 and app/s3, naming app.s2.api and app/s3 (more than one link); D-008
# scope: project, naming web. D-001 (labelled REQ-001) is from 09:30, before building started. Convicts unless each
# module lists exactly its decisions, each once by its first link, mentions with the words matched; D-001 is at spec
# and D-002 during the build, each with its commit; and with no develop start, or at a commit off HEAD's first-parent
# history, added and stage are null. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-decisions: $*" >&2; exit 1; }
view_project "$T/repo"; C1=$(git log -1 --abbrev=7 --format=%h --grep="^the documents$")
{ printf -- '- **D-002** The clock is read once a request | why: one time a page | enforced: convention | applies-to: app/s3\n'
  printf -- '- **D-003** Pages in web hold no state | why: any server serves them | enforced: convention | applies-to: ROW-001\n'
  printf -- '- **D-004** Call app.s1.api.find() for every search | why: one way in | enforced: convention | applies-to: ROW-002\n'
  printf -- '- **D-005** app/s1/deep/index.py is rebuilt nightly | why: it is large | enforced: convention | applies-to: ROW-003\n'
  printf -- '- **D-006** webhooks and xapp/s1 are retried | why: they fail | enforced: convention | applies-to: ROW-999\n'
  printf -- '- **D-007** Restocks go through app.s2.api, timed by app/s3 | why: one clock | enforced: convention | applies-to: ROW-004, app/s3\n'
  printf -- '- **D-008** Every page in web is logged | why: audits | enforced: convention | scope: project\n'; } >> DECISIONS.md
view_arch 11:40; D2=$(git rev-parse --short=7 HEAD)
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
dc() { vmod "$N" "$1" | grep -qF "\"decisions\":[$2]," || fail "$1's decisions are not $2: $(vmod "$N" "$1" | sed 's/.*"decisions"://; s/,"files".*//')"; }
# D-003, D-004 and D-005 are labelled for rows of S1, so app/s1 holds them by label, the first link
dc app/s1 '{"id":"D-001","by":"label","match":null},{"id":"D-003","by":"label","match":null},{"id":"D-004","by":"label","match":null},{"id":"D-005","by":"label","match":null}'
dc app/s2 '{"id":"D-001","by":"label","match":null},{"id":"D-007","by":"label","match":null}'
dc app/s3 '{"id":"D-002","by":"module-label","match":null},{"id":"D-007","by":"module-label","match":null}'
dc app/s1/deep '{"id":"D-005","by":"mentions","match":"app/s1/deep/index.py"}'
dc web '{"id":"D-003","by":"mentions","match":"web"}'
varch "$N" | grep -q '"D-006"\|"D-008"' && fail 'a longer name holding a module id, or a project-wide decision, is linked to a module'
# a mention by a dotted, deeper path, where no label links it: D-004 relabelled for no row
sed 's/applies-to: ROW-002$/applies-to: ROW-998/' DECISIONS.md > D.x && mv D.x DECISIONS.md; g add -A; vcommit 11:50 'relabel D-004'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
dc app/s1 '{"id":"D-001","by":"label","match":null},{"id":"D-003","by":"label","match":null},{"id":"D-004","by":"mentions","match":"app.s1.api.find"},{"id":"D-005","by":"label","match":null}'
vdata "$N" | grep -qF "\"id\":\"D-001\",\"what\":\"Prices are held in pence\",\"why\":\"no rounding\",\"appliesTo\":\"REQ-001\",\"scope\":null,\"enforced\":\"convention\",\"added\":{\"commit\":\"$C1\",\"time\":\"2026-01-01T09:30:00Z\"},\"stage\":\"spec\"}" || fail "D-001 is not dated at spec: $(vdata "$N" | grep -F '"id":"D-001","what"')"
vdata "$N" | grep -F '"id":"D-002","what"' | grep -qF "\"added\":{\"commit\":\"$D2\",\"time\":\"2026-01-01T11:40:00Z\"},\"stage\":\"build\"}" || fail "D-002 is not dated during the build: $(vdata "$N" | grep -F '"id":"D-002","what"')"
# off HEAD's first-parent history
BR=$(git rev-parse --abbrev-ref HEAD); git checkout -q -b side; printf 'side\n' > side.txt; g add -A; vcommit 12:05 'a side commit'; SIDE=$(git rev-parse HEAD); git checkout -q "$BR"
vview . --out "$T/out" --at "$SIDE" > "$T/r" 2>&1 || fail "the side run failed: $(cat "$T/r")"
vdata "$T/out/20260101T120500Z-requested.html" | grep -qF '"id":"D-001","what":"Prices are held in pence","why":"no rounding","appliesTo":"REQ-001","scope":null,"enforced":"convention","added":null,"stage":null}' || fail 'a snapshot off the first-parent history is dated'
# no develop start
grep -v '^stage name=develop state=start' .vid/metrics-events > .vid/e.x && mv .vid/e.x .vid/metrics-events
vview . --out "$T/out2" > "$T/r" 2>&1 || fail "the third run failed: $(cat "$T/r")"
vdata "$T/out2/now.html" | grep -qF '"enforced":"convention","added":null,"stage":null}' || fail 'a project with no develop start is dated'
vdata "$T/out2/now.html" | grep -q '"stage":"spec"\|"stage":"build"' && fail 'a stage is given with no develop start'
exit 0
