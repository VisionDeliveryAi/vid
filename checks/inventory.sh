#!/bin/sh
# Purpose: ViD court — the Test Inventory as a court input. Reads the
# ```vid-inventory block in INVENTORY.md (ROW-NNN | kind | subject |
# actor/state | marker | obligation | derived-from | test, plus optional
# trailing "origin:" / "proved-red:" fields; the v0.7 row classes
# rule/difference/exception/suppression are judged by checks/census.sh) and
# the project's route table from the generated, ratified route extractor
# (checks/extractors/routes.sh, "ok <route>" lines — the plugin ships no
# framework parser; the extractor encodes the scaffold's routing convention).
# Default fails closed on a code route with no inventory row, and on a row
# citing a ledger test that does not exist (promissory refs are invalid).
# Once any row carries proved-red, a row citing a test WITHOUT proved-red
# counts as owed — an unproved test is not evidence (§3.6). Hostility rows
# (hostility | HOS-NNN | attempt | protects: | disable: | test, §4) are the
# fail-first ritual's mechanical half and are judged harder: a missing
# protects:, a missing or "none" disable: toggle, and a cited probe with no
# proved-red are GAPs that fail the commit, because a probe never observed
# failing is evidence with the polarity that reassures. --strict
# additionally fails on rows still owed, on a Tier-0 rule row with no
# hostility sibling, and on orphan surfaces (a static route no other
# app-source file links to). --report prints everything and
# always exits 0 (the coverage join's input). Presence-gated: inactive when
# INVENTORY.md is absent; route-table checks inactive (stated, never silent)
# when no routes extractor exists.
# v0.8.1d, inside a repository: (1) a cited test path resolves against the
# commit under construction — the staged index, then HEAD — never the
# working tree (a row citing a worktree-only file fails its law commit:
# the citation-order court), and must be a file, not a directory; (2) the
# proved-red stamp is JOINED, not merely present — the sha resolves, the
# cited file exists at it, and the file there names the row (its id or its
# REQ) — H-17 measured 22 rows citing a file absent at the stamped sha and
# 34 citing a file that never names the row; default mode joins the rows
# this commit stages, --strict/--report join every row; (3) a golden-set
# row's `divergence: DIF-NNN` must name a difference row that exists and
# carries `paying-step:`, and its `golden:` fixture must exist at the commit.
# All three count under missing-tests (the coverage join's bucket).
# v0.9.2 (3.2, R3/R4; 3.10, R15), gated on the block's first line inside the
# fence being `grammar: 0.9.2`: an owed reason reads `owed: <class> —
# <detail>` with class in the closed table (templates/INVENTORY.md) and a
# non-empty detail — anything else is a GAP at every commit (`unclassed
# deferral`); the summary's `owed=O` keeps its name and position (the
# coverage join reads it) and gains the per-class split with `other=J`; a
# `par:` line over the ROW rows (materialised + legitimate + deploy-owed =
# rows, other = 0) is the red gate's denominator; a seam with `credentials:
# not-yet` born `probe: owed` is a GAP — the legal shape is
# `unreachable-risk(credentials not-yet)`. A block without the line keeps
# the pre-0.9.2 reading, byte-identical.
# v0.9.3 (3.13, R22), gated on `grammar: 0.9.3` as that first line — which
# also applies every 0.9.2 check above: every seam whose `probe:` is `owed`
# is OWED completion debt, named, whatever its credentials and whether or
# not client code touches it (0.9.2 rejected only the `not-yet` + `owed`
# pair, and seams.sh judges only staged client lines, so an owed seam no
# client touched survived "complete"); the coverage join consumes it with
# the other counters. The summary's parenthetical gains `seam-probes=S`.
# v0.9.7.2 (3.3, R4): `protected` prints the rows a breadth-first plan may
# never place in a hardening step, by this court's own tier reading and its
# hostility join. v0.9.7.3 (3.11, R11) narrows it to three routes: a row
# derived from a Tier-0 PRD item — a Tier-0 requirement of 2d or a Tier-0
# invariant (INV-), the effective set, amendments applied, `later` items left
# out — (`from=<REQ|INV>`), or named by a hostility row's protects: by its
# ROW id (`from=<HOS>`); the plan's `protected:` line is the third, read by
# checks/plan.sh. The rule-origin tie and a probe's REQ or rule target
# reaching every row tied to it are gone. Then `owed <ROW> by=<id>` for each
# obligation joined to a protected row by the same routes: an unpaid
# hostility row (its test owed, or cited without proved-red) naming it by ROW
# id, or protecting — in 2d's per-probe meaning (prot_reqs) — a Tier-0 item
# it derives from (HOS-…); a Tier-0 item it derives from that no probe
# protects (REQ-…, INV-…). Other obligations remain completion debt through
# --strict and coverage, unchanged. Last `protected rows=<n> owed=<k>`. Read
# by checks/plan.sh (the placement check) and checks/metrics.sh step-state
# (done). A reader: it writes nothing and needs no placement block.
# v0.9.8 (3.3, R6): --report also lists `authority-changed row=<id> since=<commit> what=<ids>` for each row whose
# authority bundle changed since it was last looked at (checks/brief.sh authority --changed), then `authority:
# changed=<n>` — a flag, never a wipe, and never a gate.
# Usage: sh checks/inventory.sh [--strict|--report|protected]
set -eu
IFS='
'

