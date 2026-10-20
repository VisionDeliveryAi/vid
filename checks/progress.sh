#!/bin/sh
# Purpose: ViD develop's progress update (v0.9.6 spec 3.15, R15) — one fixed
# table, computed from records; the format is ViD's, never the model's. It
# reads the plan block, the receipts (checks/evidence.sh, "current" as spec
# 3.3), the row engine's owed, held and `later` rows, the open `Q<n>` lines,
# the live run folders and the events. Nothing in it is written by the
# model but `now:` (RUN-STATE, one line, `--now`).
#   Passing (v0.9.7.2 3.6: was "Done", which now means a step's computed
#           done) the steps passing (every row passing, owed, held or later), by
#           name, and the rows passing; v0.9.6.1 (3.3): of them, the rows
#           claimed on a selected close that no checkpoint or full run has
#           yet run whole, counted apart as provisional (metrics.sh
#           provisional).
#   Now     each started step not yet passing: `<name> (<lane>): x of y rows
#           passing`.
#   Left    the steps not started; the rows not yet passing — red (failing),
#           not re-run since a rule or test change (v0.9.8.1 R8, R37: stale —
#           after a test edit or an amendment — apart from red, and left out
#           of the rate), never run (no case in any valid
#           receipt), not in the plan (in no step) — and blocked rows (owed
#           now, or held for the owner), counted as completion counts them
#           but never estimated. Deploy-owed and `later` rows are apart.
#   Tests   environments busy (live run folders) of .vid/budget stacks, and
#           the newest receipt's red by where it stops (evidence.sh red);
#           v0.9.6.1 (3.8): `checkpoint due n=<1|2> built=<b> plan=<p>` when
#           one is due and not yet run (metrics.sh checkpoint).
#   Builders v0.9.7.0.7 (3.5, R9): from the `build-cost` events, `<n> handed
#           back · rows passed <k> of <r> · before first change: median <t>
#           (<u> unknown)` — the median of the known before-change values
#           (a ` shell` one counts as its number; of an even count, the lower
#           middle); "none yet" with no event. v0.9.7.0.9 (3.6, R9): then
#           ` · lanes: builder <n> · run manager <m>` — the steps with a
#           step-start, by their lane in the plan (builder or absent; else
#           the run manager).
#           v0.9.7.1 (3.11, R11): the Builders line counts role=builder|fixer
#           only; a line per other role with a recorded cost (Graders, Test
#           authors, Test analysts: returned, tokens summed). (3.9, R9): once a
#           cost carries tool=, a `By builder tool` line — per tool, steps,
#           follow-up briefs, rows passed at hand-back, of them kept and
#           breached since (latest verdict), law-needed lines, early hand-backs
#           (a `not | none` line while a ticket of the attempt still ran) and
#           court refusals at commit (.vid/hook-times by worktree); v0.9.7.3 (3.9, R9): then builders, each agent
#           id once (a resumed background builder records a second agent-start). (3.9a, R14):
#           an open takeover on its own line.
#   Your questions, Estimate, Plan changes since the last update, Now (the
#           build's own words).
# v0.26.10.5 (R6): with STAGES.md, a first row `Stage` — the current stage of all, its name, and the stages closed.
# v0.9.7.2 (3.5, 3.8, 3.10, 3.11; R12, R14, R15) — read from `sh checks/metrics.sh step-state --all` (on the states
# and held rows read once, below) and row-state --table's verdict columns:
#   Debt    one line on every print, each row once: `<n> rows owed — in hardening, not done <a> · passing, not KEPT
#           <b> (never graded <b1> · product breach <b2> · test or harness breach <b3> · journey part-graded <b4> ·
#           re-grade after amendment <b5>) · held <h> (with their questions: …) · deferred open <d>` — n the union of
#           a, b, h and d, the parts overlapping as they are; passing by checks/evidence.sh, verdicts by vstate93;
#           under depth first `<b> rows owed — passing, not KEPT <b> (…)` only. The headline adds ` · debt <n>`.
#   Closed, not graded   under breadth first, the steps closed whose rows are not all graded (their dependents wait:
#           the graded gate), with the catch-up command.
#   Hardening   under breadth first, once every feature step is done: `<n> rows in <k> steps` not done.
#   Rows passing   for each feature step with `step-rows-passing`: closed, the gap to its first step-closed after
#           it (includes regression checks); open, the wait so far. A step closed only before its rows were seen
#           passing is left out: the time is when they were seen, so it has no gap.
#   Builders at once   `<now> open · target <t|none> · last 6 h average <x>`: builder and fixer agents (agent-start
#           to agent-stop, type vid:builder or vid:fixer) and Codex jobs (job-start to job-exit or job-stop; a job
#           whose latest event is job-recovery-required stays open), each clipped to the 6 hours; `open` because a
#           job's interval includes its launch. The target is .vid/budget's `builders-target=`, the owner's, shown only.
# v0.9.7.3 (3.5, R5): Refused commits   when any: `<n> — <court> <k> (<rule> <j>, …) · …`, from the `court-refused`
#           events (rule `-` where the court printed no machine line).
# v0.9.8 (3.2, R13): Test state   after Tests, always: `written <w> · passing <p> · proven <v>, of <n> rows`
#           — checks/metrics.sh test-state's counts, derived from the proofs and the evidence; shown here only.
# v0.9.7.1 (3.10, R10): the held rows and the states at HEAD are read once and handed to metrics.sh's provisional
# and checkpoint (VID_EVIDENCE_STATES, VID_EVIDENCE_HELD); the two earlier readings the rate needs run side by side;
# checks/evidence.sh reads each record once and git once per kind. The output is 0.9.7.0.12's (case progress-parity).
#   The estimate: P(t) is the rows passing on the receipts published by t,
#   judged at the commit HEAD was at t; the rate over a window w is (P(now)
#   − P(now − w)) / w, for w = 3 h and w = the time since develop's first
#   valid receipt (the first at or after its first stage start); the red, never-run and not-in-the-plan rows divided by each
#   positive rate make the range (v0.26.10.3 R7: the stale rows leave it — re-runs, not build work; a line says
#   "Not in the estimate: S to re-run; of the passing, C to confirm", and with only stale rows left the estimate
#   says "nothing left to build"). One positive rate: one number, its window
#   named. Neither: "no estimate: no rows turned green in the last 3 h".
#   Fewer than two valid receipts: "no estimate yet". The slice-close full
#   runs and grading are not included, and it says so.
#   --record appends the table to .vid/PROGRESS.md (created on first use),
#   writes `progress trigger=<hourly|plan-change|session> by=<observer|session>
#   rows-passing=<n> rows-left=<n> estimate=<lo>-<hi>|none` and prints only
#   the headline: `<project>: <P> of <T> rows passing · step <x> of <y> ·
#   <estimate>` (x the steps passing, y the steps). checks/observe.sh runs
#   it hourly and after a plan change (`--record --trigger … --by observer`).
# VID_PROGRESS_AT=<UTC> computes the update as of that moment — the rate's
# windows end there — for replaying past records; the default is now.
# Inside a 0.9.6 develop run only (checks/plan.sh gate); run at the home.
# Usage: sh checks/progress.sh [--record] [--trigger hourly|plan-change|session] [--by observer|session] [--now "<line>"]
set -u
IFS='
'
REC=no; TRIG=session; BY=session; NOWL=''; SETNOW=no
while [ $# -gt 0 ]; do
  case "$1" in
    --record) REC=yes; shift ;;
    --trigger) TRIG=${2:-}; shift 2 ;;
    --by) BY=${2:-}; shift 2 ;;
    --now) NOWL=${2:-}; SETNOW=yes; shift 2 ;;
    *) echo 'ViD progress: usage — sh checks/progress.sh [--record] [--trigger hourly|plan-change|session] [--by observer|session] [--now "<line>"]' >&2; exit 2 ;;
  esac
