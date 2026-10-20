#!/bin/sh
# Purpose: ViD evidence join — every REQ-NNN in PRD.md must trace to a citing
# comment under the app-source placement prefixes AND a ledger test in
# tests/invariants/. "cited" means exactly that: a citation, not proof of
# implementation — the ledger tests are the real evidence of behavior.
# --strict exits 1 on any gap or open VID-QUESTION marker.
# v0.9.2 (3.6, R9 — the receipt), under an INVENTORY.md block whose fence
# opens with `grammar: 0.9.2`: with --strict a REQ is ledger-tested only when
# every materialised row derived from it resolves to `passed` in the latest
# EXPORT-BACKED FULL report for HEAD (.vid/ledger-results/<sha>.full.xml, read
# through the generated checks/extractors/results.sh) — every one of the
# row's collected cases (the cases in the cited file naming the row id, else
# its REQ id), each engine and parameter included; skipped, error, absent, a
# report with nothing collected, a `.live.` report or no report at all is
# not green and is named by row (`receipt: none — materialised rows
# unverified`). Without --strict the citation grep stays (the per-commit hook
# runs no container); a pre-0.9.2 block keeps the grep under --strict too.
# v0.9.3 (3.7, 3.10; R11, R15, R22), under a block whose fence opens with
# `grammar: 0.9.3` (which satisfies every 0.9.2 check): --strict takes its
# receipt by the currency rule — the newest <S>.full.xml whose changes since
# lie only under .vid/, its <S>.deployed.xml with it for the deployed
# population — and runs the ROW pass over every materialised row not
# derived solely from a `later` item or a `later:` marker: a row is
# ledger-tested only when its cases pass in the current receipt AND its
# latest eligible verdict is KEPT, whatever it derives from; each failure is
# a gap named by row and counted ONCE; a REQ is ledger-tested only when every
# one of its rows passes, and its line reports those rows without counting
# them again. The per-row state is checks/metrics.sh's row engine (`row-state
# --table`), one computation for the headline, the claim and this pass.
set -eu
IFS='
'

STRICT=0; ROWSF=''
# v0.26.10.5 (R8): --rows <scope file> — the obligation ids (ROW, RULE, DIF, EXC, SUP, HOS) and the PRD items (REQ,
# INV) of stages 1 to N, one per line (sh checks/stages.sh scope --upto N --reqs). Every join then reads only them:
# the pilot set (REQs not in the file are not judged), the ROW pass, the design markers (a marker counts when a
# scoped row binds it or no row does), the inventory reader's GAP/OWED/ORPHAN lines (an id outside the file is left
# out; a line naming no row or item — a route, a seam — counts) and the VID-QUESTION markers (a marker whose ids,
# an OQ carrier read as the items citing it, all lie outside the file is left out). Without it, unchanged.
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --rows) [ -n "${2:-}" ] && [ -f "$2" ] || { echo 'ViD coverage: --rows takes a scope file (sh checks/stages.sh scope --upto N --reqs).' >&2; exit 2; }; ROWSF=$2; shift 2 ;;
    *) shift ;;
  esac
done
SCOPE=''; [ -n "$ROWSF" ] && SCOPE=" $(grep -v '^[[:space:]]*$' "$ROWSF" | tr '\n' ' ') "
inscope() { [ -z "$ROWSF" ] && return 0; case "$SCOPE" in *" $1 "*) return 0 ;; esac; return 1; }
[ -f PRD.md ] || { echo 'ViD coverage: PRD.md missing.' >&2; exit 1; }
[ -f CLAUDE.md ] || { echo 'ViD coverage: CLAUDE.md missing — failing closed.' >&2; exit 1; }

PREFIXES=$(sed -n '/^```vid-placement/,/^```$/p' CLAUDE.md | sed '1d;$d' | sed 's/[[:space:]]*$//' | grep -v '^$' || true)
if [ -z "$PREFIXES" ]; then
  echo 'ViD coverage: no ```vid-placement block in CLAUDE.md — failing closed.' >&2
  exit 1
fi