MODE=default
case "${1:-}" in --strict) MODE=strict ;; --report) MODE=report ;; protected) MODE=protected ;; esac

# Presence-gated: silent when inactive — courts speak only to reject or report.
[ -f INVENTORY.md ] || exit 0
PREFIXES=''
if [ "$MODE" != protected ]; then
[ -f CLAUDE.md ] || { echo 'ViD inventory: CLAUDE.md missing — failing closed.' >&2; exit 1; }
PREFIXES=$(sed -n '/^```vid-placement/,/^```$/p' CLAUDE.md | sed '1d;$d' | sed 's/[[:space:]]*$//' | grep -v '^$' || true)
[ -n "$PREFIXES" ] || { echo 'ViD inventory: no ```vid-placement block in CLAUDE.md — failing closed.' >&2; exit 1; }
fi

BLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
GRAMMAR=legacy; G93=no
case "$(printf '%s\n' "$BLOCK" | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in 'grammar: 0.9.2') GRAMMAR=0.9.2 ;; 'grammar: 0.9.3') GRAMMAR=0.9.2; G93=yes ;; esac
# v0.9.3 (3.13, R17): a --report run under 0.9.3 appends `court
# name=inventory seconds=<s>`; a caller that is itself a court or a reporter
# sets VID_COURT_EVENT=off.
if [ "$G93" = yes ] && [ "$MODE" = report ] && [ "${VID_COURT_EVENT:-on}" != off ]; then
  CT0=$(date +%s)
  trap 'mkdir -p .vid; printf "court name=inventory seconds=%s at=%s\n" "$(( $(date +%s) - CT0 ))" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/metrics-events' EXIT
