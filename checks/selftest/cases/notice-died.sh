#!/bin/sh
# Purpose: selftest case — a death is told by cause (v0.9.5 spec 3.5, R5;
# §7 case 4). Planted `died` events. Convicts unless a `rate_limit` death
# gives the usage-limit text with the resume suffix, and no quiet notice
# while it stands with nothing after it; a later `run state` event clears
# it and a second death of the same session gives a second notice; a death
# with a newer `run state` event gives none; with a live brief (whose
# check the observer's tick writes as a `brief-check` event) the death is
# told (v0.9.7.0.9: nothing is sent, so no failed send to retry); later
# activity that then goes quiet gets the quiet notice beside a standing
# death; a background agent's commit after the death does not clear it;
# and (v0.9.6) the observer's own `progress … by=observer` lines after the
# death neither lift it nor count as activity. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=notice-died
. "$CHECKS/selftest/fixtures/observer-lib.sh"
reset; rs active
ev 'died reason=rate_limit session=S1 details="weekly limit"' "$(ago 600)"
tick
[ "$(nnote 'ViD: the build hit your usage limit.')" -eq 1 ] || fail 'no usage-limit notice'
grep 'usage limit' "$T/notify.log" | grep -q 'observe.sh resume' || fail 'the death notice carries no resume suffix'
[ "$(nnote 'gone quiet')" -eq 0 ] || fail 'the quiet notice came while the death stands with nothing after it'
tick; [ "$(nnote 'usage limit')" -eq 1 ] || fail 'the death notice repeated'
# v0.9.6 (3.15; §7 case 35): the observer's own hourly progress lines after the death do not lift it
ev 'progress trigger=hourly by=observer rows-passing=0 rows-left=4 estimate=none' "$(ago 300)"; tick
ev 'progress trigger=hourly by=observer rows-passing=0 rows-left=4 estimate=none' "$(ago 200)"; tick
[ "$(nnote 'gone quiet')" -eq 0 ] || fail 'observer progress lines after a death counted as activity (a quiet notice came)'
[ "$(nnote 'usage limit')" -eq 1 ] || fail 'observer progress lines re-told the death'
ev 'run state=active' "$(ago 500)"; tick
ev 'died reason=rate_limit session=S1' "$(ago 400)"; tick
[ "$(nnote 'usage limit')" -eq 2 ] || fail 'a second death of the same session was not told'
reset; rs active
ev 'died reason=overloaded session=S1' "$(ago 300)"; ev 'run state=active' "$(ago 200)"
tick; [ "$(nnote 'connection error')" -eq 0 ] || fail 'a death with a newer run state event was told'
reset; rs active
mkdir -p .vid/briefs/3; printf 'role: builder    slice: 3\nquoted-at: x\n' > .vid/briefs/3/builder-1.md
sed 's#briefs: -#briefs: .vid/briefs/3/builder-1.md#' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md
ev 'died reason=authentication_failed session=S1' "$(ago 300)"
tick
grep -q '^brief-check ' .vid/metrics-events || fail 'the tick checked no brief (the fixture is wrong)'
[ "$(nnote 'account needs attention')" -eq 1 ] || fail 'the death was not told'
tick; [ "$(nnote 'account needs attention')" -eq 1 ] || fail 'the death was told twice'
reset; rs active
ev 'died reason=max_output_tokens session=S1' "$(ago 900)"
tick; [ "$(nnote 'cut off')" -eq 1 ] && [ "$(nnote 'gone quiet')" -eq 0 ] || fail 'the death or the held quiet notice'
hb "$(ago 300)" 'a line after the death'
tick; [ "$(nnote 'gone quiet')" -eq 1 ] || fail 'activity after the death that went quiet got no quiet notice'
reset; rs active
ev 'died reason=overloaded session=S1' "$(ago 300)"
printf 'x\n' >> w.txt; g add w.txt; g commit -qm 'a background agent commits after the death'
tick; [ "$(nnote 'service or connection error')" -eq 1 ] || fail "a background agent's commit hid the death"
grep -q 'claude --resume S1' "$T/notify.log" || fail 'the resume step does not name the session'
exit 0
