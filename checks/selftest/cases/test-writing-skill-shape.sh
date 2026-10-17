#!/bin/sh
# Purpose: selftest case — the test-writing skill (v0.9.8 spec 3.1, R1). Convicts unless
# skills/vid-test-writing/SKILL.md is an internal skill (its name, user-invocable: false) holding the writer's part
# — the test argument's six parts with the parseable `cases: ROW-<id> target=<case id> control=<case id>` line, the
# four anti-cheating rules, the techniques table of six rows as guidance (the writer picks and says why), the eight
# mistakes of the catalogue, setup, and the carried-over boundary rule, screen instrument and journey shapes (v0.9.8.1 R18: the small test files rule, the
# instrument a file per screen) (no
# reviewer's part: amendment 3 cut it); unless the test-author pass no longer holds the craft (no surface or journeys section,
# no boundary rule) yet keeps what the role receives and returns and names the skill; unless the test-author agent
# preloads it; and unless `brief.sh write --role test-author` quotes the boundary rule from the skill. Each check
# is run against the shipped tree and against a copy with one planted fault, which must be convicted. Plugin
# repository only (a project's checks/ has no skills/). Env: CHECKS.
set -eu
IFS='
'
R=$(cd "$CHECKS/.." && pwd)
[ -f "$R/skills/vid-build/SKILL.md" ] || exit 0
fail() { echo "test-writing-skill-shape: $*" >&2; exit 1; }
# shape <root>: one line per violation; returns 1 on any
shape() {
  S="$1/skills/vid-test-writing/SKILL.md"; P="$1/skills/vid-test-inventory/passes/test-author.md"; A="$1/agents/test-author.md"; bad=0
  v() { echo "$1"; bad=1; }
  [ -f "$S" ] || { echo "no skill at $S"; return 1; }
  awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on' "$S" > "$T/fm"
  grep -qx 'name: vid-test-writing' "$T/fm" || v 'the skill does not name itself vid-test-writing'
  grep -qx 'user-invocable: false' "$T/fm" || v 'the skill is not internal (user-invocable: false)'
  for h in '## The writer' '### The test argument' '### The anti-cheating rules' '### Techniques, as guidance' '### The mistakes catalogue' '### Setup' '### Carried over'; do
    grep -qxF "$h" "$S" || v "the skill lacks the heading '$h'"
  done
  for p in '- **promise:**' '- **wrong product:**' '- **given, when, then:**' '- **controls:**' '- **technique:**' '- **cases:**'; do
    grep -qF -- "$p" "$S" || v "the test argument lacks '$p'"
  done
  grep -qxF '      cases: ROW-<id> target=<case id> control=<case id>' "$S" || v 'the test argument lacks the parseable cases: line'
  for p in '**Before and after:**' '**One exact place:**' '**Decoys:**' '**Fresh values:**'; do grep -qF -- "$p" "$S" || v "the anti-cheating rules lack $p"; done
  grep -qF 'You pick, and the argument says which and why.' "$S" || v 'the techniques are not guidance the writer picks and explains'
  [ "$(awk '/^### Techniques, as guidance/ { on = 1; next } on && /^### / { exit } on && /^\| [a-z]/ && !/^\| When/' "$S" | grep -c .)" -eq 6 ] || v 'the techniques table does not hold six rows'
  [ "$(awk '/^### The mistakes catalogue/ { on = 1; next } on && /^### / { exit } on && /^- /' "$S" | grep -c .)" -eq 8 ] || v 'the mistakes catalogue does not hold eight entries'
  grep -qF '**The boundary rule (R6), verbatim:** *A promise is proved at the' "$S" || v 'the boundary rule is not carried over'
  grep -qF '#### The surface pass — one instrument, a file per screen' "$S" || v 'the screen instrument is not carried over'   # v0.9.8.1 (R18)
  grep -qxF '### Small test files (v0.9.8.1 R18)' "$S" || v 'the skill lacks the small test files rule'
  grep -qF 'A new test file holds one row, or up to 5 related rows' "$S" || v 'the small test files rule does not say one row, or up to 5'
  tr '\n' ' ' < "$S" | tr -s ' ' | grep -qF "Setup that two rows' tests both need belongs in the project's shared fixture code, never in another row's test file" || v 'the skill lacks the shared-setup line (R36)'
  grep -qF 'one instrument for every screen' "$S" && v 'the skill still asks for one instrument for every screen'
  # v0.9.8.1 (R21): the lesson's form, as vid-verify gives it, line for line
  VV="$1/skills/vid-verify/SKILL.md"
  if [ -f "$VV" ]; then for l in $(awk '/^## L-<n> · <UTC date> · from ROW-<id>$/ { on = 1 } on && /^```$/ { exit } on' "$VV"); do
    grep -qxF -- "$l" "$S" || v "the skill lacks the lesson form's line: $l"; done; fi
  grep -qF '#### The journeys pass — paid per transition' "$S" || v 'the journey shapes are not carried over'
  grep -qx '## The reviewer' "$S" && v 'the skill still holds the reviewer'"'"'s part'
  # the pass keeps what the role receives and returns, and none of the craft
  [ -f "$P" ] || { v "no pass at $P"; return 1; }
  grep -qE '^## The (surface|journeys) pass' "$P" && v 'the pass still holds the surface or journeys craft'
  grep -qF '**The boundary rule (R6), verbatim:**' "$P" && v 'the pass still holds the boundary rule'
  for p in 'receives:' 'must not receive:' 'returns, one line per row briefed, never fewer:' 'skills/vid-test-writing/SKILL.md'; do grep -qF -- "$p" "$P" || v "the pass lacks '$p'"; done
  awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on' "$A" | grep -qx '  - vid:vid-test-writing' || v 'the test-author agent does not preload vid:vid-test-writing'
  return $bad
}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
O=$(shape "$R") || fail "the shipped tree: $O"
# planted faults, each convicted
plant() { rm -rf "$T/p"; mkdir -p "$T/p/skills" "$T/p/agents"; cp -R "$R/skills/vid-test-writing" "$R/skills/vid-test-inventory" "$R/skills/vid-verify" "$T/p/skills/"; cp "$R/agents/test-author.md" "$T/p/agents/"; }
for f in '/^why: <the wrong product it let pass>$/d' '/^### Small test files/d' 's/^#### The surface pass — one instrument, a file per screen/#### The surface pass — ONE instrument for every screen/' 's/^      cases: ROW-<id> target=<case id> control=<case id>$/      cases: ROW-<id>/' 's/^- \*\*Decoys:\*\*/- Decoys:/' '/^| protects isolation /d' '/^- the row.s own example values ignored/d' '/^#### The journeys pass/d' 's/You pick, and the argument says which and why./Use the table./'; do
  plant; sed -i.bak "$f" "$T/p/skills/vid-test-writing/SKILL.md"
  shape "$T/p" > /dev/null && fail "a planted fault in the skill was not convicted: $f"