fi
SEAMS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*seam[[:space:]]*\|' || true)
ROWS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*ROW-' || true)
RULES=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*rule[[:space:]]*\|' || true)
HOSTS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*hostility[[:space:]]*\|' || true)
# field and labeled are pure shell (v0.9.2): the court runs at every commit
# over hundreds of rows, and three processes per field read was the cost.
# Same answers as the cut/sed forms they replace: the n-th '|' field
# trimmed (a row with no '|' is its own first field, as cut reads it); the
# first field opening `<label>:`, its value trimmed, empty when absent.
field() { # $1=row $2=n
  _r=$1; _i=1
  case "$_r" in *'|'*) ;; *) _i=$2 ;; esac
  while [ "$_i" -lt "$2" ]; do
    case "$_r" in *'|'*) _r=${_r#*|} ;; *) _r=''; break ;; esac
    _i=$((_i + 1))
  done
  _r=${_r%%|*}
  _r=${_r#"${_r%%[!	 ]*}"}; _r=${_r%"${_r##*[!	 ]}"}
  printf '%s\n' "$_r"
}
labeled() { # $1=row $2=label — value of a labeled field, empty if absent
  _rest=$1
  while :; do
    case "$_rest" in *'|'*) _f=${_rest%%|*}; _rest=${_rest#*|} ;; *) _f=$_rest; _rest='' ;; esac
    _f=${_f#"${_f%%[!	 ]*}"}
    case "$_f" in "$2:"*)
      _f=${_f#"$2:"}; _f=${_f#"${_f%%[!	 ]*}"}; _f=${_f%"${_f##*[!	 ]}"}
      printf '%s\n' "$_f"; return 0 ;;
    esac
    [ -n "$_rest" ] || return 0
  done
}
# the last field once trailing labeled fields are stripped — the test field
# of a rule or hostility row, whose earlier fields may contain '|'.
lastfield() { printf '%s\n' "$1" | awk -F'|' '{ n=NF; while (n > 3 && $n ~ /^[[:space:]]*(origin|proved-red|paid-at):/) n--; print $n }' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
# rule_tier <rule row>: its tier field (2c); is_t0 <tier>: the spellings read as Tier 0
rule_tier() { printf '%s\n' "$1" | awk -F'|' '{ n=NF; while (n > 4 && $n ~ /^[[:space:]]*(origin|proved-red|paid-at):/) n--; if (n >= 6) print $(n-1) }' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
is_t0() { case "$1" in 0|T0|t0|tier-0|tier0|Tier-0) return 0 ;; *) return 1 ;; esac; }
# hos_targets: every id a hostility row's protects: names (2c)
hos_targets() { for h in $HOSTS; do labeled "$h" protects; done | tr ' ,' '\n\n' | grep -v '^$' | sort -u || true; }
# t0reqs: the Tier-0 demand items of PRD.md (2d) — the effective set, phase-aware
t0reqs() {
  [ -f PRD.md ] || return 0
  if grep -q '^```vid-prd$' PRD.md; then
    sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' '{
      id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
      t=$2; gsub(/^[ \t]+|[ \t]+$/,"",t); tier=$3; gsub(/^[ \t]+|[ \t]+$/,"",tier); ph="pilot";
      for (i=4;i<=NF;i++) { f=$i; gsub(/^[ \t]+|[ \t]+$/,"",f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/,"",f); ph=f } }
      if (id ~ /^REQ-[0-9]+$/) {
        row[id] = (tier == "T0" && ph == "pilot" && (t == "functional" || t == "nfr" || t == "ux_flow" || t == "data_entity")) ? "y" : "n";
        if (!(id in seen)) { order[++n] = id; seen[id] = 1 }
      }
    } END { for (i = 1; i <= n; i++) if (row[order[i]] == "y") print order[i] }'
  else
    grep -E '^### REQ-[0-9]+( AMENDED)? \(' PRD.md | awk '{
      id=$2; tier=""; if (match($0, /\([^)]*\)/)) tier=substr($0, RSTART+1, RLENGTH-2);
      last[id]=tier; if (!(id in seen)) { order[++n]=id; seen[id]=1 }
    } END { for (i = 1; i <= n; i++) if (last[order[i]] == "T0") print order[i] }'
  fi
}
# prot_reqs <targets>: the REQs a probe protects (2d) — named, carried by a protected rule row's origin:, or a protected ROW row's derived-from or origin:
prot_reqs() {
  printf '%s\n' "$1"
  for p in $1; do
    case "$p" in
      RULE-*)
        prow=$(printf '%s\n' "$RULES" | grep -E "^[[:space:]]*rule[[:space:]]*\|[[:space:]]*$p[[:space:]]*\|" | head -n 1 || true)
        [ -n "$prow" ] && labeled "$prow" origin | tr ' ,' '\n\n' ;;
      ROW-*)
        prow=$(printf '%s\n' "$ROWS" | grep -E "^[[:space:]]*$p[[:space:]]*\|" | head -n 1 || true)
        [ -n "$prow" ] && { field "$prow" 7 | tr ' ,' '\n\n'; labeled "$prow" origin | tr ' ,' '\n\n'; } ;;
    esac
  done
}
# t0invs: the Tier-0 invariants of PRD.md's vid-prd block (v0.9.7.3, R11) — the effective set, `later` left out
t0invs() {
  [ -f PRD.md ] && grep -q '^```vid-prd$' PRD.md || return 0
  sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' '{
    id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id); tier=$3; gsub(/^[ \t]+|[ \t]+$/,"",tier); ph="pilot";
    for (i=4;i<=NF;i++) { f=$i; gsub(/^[ \t]+|[ \t]+$/,"",f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/,"",f); ph=f } }
    if (id ~ /^INV-[0-9]+$/) { row[id] = (tier == "T0" && ph == "pilot") ? "y" : "n"; if (!(id in seen)) { order[++n] = id; seen[id] = 1 } }
  } END { for (i = 1; i <= n; i++) if (row[order[i]] == "y") print order[i] }'
}
# --- v0.9.7.2 (3.3, R4), narrowed by v0.9.7.3 (3.11, R11): the protected rows and their unpaid hostility obligations ---
if [ "$MODE" = protected ]; then
  PT=$(mktemp -d); trap 'rm -rf "$PT"' EXIT
  for r in $ROWS; do printf '%s\t%s\n' "$(field "$r" 1)" "$(field "$r" 7)"; done > "$PT/rows"
  { t0reqs; t0invs; } > "$PT/t0req"
  : > "$PT/hos"; : > "$PT/hreq"; for h in $HOSTS; do
    t=$(lastfield "$h"); paid=no; hid=$(field "$h" 2)
    case "$t" in tests/*) printf '%s\n' "$h" | grep -q 'proved-red:' && paid=yes ;; esac
    printf '%s\t%s\t%s\n' "$hid" "$(labeled "$h" protects)" "$paid" >> "$PT/hos"
    # the items this probe protects in 2d's meaning: named, or carried by a named rule row's origin: or a named row's derived-from
    prot_reqs "$(labeled "$h" protects | tr ' ,' '\n\n' | grep -v '^$' || true)" | grep -v '^$' | sort -u | while read -r q; do printf '%s\t%s\n' "$hid" "$q"; done >> "$PT/hreq"
  done
  TG=$(hos_targets); prot_reqs "$TG" | grep -v '^$' | sort -u > "$PT/protreqs"
  awk -F'\t' -v pd="$PT" '
    function ids(s, A,   n, k, t) { split("", A); n = split(s, t, /[ ,]+/); for (k = 1; k <= n; k++) if (t[k] != "") A[t[k]] = 1 }
    function prot(r, why) { if (!(r in P)) { P[r] = why; O[++no] = r } else if (index("," P[r] ",", "," why ",") == 0) P[r] = P[r] "," why }
    function owe(r, by) { if (!((r, by) in W)) { W[r, by] = 1; WO[++nw] = r "\t" by } }
    BEGIN {
      while ((getline l < (pd "/rows")) > 0) { split(l, a, "\t"); R[++nr] = a[1]; ISROW[a[1]] = 1; ids(a[2], X); for (q in X) DER[a[1], q] = 1 }
      while ((getline l < (pd "/t0req")) > 0) T0[l] = 1
      while ((getline l < (pd "/protreqs")) > 0) PR[l] = 1
      while ((getline l < (pd "/hos")) > 0) { split(l, a, "\t"); HP[a[1]] = a[2]; HPD[a[1]] = a[3]; HL[++nh] = a[1] }
      # route 1: derived from a Tier-0 requirement or invariant
      for (j = 1; j <= nr; j++) { r = R[j]; for (q in T0) if ((r, q) in DER) prot(r, q) }
      # route 2: a hostility row names it by its ROW id; owed while that probe is unpaid
      for (i = 1; i <= nh; i++) { h = HL[i]; ids(HP[h], X)
        for (t in X) if (t ~ /^ROW-/ && (t in ISROW)) { prot(t, h); if (HPD[h] != "yes") owe(t, h) } }
      # an unpaid probe protecting (2d, per probe) a Tier-0 item a row derives from
      while ((getline l < (pd "/hreq")) > 0) { split(l, a, "\t"); if ((a[2] in T0) && HPD[a[1]] != "yes") for (j = 1; j <= nr; j++) if ((R[j], a[2]) in DER) owe(R[j], a[1]) }
      # a Tier-0 item no probe protects (the OWED lines of 2d)
      for (q in T0) if (!(q in PR)) for (j = 1; j <= nr; j++) if ((R[j], q) in DER) owe(R[j], q)
      for (k = 1; k <= no; k++) print "protected " O[k] " from=" P[O[k]]
      for (k = 1; k <= nw; k++) { split(WO[k], a, "\t"); print "owed " a[1] " by=" a[2] }
      printf "protected rows=%d owed=%d\n", no, nw
    }'
  exit 0
fi

SUBJECTS=$(for r in $ROWS; do field "$r" 3; done | sort -u || true)
DIFS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*difference[[:space:]]*\|' || true)

# --- The commit under construction ------------------------------------------
INGIT=no
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && INGIT=yes
# the rows this commit stages (default mode joins only these; strict/report all)
STAGEDROWS=''
[ "$INGIT" = yes ] && STAGEDROWS=$(git diff --cached -U0 -- INVENTORY.md 2>/dev/null | grep '^+' | grep -v '^+++' | sed 's/^+//' || true)
# the files the commit under construction carries: the index, then HEAD —
# listed once (blobs only, so a directory can never be cited as a test)
CITABLE=''
[ "$INGIT" = yes ] && CITABLE=$( { git ls-files --cached 2>/dev/null; git ls-tree -r --name-only HEAD 2>/dev/null; } | sort -u || true)
cited_exists() { # $1=path — index, then HEAD, never the worktree; a file, never a directory
  if [ "$INGIT" = yes ]; then
    printf '%s\n' "$CITABLE" | grep -qxF "$1"
  else
    [ -f "$1" ]
  fi
}
# v0.9.2 3.2: the closed deferral vocabulary. owed_class prints the class
# word of a legal `owed: <class> — <detail>` field, or `unclassed`.
LGF=0; LCA=0; LPC=0; LGS=0; LFS=0; LPR=0; LOD=0; LRV=0; OTHER=0
PN=0; PK=0; PD=0; PJ=0   # the par, over ROW rows: materialised · legitimate · deploy-owed · other
owed_class() { # $1=the test field
  r=$(printf '%s\n' "$1" | sed 's/^[Oo][Ww][Ee][Dd]:[[:space:]]*//')
  c=${r%% *}
  rest=$(printf '%s\n' "${r#"$c"}" | sed 's/^[[:space:]]*//')
  case "$rest" in
    '— '*) det=$(printf '%s\n' "$rest" | sed 's/^—[[:space:]]*//;s/[[:space:]]*$//') ;;
    '– '*) det=$(printf '%s\n' "$rest" | sed 's/^–[[:space:]]*//;s/[[:space:]]*$//') ;;
    '- '*) det=$(printf '%s\n' "$rest" | sed 's/^-[[:space:]]*//;s/[[:space:]]*$//') ;;
    *) det='' ;;
  esac
  [ -n "$det" ] || { echo unclassed; return 0; }
  case "$c" in
    guard-first|census-armed|probe-capture|golden-set|fixture-source|prerequisite|reverted) echo "$c" ;;
    owner-decision) case "$det" in OQ-[0-9]*) echo "$c" ;; *) echo unclassed ;; esac ;;
    *) echo unclassed ;;
  esac
}
count_class() { case "$1" in guard-first) LGF=$((LGF + 1)) ;; census-armed) LCA=$((LCA + 1)) ;; probe-capture) LPC=$((LPC + 1)) ;; golden-set) LGS=$((LGS + 1)) ;; fixture-source) LFS=$((LFS + 1)) ;; prerequisite) LPR=$((LPR + 1)) ;; owner-decision) LOD=$((LOD + 1)) ;; reverted) LRV=$((LRV + 1)) ;; esac; }
owed_row() { # $1=id $2=subject $3=test field $4=row|other — the OWED line, classed under 0.9.2
  if [ "$GRAMMAR" = 0.9.2 ]; then
    c=$(owed_class "$3")
    if [ "$c" = unclassed ]; then
      echo "GAP  $1 ($2) — unclassed deferral '$3': under grammar 0.9.2 a deferral is \"owed: <class> — <detail>\" with the class in the closed table (templates/INVENTORY.md) and the detail naming what is missing and when it is paid; a reason that describes a red test is a test to write."
      OTHER=$((OTHER + 1)); OWED=$((OWED + 1)); if [ "$4" = row ]; then PJ=$((PJ + 1)); fi
    else
      echo "OWED  $1 ($2) — $3"
      OWED=$((OWED + 1)); count_class "$c"; if [ "$4" = row ]; then PK=$((PK + 1)); fi
    fi
  else
    echo "OWED  $1 ($2) — $3"
    OWED=$((OWED + 1))
  fi
  return 0
}
proved_join() { # $1=id $2=path $3=sha $4=names the file must carry (space-separated) $5=whole row
  [ "$INGIT" = yes ] || return 0
  if [ "$MODE" = default ]; then printf '%s\n' "$STAGEDROWS" | grep -qxF "$5" || return 0; fi
  if ! git cat-file -e "$3^{commit}" 2>/dev/null; then
    echo "GAP  $1 — proved-red '$3' resolves to no commit; the stamp names where the test was observed red, and nowhere is not a place."
    MISSING_TESTS=$((MISSING_TESTS + 1)); return 0
  fi
  if [ "$(git cat-file -t "$3:$2" 2>/dev/null)" != blob ]; then
    echo "GAP  $1 — cites '$2' with proved-red $3, but the file does not exist at that commit; a test cannot have been red where it did not exist."
    MISSING_TESTS=$((MISSING_TESTS + 1)); return 0
  fi
  pat=$(printf '%s\n' "$4" | tr ' ,' '\n\n' | grep -v '^$' | paste -sd '|' -)
  if ! git show "$3:$2" 2>/dev/null | grep -qE "$pat"; then
    echo "GAP  $1 — '$2' at proved-red $3 never names the row ($4); the observed red was some other row's."
    MISSING_TESTS=$((MISSING_TESTS + 1)); return 0
  fi
}

