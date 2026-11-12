#!/bin/sh
# Purpose: selftest case — the tutorials hold nothing internal (0.26.10.28.6, R7; the publish scrub of stage 1): in every shipped file of the
# tutorials folder, fixtures included, no machine or scratch path, no repository address on GitHub but ViD's own and placeholders, no internal
# version of ViD (a PRD's or inventory's `grammar:` line, the form ViD writes, aside), no review note, no walk log or plan left out of the set,
# no session or worktree name, no numbered internal decision, nothing quoted from the owner or cited to the owner by date; and, where the
# release session names its projects in the file VID_RELEASE_NAMES points to, none of those names. JobDigest, the practice product, stays.
# Each pattern is proved to fire on a planted line. Skips where the tutorials folder and the release set are both absent (a project's
# layout); ViD's own tree, which has the set, must hold the tutorials. Env: CHECKS.
set -eu
fail() { echo "tutorials-scrub: $*" >&2; exit 1; }
R=$CHECKS/..; D=$R/docs; TU=$D/tutorials
if [ ! -d "$TU" ]; then [ -f "$D/PUBLISH-SET" ] || { echo 'needs the tutorials folder'; exit 77; }; fail 'the release set is here and the tutorials folder is not'; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# one pattern a line, a name, a tab, an extended regex; the literal paths are bracketed so that release-set.sh's own scan of checks/ passes
cat > "$T/pats" <<'P'
machine path	/U[s]ers/|(^|[ "=(`])/h[o]me/|/priv[a]te/(tmp|var)|scratch[p]ad|\.claude/w[o]rktrees|side-sess[i]on
repository address	github\.com[:/]([^V$<]|V[^i]|Vi[^s]|Vis[^i])
internal version	(^|[^0-9.=])v?0\.(7|8|9|26)\.[0-9]+
review note	[Cc]odex|(build|spec|adversarial|fresh-context) review|review (round|note)s?|(^|[^a-z])review [0-9]|[0-9]+ findings?, [0-9]+ distinct
walk log	[Ww]alk[ -][Ll]og|WALK-LOG|LOCAL-AUTO-PLAN|docs[/]reviews
session name	claude/[a-z]+-[a-z]+-[0-9a-f]{6}|(^|[^a-z0-9-])[a-z]+-[a-z]+-[0-9a-f]{6}([^0-9a-z]|$)|local_[0-9a-f]{8}-|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
internal decision	[Dd]ecision [0-9]{1,4}([^0-9a-f]|$)
owner quoted	[Tt]he owner( said| asked| ruled| wrote| confirmed)?:? *["]|owner( ruling)?, 20[0-9][0-9]-[01][0-9]
P
scan() { bad=0; while IFS='	' read -r name re; do
    grep -rnE "$re" "$1" 2>/dev/null | grep -vE '^[^:]+:[0-9]+:grammar: ' > "$T/hit" || true
    [ ! -s "$T/hit" ] || { echo "$name: $(head -n 1 "$T/hit" | sed "s|^$1/||")"; bad=1; }
  done < "$T/pats"
  if [ -n "${VID_RELEASE_NAMES:-}" ]; then grep -rniFf "$VID_RELEASE_NAMES" "$1" > "$T/hit" 2>/dev/null || true; [ ! -s "$T/hit" ] || { echo "a project's name: $(head -n 1 "$T/hit" | sed "s|^$1/||")"; bad=1; }; fi
  return $bad; }
scan "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'a shipped tutorial file holds something internal'; }
grep -rqi jobdigest "$TU" || fail 'the practice product JobDigest is gone from the tutorials'
# each pattern fires: one planted line a pattern, in a copy, must be found under that pattern's name
while IFS='	' read -r pn pl; do rm -rf "$T/c"; cp -R "$TU" "$T/c"; printf '%s\n' "$pl" >> "$T/c/START-HERE.md"
  if scan "$T/c" > "$T/out"; then fail "a planted $pn passed: $pl"; fi; grep -q "^$pn: " "$T/out" || { cat "$T/out" >&2; fail "a planted $pn was found under another name"; }
done <<P
machine path	Open $(printf '/%s/' Users)someone/Work/x.
repository address	Clone https://github.com/someone/jobdigest-lab.
repository address	Clone https://github.com/Victor-x/jobdigest.
internal version	Built with ViD 0.9.0.
review note	The section was reviewed by Codex.
walk log	See the walk log for the times.
session name	Made on claude/brave-turing-1a2b3c.
internal decision	As decision 12 says.
owner quoted	The owner said: "ship it".
P
rm -rf "$T/c"; cp -R "$TU" "$T/c"; printf 'grammar: 0.9.4\n' >> "$T/c/jobdigest-lab/spec/PRD.md"; printf 'Clone https://github.com/VisionDeliveryAi/vid and https://github.com/$ACCOUNT/jobdigest.\n' >> "$T/c/START-HERE.md"
scan "$T/c" > "$T/out" || { cat "$T/out" >&2; fail 'a grammar line or a placeholder address was taken for internal'; }
printf 'Someproject\n' > "$T/names"; printf 'Built for someproject.\n' >> "$T/c/START-HERE.md"
if VID_RELEASE_NAMES=$T/names scan "$T/c" > "$T/out"; then fail 'a planted project name passed'; fi; grep -q "^a project's name: " "$T/out" || fail 'a planted project name was found under another name'
echo 'tutorials-scrub: ok'
