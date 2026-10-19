#!/bin/sh
# Purpose: selftest case — the pass briefs (v0.9.1 spec 3.1, R17). Three
# assertions over every skills/*/passes/ directory: (1) every pass a
# SKILL.md names (`passes/<name>.md`, or `skills/<skill>/passes/<name>.md`
# from another verb) resolves to a file; (2) every file under a passes/
# directory is named by a chain — no orphan brief; (3) every pass file
# opens with the fixed independence header, verbatim, as its first
# paragraph — independence is a mechanism, not a property. Polarity both
# ways: the shipped tree (when this runs inside the plugin repository)
# must pass, and a scratch tree seeding all three violations must be
# convicted — so the case is never vacuous, inside a project or out.
# Also pins the 3.10, 3.2 and 3.5 calibration fixtures and the pass-output
# checker's polarity, and (v0.9.3 3.1) that vid-develop's role table and the
# pass files agree (plugin repository only), and (v0.9.7.0.2 3.5) that the
# one rule stands word for word in vid-develop, vid-fix and vid-test-manager,
# and (v0.9.7.0.3 3.2, 3.3) that the test analyst's pass carries its
# read-only rules and return format word for word, and vid-develop and
# vid-fix the line that starts it (v0.9.7.0.9: develop's names the run
# manager and the analyst-due listing), and (v0.9.7.0.4 3.1, 3.3) that the grader's
# pass carries the scope sentence and vid-verify's question its three options
# (v0.9.7.0.5: B-1 moved with the text it checks), and (v0.9.7.0.5 3.1, §6 V-1)
# that the grader's pass holds the three sentences and the return format,
# vid-verify the moved contract, develop and fix each cite vid-verify, the
# contract's phrases stand in vid-verify alone, and develop keeps its stop,
# and (v0.9.7.0.7 3.1, §6 phase A) that vid-build holds develop's build text
# word for word against develop at the base, and develop and fix invoke it.
# v0.9.7.0.11 (3.12, R12): the analyst's test-only limit
# (`prod: n/a`) line, and the test manager's routing of it to the test
# author, word for word. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
IFS='
'
HEADER='Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role — `vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose for a role without one) with no authoring-session and no build-session context. It receives only what this file lists under `receives:` and nothing under `must not receive:`; a re-run is never told the previous verdict; a pass whose prompt carries anything the calling session believes is VOID and is re-spawned. Independence is a mechanism here, not a property.'