# --- Route table — from the generated, ratified route extractor ------------
ROUTESRC=no
ROUTES=''
if [ -f checks/extractors/routes.sh ]; then
  ROUTESRC=yes
  ROUTES=$(sh checks/extractors/routes.sh 2>/dev/null | sed -n 's/^ok //p' | sort -u || true)
fi

# proved-red contract (§3.6) is active once any row carries the field —
# pre-v0.7 inventories are unaffected until they adopt it.
PROVED_ACTIVE=no
printf '%s\n' "$BLOCK" | grep -q 'proved-red:' && PROVED_ACTIVE=yes

GAPS=0; OWED=0; ORPHANS=0; MISSING_TESTS=0; HGAPS=0; NT0=0; DEPLOYOWED=0

# 1. Route-table diff — a route in code with no inventory row fails the commit.
if [ "$ROUTESRC" = yes ]; then
  for route in $ROUTES; do
    if ! printf '%s\n' "$SUBJECTS" | grep -qxF "$route"; then
      echo "GAP  route $route exists in code but has no row in INVENTORY.md — additions are permitted, never silent."
      GAPS=$((GAPS + 1))
    fi
  done
else
  echo 'note: no checks/extractors/routes.sh — route-table checks inactive (generate and ratify the routes extractor; see seed/extractors/README.md).'