# The REQ denominator (v0.9.1 3.6, R12-i): under the enriched grammar it is
# the effective set's `pilot` demand items (phase: pilot, the default) — a
# `later` item is listed as deferred and is never a gap; a legacy block-form
# PRD keeps the grep. A pilot REQ is satisfied by a citation and a ledger
# test, or — when every inventory row derived from it is `owed: paid by
# /vid deploy …` — by those rows being present and named (deploy-owed).
LATER=''
if grep -q '^```vid-prd$' PRD.md; then
  EFFROWS=$(sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | awk -F'|' '{
    id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
    rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
    if (!(id in seen)) { order[++n]=id; seen[id]=1 }
  } END { for (i=1;i<=n;i++) print row[order[i]] }' || true)
  phased() { printf '%s\n' "$EFFROWS" | awk -F'|' -v want="$1" '{
    id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); t=$2; gsub(/^[ \t]+|[ \t]+$/,"",t); ph="pilot"
    for (i=3;i<=NF;i++) { f=$i; gsub(/^[ \t]+|[ \t]+$/,"",f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/,"",f); ph=f } }
    if (id ~ /^REQ-[0-9]+$/ && (t=="functional"||t=="nfr"||t=="ux_flow"||t=="data_entity") && ph==want) print id }' | sort -u; }
  REQS=$(phased pilot); LATER=$(phased later)
else
  REQS=$(grep -oE 'REQ-[0-9]+' PRD.md | sort -u)
fi
if [ -n "$ROWSF" ]; then REQS=$(for r in $REQS; do if inscope "$r"; then printf '%s\n' "$r"; fi; done); fi
IBLOCK=''; [ -f INVENTORY.md ] && IBLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
GAPS=0; DEPLOYOWED=0

# --- the receipt (v0.9.2 3.6): strict under the 0.9.2 inventory grammar ---
IGRAMMAR=legacy
case "$(printf '%s\n' "$IBLOCK" | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in 'grammar: 0.9.2') IGRAMMAR=0.9.2 ;; 'grammar: 0.9.3') IGRAMMAR=0.9.3 ;; esac
RECEIPT=''; CASES=''; RECEIPT_LINE=''
# v0.9.3 (3.13, R17): a --strict run under 0.9.3 appends `court name=coverage
# seconds=<s>` (the inventory run inside it records none of its own).
if [ "$STRICT" -eq 1 ] && [ "$IGRAMMAR" = 0.9.3 ] && [ "${VID_COURT_EVENT:-on}" != off ]; then
  CT0=$(date +%s)
  trap 'mkdir -p .vid; printf "court name=coverage seconds=%s at=%s\n" "$(( $(date +%s) - CT0 ))" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/metrics-events' EXIT
fi
if [ "$STRICT" -eq 1 ] && [ "$IGRAMMAR" = 0.9.2 ]; then
  HEADSHA=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)
  if [ -f ".vid/ledger-results/$HEADSHA.full.xml" ]; then
    if [ -f checks/extractors/results.sh ]; then
      RECEIPT=".vid/ledger-results/$HEADSHA.full.xml"
      CASES=$(sh checks/extractors/results.sh "$RECEIPT" 2>/dev/null | grep -E '^case ' || true)
      NC=$(printf '%s\n' "$CASES" | grep -c . || true)
      if [ "$NC" -eq 0 ]; then
        RECEIPT_LINE="receipt: $RECEIPT — nothing collected (0 cases): not green"
      else
        RECEIPT_LINE="receipt: $RECEIPT cases=$NC passed=$(printf '%s\n' "$CASES" | awk '$3=="passed"' | grep -c . || true) failed=$(printf '%s\n' "$CASES" | awk '$3=="failed"' | grep -c . || true) skipped=$(printf '%s\n' "$CASES" | awk '$3=="skipped"' | grep -c . || true) error=$(printf '%s\n' "$CASES" | awk '$3=="error"' | grep -c . || true)"
      fi
    else
      RECEIPT_LINE="receipt: none — .vid/ledger-results/$HEADSHA.full.xml exists but no checks/extractors/results.sh reads it; materialised rows unverified"
    fi
  else
    RECEIPT_LINE="receipt: none — materialised rows unverified (no export-backed full report for HEAD $HEADSHA under .vid/ledger-results/; a .live. report is never certification)"
  fi
  echo "$RECEIPT_LINE"
