#!/bin/sh
# Purpose: selftest case — the harness-upgrade brief (v0.9.7.0.10 spec 3.6,
# R13). The brief-write fixture with bw_builder, a harness with no rules:
# line committed, a toy template carrying the three rules, two gated
# ledger-run events with overhead= (and one plain run without), and a
# ticket's timeline.log. `write --role builder --step S2 … --upgrade`
# writes ## 13 harness upgrade: the harness's hash at HEAD and `rules:
# none`, the template's path, the timeline.log, the gated passes' overhead
# lines and not the plain run's, the three rules in the template's words,
# and the harness file whole — and the check says ok. A test-author brief
# takes --upgrade too; a grader's is refused. The check refuses a section
# 13 whose hash is not the harness's at quoted-at; the writer refuses when
# the harness declares rules:. v0.9.7.0.11 (3.2, R2): the toy template
# carries four rules under `rules: 2`; the section's first line says
# `rules: none    target: 2`, it lists the slowest cases of the run's
# .cases (seconds first) and quotes rule 4; a harness at `rules: 1` is
# briefed too (`rules: 1    target: 2`); one at `rules: 2` is refused.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-harness-upgrade: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
mkdir -p "$CLAUDE_PLUGIN_ROOT/templates"
printf '# toy template\n#\n# Four harness rules (toy):\n#  1. nothing installed at start.\n#  2. ready before use.\n#  3. test-sized data.\n#  4. no case past case-limit.\n# checks/harness.sh holds rules 2 and 4.\n#\nx-vid-harness:\n  product: product\n  rules: 2\n' > "$CLAUDE_PLUGIN_ROOT/templates/docker-compose.test.yml"
printf 'x-vid-harness:\n  product: product\nservices:\n  product:\n    build: .\n  tests:\n    image: runner\n    command: install, then run\n' > docker-compose.test.yml
g add -A && g commit -qm 'a harness without the rules'
HH=$(cksum < docker-compose.test.yml | cut -d' ' -f1)
mkdir -p .vid/requests/20261010T101500Z-ab12 .vid/ledger-results
printf 'case tests/a.py::slow passed 42.5\ncase tests/a.py::quick passed 0.2\n' > .vid/ledger-results/a.xml.cases
printf 'stub-logs\n' > .vid/requests/20261010T101500Z-ab12/timeline.log
{ printf 'ledger-run seconds=200 kind=scoped report=a.xml status=0 role=builder tree=t run=r1 request=x overhead=190 at=2026-10-10T01:00:00Z\n'
  printf 'ledger-run seconds=30 kind=scoped report=p.xml status=0 role=- at=2026-10-10T01:01:00Z\n'
  printf 'ledger-run seconds=210 kind=scoped report=b.xml status=0 role=builder tree=t run=r2 request=y overhead=201 at=2026-10-10T01:02:00Z\n'; } >> .vid/metrics-events
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --upgrade || fail 'the upgrade brief was refused'
B=$(bw_out); grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$B"; }
sec 13 | grep -qx "harness: docker-compose.test.yml    hash: $HH    rules: none    target: 2" || fail 'section 13 does not name the harness, its hash and the target'
sec 13 | grep -qx "$(printf '42.5\ttests/a.py::slow')" || fail 'section 13 does not list the slowest case'
sec 13 | grep -qx '#  4. no case past case-limit.' || fail 'section 13 lacks rule 4'
sec 13 | grep -qx "template: $CLAUDE_PLUGIN_ROOT/templates/docker-compose.test.yml" || fail 'section 13 does not name the template'
sec 13 | grep -qx 'timeline: .vid/requests/20261010T101500Z-ab12/timeline.log' || fail 'section 13 does not name the timeline'
sec 13 | grep -qx 'a.xml seconds=200 overhead=190' && sec 13 | grep -qx 'b.xml seconds=210 overhead=201' || fail "section 13 lacks the gated passes' overhead"
sec 13 | grep -q '^p\.xml' && fail 'section 13 carries a plain run'
sec 13 | grep -qx '#  2. ready before use.' || fail 'section 13 lacks the rules'
sec 13 | grep -qx '        command: install, then run' || fail 'section 13 lacks the harness file'
bw_write --role test-author --slice 2 --rows ROW-104 --upgrade || fail 'the test-author upgrade brief was refused'
grep -q '^## 13 harness upgrade' "$(bw_out)" || fail 'the test-author brief has no section 13'
if bw_write --role grader --slice 2 --rows ROW-104 --receipt a.xml --upgrade; then fail 'a grader upgrade brief was written'; fi
grep -q -- '--upgrade briefs a builder or a test-author' "$T/wout" || fail 'the grader refusal does not name it'
# a section 13 for another harness
sed "s/hash: $HH/hash: 12345/" "$B" | grep -v '^written: ' > .vid/briefs/2/builder-9.md
if sh checks/brief.sh .vid/briefs/2/builder-9.md > "$T/wout" 2>&1; then fail 'a section 13 naming another harness passed'; fi
grep -q "section 13: the harness hash '12345'" "$T/wout" || fail 'the refusal does not name section 13'
awk '{ print } $0 == "  product: product" { print "  rules: 1" }' docker-compose.test.yml > c && mv c docker-compose.test.yml
g add -A && g commit -qm 'the rules'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --upgrade || fail 'the upgrade brief for a harness at rules: 1 was refused'
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$(bw_out)"; }
sec 13 | grep -q '    rules: 1    target: 2$' || fail 'the rules: 1 brief does not say rules: 1 target: 2'
sed 's/^  rules: 1$/  rules: 2/' docker-compose.test.yml > c && mv c docker-compose.test.yml
g add -A && g commit -qm 'rule 4'
if bw_write --role builder --slice 2 --step S2 --rows ROW-104 --upgrade; then fail 'an upgrade brief was written for a harness declaring rules: 2'; fi
grep -q 'declares rules: 2 — nothing to upgrade' "$T/wout" || fail 'the refusal does not say why'
exit 0