fi

# 2. Rows: owed tests, promissory test refs, unproved tests (§3.6).
check_test() { # $1=id $2=subject $3=test $4=whole-row $5=names the test must carry $6=row|other (the par counts ROW rows)
  case "$3" in
    'owed: paid by /vid deploy gate '[123]*)
      # v0.9.1 3.6: a row only the deployed shape can observe — reported apart
      # from owed debt, paid by /vid deploy's rung and stamped paid-at:
      echo "DEPLOY-OWED  $1 ($2) — $3$(labeled "$4" paid-at | sed 's/^./ [paid-at: &/;s/$/]/;s/^ \[paid-at: \]$//')"
      DEPLOYOWED=$((DEPLOYOWED + 1)); if [ "${6:-}" = row ]; then PD=$((PD + 1)); fi ;;
    owed*|OWED*)
      owed_row "$1" "$2" "$3" "${6:-}" ;;
    tests/*)
      if [ "${6:-}" = row ]; then PN=$((PN + 1)); fi
      tpath=$(printf '%s\n' "$3" | cut -d' ' -f1)
      if ! cited_exists "$tpath"; then
        echo "GAP  $1 cites '$tpath' as its test, but no such file exists at the commit under construction (index, then HEAD) — promissory and worktree-only refs are invalid."
        MISSING_TESTS=$((MISSING_TESTS + 1))
      elif [ "$PROVED_ACTIVE" = yes ] && ! printf '%s\n' "$4" | grep -q 'proved-red:'; then
        echo "OWED  $1 ($2) — unproved: test cited but never observed red (no proved-red field; §3.6)"
        OWED=$((OWED + 1))
      else
        sha=$(labeled "$4" proved-red)
        if [ -n "$sha" ]; then proved_join "$1" "$tpath" "$sha" "$1 $5" "$4"; fi
      fi ;;
    *)
      # fail-closed: a typo'd path or prose in the test field must not
      # silently exit the evidence join.
      echo "GAP  $1 ($2) — unrecognized test field '$3'; use tests/... or \"owed: <reason>\"."
      MISSING_TESTS=$((MISSING_TESTS + 1)); if [ "${6:-}" = row ]; then PJ=$((PJ + 1)); fi ;;
  esac
}
for r in $ROWS; do
  check_test "$(field "$r" 1)" "$(field "$r" 3)" "$(field "$r" 8)" "$r" "$(field "$r" 7)" row
done
for r in $RULES; do
  # the census command may contain '|': take the test as the last field after
  # stripping trailing labeled (origin:/proved-red:) fields.
  check_test "$(field "$r" 2)" "$(field "$r" 3)" "$(lastfield "$r")" "$r" "$(labeled "$r" origin)" other
done

# 2a. Golden-set rows (v0.8.1d): the golden fixture exists at the commit, and
# the named difference row exists and carries its paying step — a deferred
# test with a named step, never a permanent shrug.
for r in $ROWS; do
  id=$(field "$r" 1); g=$(labeled "$r" golden); d=$(labeled "$r" divergence)
  if [ -n "$g" ] && ! cited_exists "$g"; then
    echo "GAP  $id — golden: '$g' does not exist at the commit under construction; a golden set the test cannot read is not ratified."
    MISSING_TESTS=$((MISSING_TESTS + 1))
  fi
  if [ -n "$d" ]; then
    drow=$(printf '%s\n' "$DIFS" | grep -E "^[[:space:]]*difference[[:space:]]*\|[[:space:]]*$d[[:space:]]*\|" | head -n 1 || true)
    if [ -z "$drow" ]; then
      echo "GAP  $id — divergence: $d names no difference row; the divergence a golden set is deferred behind must be ratified."
      MISSING_TESTS=$((MISSING_TESTS + 1))
    elif [ -z "$(labeled "$drow" paying-step)" ]; then
      echo "GAP  $id — $d carries no paying-step:; a divergence on a golden-set path is a deferred test with a named step, never a permanent shrug."
      MISSING_TESTS=$((MISSING_TESTS + 1))
    fi
  fi
done

# 2b. Hostility rows (§4) — the fail-first ritual's mechanical half. Each
# Tier-0 protection gains one sibling row that ATTEMPTS the forbidden thing
# through the real public surface. Judged harder than a ROW row in two
# places: the row must name the reversible toggle that produced the red (so
# the ritual can be re-run), and proved-red is mandatory rather than
# once-active — a probe never watched failing is evidence with the polarity
# that reassures, since "refused" is equally green when the attempt never
# reached the guard.
for h in $HOSTS; do
  id=$(field "$h" 2)
  prot=$(labeled "$h" protects)
  dis=$(labeled "$h" disable)
  t=$(lastfield "$h")
  if [ -z "$prot" ]; then
    echo "GAP  $id has no 'protects:' field — a hostility probe is the sibling of a ratified Tier-0 protection, never free-standing."
    HGAPS=$((HGAPS + 1))
  fi
  case "$dis" in
    ''|none|None|NONE|n/a|N/A|N/a)
      echo "GAP  $id ($prot) — no usable 'disable:' toggle (got '${dis:-<absent>}'). Name the reversible way the protection is turned off, or the probe can never be watched failing (§4.2)."
      HGAPS=$((HGAPS + 1)) ;;
  esac
  case "$t" in
    owed*|OWED*)
      owed_row "$id" "$prot" "$t" other ;;
    tests/*)
      tpath=$(printf '%s\n' "$t" | cut -d' ' -f1)
      if ! cited_exists "$tpath"; then
        echo "GAP  $id cites '$tpath' as its probe, but no such file exists at the commit under construction (index, then HEAD) — promissory and worktree-only refs are invalid."
        MISSING_TESTS=$((MISSING_TESTS + 1))
      elif ! printf '%s\n' "$h" | grep -q 'proved-red:'; then
        echo "GAP  $id ($prot) — rejected at materialisation: probe cited but never observed red (no proved-red; §4.2). Disable the protection by its own toggle, watch the probe fail on its assertion, restore, watch it pass, then stamp the sha."
        HGAPS=$((HGAPS + 1))
      else
        proved_join "$id" "$tpath" "$(labeled "$h" proved-red)" "$id $prot" "$h"
      fi ;;
    *)
      echo "GAP  $id ($prot) — unrecognized test field '$t'; use tests/... or \"owed: <reason>\"."
      MISSING_TESTS=$((MISSING_TESTS + 1)) ;;
  esac
done

# 2b2. Seams without credentials (v0.9.2 3.10, R15): under grammar 0.9.2 a
# seam with `credentials: not-yet` is born `probe: unreachable-risk(credentials
# not-yet)`, never `owed` — the client is written against the documented
# contract and the probe is paid in full at deploy gate 2. Born owed, it
# blocks its own client code for as long as nobody holds the credentials.
if [ "$GRAMMAR" = 0.9.2 ]; then
  for sm in $SEAMS; do
    sid=$(field "$sm" 2); cred=$(labeled "$sm" credentials); prb=$(labeled "$sm" probe)
    case "$cred" in not-yet) case "$prb" in owed*|OWED*)
      echo "GAP  $sid ($(field "$sm" 3)) — credentials: not-yet born probe: owed; ratify probe: unreachable-risk(credentials not-yet) and pay the probe in full at deploy gate 2 (v0.9.2 3.10)."
      OTHER=$((OTHER + 1)) ;; esac ;; esac
  done
fi
# 2b3. v0.9.3 (3.13): an owed seam probe is completion debt, named.
SEAMOWED=0
if [ "$G93" = yes ]; then
  for sm in $SEAMS; do
    case "$(labeled "$sm" probe)" in owed*|OWED*)
      echo "OWED  $(field "$sm" 2) ($(field "$sm" 3)) — probe: owed — an owed seam probe is completion debt whether or not client code touches it; pay it (probed) or ratify unreachable-risk(reason) (v0.9.3 3.13)"
      OWED=$((OWED + 1)); SEAMOWED=$((SEAMOWED + 1)) ;; esac
  done
fi

# 2c. Tier-0 completeness — every Tier-0 rule row has a hostility sibling.
# Debt, not a commit gate: the rule may land before its probe (law first),
# but the product is not done while a must-never-happen has never been
# attempted. Blocks --strict, the same standing as any owed row.
PROTECTED=$(hos_targets)
for r in $RULES; do
  rid=$(field "$r" 2)
  is_t0 "$(rule_tier "$r")" || continue
  NT0=$((NT0 + 1))
  printf '%s\n' "$PROTECTED" | grep -qxF "$rid" && continue
  echo "OWED  $rid (Tier-0) — no hostility sibling: this protection has never been attempted, only read (§4.1)."
  OWED=$((OWED + 1))
done

# 2d. Tier-0 demand items owe a sibling too (v0.8.1b): a T0 protection may
# be a PRD requirement rather than a rule row. The T0 set is read from
# PRD.md — the enriched grammar's ```vid-prd rows (effective set: a later
# AMENDED row wins; demand types only, invariants land as rule rows) or
# the block form's "### REQ-NNN (T0)" headings. A probe protects a REQ by
# naming it, or by naming a rule row whose origin: carries it, or a ROW
# row derived from it. Same standing as 2c: debt, blocks --strict. The T0
# set is phase-aware (v0.9.1 3.6, R12-i): a `later` T0 item owes no
# sibling until an amendment moves it.
if [ -f PRD.md ]; then
  T0REQS=$(t0reqs)
  PROTREQS=$(prot_reqs "$PROTECTED")
  for q in $T0REQS; do
    NT0=$((NT0 + 1))
    printf '%s\n' "$PROTREQS" | grep -qxF "$q" && continue
    echo "OWED  $q (Tier-0 item) — no hostility sibling: this protection has never been attempted, only read (§4.1)."
    OWED=$((OWED + 1))
  done
fi

# 3. Orphans — a surface row's static route that exists in code but is linked
# from no other app-source file has no door (F1: correct rooms, no doors).
if [ "$ROUTESRC" = yes ]; then
  for r in $ROWS; do
    kind=$(field "$r" 2); subject=$(field "$r" 3)
    [ "$kind" = surface ] || continue
    case "$subject" in /) continue ;; /*\[*|/*\<*|/*:*) continue ;; /*) ;; *) continue ;; esac
    printf '%s\n' "$ROUTES" | grep -qxF "$subject" || continue
    LINKED=no
    for p in $PREFIXES; do
      case "$p" in tests*|checks*|design*) continue ;; esac
      [ -e "$p" ] || continue
      if grep -rE "(\"$subject[\"?]|'$subject['?]|\`$subject[\`?])" --exclude='*.md' "$p" 2>/dev/null \
        | grep -vE "^[^:]*$subject[^:]*:" | grep -q .; then
        LINKED=yes; break
      fi
    done
    if [ "$LINKED" = no ]; then
      echo "ORPHAN  $subject is built and inventoried but no app source links to it — unreachable from any navigation."
      ORPHANS=$((ORPHANS + 1))
    fi
  done
fi

# 4. Guard before probe (v0.9.3 3.5, R6), --report under 0.9.3: for each
# hostility row (`protects:`) and each control sibling (`control of ROW-NNN`)
# one line naming its target's state, read through `sh checks/metrics.sh
# row-state` — the headline's own computation per row, an early exit that
# runs neither the census nor the selftest. Nothing else is printed: no
# REQ→module assignment exists to print (the owner ruled against a serves:
# column), and transitions, stages and trigger rows carry no ids.
if [ "$G93" = yes ] && [ "$MODE" = report ] && [ -f checks/metrics.sh ]; then
  GP=''
  for h in $HOSTS; do
    for tg in $(labeled "$h" protects | tr ' ,' '\n\n' | grep -v '^$'); do GP="$GP$(field "$h" 2) protects $tg
"; done
  done
  for r in $ROWS; do
    tg=$(field "$r" 6 | sed -n 's/^control of \(ROW-[0-9A-Za-z]*\).*/\1/p')
    [ -n "$tg" ] && GP="$GP$(field "$r" 1) control of $tg
