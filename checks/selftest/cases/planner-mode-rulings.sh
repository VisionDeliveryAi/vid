#!/bin/sh
# Purpose: selftest case — the planner's GitHub manual branches stand only where a ruling names them (GM-4 F11, its case
# planner-mode-rulings). Every code line of checks/planner.sh that branches on the mode (MAN, or lib.sh's manual run as a
# command) names its ruling, a D<n> or GM M<n>, on the line or in the comment lines directly above it. Team names are
# lower-cased by one rule in both modes: on the planner's toy in GitHub auto, the team `Alpha` and the lanes `Alpha` read as
# alpha, with no setup or lane flag, and `planner.sh setup team` records the name lower-cased. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "planner-mode-rulings: $*" >&2; exit 1; }
awk '/^[ \t]*#/ { c = c " " $0; next }
  { l = $0; sub(/^[ \t]*/, "", l); x = l
    gsub(/-v MAN="\$MAN"/, "", x); gsub(/(^|[;{ ])MAN=(\047\047|1)/, "", x)
    b = (x ~ /(^|[^A-Za-z_])MAN([^A-Za-z_=]|$)/) || (x ~ /(^|[;&|!({] *|if |then )manual( |;|$)/)
    if (b && (c " " l) !~ /(D[0-9]+|GM M[0-9]+)/) print FILENAME ":" NR ": " substr(l, 1, 120); c = "" }' "$CHECKS/planner.sh" > "$T/nr"
[ ! -s "$T/nr" ] || { cat "$T/nr" >&2; fail 'a GitHub manual branch of the planner names no ruling (above)'; }
pt_toy "$T/toy"; pt_teams 'Alpha | the whole product | core | 1'; pt_rs 's/lane: devagent/lane: Alpha/'
pt_check
grep -qE '^(planner: clean|[a-z]+ [^ ]+ — )' "$T/out" || { cat "$T/out" >&2; fail 'the check printed neither clean nor flags: it did not run'; }
grep -q '^setup "team: Alpha' "$T/out" && { cat "$T/out" >&2; fail 'in GitHub auto the team Alpha is flagged, not read lower-cased'; }
grep -q '^lane ' "$T/out" && { cat "$T/out" >&2; fail 'in GitHub auto the lane Alpha is flagged, not read as the team alpha'; }
sh "$CHECKS/planner.sh" setup team 'Beta | the rest | core | 1' --words 'and a second team' > "$T/su" 2>&1 || { cat "$T/su" >&2; fail 'the setup of a second team was refused'; }
grep -q '^team: beta |' .vid/tw/settings || { cat .vid/tw/settings >&2; fail 'in GitHub auto the team name Beta was not recorded lower-cased'; }
echo 'planner-mode-rulings: ok'
