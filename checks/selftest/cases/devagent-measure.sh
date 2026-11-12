#!/bin/sh
# Purpose: selftest case — measure again only on a change that needs it (v0.26.10.28.2, R5, F-003, F-013). Neither the dev manager's file nor the test
# manager's sends a head report with more cases than measured: to a setup pass: each says it is no trigger. A run killed for memory (exit 137) and a run
# lost to the host's process limit still send it to step 3, with environments: 1 first, in both, and setup.md's own triggers name the process limit and
# never the cases' growth. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..; [ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
fail() { echo "devagent-measure: $*" >&2; exit 1; }
DM=$R/devagent/agents/dev-manager.md; TM=$R/devagent/test-manager/SKILL.md; SU=$R/devagent/test-manager/setup.md
one() { tr '\n' ' ' < "$1" | tr -s ' '; }
# no file makes more cases a trigger
for f in "$DM" "$TM" "$SU"; do one "$f" | grep -qE 'more cases than (the record.s )?`measured:`( line)?(: set| \(v0\.26\.10\.24\.7 R8\): before)' && fail "$(basename "$f") still sends more cases to a setup pass"; done
one "$DM" | grep -qF 'A head report with more cases than `measured:` calls for none (v0.26.10.28.2, R5)' || fail 'the dev manager does not say more cases call for no measure'
one "$TM" | grep -qF "A head report with more cases than the record's \`measured:\` line is no trigger (v0.26.10.28.2, R5)" || fail 'the test manager does not say more cases are no trigger'
# exit 137 and the process limit still do, environments: 1 first
one "$DM" | grep -qF "stopped by \`service … exit 137\`, or lost to the host's process limit (\`wait\`'s line, v0.26.10.28.2, R1): set \`environments: 1\` in the dev setup record, then a setup pass, step 3" || fail 'the dev manager does not send exit 137 or a process-limit loss to step 3'
one "$DM" | grep -qF "with no \`measured after <chunk> <k>\` line after it" && one "$DM" | grep -qF "after that pass, for a loss, a line \`measured after <chunk> <k>\` in its record, so it calls for no second measure" || fail 'a process-limit loss, once measured, still calls for a measure'
one "$TM" | grep -qF "after a run killed for memory or lost to the host's process limit, and when the product first starts: before any further run \`environments: 1\`, then the setup's step 3" || fail 'the test manager does not send exit 137 or a process-limit loss to step 3'
one "$SU" | grep -qF "after a run killed for memory or lost to the host's process limit, and when the product first starts (step 3); never only because the cases grew" || fail "setup.md's triggers"
# measured: is still recorded, and the head report still names its environments
grep -qF 'measured: <cases> <peak MiB> <UTC>' "$SU" || fail 'setup.md no longer records measured:'
grep -q 'environments: ' "$R/devagent/test-manager/run.sh" || fail 'the head report no longer names its environments'
echo 'devagent-measure: ok'
