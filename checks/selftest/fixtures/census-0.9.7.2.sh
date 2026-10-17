#!/bin/sh
# Purpose: ViD court — the census engine. Enumerate a population mechanically,
# join two sides, fail on any orphan not covered by a ratified exception row.
# It counts and joins; it never judges (the second-validator prohibition).
# Sources: (a) extractors in checks/extractors/<class>.<name>.sh — class is
# dead-path | invariant | divergence | reachability | vacuity | rendered |
# strength —
# each emitting
# "ok <subject>", "orphan <subject> <detail>" and optionally "population <n>"
# lines; no output = inactive (substrate absent); nonzero exit = failure.
# (b) rule rows in INVENTORY.md's vid-inventory block
# (rule | RULE-NNN | statement | census-command | tier | test) — the census
# command is the rule's denominator: an extractor path under checks/extractors/,
# or two enumerations "left :: right" (sites the rule applies to :: sites
# guarded), orphans = left minus right. A statement beginning
# "state-machine <field>:" is the §6.1 variant: the statement declares the
# transition table (space-separated from>to pairs; a bare token declares a
# state with no transition), the command enumerates every mutation and
# guard-read site ("<site> <from>><to>" or "<site> <state>" lines), and any
# undeclared transition or state is an orphan — fail-closed, naming the site. Joins, per orphan: exception row
# (excused — counts toward the ceremony threshold) · suppression row (extractor
# to-do — never counts toward deletion) · difference row (ratified divergence,
# printed) · debt-aware (§3.4): an orphan whose subject matches a ROW still
# owed, or belonging to a rule row still owed, reports "pending", never fails.
# Zero-denominator guard: a rule row whose population is empty is a FAILURE,
# never a pass. vacuity, rendered (§9: canvas-pinned load-bearing
# properties vs computed values on the running page) and strength (v0.8.1d:
# a Tier-0 row whose test asserts only existence) are report-only until
# their false-positive rates are measured, then promoted to fail-closed or
# deleted on the number. A census command must be SILENT on standard error
# (v0.8.1d, G-08): a diagnostic from any arm of a compound command, or from
# a single enumeration, fails the rule naming it — a failing arm must never
# silently shrink a population (measured: a syntax error in one arm took a
# rule from 72 sites to 18 with zero orphans and exit 0).
# Presence-gated: inactive when neither census rows nor extractors exist.
# v0.9.6 (3.14, R14): the extractors run side by side — every class
# extractor, and every rule row whose census command is an extractor path —
# VID_COURT_JOBS at a time (default the number of CPUs, capped at 8), each
# job's combined output and exit status in its own file; they are then
# judged in today's order, the sorted extractor list and then the rule rows,
# so the output and the verdicts are byte-identical to the serial run.
# VID_COURT_JOBS=1 is the serial run itself: each extractor runs where it is
# judged, as before. A rule row's two-sided or plain enumeration still runs
# where it is judged.
# v0.9.7.0.11 (3.10, R10): an `exception` or `suppression` row whose subject
# (field 3) holds a space or a tab can match no orphan, whose subject is one
# word. Such a row new or changed against HEAD's INVENTORY.md (its line not
# there as it is) is refused, naming it — before the presence gate, so it
# holds for seams.sh's `seam` exceptions too; one already at HEAD is a note
# on the census line, since refusing it would block every commit until its
# own law commit.
# Usage: sh checks/census.sh [--report]   (--report always exits 0)
set -eu
IFS='
'

MODE=default
[ "${1:-}" = "--report" ] && MODE=report

