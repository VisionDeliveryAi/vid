#!/bin/sh
# Purpose: selftest case — the engines move through results.sh declare (GM-4 F16): /vid next's `engines "<them>" "<words>"`
# (next-move.sh call) writes .vid/tw/handed's one engines line by results.sh declare, `engines <them> | stand-in: owner at <now>,
# words "<words>"`; named again it replaces that line, never adds one; with blank words, or a name that is no engine's, refused and
# nothing written. results.sh declare --engines takes the same and refuses the same. On GitHub manual's toy (fixtures/accept.sh). Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"   # the plan page goes under HOME
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-engines-declare: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'
mv_() { RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
mv_ engines 'alpha beta' 'alpha first, then beta'; grep -q '^done engines alpha beta' "$T/out" || fail 'the engines move was not done'
grep -qx 'engines alpha beta | stand-in: owner at [0-9TZ:-]*, words "alpha first, then beta"' .vid/tw/handed || { cp .vid/tw/handed "$T/out"; fail 'the engines line is not on record in the owner words'; }
mv_ engines 'gamma' 'gamma alone now'; [ "$(grep -c '^engines ' .vid/tw/handed)" = 1 ] && grep -q '^engines gamma | .*words "gamma alone now"' .vid/tw/handed || { cp .vid/tw/handed "$T/out"; fail 'the engines named again did not replace the one line'; }
h0=$(cksum < .vid/tw/handed); mv_ engines 'a;b' 'yes'; grep -q '^refused engines' "$T/out" && [ "$(cksum < .vid/tw/handed)" = "$h0" ] || fail 'a name that is no engine was taken'
mv_ engines 'delta' ' '; grep -q '^refused engines' "$T/out" && [ "$(cksum < .vid/tw/handed)" = "$h0" ] || fail 'blank words were taken'
RC=0; sh "$CHECKS/results.sh" declare --engines 'delta' --words '' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ "$(cksum < .vid/tw/handed)" = "$h0" ] || fail 'results.sh declare took blank words'
sh "$CHECKS/results.sh" declare --engines 'delta epsilon' --words 'the owner, by hand' > "$T/out" 2>&1 || fail 'results.sh declare --engines was refused'
grep -q '^engines delta epsilon | stand-in: owner at .*words "the owner, by hand"' .vid/tw/handed || fail 'results.sh declare did not write the line'
exit 0
