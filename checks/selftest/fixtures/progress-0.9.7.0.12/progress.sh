#!/bin/sh
# Purpose: ViD develop's progress update (v0.9.6 spec 3.15, R15) — one fixed
# table, computed from records; the format is ViD's, never the model's. It
# reads the plan block, the receipts (checks/evidence.sh, "current" as spec
# 3.3), the row engine's owed, held and `later` rows, the open `Q<n>` lines,
# the live run folders and the events. Nothing in it is written by the
# model but `now:` (RUN-STATE, one line, `--now`).
#   Done    the steps passing (every row passing, owed, held or later), by
#           name, and the rows passing; v0.9.6.1 (3.3): of them, the rows
#           claimed on a selected close that no checkpoint or full run has
#           yet run whole, counted apart as provisional (metrics.sh
#           provisional).
#   Now     each started step not yet passing: `<name> (<lane>): x of y rows
#           passing`.
#   Left    the steps not started; the rows not yet passing — red (failing,
#           or run only on other code), never run (no case in any valid
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
#   Your questions, Estimate, Plan changes since the last update, Now (the
#           build's own words).
#   The estimate: P(t) is the rows passing on the receipts published by t,
#   judged at the commit HEAD was at t; the rate over a window w is (P(now)
#   − P(now − w)) / w, for w = 3 h and w = the time since develop's first
#   valid receipt (the first at or after its first stage start); the red, never-run and not-in-the-plan rows divided by each
#   positive rate make the range. One positive rate: one number, its window
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
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
function ep(t,  y, m, d, H, M, S) { y = substr(t, 1, 4) + 0; m = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0; H = substr(t, 12, 2) + 0; M = substr(t, 15, 2) + 0; S = substr(t, 18, 2) + 0
  if (m <= 2) { y--; m += 12 } return (365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d - 719469) * 86400 + H * 3600 + M * 60 + S }'
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
sh checks/plan.sh parse > "$T/parsed" 2>"$T/err" || { cat "$T/err" >&2; echo 'ViD progress: the plan block does not hold — no update.' >&2; exit 1; }
sh checks/plan.sh map --all > "$T/map" 2>/dev/null || { echo 'ViD progress: no currency map.' >&2; exit 1; }
sh checks/evidence.sh rows --at HEAD --map "$T/map" ${VID_EVIDENCE_LEGACY:+--legacy} > "$T/states" || { echo 'ViD progress: the evidence could not be read.' >&2; exit 1; }
[ -f "$EV" ] || : > "$EV"
awk "$AWKAT"' $1 == "step-start" { print kv("step") }' "$EV" | sort -u > "$T/started"
# the valid receipts, with their times (for the rate), and the newest
awk "$AWKAT"' $1 == "invalidated" && kv("report") != "" { inv[kv("report")] = 1; next }
  $1 == "ledger-run" && kv("report") != "" && kv("report") != "none" { n++; R[n] = kv("report"); A[n] = lastat(); K[n] = kv("kind") }
  END { for (i = 1; i <= n; i++) if (!(R[i] in inv) && A[i] != "") print A[i] "\t" R[i] "\t" K[i] }' "$EV" | sort > "$T/rcpts.raw"