done
case "$TRIG" in hourly|plan-change|session) ;; *) echo 'ViD progress: --trigger is hourly, plan-change or session' >&2; exit 2 ;; esac
case "$BY" in observer|session) ;; *) echo 'ViD progress: --by is observer or session' >&2; exit 2 ;; esac
G=$(sh checks/plan.sh gate 2>/dev/null || true)
case "$G" in 'on '*) H=${G#on } ;; *) echo "ViD progress: no update — not inside a develop run under a 0.9.6 plan (${G#off })."; exit 0 ;; esac
cd "$H" || exit 1
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT
EV=.vid/metrics-events; RS=.vid/RUN-STATE.md
if [ "$SETNOW" = yes ]; then
  case "$NOWL" in *'
'*) echo 'ViD progress: now: is one line' >&2; exit 2 ;; esac
  if grep -q '^now:' "$RS"; then awk -v n="now: $NOWL" '/^now:/ && !d { print n; d = 1; next } { print }' "$RS" > "$T/rs"
  else awk -v n="now: $NOWL" '{ print } /^plan:/ && !d { print n; d = 1 }' "$RS" > "$T/rs"; grep -q '^now:' "$T/rs" || { cat "$RS"; echo "now: $NOWL"; } > "$T/rs"; fi
  cat "$T/rs" > "$RS"
fi
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" } function bkv(h,   i, s, j) { i = index($0, " brief="); if (!i) return ""; s = substr($0, i + 7); j = match(s, / [a-z][a-z-]*=/); if (j) s = substr(s, 1, j - 1); if (h != "" && index(s, h "/") == 1) s = substr(s, length(h) + 2); return s }
function ep(t,  y, m, d, H, M, S) { y = substr(t, 1, 4) + 0; m = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0; H = substr(t, 12, 2) + 0; M = substr(t, 15, 2) + 0; S = substr(t, 18, 2) + 0
  if (m <= 2) { y--; m += 12 } return (365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d - 719469) * 86400 + H * 3600 + M * 60 + S }'
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
sh checks/plan.sh parse > "$T/parsed" 2>"$T/err" || { cat "$T/err" >&2; echo 'ViD progress: the plan block does not hold — no update.' >&2; exit 1; }
sh checks/plan.sh map --all > "$T/map" 2>/dev/null || { echo 'ViD progress: no currency map.' >&2; exit 1; }
# v0.9.7.3 (3.5, R5): Refused commits   when any: `<n> — <court> <k> (<rule> <j>, …) · …`, from the `court-refused`
#           events (rule `-` where the court printed no machine line).
# v0.9.7.1 (3.10, R10): the held rows and the states at HEAD are read once and shared — with the earlier passes'
# readings and with metrics.sh's provisional and checkpoint, which read the same map at HEAD
if [ -f checks/metrics.sh ]; then sh checks/metrics.sh row-state --table > "$T/table93" 2>/dev/null || : > "$T/table93"; else : > "$T/table93"; fi
awk -F'\t' 'NF >= 9 && $5 != "-" { print $1 }' "$T/table93" > "$T/held"
VID_EVIDENCE_HELD=$T/held; export VID_EVIDENCE_HELD
sh checks/evidence.sh rows --at HEAD --map "$T/map" ${VID_EVIDENCE_LEGACY:+--legacy} > "$T/states" || { echo 'ViD progress: the evidence could not be read.' >&2; exit 1; }
[ -n "${VID_EVIDENCE_LEGACY:-}" ] || { VID_EVIDENCE_STATES=$T/states; export VID_EVIDENCE_STATES; }
[ -f "$EV" ] || : > "$EV"
awk "$AWKAT"' $1 == "step-start" { print kv("step") }' "$EV" | sort -u > "$T/started"
# the valid receipts, with their times (for the rate), and the newest
awk "$AWKAT"' $1 == "invalidated" && kv("report") != "" { inv[kv("report")] = 1; next }
  $1 == "ledger-run" && kv("report") != "" && kv("report") != "none" && !index(kv("report"), ".proof.") { n++; R[n] = kv("report"); A[n] = lastat(); K[n] = kv("kind") }
  END { for (i = 1; i <= n; i++) if (!(R[i] in inv) && A[i] != "") print A[i] "\t" R[i] "\t" K[i] }' "$EV" | sort > "$T/rcpts.raw"
: > "$T/rcpts"; while IFS='	' read -r a r k; do [ -f ".vid/ledger-results/$r" ] && printf '%s\t%s\t%s\n' "$a" "$r" "$k" >> "$T/rcpts"; done < "$T/rcpts.raw"
NRC=$(grep -c . "$T/rcpts" || true)
NOWE=$(date +%s); NOWU=$(utc)
if [ -n "${VID_PROGRESS_AT:-}" ]; then NOWU=$VID_PROGRESS_AT; NOWE=$(printf '%s\n' "$NOWU" | awk "$AWKAT"' { print ep($0) }'); fi
# P(t): rows passing on the receipts published by t, at the commit HEAD was at t
# v0.9.8.1 (R8, F-6): a row stale now (run before, not on the current tests or row) is left out of both ends of the
# rate — it was passing then and is not now only because its test or row changed, which is no going backward
passing_at() { # $1=UTC
  _c=$(git rev-list -1 --before="$1" HEAD 2>/dev/null || true)
  [ -n "$_c" ] || { echo 0; return; }
  sh checks/evidence.sh rows --at "$_c" --map "$T/map" --until "$1" ${VID_EVIDENCE_LEGACY:+--legacy} 2>/dev/null |
    awk -F'\t' -v sf="$T/states" 'BEGIN { while ((getline l < sf) > 0) { split(l, a, "\t"); if (a[2] == "stale") S[a[1]] = 1 } } $2 == "pass" && !($1 in S) { n++ } END { print n + 0 }'
}
utc_of() { awk -v e="$1" 'BEGIN { d = int(e / 86400); s = e - d * 86400; z = d + 719468; era = int(z / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
  mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); if (m <= 2) y++
  printf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", y, m, dd, int(s / 3600), int((s % 3600) / 60), s % 60 }'; }
# the numbers
eval "$(awk -F'\t' -v pf="$T/parsed" -v sf="$T/started" '
  BEGIN { while ((getline l < pf) > 0) { split(l, a, "\t"); if (a[1] == "step") { ns++; S[ns] = a[2]; NM[a[2]] = a[3]; LN[a[2]] = a[6] } if (a[1] == "row") RSTEP[a[2]] = a[3] }
    while ((getline l < sf) > 0) ST[l] = 1 }
  FILENAME == ARGV[1] { MSTEP[$1] = $2; next }
  { st = $2; id = $1; inplan = (id in RSTEP)
    if (st == "deploy-owed") { dep++; next } if (st == "later") { lat++; next }
    tot++
    if (st == "pass") P++
    if (st == "owed") { blk++; bo++ } else if (st == "held") { blk++; bh++ }
    else if (st != "pass") { if (!inplan) nip++; else if (st == "never") nev++; else if (st == "stale") stl++; else red++ }   # v0.9.8.1 (R8): stale apart from red
    if (inplan) { s = RSTEP[id]; SR[s]++; if (st == "pass") SP[s]++; if (st == "pass" || st == "owed" || st == "held") SOK[s]++ } }
  END {
    for (i = 1; i <= ns; i++) { s = S[i]; if (SOK[s] + 0 == SR[s] + 0) { np++; done = done (done == "" ? "" : "; ") NM[s] } }
    for (i = 1; i <= ns; i++) { s = S[i]; if (SOK[s] + 0 == SR[s] + 0) continue
      if (s in ST) now = now (now == "" ? "" : " · ") NM[s] " (" (LN[s] == "-" ? "unassigned" : LN[s]) "): " SP[s] + 0 " of " SR[s] + 0 " rows passing"
      else { nns++; notst = notst (notst == "" ? "" : "; ") NM[s] } }
    q = "\047"
    printf "NSTEPS=%d NPASS=%d P=%d TOT=%d RED=%d STL=%d NEV=%d NIP=%d BLK=%d BO=%d BH=%d DEP=%d LAT=%d NNS=%d\n", ns, np, P, tot, red, stl, nev, nip, blk, bo, bh, dep, lat, nns
    gsub(q, q "\\" q q, done); gsub(q, q "\\" q q, now); gsub(q, q "\\" q q, notst)
    printf "DONE=%s%s%s\nNOWS=%s%s%s\nNOTST=%s%s%s\n", q, done, q, q, now, q, q, notst, q }' "$T/map" "$T/states")"
LEFT=$((RED + STL + NEV + NIP + BLK)); EST=$((RED + NEV + NIP))   # v0.26.10.3 (R7): stale rows are re-runs, not build work
# v0.9.7.1 (3.10, R10): the two earlier readings the rate needs run side by side, while the rest is computed
if [ "$NRC" -ge 2 ] && [ "$EST" -ne 0 ]; then
  # develop's first valid receipt: the first at or after develop's first stage start
  DEV0=$(awk "$AWKAT"' $1 == "stage" && kv("name") == "develop" && kv("state") == "start" { a = lastat(); if (a != "" && (m == "" || a < m)) m = a } END { print m }' "$EV")
  T0=$(awk -F'\t' -v d="$DEV0" '$1 >= d { print $1; exit }' "$T/rcpts"); [ -n "$T0" ] || T0=$(head -n 1 "$T/rcpts" | cut -f1)
  ( passing_at "$(utc_of $((NOWE - 10800)))" > "$T/p3" ) & PJ3=$!
  ( passing_at "$T0" > "$T/pa" ) & PJA=$!
fi
# Done, Now, Left
DONEL="$NPASS of $NSTEPS steps passing${DONE:+: $DONE}. $P rows passing"
NPROV=$(sh checks/metrics.sh provisional 2>/dev/null | sed -n 's/^provisional rows=\([0-9][0-9]*\)$/\1/p')
[ "${NPROV:-0}" -gt 0 ] && DONEL="$DONEL ($NPROV provisional: claimed on a selected close, not yet run whole by a checkpoint or the full run)"
NOWLN=${NOWS:-no step in progress}
if [ "$NNS" -eq 1 ]; then LEFTL="1 step not started: $NOTST."; elif [ "$NNS" -gt 1 ]; then LEFTL="$NNS steps not started: $NOTST."; else LEFTL='every step started.'; fi
LEFTL="$LEFTL $((RED + STL + NEV + NIP)) rows not yet passing ($RED red, $STL not re-run since a rule or test change, $NEV never run"
[ "$NIP" -gt 0 ] && LEFTL="$LEFTL, $NIP not in the plan"
LEFTL="$LEFTL)"
if [ "$BLK" -gt 0 ]; then
  LEFTL="$LEFTL; blocked: $BLK ("; _bl=''
  [ "$BO" -gt 0 ] && _bl="$BO owed on something not yet built or decided"
  [ "$BH" -gt 0 ] && _bl="${_bl:+$_bl, }$BH held for your answer"
  LEFTL="$LEFTL$_bl)"
fi
[ "$DEP$LAT" != 00 ] && LEFTL="$LEFTL. Apart: $DEP checked at deploy, $LAT later"
# Tests
STK=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' .vid/budget 2>/dev/null | head -n 1); STK=${STK:-1}
# v0.9.8.1 (R35, F-25): busy counts only runs holding a stack (their holder names its slot= or a ctx is frozen), the
# queue apart — a run waiting for a slot has its folder too
BUSY=0; for h in .vid/runs/*/holder; do [ -f "$h" ] || continue; p=$(sed -n 's/^pid=//p' "$h" | head -n 1); [ -n "$p" ] && kill -0 "$p" 2>/dev/null || continue
  { grep -q '^slot=' "$h" || [ -d "${h%/holder}/ctx" ]; } && BUSY=$((BUSY + 1)); done
QUEUED=0; for q in .vid/requests/*/state .vid/requests/*/chunks/*/state; do [ "$(cat "$q" 2>/dev/null)" = queued ] && QUEUED=$((QUEUED + 1)); done
QUEL=''; [ "$QUEUED" -gt 0 ] && QUEL=" · $QUEUED queued"
NEWEST=$(tail -n 1 "$T/rcpts" | cut -f2)
if [ -n "$NEWEST" ]; then
  RS_=$(sh checks/evidence.sh red "$NEWEST" 2>/dev/null | head -n 1)
  SETUP=$(printf '%s\n' "$RS_" | sed -n 's/.* setup=\([0-9]*\).*/\1/p'); FAILED=$(printf '%s\n' "$RS_" | sed -n 's/.* failed=\([0-9]*\).*/\1/p')
  TESTS="$BUSY of $STK environments busy$QUEL · red by where it stops: setup ${SETUP:-0}, failed ${FAILED:-0}"
else TESTS="$BUSY of $STK environments busy$QUEL · no receipt yet"; fi
CPD=$(sh checks/metrics.sh checkpoint 2>/dev/null | grep '^checkpoint due ' | head -n 1)
[ -n "$CPD" ] && TESTS="$TESTS · $CPD"
# Your questions
QL=$(awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' "$RS" | awk '/<!--/ { c = 1 } !c && /^- Q[0-9]+ · asked / { print } /-->/ { c = 0 }')
NQ=$(printf '%s\n' "$QL" | grep -c . || true)
if [ "$NQ" -gt 0 ]; then
  QS=$(printf '%s\n' "$QL" | sed 's/^- \(Q[0-9]*\) · asked [^ ]* · gates \([^·]*\) · \(.*\)$/\1: \3 (holds \2)/; s/ )$/)/' | tr '\n' ';' | sed 's/;$//; s/;/; /g')
  QUES="$NQ open — $QS"
else QUES='none open'; fi
# the estimate
LASTFULL=$(awk -F'\t' '$3 == "full" { a = $1 } END { print a }' "$T/rcpts")
NOTINC="Not included: the slice-close full runs and grading (last full run: ${LASTFULL:-none yet})"
# v0.26.10.3 (R7): what the estimate leaves out — the rows to re-run (stale) and, of the passing, the rows to confirm
# (checks/metrics.sh to-confirm); when only rows to re-run are left, nothing is left to build
TCP=$(sh checks/metrics.sh to-confirm 2>/dev/null | sed -n 's/^to-confirm row=\([^ ]*\) .*/\1/p' | awk -F'\t' 'NR == FNR { if ($2 == "pass") P[$1] = 1; next } ($1 in P) { n++ } END { print n + 0 }' "$T/states" -)
OUTL=''; [ $((STL + TCP)) -gt 0 ] && OUTL=" Not in the estimate: $STL to re-run; of the passing, $TCP to confirm."
ESTF=none; NONE0='nothing left to turn green'; [ "$STL" -gt 0 ] && NONE0='nothing left to build'
if [ "$NRC" -lt 2 ]; then ESTL="no estimate yet — fewer than two valid receipts. $NOTINC$OUTL"
elif [ "$EST" -eq 0 ]; then _bn=''; [ "$BLK" -gt 0 ] && _bn=" — blocked, not estimated: $BLK"; ESTL="$NONE0$_bn. $NOTINC$OUTL"; ESTF=0-0
else
  wait "$PJ3" "$PJA" 2>/dev/null || true
  P3=$(cat "$T/p3" 2>/dev/null); P3=${P3:-0}
  T0E=$(printf '%s\n' "$T0" | awk "$AWKAT"' { print ep($0) }')
  PA=$(cat "$T/pa" 2>/dev/null); PA=${PA:-0}; WA=$((NOWE - T0E)); [ "$WA" -gt 0 ] || WA=1
  G3=$((P - P3)); GA=$((P - PA))
  ESTL=$(awk -v est="$EST" -v g3="$G3" -v ga="$GA" -v wa="$WA" -v notinc="$NOTINC" -v blk="$BLK" 'BEGIN {
      r3 = g3 / 3; ra = ga / (wa / 3600); hrs = wa / 3600
      f = "%.1f"; n = 0
      if (r3 > 0) { e[++n] = est / r3; r[n] = r3 } if (ra > 0) { e[++n] = est / ra; r[n] = ra }
      basis = sprintf("(last 3 h: %d rows; since develop began: %d rows in %.1f h)", g3, ga, hrs)
      bl = (blk > 0 ? sprintf("; blocked, not estimated: %d", blk) : "")
      if (n == 0) { printf "no estimate: no rows turned green in the last 3 h %s. %s%s\n", basis, notinc, bl; print "ESTF=none" > "/dev/stderr"; exit }
      if (n == 1) { printf "%.1f h to the last row passing, at %.1f rows/hour (%s only) %s. %s%s\n", e[1], r[1], (r3 > 0 ? "the last 3 h" : "since develop began"), basis, notinc, bl; printf "ESTF=%.1f-%.1f\n", e[1], e[1] > "/dev/stderr"; exit }
      lo = (e[1] < e[2] ? e[1] : e[2]); hi = (e[1] < e[2] ? e[2] : e[1]); rl = (r[1] < r[2] ? r[1] : r[2]); rh = (r[1] < r[2] ? r[2] : r[1])
      printf "%.1f–%.1f h to the last row passing, at %.1f–%.1f rows/hour %s. %s%s\n", lo, hi, rl, rh, basis, notinc, bl
      printf "ESTF=%.1f-%.1f\n", lo, hi > "/dev/stderr" }' 2>"$T/estf")
  ESTF=$(sed -n 's/^ESTF=//p' "$T/estf"); ESTF=${ESTF:-none}
  ESTL="$ESTL$OUTL"
fi
# v0.9.7.0.7 (3.5): the builders' cost, from the build-cost events
BLD=$(awk "$AWKAT"' $1 == "build-cost" && (kv("role") == "builder" || kv("role") == "fixer") { n++; r += kv("rows"); k += kv("rows-passed"); b = kv("before-change"); if (b ~ /^[0-9]+$/) V[++nv] = b + 0; else u++ }
  END { if (!n) { print "none yet"; exit }
    for (i = 2; i <= nv; i++) { x = V[i]; j = i - 1; while (j >= 1 && V[j] > x) { V[j + 1] = V[j]; j-- } V[j + 1] = x }
    m = nv ? V[int((nv + 1) / 2)] : "none"
    printf "%d handed back · rows passed %d of %d · before first change: median %s (%d unknown)\n", n, k, r, m, u }' "$EV")
# v0.9.7.1 (3.11, R11): a line per other role with a recorded cost — returns, and their tokens summed
ROLEL=$(awk "$AWKAT"' $1 == "build-cost" { r = kv("role"); if (r == "builder" || r == "fixer" || r == "") next; if (!(r in N)) O[++no] = r; N[r]++; t = kv("total"); if (t ~ /^[0-9]+$/) T[r] += t; else U[r]++ }
  END { for (i = 1; i <= no; i++) { r = O[i]; nm = (r == "grader") ? "Graders" : (r == "test-author") ? "Test authors" : (r == "test-analyst") ? "Test analysts" : r; printf "%s\t%d returned · tokens %d (%d unknown)\n", nm, N[r], T[r], U[r] + 0 } }' "$EV")
# v0.9.7.1 (3.9, R9, R11): by builder tool, once a cost record carries tool= — the pilot's counts, each read from the records:
# steps and briefs (the follow-up cycles are briefs beyond the first per step), rows passed at hand-back, of those the
# rows whose latest verdict is KEPT and those since BREACHED (later breakage), law-needed lines, hand-backs naming no
# receipt while one of the attempt's tickets still ran, and court refusals at commit (.vid/hook-times by worktree)
BYT=''
if grep -q '^build-cost .* tool=' "$EV"; then
  # v0.9.8.1 (R7, F-1; the live project's A-272): brief= up to the next field, its home prefix removed — an older
  #   record's absolute path in a home whose path holds a space is read whole, never cut and counted as no row
  awk -v h="$(pwd -P)" "$AWKAT"' $1 == "build-cost" && (kv("role") == "builder") { t = kv("tool"); if (t == "") t = "claude"; print bkv(h) "\t" t "\t" kv("step") "\t" kv("rows-passed") }' "$EV" > "$T/bt"
  awk "$AWKAT"' $1 == "verdict" && kv("row") != "" { V[kv("row")] = kv("result") } END { for (r in V) print r "\t" V[r] }' "$EV" > "$T/lv"
  : > "$T/btl"
  while IFS='	' read -r b tl st rp; do
    rf=${b%.md}.return.md; [ -f "$rf" ] || { printf '%s\tM\t%s\n' "$tl" "$rf" >> "$T/btl"; continue; }   # v0.9.8.1 (R7): said, never 0
    try=$(sed -n '1,14s/^try:[[:space:]]*//p' "$b" 2>/dev/null | head -n 1)
    late=0
    if [ -n "$try" ]; then for r in .vid/requests/*/request; do grep -qx "try=$try" "$r" 2>/dev/null || continue; e=${r%/request}/exit; [ -f "$e" ] && [ "$e" -nt "$rf" ] && late=1; done; fi
    awk -F'|' -v tl="$tl" -v late="$late" 'function tr(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x } tr($1) ~ /^ROW-/ { s = tr($2); r = tr($3); w = tr($4)
        if (s == "pass") print tl "\tP\t" tr($1); else if (index(w, "law-needed:") == 1) print tl "\tL\t" tr($1); if (s == "not" && r == "none" && late) print tl "\tE\t" tr($1) }' "$rf" >> "$T/btl"
  done < "$T/bt"
  { ls .vid/jobs 2>/dev/null | sed -n 's/\.wt$//p'; } > "$T/cxwt"
  # v0.9.7.3 (3.9, R9): the builders by tool, each counted once — distinct agent ids of vid:builder agent-starts
  # (a resumed background builder starts twice), distinct tries of Codex job-starts
  awk "$AWKAT"' $1 == "agent-start" && kv("type") == "vid:builder" && kv("agent") != "" { a = kv("agent"); if (!(a in S)) { S[a] = 1; print "claude" } }
    $1 == "job-start" && kv("try") != "" { a = kv("try"); if (!(("job", a) in S)) { S["job", a] = 1; print "codex" } }' "$EV" > "$T/bag"
  BYT=$(awk -F'\t' -v T="$T" 'BEGIN { while ((getline l < (T "/lv")) > 0) { split(l, a, "\t"); V[a[1]] = a[2] } while ((getline l < (T "/cxwt")) > 0) CX[l ".wt"] = 1
      while ((getline l < (T "/bag")) > 0) AG[l]++
      while ((getline l < (T "/btl")) > 0) { split(l, a, "\t"); if (a[2] == "P") { P[a[1]]++; if (V[a[3]] == "KEPT") K[a[1]]++; if (V[a[3]] == "BREACHED") B[a[1]]++ } else if (a[2] == "L") L[a[1]]++; else if (a[2] == "E") E[a[1]]++; else if (a[2] == "M") M[a[1]]++ }
      while ((getline l < ".vid/hook-times") > 0) { if (l !~ /^hook result=refused/) continue; c = ""; n = split(l, f, " "); for (i = 1; i <= n; i++) if (index(f[i], "checkout=") == 1) c = substr(f[i], 10); if (c == "") continue; R[(c in CX) ? "codex" : "claude"]++ } }
    { NB[$2]++; if (!(($2, $3) in S)) { S[$2, $3] = 1; NS[$2]++ } if (!($2 in O)) O[$2] = ++no; TL[O[$2]] = $2 }
    END { for (i = 1; i <= no; i++) { t = TL[i]; printf "%s%s: steps %d · follow-up briefs %d · rows passed %d · kept %d · breached since %d · law-needed %d · early hand-backs %d · court refusals %d · builders %d%s", (i > 1 ? "; " : ""), t, NS[t], NB[t] - NS[t], P[t], K[t], B[t], L[t], E[t], R[t], AG[t], (M[t] ? sprintf(" · hand-backs not found %d (their rows not counted)", M[t]) : "") } }' "$T/bt")
fi
# v0.9.7.1 (3.9a, R14): a takeover of the builders' tests or commits still open
TKO=$(awk '$1 == "takeover" && $2 == "started" { o = $0; next } $1 == "takeover" && $2 == "ended" { o = "" } END { print o }' "$EV")
# v0.9.7.0.9 (3.6, R9): the started steps by their lane in the plan — builder (or absent), else the run manager
LANES=$(awk -F'\t' -v sf="$T/started" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 }
  $1 == "step" && ($2 in S) { if ($6 ~ /^orchestrator/) m++; else b++ } END { printf "lanes: builder %d · run manager %d\n", b, m }' "$T/parsed")
# v0.9.7.2 (R12, R14, R15): the steps' state, the debt, the closed steps not graded, hardening, rows first passing, builders
STRAT=$(sed -n 's/^strategy:[[:space:]]*//p' "$RS" | head -n 1 | sed 's/[[:space:]]*$//'); [ "$STRAT" = breadth-first ] || STRAT=depth-first
sh checks/metrics.sh step-state --all > "$T/ss" 2>/dev/null || : > "$T/ss"
awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+/ { print }' "$RS" > "$T/qs"
DEBT=$(awk -v st="$STRAT" -v T="$T" "$AWKAT"'
  function sk(l, k,   n, a, i) { n = split(l, a, " "); for (i = 2; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }
  BEGIN { FS = "\t"
    while ((getline l < (T "/parsed")) > 0) { split(l, a, "\t"); if (a[1] == "row") RS_[a[2]] = a[3] }
    while ((getline l < (T "/ss")) > 0) { if (l ~ /^step-state /) { K[sk(l, "step")] = sk(l, "kind"); DN[sk(l, "step")] = sk(l, "done") } }
    while ((getline l < (T "/states")) > 0) { split(l, a, "\t"); S[a[1]] = a[2] }
    while ((getline l < (T "/table93")) > 0) { split(l, a, "\t"); L[a[1]] = a[3]; GK[a[1]] = a[13] + 0; GN[a[1]] = a[14] + 0; BC[a[1]] = a[15]; PR[a[1]] = a[16] + 0 }
    while ((getline l < (T "/qs")) > 0) Q[++nq] = l
    FS = " " }
  { r = kv("row") } $1 == "deferred" && r != "" { DF[r] = 1 } $1 == "deferred-resolved" && r != "" { delete DF[r] }
  function whole(s, id,   p, q, b, c) { q = s; while ((p = index(q, id)) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; c = substr(q, p + length(id), 1); if (b !~ /[A-Za-z0-9_-]/ && c !~ /[A-Za-z0-9_-]/) return 1; q = substr(q, p + 1) } return 0 }
  END {
    for (r in S) {
      if (st == "breadth-first" && (r in RS_) && K[RS_[r]] == "hardening" && DN[RS_[r]] != "yes") { U[r] = 1; na++ }
      if (S[r] == "pass" && (L[r] != "KEPT" || (GN[r] > 0 && GK[r] < GN[r]))) { U[r] = 1; nb++
        if (L[r] != "KEPT" && L[r] != "BREACHED" && GK[r] == 0) { if (PR[r]) b5++; else b1++ }
        if (BC[r] ~ /product/) b2++; if (BC[r] ~ /test|harness/) b3++; if (GN[r] > 0 && GK[r] < GN[r]) b4++ }
      if (st == "breadth-first" && S[r] == "held") { U[r] = 1; nh++; for (k = 1; k <= nq; k++) if (whole(Q[k], r)) { q = Q[k]; sub(/^- /, "", q); sub(/[ \t].*/, "", q); if (!(q in QS)) { QS[q] = 1; ql = ql (ql == "" ? "" : ", ") q } } } }
    if (st == "breadth-first") for (r in DF) { U[r] = 1; nd++ }
    for (r in U) n++; n += 0; b1 += 0; b2 += 0; b3 += 0; b4 += 0; b5 += 0
    parts = sprintf("passing, not KEPT %d (never graded %d · product breach %d · test or harness breach %d · journey part-graded %d · re-grade after amendment %d)", nb, b1, b2, b3, b4, b5)
    if (st != "breadth-first") { printf "%d rows owed — %s\n", nb, parts; exit }
    printf "%d rows owed — in hardening, not done %d · %s · held %d (with their questions: %s) · deferred open %d\n", n, na, parts, nh, (ql == "" ? "none open" : ql), nd }' "$EV")
DEBTN=$(printf '%s\n' "$DEBT" | sed -n 's/^\([0-9][0-9]*\) rows owed.*/\1/p')
CNG=''; HARD=''
if [ "$STRAT" = breadth-first ]; then
  CNG=$(awk 'function sk(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "step-state" && sk("closed") == "yes" && sk("graded") == "no" { O[++n] = sk("step") } $1 == "ungraded" { U[sk("step")]++ }
    END { for (i = 1; i <= n; i++) printf "%s%s (%d rows)", (i > 1 ? ", " : ""), O[i], U[O[i]] }' "$T/ss")
  HARD=$(awk -F'\t' -v sf="$T/ss" 'function sk(l, k,   n, a, i) { n = split(l, a, " "); for (i = 2; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }
    BEGIN { while ((getline l < sf) > 0) if (l ~ /^step-state /) { s = sk(l, "step"); K[s] = sk(l, "kind"); D[s] = sk(l, "done"); if (K[s] == "feature" && D[s] != "yes") fo++ } }
    $1 == "row" && K[$3] == "hardening" && D[$3] != "yes" { n++; if (!($3 in H)) { H[$3] = 1; k++ } }
    END { if (!fo && k) printf "%d rows in %d steps", n, k }' "$T/parsed")
fi
# rows first seen passing: closed, the gap to its next step-closed; open, the wait so far
RPL=$(awk -v now="$NOWE" "$AWKAT"' $1 == "step-rows-passing" { s = kv("step"); if (!(s in P)) { P[s] = ep(lastat()); O[++n] = s } next }
  $1 == "step-closed" { s = kv("step"); NC[s]++; CT[s, NC[s]] = ep(lastat()); next }
  END { for (i = 1; i <= n; i++) { s = O[i]; c1 = ""; cb = 0
      for (k = 1; k <= NC[s]; k++) { if (CT[s, k] >= P[s]) { if (c1 == "" || CT[s, k] < c1) c1 = CT[s, k] } else cb = 1 }
      if (c1 != "") c = c (c == "" ? "" : ", ") sprintf("%s %.1f h", s, (c1 - P[s]) / 3600)
      else if (!cb) o = o (o == "" ? "" : ", ") sprintf("%s waiting %.1f h", s, (now > P[s] ? now - P[s] : 0) / 3600) }
    if (c != "") printf "closed: %s (includes regression checks)", c; if (o != "") printf "%sopen: %s", (c != "" ? " · " : ""), o }' "$EV")
# builders at once: open intervals, clipped to the last 6 hours
BTGT=$(sed -n 's/^builders-target=\([0-9][0-9]*\).*/\1/p' .vid/budget 2>/dev/null | tail -n 1)
BAT=$(awk -v now="$NOWE" -v tgt="${BTGT:-none}" "$AWKAT"' { t = ep(lastat()) }
  $1 == "agent-start" && (kv("type") == "vid:builder" || kv("type") == "vid:fixer") { k = kv("agent"); if (!(k in OP)) OP[k] = t }
  $1 == "agent-stop" { k = kv("agent"); if (k in OP) { I[++ni] = OP[k] "\t" t; delete OP[k] } }
  $1 == "job-start" { k = kv("try"); if (!(k in JS)) { JS[k] = t; JO[++nj] = k } }
  $1 == "job-exit" || $1 == "job-stop" { JE[kv("try")] = t }
  $1 == "job-recovery-required" { JR[kv("try")] = 1 }
  END { w0 = now - 21600; for (k in OP) { no++; I[++ni] = OP[k] "\t" now }
    for (i = 1; i <= nj; i++) { k = JO[i]; if ((k in JR) || !(k in JE)) { no++; I[++ni] = JS[k] "\t" now } else I[++ni] = JS[k] "\t" JE[k] }
    for (i = 1; i <= ni; i++) { split(I[i], x, "\t"); a = x[1] + 0; b = x[2] + 0; if (b > now) b = now; if (a < w0) a = w0; if (b > a) sum += b - a }
    printf "%d open · target %s · last 6 h average %.1f\n", no, tgt, sum / 21600 }' "$EV")
# v0.9.7.3 (3.5, R5): refused commits by court and rule, from the `court-refused` events
REFL=$(awk "$AWKAT"' $1 == "court-refused" { c = kv("court"); r = kv("rule"); n++; if (!(c in C)) CO[++nc] = c; C[c]++; k = c SUBSEP r; if (!(k in R)) RO[c] = RO[c] (RO[c] == "" ? "" : " ") r; R[k]++ }
  END { if (!n) exit; printf "%d", n; for (i = 1; i <= nc; i++) { c = CO[i]; printf "%s %s %d (", (i == 1 ? " —" : " ·"), c, C[c]; m = split(RO[c], a, " "); for (j = 1; j <= m; j++) printf "%s%s %d", (j > 1 ? ", " : ""), a[j], R[c SUBSEP a[j]]; printf ")" } printf "\n" }' "$EV")
# v0.9.8 (3.2, R13): the tests' state, derived (checks/metrics.sh test-state) — shown here only
TSTATE=$(sh checks/metrics.sh test-state 2>/dev/null | sed -n 's/^test-state rows=\([0-9]*\) written=\([0-9]*\) passing=\([0-9]*\) proven=\([0-9]*\)$/written \2 · passing \3 · proven \4, of \1 rows/p')
# plan changes since the last update
LASTP=$(awk "$AWKAT"' $1 == "progress" { a = lastat() } END { print a }' "$EV")
PCH=$(awk -v since="$LASTP" "$AWKAT"' $1 == "plan-change" { a = lastat(); if (since != "" && a <= since) next; w = $0; sub(/.* why="/, "", w); sub(/" at=.*/, "", w); printf "%s%s — \"%s\"", (n++ ? "; " : ""), kv("what"), w }' "$EV")
NOWT=$(sed -n 's/^now:[[:space:]]*//p' "$RS" | head -n 1); [ "$NOWT" = - ] && NOWT=''
HEADL="## $(printf '%s' "$NOWU" | cut -c1-16)Z — progress ($TRIG)"
# v0.26.10.5 (R6): with STAGES.md, the stage being built — `<n> of <k>, <name>` — and the stages closed so far
STGL=''
if [ -f STAGES.md ] && [ -f checks/stages.sh ]; then
  _cs=$(sh checks/stages.sh current 2>/dev/null || echo 1)
  _sb=$(sed -n '/^```vid-stages$/,/^```$/p' STAGES.md | grep -E '^[[:space:]]*STAGE-[0-9]+[[:space:]]*\|' || true)
  _sn=$(printf '%s\n' "$_sb" | awk -F'|' -v n="STAGE-$_cs" '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id == n { x = $2; gsub(/^[ \t]+|[ \t]+$/, "", x); print x; exit }')
  _sc=$(awk '$1 == "stage-closed" && / ready( |$)/ { for (i = 2; i <= NF; i++) if (index($i, "n=") == 1) printf "%s%s", (k++ ? ", " : ""), substr($i, 3) }' "$EV" 2>/dev/null)
  # v0.26.10.8 (R2): of <the final stage>, the highest number — with STAGE-0 one less than the count of lines
  STGL="$_cs of $(printf '%s\n' "$_sb" | sed -n 's/^[[:space:]]*STAGE-\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n | tail -n 1)${_sn:+, $_sn}${_sc:+ · closed: $_sc}"
fi
{ printf '%s\n\n| | |\n|---|---|\n' "$HEADL"
  [ -n "$STGL" ] && printf '| Stage | %s |\n' "$STGL"
  printf '| Passing | %s |\n' "$DONEL"
  printf '| Debt | %s |\n' "$DEBT"
  [ -n "$CNG" ] && printf '| Closed, not graded | %s — their dependents wait (the graded gate); catch-up: sh checks/brief.sh write --role grader --catch-up <step> --slice <N> |\n' "$CNG"
  [ -n "$HARD" ] && printf '| Hardening | %s |\n' "$HARD"
  printf '| Now | %s |\n' "$NOWLN"
  printf '| Left | %s |\n' "$LEFTL"
  printf '| Tests | %s |\n' "$TESTS"
  printf '| Test state | %s |\n' "${TSTATE:-not read}"
  printf '| Builders | %s · %s |\n' "$BLD" "$LANES"
  printf '| Builders at once | %s |\n' "$BAT"
  [ -n "$RPL" ] && printf '| Rows passing | %s |\n' "$RPL"
  [ -n "$REFL" ] && printf '| Refused commits | %s |\n' "$REFL"
  [ -n "$ROLEL" ] && printf '%s\n' "$ROLEL" | awk -F'\t' '{ printf "| %s | %s |\n", $1, $2 }'
  [ -n "$BYT" ] && printf '| By builder tool | %s |\n' "$BYT"
  [ -n "$TKO" ] && printf '| Takeover | open — %s |\n' "$(printf '%s' "$TKO" | sed 's/^takeover started //; s/ at=\(.*\)$/ (since \1)/')"
  printf '| Your questions | %s |\n' "$QUES"
  printf '| Estimate | %s |\n' "$ESTL"
  printf '| Plan changes since the last update | %s |\n' "${PCH:-none}"
  printf '| Now (the build'"'"'s own words) | %s |\n' "${NOWT:-—}"; } > "$T/table"
if [ "$REC" = no ]; then cat "$T/table"; exit 0; fi
[ -f .vid/PROGRESS.md ] || printf '# Progress — the build, hourly and at every plan change (checks/progress.sh)\n' > .vid/PROGRESS.md
{ printf '\n'; cat "$T/table"; } >> .vid/PROGRESS.md
printf 'progress trigger=%s by=%s rows-passing=%s rows-left=%s estimate=%s at=%s\n' "$TRIG" "$BY" "$P" "$LEFT" "$ESTF" "$(utc)" >> "$EV"
case "$ESTF" in none) HE='no estimate' ;; 0-0) HE=$NONE0 ;; *) HE="${ESTF%-*}–${ESTF#*-} h left" ;; esac
[ "$NRC" -lt 2 ] && HE='no estimate yet'
echo "$(basename "$H"): $P of $TOT rows passing · step $NPASS of $NSTEPS · $HE · debt ${DEBTN:-uncounted}"
exit 0