BLOCK=''
[ -f INVENTORY.md ] && BLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
EXTRACTORS=$(find checks/extractors -type f -name '*.sh' 2>/dev/null | sort || true)
RULES=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*rule[[:space:]]*\|' || true)
field() { printf '%s\n' "$1" | cut -d'|' -f"$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
# v0.9.7.0.11 (3.10, R10): no new exception or suppression whose subject holds whitespace
SPNOTE=''; SPBAD=0
HEADBLK=$(git show HEAD:INVENTORY.md 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' || true)
for _e in $(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*(exception|suppression)[[:space:]]*\|' || true); do
  case "$(field "$_e" 3)" in *[[:space:]]*) ;; *) continue ;; esac
  _k=$(field "$_e" 1); _i=$(field "$_e" 2)
  if printf '%s\n' "$HEADBLK" | grep -qxF -- "$_e"; then SPNOTE="$SPNOTE · note: $_k $_i's subject has whitespace, which no orphan's subject can carry (at HEAD)"
  else echo "ViD census: rejected — $_k $_i's subject has whitespace, which no orphan's subject can carry: '$(field "$_e" 3)'" >&2; SPBAD=1; fi
done
if [ -z "$EXTRACTORS" ] && [ -z "$RULES" ]; then [ "$SPBAD" -eq 0 ] || [ "$MODE" = report ] || exit 1; exit 0; fi

EXCS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*exception[[:space:]]*\|' || true)
SUPS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*suppression[[:space:]]*\|' || true)
DIFS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*difference[[:space:]]*\|' || true)
# Debt ledger join (§3.4): subjects of ROW rows still owed.
OWEDSUBJ=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*ROW-' | while IFS= read -r r; do
  case "$(printf '%s\n' "$r" | cut -d'|' -f8)" in (*owed*) printf '%s\n' "$r" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' ;; esac
done || true)

FAILS=0; TPOP=0; TORPH=0; TEXC=0; TSUP=0; TPEND=0; TVAC=0; TREND=0; TSTR=0
ERR=$(mktemp); XD=$(mktemp -d); trap 'rm -f "$ERR"; rm -rf "$XD"' EXIT
# v0.9.3 (3.13, R17, R22): under `grammar: 0.9.3` a --report run appends
# `court name=census seconds=<s>` to .vid/metrics-events — court runtime is
# measured before it is budgeted. A reporter calling this court sets
# VID_COURT_EVENT=off (checks/metrics.sh does), so reading never writes.
case "$(printf '%s\n' "$BLOCK" | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in
  'grammar: 0.9.3') if [ "$MODE" = report ] && [ "${VID_COURT_EVENT:-on}" != off ]; then
    CT0=$(date +%s)
    trap 'rm -f "$ERR"; rm -rf "$XD"; mkdir -p .vid; printf "court name=census seconds=%s at=%s\n" "$(( $(date +%s) - CT0 ))" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/metrics-events' EXIT
  fi ;;
esac
# run one census enumeration; any diagnostic on standard error is a failure
# (RUN_OUT holds the output, RUN_ERR the first diagnostic line, empty if clean)
run_enum() { # $1=command
  RUN_ERR=''
  RUN_OUT=$(sh -c "$1" 2>"$ERR" | grep -v '^[[:space:]]*$' || true)
  [ -s "$ERR" ] && RUN_ERR=$(head -n 1 "$ERR")
  : >"$ERR"
}

