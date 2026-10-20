#!/bin/sh
# Purpose: selftest case — the question's count and what lands are one calculation (v0.26.10.3 R1, R4; §5
# impact-equals-post-commit). A toy repository with the real post-commit hook under `grammar: 0.9.3`: REQ-001 (rows
# ROW-001, ROW-002, ROW-004) and REQ-002 (ROW-003). The candidate, in the working tree: REQ-001's fail-if changed,
# ROW-001's obligation changed, ROW-005 added under REQ-001. Convicts unless `inventory.sh impact` (base HEAD, the working
# tree's files) prints reset ROW-001 and confirm ROW-002,ROW-004 with their counts, exits 0 and writes nothing; and
# unless the commit of that candidate then writes `amended … by=obligation` for exactly the reset set and `law-changed`
# for exactly the confirm set. A second candidate given as files (--prd, --inventory) beside an unchanged working tree
# gives the same sets as the files; with nothing changed both sets read `-`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q; mkdir -p checks/hooks .vid
cp "$CHECKS/inventory.sh" "$CHECKS/prd.sh" checks/; cp "$CHECKS/hooks/post-commit" checks/hooks/; chmod +x checks/hooks/post-commit
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "impact-equals-post-commit: $*" >&2; exit 1; }
prd() { printf '# Toy — PRD\n\ngrammar: 0.9.3\n\n```vid-prd\nREQ-001 | functional | T1 | A link lasts a while. | fail-if: %s | serves: x | authority: authoritative | source: A-001 | phase: pilot | plain: links expire\nREQ-002 | functional | T1 | A code is short. | fail-if: a code has another length than six | serves: x | authority: authoritative | source: A-002 | phase: pilot | plain: codes are short\n```\n' "$1"; }
inv() { # <ROW-001 obligation> [extra row]
  printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | s1 | anon | - | %s | REQ-001 | owed: prerequisite — a clock; paid at slice 2\nROW-002 | behavior | s2 | anon | - | a link answers before it expires | REQ-001 | owed: prerequisite — a clock; paid at slice 2\nROW-003 | behavior | s3 | anon | - | a code is six characters | REQ-002 | owed: prerequisite — a clock; paid at slice 2\nROW-004 | behavior | s4 | anon | - | an expired link says so | REQ-001, REQ-002 | owed: prerequisite — a clock; paid at slice 2\n%s```\n' "$1" "${2:-}"; }
printf '.vid/\n' > .gitignore
prd 'a link works after seven days' > PRD.md; inv 'a link refuses after seven days' > INVENTORY.md
g add -A; g commit -qm root; git config core.hooksPath checks/hooks
EV=.vid/metrics-events; : > "$EV"
# the candidate, in the working tree
prd 'a link works after three days' > PRD.md
inv 'a link refuses after three days' 'ROW-005 | behavior | s5 | anon | - | a new link is created | REQ-001 | owed: prerequisite — a clock; paid at slice 2
' > INVENTORY.md
sh checks/inventory.sh impact > "$T/impact" 2> "$T/impact.err" || fail "impact exited non-zero: $(cat "$T/impact.err")"
[ ! -s "$EV" ] || fail 'impact wrote an event'
sed -n 1p "$T/impact" | grep -qE '^impact reset=1 reset-passing=[a-z0-9]+ reset-kept=[a-z0-9]+ confirm=2 confirm-passing=[a-z0-9]+ confirm-kept=[a-z0-9]+$' || fail "impact's count line: $(sed -n 1p "$T/impact")"
[ "$(sed -n 2p "$T/impact")" = 'reset ROW-001' ] || fail "impact's reset set: $(sed -n 2p "$T/impact")"
[ "$(sed -n 3p "$T/impact")" = 'confirm ROW-002,ROW-004' ] || fail "impact's confirm set: $(sed -n 3p "$T/impact")"
g add -A; g commit -qm candidate > /dev/null 2>&1 || fail 'the candidate did not commit'
H=$(git rev-parse --short=12 HEAD)
[ "$(sed -n "s/^amended row=\([^ ]*\) sha=$H by=obligation .*/\1/p" "$EV" | sort | paste -sd, -)" = "$(sed -n 's/^reset //p' "$T/impact")" ] || fail "the reset set landed differently: $(cat "$EV")"
[ "$(sed -n "s/^law-changed row=\([^ ]*\) sha=$H item=REQ-001 .*/\1/p" "$EV" | sort | paste -sd, -)" = "$(sed -n 's/^confirm //p' "$T/impact")" ] || fail "the confirm set landed differently: $(cat "$EV")"
[ "$(grep -c . "$EV")" -eq 3 ] || fail "not exactly the three events: $(cat "$EV")"
grep -q 'ROW-005' "$EV" && fail 'the new row got an event'
# a candidate as files, the working tree unchanged
prd 'a link works after one day' > "$T/prd.draft"; sed 's/^ROW-003 | behavior | s3 | anon | - | a code is six characters |/ROW-003 | behavior | s3 | anon | - | a code is exactly six characters |/' INVENTORY.md > "$T/inv.draft"
sh checks/inventory.sh impact --prd "$T/prd.draft" --inventory "$T/inv.draft" > "$T/impact2" || fail 'impact on files exited non-zero'
git diff --quiet || fail 'impact on files changed the working tree'
[ "$(sed -n 2,3p "$T/impact2" | paste -sd ' ' -)" = 'reset ROW-003 confirm ROW-001,ROW-002,ROW-004,ROW-005' ] || fail "impact on files: $(cat "$T/impact2")"
[ "$(sh checks/inventory.sh impact | sed -n 2,3p | paste -sd ' ' -)" = 'reset - confirm -' ] || fail "an empty impact does not print its sets as -: $(sh checks/inventory.sh impact)"
exit 0