# check <skills-root>: prints one line per violation, returns 1 on any.
check() {
  root=$1; bad=0
  for sk in $(find "$root" -mindepth 2 -maxdepth 2 -name SKILL.md | sort); do
    dir=$(dirname "$sk")
    for ref in $(grep -oE '(skills/[a-z0-9-]+/)?passes/[a-z0-9-]+\.md' "$sk" | sort -u); do
      case "$ref" in skills/*) f="$root/${ref#skills/}" ;; *) f="$dir/$ref" ;; esac
      [ -f "$f" ] || { echo "passes: $sk names $ref but no such file exists"; bad=1; }
    done
  done
  for f in $(find "$root" -mindepth 3 -maxdepth 3 -path '*/passes/*.md' | sort); do
    name=${f##*/}; skill=$(basename "$(dirname "$(dirname "$f")")")
    if ! grep -q "passes/$name" "$root/$skill/SKILL.md" 2>/dev/null \
       && ! grep -rq "skills/$skill/passes/$name" "$root"/*/SKILL.md 2>/dev/null; then
      echo "passes: $f is named by no chain — an orphan brief"; bad=1
    fi
    first=$(awk 'NF==0{exit} {printf "%s ", $0}' "$f" | tr -s ' ' | sed 's/ $//')
    [ "$first" = "$HEADER" ] || { echo "passes: $f does not open with the independence header verbatim"; bad=1; }
  done
  return $bad
}

# --- the shipped tree must pass (plugin repository only). The gate is ViD's
# own skills, never the directory: a project may keep a skills/ of its own,
# which neither this check nor the role table below may judge (v0.9.4 fix) ---
SKILLS="$CHECKS/../skills"
if [ -f "$SKILLS/vid-develop/SKILL.md" ]; then
  check "$SKILLS" || exit 1
fi

# --- the 3.10 and 3.2 calibration fixtures (plugin repository only): each exists,
# is court-green, carries an expected.md; and the pass-output checker
# convicts a known-bad output and acquits a known-good one — the
# stochastic half (fresh agents reviewing, the checker judging) runs
# procedurally and lands in the build notes, never here.
CAL="$SKILLS/vid-create-prd/selftest"
if [ -d "$CAL" ]; then
  for fx in clean-set deliberate-deferral engineering-choice material-contradiction append-contradiction append-clean wording-arms; do
    [ -f "$CAL/fixtures/$fx/PRD.md" ] || { echo "passes: calibration fixture $fx has no PRD.md"; exit 1; }
    [ -f "$CAL/fixtures/$fx/expected.md" ] || { echo "passes: calibration fixture $fx has no expected.md"; exit 1; }
    sh "$CHECKS/prd.sh" "$CAL/fixtures/$fx/PRD.md" >/dev/null 2>&1 || { echo "passes: calibration fixture $fx is not court-green"; exit 1; }
  done
  C=$(mktemp -d); trap 'rm -rf "$C"' EXIT
  printf '```vid-prd-findings\n```\n' > "$C/clean.md"
  printf '```vid-prd-findings\nF-01 | review | blocking | REQ-018, REQ-004 | - | evidence: a reader following an expired link sees not-found under REQ-018 and the expired page under REQ-004 | triage: needs_owner\n```\n' > "$C/hit.md"
  printf 'no block here\n' > "$C/none.md"
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-set" "$C/clean.md" >/dev/null 2>&1 || exit 1        # empty block acquits the clean set
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-set" "$C/hit.md" >/dev/null 2>&1 && exit 1           # a finding convicts the clean set
  sh "$CAL/pass-check.sh" "$CAL/fixtures/material-contradiction" "$C/hit.md" >/dev/null 2>&1 || exit 1   # the well-formed finding acquits
  sh "$CAL/pass-check.sh" "$CAL/fixtures/material-contradiction" "$C/clean.md" >/dev/null 2>&1 && exit 1  # silence convicts the contradiction
  sh "$CAL/pass-check.sh" "$CAL/fixtures/clean-set" "$C/none.md" >/dev/null 2>&1 && exit 1          # no block is no verdict — fails closed
  # the 3.2 delta-mode pair: the two expected findings acquit the defective append and convict the clean one; silence does the reverse
  printf '```vid-prd-findings\nF-01 | review | blocking | REQ-018, REQ-004 | - | evidence: an editor extending a link keeps it redirecting past the thirty days REQ-004 and the thesis promise a reader it stops by | triage: fix_from_record\nF-02 | review | advisory | REQ-006, A-016 | - | evidence: A-016 rules the remaining days onto the deletion page but REQ-006 is neither amended nor left standing under unchanged | triage: fix_from_record\n```\n' > "$C/delta.md"
  sh "$CAL/pass-check.sh" "$CAL/fixtures/append-contradiction" "$C/delta.md" >/dev/null 2>&1 || exit 1   # the two findings acquit the defective append
  sh "$CAL/pass-check.sh" "$CAL/fixtures/append-contradiction" "$C/clean.md" >/dev/null 2>&1 && exit 1  # silence convicts it
  sh "$CAL/pass-check.sh" "$CAL/fixtures/append-clean" "$C/clean.md" >/dev/null 2>&1 || exit 1          # the empty block acquits the clean append
  sh "$CAL/pass-check.sh" "$CAL/fixtures/append-clean" "$C/delta.md" >/dev/null 2>&1 && exit 1         # a finding convicts it
  # the 3.5 wording lens: one harm-worded rewording keeping three arms acquits; silence, a lost arm, and a missing block convict
  printf '```vid-prd-rewordings\nREQ-018 | fail-if: a target whose scheme is not http or https is accepted, or a link that has left the active state answers a redirect, or the time taken to reject a wrong deletion token depends on how many of its characters match | arms: 1 strengthened, 2 strengthened, 3 strengthened\n```\n' > "$C/reword.md"
  printf '```vid-prd-rewordings\n```\n' > "$C/noreword.md"
  printf '```vid-prd-rewordings\nREQ-018 | fail-if: the scheme check is missing from the create path | arms: 1 retained, 2 withdrawn A-005\n```\n' > "$C/lostarm.md"
  sh "$CAL/pass-check.sh" "$CAL/fixtures/wording-arms" "$C/reword.md" >/dev/null 2>&1 || exit 1       # the accounted rewording acquits
  sh "$CAL/pass-check.sh" "$CAL/fixtures/wording-arms" "$C/noreword.md" >/dev/null 2>&1 && exit 1     # silence convicts
  sh "$CAL/pass-check.sh" "$CAL/fixtures/wording-arms" "$C/lostarm.md" >/dev/null 2>&1 && exit 1      # a withdrawn arm with no ruling convicts
  sh "$CAL/pass-check.sh" "$CAL/fixtures/wording-arms" "$C/clean.md" >/dev/null 2>&1 && exit 1        # a findings block is no rewording block — fails closed
fi

# --- v0.9.3 (3.1): the role table and the pass files agree (plugin repository only) ---
# vid-develop's "Spawned roles" table names the four roles; its test-author row
# defers to the pass file, which exists and lists receives:/must not receive:;
# the grader row, and GRADING.md's shared rule, carry the withheld form and the
# read exclusion verbatim; checks/brief.sh checks the same independence
# paragraph this case pins. Polarity: a copy with the test-author row dropped,
# and one with the read exclusion reworded, are convicted.
roles() { # $1=vid-develop SKILL.md $2=GRADING.md $3=test-author pass $4=brief.sh
  r=0
  sed -n '/^## Spawned roles/,/^## /p' "$1" > "$T0/roles"
  [ -s "$T0/roles" ] || { echo "passes: $1 has no Spawned roles section"; return 1; }
  for role in '| builder |' '| fixer |' '| grader (slice close) |' '| test-author |'; do
    grep -qF -- "$role" "$T0/roles" || { echo "passes: the role table lacks the row $role"; r=1; }
  done
  grep -F '| test-author |' "$T0/roles" | grep -q 'passes/test-author.md' || { echo 'passes: the test-author row does not defer to the pass file'; r=1; }
  grep -q '^receives:' "$3" && grep -q '^must not receive:' "$3" || { echo "passes: $3 lists no receives:/must not receive:"; r=1; }
  for f in "$T0/roles" "$2"; do
    grep -qF 'owed: reverted — (detail withheld from graders)' "$f" || { echo "passes: $f lacks the withheld form"; r=1; }
    grep -qF 'Do not read under `.vid/` beyond the receipt named above' "$f" || { echo "passes: $f lacks the read exclusion"; r=1; }
  done
  grep -qF "HDR='$HEADER'" "$4" || { echo "passes: $4 checks another independence paragraph than this case pins"; r=1; }
  return $r
}
if [ -f "$SKILLS/vid-develop/SKILL.md" ]; then
  T0=$(mktemp -d)
  roles "$SKILLS/vid-develop/SKILL.md" "$SKILLS/vid-grade/GRADING.md" "$SKILLS/vid-test-inventory/passes/test-author.md" "$CHECKS/brief.sh" || { rm -rf "$T0"; exit 1; }
  grep -v '^| test-author |' "$SKILLS/vid-develop/SKILL.md" > "$T0/dev-norow.md"
  if roles "$T0/dev-norow.md" "$SKILLS/vid-grade/GRADING.md" "$SKILLS/vid-test-inventory/passes/test-author.md" "$CHECKS/brief.sh" >/dev/null; then rm -rf "$T0"; exit 1; fi
  sed 's/Do not read under `.vid\/` beyond the receipt named above/Avoid the run records/' "$SKILLS/vid-grade/GRADING.md" > "$T0/grading-reworded.md"
  if roles "$SKILLS/vid-develop/SKILL.md" "$T0/grading-reworded.md" "$SKILLS/vid-test-inventory/passes/test-author.md" "$CHECKS/brief.sh" >/dev/null; then rm -rf "$T0"; exit 1; fi
  rm -rf "$T0"
fi

# --- v0.9.7.0.2 (3.5, R10; §6 D-2): the one rule, word for word, in vid-develop,
# vid-fix and vid-test-manager (plugin repository only). Polarity: a reworded copy is convicted.
RULE='Nobody runs the test runner directly. To get a test result, make a request to the test manager.'
onerule() { for f in "$@"; do grep -qF -- "$RULE" "$f" || { echo "passes: $f lacks the one rule word for word"; return 1; }; done; }
if [ -f "$SKILLS/vid-develop/SKILL.md" ]; then
  onerule "$SKILLS/vid-develop/SKILL.md" "$SKILLS/vid-fix/SKILL.md" "$SKILLS/vid-test-manager/SKILL.md" || exit 1
  T1=$(mktemp -d)
  sed 's/Nobody runs the test runner directly\./Nobody should run the test runner directly./' "$SKILLS/vid-fix/SKILL.md" > "$T1/fix.md"
  if onerule "$SKILLS/vid-develop/SKILL.md" "$T1/fix.md" "$SKILLS/vid-test-manager/SKILL.md" >/dev/null; then rm -rf "$T1"; exit 1; fi
  rm -rf "$T1"
fi

# --- v0.9.7.0.3 (3.2, 3.3; §6 B-1): the test analyst (plugin repository only) — its pass
# carries the read-only rules and the return format word for word, and vid-develop and vid-fix
# carry the line that starts it. Polarity: a reworded rule and a dropped line are convicted.
ARULES='- It reads. It never edits, commits or stages anything, and never requests or runs a test.
- For a hang it may read container state through `sh checks/testenv.sh leftovers` and the run'"'"'s log. Nothing else that changes state.
- It names a cause only from what it read, citing file and line or log line. Otherwise it says `cause: not found` and what it would need.
- It never proposes weakening an assertion. That is a product question, and the conductor'"'"'s skill already sends it to the owner.'
AFORMAT='analyst request=<ticket> reason=<reason> outcome=<setup|hang|limit|none>
finding: <one line>
setup-cause: <first message> | cases=<n> | cause: <one line, cited> | repair: <one line for the test-author>
hang-cause: <one line, cited> | action: <incident|harness fix|owner question>
limit: <ROW-id> | cases: <triggering case ids> | setting: <name> | test: <value> | prod: <value> | holds-because: <one line> | paying-step: <where> | question: "<one plain question>"
- `prod: n/a` — the setting exists only in the test, its own wait or poll: `paying-step: none` and `question: none`; it goes to the test author, not the owner.'
# v0.9.7.0.11 (3.12, R12): the test manager routes a test-only limit to the test author, word for word
NALINE='- **limit with `prod: n/a`:** a limit that exists only in the test is the test author'"'"'s: no owner question, no `difference` row. Brief a test-author pass with the return; it changes the test.'
ALINE='When a request'"'"'s result says `analyst due`, start the test analyst (`vid-test-manager`, the test analyst).'
# v0.9.7.0.9 (3.4, R5): vid-develop's line names the run manager and the listing; vid-fix keeps ALINE
DLINE='Only you, the run manager, start the test analyst (`vid-test-manager`, the test analyst): when a request'"'"'s result says `analyst due`, and for each line `sh checks/test.sh analyst-due` prints.'
analyst() { # $1=test-analyst.md $2=vid-develop $3=vid-fix
  r=0
  for l in $ARULES $AFORMAT; do grep -qxF -- "$l" "$1" || { echo "passes: $1 lacks, word for word: $l"; r=1; }; done
  grep -q '^receives:' "$1" && grep -q '^must not receive:' "$1" || { echo "passes: $1 lists no receives:/must not receive:"; r=1; }
  tr '\n' ' ' < "$2" | tr -s ' ' | grep -qF -- "$DLINE" || { echo "passes: $2 lacks the line that starts the test analyst"; r=1; }
  grep -qxF -- "$ALINE" "$3" || { echo "passes: $3 lacks the line that starts the test analyst"; r=1; }
  grep -qxF -- "$NALINE" "$SKILLS/vid-test-manager/SKILL.md" || { echo "passes: vid-test-manager lacks the test-only limit's routing"; r=1; }
  return $r
}
AP="$SKILLS/vid-test-manager/passes/test-analyst.md"
if [ -f "$SKILLS/vid-develop/SKILL.md" ]; then
  analyst "$AP" "$SKILLS/vid-develop/SKILL.md" "$SKILLS/vid-fix/SKILL.md" || exit 1
  T2=$(mktemp -d)
  sed 's/and never requests or runs a test\./and rarely runs a test./' "$AP" > "$T2/pass.md"
  if analyst "$T2/pass.md" "$SKILLS/vid-develop/SKILL.md" "$SKILLS/vid-fix/SKILL.md" >/dev/null; then rm -rf "$T2"; exit 1; fi
  grep -vF 'start the test analyst' "$SKILLS/vid-fix/SKILL.md" > "$T2/fix.md"
  if analyst "$AP" "$SKILLS/vid-develop/SKILL.md" "$T2/fix.md" >/dev/null; then rm -rf "$T2"; exit 1; fi
  rm -rf "$T2"
fi

# --- v0.9.7.0.4 (3.1, 3.3; §6 B-1), moved with its text by v0.9.7.0.5 (3.1): the grader's pass
# carries the third sentence word for word, and vid-verify's question its three options (plugin
# repository only; line breaks and quote marks read as spaces). Polarity: a reworded sentence and
# a dropped option are convicted.
SCOPE='*"If a breach rests on a case whose inclusion in the row'"'"'s promise is itself unsettled, add `scope: "<the question the owner must answer>"` to that verdict; a breach of a case the promise plainly includes takes no scope."*'
OPTA='how far? (a) <the drafted clarification or narrowing>'
OPTB='(b) N more grading rounds (say N)'
OPTC='(c) record it as a known limit:'
flatq() { sed 's/^[[:space:]]*>[[:space:]]*//; s/^[[:space:]]*//' "$1" | tr '\n' ' ' | tr -s ' '; }
howfar() { # $1=the grader's pass $2=vid-verify
  r=0
  case "$(flatq "$1")" in *"$SCOPE"*) ;; *) echo "passes: $1 lacks, word for word: $SCOPE"; r=1 ;; esac
  for l in "$OPTA" "$OPTB" "$OPTC"; do
    case "$(flatq "$2")" in *"$l"*) ;; *) echo "passes: $2 lacks, word for word: $l"; r=1 ;; esac
  done
  return $r
}
GP="$SKILLS/vid-verify/passes/grader.md"; VV="$SKILLS/vid-verify/SKILL.md"
if [ -f "$SKILLS/vid-develop/SKILL.md" ]; then
  howfar "$GP" "$VV" || exit 1
  T3=$(mktemp -d)
  sed 's/takes no scope\./takes no scope flag./' "$GP" > "$T3/gp.md"
  if howfar "$T3/gp.md" "$VV" >/dev/null; then rm -rf "$T3"; exit 1; fi
  sed 's/(b) N more/(b) more/' "$VV" > "$T3/vv.md"
  if howfar "$GP" "$T3/vv.md" >/dev/null; then rm -rf "$T3"; exit 1; fi
  rm -rf "$T3"
