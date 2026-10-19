#!/bin/sh
# Purpose: selftest case — the module table as written, and may use (v0.26.10.2 spec R1, R2). The viewer fixture
# with view_arch. Convicts unless now's architecture holds the five rows of the first Module table only (no {{ row,
# no External boundaries row), the dotted label app.s2 read as the id app/s2, every cell as written; app/s1's
# Dependents read as the court reads them: web may use it, and the dotted, trailing-slash and tests/invariants names
# go to otherNames as written; app/s3's `all` beside web opens it to every module; mayUse the reverse plus the open
# module; and a table lacking a column gives null in that field on every row, the column named in missing. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-modules: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
[ "$(varch "$N" | grep -c '"responsibility":')" -eq 5 ] || fail "now does not hold five modules: $(varch "$N")"
varch "$N" | grep -q '{{MODULE\|"id":"Pay"' && fail 'a {{ row or the External boundaries table was read as a module'
vmod "$N" app/s1 | grep -qF '"responsibility":"Finding things","ownedData":"items","surface":"`app.s1.api` — find()","dependents":"app.s2, app/s3/, web tests/invariants","openToAll":false,"mayBeUsedBy":["web"],"otherNames":["app.s2","app/s3/","tests/invariants"],"mayUse":["app/s3","app/s1/deep"]' || fail "app/s1 is not as written and as the court reads it: $(vmod "$N" app/s1)"
vmod "$N" app/s2 | grep -qF '"mayBeUsedBy":["web"],"otherNames":[],"mayUse":["app/s3"]' || fail "the dotted label app.s2 is not the module app/s2: $(varch "$N")"
vmod "$N" app/s3 | grep -qF '"dependents":"all, web","openToAll":true,"mayBeUsedBy":["web"],"otherNames":[]' || fail "app/s3 is not open to every module: $(vmod "$N" app/s3)"
vmod "$N" app/s1/deep | grep -qF '"ownedData":"-",' || fail 'a cell is not kept as written'
vmod "$N" web | grep -qF '"mayBeUsedBy":[],"otherNames":[],"mayUse":["app/s1","app/s2","app/s3"]' || fail "web's may-use is not the reverse plus the open module: $(vmod "$N" web)"
# a column missing: null on every row, named
sed 's/ Owned tables\/data |/ Owns |/' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A; vcommit 11:50 'a renamed column'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
[ "$(varch "$N" | grep -c '"ownedData":null')" -eq 5 ] || fail "a missing column is not null on every row: $(varch "$N")"
varch "$N" | grep -qF '{"part":"modules","why":"The module table has no Owned tables/data column."}' || fail "the missing column is not named: $(varch "$N" | tail -n 1)"
exit 0