fi
# row_green <row id> <cited path> <derived-from>: prints nothing when every
# collected case of the row passed; otherwise the reason (one line).
row_green() {
  rc=$(printf '%s\n' "$CASES" | awk -v p="$2::" -v id="$1" 'index($2, p)==1 && index($2, id) { print }')
  if [ -z "$rc" ]; then
    for q in $(printf '%s\n' "$3" | tr ' ,' '\n\n' | grep -v '^$'); do
      rc=$(printf '%s\n' "$CASES" | awk -v p="$2::" -v id="$q" 'index($2, p)==1 && index($2, id) { print }')
      [ -n "$rc" ] && break
    done
  fi
  [ -n "$rc" ] || { echo "absent from the receipt (no collected case in $2 names $1 or its REQ)"; return 0; }
  bad=$(printf '%s\n' "$rc" | awk '$3!="passed" { printf "%s %s; ", $2, $3 }')
  [ -z "$bad" ] || echo "not green: ${bad%; }"
  return 0
}

# --- v0.9.3: the currency rule and the ROW pass (3.7, 3.10) --------------------
TABLE=''; FAILROWS=''
if [ "$STRICT" -eq 1 ] && [ "$IGRAMMAR" = 0.9.3 ]; then
  [ -f checks/metrics.sh ] || { echo 'ViD coverage: grammar 0.9.3 reads the row engine in checks/metrics.sh, which is missing — failing closed.' >&2; exit 1; }
  RL=$(sh checks/metrics.sh receipt)
  RP=$(printf '%s\n' "$RL" | tr ' ' '\n' | sed -n 's/^receipt=//p'); DP=$(printf '%s\n' "$RL" | tr ' ' '\n' | sed -n 's/^deployed=//p')
  if [ "$RP" = none ] || [ -z "$RP" ]; then
    echo "receipt: none — materialised rows unverified (no current export-backed full report for HEAD $(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead): current means every change since it lies under .vid/ — v0.9.3 3.10; a .live. report is never certification)"
  elif [ ! -f checks/extractors/results.sh ]; then
    echo "receipt: none — $RP exists but no checks/extractors/results.sh reads it; materialised rows unverified"
  else
    CASES=$(sh checks/extractors/results.sh "$RP" 2>/dev/null | grep -E '^case ' || true)
    NC=$(printf '%s\n' "$CASES" | grep -c . || true)
    if [ "$NC" -eq 0 ]; then echo "receipt: $RP — nothing collected (0 cases): not green"
    else echo "receipt: $RP cases=$NC passed=$(printf '%s\n' "$CASES" | awk '$3=="passed"' | grep -c . || true) failed=$(printf '%s\n' "$CASES" | awk '$3=="failed"' | grep -c . || true) skipped=$(printf '%s\n' "$CASES" | awk '$3=="skipped"' | grep -c . || true) error=$(printf '%s\n' "$CASES" | awk '$3=="error"' | grep -c . || true)"; fi
  fi
  case "$DP" in none-declared) echo 'deployed: none declared (no deployed-selector: in the harness contract)' ;; none) echo 'deployed: none — the harness declares a deployed shape and no <S>.deployed.xml stands beside the receipt' ;; *) echo "deployed: $DP" ;; esac
  TABLE=$(sh checks/metrics.sh row-state --table)
  LMARK=''; [ -f DESIGN-BRIEF.md ] && LMARK=$(sed -n '/^```vid-design-manifest/,/^```$/p' DESIGN-BRIEF.md | sed '1d;$d' | grep -E '\|[[:space:]]*later:' | sed -E 's/^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*\|[[:space:]]*([A-Za-z0-9_-]+).*/\1\/\2/' || true)
  PASSOUT=$(printf '%s\n' "$TABLE" | awk -F'\t' -v later=" $(printf '%s\n' "$LATER" "$LMARK" | tr '\n' ' ') " -v scope="$SCOPE" '
    $2!="kept" && $2!="unverdicted" && $2!="breached" && $2!="red" { next }
    scope != "" && index(scope, " " $1 " ") == 0 { next }
    $10 ~ /^unrecognized test field/ { next }
    { n=split($9, t, /[ ,]+/); only=1; any=0
      for (k=1;k<=n;k++) { if (t[k]=="") continue; any=1; if (index(later, " " t[k] " ")==0) only=0 }
      if (any && only) next
      if ($2=="kept") next
      print "    GAP  " $1 " — " $10 }')
  if [ -n "$PASSOUT" ]; then
    printf '%s\n' "$PASSOUT"
    GAPS=$((GAPS + $(printf '%s\n' "$PASSOUT" | grep -c . || true)))
    FAILROWS=" $(printf '%s\n' "$PASSOUT" | awk '{ print $2 }' | tr '\n' ' ') "
  fi
fi

printf '%-10s  %-6s  %-5s  %s\n' 'REQ' 'cited' 'test' 'status'
for r in $REQS; do
  C=no
  T=no
  for p in $PREFIXES; do
    case "$p" in tests*|checks*) continue ;; esac
    [ -e "$p" ] || continue
    grep -rq "$r" --exclude='*.md' "$p" 2>/dev/null && { C=yes; break; }
  done
  [ -d tests/invariants ] && grep -rq "$r" tests/invariants 2>/dev/null && T=yes
  if [ "$STRICT" -eq 1 ] && [ "$IGRAMMAR" = 0.9.2 ]; then
    # the receipt decides: every materialised row of this REQ, every case passed
    MROWS=$(printf '%s\n' "$IBLOCK" | awk -F'|' -v id="$r" '$1 ~ /^[[:space:]]*ROW-/ { t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t !~ /^tests\//) next; d=$7; gsub(/^[ \t]+|[ \t]+$/,"",d); n=split(d, parts, /[ ,]+/); for (k=1;k<=n;k++) if (parts[k]==id) { print; break } }' || true)
    T=no
    if [ -n "$MROWS" ]; then
      T=yes
      for mr in $MROWS; do
        rid=$(printf '%s\n' "$mr" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        rpath=$(printf '%s\n' "$mr" | cut -d'|' -f8 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -d' ' -f1)
        rder=$(printf '%s\n' "$mr" | cut -d'|' -f7 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        why=$(row_green "$rid" "$rpath" "$rder")
        if [ -n "$why" ]; then echo "    RED  $rid ($r) — $why"; T=no; fi
      done
    fi
  fi
  RF=''
  if [ "$STRICT" -eq 1 ] && [ "$IGRAMMAR" = 0.9.3 ]; then
    # the ROW pass decides: every materialised row of this REQ passed it
    MR=$(printf '%s\n' "$TABLE" | awk -F'\t' -v id="$r" '($2=="kept"||$2=="unverdicted"||$2=="breached"||$2=="red") && $10 !~ /^unrecognized test field/ { n=split($9, t, /[ ,]+/); for (k=1;k<=n;k++) if (t[k]==id) { print $1; break } }')
    T=no; [ -n "$MR" ] && T=yes
    for mr in $MR; do case "$FAILROWS" in *" $mr "*) RF="$RF $mr"; T=no ;; esac; done
  fi
  S=OK
  if [ -n "$RF" ] && [ "$C" = yes ]; then
    S="ROW-GAP ($(printf '%s' "$RF" | sed 's/^ //')) — counted once per row, above"
  elif [ "$C" = no ] || [ "$T" = no ]; then
    # deploy-owed: every inventory row derived from this REQ is owed to a /vid deploy rung
    DROWS=$(printf '%s\n' "$IBLOCK" | awk -F'|' -v id="$r" '$1 ~ /^[[:space:]]*ROW-/ { d=$7; gsub(/^[ \t]+|[ \t]+$/,"",d); n=split(d, parts, /[ ,]+/); for (k=1;k<=n;k++) if (parts[k]==id) { print; break } }' || true)
    NALL=$(printf '%s\n' "$DROWS" | grep -c . || true)
    NDEP=$(printf '%s\n' "$DROWS" | awk -F'|' '{ t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t ~ /^owed: paid by \/vid deploy/) c++ } END { print c+0 }')
    if [ "$NALL" -gt 0 ] && [ "$NALL" -eq "$NDEP" ]; then
      S="DEPLOY-OWED ($(printf '%s\n' "$DROWS" | awk -F'|' '{ id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); printf "%s%s", (c++ ? " " : ""), id }'))"
      DEPLOYOWED=$((DEPLOYOWED + 1))
    else
      S=GAP
      GAPS=$((GAPS + 1))
    fi
  fi
  printf '%-10s  %-6s  %-5s  %s\n' "$r" "$C" "$T" "$S"
done
NLATER=$(printf '%s\n' "$LATER" | grep -c . || true)
if [ "$NLATER" -gt 0 ]; then echo "later (deferred, never a gap): $(printf '%s\n' "$LATER" | tr '\n' ' ')"; fi

# Design join — when a ratified design exists, its join unit is the @screen
# MARKER, never the filename (F6: file-level joins lie — 5 whole-file
# citations once satisfied 67 designed screens). Every unresolved marker must
# be cited as ID/state by an implementation. Packs predating the marker
# contract (no @screen anywhere) keep the v0.5 per-file join.
DPACK=''
if [ -d design/screens ]; then DPACK=design/screens; elif [ -d design ]; then DPACK=design; fi
DMARKERS=''
if [ -n "$DPACK" ]; then
  for s in "$DPACK"/*.html; do
    [ -f "$s" ] || continue
    for m in $(grep -oE '<!--[[:space:]]*@screen[[:space:]]+[^>]*-->' "$s" || true); do
      id=$(printf '%s\n' "$m" | sed -E 's/.*@screen[[:space:]]+([A-Za-z0-9_-]+).*/\1/')
      state=default
      case "$m" in *state=*) state=$(printf '%s\n' "$m" | sed -E 's/.*state=([A-Za-z0-9_-]+).*/\1/') ;; esac
      DMARKERS="$DMARKERS$id/$state
