#!/bin/sh
# Purpose: selftest case — the death record (v0.9.5 spec 3.4, R4; §7 case
# 8). Needs the plugin's hooks/stop-failure.sh beside checks/, so in a
# project (init copies checks/ alone) it proves nothing and passes; in the
# plugin repository it runs in a directory whose name has a space.
# Convicts unless: a StopFailure input for the run's session appends one
# `died` line with `reason=`, `session=`, `details=` and `at=`; with
# `agent_id`, or another session, it appends nothing; a
# `quota_auto_resume_stale` Notification appends `usage-limit-waiting`;
# compact and pretty-printed input both parse, and an `error_details` text
# carrying `\"session_id\"` is never taken for the key; a `cwd` in a
# subdirectory records from the walk-up; and with no RUN-STATE, no
# checks/records-version, or malformed input, it appends nothing and exits 0.
# Env: CHECKS.
set -eu
H="$CHECKS/../hooks/stop-failure.sh"
[ -f "$H" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
R="$T/a run dir"; mkdir -p "$R/.vid" "$R/checks" "$R/app/deep"
cd "$R"; git init -q
printf '# Purpose: x\nrecords: 1\n' > checks/records-version
printf 'run: active\nsession: S1\nquestions: - · next Q1\n' > .vid/RUN-STATE.md
fail() { echo "death-record: $*" >&2; cat .vid/metrics-events >&2 2>/dev/null; exit 1; }
hook() { printf '%s' "$1" | ( cd "$T" && sh "$H" ); }
n() { [ -f .vid/metrics-events ] && grep -c '^died ' .vid/metrics-events || echo 0; }
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"rate_limit\",\"error_details\":\"429 the weekly limit\"}" || fail 'the hook exited non-zero'
[ "$(n)" -eq 1 ] || fail 'no died line'
grep -qxE "died reason=rate_limit session=S1 details=\"429 the weekly limit\" $ATRE" .vid/metrics-events || fail 'the died line is not in its form'
hook "{\"session_id\":\"S1\",\"agent_id\":\"a-7\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"server_error\"}"
hook "{\"session_id\":\"S2\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"server_error\"}"
[ "$(n)" -eq 1 ] || fail 'a subagent or another session recorded a death'
hook "{\"error_details\":\"see \\\"session_id\\\": \\\"S1\\\"\",\"session_id\":\"S2\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"overloaded\"}"
[ "$(n)" -eq 1 ] || fail 'text inside a string value was taken for the session key'
hook "{
  \"session_id\": \"S1\",
  \"transcript_path\": \"/x/t.jsonl\",
  \"cwd\": \"$R/app/deep\",
  \"hook_event_name\": \"Notification\",
  \"notification_type\": \"quota_auto_resume_stale\",
  \"message\": \"a limit reset while the host slept\"
}"
[ "$(n)" -eq 2 ] || fail 'the pretty-printed Notification from a subdirectory recorded nothing'
tail -n 1 .vid/metrics-events | grep -qE "^died reason=usage-limit-waiting session=S1 details=\"quota_auto_resume_stale\" $ATRE\$" || fail 'the usage-limit pause is not in its form'
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"Notification\",\"notification_type\":\"permission_prompt\"}"
hook '{"session_id":"S1","cwd":' || fail 'malformed input exited non-zero'
[ "$(n)" -eq 2 ] || fail 'another notification type or malformed input recorded something'
rm checks/records-version
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"rate_limit\"}" || fail 'the hook exited non-zero without records-version'
[ "$(n)" -eq 2 ] || fail 'a project without checks/records-version recorded a death'
printf '# Purpose: x\nrecords: 1\n' > checks/records-version; rm .vid/RUN-STATE.md
hook "{\"session_id\":\"S1\",\"cwd\":\"$R\",\"hook_event_name\":\"StopFailure\",\"error\":\"rate_limit\"}" || fail 'the hook exited non-zero without a run'
[ "$(n)" -eq 2 ] || fail 'a directory with no run recorded a death'
exit 0
