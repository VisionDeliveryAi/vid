#!/bin/sh
# Purpose: selftest case — the rendered-vs-cited class (§9, report-only):
# a rule whose source correctly cites its canvas but whose COMPUTED value
# differs (specificity override) must surface as a REND report line — and
# must NOT fail the commit (report-only until a measured FP rate), must
# never be swallowed as ok, and a silent-empty rendered extractor must
# still fail (silence is how a census dies).
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors
cat > checks/extractors/rendered.toy.sh <<'EOF'
#!/bin/sh
# Purpose: seeded fixture — a specificity-overridden identity color.
echo 'ok P02/populated:color'
echo 'orphan P02/populated:background-color cited=var(--jt-accent) computed=rgb(255,0,0) specificity-override'
EOF
ST=0; OUT=$(sh "$CHECKS/census.sh" 2>&1) || ST=$?
# report-only: the commit does not fail...
[ "$ST" -eq 0 ] || exit 1
# ...but the mismatch is REPORTED, never swallowed
printf '%s\n' "$OUT" | grep -q '^REND .*P02/populated:background-color' || exit 1
printf '%s\n' "$OUT" | grep -q 'rendered-reports=1' || exit 1
# silence is failure, for this class like every other
printf '#!/bin/sh\nexit 0\n' > checks/extractors/rendered.silent.sh
if sh "$CHECKS/census.sh" >/dev/null 2>&1; then exit 1; fi
exit 0
