#!/bin/sh
# Purpose: selftest case — the release tree stands alone: the release set (docs/PUBLISH-SET, 0.26.10.28.1) copied out holds every path DevAgent names, the one file of docs/ it needs
# among them, and nothing in devagent/ or checks/ points to docs/ past that, or to a machine or a scratch folder. 0.26.10.28.5 (R4): the whole set is scanned for internal text, by the
# exact lists below, with every exemption named by file and line; a name from the owner's own list (VID_RELEASE_NAMES) fails it; planted lines prove each list, and controls that it
# leaves the plugin's own version notes and a fixture's date alone; the set holds no viewer/page/screenshots. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..; [ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "release-set: $*" >&2; exit 1; }
# 0.26.10.28.1 (stage 9 R3, S3): the set is docs/PUBLISH-SET's, one path a line, `#` lines and blank ones skipped — one list
[ -f "$R/docs/PUBLISH-SET" ] || fail 'no docs/PUBLISH-SET'
SET=$(grep -v '^#' "$R/docs/PUBLISH-SET" | grep -v '^[[:space:]]*$'); [ -n "$SET" ] || fail 'docs/PUBLISH-SET names no path'
printf '%s\n' "$SET" | grep -qxF docs/PUBLISH-SET || fail 'docs/PUBLISH-SET does not list itself'
printf '%s\n' "$SET" | grep -qxF devagent || fail 'docs/PUBLISH-SET leaves out devagent'
# one path a line, a space inside a name kept (the viewer's page)
mkdir -p "$T/t/docs"; printf '%s\n' "$SET" > "$T/set"; while IFS= read -r p; do [ -e "$R/$p" ] || fail "the set names $p, which is not here"; mkdir -p "$(dirname "$T/t/$p")"; cp -R "$R/$p" "$T/t/$p"; done < "$T/set"
# 0.26.10.28.5 (R4): the screenshots are the design pack's, which the page does not use; they leave the set
[ ! -e "$T/t/viewer/page/screenshots" ] || fail 'the set holds viewer/page/screenshots'
[ -f "$T/t/viewer/page/ViD Viewer v4.dc.html" ] && [ -f "$T/t/viewer/view.sh" ] || fail "the set leaves out the viewer's page or view.sh"
# every path DevAgent names, relative to its file for ../, to the release tree otherwise
find "$T/t/devagent" -type f | while IFS= read -r f; do dir=$(dirname "$f"); grep -oE '(\.\./)*(agents|skills|devagent|docs|hooks|templates|dev-manager|test-manager|checks/selftest)/[A-Za-z0-9_./-]+\.(md|sh)' "$f" 2>/dev/null | sort -u | while IFS= read -r p; do case $p in ../*|dev-manager/*|test-manager/*) t=$dir/$p; [ -e "$t" ] || t=$T/t/devagent/$p ;; *) t=$T/t/$p ;; esac; [ -e "$t" ] || echo "${f#"$T"/t/} names $p, not in the release tree" >> "$T/bad"; done; done
[ ! -f "$T/bad" ] || { cat "$T/bad" >&2; fail 'a path outside the release set'; }
# by each path, not each line. docs/PUBLISH-SET ships, listing itself (devagent-name reads it, 0.26.10.28.8); docs/specs and docs/notes.md are a project's own; view-page-diff skips when its docs/ folders are absent
B=$(grep -rhoE 'docs/[A-Za-z0-9_.-]+' "$R/devagent" "$R/checks" --exclude=release-set.sh --exclude=view-page-diff.sh | grep -vxE 'docs/(RESULTS-FORMAT\.md|PUBLISH-SET|specs\.?|notes\.md)' || true); [ -z "$B" ] || fail "points into docs/: $B"
B=$(grep -rnE '/Users/|(^|[ "=(`])/home/|/private/tmp|scratchpad' "$R/devagent" "$R/checks" --exclude=release-set.sh || true); [ -z "$B" ] || fail "a machine path: $B"
# 0.26.10.28.5 (R4): the whole set, scanned. Always on, the exact lists: a decision cited by number (the queue's own output form "the first
# decision <n> of <m>" and ViD's comment form "vid: decision <commit>" aside); a review-round phrase; a field-run phrase, a project's version tag and a field finding's id among them; an owner-quotation phrase, a ruling cited by its date or its number among them
DEC='[Dd]ecisions? [0-9]+([^0-9.]|\.([^0-9]|$)|$)'
REV='[Rr]eviews? [0-9]|[Rr]eview rounds?|[Rr]ounds? [0-9]+ findings?|[Rr]ounds? [0-9]+, findings? [0-9]|[Rr]eview findings? [0-9]|[(,;] *rounds? [0-9]+(, [0-9]+)*\)|[Cc]odex finding'
FLD='[Ff]ield[ -]runs?|v[0-9]+\.[0-9]+ [A-Z]-[0-9]|v[0-9]+\.[0-9]+ (run|re-grade)|v[0-9]+\.[0-9]+/v[0-9]+\.[0-9]+|[Tt]rials? [0-9]|v[0-9][0-9.]*[a-z]?,? [GH]-[0-9]|[a-z]+-v[0-9]+ F[0-9]|[0-9]+\.[0-9.]+ trial|found by the trial|grade finding #[0-9]|v[0-9]+\.[0-9]+ (rounds|grader)|[Tt]he live project|[Aa] live project'"'"'?s|the trial'"'"'s|replay found'
OWN="the owner's words:|[Oo]wner'?s? rulings?,? (of )?20[0-9][0-9]-|[Oo]wner rulings? [A-Z]?[0-9]|[;(] *(the )?owner,? 20[0-9][0-9]-|[Oo]wner agreed \\(20|the owner said[:,]? \"|owner chose:? \"|owner: \""
# the patterns reach awk by its environment, which leaves their backslashes as they are. The exemptions, each a file and the words of its one line: a line whose wording is behaviour or test data. An exemption whose words name no line
# of its file, or more than one, fails, so none stands for lines it was not written for; a file the tree lacks (a scoped copy) has none to cover. This file's own lists are its own.
# vid-verify's line is frozen (0.26.10.28.4's freeze of skills/vid-verify), so it is named here rather than changed.
cat > "$T/exempt" <<'X'
checks/queue.sh|amend ${r%-T[0-9]*} in the owner's words: $*
checks/writer.sh|the three forms the writer rewrites (owner chose "…", owner: "…", A: "…"; )
checks/writer.sh|rewrites and nothing else (owner chose "…" one or more, owner: "…", an answer's own A: "…"; )
checks/writer.sh|(match(l, /owner chose:? "[^"]*"|owner: "[^"]*"|A: "[^"]*"; /)
checks/selftest/cases/tw-check-rules.sh|the cap is ten, owner: "ten is plenty"
checks/selftest/cases/tw-check-rules.sh|refused 'an owner quote — owner: "ten and no more"'
checks/selftest/cases/tw-check-rules.sh|refused 'an owner quote — owner chose "ten"'
checks/selftest/cases/tw-parity.sh|-e 's/owner: "[^"]*"/confirmed by the owner/g'
checks/selftest/cases/tw-check-rules.sh|(owner chose "Ten" and "No more")
checks/selftest/cases/scorecard-counted.sh|new ViD decisions 1)
skills/vid-create-prd/selftest/fixtures/engineering-choice/PRD.md|the owner said "you pick"
skills/vid-verify/SKILL.md|a v0.7 grader silently skipped 1 of 47
docs/tutorials/local-auto-lab/ten-requirements/answers.md|Its decisions 5 (flood limit on confirmation emails)
checks/selftest/cases/tutorials-scrub.sh|internal decision	As decision 12 says.
X
# the deny-list's allowed lines: the founder's attribution and the official repository's address, named without a name
cat > "$T/allowed" <<'X'
README.md|was founded by 
NOTICE|was founded by 
README.md|Official repository: [
.claude-plugin/plugin.json|"repository": "https://github.com/
X
for x in exempt allowed; do while IFS='|' read -r f w; do [ -f "$T/t/$f" ] || continue; n=$(grep -cF -- "$w" "$T/t/$f" 2>/dev/null || true); [ "${n:-0}" = 1 ] || fail "the $x line of $f, \"$w\", names ${n:-0} lines"; done < "$T/$x"; done
# scan <tree>: every line the lists or the names convict, as path:line: words; none prints nothing
scan() { ( cd "$1"; { grep -rnIE "$DEC|$REV|$FLD|$OWN" . --exclude=release-set.sh || true; } | A="$DEC|$REV|$FLD|$OWN" awk -v X="$T/exempt" '
    BEGIN { A = ENVIRON["A"]; while ((getline l < X) > 0) { i = index(l, "|"); E[++n] = "./" substr(l, 1, i - 1); W[n] = substr(l, i + 1) } }
    { p = $0; sub(/:.*/, "", p); r = substr($0, length(p) + 2); k = r; sub(/:.*/, "", k); t = substr(r, length(k) + 2)
      for (j = 1; j <= n; j++) if (E[j] == p && index(t, W[j])) next
      u = t; gsub(/first decision [0-9]+ of [0-9]+/, "", u); gsub(/vid: decision [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/, "", u); if (u ~ A) print }'
  # a note wrapped across two lines: each line joined to the next, its comment mark taken off, convicts where neither line alone does. awk only
  # joins (the last 60 characters of one line and the first 60 of the next, the queue's output form taken out first); grep finds the joins the lists convict; awk then drops those a
  # line convicts alone, and the exempt ones
  { grep -rlI --null '' . --exclude=release-set.sh < /dev/null || true; } | xargs -0 awk 'FNR == 1 { q = ""; pl = "" }
    { u = $0; sub(/^[ \t]*(#|>|\/\/)?[ \t]*/, "", u); if (index(u, "first decision")) gsub(/first decision [0-9]+ of [0-9]+/, "", u); if (index(u, "vid: decision")) gsub(/vid: decision [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/, "", u); if (q != "") printf "%s\001%d\001%s %s\001%s\001%s\001%s\001%s\n", FILENAME, FNR - 1, substr(q, length(q) > 60 ? length(q) - 59 : 1), substr(u, 1, 60), q, u, pl, $0; q = u; pl = $0 }' |
    { grep -E "$DEC|$REV|$FLD|$OWN" || true; } | A="$DEC|$REV|$FLD|$OWN" awk -F '\001' -v X="$T/exempt" '
    BEGIN { A = ENVIRON["A"]; while ((getline l < X) > 0) { i = index(l, "|"); E[++n] = "./" substr(l, 1, i - 1); W[n] = substr(l, i + 1) } }
    { j = $3; q = $4; u = $5
      if (j !~ A || q ~ A || u ~ A) next; for (k = 1; k <= n; k++) if (E[k] == $1 && (index($6, W[k]) || index($7, W[k]))) next
      print $1 ":" $2 ": (wrapped) " $6 " / " $7 }'
  if [ -n "${VID_RELEASE_NAMES:-}" ]; then [ -r "$VID_RELEASE_NAMES" ] || { echo "a name: VID_RELEASE_NAMES names no readable file: $VID_RELEASE_NAMES"; return; }; grep -v '^[[:space:]]*$' "$VID_RELEASE_NAMES" > "$T/names" || true
    [ ! -s "$T/names" ] || { grep -rnIiF -f "$T/names" . --exclude=release-set.sh || true; } | awk -v X="$T/allowed" '
      BEGIN { while ((getline l < X) > 0) { i = index(l, "|"); E[++n] = "./" substr(l, 1, i - 1); W[n] = substr(l, i + 1) } }
      { p = $0; sub(/:.*/, "", p); for (j = 1; j <= n; j++) if (E[j] == p && index($0, W[j])) next; print "a name: " $0 }'; fi ); }
B=$(scan "$T/t"); [ -z "$B" ] || fail "internal text in the published set: $B"
if [ -z "${VID_RELEASE_SET_COPY:-}" ]; then
  # the proofs: each planted line fails the scan, and each control passes it; the names from a made-up list the case writes
  printf 'Quillfeather Labs\nbramblewick\n' > "$T/made-up"; B=$(VID_RELEASE_NAMES=$T/made-up scan "$T/t"); [ -z "$B" ] || fail "the set fails with a made-up name list: $B"
  # each plant alone in a one-file tree, the same scan: the whole set was scanned clean above
  mkdir "$T/p"; P=$T/p/plant.md
  plant() { printf '%s\n' "$2" > "$P"; B=$(VID_RELEASE_NAMES=$T/made-up scan "$T/p")
    if [ "$1" = fails ]; then [ -n "$B" ] || fail "a planted \"$2\" passes the scan"; else [ -z "$B" ] || fail "the control \"$2\" fails the scan: $B"; fi; }
  plant fails 'built for the BrambleWick team'; plant fails 'as decision 12 has it'; plant fails 'the lock goes first (review 2)'
  plant fails 'a server error is never shown (field runs v0.6/v0.7)'; plant fails 'a corpus of the product'"'"'s own (v0.8 G-02)'; plant fails "door: amend it in the owner's words: keep the cap"
  plant fails '# (round 1, finding 3): no notice'; plant fails 'kept (v0.9.6.1 spec 3.3, R3, review finding 5)'; plant fails '# --- claim (v0.9.2 3.6, round 4) ---'
  plant fails 'undefined (evidence: quill-v3 F7)'; plant fails 'unspecified (Codex finding 1)'; plant fails '# v0.26.10.9 (R1, found by the trial): a note'; plant fails 'the processes the 0.26.10.9 trial found'
  plant fails "$(printf '# removed once that clearer is gone (review\n# 2: never for its age)')"; plant fails "$(printf 'before the first round. A field\n  run agreed its bar')"
  plant fails '# v0.9.8.1 (R11, F-10; the live project'"'"'s A-274)'; plant fails 'the 2026-09-21 replay found the court aborting'
  B=$(VID_RELEASE_NAMES=$T/no-such-list scan "$T/p"); [ -n "$B" ] || fail 'a VID_RELEASE_NAMES that names no file passes the scan'
  plant passes 'vid: decision 48515924be63eab070523d824e849c2f2915fc0a'; plant passes '| G-14 | low | a grade finding of the product |'; plant fails '(v0.8.1d, G-08): a field finding'
  plant passes "$(printf -- '- numbers only, the defaults unless the owner\n  said otherwise')"; plant passes "# the round's refusal key, read once per round"; plant passes '# v0.26.10.28.5 (R4): a version note of the plugin'; plant passes "printf 'flag at=2026-11-10T09:00:00Z\\n'"; plant passes 'accepted at the first decision 2 of 2'
fi
# the same case, run once from the tree that set's own list copied: the installed plugin's self-test reads its PUBLISH-SET there
[ -n "${VID_RELEASE_SET_COPY:-}" ] || VID_RELEASE_SET_COPY=1 CHECKS=$T/t/checks sh "$T/t/checks/selftest/cases/release-set.sh" || fail 'the case fails in the tree its own set copied'
exit 0
