#!/bin/sh
# Purpose: selftest case — skill and template passages no other case reads, each by its operative words, the file's lines
# joined. vid-test-inventory's append mode: its delta may be an incorporation's decision lines, with the REQs each serves, and
# where each is derived (IR I4); an incorporation's delta: rows from REQs, never a decision id, `origin: incorporation <date>
# D-NNN` (a rule row's REQ after it), a line that brings no row named `left: DECISIONS.md`, the replaced lines carried and the
# rows on their REQs checked against the replacing rule, a CHANGED row amended or named `left: INVENTORY.md`, and the buckets
# ratified on their own. vid-stage's one table: the counts per stage hold the rows provable only at a later stage and a
# re-cut's moved rows (0.26.11.1.4, R9). vid-help's /vid:vid-next row: it does the moves the owner names and writes the plan page
# (GM-2 T10). The DECISIONS.md template: labels and replaced-by marks the one edit allowed, the mark's form and place, the
# named lines win, the mark keeps its ids (IR I2). The INVENTORY.md template: the `origin: incorporation` form (IR I4). Skips
# where skills/ and templates/ are absent (a project's layout). Env: CHECKS.
set -eu
B=$CHECKS/..; TI=$B/skills/vid-test-inventory/SKILL.md; VS=$B/skills/vid-stage/SKILL.md; VH=$B/skills/vid-help/SKILL.md
TD=$B/templates/DECISIONS.md; TV=$B/templates/INVENTORY.md
[ -f "$TI" ] && [ -f "$VS" ] && [ -f "$VH" ] && [ -f "$TD" ] && [ -f "$TV" ] || { echo 'needs skills/ and templates/'; exit 77; }
fail() { echo "skill-template-passages: $*" >&2; exit 1; }
# inx <name> <text> <words>…: each set of words in the text; has <file> <words>…: in the file, its lines joined and spaces squeezed
inx() { n=$1; J=$2; shift 2; for w; do printf '%s' "$J" | grep -qF -- "$w" || fail "$n lacks: $w"; done; }
has() { f=$1; shift; inx "${f#"$B"/}" "$(tr '\n' ' ' < "$f" | tr -s ' ')" "$@"; }
has "$TI" "or an incorporation's decision lines, with the REQs each one serves" \
  'in develop and GitHub manual after those lines have landed, in GitHub auto in the working tree before its draft' \
  "**An incorporation's delta** (IR I4) derives as every delta does" \
  "each new row's \`derived-from\` names the REQs the decision line serves, never a decision id" \
  '`origin: incorporation <YYYY-MM-DD> D-NNN` (the incorporation' \
  '`origin: incorporation <YYYY-MM-DD> D-NNN REQ-NNN`' \
  'brings no row, and the incorporation'"'"'s map says so: `left: DECISIONS.md | D-NNN | <why>`' \
  'The delta also carries each line the incorporation marks `replaced-by:`, with the REQs that line serves' \
  'every existing row derived from those REQs is checked against the replacing rule' \
  'one resting on a replaced line among them), is amended in the same amendment, or named in the map by `left: INVENTORY.md | <row id> | <why>`' \
  'a yes to the map never stands for their ratification'
has "$VS" 'the counts per stage (its rows provable only at a later stage among them, and on a re-cut its moved rows)'
R=$(grep '^| \*\*/vid:vid-next\*\* |' "$VH") || fail 'vid-help has no /vid:vid-next row'
inx "vid-help's /vid:vid-next row" "$R" 'then it does the moves the owner names in the call, in your words' 'and writes the plan page'
has "$TD" 'Append-only, except labels and replaced-by marks.' \
  'is marked, and only marked: `| replaced-by: D-NNN[, D-MMM]` in its rule part, right before ` | why:`' \
  'Where the lines differ, the named lines win' 'wherever it is quoted the lines it names follow it' \
  'or add a D-id to the mark it has, keeping the ids already there, and nothing else; that is the one edit this file allows'
has "$TV" '`| origin: incorporation <date> D-NNN` — the decision line an incorporation (/vid:vid-incorporate) added; a rule row names its REQs after it.'
echo 'skill-template-passages: ok'