: > "$T/rcpts"; while IFS='	' read -r a r k; do [ -f ".vid/ledger-results/$r" ] && printf '%s\t%s\t%s\n' "$a" "$r" "$k" >> "$T/rcpts"; done < "$T/rcpts.raw"
NRC=$(grep -c . "$T/rcpts" || true)
NOWE=$(date +%s); NOWU=$(utc)
if [ -n "${VID_PROGRESS_AT:-}" ]; then NOWU=$VID_PROGRESS_AT; NOWE=$(printf '%s\n' "$NOWU" | awk "$AWKAT"' { print ep($0) }'); fi
# P(t): rows passing on the receipts published by t, at the commit HEAD was at t
passing_at() { # $1=UTC
  _c=$(git rev-list -1 --before="$1" HEAD 2>/dev/null || true)
  [ -n "$_c" ] || { echo 0; return; }
  sh checks/evidence.sh rows --at "$_c" --map "$T/map" --until "$1" ${VID_EVIDENCE_LEGACY:+--legacy} 2>/dev/null | awk -F'\t' '$2 == "pass" { n++ } END { print n + 0 }'
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
    else if (st != "pass") { if (!inplan) nip++; else if (st == "never") nev++; else red++ }
    if (inplan) { s = RSTEP[id]; SR[s]++; if (st == "pass") SP[s]++; if (st == "pass" || st == "owed" || st == "held") SOK[s]++ } }
  END {
    for (i = 1; i <= ns; i++) { s = S[i]; if (SOK[s] + 0 == SR[s] + 0) { np++; done = done (done == "" ? "" : "; ") NM[s] } }
    for (i = 1; i <= ns; i++) { s = S[i]; if (SOK[s] + 0 == SR[s] + 0) continue
      if (s in ST) now = now (now == "" ? "" : " · ") NM[s] " (" (LN[s] == "-" ? "unassigned" : LN[s]) "): " SP[s] + 0 " of " SR[s] + 0 " rows passing"
      else { nns++; notst = notst (notst == "" ? "" : "; ") NM[s] } }
    q = "\047"
    printf "NSTEPS=%d NPASS=%d P=%d TOT=%d RED=%d NEV=%d NIP=%d BLK=%d BO=%d BH=%d DEP=%d LAT=%d NNS=%d\n", ns, np, P, tot, red, nev, nip, blk, bo, bh, dep, lat, nns
    gsub(q, q "\\" q q, done); gsub(q, q "\\" q q, now); gsub(q, q "\\" q q, notst)
    printf "DONE=%s%s%s\nNOWS=%s%s%s\nNOTST=%s%s%s\n", q, done, q, q, now, q, q, notst, q }' "$T/map" "$T/states")"
LEFT=$((RED + NEV + NIP + BLK)); EST=$((RED + NEV + NIP))
# Done, Now, Left
DONEL="$NPASS of $NSTEPS steps passing${DONE:+: $DONE}. $P rows passing"
NPROV=$(sh checks/metrics.sh provisional 2>/dev/null | sed -n 's/^provisional rows=\([0-9][0-9]*\)$/\1/p')
[ "${NPROV:-0}" -gt 0 ] && DONEL="$DONEL ($NPROV provisional: claimed on a selected close, not yet run whole by a checkpoint or the full run)"
NOWLN=${NOWS:-no step in progress}
if [ "$NNS" -eq 1 ]; then LEFTL="1 step not started: $NOTST."; elif [ "$NNS" -gt 1 ]; then LEFTL="$NNS steps not started: $NOTST."; else LEFTL='every step started.'; fi
LEFTL="$LEFTL $EST rows not yet passing ($RED red, $NEV never run"
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
BUSY=0; for h in .vid/runs/*/holder; do [ -f "$h" ] || continue; p=$(sed -n 's/^pid=//p' "$h" | head -n 1); [ -n "$p" ] && kill -0 "$p" 2>/dev/null && BUSY=$((BUSY + 1)); done
NEWEST=$(tail -n 1 "$T/rcpts" | cut -f2)
if [ -n "$NEWEST" ]; then
  RS_=$(sh checks/evidence.sh red "$NEWEST" 2>/dev/null | head -n 1)
  SETUP=$(printf '%s\n' "$RS_" | sed -n 's/.* setup=\([0-9]*\).*/\1/p'); FAILED=$(printf '%s\n' "$RS_" | sed -n 's/.* failed=\([0-9]*\).*/\1/p')
  TESTS="$BUSY of $STK environments busy · red by where it stops: setup ${SETUP:-0}, failed ${FAILED:-0}"
