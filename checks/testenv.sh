#!/bin/sh
# Purpose: ViD develop's test environments (v0.9.6 spec 3.9, 3.10; R9,
# R10). Stack-neutral: it reads Docker and Compose only, never the
# project's compose file, and changes no tracked file and no other
# project's containers. Run at the run's home by develop's test-environment
# step (skills/vid-test-manager/passes/test-environments.md), inside a 0.9.6
# develop run (`sh checks/plan.sh gate` on); its working figures live in
# the home's .vid/testenv.
#   measure --rows <ids> [--expect <s>] -- <sel>
#                      one run of <sel>, a request (v0.9.7.0.2 3.4: `sh
#                      checks/test.sh request --type iterate --role testenv
#                      --rows <ids> -- <sel>`, so it has an estimate, a cap
#                      and a ticket; the rows are kept for prove) — this
#                      call blocks until it ends, while `docker stats --no-stream` samples that run's
#                      compose project every 5 s; records the peak memory of
#                      the environment, the Compose version and whether it
#                      takes the !reset tag (the run says when it does not),
#                      the median case seconds of its receipt, Docker's total
#                      memory (`docker info`) and the memory used now by
#                      containers outside this repository.
#                      v0.9.7.0.12 (3.8, R8): the selection holds the
#                      home's heaviest case (`heaviest`) — a receipt
#                      without it is refused, naming it, and nothing is
#                      recorded — so env-mb comes from a heavy run; the
#                      same selection is then proved.
#   heaviest           v0.9.7.0.12 (3.8, R8): the heaviest case in the
#                      home's whole receipt history — the largest recorded
#                      seconds in any receipt's .cases (ties: the newest
#                      receipt): `heaviest case=<id> seconds=<s>
#                      receipt=<name>`, or `heaviest none` with no history.
#   pick               k = min(3, floor((docker − other − headroom) / env)),
#                      headroom = .vid/budget memory-headroom-mb (default
#                      2048); k 0 still uses one environment and says so; k
#                      is 1 without the !reset tag. Prints what Docker's
#                      memory would need to be for 2 and for 3.
#   prove [-- <sel>]   only when pick gave k ≥ 2: two runs of the
#                      measured selection (v0.9.8.1 R25: every word of it, read
#                      from its one line) and rows at once, started back to
#                      back once no other run holds a slot and no other request
#                      at the home waits — two requests, each passed
#                      VID_TESTENV_PROVE=<proof id> (checks/test.sh admits
#                      exactly two slots under it before testenv=proved);
#                      both must publish, under different names, and each
#                      receipt's case results must equal the measured
#                      (serial) receipt's, case by case. A failure is
#                      recorded as an `incident` and the proof stays unmet.
#                      v0.9.7.0.11 (3.5, R5): and the two runs must have
#                      overlapped in time — each took its slot (its ticket's
#                      running-at) before the other's `exit` was written — or
#                      nothing was proved side by side (checks/test.sh's
#                      memory admission may serialise them).
#   record             writes stacks=<k>, unverified-rows=<60·k>, env-mb=<peak>
#                      and testenv=proved harness=<cksum of the home's
#                      docker-compose.test.yml — v0.9.7.0.10 R14, the one read
#                      of that file, its hash> to .vid/budget (k falls to 1, and
#                      testenv=one, without a passed proof), keeping every
#                      other key, and the event `testenv stacks=<k>
#                      env-mb=<n> docker-mb=<n> other-mb=<n> case-seconds=<s>
#                      compose=<version> resets=yes|no`.
#   leftovers          lists what this project still has: containers, running
#                      or stopped, whose compose working-directory label is
#                      this repository or a path under it (per-slot volumes
#                      and images are caches, never listed; a live run's own
#                      containers are not leftovers); .vid/runs/ folders with
#                      no live holder; linked worktrees whose branch is merged
#                      into the home's branch, and (v0.9.8.1 R10) those whose
#                      agent's return is recorded; declared operations with no
#                      `done`. One `leftover <what> (<age>)` line each, then
#                      `leftovers n=<k>`. Always exits 0.
# VID_DOCKER overrides the docker command (the self-test drives a stub).
# v0.9.7.0.8 (T3): with IFS a newline only, `--expect` and its value are passed
# to the request as two words (as one, `--expect 120`, every request was refused).
# Usage: sh checks/testenv.sh measure --rows <ROW-id,…> [--expect <seconds>] -- <selector> | heaviest | pick | prove [-- <selector>] | record | leftovers
set -u
IFS='
'
DK=${VID_DOCKER:-docker}
usage() { echo 'ViD testenv: usage — sh checks/testenv.sh measure --rows <ROW-id,…> [--expect <seconds>] -- <selector> | heaviest | pick | prove [-- <selector>] | record | leftovers' >&2; exit 2; }
SUB=${1:-}; [ -n "$SUB" ] || usage; shift
G=$(sh checks/plan.sh gate 2>/dev/null || true)
case "$G" in
  'on '*) H=${G#on } ;;
  *) if [ "$SUB" = leftovers ]; then H=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P); else echo "ViD testenv: refused — the test-environment step runs inside a develop run under a 0.9.6 plan (plan.sh gate: ${G:-off})." >&2; exit 1; fi ;;