"
    done
  done
  DMARKERS=$(printf '%s' "$DMARKERS" | sort -u || true)
fi
if [ -n "$DMARKERS" ]; then
  RESOLVED=''
  if [ -f DESIGN-BRIEF.md ]; then
    RESOLVED=$(sed -n '/^```vid-design-manifest/,/^```$/p' DESIGN-BRIEF.md | sed '1d;$d' \
      | grep -E '\|[[:space:]]*(owed|descoped|fenced|later):' \
      | sed -E 's/^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*\|[[:space:]]*([A-Za-z0-9_-]+).*/\1\/\2/' || true)
  fi
  # v0.26.10.5 (R8): scoped, a marker counts when a scoped ROW binds it (its marker field) or no ROW binds it
  BOUND=''; SBOUND=''
  if [ -n "$ROWSF" ]; then
    BOUND=$(printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); m = $5; gsub(/^[ \t]+|[ \t]+$/, "", m); if (m != "" && m != "n/a") print id " " m }')
    SBOUND=$(printf '%s\n' "$BOUND" | while read -r _i _m; do if [ -n "$_i" ] && inscope "$_i"; then printf '%s\n' "$_m"; fi; done)
  fi
  for tok in $DMARKERS; do
    printf '%s\n' "$RESOLVED" | grep -qxF "$tok" && continue
    if [ -n "$ROWSF" ] && printf '%s\n' "$BOUND" | awk '{ print $2 }' | grep -qxF "$tok" && ! printf '%s\n' "$SBOUND" | grep -qxF "$tok"; then continue; fi
    D=no
    for p in $PREFIXES; do
      case "$p" in tests*|checks*|design*) continue ;; esac
      [ -e "$p" ] || continue
      grep -rqF "$tok" --exclude='*.md' "$p" 2>/dev/null && { D=yes; break; }
    done
    if [ "$D" = no ]; then
      printf '%-10s  %-6s  %-5s  %s\n' "marker" "no" "-" "GAP  $tok drawn but not cited by any implementation"
      GAPS=$((GAPS + 1))
    fi
  done
