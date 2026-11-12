#!/bin/sh
# Purpose: selftest case — citations by heading, held (0.26.10.28.4, 9.3 R6, M8). No .md file of skills/, agents/ or devagent/ cites another by line
# number, but the grader's two (devagent/agents/grader.md, frozen), and those two still hold their text: the "Denominator attacks" bullet and the
# decision-mining sweep of skills/vid-grade/SKILL.md, by their first and last lines (this case takes over 9.2's pinning case). Every
# citation by its first words, `<file> § "<words>"` (TM for skills/vid-test-manager/SKILL.md), is looked up: the file is there and a heading, bullet
# or paragraph of it begins with those words, or a bold name holds them; so is each in the older form, a file by name then its words quoted, found by
# its name under skills/, agents/, devagent/ or templates/. A planted rename of a cited heading, and of a bullet cited in the older form, shows it red. Skips where skills/ is
# absent (a project's layout), exit 77. It takes over 9.2's grader-citation.sh, with its last lines too. Env: CHECKS.
set -eu
R=$CHECKS/..; [ -d "$R/skills" ] && [ -d "$R/devagent" ] || { echo 'needs skills/ and devagent/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "citations: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# lines <root>: every citation by line number, as file:line: text; a citation split over a line break, the line where it starts
lines() { ( cd "$1" && find skills agents devagent -name '*.md' | sort | while IFS= read -r f; do
    grep -nE '\.(md|sh)(:|, lines? )[0-9]+|(^|[^A-Za-z])lines? [0-9]+([-–][0-9]+)?|\(TM [0-9]|[0-9]+[–-][0-9]+ and [0-9]+[–-][0-9]+' "$f" | sed "s|^|$f:|" || true
    awk -v f="$f" 'p && /^[0-9]/ { print f ":" n ": " q } { p = ($0 ~ /(^|[^A-Za-z])lines?,?$/); n = NR; q = $0 }' "$f"; done ); }
lines "$R" > "$T/ln"; grep -v '^devagent/agents/grader.md:6: ' "$T/ln" > "$T/out" || true; [ ! -s "$T/out" ] || fail 'a citation by line number:'
grep -q '^devagent/agents/grader.md:6: ' "$T/ln" || fail "the grader's two citations are not where they were"
# the grader's two hold their text, by first and last lines: the ranges as grader.md writes them, `lines <a>–<b> and <c>–<d>` over a line break
set -- $(tr '\n' ' ' < "$R/devagent/agents/grader.md" | sed -n 's/.*vid-grade\/SKILL\.md`, lines *\([0-9][0-9]*\)–\([0-9][0-9]*\) and \([0-9][0-9]*\)–\([0-9][0-9]*\).*/\1 \2 \3 \4/p')
[ $# -eq 4 ] || fail "grader.md no longer cites two ranges of skills/vid-grade/SKILL.md"
G=$R/skills/vid-grade/SKILL.md; ln() { sed -n "${1}p" "$G"; }
[ "$(ln "$1")" = '- **Denominator attacks** — a standing instruction in every brief: find one' ] && [ "$(ln "$2")" = '  finding is a rule, not a bug — /vid fix forks its protocol on this tag.' ] || fail "the grader's lines $1–$2 no longer hold the Denominator attacks bullet: $(ln "$1") … $(ln "$2")"
[ "$(ln "$3")" = '- **ViD repos additionally get the decision-mining sweep** — "what choices' ] && [ "$(ln "$4")" = '  finding. The sweep includes the **court-edit check** (CLAUDE.md court' ] || fail "the grader's lines $3–$4 no longer hold the decision-mining sweep: $(ln "$3") … $(ln "$4")"
# heads <root>: every citation by first words, as source TAB file TAB words, each looked up
heads() { ( cd "$1" && find skills agents devagent -name '*.md' | sort | while IFS= read -r f; do awk -v f="$f" '{ s = $0
      while (match(s, /(TM|[A-Za-z0-9_.\/-]+\.md) § "[^"]+"/)) { m = substr(s, RSTART, RLENGTH); t = m; sub(/ § ".*/, "", t); w = m; sub(/^[^"]*"/, "", w); sub(/"$/, "", w)
        if (t == "TM") t = "skills/vid-test-manager/SKILL.md"; print f ":" NR "\t" t "\t" w; s = substr(s, RSTART + RLENGTH)
        while (match(s, /^, § "[^"]+"/)) { w = substr(s, 1, RLENGTH); sub(/^, § "/, "", w); sub(/"$/, "", w); print f ":" NR "\t" t "\t" w; s = substr(s, RLENGTH + 1) } }
      # the older form, a file by name then its words quoted, as GRADING.md shared rule ("…" or DEPLOYMENT.md "…", found by its name
      s = $0; while (match(s, /[A-Za-z0-9_.-]+\.md`?([^"(]{0,40}\("|`? ")[A-Z][^"]+"/)) { m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        if (m ~ / § "/) continue; t = m; sub(/\.md.*/, ".md", t); w = m; sub(/^[^"]*"/, "", w); sub(/"$/, "", w); print f ":" NR "\t@" t "\t" w } }' "$f"; done ); }
look() { : > "$T/miss"; heads "$1" > "$T/hd"; while IFS='	' read -r src t w; do F=$1/$t
    case $t in @*) F=$( cd "$1" && find skills agents devagent templates -name "${t#@}" 2>/dev/null | head -n 2 ); [ "$(printf '%s\n' "$F" | grep -c .)" = 1 ] || { echo "$src: no one file named ${t#@}" >> "$T/miss"; continue; }; t=$F; F=$1/$F ;; esac
    [ -f "$F" ] || { echo "$src: no file $t" >> "$T/miss"; continue; }
    awk -v w="$w" '{ l = $0; sub(/^[ \t]*(#+[ \t]+|-[ \t]+)?(\*\*)?/, "", l); if (index(l, w) == 1 || index($0, "**" w)) { f = 1; exit } } END { exit !f }' "$F" || echo "$src: no \"$w\" in $t" >> "$T/miss"; done < "$T/hd"; }
look "$R"; [ "$(grep -c '	@' "$T/hd")" -ge 3 ] || fail "only $(grep -c '	@' "$T/hd") citations in the older form found"; [ "$(grep -c . "$T/hd")" -ge 20 ] || fail "only $(grep -c . "$T/hd") citations by first words found"; cp "$T/miss" "$T/out"; [ ! -s "$T/miss" ] || fail 'a citation that finds nothing:'
# a planted rename of a cited heading is red
mkdir -p "$T/c/skills/vid-test-manager" "$T/c/devagent/test-manager" "$T/c/agents"; cp "$R/devagent/test-manager/SKILL.md" "$T/c/devagent/test-manager/"
sed 's/^## The one rule$/## The single rule/' "$R/skills/vid-test-manager/SKILL.md" > "$T/c/skills/vid-test-manager/SKILL.md"; ! cmp -s "$T/c/skills/vid-test-manager/SKILL.md" "$R/skills/vid-test-manager/SKILL.md" || fail 'the plant changed nothing'
mkdir -p "$T/c/skills/vid-verify" "$T/c/skills/vid-grade"; cp "$R/skills/vid-verify/SKILL.md" "$T/c/skills/vid-verify/"; sed 's/What every brief withholds/What a brief withholds/' "$R/skills/vid-grade/GRADING.md" > "$T/c/skills/vid-grade/GRADING.md"
look "$T/c"; grep -q 'no "The one rule" in skills/vid-test-manager/SKILL.md' "$T/miss" || fail 'a planted rename of a cited heading was not caught'
grep -q 'no "What every brief withholds" in skills/vid-grade/GRADING.md' "$T/miss" || fail 'a planted rename of a bullet cited in the older form was not caught'
echo 'citations: ok'