esac
TE="$H/.vid/testenv"; BUD="$H/.vid/budget"; EV="$H/.vid/metrics-events"
# v0.9.8.1 (R25, F-14): every value is one line — the selector's words space-separated — and tset drops any line that
# is no `key=value` (an older measure wrote the selector's ids one a line), so such a file is cleaned at the next write
tget() { [ -f "$TE" ] && sed -n "s/^$1=//p" "$TE" | tail -n 1; }
tset() { mkdir -p "$H/.vid"; { [ -f "$TE" ] && grep -v "^$1=" "$TE" | grep '^[a-z][a-z-]*='; printf '%s=%s\n' "$1" "$2"; } > "$TE.tmp"; mv "$TE.tmp" "$TE"; }
words() { _w=$(printf '%s ' "$@"); printf '%s\n' "${_w% }"; }   # the arguments on one line, space-separated (IFS is a newline here)
bget() { _v=''; [ -f "$BUD" ] && _v=$(sed -n "s/^$1=\([0-9][0-9]*\).*/\1/p" "$BUD" | head -n 1); echo "${_v:-$2}"; }
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
# mb: docker's sizes (123.4MiB, 1.2GiB, 512KiB, 0B, 1.1GB …) → whole MB, summed over stdin
mb() { awk '{ v = $0; n = v + 0; u = v; sub(/^[0-9.]+/, "", u)
  if (u ~ /^Gi?B/) n = n * 1024; else if (u ~ /^Ki?B/ || u ~ /^kB/) n = n / 1024; else if (u == "B") n = n / 1048576
  s += n } END { printf "%d\n", s }'; }
# the cases of a receipt as `id status`, sorted — the comparison the proof makes
cases() { [ -f "$H/.vid/ledger-results/$1.cases" ] && awk '$1 == "case" { print $2, $3 }' "$H/.vid/ledger-results/$1.cases" | LC_ALL=C sort; }
# run_of <pid>: the receipt the test.sh with that pid published (none when it published none)
run_of() { grep '^ledger-run ' "$EV" 2>/dev/null | grep -E " run=[0-9TZ]+-$1( |\$)" | tail -n 1 | sed -n 's/.* report=\([^ ]*\).*/\1/p'; }
# stats_of <compose project>: its containers' memory now, in MB
stats_of() { $DK stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' 2>/dev/null | awk -F'\t' -v p="$1-" 'index($1, p) == 1 { split($2, a, " / "); print a[1] }' | mb; }
under_here() { case "$1" in "$H"|"$H"/*) return 0 ;; *) return 1 ;; esac; }
# v0.9.7.0.2 (3.4): a run is a request; ask <out file> <request arguments…> → its ticket folder, or exit 1 with the refusal
ask() { _o=$1; shift; if ! sh checks/test.sh request --type iterate --role testenv "$@" > "$_o" 2>&1; then cat "$_o" >&2; echo 'ViD testenv: refused — the test manager did not accept the run.' >&2; exit 1; fi
  printf '%s/.vid/requests/%s\n' "$H" "$(sed -n 's/^next: sh checks\/test.sh wait //p' "$_o")"; }
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
ended() { case "$(cat "$1/state" 2>/dev/null)" in done|capped|failed-to-start|stopped) [ -f "$1/result" ] ;; *) return 1 ;; esac; }
# heavy: `<case>\t<seconds>\t<receipt>` — the largest recorded seconds over every receipt's .cases at the home (newest wins a tie)
# v0.9.8 (R15): never a proof receipt's (checks/evidence.sh ordinary)
heavy() { ls -tr "$H"/.vid/ledger-results/*.cases 2>/dev/null | grep -v '\.proof\.' | while IFS= read -r _f; do _n=${_f##*/}; awk -v r="${_n%.cases}" '$1 == "case" { print $2 "\t" ($4 + 0) "\t" r }' "$_f"; done |
  awk -F'\t' '$2 >= m { m = $2; l = $0 } END { if (l != "") print l }'; }
