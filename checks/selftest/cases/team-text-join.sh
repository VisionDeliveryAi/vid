#!/bin/sh
# Purpose: selftest case — the text for the team and the reader hold the same ids (FB-3 A3), so the rules and the words change together.
# In GitHub manual: each beginning that makes an id no result report (results.sh rlist) is named in `results.sh team`. In GitHub auto: each
# id the form takes from the dev side (form's own line, GitHub manual's step- ones apart) is in the text. And back, in each mode: each id the
# text gives, its places filled in, is a report the form knows, refused for its missing branch alone. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "team-text-join: $*" >&2; exit 1; }
mkdir -p "$T/p/.vid/plan" "$T/p/.vid/tw/out"; cd "$T/p"; git init -q; git init -q --bare .vid/code; printf 'repo: owner/code\nlabels-prefix: vid:\n' > .vid/tw/settings
printf '# Step ticket S02\n\n## Header\n\n- kind: step\n\n## Rows\n\n> ROW-001 | behavior | a promise\n\n## Engines\n\n- primary: alpha\n' > .vid/tw/out/issue-7.md
mode() { printf 'setup-answered key=github-mode value="%s" words="the toy" at=2026-11-24T09:00:00Z\n' "$1" > .vid/plan/setup; sh "$CHECKS/results.sh" team > "$T/$1" 2> "$T/err" || { cat "$T/err" >&2; fail "no text in GitHub $1"; }; [ -s "$T/$1" ] || fail "an empty text in GitHub $1"; }
# back: the ids of a text, each with its places filled in
back() { grep -oE '`(vid-results/)?[a-z]+-[a-z0-9-]*<[^`]*`' "$T/$1" | tr -d '`' | sed 's|^vid-results/||' | grep -v '[.]xml$' | sort -u > "$T/ids.$1"; [ "$(grep -c . "$T/ids.$1")" -ge 4 ] || fail "too few ids found in the text of GitHub $1"
  while IFS= read -r i; do x=$(printf '%s\n' "$i" | sed 's/<commit12>/0123456789ab/g; s/<head12>/0123456789ab/g; s/<chunk>/p1c1/g; s/<[^>]*>/7/g'); o=$(sh "$CHECKS/results.sh" check "$x" --ticket 7 2>&1 || true)
    [ "$o" = "refused no branch vid-results/$x" ] || fail "in GitHub $1 the text gives $i, which the form does not know: $o"; done < "$T/ids.$1"; }
mode manual; back manual
w=$(sed -n "s/.*grep -vE '^(\([a-z|]*\))-'.*/\1/p" "$CHECKS/results.sh" | head -n 1); [ -n "$w" ] || fail 'the beginnings that are no result report were not found in results.sh'
for x in $(printf %s "$w" | tr '|' ' '); do grep -qF -e "\`$x-\`" "$T/manual" || fail "in GitHub manual the text does not name the beginning $x-"; done
mode auto; grep -qF -e 'stopped-<k>' "$T/auto" || fail 'in GitHub auto the text has no stopped report'; sed 's/`stopped-<k>`//' "$T/auto" > "$T/a2" && mv "$T/a2" "$T/auto"; back auto
l=$(grep -E '^ *form\(\)|case \$1 in red-\*\) FN=' "$CHECKS/results.sh" | grep -oE 'case \$1 in red-\*\) FN=.*' | head -n 1); [ -n "$l" ] || fail "form's own line was not found in results.sh"
n=0; for x in $(printf '%s\n' "$l" | grep -oE '(^case \$1 in |;; |\|)[a-z]+-([a-z]+-)?(\[0-9\])?\*' | grep -oE '[a-z]+-([a-z]+-)?(\[0-9\])?\*$' | sed 's/\[0-9\]//; s/\*$//' | sort -u); do case $x in *step-) continue ;; esac; n=$((n + 1)); grep -qF -e "\`$x<" "$T/auto" || fail "in GitHub auto the text gives no id beginning $x"; done
[ "$n" -ge 7 ] || fail "only $n ids were found in form's own line"
echo 'team-text-join: ok'