# judge one source's output. $1=class $2=source-name $3=rule-id-or-"" $4=output
# $5=debt ("owed" when the source's own rule row is still owed).
judge() {
  pop=0; okc=0; orph=0; exc=0; sup=0; pend=0; vac=0; rend=0; str=0
  for line in $4; do
    tag=${line%% *}; rest=${line#* }
    case "$tag" in
      population) pop=$((pop + rest)) ;;
      ok) pop=$((pop + 1)); okc=$((okc + 1)) ;;
      orphan)
        pop=$((pop + 1))
        subj=${rest%% *}; det=${rest#"$subj"}; det=${det# }
        # exception join — a rule row's exceptions must name the rule id;
        # the class word applies only to class extractors (no skeleton keys).
        HIT=''
        for e in $EXCS; do
          [ "$(field "$e" 3)" = "$subj" ] || continue
          c=$(field "$e" 4)
          if { [ -n "$3" ] && [ "$c" = "$3" ]; } || { [ -z "$3" ] && [ "$c" = "$1" ]; }; then HIT=$(field "$e" 2); break; fi
        done
        if [ -n "$HIT" ]; then
          echo "EXC   $2  $subj  ($HIT: $(field "$e" 5))"; exc=$((exc + 1)); continue
        fi
        # suppression join — the rule applies, the extractor cannot yet see it
        for s in $SUPS; do
          [ "$(field "$s" 3)" = "$subj" ] || continue
          c=$(field "$s" 4)
          if { [ -n "$3" ] && [ "$c" = "$3" ]; } || { [ -z "$3" ] && [ "$c" = "$1" ]; }; then HIT=$(field "$s" 2); break; fi
        done
        if [ -n "$HIT" ]; then
          echo "SUP   $2  $subj  ($HIT — extractor gap, to-do)"; sup=$((sup + 1)); continue
        fi
        # difference join — a ratified divergence is printed, never an orphan
        if [ "$1" = divergence ]; then
          for d in $DIFS; do
            if [ "$(field "$d" 3)" = "$subj" ]; then HIT=$(field "$d" 2); break; fi
          done
          if [ -n "$HIT" ]; then
            echo "DIF   $2  $subj  live: $det  (ratified $HIT)"; continue
          fi
        fi
        # v0.9.3 (3.4, R5): the topology census — a queue or schedule a ratified
        # difference row (its knob) or a deploy-owed ROW (its subject) names as
        # a platform-only consumer is printed as a ratified divergence
        if [ "$2" = dead-path.topology ]; then
          bare=${subj#*:}
          for d in $DIFS; do
            k=$(field "$d" 3)
            if [ "$k" = "$subj" ] || [ "$k" = "$bare" ]; then HIT=$(field "$d" 2); break; fi
          done
          if [ -z "$HIT" ]; then
            for rr in $(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*ROW-' | grep -E '\|[[:space:]]*owed: paid by /vid deploy' || true); do
              k=$(field "$rr" 3)
              if [ "$k" = "$subj" ] || [ "$k" = "$bare" ]; then HIT=$(field "$rr" 1); break; fi
            done
          fi
          if [ -n "$HIT" ]; then
            echo "DIF   $2  $subj  $det — a platform-only consumer (ratified $HIT; its platform half is paid at deploy gate 2)"; continue
          fi
        fi
        # debt-aware (§3.4): partner row owed, or the rule row itself owed
        if [ "$5" = owed ] || { [ -n "$subj" ] && printf '%s\n' "$OWEDSUBJ" | grep -qxF "$subj"; }; then
          echo "PEND  $2  $subj  $det (partner row owed — reported, not failed)"; pend=$((pend + 1)); continue
        fi
        if [ "$1" = vacuity ]; then
          echo "VAC   $2  $subj  $det (report-only — promote or delete on measured FP rate)"; vac=$((vac + 1)); continue
        fi
        if [ "$1" = rendered ]; then
          echo "REND  $2  $subj  $det (report-only §9 — the computed value differs from the canvas value; promote or delete on measured FP rate)"; rend=$((rend + 1)); continue
        fi
        if [ "$1" = strength ]; then
          echo "STR   $2  $subj  $det (report-only — a Tier-0 row whose strongest assertion is existence; promote or delete on measured FP rate)"; str=$((str + 1)); continue
        fi
        echo "FAIL  $2  $subj  $det"
        orph=$((orph + 1)) ;;
    esac
  done
  if [ -n "$3" ]; then
    guarded=$((pop - orph - exc - sup - pend - vac))
    echo "census $3: $pop sites, $guarded guarded (orphans=$orph exc=$exc sup=$sup pending=$pend)"
    if [ "$pop" -eq 0 ]; then
      if [ "$5" = owed ]; then
        # ratified, not yet armed: an empty population before any site or
        # test exists is debt, not law death — fail-closed once armed.
        echo "PEND  $3  zero-denominator — rule ratified, test owed, no sites yet (fail-closed once armed)"
        pend=$((pend + 1))
      else
        echo "FAIL  $3  zero-denominator — the census command enumerates nothing; a rule must not silently survive the renaming of what it watches." >&2
        FAILS=$((FAILS + 1))
      fi
    fi
  else
    echo "census $2: population=$pop ok=$okc orphans=$orph exc=$exc sup=$sup pending=$pend vac=$vac rend=$rend str=$str"
    if [ "$pop" -eq 0 ]; then
      echo "FAIL  $2  zero-population — enumerate the substrate or declare 'inactive <reason>'; an empty census is a failure, never a pass." >&2
      FAILS=$((FAILS + 1))
    fi
  fi
  FAILS=$((FAILS + orph)); TPOP=$((TPOP + pop)); TORPH=$((TORPH + orph))
  TEXC=$((TEXC + exc)); TSUP=$((TSUP + sup)); TPEND=$((TPEND + pend)); TVAC=$((TVAC + vac))
  TREND=$((TREND + rend)); TSTR=$((TSTR + str))
}

# v0.9.6 (3.14): the side-by-side jobs. A job is one extractor run, exactly
# as the serial loops below would run it; its index is its place in the
# order they judge it.
rulecmd() { # $1=rule row → its census command (origin:/proved-red: stripped)
  printf '%s\n' "$1" | awk -F'|' '{ n=NF; while (n > 4 && $n ~ /^[[:space:]]*(origin|proved-red):/) n--; c=""; for (i=4; i<=n-2; i++) c = c (i>4 ? "|" : "") $i; print c }' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}
isclass() { # $1=extractor path → 0 when the class loop judges it
  _b=${1##*/}; _b=${_b%.sh}
  case "${_b%%.*}" in state-machine) return 1 ;; esac
  case "$1" in checks/extractors/memory.sh) return 1 ;; esac
  return 0
}
NJ=${VID_COURT_JOBS:-}
[ -n "$NJ" ] || NJ=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
case "$NJ" in ''|*[!0-9]*|0) NJ=1 ;; esac
[ "$NJ" -gt 8 ] && NJ=8
if [ "$NJ" -gt 1 ]; then
  { _k=0; for x in $EXTRACTORS; do isclass "$x" || continue; _k=$((_k + 1)); printf 'c%s %s\n' "$_k" "$x"; done
    _k=0; for r in $RULES; do _k=$((_k + 1)); c=$(rulecmd "$r"); case "$c" in checks/extractors/*) [ -f "$c" ] && printf 'r%s %s\n' "$_k" "$c" ;; esac; done
  } > "$XD/list" || true
  if [ -s "$XD/list" ]; then
    awk '{ print NR }' "$XD/list" | xargs -n 1 -P "$NJ" sh -c 'l=$(sed -n "${1}p" "$0/list"); k=${l%% *}; x=${l#* }; ST=0; sh "$x" > "$0/$k.out" 2>&1 || ST=$?; echo "$ST" > "$0/$k.st"' "$XD" || true
  fi
fi
# runx <key> <path>: sets ST and OUT — the serial run, or that job's files
runx() {
  if [ "$NJ" -gt 1 ]; then
    ST=$(cat "$XD/$1.st" 2>/dev/null || echo 1); OUT=$(cat "$XD/$1.out" 2>/dev/null || true)
  else
    ST=0; OUT=$(sh "$2" 2>&1) || ST=$?
  fi
}
CI=0; RI=0

# --- Extractors -------------------------------------------------------------
for x in $EXTRACTORS; do
  base=${x##*/}; base=${base%.sh}
  class=${base%%.*}; name=$base
  # state-machine.<field>.sh is a rule row's denominator, not a class
  # census: its lines are "<site> <from>><to>" / "<site> <state>" and are
  # judged only through the state-machine rule row that cites it (§6.1).
  case "$class" in state-machine) continue ;; esac
  # v0.9.4 fix: checks/extractors/memory.sh is the observer's reader (v0.9.3
  # 3.9; seed/extractors/README.md), never a census: its one line, `free-mb
  # <n>` or `inactive <reason>`, is read by checks/observe.sh alone. Judged
  # here, `free-mb <n>` counted as a zero population and refused every
  # commit on a host that reports its free memory.
  case "$x" in checks/extractors/memory.sh) continue ;; esac
  CI=$((CI + 1)); runx "c$CI" "$x"
  if [ "$ST" -ne 0 ]; then
    echo "FAIL  $name  extractor exited $ST — a broken census is a failure, never a pass." >&2
    FAILS=$((FAILS + 1)); continue
  fi
  # Silence is failure: an absent substrate is declared ("inactive <reason>"
  # first line), never inferred — a census must not silently self-disable.
  if [ -z "$OUT" ]; then
    echo "FAIL  $name  silent-empty — an extractor declares 'inactive <reason>' when its substrate is absent; silence is how a census dies." >&2
    FAILS=$((FAILS + 1)); continue
  fi
  case "$OUT" in
    inactive*)
      first=${OUT%%'
'*}
      echo "census $name: $first"
      continue ;;
  esac
  judge "$class" "$name" '' "$OUT" active
done

# --- Rule rows --------------------------------------------------------------
for r in $RULES; do
  RI=$((RI + 1))
  id=$(field "$r" 2)
  # census-command may contain pipes: strip trailing labeled fields
  # (origin:/proved-red:), then rejoin fields 4..n-2 (awk restores '|').
  cmd=$(rulecmd "$r")
  test=$(printf '%s\n' "$r" | awk -F'|' '{ n=NF; while (n > 4 && $n ~ /^[[:space:]]*(origin|proved-red):/) n--; print $n }' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  debt=active; case "$test" in owed*|OWED*) debt=owed ;; esac
  if [ -z "$cmd" ]; then
    echo "FAIL  $id  rule row has no census command — a rule without a denominator is a hand-list." >&2
    FAILS=$((FAILS + 1)); continue
  fi
  stmt=$(field "$r" 3)
  case "$stmt" in
    state-machine*)
      # §6.1 state-machine variant: the declared transitions are the
      # field's whole legal vocabulary; every enumerated site must move or
      # read inside it.
      case "$stmt" in
        *:*) ;;
        *)
          echo "FAIL  $id  state-machine statement lacks '<field>:' — declare the table: state-machine <field>: from>to …" >&2
          FAILS=$((FAILS + 1)); continue ;;
      esac
      DECL=$(printf '%s
' "${stmt#*:}" | tr ' ' '
' | grep -v '^$' || true)
      if [ -z "$DECL" ]; then
        echo "FAIL  $id  state-machine table declares nothing — a lifecycle without a vocabulary is a hand-list." >&2
        FAILS=$((FAILS + 1)); continue
      fi
      STATES=$(printf '%s
' "$DECL" | tr '>' '
' | grep -v '^$' | sort -u)
      RAW=''
      case "$cmd" in
        checks/extractors/*)
          if [ ! -f "$cmd" ]; then
            echo "FAIL  $id  census command '$cmd' does not exist — promissory denominators are invalid." >&2
            FAILS=$((FAILS + 1)); continue
          fi
          runx "r$RI" "$cmd"; RAW=$OUT
          [ "$ST" -eq 0 ] || { echo "FAIL  $id  census extractor exited $ST." >&2; FAILS=$((FAILS + 1)); continue; } ;;
        *)
          run_enum "$cmd"; RAW=$RUN_OUT
          if [ -n "$RUN_ERR" ]; then
            echo "FAIL  $id  census command wrote to standard error — a failing arm must never silently shrink a population: $RUN_ERR" >&2
            FAILS=$((FAILS + 1)); continue
          fi ;;
      esac
      OUT=''
      for ln in $RAW; do
        site=${ln%% *}; tok=${ln#* }
        if [ "$tok" = "$ln" ]; then
          OUT="$OUT
orphan $site line-carries-no-state-or-transition-token"
          continue
        fi
        tok=$(printf '%s
' "$tok" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        case "$tok" in
          *'>'*)
            if printf '%s
' "$DECL" | grep -qxF "$tok"; then OUT="$OUT
ok $site"; else OUT="$OUT
orphan $site undeclared-transition:$tok"; fi ;;
          *)
            if printf '%s
' "$STATES" | grep -qxF "$tok"; then OUT="$OUT
ok $site"; else OUT="$OUT
orphan $site undeclared-state:$tok"; fi ;;
        esac
      done
      judge invariant "$id" "$id" "$OUT" "$debt"
      continue
      ;;
  esac
  OUT=''
  case "$cmd" in
    checks/extractors/*)
      if [ ! -f "$cmd" ]; then
        echo "FAIL  $id  census command '$cmd' does not exist — promissory denominators are invalid." >&2
        FAILS=$((FAILS + 1)); continue
      fi
      runx "r$RI" "$cmd"
      [ "$ST" -eq 0 ] || { echo "FAIL  $id  census extractor exited $ST." >&2; FAILS=$((FAILS + 1)); continue; } ;;
    *' :: '*)
      left=${cmd%% :: *}; right=${cmd#* :: }
      run_enum "$left"; L=$(printf '%s\n' "$RUN_OUT" | sort -u); LERR=$RUN_ERR
      run_enum "$right"; R=$(printf '%s\n' "$RUN_OUT" | sort -u); RERR=$RUN_ERR
      if [ -n "$LERR$RERR" ]; then
        echo "FAIL  $id  census command wrote to standard error — a failing arm must never silently shrink a population: ${LERR:-$RERR}" >&2
        FAILS=$((FAILS + 1)); continue
      fi
      OUT=$(for s in $L; do
        [ -n "$s" ] || continue
        if printf '%s\n' "$R" | grep -qxF "$s"; then echo "ok $s"; else echo "orphan $s unguarded"; fi
      done) ;;
    *)
      run_enum "$cmd"
      if [ -n "$RUN_ERR" ]; then
        echo "FAIL  $id  census command wrote to standard error — a failing arm must never silently shrink a population: $RUN_ERR" >&2
        FAILS=$((FAILS + 1)); continue
      fi
      OUT=$(printf '%s\n' "$RUN_OUT" | grep -v '^[[:space:]]*$' | sed 's/^/ok /' || true) ;;
  esac
  judge invariant "$id" "$id" "$OUT" "$debt"
done

# --- Divergence table — what the green ledger did NOT validate --------------
if [ -n "$DIFS" ]; then
  echo ''
  echo 'divergences (ratified — the green ledger did not validate these):'
  for d in $DIFS; do
    printf '    %s  %s  test=%s  prod=%s  %s\n' "$(field "$d" 2)" "$(field "$d" 3)" "$(field "$d" 4)" "$(field "$d" 5)" "$(field "$d" 6)"
  done
fi
if [ -n "$SUPS" ]; then
  echo ''
  echo 'suppressions (extractor to-do — never counted toward the ceremony threshold):'
  for s in $SUPS; do
    printf '    %s  %s  %s  gap: %s  fix-by: %s\n' "$(field "$s" 2)" "$(field "$s" 4)" "$(field "$s" 3)" "$(field "$s" 5)" "$(field "$s" 6)"
  done
fi

echo ''
echo "census: population=$TPOP orphans=$TORPH exceptions=$TEXC suppressed=$TSUP pending=$TPEND vacuity-reports=$TVAC rendered-reports=$TREND strength-reports=$TSTR$SPNOTE"
[ "$MODE" = report ] && exit 0
[ "$SPBAD" -eq 0 ] || FAILS=$((FAILS + 1))
if [ "$FAILS" -gt 0 ]; then
  echo 'ViD census: rejected — every orphan is fixed, or carries a ratified exception/suppression row (standalone law commit).' >&2
  exit 1
fi
exit 0