done
plant; printf '\n## The surface pass — ONE instrument for every screen\n' >> "$T/p/skills/vid-test-inventory/passes/test-author.md"
shape "$T/p" > /dev/null && fail 'the craft left in the pass was not convicted'
plant; sed -i.bak '/vid:vid-test-writing/d' "$T/p/agents/test-author.md"
shape "$T/p" > /dev/null && fail 'an agent without the preload was not convicted'
plant; printf '\n## The reviewer\n' >> "$T/p/skills/vid-test-writing/SKILL.md"
shape "$T/p" > /dev/null && fail 'a reviewer part left in the skill was not convicted'
# brief.sh quotes the boundary rule from the skill (the toy plugin's pass has none)
. "$CHECKS/selftest/fixtures/brief-write.sh"
bw_plugin; bw_repo "$T/repo"
grep -q 'boundary rule' "$P/skills/vid-test-inventory/passes/test-author.md" && fail 'the toy pass still holds the boundary rule'
OUT=$(CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role test-author --slice 1 --rows ROW-102 2>&1) || fail "the test-author brief was refused: $OUT"
BF=$(printf '%s\n' "$OUT" | sed -n 's/^ViD brief write: //p' | head -n 1)
grep -qF '*A promise is proved at the' "$BF" || fail 'the brief does not quote the boundary rule from the skill'
grep -qF "the skill: $P/skills/vid-test-writing/SKILL.md" "$BF" || fail 'the brief does not name the skill'
rm -f "$P/skills/vid-test-writing/SKILL.md"
CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role test-author --slice 1 --rows ROW-102 > /dev/null 2>&1 && fail 'a test-author brief was written without the skill'
exit 0
