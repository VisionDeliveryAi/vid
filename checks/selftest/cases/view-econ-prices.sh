#!/bin/sh
# Purpose: selftest case — a dated price table, for estimates only (v0.26.10.6 spec R13). The viewer fixture with
# planted usage in four kinds: a priced model with a 1-hour cache write, a model the table lacks, `default` (a Codex
# job's) and `mixed`. Convicts unless the data's prices are viewer/prices.tsv's — its as-of date, every source, not
# a placeholder, each model's five rates keyed by its name — and name none of the unpriced models; unless each entry
# keeps its model as recorded (the page then says "model not priced"); and unless the built page prices the 1-hour
# part of a cache write at the table's 1-hour rate and the rest at the 5-minute rate. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-econ-prices: $*" >&2; exit 1; }
PT="$CHECKS/../viewer/prices.tsv"; [ -f "$PT" ] || fail 'no viewer/prices.tsv'
view_project "$T/repo"
M1=$(awk -F'\t' '!/^#/ && NF >= 6 { print $1; exit }' "$PT")
for a in A1:"$M1" A2:no-such-model A3:default A4:mixed; do id=${a%%:*}; m=${a#*:}
  vev 11:00 "agent-start session=S1 agent=$id type=vid:grader"; vev 11:05 "agent-stop session=S1 agent=$id type=vid:grader transcript=-"
  vev 11:05:01 "usage agent=$id session=S1 tool=claude model=$m effort=high calls=1 input=1000000 cache-read=1000000 cache-write=1000000 cache-write-1h=400000 output=1000000 scope=agent"; done
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
P=$(vel "$N" '"prices":{')
AS=$(sed -n 's/^as-of //p' "$PT"); printf '%s' "$P" | grep -qF "\"prices\":{\"asOf\":\"$AS\"," || fail "the as-of date: $P"
sed -n 's/^source //p' "$PT" | while IFS= read -r u; do printf '%s' "$P" | grep -qF "$u" || fail "the source $u is not named: $P"; done
printf '%s' "$P" | grep -qF '"placeholder":false' || fail 'the prices are marked placeholders'
awk -F'\t' '!/^#/ && NF >= 6 && $2 ~ /^[0-9.]+$/' "$PT" | while IFS='	' read -r m i cr cw c1 o; do
  printf '%s' "$P" | grep -qF "\"$m\":{\"input\":$i,\"cacheRead\":$cr,\"cacheWrite\":$cw,\"cacheWrite1h\":$c1,\"output\":$o}" || fail "$m's rates are not the table's: $P"; done
for m in no-such-model default mixed; do printf '%s' "$P" | grep -qF "\"$m\":" && fail "$m is priced"; done
for a in A1:"$M1" A2:no-such-model A3:default A4:mixed; do vel "$N" "{\"agent\":\"${a%%:*}\"," | grep -qF "\"model\":\"${a#*:}\"" || fail "${a%%:*} does not keep its model"; done
grep -qF '((u.cacheWrite||0)-(u.cacheWrite1h||0))*p.cacheWrite+(u.cacheWrite1h||0)*p.cacheWrite1h+' "$N" || fail 'the page does not price the 1-hour cache write at its own rate'
grep -qF "if(!p)return {why:'model not priced'}" "$N" || fail 'the page does not say model not priced'
exit 0