"
  done
  if [ -n "$GP" ]; then
    TGS=$(printf '%s' "$GP" | awk '{print $NF}' | sort -u | tr '\n' ' ')
    GST=$(IFS=' '; sh checks/metrics.sh row-state $TGS 2>/dev/null || true)
    for gp in $(printf '%s' "$GP"); do
      tg=${gp##* }
      st=$(printf '%s\n' "$GST" | sed -n "s/^$tg: //p" | head -n 1)
      echo "guard $gp: ${st:-unknown (no state computed)}"
    done
  fi
fi

NROWS=$(printf '%s\n' "$ROWS" | grep -c . || true)
NROUTES=$(printf '%s\n' "$ROUTES" | grep -c . || true)
echo ''
NHOST=$(printf '%s\n' "$HOSTS" | grep -c . || true)
OWEDSTR="owed=$OWED"
if [ "$GRAMMAR" = 0.9.2 ]; then
  LEGIT=$((LGF + LCA + LPC + LGS + LFS + LPR + LOD + LRV))
  OWEDSTR="owed=$OWED (legitimate=$LEGIT: guard-first=$LGF census-armed=$LCA probe-capture=$LPC golden-set=$LGS fixture-source=$LFS prerequisite=$LPR owner-decision=$LOD reverted=$LRV; other=$OTHER)"
  if [ "$G93" = yes ]; then OWEDSTR="owed=$OWED (legitimate=$LEGIT: guard-first=$LGF census-armed=$LCA probe-capture=$LPC golden-set=$LGS fixture-source=$LFS prerequisite=$LPR owner-decision=$LOD reverted=$LRV; other=$OTHER; seam-probes=$SEAMOWED)"; fi
fi
echo "inventory: rows=$NROWS routes=$NROUTES route-gaps=$GAPS $OWEDSTR deploy-owed=$DEPLOYOWED orphans=$ORPHANS missing-tests=$MISSING_TESTS hostility=$NHOST tier0=$NT0 hostility-gaps=$HGAPS"
if [ "$GRAMMAR" = 0.9.2 ]; then
  # the par (R4): every ROW row is materialised, legitimately deferred, or deploy-owed — nothing else
  if [ "$PJ" -eq 0 ] && [ $((PN + PK + PD)) -eq "$NROWS" ]; then PARV='holds'; else PARV='FAILS — every row is materialised or legitimately deferred; the gate does not open'; fi
  echo "par: rows=$NROWS materialised=$PN legitimate=$PK deploy-owed=$PD other=$PJ — $PARV"
fi

# v0.9.8 (3.3, R6): authority changes raise a flag, never a wipe — each row whose authority bundle changed since its
# baseline (checks/brief.sh authority --changed: an arm, an owner answer, a decision's rule), then the count. The next
# close's test-author pass revisits it: kept (brief.sh authority --kept) or amended. Verdicts, attempts and holds are untouched; nothing here gates.
if [ "$MODE" = report ] && [ -f checks/brief.sh ] && git rev-parse -q --verify HEAD > /dev/null 2>&1; then
  AUTHC=$(sh checks/brief.sh authority --changed 2>/dev/null | grep '^authority-changed ' || true)
  [ -n "$AUTHC" ] && printf '%s\n' "$AUTHC"
  echo "authority: changed=$(printf '%s\n' "$AUTHC" | grep -c . || true)"
fi

case "$MODE" in
  report) exit 0 ;;
  strict)
    if [ $((GAPS + OWED + ORPHANS + MISSING_TESTS + HGAPS)) -gt 0 ]; then
      echo 'ViD inventory --strict: not done — every route inventoried, every owed row materialised and proved red, every Tier-0 protection attempted by its hostility sibling, every surface reachable.' >&2
      exit 1
    fi ;;
  *)
    if [ $((GAPS + MISSING_TESTS + HGAPS + OTHER)) -gt 0 ]; then
      echo 'ViD inventory: rejected — add the inventory row (and its test, or "owed: <reason>") for every new route; a hostility row names its protects:, its disable: toggle, and the sha where its probe was watched failing; under grammar 0.9.2 every deferral is classed.' >&2
      exit 1
    fi ;;
esac
exit 0