fi

# --- v0.9.7.0.5 (3.1, R1, R2; §6 V-1): one row-verdict contract (plugin repository only). The
# grader's pass holds the three sentences and the return format; vid-verify holds the moved
# contract and is internal; develop and fix each cite it; the contract's phrases stand in
# vid-verify alone (not in develop, not in fix); develop keeps its loop's stop word for word.
# Polarity: a pass without the return format, a develop still holding "bandwagon", a fix not
# citing vid-verify, and a develop without the stop are each convicted.
S1='*"Name the plausible wrong behaviour at this test'"'"'s boundary that the test would not catch; if you can, return BREACHED class=test."*'
S2='*"An assertion that was already true before the action is not evidence the action worked."*'
RETF='ROW-<id> [transition=k/n] | KEPT|BREACHED|ROW-AMBIGUOUS | class=<…> | [scope: "<…>" |] <evidence or counterexample, with file:line>'
OUTL='outside these rows goes in a separate list; it cannot change a verdict'
NOTEST='run no tests; a disputed result goes back to the caller'
STOP='The breached set must strictly shrink; if it does not, halt the loop and escalate rather than iterate.'
CONTRACT='bandwagon
verdicts returned must equal rows claimed
Append each verdict to the row'"'"'s attempt record
The bound is computed, never written
Code alone never releases a hold.
the rows headline reads the LATEST ELIGIBLE per-row verdict'
verify() { # $1=grader's pass $2=vid-verify $3=vid-develop $4=vid-fix
  r=0
  for l in "$S1" "$S2" "$SCOPE" "$OUTL" "$NOTEST"; do case "$(flatq "$1")" in *"$l"*) ;; *) echo "passes: $1 lacks, word for word: $l"; r=1 ;; esac; done
  grep -qxF -- "$RETF" "$1" || { echo "passes: $1 lacks the return format line"; r=1; }
  grep -q '^user-invocable: false$' "$2" || { echo "passes: $2 is not internal (user-invocable: false)"; r=1; }
  for l in $CONTRACT; do
    case "$(flatq "$2")" in *"$l"*) ;; *) echo "passes: $2 lacks the moved contract: $l"; r=1 ;; esac
    for f in "$3" "$4"; do case "$(flatq "$f")" in *"$l"*) echo "passes: $f still holds the contract's phrase: $l"; r=1 ;; esac; done
  done
  for f in "$3" "$4"; do grep -qF 'skills/vid-verify/SKILL.md' "$f" || { echo "passes: $f does not cite vid-verify"; r=1; }; done
  case "$(flatq "$3")" in *"$STOP"*) ;; *) echo "passes: $3 lacks its loop's stop: $STOP"; r=1 ;; esac
  return $r
}
DV="$SKILLS/vid-develop/SKILL.md"; FX="$SKILLS/vid-fix/SKILL.md"
if [ -f "$DV" ]; then
  verify "$GP" "$VV" "$DV" "$FX" || exit 1
  T4=$(mktemp -d)
  grep -v '^ROW-<id> \[transition' "$GP" > "$T4/gp.md"
  if verify "$T4/gp.md" "$VV" "$DV" "$FX" >/dev/null; then rm -rf "$T4"; exit 1; fi
  { cat "$DV"; printf '\nbandwagon effects run >70%%\n'; } > "$T4/dv.md"
  if verify "$GP" "$VV" "$T4/dv.md" "$FX" >/dev/null; then rm -rf "$T4"; exit 1; fi
  sed 's#skills/vid-verify/SKILL\.md#skills/vid-other/SKILL.md#g' "$FX" > "$T4/fx.md"
  if verify "$GP" "$VV" "$DV" "$T4/fx.md" >/dev/null; then rm -rf "$T4"; exit 1; fi
  sed 's/halt the loop and escalate/keep looping/' "$DV" > "$T4/dv2.md"
  if verify "$GP" "$VV" "$T4/dv2.md" "$FX" >/dev/null; then rm -rf "$T4"; exit 1; fi
  rm -rf "$T4"
