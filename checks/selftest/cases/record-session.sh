#!/bin/sh
# Purpose: selftest case — the session hook (v0.9.6.2 spec 3.2, R2; §6 case
# 6). Needs the plugin's hooks/ beside checks/, so in a project it proves
# nothing and passes; in the plugin repository it runs in a directory whose
# name has a space. Convicts unless hooks.json registers hooks/record.sh for
# SessionStart, and a SessionStart input whose `cwd` is the home — or a
# subdirectory of it, or a builder worktree whose .vid/home names it —
# appends `session id= source= model= transcript= vid=` (the source as
# given, `fork` included; vid= the plugin's version) to the home's events,
# the builder's own .vid/ holding none; an input without `model` writes no
# model=; and in a folder with no .vid/ (a session before init) nothing is
# written anywhere and the hook exits 0; after init there (a stage event
# naming the session) there is still no session event, and the export lists
# that session's transcript. Env: CHECKS.
set -eu
HD="$CHECKS/../hooks"
[ -f "$HD/stop-failure.sh" ] || exit 0
fail() { echo "record-session: $*" >&2; cat "${HOMEP:-.}/.vid/metrics-events" >&2 2>/dev/null || true; exit 1; }
[ -f "$HD/record.sh" ] || fail 'no hooks/record.sh'
tr -d ' \n' < "$HD/hooks.json" | grep -q '"SessionStart":\[{"hooks":\[{"type":"command","command":"sh\\"${CLAUDE_PLUGIN_ROOT}/hooks/record.sh\\""' || fail 'hooks.json does not register record.sh for SessionStart'
VER=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$CHECKS/../.claude-plugin/plugin.json")
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
hook() { printf '%s' "$1" | ( cd "$T" && sh "$HD/record.sh" ); }
mkdir -p "$T/a home/.vid" "$T/a home/app/deep"; cd "$T/a home"; git init -q
printf '.vid/\n' > .gitignore; g add -A; g commit -qm root
HOMEP=$(pwd -P)
printf 'run: active\nsession: S1\nplan: required\n' > .vid/RUN-STATE.md
hook "{\"session_id\":\"S1\",\"transcript_path\":\"/t/S1.jsonl\",\"cwd\":\"$HOMEP\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\",\"model\":\"claude-x-1\"}" || fail 'the hook exited non-zero'
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
grep -qxE "session id=S1 source=startup model=claude-x-1 transcript=/t/S1.jsonl vid=$VER $ATRE" .vid/metrics-events || fail 'the session line is not in its form'
hook "{
  \"session_id\": \"S2\",
  \"transcript_path\": \"/t/a b/S2.jsonl\",
  \"cwd\": \"$HOMEP/app/deep\",
  \"hook_event_name\": \"SessionStart\",
  \"source\": \"fork\"
}"
tail -n 1 .vid/metrics-events | grep -qxE "session id=S2 source=fork transcript=\"/t/a b/S2.jsonl\" vid=$VER $ATRE" || fail 'a fork from a subdirectory, with no model, is not in its form'
g worktree add -q "$T/builder" -b builder 2>/dev/null
mkdir -p "$T/builder/.vid"; printf '%s\n' "$HOMEP" > "$T/builder/.vid/home"
hook "{\"session_id\":\"S3\",\"transcript_path\":\"/t/S3.jsonl\",\"cwd\":\"$T/builder\",\"hook_event_name\":\"SessionStart\",\"source\":\"resume\"}"
tail -n 1 .vid/metrics-events | grep -q '^session id=S3 source=resume ' || fail "a builder worktree's session is not at the home"
[ ! -f "$T/builder/.vid/metrics-events" ] || fail "the builder's own .vid/ holds the session"
[ "$(grep -c '^session ' .vid/metrics-events)" -eq 3 ] || fail 'not three session lines'
# a session in an empty folder, before init: nothing anywhere
mkdir -p "$T/empty"
hook "{\"session_id\":\"S0\",\"transcript_path\":\"/t/S0.jsonl\",\"cwd\":\"$T/empty\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" || fail 'the hook exited non-zero outside a project'
[ ! -e "$T/empty/.vid" ] || fail 'a session outside a ViD project was recorded'
grep -q 'id=S0' .vid/metrics-events && fail 'the empty folder'"'"'s session landed elsewhere'
# then init there: still no session event, and the export lists its transcript (from the stage event's session=)
if [ -f "$CHECKS/export.sh" ]; then
  cd "$T/empty"; git init -q; g commit -q --allow-empty -m init
  sh "$CHECKS/event.sh" 'stage name=init state=start session=S0 records=1'
  grep -q '^session ' .vid/metrics-events && fail 'init backdated a session event'
  export CLAUDE_CONFIG_DIR="$T/claude"; EN=$(pwd -P | sed 's/[^A-Za-z0-9]/-/g')
  mkdir -p "$CLAUDE_CONFIG_DIR/projects/$EN"; printf '{"s":"S0"}\n' > "$CLAUDE_CONFIG_DIR/projects/$EN/S0.jsonl"
  sh "$CHECKS/export.sh" > /dev/null 2>&1 || fail 'the export failed'
  grep -q "^file	transcripts/$EN/S0.jsonl	" .vid/exports/*/manifest.tsv || fail "the export does not list the creating session's transcript"
fi
exit 0
