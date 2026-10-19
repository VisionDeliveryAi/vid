#!/bin/sh
# Purpose: selftest case — the architecture change kind (v0.26.10.2 spec R9). The viewer fixture with view_arch at
# 11:40 (requested), then at 11:50: app/s1's responsibility changed, web removed, app/s4 added, the Database choice
# changed, SEAM-003 removed and SEAM-004 added. Convicts unless now's window holds exactly those six architecture
# changes, each with what, part, text and ids, a change with each field's from and to, at null and no
# capabilities — and no change for a module whose derived may-use alone changed. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-changes: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40; A=$(git rev-parse HEAD)
awk '/^\| web \|/ { next } /^\| app\/s1 \|/ { sub(/Finding things/, "Finding all things"); print; print "| app/s4 | Gifts | gifts | `app.s4.api` — wrap() | web |"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
sed 's/| Store X 16 |/| Store X 17 |/' BASELINE.md > B.x && mv B.x BASELINE.md
awk '/^seam \| SEAM-003/ { print "seam | SEAM-004 | Post | posting parcels | chosen: D-001 | credentials: held | probe: owed | evidence: owed | quirks: none yet"; next } { print }' INVENTORY.md > I.x && mv I.x INVENTORY.md
g add -A; vcommit 11:50 'the architecture moves'
vview . --out "$T/out" --at "$A" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
vdata "$T/out/now.html" | sed "s/^\"changes\":\[//" | grep '^,\{0,1\}{"kind":"architecture"' > "$T/ch" || fail 'now holds no architecture change'
[ "$(grep -c . "$T/ch")" -eq 6 ] || fail "now does not hold six architecture changes: $(cat "$T/ch")"
for x in '{"kind":"architecture","ids":["app/s1"],"at":null,"what":"changed","part":"module","text":"app/s1","fields":[{"name":"responsibility","from":"Finding things","to":"Finding all things"}],"capabilities":[],"window":"now.html"}' \
  '{"kind":"architecture","ids":["web"],"at":null,"what":"removed","part":"module","text":"web","capabilities":[],"window":"now.html"}' \
  '{"kind":"architecture","ids":["app/s4"],"at":null,"what":"added","part":"module","text":"app/s4","capabilities":[],"window":"now.html"}' \
  '{"kind":"architecture","ids":["Database"],"at":null,"what":"changed","part":"stack","text":"Database","fields":[{"name":"choice","from":"Store X 16","to":"Store X 17"}],"capabilities":[],"window":"now.html"}' \
  '{"kind":"architecture","ids":["SEAM-003"],"at":null,"what":"removed","part":"service","text":"Maps","capabilities":[],"window":"now.html"}' \
  '{"kind":"architecture","ids":["SEAM-004"],"at":null,"what":"added","part":"service","text":"Post","capabilities":[],"window":"now.html"}'; do
  grep -qF "$x" "$T/ch" || fail "now lacks $x: $(cat "$T/ch")"; done
sh "$VIEWER_SH" --check "$T/out/now.html" > "$T/c" 2>&1 || fail "now fails the check: $(cat "$T/c")"
exit 0