fi

# --- v0.9.7.0.6 (3.3, R6; §6 B-1): develop names the watcher's gate, at its start and at every resume
# (plugin repository only). Polarity: a develop without it is convicted. v0.9.7.0.9 (3.8, R12): develop
# starts the watcher itself — `sh checks/observe.sh start`, then the gate — at its start and at every resume.
gate() { r=0
  sed -n '/^## Before any work/,/^## /p' "$1" | tr '\n' ' ' | tr -s ' ' | grep -qF 'then `sh checks/observe.sh alive`' || { echo "passes: $1 does not run the watcher's gate before any work"; r=1; }
  sed -n '/^## Resume/,/^\*\*Record the dataset/p' "$1" | tr '\n' ' ' | tr -s ' ' | grep -qF '`sh checks/observe.sh alive`' || { echo "passes: $1 does not run the watcher's gate at resume"; r=1; }
  sed -n '/^## Before any work/,/^## /p' "$1" | tr '\n' ' ' | tr -s ' ' | grep -qF 'run `sh checks/observe.sh start`' || { echo "passes: $1 does not start the watcher before any work"; r=1; }
  sed -n '/^## Resume/,/^\*\*Record the dataset/p' "$1" | tr '\n' ' ' | tr -s ' ' | grep -qF 'start the watcher, `sh checks/observe.sh start`' || { echo "passes: $1 does not start the watcher at resume"; r=1; }
  tr '\n' ' ' < "$1" | tr -s ' ' | grep -qF 'run: stopped the watcher is not running' || { echo "passes: $1 does not record the watcher's stop"; r=1; }
  return $r; }
