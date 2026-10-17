#!/bin/sh
# Purpose: selftest case — the record contract covers every writer (v0.9.5
# spec 3.10, R10; §7 case 16). Every event type written must be listed in
# RECORDS.md's Events table, taken from three sources: the code (checks/*.sh,
# checks/hooks/*, the plugin's hooks/*.sh — a single- or double-quoted
# `printf '<type> …'` appended to the events file, traps included); every
# `event.sh '<type> …'` call under skills/; develop's catalogue (the
# "Record the dataset as you go" paragraph's `<type> <field>=…` spans). In
# the plugin repository the real tree must show no drift. Then, on a
# scratch copy, each of three plants must be caught alone: a new
# single-quoted writer, a new double-quoted writer in a trap, a new
# event.sh call in a skill. Where RECORDS.md is absent (a project: init
# copies checks/ alone), the scratch copy is the project's checks/ with a
# contract listing the types its code writes — it still proves the
# detector convicts each plant. v0.9.6.2 (3.9, R8; §6 case 21): the code
# source also takes an `event.sh "<type> …"` call in a script or hook (the
# refusal and deploy-gate writers), and in the plugin repository each event
# type records 4 adds — session, agent-start, agent-stop, refused,
# deploy-gate, deploy-confirm, deploy-rollback — must be found written AND
# listed. v0.9.6.2.2: a project's stub contract also lists the types its
# scripts write through event.sh, as the detector reads them. v0.9.7.0.3
# (3.4, R7): the two records-7 events, analyst-due (checks/test.sh) and
# analyst-done (the test manager's skill), must be found written AND
# listed in the plugin repository. v0.9.7.2 (3.12, R16): so must the five
# records-17 events — strategy, step-done, step-rows-passing, deferred,
# deferred-resolved. v0.9.7.3 (3.10, R10): so must the two records-18
# events, decision-labels and court-refused. v0.9.7.4 (3.11, R12): so must
# the records-19 event, delegated. v0.9.8 (R14; amendment 3): so must two records-20 events —
# test-proven, authority-kept. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ROOT=$(cd "$CHECKS/.." && pwd)
# drift <root>: prints each written type RECORDS.md does not list; exit 1 if any
drift() {
  _r=$1; : > "$T/types"
  for f in "$_r"/checks/*.sh "$_r"/checks/hooks/* "$_r"/hooks/*.sh "$_r"/checks/selftest/run.sh; do   # v0.9.8.1: run.sh writes selftest-retried
    [ -f "$f" ] || continue
    grep -E "printf ['\"][a-z][a-z-]* [^'\"]*=" "$f" | grep '>>' | grep -E 'metrics-events|"\$EV"|\$EVENTS|\$\{EV\}' \
      | sed -E "s/.*printf ['\"]([a-z][a-z-]*) .*/\1/" >> "$T/types" || true
    grep -oE "event\.sh\"?[[:space:]]+['\"][a-z][a-z-]* [^'\"]*=" "$f" | sed -E "s/.*['\"]([a-z][a-z-]*) .*/\1/" >> "$T/types" || true
  done
  if [ -d "$_r/skills" ]; then
    find "$_r/skills" -type f -name '*.md' | while IFS= read -r f; do
      tr '\n' ' ' < "$f" | grep -oE "event\.sh\"?[[:space:]]+['\"][a-z][a-z-]*[[:space:]]" | sed -E "s/.*['\"]([a-z][a-z-]*)[[:space:]]$/\1/" || true
    done >> "$T/types"
    D="$_r/skills/vid-develop/SKILL.md"
    if [ -f "$D" ]; then
      awk '/Record the dataset as you go/ { on = 1 } on && /^[[:space:]]*$/ { exit } on' "$D" | tr '\n' ' ' \
        | grep -oE '`[a-z][a-z-]* [^`]*=[^`]*`' | sed -E 's/^`([a-z][a-z-]*) .*/\1/' >> "$T/types" || true
    fi
  fi
  [ -f "$_r/RECORDS.md" ] || { echo 'no RECORDS.md'; return 1; }
  awk '/^## Events/ { on = 1; next } on && /^## / { exit } on' "$_r/RECORDS.md" | sed -nE 's/^\| `([a-z][a-z-]*)` \|.*/\1/p' | sort -u > "$T/listed"
  [ -s "$T/listed" ] || { echo 'RECORDS.md lists no event type'; return 1; }
  sort -u "$T/types" | grep -v '^$' > "$T/written" || true
  [ -s "$T/written" ] || { echo 'no writer found — the extraction is broken'; return 1; }
  _m=$(comm -23 "$T/written" "$T/listed")
  [ -z "$_m" ] || { printf 'unlisted: %s\n' $_m; return 1; }
  return 0
}
S="$T/scratch"; mkdir -p "$S/checks/hooks"
cp "$CHECKS"/*.sh "$S/checks/"; cp "$CHECKS"/hooks/* "$S/checks/hooks/"
if [ -f "$ROOT/RECORDS.md" ]; then
  drift "$ROOT" || { echo 'records-drift: the shipped tree writes an event type RECORDS.md does not list' >&2; exit 1; }
  for t in session agent-start agent-stop refused deploy-gate deploy-confirm deploy-rollback; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-4 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-4 event $t" >&2; exit 1; }
  done
  for t in analyst-due analyst-done; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-7 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-7 event $t" >&2; exit 1; }
  done
  for t in strategy step-done step-rows-passing deferred deferred-resolved; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-17 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-17 event $t" >&2; exit 1; }
  done
  for t in delegated; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-19 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-19 event $t" >&2; exit 1; }
  done
  for t in test-proven authority-kept; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-20 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-20 event $t" >&2; exit 1; }
  done
  for t in selftest-retried agent-brief; do   # v0.9.8.1 (R24)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-21 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-21 event $t" >&2; exit 1; }
  done
  for t in decision-labels court-refused; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-18 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-18 event $t" >&2; exit 1; }
  done
  cp "$ROOT/RECORDS.md" "$S/"
  [ -d "$ROOT/skills" ] && cp -R "$ROOT/skills" "$S/"
  [ -d "$ROOT/hooks" ] && cp -R "$ROOT/hooks" "$S/"
else
  # a project: a contract listing exactly what its checks/ writes
  mkdir -p "$S/skills"; printf '# stub\n' > "$S/skills/stub.md"
  { printf '## Events\n\n| type | fields |\n|---|---|\n'
    for f in "$S"/checks/*.sh "$S"/checks/hooks/*; do grep -E "printf ['\"][a-z][a-z-]* [^'\"]*=" "$f" | grep '>>' | grep -E 'metrics-events|"\$EV"|\$EVENTS|\$\{EV\}' | sed -E "s/.*printf ['\"]([a-z][a-z-]*) .*/| \`\1\` | x |/" || true
      grep -oE "event\.sh\"?[[:space:]]+['\"][a-z][a-z-]* [^'\"]*=" "$f" | sed -E "s/.*['\"]([a-z][a-z-]*) .*/| \`\1\` | x |/" || true; done | sort -u
  } > "$S/RECORDS.md"
fi
drift "$S" >/dev/null || { echo 'records-drift: the scratch copy drifts before any plant' >&2; exit 1; }
mkdir -p "$S/skills/vid-plant"
for p in single double skill; do
  rm -f "$S/checks/plant.sh" "$S/skills/vid-plant/SKILL.md"
  case "$p" in
    single) printf '#!/bin/sh\n# Purpose: plant\nprintf '"'"'xplant n=%%s\\n'"'"' 1 >> .vid/metrics-events\n' > "$S/checks/plant.sh" ;;
    double) printf '#!/bin/sh\n# Purpose: plant\ntrap '"'"'printf "yplant seconds=%%s\\n" 1 >> .vid/metrics-events'"'"' EXIT\n' > "$S/checks/plant.sh" ;;
    skill)  printf 'Then record\n`sh checks/event.sh '"'"'zplant slice=N n=K'"'"'` and continue.\n' > "$S/skills/vid-plant/SKILL.md" ;;
  esac
  if OUT=$(drift "$S"); then echo "records-drift: the $p plant was not caught" >&2; exit 1; fi
  printf '%s\n' "$OUT" | grep -q 'plant' || { echo "records-drift: the $p plant failed for another reason: $OUT" >&2; exit 1; }
done
exit 0