elif [ -d design/screens ]; then
  for s in design/screens/*; do
    [ -f "$s" ] || continue
    base=${s##*/}
    D=no
    for p in $PREFIXES; do
      case "$p" in tests*|checks*|design*) continue ;; esac
      [ -e "$p" ] || continue
      grep -rq "$base" --exclude='*.md' "$p" 2>/dev/null && { D=yes; break; }
    done
    if [ "$D" = no ]; then
      printf '%-10s  %-6s  %-5s  %s\n' "screen" "no" "-" "GAP  $base designed but not cited by any implementation"
      GAPS=$((GAPS + 1))
    fi
  done
fi

# Reachability leg — the join is REQ → code → test → reachable surface. The
# inventory court supplies the surface half: its route gaps, owed rows,
# orphans, promissory test refs and hostility gaps (§4: an unattempted
# Tier-0 protection, an unproved probe) all count as coverage gaps.
if [ -f INVENTORY.md ] && [ -f checks/inventory.sh ]; then
  INV=$(VID_COURT_EVENT=off sh checks/inventory.sh --report || true)
  ISUM=$(printf '%s\n' "$INV" | grep '^inventory: ' | tail -n 1 || true)
  if [ -n "$ROWSF" ]; then
    # v0.26.10.5 (R8): scoped, the reader's lines are counted one by one — an id outside the scope file is left out
    ISC=$(printf '%s\n' "$INV" | grep -E '^(GAP|OWED|ORPHAN|DEPLOY-OWED) ' | while IFS= read -r _l; do
      _id=$(printf '%s\n' "$_l" | awk '{ print $2 }')
      case "$_id" in (ROW-*|RULE-*|DIF-*|EXC-*|SUP-*|HOS-*|REQ-*|INV-*) inscope "$_id" || continue ;; esac
      printf '%s\n' "$_l"; done)
    printf '%s\n' "$ISC" | grep -v '^$' | sed 's/^/    /' || true
    IGAPS=$(printf '%s\n' "$ISC" | grep -cE '^(GAP|OWED|ORPHAN) ' || true)
    GAPS=$((GAPS + IGAPS))
    echo "    inventory (stages in scope): $IGAPS gaps of the reader's lines${ISUM:+ — the whole: $ISUM}"
    ISUM=''
  else
    printf '%s\n' "$INV" | grep -E '^(GAP|OWED|ORPHAN|DEPLOY-OWED)' | sed 's/^/    /' || true
  fi
  if [ -n "$ISUM" ]; then
    IGAPS=0
    for kv in $(printf '%s\n' "$ISUM" | tr ' ' '\n' | grep -E '^(route-gaps|owed|orphans|missing-tests|hostility-gaps)=' || true); do
      IGAPS=$((IGAPS + ${kv#*=}))
    done
    GAPS=$((GAPS + IGAPS))
    echo "    $ISUM"
  fi
fi

# The archive is invisible to the census (v0.9.1 3.4, R12-iii): PRD-HISTORY-*.md
# and SEED.md keep every carrier verbatim; only live carriers count.
Q=$(grep -rn 'VID-QUESTION:' --exclude-dir=.git --exclude-dir=checks --exclude=CLAUDE.md --exclude='PRD-HISTORY-*.md' --exclude=SEED.md . 2>/dev/null | wc -l | tr -d ' ')
# v0.26.10.5 (R8): scoped, a marker whose ids (an OQ carrier read as the PRD items citing it) all lie outside the
# scope file is left out; a marker naming nothing counts
if [ -n "$ROWSF" ]; then
  EFFP=''; [ -f PRD.md ] && [ -f checks/prd.sh ] && EFFP=$(sh checks/prd.sh --effective PRD.md 2>/dev/null || true)
  Q=$(grep -rh 'VID-QUESTION:' --exclude-dir=.git --exclude-dir=checks --exclude=CLAUDE.md --exclude='PRD-HISTORY-*.md' --exclude=SEED.md . 2>/dev/null | while IFS= read -r _l; do
      _ids=$(printf '%s\n' "$_l" | grep -oE '(REQ|INV|ROW|HOS|RULE|DIF|EXC|SUP)-[0-9]+' || true)
      for _oq in $(printf '%s\n' "$_l" | grep -oE 'OQ-[0-9]+' || true); do
        _ids="$_ids
$(printf '%s\n' "$EFFP" | grep -E "(^|[^A-Za-z0-9-])$_oq([^0-9]|\$)" | awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); print id }')"
      done
      _ids=$(printf '%s\n' "$_ids" | grep -v '^$' || true)
      if [ -z "$_ids" ]; then echo q; continue; fi
      for _i in $_ids; do if inscope "$_i"; then echo q; break; fi; done
    done | grep -c . || true)
fi
N=$(printf '%s\n' "$REQS" | grep -c . || true)
NLM=0; [ -f DESIGN-BRIEF.md ] && NLM=$(sed -n '/^```vid-design-manifest/,/^```$/p' DESIGN-BRIEF.md | grep -cE '\|[[:space:]]*later:' || true)
echo ''
echo "REQs: $N   gaps: $GAPS   open VID-QUESTION markers: $Q   deploy-owed: $DEPLOYOWED   later items: $NLATER   later markers: $NLM"
echo "note: 'cited' = citation present under app-source placement prefixes; the ledger tests are the evidence."

if [ "$STRICT" -eq 1 ]; then
  if [ "$GAPS" -gt 0 ] || [ "$Q" -gt 0 ]; then
    echo 'ViD coverage --strict: not done — close every gap and resolve every open question.' >&2
    exit 1
  fi
fi
exit 0