if [ -f "$DV" ]; then
  gate "$DV" || exit 1
  T5=$(mktemp -d); sed 's/observe\.sh alive/observe.sh resume/g' "$DV" > "$T5/dv.md"
  if gate "$T5/dv.md" >/dev/null; then rm -rf "$T5"; exit 1; fi
  sed 's/observe\.sh start/observe.sh resume/g' "$DV" > "$T5/dv.md"
  if gate "$T5/dv.md" >/dev/null; then rm -rf "$T5"; exit 1; fi
  rm -rf "$T5"
fi

# --- v0.9.7.0.6 (3.5, R9; §6 phase D): develop and fix invoke vid-test-manager and vid-verify as
# skills (Claude Code restores after a compaction only the skills invoked), and develop no longer
# names the test manager by its file. Plugin repository only. Polarity: a fix without the line is convicted.
INV='invoke the `vid-test-manager`, `vid-verify` and `vid-build` skills (the Skill tool)'
invoke() { r=0; for f in "$@"; do tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$INV" || { echo "passes: $f does not invoke the internal skills as skills"; r=1; }; done
  grep -qF 'Its rules are `${CLAUDE_PLUGIN_ROOT}/skills/vid-test-manager/SKILL.md`' "$1" && { echo "passes: $1 still names the test manager by its file"; r=1; }
  return $r; }
