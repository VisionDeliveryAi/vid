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
# test-proven, authority-kept. v0.26.10.6 (R17): so must the records-26 event, usage. v0.26.10.7 (R18): so must the
# records-27 events, deploy-check and stage-hold. v0.26.10.8 (R14): so must the records-28 event, staging-auth.
# v0.26.10.9 (R28): the code source also takes a script's own `ev "<type> …"` helper call (ticket.sh, github.sh), and
# the records-29 events — ticket, milestone, publish-approved, copy-check, skeleton — must be found written AND listed.
# v0.26.10.12 (H1): the project branch's stub read only two of the three forms, so in every init'd project the case
# aborted before any plant; both now read one extraction, and the project branch runs in the plugin repository too.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ROOT=$(cd "$CHECKS/.." && pwd)
# code_types <file>...: each type the code writes, by the three writer forms. v0.26.10.12 (H1): the detector and a
# project's stub contract both read through this one function, so they cannot read different forms again.
code_types() {
  for f in "$@"; do
    [ -f "$f" ] || continue
    grep -E "printf ['\"][a-z][a-z-]* [^'\"]*=" "$f" | grep '>>' | grep -E 'metrics-events|"\$EV"|\$EVENTS|\$\{EV\}' \
      | sed -E "s/.*printf ['\"]([a-z][a-z-]*) .*/\1/" || true
    grep -oE "event\.sh\"?[[:space:]]+['\"][a-z][a-z-]* [^'\"]*=" "$f" | sed -E "s/.*['\"]([a-z][a-z-]*) .*/\1/" || true
    # v0.26.10.9 (R28): ticket.sh, github.sh and the planner write through their own `ev "<type> …"` helper
    grep -oE "(^|[;&|( ])ev ['\"][a-z][a-z-]* [^'\"]*=" "$f" | sed -E "s/.*ev ['\"]([a-z][a-z-]*) .*/\1/" || true
  done
}
# drift <root>: prints each written type RECORDS.md does not list; exit 1 if any
drift() {
  _r=$1
  code_types "$_r"/checks/*.sh "$_r"/checks/hooks/* "$_r"/hooks/*.sh "$_r"/checks/selftest/run.sh > "$T/types"   # v0.9.8.1: run.sh writes selftest-retried
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
# copy <scratch>: the checks/ under test, its scripts and hooks
copy() { mkdir -p "$1/checks/hooks"; cp "$CHECKS"/*.sh "$1/checks/"; cp "$CHECKS"/hooks/* "$1/checks/hooks/"; }
# plants <scratch> <branch>: the copy shows no drift, then each of the three plants is caught alone
plants() {
  _s=$1 _b=$2
  drift "$_s" >/dev/null || { echo "records-drift: the $_b scratch copy drifts before any plant" >&2; exit 1; }
  mkdir -p "$_s/skills/vid-plant"
  for p in single double skill; do
    rm -f "$_s/checks/plant.sh" "$_s/skills/vid-plant/SKILL.md"
    case "$p" in
      single) printf '#!/bin/sh\n# Purpose: plant\nprintf '"'"'xplant n=%%s\\n'"'"' 1 >> .vid/metrics-events\n' > "$_s/checks/plant.sh" ;;
      double) printf '#!/bin/sh\n# Purpose: plant\ntrap '"'"'printf "yplant seconds=%%s\\n" 1 >> .vid/metrics-events'"'"' EXIT\n' > "$_s/checks/plant.sh" ;;
      skill)  printf 'Then record\n`sh checks/event.sh '"'"'zplant slice=N n=K'"'"'` and continue.\n' > "$_s/skills/vid-plant/SKILL.md" ;;
    esac
    if OUT=$(drift "$_s"); then echo "records-drift: the $p plant was not caught in the $_b scratch copy" >&2; exit 1; fi
    printf '%s\n' "$OUT" | grep -q 'plant' || { echo "records-drift: the $p plant failed for another reason in the $_b scratch copy: $OUT" >&2; exit 1; }
  done
}
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
  for t in usage; do   # v0.26.10.6 (R17)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-26 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-26 event $t" >&2; exit 1; }
  done
  for t in deploy-check stage-hold; do   # v0.26.10.7 (R18)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-27 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-27 event $t" >&2; exit 1; }
  done
  for t in ticket milestone publish-approved copy-check skeleton; do   # v0.26.10.9 (R28)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-29 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-29 event $t" >&2; exit 1; }
  done
  for t in staging-auth; do   # v0.26.10.8 (R14)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-28 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-28 event $t" >&2; exit 1; }
  done
  for t in decision-labels court-refused; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-18 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-18 event $t" >&2; exit 1; }
  done
  S="$T/plugin"; copy "$S"
  cp "$ROOT/RECORDS.md" "$S/"
  [ -d "$ROOT/skills" ] && cp -R "$ROOT/skills" "$S/"
  [ -d "$ROOT/hooks" ] && cp -R "$ROOT/hooks" "$S/"
  plants "$S" plugin
fi
# v0.26.10.12 (H1): the project branch runs everywhere, the plugin repository included, so ViD's own suite takes the
# path every init'd project takes: checks/ alone, with a contract listing exactly what its code writes
S="$T/project"; copy "$S"
mkdir -p "$S/skills"; printf '# stub\n' > "$S/skills/stub.md"
{ printf '## Events\n\n| type | fields |\n|---|---|\n'
  code_types "$S"/checks/*.sh "$S"/checks/hooks/* | sort -u | sed 's/.*/| `&` | x |/'
} > "$S/RECORDS.md"
plants "$S" project
exit 0
