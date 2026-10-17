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
# v0.9.7.3 (3.4, R4): the same verdicts, faster. The inventory's rows are read
# once, by one awk pass, into ordered records (exceptions, suppressions,
# differences, rule rows, the owed and deploy-owed ROW subjects) — no
# per-field subprocess per row — and each orphan's joins are keyed lookups in
# today's precedence (exception, then suppression, by subject and scope, the
# first row in order; an ordinary difference by subject; a topology difference
# by subject or bare subject, then a deploy-owed row; the owed subjects).
# Each extractor runs once per invocation — a class extractor a rule row also
# cites included — its output and status kept and judged separately in class
# and rule context: execution is deduplicated, not judgement. Output, counters
# and exit status are the 0.9.7.2 census's (selftest/fixtures/census-0.9.7.2.sh,
# case census-oracle).
# Usage: sh checks/census.sh [--report]   (--report always exits 0) | --measure <fixture dir>   (v0.9.8, advisory)
set -eu
IFS='
'

MODE=default
[ "${1:-}" = "--report" ] && MODE=report

# v0.9.8 (3.6, R11): the weak-test checks measured — `--measure <fixture dir>` runs this project's vacuity and strength
# extractors (checks/extractors/vacuity.*.sh, strength.*.sh) with the fixture dir as their working directory — a
# labelled tree of known weak and known good tests — and scores their orphans against <dir>/labels: one line each,
# `weak <class> <subject> <rule>` or `good <class> <subject>` (# lines ignored); an orphan's rule is the first word of
# its detail. Per class and rule: tp (a weak label its orphan names with that rule), fp (an orphan on a good label, an
# unlabelled subject, or with another rule), fn (a weak label no such orphan names), and precision tp/(tp+fp) and
# recall tp/(tp+fn) as counts over counts, never percentages. Advisory: it gates nothing and always exits 0 (2 on
# usage); a later release sets the bar.
if [ "${1:-}" = --measure ]; then
  MD=${2:-}; [ -n "$MD" ] && [ -d "$MD" ] && [ -f "$MD/labels" ] || { echo 'ViD census: usage — sh checks/census.sh --measure <fixture dir holding labels>' >&2; exit 2; }
  MX=$(find checks/extractors -type f \( -name 'vacuity.*.sh' -o -name 'strength.*.sh' \) 2>/dev/null | sort)
  MW=$(mktemp -d); trap 'rm -rf "$MW"' EXIT; : > "$MW/orph"; MH=$(pwd -P)
  for x in $MX; do cl=${x##*/}; cl=${cl%%.*}
    (cd "$MD" && sh "$MH/$x" 2>/dev/null) | awk -v c="$cl" '$1 == "orphan" { print c "\t" $2 "\t" $3 }' >> "$MW/orph" || true
  done
  awk -F'\t' -v lf="$MD/labels" -v nx="$(printf '%s\n' "$MX" | grep -c . || true)" '
    BEGIN { while ((getline l < lf) > 0) { if (l ~ /^[ \t]*(#|$)/) continue; n = split(l, a, /[ \t]+/)
        if (a[1] == "weak") { W[a[2], a[3]] = a[4]; WL[++nw] = a[2] SUBSEP a[3] } else if (a[1] == "good") G[a[2], a[3]] = 1; nl++ } }
    { c = $1; s = $2; r = $3; no++; K[c, r] = 1
      if (((c, s) in W) && W[c, s] == r) { HIT[c, s] = 1; TP[c, r]++ } else FP[c, r]++ }
    END { for (i = 1; i <= nw; i++) { split(WL[i], k, SUBSEP); r = W[k[1], k[2]]; K[k[1], r] = 1; if (!((k[1], k[2]) in HIT)) FN[k[1], r]++ }
      for (key in K) { split(key, k, SUBSEP); O[++m] = k[1] " " k[2] }
      for (i = 1; i < m; i++) for (j = i + 1; j <= m; j++) if (O[j] < O[i]) { t = O[i]; O[i] = O[j]; O[j] = t }
      for (i = 1; i <= m; i++) { split(O[i], k, " "); c = k[1]; r = k[2]; tp = TP[c, r] + 0; fp = FP[c, r] + 0; fn = FN[c, r] + 0
        printf "measure class=%s rule=%s tp=%d fp=%d fn=%d precision=%d/%d recall=%d/%d\n", c, r, tp, fp, fn, tp, tp + fp, tp, tp + fn }
      printf "measure extractors=%d labels=%d orphans=%d — advisory: no bar is set\n", nx, nl, no }' "$MW/orph"
  exit 0
fi

BLOCK=''
[ -f INVENTORY.md ] && BLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
EXTRACTORS=$(find checks/extractors -type f -name '*.sh' 2>/dev/null | sort || true)
RULES=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*rule[[:space:]]*\|' || true)
# v0.9.7.3 (R4): the parsed records live here for the whole invocation
PD=$(mktemp -d); trap 'rm -rf "$PD"' EXIT
printf '%s\n' "$BLOCK" > "$PD/block"
# v0.9.7.0.11 (3.10, R10): no new exception or suppression whose subject holds whitespace
SPNOTE=''; SPBAD=0
git show HEAD:INVENTORY.md 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' > "$PD/head" 2>/dev/null || : > "$PD/head"
# one pass: `note<TAB><kind> <id>` for a row at HEAD as it is, `bad<TAB><kind> <id><TAB><subject>` otherwise
awk -F'|' -v hf="$PD/head" '
  function fld(n,   v) { v = (index($0, "|") ? $n : $0); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
  BEGIN { while ((getline l < hf) > 0) H[l] = 1 }
  /^[[:space:]]*(exception|suppression)[[:space:]]*\|/ { if (fld(3) !~ /[[:space:]]/) next
    if ($0 in H) print "note\t" fld(1) " " fld(2); else print "bad\t" fld(1) " " fld(2) "\t" fld(3) }' "$PD/block" > "$PD/space"
while IFS="$(printf '\t')" read -r _w _ki _sj; do
  if [ "$_w" = note ]; then SPNOTE="$SPNOTE · note: $_ki's subject has whitespace, which no orphan's subject can carry (at HEAD)"
  else echo "ViD census: rejected — $_ki's subject has whitespace, which no orphan's subject can carry: '$_sj'" >&2; SPBAD=1; fi
done < "$PD/space"
if [ -z "$EXTRACTORS" ] && [ -z "$RULES" ]; then [ "$SPBAD" -eq 0 ] || [ "$MODE" = report ] || exit 1; exit 0; fi

# v0.9.7.3 (R4): the records, read once, in order — fields split on `|` and
# trimmed as `cut -d'|' -f<n>` then a trim read them (a line without `|` is its
# own every field), separated by US (\037): exc and sup `<id> <subject>
# <scope> <f5> <f6>`, dif `<id> <f3> <f4> <f5> <f6>`, the debt ledger join
# (§3.4) owed `<subject>` (a ROW row whose 8th field says owed), deploy `<id>
# <subject>` (a ROW row owed: paid by /vid deploy), rules `<id> <command>
# <test> <statement>` (command and test as 0.9.7.2's rulecmd and test field read
# them, origin:/proved-red: stripped)
US=$(printf '\037')
awk -F'|' -v pd="$PD" '
  function tr(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
  function fld(n) { return tr(index($0, "|") ? $n : $0) }
  /^[[:space:]]*exception[[:space:]]*\|/ { print fld(2) "\037" fld(3) "\037" fld(4) "\037" fld(5) "\037" fld(6) > (pd "/exc") }
  /^[[:space:]]*suppression[[:space:]]*\|/ { print fld(2) "\037" fld(3) "\037" fld(4) "\037" fld(5) "\037" fld(6) > (pd "/sup") }
  /^[[:space:]]*difference[[:space:]]*\|/ { print fld(2) "\037" fld(3) "\037" fld(4) "\037" fld(5) "\037" fld(6) > (pd "/dif") }
  /^[[:space:]]*ROW-/ { f8 = (index($0, "|") ? $8 : $0); if (f8 ~ /owed/) print fld(3) > (pd "/owed")
    if ($0 ~ /\|[[:space:]]*owed: paid by \/vid deploy/) print fld(1) "\037" fld(3) > (pd "/deploy") }
  /^[[:space:]]*rule[[:space:]]*\|/ { n = NF; while (n > 4 && $n ~ /^[[:space:]]*(origin|proved-red):/) n--
    c = ""; for (i = 4; i <= n - 2; i++) c = c (i > 4 ? "|" : "") $i
    print fld(2) "\037" tr(c) "\037" tr($n) "\037" fld(3) > (pd "/rules") }' "$PD/block"
for _f in exc sup dif owed deploy rules; do [ -f "$PD/$_f" ] || : > "$PD/$_f"; done
DIFS=$(cat "$PD/dif"); SUPS=$(cat "$PD/sup")

FAILS=0; TPOP=0; TORPH=0; TEXC=0; TSUP=0; TPEND=0; TVAC=0; TREND=0; TSTR=0
ERR=$(mktemp); XD=$(mktemp -d); trap 'rm -f "$ERR"; rm -rf "$XD" "$PD"' EXIT
# v0.9.3 (3.13, R17, R22): under `grammar: 0.9.3` a --report run appends
# `court name=census seconds=<s>` to .vid/metrics-events — court runtime is
# measured before it is budgeted. A reporter calling this court sets
# VID_COURT_EVENT=off (checks/metrics.sh does), so reading never writes.
# v0.9.8.1 (R13): every reader of a pipe here reads it to its end — a reader closing early (head, grep -q) left the
# writer a broken pipe, said on standard error when the caller ignores SIGPIPE, as a parent process may
case "$(printf '%s\n' "$BLOCK" | awk 'NF && !d { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); print; d = 1 }')" in
  'grammar: 0.9.3') if [ "$MODE" = report ] && [ "${VID_COURT_EVENT:-on}" != off ]; then
    CT0=$(date +%s)
    trap 'rm -f "$ERR"; rm -rf "$XD" "$PD"; mkdir -p .vid; printf "court name=census seconds=%s at=%s\n" "$(( $(date +%s) - CT0 ))" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/metrics-events' EXIT
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
# v0.9.7.3 (R4): one awk pass over the output with the records indexed by key;
# the lines and counters are 0.9.7.2's shell loop's, in its order.
JN=0
judge() {
  JN=$((JN + 1))
  printf '%s\n' "$4" > "$PD/j.$JN"
  awk -v cls="$1" -v nm="$2" -v rid="$3" -v debt="$5" -v pd="$PD" -v cf="$PD/c.$JN" '
    BEGIN { FS = "\037"
      while ((getline l < (pd "/exc")) > 0) { split(l, a, "\037"); k = a[2] SUBSEP a[3]; if (!(k in EX)) { EX[k] = a[1]; ER[k] = a[4] } }
      while ((getline l < (pd "/sup")) > 0) { split(l, a, "\037"); k = a[2] SUBSEP a[3]; if (!(k in SX)) SX[k] = a[1] }
      while ((getline l < (pd "/dif")) > 0) { split(l, a, "\037"); nd++; if (!(a[2] in DX)) { DX[a[2]] = a[1]; DI[a[2]] = nd } }
      while ((getline l < (pd "/deploy")) > 0) { split(l, a, "\037"); np++; if (!(a[2] in DP)) { DP[a[2]] = a[1]; PI[a[2]] = np } }
      while ((getline l < (pd "/owed")) > 0) OW[l] = 1
      FS = "\n"; scope = (rid != "") ? rid : cls }
    $0 == "" { next }
    { line = $0; sp = index(line, " "); tag = sp ? substr(line, 1, sp - 1) : line; rest = sp ? substr(line, sp + 1) : line
      if (tag == "population") { pop += rest; next }
      if (tag == "ok") { pop++; okc++; next }
      if (tag != "orphan") next
      pop++
      sp = index(rest, " "); subj = sp ? substr(rest, 1, sp - 1) : rest; det = substr(rest, length(subj) + 1); sub(/^ /, "", det)
      k = subj SUBSEP scope
      if (k in EX) { print "EXC   " nm "  " subj "  (" EX[k] ": " ER[k] ")"; exc++; next }
      if (k in SX) { print "SUP   " nm "  " subj "  (" SX[k] " — extractor gap, to-do)"; sup++; next }
      if (cls == "divergence" && (subj in DX)) { print "DIF   " nm "  " subj "  live: " det "  (ratified " DX[subj] ")"; next }
      if (nm == "dead-path.topology") {
        c = index(subj, ":"); bare = c ? substr(subj, c + 1) : subj; hit = ""
        # the first row in order naming the subject or the bare subject
        if ((subj in DX) && (!(bare in DX) || DI[subj] <= DI[bare])) hit = DX[subj]; else if (bare in DX) hit = DX[bare]
        if (hit == "") { if ((subj in DP) && (!(bare in DP) || PI[subj] <= PI[bare])) hit = DP[subj]; else if (bare in DP) hit = DP[bare] }
        if (hit != "") { print "DIF   " nm "  " subj "  " det " — a platform-only consumer (ratified " hit "; its platform half is paid at deploy gate 2)"; next } }
      if (debt == "owed" || (subj != "" && (subj in OW))) { print "PEND  " nm "  " subj "  " det " (partner row owed — reported, not failed)"; pend++; next }
      if (cls == "vacuity") { print "VAC   " nm "  " subj "  " det " (report-only — promote or delete on measured FP rate)"; vac++; next }
      if (cls == "rendered") { print "REND  " nm "  " subj "  " det " (report-only §9 — the computed value differs from the canvas value; promote or delete on measured FP rate)"; rend++; next }
      if (cls == "strength") { print "STR   " nm "  " subj "  " det " (report-only — a Tier-0 row whose strongest assertion is existence; promote or delete on measured FP rate)"; str++; next }
      print "FAIL  " nm "  " subj "  " det; orph++ }
    END { printf "%d %d %d %d %d %d %d %d %d\n", pop, okc, orph, exc, sup, pend, vac, rend, str > cf }' "$PD/j.$JN"
  IFS=' ' read -r pop okc orph exc sup pend vac rend str < "$PD/c.$JN"
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
# v0.9.7.3 (R4): one job per distinct extractor path, numbered in order of
# first use (the class extractors, then the rule rows' paths) — `p<k> <path>`
{ for x in $EXTRACTORS; do isclass "$x" && printf '%s\n' "$x"; done
  awk -F'\037' '{ c = $2; if (c ~ /^checks\/extractors\//) print c }' "$PD/rules" | while IFS= read -r c; do [ -f "$c" ] && printf '%s\n' "$c"; done
} | awk '!s[$0]++ { print "p" NR " " $0 }' > "$XD/list" || true
if [ "$NJ" -gt 1 ] && [ -s "$XD/list" ]; then
  awk '{ print NR }' "$XD/list" | xargs -n 1 -P "$NJ" sh -c 'l=$(sed -n "${1}p" "$0/list"); k=${l%% *}; x=${l#* }; ST=0; sh "$x" > "$0/$k.out" 2>&1 || ST=$?; echo "$ST" > "$0/$k.st"' "$XD" || true
fi
# runx <path>: sets ST and OUT — that path's job files; serially, the path is
# run where it is first judged and its output kept for a later judgement
runx() {
  _k=$(awk -v x="$1" 'substr($0, index($0, " ") + 1) == x { print $1; exit }' "$XD/list")
  if [ "$NJ" -le 1 ] && [ -n "$_k" ] && [ ! -f "$XD/$_k.st" ]; then
    ST=0; OUT=$(sh "$1" 2>&1) || ST=$?; printf '%s' "$OUT" > "$XD/$_k.out"; echo "$ST" > "$XD/$_k.st"
  elif [ -n "$_k" ]; then
    ST=$(cat "$XD/$_k.st" 2>/dev/null || echo 1); OUT=$(cat "$XD/$_k.out" 2>/dev/null || true)
  else
    ST=0; OUT=$(sh "$1" 2>&1) || ST=$?
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
  CI=$((CI + 1)); runx "$x"
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
# v0.9.7.3 (R4): from the parsed records — the census command may contain
# pipes (trailing origin:/proved-red: stripped, fields 4..n-2 rejoined)
while IFS="$US" read -r id cmd test stmt <&3; do
  RI=$((RI + 1))
  debt=active; case "$test" in owed*|OWED*) debt=owed ;; esac
  if [ -z "$cmd" ]; then
    echo "FAIL  $id  rule row has no census command — a rule without a denominator is a hand-list." >&2
    FAILS=$((FAILS + 1)); continue
  fi
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
          runx "$cmd"; RAW=$OUT
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
' "$DECL" | grep -xF -- "$tok" > /dev/null; then OUT="$OUT
ok $site"; else OUT="$OUT
orphan $site undeclared-transition:$tok"; fi ;;
          *)
            if printf '%s
' "$STATES" | grep -xF -- "$tok" > /dev/null; then OUT="$OUT
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
      runx "$cmd"
      [ "$ST" -eq 0 ] || { echo "FAIL  $id  census extractor exited $ST." >&2; FAILS=$((FAILS + 1)); continue; } ;;
    *' :: '*)
      left=${cmd%% :: *}; right=${cmd#* :: }
      run_enum "$left"; L=$(printf '%s\n' "$RUN_OUT" | sort -u); LERR=$RUN_ERR
      run_enum "$right"; R=$(printf '%s\n' "$RUN_OUT" | sort -u); RERR=$RUN_ERR
      if [ -n "$LERR$RERR" ]; then
        echo "FAIL  $id  census command wrote to standard error — a failing arm must never silently shrink a population: ${LERR:-$RERR}" >&2
        FAILS=$((FAILS + 1)); continue
      fi
      printf '%s\n' "$R" > "$PD/right"
      OUT=$(printf '%s\n' "$L" | awk -v rf="$PD/right" 'BEGIN { while ((getline l < rf) > 0) R[l] = 1 } $0 != "" { if ($0 in R) print "ok " $0; else print "orphan " $0 " unguarded" }') ;;
    *)
      run_enum "$cmd"
      if [ -n "$RUN_ERR" ]; then
        echo "FAIL  $id  census command wrote to standard error — a failing arm must never silently shrink a population: $RUN_ERR" >&2
        FAILS=$((FAILS + 1)); continue
      fi
      OUT=$(printf '%s\n' "$RUN_OUT" | grep -v '^[[:space:]]*$' | sed 's/^/ok /' || true) ;;
  esac
  judge invariant "$id" "$id" "$OUT" "$debt"
done 3< "$PD/rules"

# --- Divergence table — what the green ledger did NOT validate --------------
if [ -n "$DIFS" ]; then
  echo ''
  echo 'divergences (ratified — the green ledger did not validate these):'
  awk -F'\037' '{ printf "    %s  %s  test=%s  prod=%s  %s\n", $1, $2, $3, $4, $5 }' "$PD/dif"
fi
if [ -n "$SUPS" ]; then
  echo ''
  echo 'suppressions (extractor to-do — never counted toward the ceremony threshold):'
  awk -F'\037' '{ printf "    %s  %s  %s  gap: %s  fix-by: %s\n", $1, $3, $2, $4, $5 }' "$PD/sup"
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