if [ -f "$DV" ]; then
  invoke "$DV" "$FX" || exit 1
  T6=$(mktemp -d); sed 's/(the Skill tool)/(read their files)/' "$FX" > "$T6/fx.md"
  if invoke "$DV" "$T6/fx.md" >/dev/null; then rm -rf "$T6"; exit 1; fi
  rm -rf "$T6"
fi

# --- v0.9.7.0.7 (3.1, R1, R2; §6 phase A): develop's build text moved into vid-build word for word
# (plugin repository only). The base is checks/selftest/fixtures/develop-build-text.md: develop's
# design transcription law and steps 0–6 at 2a8d4dc (lines 66–86 and 219–317, a blank line between),
# checked against that commit whenever this repository holds it. vid-build's two sections, their
# headings dropped and the named edits undone (step 1's run-manager sentence removed, step 1b's
# "the run manager's to RUN" read back as "yours to RUN", v0.9.8.1 R3: step 5's dirty-law exception read back
# as its old three lines; v0.26.10.2 R17: step 6's three lines on module labels removed; v0.9.8.1 R18: the design law's "a ledger test file per screen" and "surface test" read
# back as "one ledger test for every screen" and "per-screen test"), equal it line for line; the edits, the
# builder's frame and the hand-back (v0.9.7.1 R4: the agent writes no `agent:` line) are present; the
# hand-back's heading may carry its version; vid-build is internal. No line of the base longer
# than 30 characters is left in develop or fix; develop carries the two pointers; fix names vid-build's
# file. Polarity: a word changed in vid-build, a moved line left in develop, and a fix without
# vid-build's file are each convicted.
BASE="$CHECKS/selftest/fixtures/develop-build-text.md"
E1='   The test-author pass, the `prove-red` request and the law commit are
   the run manager'"'"'s; a builder that needs them hands back `law-needed`
   (B3).'
# v0.9.8.1 (R3): a third named edit — step 5's dirty-law exception — undone the same way (lines 2 on, the first unchanged)
E3N='   and the inventory court judge what the commit stages, never the rest of
   the working tree (v0.9.6 3.12) — uncommitted product work elsewhere
   cannot fail an unrelated commit. One exception (v0.9.8.1 R3): law files
   (`checks/`, `design/`, the files `checks/lawfiles` names) edited but not
   staged refuse every commit, because the courts run from the working
   tree. The refusal names them; commit them first as their own law
   commit, or set them aside with a WIP commit (on a side branch, never a
   stash) and bring them back after. Its'
E3O='   and the inventory court judge what the commit stages, never the rest of
   the working tree (v0.9.6 3.12) — uncommitted work elsewhere cannot fail
   an unrelated commit, so never stash or park work to get one through. Its'
