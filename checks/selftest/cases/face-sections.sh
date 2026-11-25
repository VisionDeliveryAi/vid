#!/bin/sh
# Purpose: selftest case — the owner's list in the panel (FB-5 A1, S3). The panel reads .vid/face/list.json and draws the sections
# My to do, Waiting, Changed, The rest, The plan and one a team, numbered and in order, narrow and wide, with a link to each; My to
# do's first line open, one at a time; a press sent in the chat as the owner's words, once, with the ids of its line, and put in the
# message box where the chat refused it; the plan's boxes and what holds the rest up; a card a step, three tracks side by side from
# 90 columns; with no plan, four sections. Convicts unless the panel's own tests of it (hooks/face, named FB-5 A1) all pass with
# Claude Code's test kit, and unless every word of the list takes a theme's named colour. Gated on the plugin's hooks/face/ beside
# checks/ and on a claude on PATH. Env: CHECKS.
set -eu
P=$(cd "$CHECKS/.." && pwd -P); F="$P/hooks/face"
[ -f "$F/register.test.tsx" ] || { echo 'needs the plugin'"'"'s hooks/face/'; exit 77; }
fail() { echo "face-sections: $*" >&2; exit 1; }
grep -q 'list\.json' "$F/register.tsx" || fail 'the panel does not read .vid/face/list.json'
# the kit takes no module's own scroll, so that the link is wired to its scroll is read in the source
grep -q 'go: n => goTo(\$, PANE, n)' "$F/register.tsx" || fail "a link of the top row does not ask for its section's scroll"
grep -nE '<Text[^>]*color=("#|\{["'"'"']#|\{(LINE|FILL|TINT|INK))' "$F"/*.tsx && fail 'a Text takes a raw colour'
n=$(grep -c "^test('FB-5 A1 " "$F/register.test.tsx" || true); [ "$n" -ge 28 ] || fail "the panel has $n tests of FB-5 A1, not its 28"
command -v claude >/dev/null 2>&1 || { echo 'needs claude on PATH for its test kit'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME="$T/home"; export HOME; mkdir -p "$HOME"
set +e; ( cd "$P" && claude plugin test "$P" ) > "$T/out" 2>&1 < /dev/null; set -e
grep '^(fail) FB-5 A1 ' "$T/out" >&2 && fail 'a panel test of FB-5 A1 failed'
p=$(grep -c '^(pass) FB-5 A1 ' "$T/out" || true); [ "$p" = "$n" ] || fail "the kit passed $p of the $n tests of FB-5 A1"
echo "face-sections: $p passed"
