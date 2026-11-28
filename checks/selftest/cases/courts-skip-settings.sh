#!/bin/sh
# Purpose: selftest case — the conformance and seams courts read the project's own files, never ViD's host settings file
# (FIX-BATCH-T3 §1, B-15). init's step 6 writes .claude/settings.json (other plugins' names, on the owner's yes); a name
# holding a forbidden term, or an owed seam's token, refused the spec commit. Convicts unless: (a) conformance passes that
# file staged with a forbidden term while the allowed list lacks .json; (b) beside it, a term in app/ is refused, quoting
# the app's line and not the settings line; (c) another file under .claude/ and (d) a settings.json elsewhere are refused
# for the term and the extension; (e) a lockfile line is refused for the term; (f) seams passes the file staged with an
# owed seam's token and an outside URL; (g) beside it, the token in app/ is refused, quoting the app's line alone; (h) the
# token in another .claude/ file and in a settings.json elsewhere is refused; (i) the URL in app/ is refused.
# Made-up data only. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "courts-skip-settings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
# run <court> <want rc>: the court's rc must be the one wanted
run() { RC=0; sh "$CHECKS/$1.sh" > "$T/out" 2>&1 || RC=$?; [ "$RC" = "$2" ]; }
put() { mkdir -p "${1%/*}"; printf '%s\n' "$2" > "$1"; g add -f "$1"; }

# conformance
mkdir "$T/c"; cd "$T/c"; git init -q
printf '# Baseline\n\n```vid-allowed-extensions\n.md .sh .txt .lock\n```\n\n```vid-forbidden\nzapkit\n```\n' > BASELINE.md
g add -A; g commit -qm root
put .claude/settings.json '{ "enabledPlugins": { "zapkit-tools@example-market": false } }'
run conformance 0 || fail "(a) the host settings file was refused ($RC)"
put app/config.txt 'use zapkit-core'
run conformance 1 && grep -q "forbidden term 'zapkit'" "$T/out" || fail "(b) the term in app/ was not refused ($RC)"
grep -q 'zapkit-core' "$T/out" || fail "(b) the refusal does not quote the app's line"
grep -q 'zapkit-tools' "$T/out" && fail "(b) the refusal quotes the settings file's line"
g reset -q app/config.txt
for f in .claude/other.json app/settings.json; do
  put "$f" '{ "zapkit-extra": true }'
  run conformance 1 || fail "($f) was let through ($RC)"
  grep -q "forbidden term 'zapkit'" "$T/out" || fail "(c, d) $f was not refused for the term"
  grep -q "'$f' introduces extension '.json'" "$T/out" || fail "(c, d) $f was not refused for its extension"
  g reset -q "$f"
done
put app/deps.lock 'zapkit 1.2.3'
run conformance 1 && grep -q "forbidden term 'zapkit'" "$T/out" || fail "(e) the lockfile line was not refused ($RC)"

# seams
mkdir "$T/s"; cd "$T/s"; git init -q
printf '# toy\n```vid-inventory\nseam | SEAM-001 | examplepay | card charges | chosen: D-001 | credentials: named | probe: owed | evidence: none | quirks: none | match: examplepay\n```\n' > INVENTORY.md
g add -A; g commit -qm root
put .claude/settings.json '{ "enabledPlugins": { "examplepay-tools@example-market": false }, "hook": "https://hooks.examplechat.com/in" }'
run seams 0 || fail "(f) the host settings file was refused ($RC)"
put app/pay.txt 'use examplepay-client'
run seams 1 && grep -q 'SEAM-001' "$T/out" || fail "(g) the token in app/ was not refused ($RC)"
grep -q 'examplepay-client' "$T/out" || fail "(g) the refusal does not quote the app's line"
grep -q 'examplepay-tools' "$T/out" && fail "(g) the refusal quotes the settings file's line"
g reset -q app/pay.txt
for f in .claude/other.json app/settings.json; do
  put "$f" '{ "examplepay-extra": true }'
  run seams 1 && grep -q 'SEAM-001' "$T/out" || fail "(h) the token in $f was let through ($RC)"
  g reset -q "$f"
done
put app/hook.txt 'https://hooks.examplechat.com/in'
run seams 1 && grep -q 'hooks.examplechat.com' "$T/out" || fail "(i) the outside URL in app/ was not refused ($RC)"
echo 'courts-skip-settings: ok'