tpid() { _i=0; while [ ! -s "$1/pid" ] && ! ended "$1" && [ "$_i" -lt 60 ]; do sleep 1; _i=$((_i + 1)); done; cat "$1/pid" 2>/dev/null || echo 0; }

case "$SUB" in
  measure)
    ROWS=''; EXP=''
    while [ $# -gt 0 ]; do case "$1" in --rows) ROWS=${2:-}; shift 2 ;; --expect) EXP=${2:-}; shift 2 ;; --) shift; break ;; *) usage ;; esac; done
    SEL=$(words "$@"); [ -n "$SEL" ] && [ -n "$ROWS" ] || usage
    HV=$(heavy)   # v0.9.7.0.12 (3.8, R8): before the run — the measuring run itself never sets the bar
    O=$(mktemp); trap 'rm -f "$O"' EXIT
    TK=$(ask "$O" --rows "$ROWS" ${EXP:+--expect} ${EXP:+"$EXP"} --why 'testenv measure: one environment, its memory sampled' -- "$@") || exit 1
    TP=$(tpid "$TK"); PEAK=0; LAST=0
    while ! ended "$TK"; do
      PJ=$(sed -n 's/^project=//p' "$H"/.vid/runs/*-"$TP"/holder 2>/dev/null | head -n 1)
      if [ -n "$PJ" ] && [ $(( $(date +%s) - LAST )) -ge 5 ]; then
        M=$(stats_of "$PJ"); LAST=$(date +%s)
        [ "${M:-0}" -gt "$PEAK" ] && PEAK=$M
      fi
      sleep 1
    done
    ST=$(cat "$TK/exit" 2>/dev/null || echo 1)
    REC=$(run_of "$TP")
    if [ -z "$REC" ] || [ "$REC" = none ]; then cat "$TK/result" >&2; echo "ViD testenv: refused — the measuring run published no receipt (exit $ST; ticket ${TK##*/}); measure a selection that runs to its end." >&2; exit 1; fi
    if [ -n "$HV" ]; then
      _hc=$(printf '%s\n' "$HV" | cut -f1)
      awk -v c="$_hc" '$1 == "case" && $2 == c { f = 1 } END { exit !f }' "$H/.vid/ledger-results/$REC.cases" 2>/dev/null ||
        { echo "ViD testenv: refused — the measured selection left out the home's heaviest case $_hc ($(printf '%s\n' "$HV" | cut -f2) s in $(printf '%s\n' "$HV" | cut -f3)); nothing recorded. Measure a selection that holds it (sh checks/testenv.sh heaviest), so the memory measured is a heavy run's." >&2; exit 1; }
    fi
    RESETS=yes; grep -q 'refuses the !reset tag' "$TK/log" && RESETS=no
    CS=$(awk '$1 == "case" { print $4 + 0 }' "$H/.vid/ledger-results/$REC.cases" 2>/dev/null | sort -n | awk '{ v[NR] = $1 } END { if (NR == 0) print "none"; else if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }')
    DM=$($DK info --format '{{.MemTotal}}' 2>/dev/null | awk '{ printf "%d\n", $1 / 1048576 }')
    OTH=0
    for l in $($DK ps --format '{{.ID}}\t{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null); do
      id=${l%%	*}; wd=${l#*	}
      under_here "$wd" && continue
      M=$($DK stats --no-stream --format '{{.MemUsage}}' "$id" 2>/dev/null | awk -F' / ' '{ print $1 }' | mb); OTH=$((OTH + ${M:-0}))
    done
    CV=$($DK compose version --short 2>/dev/null | head -n 1); CV=${CV:-unknown}
    tset selector "$SEL"; tset rows "$ROWS"; tset expect "$EXP"; tset receipt "$REC"; tset env-mb "$PEAK"; tset docker-mb "${DM:-0}"; tset other-mb "$OTH"
    tset case-seconds "$CS"; tset compose "$CV"; tset resets "$RESETS"; tset measured-at "$(utc)"; tset proof ''; tset pick ''
    echo "testenv measure env-mb=$PEAK docker-mb=${DM:-0} other-mb=$OTH case-seconds=$CS compose=$CV resets=$RESETS receipt=$REC"
    exit 0 ;;
  heaviest)
    HV=$(heavy)
    if [ -n "$HV" ]; then printf '%s\n' "$HV" | awk -F'\t' '{ print "heaviest case=" $1 " seconds=" $2 " receipt=" $3 }'; else echo 'heaviest none — no receipt with recorded case seconds at the home'; fi
    exit 0 ;;
  pick)
    E=$(tget env-mb); D=$(tget docker-mb); OT=$(tget other-mb); R=$(tget resets)
    [ -n "$E" ] && [ -n "$D" ] || { echo 'ViD testenv: refused — nothing measured yet: sh checks/testenv.sh measure -- <selector>' >&2; exit 1; }
    HR=$(bget memory-headroom-mb 2048)
    if [ "$E" -le 0 ]; then K=0; else K=$(( (D - OT - HR) / E )); fi
    [ "$K" -lt 0 ] && K=0; [ "$K" -gt 3 ] && K=3
    NOTE=''
    [ "$K" -eq 0 ] && NOTE=" — k=0: one environment is still used"
    USE=$K; [ "$USE" -lt 1 ] && USE=1
    if [ "$R" = no ] && [ "$USE" -gt 1 ]; then USE=1; NOTE=" — this Compose refuses the !reset tag: one environment until it is updated"; fi
    N2=$((OT + HR + 2 * E)); N3=$((OT + HR + 3 * E))
    tset pick "$USE"
    echo "testenv pick k=$USE computed=$K docker-mb=$D other-mb=$OT headroom-mb=$HR env-mb=$E · Docker memory for 2: $N2 MB · for 3: $N3 MB$NOTE"
    if [ "$USE" -lt 2 ] && [ "$R" != no ] && [ "$E" -gt 0 ]; then
      echo "testenv short: raise Docker's memory to $(( (N2 + 1023) / 1024 )) GB for 2 environments, or $(( (N3 + 1023) / 1024 )) GB for 3, instead of 1"
    fi
    exit 0 ;;
  prove)
    K=$(tget pick); SEL=$(tget selector); REC=$(tget receipt); ROWS=$(tget rows); EXP=$(tget expect)
    [ -n "$K" ] || { echo 'ViD testenv: refused — run pick first.' >&2; exit 1; }
    [ "$K" -ge 2 ] || { echo "ViD testenv: refused — pick gave k=$K: no environment beside the first fits, so nothing is proved side by side." >&2; exit 1; }
    [ "${1:-}" = -- ] && shift
    if [ $# -gt 0 ] && [ "$(words "$@")" != "$SEL" ]; then echo "ViD testenv: refused — prove the measured selection ($SEL): its receipt is the serial result the proof compares with." >&2; exit 1; fi
    # v0.9.8.1 (R25, F-14): the two runs must overlap, so the proof starts them only once no other run holds a slot on
    # this host and no other request at the home is queued or running — then back to back. Bounded by
    # VID_PROVE_FREE_WAIT (default 1800 s): past it the proof fails, saying so.
    HOSTD="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"; HOSTD="${HOSTD%/}/vid-host"
    busy() { for _s in "$HOSTD"/stack.*; do [ -d "$_s" ] || continue; _p=$(sed -n 1p "$_s/holder" 2>/dev/null); _pe=$(kill -0 "${_p:-0}" 2>&1) && return 0
        case "$_pe" in *'No such process'*) ;; *) [ -n "$_p" ] && return 0 ;; esac; done
      for _q in "$H"/.vid/requests/*/state "$H"/.vid/requests/*/chunks/*/state; do case "$(cat "$_q" 2>/dev/null)" in queued|running) return 0 ;; esac; done
      return 1; }
    _fw=0; _fl=${VID_PROVE_FREE_WAIT:-1800}
    while busy; do
      [ "$_fw" -ge "$_fl" ] && { echo "ViD testenv: the proof failed — other runs held a slot for ${_fl} s, so its two runs could not overlap; prove again when the host is free. stacks stays 1." >&2; exit 1; }
      [ $((_fw % 60)) -eq 0 ] && echo "testenv prove: waiting for every slot to be free (${_fw} s)"
      sleep 2; _fw=$((_fw + 2))
    done
    ID="prove-$(date +%s)-$$"
    # v0.9.7.0.9 (R3): the measured selection as its words, one per argument (a word holding a space is refused)
    SELW=$(printf '%s\n' "$SEL" | tr ' ' '\n'); set -f
    O1=$(mktemp); O2=$(mktemp); trap 'rm -f "$O1" "$O2"' EXIT
    [ -n "$ROWS" ] || { echo 'ViD testenv: refused — the measure recorded no rows: measure again with --rows <ROW-id,…>.' >&2; exit 1; }
    K1=$(VID_TESTENV_PROVE=$ID ask "$O1" --rows "$ROWS" ${EXP:+--expect} ${EXP:+"$EXP"} --why "testenv prove $ID: run 1 of 2" -- $SELW) || exit 1
    K2=$(VID_TESTENV_PROVE=$ID ask "$O2" --rows "$ROWS" ${EXP:+--expect} ${EXP:+"$EXP"} --why "testenv prove $ID: run 2 of 2" -- $SELW) || exit 1
    set +f; P1=$(tpid "$K1"); P2=$(tpid "$K2")
    while ! ended "$K1" || ! ended "$K2"; do sleep 1; done
    cat "$K1/log" > "$O1"; cat "$K2/log" > "$O2"
    R1=$(run_of "$P1"); R2=$(run_of "$P2"); WHY=''
    if [ -z "$R1" ] || [ "$R1" = none ] || [ -z "$R2" ] || [ "$R2" = none ]; then WHY="both runs must publish (got ${R1:-none} and ${R2:-none})"
    elif [ "$R1" = "$R2" ]; then WHY='the two runs published under one name'
    else
      cases "$REC" > "$O1.s"; cases "$R1" > "$O1.a"; cases "$R2" > "$O1.b"
      if ! cmp -s "$O1.s" "$O1.a" || ! cmp -s "$O1.s" "$O1.b"; then WHY="a receipt's case results differ from the serial receipt $REC"; fi
      [ -s "$O1.s" ] || WHY="the serial receipt $REC has no cases to compare"
      rm -f "$O1.s" "$O1.a" "$O1.b"
      # v0.9.7.0.11 (3.5, R5): side by side, or not proved
      if [ -z "$WHY" ]; then
        S1=$(cat "$K1/running-at" 2>/dev/null || echo 0); S2=$(cat "$K2/running-at" 2>/dev/null || echo 0)
        E1=$(mtime "$K1/exit"); E2=$(mtime "$K2/exit")
        [ "$S1" -lt "$E2" ] && [ "$S2" -lt "$E1" ] || WHY='the two runs did not overlap in time (one waited for the other), so nothing was proved side by side'
      fi
    fi
    if [ -n "$WHY" ]; then
      tset proof failed
      SL=$(sed -n 's/^slice:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$H/.vid/RUN-STATE.md" 2>/dev/null | head -n 1)
      printf 'incident slice=%s testenv proof %s failed: %s at=%s\n' "${SL:--}" "$ID" "$WHY" "$(utc)" >> "$EV"
      cat "$O1" "$O2" >&2
      echo "ViD testenv: the proof failed — $WHY. stacks stays 1; repair what this names, or go on with one environment." >&2
      exit 1
    fi
    tset proof ok; tset proof-id "$ID"
    echo "testenv prove ok id=$ID receipts=$R1,$R2 — both equal the serial receipt $REC"
    exit 0 ;;
  record)
    K=$(tget pick); E=$(tget env-mb)
    [ -n "$K" ] && [ -n "$E" ] || { echo 'ViD testenv: refused — measure and pick first.' >&2; exit 1; }
    TV=proved
    if [ "$K" -ge 2 ] && [ "$(tget proof)" != ok ]; then echo "ViD testenv: note — k=$K was not proved side by side; recording one environment."; K=1; fi
    [ "$K" -lt 2 ] && TV=one
    [ "$TV" = proved ] && TV="proved harness=$(cksum < "$H/docker-compose.test.yml" | cut -d' ' -f1)"   # v0.9.7.0.10 (3.7, R14)
    mkdir -p "$H/.vid"
    { [ -f "$BUD" ] && grep -vE '^(stacks|unverified-rows|env-mb|testenv)=' "$BUD"
      printf 'stacks=%s\nunverified-rows=%s\nenv-mb=%s\ntestenv=%s\n' "$K" "$((60 * K))" "$E" "$TV"; } > "$BUD.tmp"
    mv "$BUD.tmp" "$BUD"
    printf 'testenv stacks=%s env-mb=%s docker-mb=%s other-mb=%s case-seconds=%s compose=%s resets=%s at=%s\n' "$K" "$E" "$(tget docker-mb)" "$(tget other-mb)" "$(tget case-seconds)" "$(tget compose)" "$(tget resets)" "$(utc)" >> "$EV"
    echo "testenv record stacks=$K unverified-rows=$((60 * K)) env-mb=$E testenv=$TV"
    exit 0 ;;
  leftovers)
    NOW=$(date +%s); N=0
    out() { echo "leftover $1"; N=$((N + 1)); }
    LIVEP=''
    for h in "$H"/.vid/runs/*/holder; do
      [ -f "$h" ] || continue
      d=${h%/holder}; p=$(sed -n 's/^pid=//p' "$h" | head -n 1); t=$(sed -n 's/^start=//p' "$h" | head -n 1)
      if [ -n "$p" ] && kill -0 "$p" 2>/dev/null && ! grep -q '^teardown-failed' "$h"; then LIVEP="$LIVEP