# v0.26.10.2 (R17e): a fourth named edit — step 6's module labels, three lines of their own — removed the same way
E4='   A decision that bears on one module, or a few, names their module ids
   in its `applies-to:` label, beside its row, requirement or screen
   items, never instead of them (v0.26.10.2 R17).'
P1='The design transcription law: `vid-build`.'
P2='Building a step — steps 0–6: `vid-build` (`${CLAUDE_PLUGIN_ROOT}/skills/vid-build/SKILL.md`).'
FRAME='A builder or fixer lands no law — no line in the regions `checks/lawfiles` names, no PRD change, nothing under checks/, no weakened ledger test, no protected design/ change, no DEPLOYMENT.md change — and hands it back instead.'
HANDB='Law you needed and did not land is a `not` line whose reason begins `law-needed:`. Write no `agent:` line: the run manager adds your agent id.'
buildtext() { # $1=vid-build $2=vid-develop $3=vid-fix
  r=0
  printf '%s\n' "$E3N" > "$TB/e3n"; printf '%s\n' "$E3O" > "$TB/e3o"
  awk '/^## The design transcription law$/ { on = 1; skip = 1; next } /^## The hand-back( |$)/ { on = 0 }
    /^## Building a step — steps 0–6$/ { skip = 1; next }
    on { if (skip && $0 == "") { skip = 0; next } skip = 0; print }' "$1" | sed '$ { /^$/d; }' > "$TB/moved"
  grep -vxF -e "$(printf '%s\n' "$E1" | sed -n 1p)" -e "$(printf '%s\n' "$E1" | sed -n 2p)" -e "$(printf '%s\n' "$E1" | sed -n 3p)" \
    -e "$(printf '%s\n' "$E4" | sed -n 1p)" -e "$(printf '%s\n' "$E4" | sed -n 2p)" -e "$(printf '%s\n' "$E4" | sed -n 3p)" "$TB/moved" \
    | sed -e 's/the ritual is the run manager'"'"'s to RUN\./the ritual is yours to RUN./' \
        -e 's/^instrument is the fidelity evidence\*\* (v0\.9\.2 3\.4, R7, R20): a ledger$/instrument is the fidelity evidence** (v0.9.2 3.4, R7, R20): one ledger/' \
        -e 's/^test file per screen (v0\.9\.8\.1 R18), the surface test-author pass'"'"'s product, mapping$/test for every screen, the surface test-author pass'"'"'s product, mapping/' \
        -e 's/^surface test or a pins hook\*\* — a screen'"'"'s case is red until the$/per-screen test or a pins hook** — a screen'"'"'s case is red until the/' \
    | awk -v nf="$TB/e3n" -v of="$TB/e3o" 'BEGIN { while ((getline l < nf) > 0) N[++k] = l; while ((getline l < of) > 0) O[++ko] = l } { L[NR] = $0 }
        END { for (i = 1; i <= NR; i++) { m = 1; for (j = 2; j <= k; j++) if (L[i + j - 2] != N[j]) { m = 0; break }
            if (m) { print O[2]; print O[3]; i += k - 2; continue } print L[i] } }' > "$TB/undone"
  cmp -s "$TB/undone" "$BASE" || { echo "passes: $1 does not hold develop's build text word for word: $(diff "$BASE" "$TB/undone" | sed -n 2p)"; r=1; }
  case "$(tr '\n' ' ' < "$1" | tr -s ' ')" in *"$(printf '%s\n' "$E1" | tr '\n' ' ' | tr -s ' ' | sed 's/ $//')"*) ;; *) echo "passes: $1 lacks step 1's run-manager sentence"; r=1 ;; esac
  grep -qF "the ritual is the run manager's to RUN." "$1" || { echo "passes: $1 lacks step 1b's run manager"; r=1; }
  case "$(tr '\n' ' ' < "$1" | tr -s ' ')" in *"$(printf '%s\n' "$E4" | tr '\n' ' ' | tr -s ' ' | sed 's/ $//')"*) ;; *) echo "passes: $1 lacks step 6's module labels"; r=1 ;; esac
  grep -qF 'set them aside with a WIP commit (on a side branch, never a' "$1" || { echo "passes: $1 lacks step 5's dirty-law exception"; r=1; }
  grep -qF 'test file per screen (v0.9.8.1 R18), the surface test-author' "$1" || { echo "passes: $1 lacks the design law's file per screen"; r=1; }
  for l in "$FRAME" "$HANDB"; do case "$(tr '\n' ' ' < "$1" | tr -s ' ')" in *"$l"*) ;; *) echo "passes: $1 lacks, word for word: $l"; r=1 ;; esac; done
  grep -q '^user-invocable: false$' "$1" || { echo "passes: $1 is not internal (user-invocable: false)"; r=1; }
  awk 'length($0) > 30' "$BASE" > "$TB/long"
  for f in "$2" "$3"; do grep -xFf "$TB/long" "$f" > /dev/null && { echo "passes: $f still holds the moved text: $(grep -xFf "$TB/long" "$f" | head -n 1)"; r=1; }; done
  for l in "$P1" "$P2"; do grep -qxF -- "$l" "$2" || { echo "passes: $2 lacks the pointer: $l"; r=1; }; done
  grep -qF 'skills/vid-build/SKILL.md' "$3" || { echo "passes: $3 does not name vid-build's file"; r=1; }
  return $r; }
