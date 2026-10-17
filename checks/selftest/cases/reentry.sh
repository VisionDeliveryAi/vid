#!/bin/sh
# Purpose: selftest case — the re-entry page (v0.9.7.0.6 spec 3.4, R8; §6
# C-1, C-3). Needs the plugin's hooks/ beside checks/, so in a project it
# proves nothing and passes. Convicts unless hooks.json registers
# hooks/reentry.sh for SessionStart with the matcher `compact|resume`;
# `source=compact` in a run that is `active` prints the page — the header
# line, the re-read list (develop's skill, vid-test-manager's,
# vid-verify's and, from v0.9.7.0.7 3.1, vid-build's, by absolute path), the watcher's line and the `resume`
# lines — and writes the session's debt with one `file` line per path;
# `resume` prints it too (v0.9.8.1 R31: writing no debt), and with fix the open verb it lists vid-fix's
# skill; `startup`, `clear`, `run: stopped` and no .vid/ print nothing; it
# exits 0 on unparseable input; and with a project checks/records-version of
# 8 the hook never calls `alive` (an older observe.sh would tick and write):
# .vid/observer.state is unchanged. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=reentry
. "$CHECKS/selftest/fixtures/reread-lib.sh"
tr -d ' \n' < "$HD/hooks.json" | grep -q '{"matcher":"compact|resume","hooks":\[{"type":"command","command":"sh\\"${CLAUDE_PLUGIN_ROOT}/hooks/reentry.sh\\""' || fail 'hooks.json does not register reentry.sh for compact|resume'
page compact
head -n 1 "$T/page.out" | grep -qxF 'ViD re-entry — your memory of this run was compacted or resumed; continue from these records' || fail 'the header line is not first'
grep -qxF 'Re-read these in full now, with the Read tool:' "$T/page.out" || fail 'no re-read heading'
for f in "$DV" "$TM" "$VV" "$VB"; do grep -qxF -- "- $f" "$T/page.out" || fail "the page does not list $f"; done
grep -q "^watcher: " "$T/page.out" || fail "the page has no watcher line"
grep -q '^resume: run: active' "$T/page.out" && grep -q '^resume: claims: ROW-1 ROW-2' "$T/page.out" || fail 'the page has no resume lines'
grep -qF "$H/.vid/reread-owed.S1 from another terminal" "$T/page.out" || fail 'the page does not name the debt file'
[ "$(sed -n 's/^file //p' "$H/.vid/reread-owed.S1")" = "$DV
$TM
$VV
$VB" ] || fail 'the debt file does not list the four paths'
grep -q '^since 20[0-9][0-9]-' "$H/.vid/reread-owed.S1" || fail 'the debt file has no since line'
rm -f "$H/.vid/reread-owed.S1"
page resume S2; grep -q '^ViD re-entry' "$T/page.out" || fail 'source=resume printed no page'
[ ! -f "$H/.vid/reread-owed.S2" ] || fail 'source=resume wrote a re-read debt'   # v0.9.8.1 (R31): the debt is compaction's only
printf 'stage name=develop state=end session=S1 at=2026-10-02T11:00:00Z\nstage name=fix state=start session=S1 records=8 at=2026-10-02T11:01:00Z\n' >> "$H/.vid/metrics-events"
page compact; grep -qxF -- "- $FX" "$T/page.out" && grep -qxF -- "- $VB" "$T/page.out" && ! grep -qxF -- "- $DV" "$T/page.out" || fail 'with fix the open verb the list is not fix'"'"'s'
rm -f "$H/.vid/reread-owed."*
for s in startup clear; do page $s; [ ! -s "$T/page.out" ] || fail "source=$s printed something"; done
ls "$H/.vid" | grep -q reread-owed && fail 'startup or clear wrote a debt'
printf 'run: stopped owner asked to pause\n' > "$H/.vid/RUN-STATE.md"; page compact; [ ! -s "$T/page.out" ] || fail 'a stopped run printed a page'
printf 'run: active\nsession: S1\n' > "$H/.vid/RUN-STATE.md"
mkdir -p "$T/plain"; ( cd "$T/plain" && git init -q ); page compact S1 "$T/plain"; [ ! -s "$T/page.out" ] || fail 'a directory with no .vid/ printed a page'
printf 'not json' | sh "$PR/hooks/reentry.sh" > "$T/page.out" || fail 'unparseable input exited non-zero'
[ ! -s "$T/page.out" ] || fail 'unparseable input printed something'
# C-3: an older checks/ — alive is never called
printf '# Purpose: toy\nrecords: 8\n' > "$H/checks/records-version"
printf '#!/bin/sh\ncase "$1" in resume) echo "resume: run: active" ;; *) echo "tick $1" >> .vid/observer.state ;; esac\n' > "$H/checks/observe.sh"
printf 'tick 1\n' > "$H/.vid/observer.state"; B=$(cksum < "$H/.vid/observer.state")
page compact
grep -q '^resume: run: active' "$T/page.out" && grep -qxF -- "- $FX" "$T/page.out" || fail 'with records 8 the page lacks the list or resume'
[ "$(cksum < "$H/.vid/observer.state")" = "$B" ] || fail 'with records 8 the hook called alive, and an older observe.sh wrote'
exit 0