$d/"; continue; fi
      out "run-folder ${d#"$H"/} ($(( NOW - ${t:-NOW} )) s, no live holder$(grep -q '^teardown-failed' "$h" && echo '; its teardown failed'))"
    done
    for l in $($DK ps -a --format '{{.Names}}\t{{.Label "com.docker.compose.project.working_dir"}}\t{{.Status}}\t{{.RunningFor}}' 2>/dev/null); do
      nm=$(printf '%s' "$l" | cut -f1); wd=$(printf '%s' "$l" | cut -f2); stt=$(printf '%s' "$l" | cut -f3); age=$(printf '%s' "$l" | cut -f4)
      [ -n "$wd" ] && under_here "$wd" || continue
      skip=no; for lp in $LIVEP; do case "$wd/" in "$lp"*) skip=yes ;; esac; done
      [ "$skip" = yes ] && continue
      out "container $nm ($stt, created $age; working directory $wd)"
    done
    HB=$(git -C "$H" rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)
    HP=$(cd "$H" && pwd -P)
    # v0.9.8.1 (R10, F-7): an agent's worktree whose return is recorded — a hand-back naming its branch, whose brief's
    # build-cost is in the events (brief= read up to the next field, its home prefix removed) — is a leftover too
    RETB=''
    for rf in "$H"/.vid/briefs/*/*.return.md; do
      [ -f "$rf" ] && [ -f "$EV" ] || continue
      rbr=$(sed -n '1,12s/^branch:[[:space:]]*//p' "$rf" | head -n 1 | sed 's/[[:space:]]*$//'); [ -n "$rbr" ] || continue
      rb=${rf#"$H"/}; rb=${rb%.return.md}.md
      awk -v b="$rb" -v h="$H" -v hp="$HP" 'function bkv(h,   i, s, j) { i = index($0, " brief="); if (!i) return ""; s = substr($0, i + 7); j = match(s, / [a-z][a-z-]*=/); if (j) s = substr(s, 1, j - 1); if (h != "" && index(s, h "/") == 1) s = substr(s, length(h) + 2); return s }
        $1 == "build-cost" && (bkv(h) == b || bkv(hp) == b) { f = 1 } END { exit !f }' "$EV" && RETB="$RETB$rbr	${rf#"$H"/}
"
    done
    for l in $(git -C "$H" worktree list --porcelain 2>/dev/null | awk '/^worktree / { w = substr($0, 10); n++ } /^branch refs\/heads\// { if (n > 1) print w "\t" substr($0, 19) }'); do
      WT=${l%%	*}; BR=${l#*	}
      [ "$(cd "$WT" 2>/dev/null && pwd -P)" = "$HP" ] && continue
      [ "$BR" = "$HB" ] && continue
      ct=$(git -C "$H" log -1 --format=%ct "refs/heads/$BR" 2>/dev/null || echo "$NOW")
      # v0.9.8.1 (R39, F-33, safety): a worktree a live agent or attempt owns is `in use`, never a leftover — the branch
      # worktree-agent-<id> of an agent started with no stop, cost or return after, or vid/<try> of a Codex job started
      # with no exit or clean after
      IU=''
      case "$BR" in
        worktree-agent-*) _ag=${BR#worktree-agent-}
          [ -f "$EV" ] && awk -v a="agent=$_ag" '{ hit = 0; for (i = 2; i <= NF; i++) if ($i == a) hit = 1 } !hit { next }
              $1 == "agent-start" { on = 1 } $1 == "agent-stop" || $1 == "build-cost" || $1 == "agent-returned" { on = 0 } END { exit on ? 0 : 1 }' "$EV" && IU="agent $_ag" ;;
        vid/*) _tr=${BR#vid/}
          [ -f "$EV" ] && awk -v t="try=$_tr" '{ hit = 0; for (i = 2; i <= NF; i++) if ($i == t) hit = 1 } !hit { next }
              $1 == "job-start" { on = 1 } $1 == "job-exit" || $1 == "job-cleaned" || $1 == "job-stop" { on = 0 } END { exit on ? 0 : 1 }' "$EV" && IU="Codex job $_tr" ;;
      esac
      if [ -n "$IU" ]; then echo "in use: worktree $WT (branch $BR, $IU still working) — never a leftover"; continue; fi
      # merged only when the branch has commits beyond its base (its tip moved from where it was created, by its reflog)
      # and they are in the home's branch; a fresh worktree whose tip is its base is never offered
      _bs=$(git -C "$H" reflog show --format=%H "refs/heads/$BR" 2>/dev/null | tail -n 1); _tp=$(git -C "$H" rev-parse "refs/heads/$BR" 2>/dev/null)
      if [ -n "$_bs" ] && [ "$_bs" != "$_tp" ] && git -C "$H" merge-base --is-ancestor "refs/heads/$BR" HEAD 2>/dev/null; then
        out "worktree $WT (branch $BR, merged into $HB; its last commit $(( NOW - ct )) s ago)"; continue; fi
      RT=$(printf '%s' "$RETB" | awk -F'\t' -v b="$BR" '$1 == b { print $2; exit }')
      [ -n "$RT" ] && out "worktree $WT (branch $BR, not merged; its agent's return is recorded, $RT; its last commit $(( NOW - ct )) s ago)"
    done
    if [ -d "$H/.vid/watchdog" ]; then
      for f in "$H"/.vid/watchdog/*; do
        [ -f "$f" ] || continue
        s=$(sed -n 's/^start=//p' "$f" | tail -n 1)
        out "operation ${f##*/} (declared $(( NOW - ${s:-NOW} )) s ago, no done)"
      done
    fi
    echo "leftovers n=$N"
    exit 0 ;;
  *) usage ;;
esac