else TESTS="$BUSY of $STK environments busy · no receipt yet"; fi
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
ESTF=none
if [ "$NRC" -lt 2 ]; then ESTL="no estimate yet — fewer than two valid receipts. $NOTINC"
elif [ "$EST" -eq 0 ]; then _bn=''; [ "$BLK" -gt 0 ] && _bn=" — blocked, not estimated: $BLK"; ESTL="nothing left to turn green$_bn. $NOTINC"; ESTF=0-0
else
  P3=$(passing_at "$(utc_of $((NOWE - 10800)))")
  # develop's first valid receipt: the first at or after develop's first stage start
  DEV0=$(awk "$AWKAT"' $1 == "stage" && kv("name") == "develop" && kv("state") == "start" { a = lastat(); if (a != "" && (m == "" || a < m)) m = a } END { print m }' "$EV")
  T0=$(awk -F'\t' -v d="$DEV0" '$1 >= d { print $1; exit }' "$T/rcpts"); [ -n "$T0" ] || T0=$(head -n 1 "$T/rcpts" | cut -f1)
  T0E=$(printf '%s\n' "$T0" | awk "$AWKAT"' { print ep($0) }')
  PA=$(passing_at "$T0"); WA=$((NOWE - T0E)); [ "$WA" -gt 0 ] || WA=1
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
fi
# v0.9.7.0.7 (3.5): the builders' cost, from the build-cost events
BLD=$(awk "$AWKAT"' $1 == "build-cost" { n++; r += kv("rows"); k += kv("rows-passed"); b = kv("before-change"); if (b ~ /^[0-9]+$/) V[++nv] = b + 0; else u++ }
  END { if (!n) { print "none yet"; exit }
    for (i = 2; i <= nv; i++) { x = V[i]; j = i - 1; while (j >= 1 && V[j] > x) { V[j + 1] = V[j]; j-- } V[j + 1] = x }
    m = nv ? V[int((nv + 1) / 2)] : "none"
    printf "%d handed back · rows passed %d of %d · before first change: median %s (%d unknown)\n", n, k, r, m, u }' "$EV")
# v0.9.7.0.9 (3.6, R9): the started steps by their lane in the plan — builder (or absent), else the run manager
LANES=$(awk -F'\t' -v sf="$T/started" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 }
  $1 == "step" && ($2 in S) { if ($6 ~ /^orchestrator/) m++; else b++ } END { printf "lanes: builder %d · run manager %d\n", b, m }' "$T/parsed")
# plan changes since the last update
LASTP=$(awk "$AWKAT"' $1 == "progress" { a = lastat() } END { print a }' "$EV")
PCH=$(awk -v since="$LASTP" "$AWKAT"' $1 == "plan-change" { a = lastat(); if (since != "" && a <= since) next; w = $0; sub(/.* why="/, "", w); sub(/" at=.*/, "", w); printf "%s%s — \"%s\"", (n++ ? "; " : ""), kv("what"), w }' "$EV")
NOWT=$(sed -n 's/^now:[[:space:]]*//p' "$RS" | head -n 1); [ "$NOWT" = - ] && NOWT=''
HEADL="## $(printf '%s' "$NOWU" | cut -c1-16)Z — progress ($TRIG)"
{ printf '%s\n\n| | |\n|---|---|\n' "$HEADL"
  printf '| Done | %s |\n' "$DONEL"
  printf '| Now | %s |\n' "$NOWLN"
  printf '| Left | %s |\n' "$LEFTL"
  printf '| Tests | %s |\n' "$TESTS"
  printf '| Builders | %s · %s |\n' "$BLD" "$LANES"
  printf '| Your questions | %s |\n' "$QUES"
  printf '| Estimate | %s |\n' "$ESTL"
  printf '| Plan changes since the last update | %s |\n' "${PCH:-none}"
  printf '| Now (the build'"'"'s own words) | %s |\n' "${NOWT:-—}"; } > "$T/table"
if [ "$REC" = no ]; then cat "$T/table"; exit 0; fi
[ -f .vid/PROGRESS.md ] || printf '# Progress — the build, hourly and at every plan change (checks/progress.sh)\n' > .vid/PROGRESS.md
{ printf '\n'; cat "$T/table"; } >> .vid/PROGRESS.md
printf 'progress trigger=%s by=%s rows-passing=%s rows-left=%s estimate=%s at=%s\n' "$TRIG" "$BY" "$P" "$LEFT" "$ESTF" "$(utc)" >> "$EV"
case "$ESTF" in none) HE='no estimate' ;; 0-0) HE='nothing left to turn green' ;; *) HE="${ESTF%-*}–${ESTF#*-} h left" ;; esac
[ "$NRC" -lt 2 ] && HE='no estimate yet'
echo "$(basename "$H"): $P of $TOT rows passing · step $NPASS of $NSTEPS · $HE"
exit 0