if [ -f "$DV" ]; then
  TB=$(mktemp -d)
  if git -C "$CHECKS/.." cat-file -e 2a8d4dc:skills/vid-develop/SKILL.md 2>/dev/null; then
    { git -C "$CHECKS/.." show 2a8d4dc:skills/vid-develop/SKILL.md | sed -n '66,86p'; echo; git -C "$CHECKS/.." show 2a8d4dc:skills/vid-develop/SKILL.md | sed -n '219,317p'; } > "$TB/base"
    cmp -s "$TB/base" "$BASE" || { echo "passes: $BASE is not develop's text at 2a8d4dc"; rm -rf "$TB"; exit 1; }
  fi
  VBF="$SKILLS/vid-build/SKILL.md"
  [ -f "$VBF" ] || { echo "passes: no vid-build skill"; rm -rf "$TB"; exit 1; }
  buildtext "$VBF" "$DV" "$FX" || { rm -rf "$TB"; exit 1; }
  sed 's/Elapsed time is not evidence of progress/Elapsed time is little evidence of progress/' "$VBF" > "$TB/vb.md"
  if buildtext "$TB/vb.md" "$DV" "$FX" >/dev/null; then rm -rf "$TB"; exit 1; fi
  { cat "$DV"; sed -n 30p "$BASE"; } > "$TB/dv.md"
  if buildtext "$VBF" "$TB/dv.md" "$FX" >/dev/null; then rm -rf "$TB"; exit 1; fi
  sed 's#skills/vid-build/SKILL\.md#skills/vid-other/SKILL.md#g' "$FX" > "$TB/fx.md"
  if buildtext "$VBF" "$DV" "$TB/fx.md" >/dev/null; then rm -rf "$TB"; exit 1; fi
  rm -rf "$TB"
fi

# --- v0.9.7.0.7 (3.5, R9): develop's planning paragraph carries the step-size advice, word for word,
# with no number in it (plugin repository only). Polarity: a develop without it is convicted.
ADVICE='Size each builder step as a modular unit: rows whose tests exercise the same modules and share their setup, so one builder can make them pass together without holding the rest of the product. Not so big that the builder spends its context finding its way before it changes anything; not so small that the cost of starting an agent and writing its brief dominates. Within that, choose the grouping most likely to pass whole at the hand-back. The `build-cost` lines in the progress table show what your past steps cost and how many of their rows passed; use them.'
advice() { tr '\n' ' ' < "$1" | tr -s ' ' | grep -qF -- "$ADVICE" || { echo "passes: $1 lacks the step-size advice"; return 1; }
  printf '%s' "$ADVICE" | grep -q '[0-9]' && { echo 'passes: the step-size advice carries a number'; return 1; }; return 0; }
if [ -f "$DV" ]; then
  advice "$DV" || exit 1
  T7=$(mktemp -d); sed 's/rows whose tests exercise the same modules/rows of any kind/' "$DV" > "$T7/dv.md"
  if advice "$T7/dv.md" >/dev/null; then rm -rf "$T7"; exit 1; fi
  rm -rf "$T7"
fi

# --- a scratch tree seeding every violation must be convicted, each named ---
T=$(mktemp -d); trap 'rm -rf "$T" "${C:-}"' EXIT
mkdir -p "$T/skills/alpha/passes" "$T/skills/beta/passes"
printf '%s\n' "$HEADER" > "$T/skills/alpha/passes/good.md"
printf '%s\n\n# good\n\nbody\n' "$HEADER" > "$T/skills/alpha/passes/good.md"
printf '%s\n\n# orphan\n' "$HEADER" > "$T/skills/alpha/passes/orphan.md"
printf 'Spawned as a helper with the build context.\n\n# bare\n' > "$T/skills/beta/passes/bare.md"
printf 'chain: spawn `passes/good.md`; spawn `passes/missing.md`.\n' > "$T/skills/alpha/SKILL.md"
printf 'chain: spawn `passes/bare.md`; also `skills/alpha/passes/good.md`.\n' > "$T/skills/beta/SKILL.md"
OUT=$(check "$T/skills" 2>&1) && exit 1          # a passing verdict on the seeded tree is failure
printf '%s\n' "$OUT" | grep -q 'names passes/missing.md but no such file' || exit 1
printf '%s\n' "$OUT" | grep -q 'orphan.md is named by no chain' || exit 1
printf '%s\n' "$OUT" | grep -q 'bare.md does not open with the independence header' || exit 1
printf '%s\n' "$OUT" | grep -q 'good.md' && exit 1   # the clean brief is never named
exit 0
