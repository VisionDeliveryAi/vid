#!/bin/sh
# Purpose: selftest case — the joint case of 0.26.10.28.7 (its merge point): the real bundle and the real send, end to end, on stubs.
# On the share's toy with the real checks/share.sh in place of its stand-in scanner: `share.sh build` writes .vid/shares/<run>/ with
# <run>.summary and <run>.known beside it, the summary's folder relative to the project and no home path in it; `share.sh scan` finds it
# clean and `pack` makes one archive; github.sh share-create and share-push, scanning the folder in place with its .known beside it,
# put the bundle at projects/<project>/<run>/ on the fake gh's private repository, the .known and summary not among its files; a secret
# planted in the bundle after its build is refused by share-push, the scan naming the file and the kind and never the value, with no call
# after gh auth status and no push. Made-up names alone. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-joint: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
CLAUDE_CONFIG_DIR=$T/claude; export CLAUDE_CONFIG_DIR; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
. "$CHECKS/selftest/fixtures/share-toy.sh"; sh_toy "$T"; cp "$CHECKS/share.sh" checks/share.sh; rm -rf .vid/shares
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=33 at=2026-11-03T09:00:00Z\n' > .vid/metrics-events
printf 'round 1 of the toy\n' > round.log; printf '# plan\n' > PLAN.md
RUN=2026-11-local-auto-toy; GS=checks/github.sh; RP=quill-tester/vid-shares
sh checks/share.sh build --run "$RUN" > "$T/out" 2>&1 || fail 'share.sh build failed'
B=.vid/shares/$RUN; [ -d "$B" ] && [ -f "$B.summary" ] && [ -f "$B.known" ] || fail 'no bundle with its summary and .known beside it'
grep -qx "folder	$B" "$B.summary" || fail "the summary's folder is not $B: $(grep '^folder' "$B.summary")"
! grep -qF "$T" "$B.summary" || fail 'the summary holds a home path'
sh checks/share.sh scan "$B" > "$T/out" 2>&1 || fail 'the scan of the fresh bundle is not clean'
A=$(sh checks/share.sh pack "$B" 2> "$T/out") && [ -f "$A" ] || fail 'pack made no archive'
sh "$GS" share-create --repo "$RP" > "$T/out" 2>&1 || fail 'share-create failed'
sh "$GS" share-push --repo "$RP" --project toy --run "$RUN" "$B" > "$T/out" 2>&1 || fail 'share-push of the real bundle failed'
G=$(sh_dir "$RP")/remote.git; git --git-dir="$G" ls-tree -r --name-only main > "$T/tree"
grep -qx "projects/toy/$RUN/RUN.md" "$T/tree" && grep -qx "projects/toy/$RUN/MANIFEST.json" "$T/tree" || { cp "$T/tree" "$T/out"; fail 'the pushed run folder lacks RUN.md or MANIFEST.json'; }
! grep -qE '\.known$|\.summary$' "$T/tree" || fail 'the .known or the summary was pushed'
C0=$(git --git-dir="$G" rev-parse main)
# a value planted after the build: the push refuses, with no call after gh auth status
printf 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY1\n' >> "$B/RUN.md"; sh_mark
if sh "$GS" share-push --repo "$RP" --project toy --run "$RUN-2" "$B" > "$T/out" 2>&1; then fail 'a bundle holding a planted secret was pushed'; fi
[ "$(sh_calls | paste -sd '|' -)" = 'gh auth status' ] || fail "the refused push called more than gh auth status: $(sh_calls | paste -sd '|' -)"
grep -q 'RUN.md' "$T/out" && ! grep -qF 'wJalrXUtnFEMI' "$T/out" || fail 'the refusal does not name the file, or prints the value'
[ "$(git --git-dir="$G" rev-parse main)" = "$C0" ] || fail 'main moved after a refused push'
echo 'share-joint: ok'
