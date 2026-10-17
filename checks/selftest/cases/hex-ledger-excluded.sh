#!/bin/sh
# Purpose: selftest case — the hex-colour court excludes the ledger tests (v0.9.7.3 spec 3.9, R9; owner-accepted on
# the live project since 2026-09-26). With a ratified design (design/tokens.css): a ledger test under
# tests/invariants/ whose expected value is a raw hex colour passes conformance; the same colour in app source is
# still refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "hex-ledger-excluded: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p checks design app tests/invariants; cp "$CHECKS/conformance.sh" checks/
printf '# BASELINE\n\n```vid-allowed-extensions\n.sh .css .js .md\n```\n' > BASELINE.md
printf ':root { --accent: #0a5; }\n' > design/tokens.css
g add -A && g commit -qm root
printf '# Purpose: the ledger\nexpect_colour "#0a5aff" on the primary action\n' > tests/invariants/test_colour.sh; g add tests/invariants/test_colour.sh
sh checks/conformance.sh > "$T/out" 2>&1 || fail 'a ledger test'"'"'s expected hex colour was refused'
g commit -qm 'the ledger test'
printf '// Purpose: app\nconst accent = "#0a5aff";\n' > app/x.js; g add app/x.js
if sh checks/conformance.sh > "$T/out" 2>&1; then fail 'a raw hex colour in app source passed'; fi
grep -q 'raw hex color' "$T/out" || fail 'the refusal does not name the hex colour'
exit 0
