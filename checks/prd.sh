#!/bin/sh
# Purpose: ViD court — the enriched PRD grammar (v0.8.1a skill, installed
# at init since v0.8.1b).
# Reads the four machine blocks in a PRD.md (```vid-prd items,
# ```vid-prd-contract, ```vid-prd-answers, ```vid-prd-mechanisms) and runs
# the twelve joins of the vid-create-prd spec §5: grammar, closed enums,
# Fail-if two-way, serves, authority routing, pending-claims-no-covers,
# no-pending-with-live-answer, answer tracing, contract closure/legality
# (facets, type-eligibility, prompt on panel-added rows, the 24 cap),
# non-goals present, the mechanism join, effective-set integrity (base
# rows superseded by later AMENDED rows, latest wins — the same law for
# items and for answer-ledger rows: an amended answer restates its full
# row and the effective ledger is what every ref resolves against), and
# join 13, the findings record (```vid-prd-findings sitting rows: enums,
# unique ids, resolving dispositions on blocking findings, targets that
# exist — the sha covers what the owner was shown, not only what they
# decided). Presence-gated:
# silent exit 0 when the file has no ```vid-prd* block of any kind
# (pre-enrichment PRDs unaffected); fails closed when an items block
# exists but the contract or answer blocks are missing. Before items
# exist (the pause-1 artifact) the court judges what is present —
# contract grammar, the cap, prompts, the mechanism join, answer
# tracing — and holds coverage/status closure until items exist, since
# coverage is meaningless before authoring. Lines beginning `#` inside
# machine blocks are annotations, ignored. Counts, never scores.
# Runs from checks/hooks/pre-commit at every commit (presence-gated, like
# the inventory and census courts); the vid-create-prd skill also invokes
# it by plugin path before every ratification commit, and in standalone
# mode (no hooks) that explicit gate carries the whole enforcement.
# v0.9.3 (4.21): the effective-set reader exposed for checks/brief.sh and
# checks/hooks/post-commit, as two early-exit modes that judge nothing:
# --effective prints the effective item rows (latest per id, AMENDED
# stripped — the EFF computation below), or, for a legacy block-form PRD,
# each REQ's effective `### REQ-NNN` block verbatim (the last heading for
# that id wins); --failifs prints `REQ-NNN<TAB><effective fail-if text>`
# for either grammar. Both exit 0, silent when the file is absent.
# v0.9.4: the header `grammar: 0.9.4` (or later, compared component by
# component — g094) opts a file into joins 16-19 at every commit: 16, the
# features (```vid-prd-features rows FEAT-NN | goal | name, latest per id —
# the effective-set law; every demand item and invariant carries exactly one
# `feature:` naming an effective feature); 17, honest labels (an
# authoritative item cites no model_proposed answer — a ViD decision; a
# source entry `proposal` is retired; a provisional owner-decision item
# cites the ViD decision or SRC- document it rests on); 18, must-never-break
# (a T0 item citing a ViD decision is provisional, routed `/yes` to one open
# carrier per decision, `VID-QUESTION: (OQ-n) A-NNN — …`); 19, values traced
# (every digit run in a settled statement appears in a cited text: the seed,
# a cited answer's A:, the thesis, the sources; door sitting references
# `fix `/`grade `/`design ` are counted in values-unchecked=, not traced).
# --pause adds join 20 (every model_proposed answer carries a current
# `shown: pause-N <sum>`, the sum the cksum of its whitespace-collapsed A:
# text as presented) and the importance floor (a human answer grounding a
# T0 item carries `importance: priority`), both only under g094, and prints
# the pause material on every grammar: size, the must-never-break
# questions, the new ViD decisions ranked, the sensitive and measurement
# lists, near-duplicate pairs, the features. The new labels (feature:,
# importance:, shown:) and the `lens` findings pass are legal on every
# grammar and ignored before 0.9.4. Joins 16-20 run in one awk pass.
# v0.9.5 (3.13, R13): the header `grammar: 0.9.5` (or later, component by
# component — g095) satisfies every 0.9.4 rule and adds join 21, in the same
# awk pass: every effective demand item and invariant carries `plain:`
# exactly once — one sentence (no `.`, `?` or `!` followed by a space and an
# uppercase letter or a digit), at most 30 words, no ids (`REQ-`, `INV-`,
# `NG-`, `A-`, `OQ-`, `FEAT-`, `MECH-`, `ROW-`, `D-` and a number; `DIM-`
# or `SRC-` and a letter; each as a whole token), and every digit value in
# it found in the item's own statement or fail-if (join 19's tokenizer; a
# spelled-out number is not checked). `plain:` is legal on every grammar.
# --pause adds `plain sentences`: every demand item and invariant's
# sentence beside its statement, which the owner approves together.
# Usage: sh checks/prd.sh [PRD.md] [--report] [--pause] · sh checks/prd.sh --effective|--failifs [PRD.md]
set -eu
IFS='
'
PRD=./PRD.md; MODE=default; PAUSE=no
for a in "$@"; do case "$a" in
  --report) MODE=report ;; --effective) MODE=effective ;; --failifs) MODE=failifs ;; --pause) PAUSE=yes ;;
  --*) echo "ViD prd: unknown flag '$a' — the flags are --report, --pause, --effective, --failifs; refusing rather than reading it as a file." >&2; exit 1 ;;
  *) PRD=$a ;; esac; done
[ -f "$PRD" ] || exit 0
if [ "$MODE" = effective ] || [ "$MODE" = failifs ]; then
  if grep -q '^```vid-prd$' "$PRD"; then
    EFFR=$(sed -n '/^```vid-prd$/,/^```$/p' "$PRD" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | awk -F'|' '{
      id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
      rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
      if (!(id in seen)) { order[++n]=id; seen[id]=1 }
    } END { for (i=1;i<=n;i++) print row[order[i]] }' || true)
    if [ "$MODE" = effective ]; then
      [ -z "$EFFR" ] || printf '%s\n' "$EFFR"
    else
      [ -z "$EFFR" ] || printf '%s\n' "$EFFR" | awk -F'|' '{
        id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); if (id !~ /^REQ-[0-9]+$/) next
        for (i=2;i<=NF;i++) { f=$i; gsub(/^[ \t]+|[ \t]+$/,"",f); if (f ~ /^fail-if:/) { sub(/^fail-if:[ \t]*/,"",f); print id "\t" f; break } } }'
    fi
  else
    # legacy block form: `### REQ-NNN [AMENDED] …` headings; a block runs to the next heading
    awk -v mode="$MODE" '
      /^#{1,3} / { cur=""; if ($0 ~ /^### REQ-[0-9]+/) { match($0, /REQ-[0-9]+/); cur=substr($0, RSTART, RLENGTH); if (!(cur in seen)) { order[++n]=cur; seen[cur]=1 }; blk[cur]=""; fi[cur]="" } }
      cur!="" { blk[cur]=blk[cur] $0 "\n"; if (fi[cur]=="" && tolower($0) ~ /fail-if/) { t=$0; sub(/^.*[Ff]ail-if:?[*]*:?[ \t]*/,"",t); sub(/[ \t]+$/,"",t); fi[cur]=t } }
      END { for (i=1;i<=n;i++) { k=order[i]; if (mode=="effective") printf "%s", blk[k]; else if (fi[k]!="") print k "\t" fi[k] } }' "$PRD"
  fi
  exit 0
fi
grep -q '^```vid-prd' "$PRD" || exit 0
HASITEMS=no; grep -q '^```vid-prd$' "$PRD" && HASITEMS=yes
# grammar: the header line `grammar: 0.9.1` (v0.9.1 3.6) opts a file into the
# 0.9.1 strictnesses; without it the file is legacy — a new strictness is
# reported (NOTE), never convicted, and consolidation is the migration.
GRAMMAR=$(awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{sub(/^grammar:[ \t]*/,""); sub(/[ \t]*$/,""); print; exit}' "$PRD")
[ -n "$GRAMMAR" ] || GRAMMAR=legacy
# g094 (v0.9.4 3.1): the header grammar compares >= 0.9.4, component by component.
G094=no
[ "$GRAMMAR" = legacy ] || G094=$(printf '%s\n' "$GRAMMAR" | awk -F. '{ split("0.9.4", w, ".")
  for (i = 1; i <= 3; i++) { a = $i + 0; if (a > w[i] + 0) { print "yes"; exit } if (a < w[i] + 0) { print "no"; exit } }
  print "yes" }')
# g095 (v0.9.5 3.13): the same comparison against 0.9.5.
G095=no
[ "$GRAMMAR" = legacy ] || G095=$(printf '%s\n' "$GRAMMAR" | awk -F. '{ split("0.9.5", w, ".")
  for (i = 1; i <= 3; i++) { a = $i + 0; if (a > w[i] + 0) { print "yes"; exit } if (a < w[i] + 0) { print "no"; exit } }
  print "yes" }')
# g0981 (v0.9.8.1 R38): the same comparison against 0.9.8.1 — join 17's every-cited-answer reading refuses only from it
G0981=no
[ "$GRAMMAR" = legacy ] || G0981=$(printf '%s\n' "$GRAMMAR" | awk -F. '{ split("0.9.8.1", w, ".")
  for (i = 1; i <= 4; i++) { a = $i + 0; if (a > w[i] + 0) { print "yes"; exit } if (a < w[i] + 0) { print "no"; exit } }
  print "yes" }')
# Positional fields (v0.9.1 3.8): legacy rows carry five (ID | type | tier |
# priority | statement); under `grammar: 0.9.1` the priority column is gone
# and rows carry four (ID | type | tier | statement). Labeled fields follow.
if [ "$GRAMMAR" = legacy ]; then NPOS=5; else NPOS=4; fi
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

blk() { sed -n "/^\`\`\`$1\$/,/^\`\`\`\$/p" "$PRD" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
ITEMS_RAW=''; [ "$HASITEMS" = yes ] && ITEMS_RAW=$(blk vid-prd)
CONTRACT=$(blk vid-prd-contract)
ANSWERS=$(blk vid-prd-answers); MECHS=$(blk vid-prd-mechanisms)
if [ "$HASITEMS" = yes ]; then
  [ -n "$CONTRACT" ] || { echo 'ViD prd: items exist but no ```vid-prd-contract block — failing closed.' >&2; exit 1; }
  [ -n "$ANSWERS" ] || { echo 'ViD prd: items exist but no ```vid-prd-answers block — failing closed.' >&2; exit 1; }
fi

field() { printf '%s\n' "$1" | cut -d'|' -f"$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
labeled() { printf '%s\n' "$1" | tr '|' '\n' | sed -n 's/^[[:space:]]*'"$2"':[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//'; }
nfields() { printf '%s\n' "$1" | awk -F'|' '{print NF}'; }
GAPS=0
gap() { echo "GAP  $*"; GAPS=$((GAPS + 1)); }
NOTES=0
note() { echo "NOTE  $*"; NOTES=$((NOTES + 1)); }
# strict: a 0.9.1 strictness — a gap under `grammar: 0.9.1`, a NOTE on a legacy file.
strict() { if [ "$GRAMMAR" = legacy ]; then note "$* — reported, not convicted (pre-0.9.1 grammar)"; else gap "$@"; fi; }

CATALOG='DIM-identity DIM-consent DIM-lifecycle DIM-operations DIM-feedback-intake DIM-trust-states DIM-authorization DIM-notifications DIM-data-integrity DIM-nfr-security DIM-nfr-privacy DIM-nfr-availability DIM-nfr-accessibility DIM-nfr-operability DIM-proof-thresholds DIM-instrumentation DIM-core-loop-continuity DIM-seo-technical DIM-i18n-locale'
DEMANDT='functional nfr ux_flow data_entity'
# OQ carriers: open (`VID-QUESTION: (OQ-n) …`, counted by coverage.sh) or
# resolved (`RESOLVED: (OQ-n) A-NNN — …`, the one line class the base may
# rewrite). References resolve against both; only open carriers count, and
# a pending item may not point at a resolved one.
oq_open() { grep -q "VID-QUESTION: ($1)" "$PRD"; }
oq_exists() { grep -Eq "^(VID-QUESTION|RESOLVED): \($1\)" "$PRD"; }

# --- join 12a: base ids unique, an AMENDED row's id exists earlier ---------
SEEN=''
for r in $ITEMS_RAW; do
  id=$(field "$r" 1)
  case "$id" in
    *AMENDED) bid=$(printf '%s' "$id" | sed 's/[[:space:]]*AMENDED$//')
      printf '%s\n' "$SEEN" | grep -qxF "$bid" || gap "join 12: '$id' has no earlier row with id $bid — an amendment needs an ancestor."
      id=$bid ;;
    *) printf '%s\n' "$SEEN" | grep -qxF "$id" && gap "join 12: duplicate id $id in the base — ids are stable and never reused." ;;
  esac
  SEEN="$SEEN
$id"
done
# effective set: latest row per id wins; AMENDED marker stripped from field 1.
EFF=''
[ -n "$ITEMS_RAW" ] && EFF=$(printf '%s\n' "$ITEMS_RAW" | awk -F'|' '{
  id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
  rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
  if (!(id in seen)) { order[++n]=id; seen[id]=1 }
} END { for (i=1;i<=n;i++) print row[order[i]] }')

# --- join 12c: the answer ledger under the same effective-set law ----------
ASEEN=''
for r in $ANSWERS; do
  aid=$(field "$r" 1)
  case "$aid" in
    *AMENDED) bid=$(printf '%s' "$aid" | sed 's/[[:space:]]*AMENDED$//')
      printf '%s\n' "$ASEEN" | grep -qxF "$bid" || gap "join 12 ($aid): no earlier ledger row with id $bid — an amended answer needs an ancestor."
      aid=$bid ;;
    *) printf '%s\n' "$ASEEN" | grep -qxF "$aid" && gap "join 12: duplicate answer id $aid in the ledger — restate a changed ruling as $aid AMENDED, latest wins." ;;
  esac
  ASEEN="$ASEEN
$aid"
done
AEFF=''
[ -n "$ANSWERS" ] && AEFF=$(printf '%s\n' "$ANSWERS" | awk -F'|' '{
  id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
  rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
  if (!(id in seen)) { order[++n]=id; seen[id]=1 }
} END { for (i=1;i<=n;i++) print row[order[i]] }')

# --- items: joins 1-6, 10, collection for 7-9 and 12b ----------------------
IDS=''; PENDING=''; PENDOQ=''; COVERS=''; SPANS=''; NG=0; NDEMAND=0; NFRAME=0; NP0=0; NPILOT=0; NLATER=0
NAUTH=0; NPROV=0; NPEND=0; NBLOCK=0; NODPROV=0; STMTS=''
ANSIDS=$(for r in $AEFF; do field "$r" 1; done)
for r in $EFF; do
  id=$(field "$r" 1); nf=$(nfields "$r")
  if [ "$nf" -lt "$NPOS" ]; then gap "join 1 ($id): row under-parses ($nf fields; $NPOS positional fields required)."; continue; fi
  i=$((NPOS + 1)); while [ "$i" -le "$nf" ]; do
    f=$(field "$r" "$i")
    case "$f" in fail-if:*|serves:*|authority:*|confirms_via:*|source:*|covers:*|derives:*|spans:*|cross-cutting:*|phase:*|arms:*|feature:*|plain:*) ;;
      *) gap "join 1 ($id): unlabeled field '$f' — a stray | inside a field, or an unknown label." ;; esac
    i=$((i + 1))
  done
  type=$(field "$r" 2); tier=$(field "$r" 3)
  if [ "$NPOS" -eq 5 ]; then pri=$(field "$r" 4); stmt=$(field "$r" 5); else
    pri='-'; stmt=$(field "$r" 4)
    case "$stmt" in P0|P1|P2|-) gap "join 1 ($id): the priority column ('$stmt') is gone under grammar $GRAMMAR — four positional fields (ID | type | tier | statement); a five-field row is a legacy row." ;; esac
  fi
  case "$type" in functional|nfr|ux_flow|data_entity|invariant|non_goal|risk|hypothesis|outcome|metric|constraint) ;;
    *) gap "join 2 ($id): unknown type '$type' — the type list is closed."; continue ;; esac
  case "$tier" in T0|T1|T2|-) ;; *) gap "join 2 ($id): unknown tier '$tier'." ;; esac
  if [ "$NPOS" -eq 5 ]; then case "$pri" in P0|P1|P2|-) ;; *) gap "join 2 ($id): unknown priority '$pri'." ;; esac; fi
  demand=no; case " $DEMANDT " in *" $type "*) demand=yes ;; esac
  [ "$demand" = yes ] && NDEMAND=$((NDEMAND + 1)) || NFRAME=$((NFRAME + 1))
  [ "$demand" = yes ] && [ "$pri" = P0 ] && NP0=$((NP0 + 1))
  # join 15 (v0.9.1 3.6): phase is membership, not ranking — pilot | later,
  # default pilot; under grammar: 0.9.1 every demand item and invariant carries it.
  ph=$(labeled "$r" phase)
  case "$ph" in ''|pilot|later) ;; *) gap "join 15 ($id): unknown phase '$ph' — pilot | later." ;; esac
  if [ -z "$ph" ] && [ "$GRAMMAR" != legacy ]; then
    case "$type" in functional|nfr|ux_flow|data_entity|invariant) gap "join 15 ($id): no phase: under grammar $GRAMMAR — every demand item and invariant carries pilot | later (membership, not ranking)." ;; esac
  fi
  case "${ph:-pilot}" in pilot) NPILOT=$((NPILOT + 1)) ;; later) NLATER=$((NLATER + 1)) ;; esac
  [ "$type" = non_goal ] && NG=$((NG + 1))
  case "$type" in functional|nfr|ux_flow|data_entity|invariant) [ "$tier" = - ] && gap "join 2 ($id): demand items and invariants always carry a tier." ;; esac
  fi_=$(labeled "$r" fail-if); sv=$(labeled "$r" serves)
  au=$(labeled "$r" authority); cv=$(labeled "$r" confirms_via)
  src=$(labeled "$r" source); cov=$(labeled "$r" covers); dv=$(labeled "$r" derives)
  if [ "$demand" = yes ]; then
    [ -n "$fi_" ] || gap "join 3 ($id): a demand row with no fail-if: — every demand item names its falsifier."
    [ -n "$sv" ] || gap "join 4 ($id): a demand row with no serves: — purpose is what resolves the unanticipated tradeoff."
  else
    [ -n "$fi_" ] && gap "join 3 ($id): a frame row carrying fail-if: — frame types are boundary and frame, not behaviour a test exercises."
  fi
  case "$au" in
    authoritative) NAUTH=$((NAUTH + 1))
      # before 0.9.4 as today; under g094 join 17 owns `proposal` as an exact entry (3.4).
      [ "$G094" = yes ] || case ",$src," in *proposal*) gap "join 5 ($id): source: proposal is never authoritative." ;; esac ;;
    provisional|pending)
      [ "$au" = provisional ] && NPROV=$((NPROV + 1)) || NPEND=$((NPEND + 1))
      if [ -z "$cv" ]; then gap "join 5 ($id): $au with no confirms_via: — provisionality is routed, never narrated."
      else
        kind=$(printf '%s' "$cv" | sed 's|[/ ].*||'); blocks=${cv##*/}
        case "$kind" in owner-decision|measurement|external-dependency) ;; *) gap "join 2 ($id): unknown confirms_via kind '$kind'." ;; esac
        case "$blocks" in yes|no) ;; *) gap "join 2 ($id): confirms_via blocks must be yes|no, got '$blocks'." ;; esac
        [ "$blocks" = yes ] && NBLOCK=$((NBLOCK + 1))
        [ "$au" = provisional ] && [ "$kind" = owner-decision ] && NODPROV=$((NODPROV + 1))
        if [ "$au" = pending ]; then
          oq=$(printf '%s' "$cv" | grep -o 'OQ-[0-9]*' | head -n 1 || true)
          if [ -n "$oq" ] && [ "$kind" = owner-decision ] && ! oq_open "$oq" && oq_exists "$oq"; then
            gap "join 5 ($id): pending on $oq, but that carrier is resolved — amend the item on the answer that resolved it."
          elif [ "$kind" != owner-decision ] || [ -z "$oq" ] || ! oq_open "$oq"; then
            gap "join 5 ($id): a pending row's confirms_via must be owner-decision naming a live OQ carrier."
          else PENDOQ="$PENDOQ
$oq"; fi
          PENDING="$PENDING
$id"
        fi
      fi ;;
    '') gap "join 2 ($id): no authority: field." ;;
    *) gap "join 2 ($id): unknown authority '$au'." ;;
  esac
  case "$dv" in ''|golden-set|trigger-row) ;; *) gap "join 2 ($id): unknown derives '$dv'." ;; esac
  if printf '%s\n' "$r" | tr '|' '\n' | grep -q '^[[:space:]]*cross-cutting:'; then
    [ -n "$(labeled "$r" cross-cutting)" ] || gap "join 2 ($id): cross-cutting: names no surface — a marker nothing reads is decoration."
  fi
  if [ -n "$cov" ]; then
    if [ "$au" = pending ]; then gap "join 6 ($id): a pending item claims covers — an item awaiting a decision cannot also be decided."
    else for c in $(printf '%s\n' "$cov" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'); do
      COVERS="$COVERS
$id $type $c"; done; fi
  fi
  for s in $(printf '%s\n' "$src" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep '^A-[0-9]*$' || true); do
    printf '%s\n' "$ANSIDS" | grep -qxF "$s" || gap "join 8 ($id): source cites $s but no such ledger row exists."
  done
  sp=$(labeled "$r" spans)
  for s in $(printf '%s\n' "$sp" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true); do
    SPANS="$SPANS
$id $s"; done
  IDS="$IDS
$id"; STMTS="$STMTS
$stmt"
done
[ "$HASITEMS" = no ] || [ "$NG" -ge 1 ] || gap "join 10: zero non_goal rows — a generator cannot infer a boundary from silence."
DUPS=$(printf '%s\n' "$STMTS" | grep -v '^$' | sort | uniq -d || true)
for d in $DUPS; do gap "join 12: duplicate statement in the effective set — never two items of the same content, whatever their ids: '$d'"; done
# spans: an interaction falsifier names the items whose seam it guards.
for s in $(printf '%s\n' "$SPANS" | grep -v '^$' || true); do
  sid=${s%% *}; ref=${s#* }
  printf '%s\n' "$IDS" | grep -qxF "$ref" || gap "join 12 ($sid): spans cites $ref, which is no item in the effective set — an interaction falsifier must name the items it guards."
done

# --- join 14: arms (v0.9.1 3.5b) -------------------------------------------
# An arm is one clause of a fail-if split at top-level " or " / ", or " /
# "; or ". Every AMENDED row whose predecessor carries a fail-if accounts
# for each predecessor arm by ordinal — retained · strengthened · moved <id>
# · withdrawn <A-NNN>; a moved arm is checked against the target's revision
# BEFORE the moving row (append order is time order), a withdrawn arm
# against an effective answer settling the item. Required under grammar:
# 0.9.1; on a legacy file an unaccounted amendment is reported, never
# convicted: arm-losing (fewer arms than its predecessor) or arm-changed
# (the same count, an arm's text no longer found) — counts, never scores.
arms_of() { printf '%s\n' "$1" | awk '
  function norm(s) { gsub(/[ \t]+/, " ", s); gsub(/^ | $/, "", s); return s }
  { s = $0; depth = 0; cur = ""; i = 1; L = length(s)
    while (i <= L) { c = substr(s, i, 1)
      if (c == "(") depth++; else if (c == ")" && depth > 0) depth--
      if (depth == 0) {
        if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { print norm(cur); cur = ""; i += 5; continue }
        if (substr(s, i, 4) == " or ") { print norm(cur); cur = ""; i += 4; continue } }
      cur = cur c; i++ }
    print norm(cur) }'; }
normws() { printf '%s\n' "$1" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//'; }
ARMLOSING=0; ARMCHANGED=0; RN=0
for r in $ITEMS_RAW; do
  RN=$((RN + 1))
  id=$(field "$r" 1)
  case "$id" in *AMENDED) ;; *) continue ;; esac
  bid=$(printf '%s' "$id" | sed 's/[[:space:]]*AMENDED$//')
  pred=$(printf '%s\n' "$ITEMS_RAW" | head -n $((RN - 1)) | grep -E "^[[:space:]]*$bid([[:space:]]+AMENDED)?[[:space:]]*\|" | tail -n 1 || true)
  [ -n "$pred" ] || continue                                   # join 12 names the missing ancestor
  pfi=$(labeled "$pred" fail-if); [ -n "$pfi" ] || continue    # a frame row has no arms
  PARMS=$(arms_of "$pfi"); NP=$(printf '%s\n' "$PARMS" | grep -c . || true)
  cfi=$(labeled "$r" fail-if); CARMS=$(arms_of "$cfi"); NC=$(printf '%s\n' "$CARMS" | grep -c . || true)
  ac=$(labeled "$r" arms)
  if [ -z "$ac" ]; then
    if [ "$GRAMMAR" != legacy ]; then
      gap "join 14 ($id): no arms: — an amendment accounts for every arm of the row it supersedes ($NP arm(s); retained · strengthened · moved <id> · withdrawn <A-NNN>)."
    else
      changed=0; cn=$(normws "$cfi")
      for a in $PARMS; do case "$cn" in *"$a"*) ;; *) changed=1 ;; esac; done
      if [ "$NC" -lt "$NP" ]; then note "join 14 ($id): arm-losing — $NP arm(s) before, $NC after, no arms: accounting (pre-0.9.1 grammar, reported)"; ARMLOSING=$((ARMLOSING + 1))
      elif [ "$changed" -eq 1 ]; then note "join 14 ($id): arm-changed — $NP arm(s) before and after, an arm's text no longer found, no arms: accounting (pre-0.9.1 grammar, reported)"; ARMCHANGED=$((ARMCHANGED + 1)); fi
    fi
    continue
  fi
  NE=$(printf '%s\n' "$ac" | tr ',' '\n' | grep -c . || true)
  [ "$NE" -eq "$NP" ] || strict "join 14 ($id): arms: carries $NE entr(y/ies) for a predecessor with $NP arm(s) — one entry per arm, by ordinal."
  k=0
  for e in $(printf '%s\n' "$ac" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'); do
    k=$((k + 1))
    ord=$(printf '%s\n' "$e" | awk '{print $1}'); disp=$(printf '%s\n' "$e" | awk '{print $2}'); ref=$(printf '%s\n' "$e" | awk '{print $3}')
    case "$ord" in ''|*[!0-9]*) strict "join 14 ($id): arms: entry '$e' has no ordinal."; continue ;; esac
    if [ "$ord" -lt 1 ] || [ "$ord" -gt "$NP" ] || [ "$ord" -ne "$k" ]; then strict "join 14 ($id): arms: entry '$e' is out of order — ordinals run 1..$NP in the predecessor's order."; continue; fi
    arm=$(printf '%s\n' "$PARMS" | sed -n "${ord}p")
    case "$disp" in
      retained|strengthened) ;;
      moved)
        tgt=$(printf '%s\n' "$ITEMS_RAW" | head -n $((RN - 1)) | grep -E "^[[:space:]]*$ref([[:space:]]+AMENDED)?[[:space:]]*\|" | tail -n 1 || true)
        if [ -z "$tgt" ]; then strict "join 14 ($id): arm $ord moved to $ref, which has no row before this one — the receiving revision precedes the move."
        else tn=$(normws "$(labeled "$tgt" fail-if)"); case "$tn" in *"$arm"*) ;; *) strict "join 14 ($id): arm $ord moved to $ref, but $ref's revision before this row does not carry it (\"$arm\")." ;; esac; fi ;;
      withdrawn)
        arow=$(printf '%s\n' "$AEFF" | grep -E "^[[:space:]]*$ref[[:space:]]*\|" | head -n 1 || true)
        if [ -z "$arow" ]; then strict "join 14 ($id): arm $ord withdrawn under $ref, which is no effective answer."
        else printf '%s\n' "$(labeled "$arow" settles)" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -qx "$bid" || strict "join 14 ($id): arm $ord withdrawn under $ref, whose settles: does not name $bid."; fi ;;
      *) strict "join 14 ($id): arms: disposition '$disp' is not retained · strengthened · moved <id> · withdrawn <A-NNN>." ;;
    esac
  done
done

# --- contract: join 9 ------------------------------------------------------
NDIMS=0; DIMIDS=''; NCOV=0; NNA=0; NMECHD=0; NNFRD=0; NPROOFD=0; NFACETS=0
for r in $CONTRACT; do
  dim=$(field "$r" 1); nf=$(nfields "$r")
  if [ "$nf" -lt 4 ]; then gap "join 1 ($dim): contract row under-parses ($nf fields; 4 positional fields required)."; continue; fi
  NDIMS=$((NDIMS + 1)); DIMIDS="$DIMIDS
$dim"
  cat_=$(field "$r" 3); dem=$(field "$r" 4)
  case "$cat_" in mechanism) NMECHD=$((NMECHD + 1)) ;; nfr) NNFRD=$((NNFRD + 1)) ;; proof) NPROOFD=$((NPROOFD + 1)) ;;
    *) gap "join 9 ($dim): unknown category '$cat_'." ;; esac
  case "$dem" in required|case-by-case) ;; *) gap "join 9 ($dim): unknown demand '$dem'." ;; esac
  case " $CATALOG " in *" $dim "*) ;; *) [ -n "$(labeled "$r" prompt)" ] || gap "join 9 ($dim): a panel-added dimension with no prompt: — a dimension that cannot name its defect class does not enter." ;; esac
  facets=$(labeled "$r" facets | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true)
  [ -n "$facets" ] && NFACETS=$((NFACETS + $(printf '%s\n' "$facets" | grep -c .)))
  [ "$HASITEMS" = yes ] || continue   # coverage/status closure waits for items (pause-1 artifact).
  st=$(labeled "$r" status)
  case "$st" in
    'na owner'*) NNA=$((NNA + 1)) ;;
    na*) gap "join 9 ($dim): status '$st' — an NA is legal only with an owner attribution; you propose, you never disposition." ;;
    covered)
      NCOV=$((NCOV + 1))
      if [ -n "$facets" ]; then
        for f in $facets; do
          printf '%s\n' "$COVERS" | grep -q " $dim/$f\$" || gap "join 9 ($dim): facet '$f' is cited by no item and the dimension carries no owner NA — one citation must not collapse a compound dimension's facets."
        done
      else
        printf '%s\n' "$COVERS" | grep -q " $dim\$" || gap "join 9 ($dim): written status 'covered' but no item cites it and it carries no owner NA."
      fi ;;
    '') gap "join 9 ($dim): no status field." ;;
    *) gap "join 9 ($dim): unknown status '$st'." ;;
  esac
done
[ "$NDIMS" -le 24 ] || gap "join 9: $NDIMS dimensions — the contract is capped at 24; a contract that grows past recognition speed stops being ratifiable at recognition speed."
# item-side covers legality: ghost dims, ghost facets, type-eligibility (CR-009).
for c in $(printf '%s\n' "$COVERS" | grep -v '^$' || true); do
  cid=${c%% *}; rest=${c#* }; ctype=${rest%% *}; ref=${rest#* }
  dim=${ref%%/*}; facet=''; case "$ref" in */*) facet=${ref#*/} ;; esac
  if ! printf '%s\n' "$DIMIDS" | grep -qxF "$dim"; then gap "join 9 ($cid): covers cites $dim, which is not in the ratified contract — a ghost dimension."; continue; fi
  drow=$(printf '%s\n' "$CONTRACT" | grep "^[[:space:]]*$dim[[:space:]]*|" | head -n 1)
  dfacets=$(labeled "$drow" facets | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true)
  if [ -n "$facet" ]; then
    printf '%s\n' "$dfacets" | grep -qxF "$facet" || gap "join 9 ($cid): covers cites $dim/$facet but '$facet' is not a declared facet — a ghost facet."
  elif [ -n "$dfacets" ]; then gap "join 9 ($cid): $dim declares facets — citations must be facet-qualified."; fi
  elig=$(labeled "$drow" covered_by | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
  printf '%s\n' "$elig" | grep -qxF "$ctype" || gap "join 9 ($cid): type '$ctype' is not in $dim's covered_by list — an ineligible citation is a named GAP, never a silent drop."
done

# --- mechanisms: join 11 ---------------------------------------------------
# The seed: the `## Seed` section, or — after consolidation (v0.9.1 3.4) — the
# header line `Seed: SEED.md (sha256 <hash>)` pointing at the verbatim file.
SEEDPTR=$(awk '/^## /{exit} /^Seed:[ \t]+[^ \t]+[ \t]+\(sha256 [0-9a-f]+\)/{print; exit}' "$PRD")
if [ -n "$SEEDPTR" ]; then
  SEEDFILE=$(printf '%s\n' "$SEEDPTR" | sed -E 's/^Seed:[ \t]+([^ \t]+).*/\1/')
  SEEDHASH=$(printf '%s\n' "$SEEDPTR" | sed -E 's/.*\(sha256 ([0-9a-f]+)\).*/\1/')
  SEEDPATH="$(dirname "$PRD")/$SEEDFILE"
  if [ -f "$SEEDPATH" ]; then
    got=$(sha256 "$SEEDPATH")
    [ "$got" = "$SEEDHASH" ] || gap "join 11: $SEEDFILE's sha256 ($got) differs from the Seed: line ($SEEDHASH) — the seed is never edited after consolidation."
    SEEDFLAT=$(tr '\n' ' ' < "$SEEDPATH" | tr -s ' ')
  else
    gap "join 11: the Seed: line points at $SEEDFILE, which does not exist beside the PRD — the seed is the highest authority and must be present."
    SEEDFLAT=''
  fi
else
  SEEDFLAT=$(sed -n '/^## Seed$/,/^## /p' "$PRD" | tr '\n' ' ' | tr -s ' ')
fi
MECHGOALS=$(for r in $MECHS; do field "$r" 2; done)
for g in $(sed -n '/^### MVP focus$/,/^###/p' "$PRD" | grep -oE '^- *G[0-9]+' | grep -oE 'G[0-9]+' || true); do
  printf '%s\n' "$MECHGOALS" | grep -qxF "$g" || gap "join 11: goal $g has no mechanisms row — a goal with no mechanism and no open question is a wish and will be refused."
done
for r in $MECHS; do
  mid=$(field "$r" 1); gr=$(field "$r" 4)
  case "$gr" in
    'stated: seed "'*'"')
      ex=$(printf '%s' "$gr" | sed 's/^stated: seed "//;s/"$//' | tr -s ' ')
      case "$SEEDFLAT" in *"$ex"*) ;; *) gap "join 11 ($mid): seed excerpt \"$ex\" does not appear verbatim in the Seed section — the join is checked mechanically." ;; esac ;;
    'stated: answer A-'*)
      aref=$(printf '%s' "$gr" | grep -o 'A-[0-9]*')
      printf '%s\n' "$ANSIDS" | grep -qxF "$aref" || gap "join 11 ($mid): stated: answer $aref but no such ledger row exists." ;;
    'open: OQ-'*)
      oref=$(printf '%s' "$gr" | grep -o 'OQ-[0-9]*')
      oq_exists "$oref" || gap "join 11 ($mid): open: $oref but no such carrier exists under Open decisions." ;;
    *) gap "join 2 ($mid): unknown grounding '$gr' — stated: seed \"…\" | stated: answer A-NNN | open: OQ-n." ;;
  esac
done

# --- answers: joins 7 and 8 ------------------------------------------------
NHUM=0; NMOD=0
MECHIDS=$(for r in $MECHS; do field "$r" 1; done)
for r in $AEFF; do
  aid=$(field "$r" 1); at=$(field "$r" 2)
  case "$at" in human) NHUM=$((NHUM + 1)) ;; model_proposed) NMOD=$((NMOD + 1)) ;;
    *) gap "join 2 ($aid): unknown answer tier '$at'." ;; esac
  nf=$(nfields "$r"); i=4
  while [ "$i" -le "$nf" ]; do
    f=$(field "$r" "$i")
    case "$f" in Q:*|A:*|settles:*|unchanged:*|importance:*|shown:*) ;;
      *) strict "join 1 ($aid): unlabeled field '$f' on an answer row — a stray | inside a field, or an unknown label (Q:, A:, settles:, unchanged:, importance:, shown:)." ;; esac
    i=$((i + 1))
  done
  st=$(labeled "$r" settles)
  [ -n "$st" ] || { gap "join 8 ($aid): a live answer that traces to nothing — settles: is empty."; continue; }
  for ref in $(printf '%s\n' "$st" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'); do
    if printf '%s\n' "$PENDING" | grep -qxF "$ref" || { printf '%s\n' "$PENDOQ" | grep -qxF "$ref"; }; then
      gap "join 7 ($aid): settles $ref while it is still pending — the record can never hold a pending item whose answer already exists."
    elif [ "$ref" = thesis ] || [ "$ref" = contract ] || printf '%s\n' "$IDS" | grep -qxF "$ref" || printf '%s\n' "$MECHIDS" | grep -qxF "$ref" \
      || printf '%s\n' "$DIMIDS" | grep -qxF "$ref" || { case "$ref" in OQ-*) oq_exists "$ref" ;; *) false ;; esac; }; then :
    else gap "join 8 ($aid): settles '$ref' resolves to no item, mechanism, dimension, OQ carrier, the thesis, or the contract."; fi
  done
  # unchanged: (v0.9.1 3.2, R14-i) — bare item ids the ruling examined and left
  # standing; the delta review's propagation ledger. Every id must exist.
  un=$(labeled "$r" unchanged)
  for ref in $(printf '%s\n' "$un" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'); do
    printf '%s\n' "$IDS" | grep -qxF "$ref" || gap "join 8 ($aid): unchanged: names '$ref', which is no item in the effective set — a ruling leaves standing only what exists."
  done
done

# --- findings: join 13 — the sitting record, dispositions resolving --------
# The ratification sha covers what the owner was shown, not only what they
# decided. Presence-gated: a run whose sittings were clean carries no block.
FINDINGS=$(blk vid-prd-findings)
NFIND=0; FSEEN=''
for r in $FINDINGS; do
  fid=$(field "$r" 1); nf=$(nfields "$r")
  NFIND=$((NFIND + 1))
  if [ "$nf" -lt 5 ]; then gap "join 13 ($fid): findings row under-parses ($nf fields; 5 positional fields required)."; continue; fi
  i=6; while [ "$i" -le "$nf" ]; do
    f=$(field "$r" "$i")
    case "$f" in evidence:*) ;; *) gap "join 13 ($fid): unlabeled field '$f' — a stray | inside a field, or an unknown label." ;; esac
    i=$((i + 1))
  done
  printf '%s\n' "$FSEEN" | grep -qxF "$fid" && gap "join 13: duplicate finding id $fid."
  FSEEN="$FSEEN
$fid"
  pass=$(field "$r" 2); sev=$(field "$r" 3); tgt=$(field "$r" 4); disp=$(field "$r" 5)
  case "$pass" in red-team|audit|review|lens) ;; *) gap "join 13 ($fid): unknown pass '$pass' — red-team | audit | review | lens." ;; esac
  case "$sev" in blocking|advisory) ;; *) gap "join 13 ($fid): unknown severity '$sev'." ;; esac
  case "$disp" in
    repaired) ;;
    'overruled A-'*|'accepted A-'*)
      aref=$(printf '%s' "$disp" | grep -o 'A-[0-9]*' | head -n 1)
      printf '%s\n' "$ANSIDS" | grep -qxF "$aref" || gap "join 13 ($fid): disposition cites $aref but no such ledger row exists." ;;
    'routed OQ-'*)
      oref=$(printf '%s' "$disp" | grep -o 'OQ-[0-9]*' | head -n 1)
      oq_exists "$oref" || gap "join 13 ($fid): routed to $oref but no such carrier exists under Open decisions." ;;
    noted)
      [ "$sev" = blocking ] && gap "join 13 ($fid): a blocking finding merely noted — a lock that can be taken while the red team still objects is a signature on an unread document." ;;
    '') gap "join 13 ($fid): no disposition — a blocking finding must carry a resolving disposition before its pause commits." ;;
    *) gap "join 13 ($fid): unknown disposition '$disp' — repaired | overruled A-NNN | accepted A-NNN | routed OQ-n | noted." ;;
  esac
  for t in $(printf '%s\n' "$tgt" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'); do
    if [ "$t" = thesis ] || [ "$t" = seed ] || printf '%s\n' "$IDS" | grep -qxF "$t" \
      || printf '%s\n' "$MECHIDS" | grep -qxF "$t" || printf '%s\n' "$DIMIDS" | grep -qxF "$t"; then :
    else gap "join 13 ($fid): target '$t' resolves to no item, mechanism, dimension, the thesis, or the seed — a finding with no target cannot be repaired or verified."; fi
  done
done

# --- resolved carriers: the answer a RESOLVED line cites must exist --------
for l in $(grep -E '^RESOLVED: \(OQ-[0-9]+\)' "$PRD" || true); do
  oref=$(printf '%s' "$l" | grep -o 'OQ-[0-9]*' | head -n 1)
  aref=$(printf '%s' "$l" | grep -o 'A-[0-9]*' | head -n 1 || true)
  if [ -z "$aref" ] || ! printf '%s\n' "$ANSIDS" | grep -qxF "$aref"; then
    gap "join 8 ($oref): RESOLVED names no ledger answer that exists — a carrier is resolved by an answer, never by deletion."
  fi
done

# --- v0.9.4: joins 16-20, the importance floor, the report fields and the ---
# pause material — one awk pass over EFF, AEFF, the features rows, the
# carriers and the cited texts (3.1: never a per-row shell loop). Joins 16-19
# convict under g094; join 20, the floor and the door-reference rule under
# g094 and --pause; the counts and (with --pause) the material on every grammar.
TAB=$(printf '\t'); SECT=$(printf '\302\247')
FEATRAW=$(blk vid-prd-features)
GOALS=$(sed -n '/^### MVP focus$/,/^###/p' "$PRD" | grep -oE '^- *G[0-9]+' | grep -oE 'G[0-9]+' || true)
OPENL=$(grep 'VID-QUESTION: (OQ-[0-9][0-9]*)' "$PRD" || true)
RESL=$(grep -E '^RESOLVED: \(OQ-[0-9]+\)' "$PRD" || true)
THESIS=$(sed -n '/^## Thesis$/,/^## /p' "$PRD")
SOURCES=$(sed -n '/^## Sources$/,/^## /p' "$PRD")
# shown: sums (3.5) — the cksum of a model_proposed answer's A: text, whitespace
# collapsed, as `printf '%s\n' <text> | cksum` prints its first field; once per
# model_proposed row, and only when --pause needs them.
SUMS=''
if [ "$PAUSE" = yes ] && [ -n "$AEFF" ]; then
  ATXT=$(printf '%s\n' "$AEFF" | awk -F'|' '{
    id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); t = $2; gsub(/^[ \t]+|[ \t]+$/, "", t); if (t != "model_proposed") next
    for (i = 4; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (f ~ /^A:/) { sub(/^A:[ \t]*/, "", f); gsub(/[ \t\r]+/, " ", f); sub(/ $/, "", f); print id "\t" f; next } }
    print id "\t" }')
  for l in $ATXT; do
    s=$(printf '%s\n' "${l#*"$TAB"}" | cksum)
    SUMS="$SUMS
${l%%"$TAB"*}$TAB${s%% *}"
  done
fi
J094='function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function gap(m) { print "GAP  " m; ngap++ }
function note(m) { print "NOTE  " m; nnote++ }
function num(id,    s) { s = id; sub(/^[A-Z]+-/, "", s); return s + 0 }
function add(l, x) { return l (l == "" ? "" : ", ") x }
# vals (3.4): the value tokens of s, in order of first appearance — `§`
# sequences removed byte-level, maximal runs [0-9][0-9,.]*[0-9] or a single
# digit, thousands commas removed; a run after a letter, or after a `-` that
# follows a letter, is an id or a label (REQ-120, A-038, G4, T0), not a value.
function vals(s, out,    off, t, p, v, b, b2, n, seen) {
  split("", out); split("", seen); n = 0
  gsub(sect "[0-9.]*", "", s)
  off = 0
  while (match(t = substr(s, off + 1), /[0-9]([0-9,.]*[0-9])?/)) {
    p = off + RSTART; v = substr(t, RSTART, RLENGTH); off = p + RLENGTH - 1
    b = (p > 1) ? substr(s, p - 1, 1) : ""; b2 = (p > 2) ? substr(s, p - 2, 1) : ""
    if (b ~ /[A-Za-z]/ || (b == "-" && b2 ~ /[A-Za-z]/)) continue
    gsub(/,/, "", v)
    if (!(v in seen)) { seen[v] = 1; out[++n] = v }
  }
  return n
}
function valset(s, set,    k, n, tmp) { n = vals(s, tmp); for (k = 1; k <= n; k++) set[tmp[k]] = 1 }
# ntoks (3.5, near-duplicates): lowercase [a-z0-9]+ of length >= 3, minus the stopwords.
function ntoks(s, id, pre,    t, n) {
  s = tolower(s); n = 0
  while (match(s, /[a-z0-9]+/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (length(t) < 3 || (t in STOP) || ((pre, id, t) in TK)) continue
    TK[pre, id, t] = 1; TW[pre, id, ++n] = t
  }
  TN[pre, id] = n
}
function shared(pre, a, b,    sm, bg, n, k, i) {
  if (TN[pre, a] <= TN[pre, b]) { sm = a; bg = b } else { sm = b; bg = a }
  n = TN[pre, sm]; k = 0
  for (i = 1; i <= n; i++) if ((pre, bg, TW[pre, sm, i]) in TK) k++
  return k
}
function before(x, y) {   # the ranked list: T0, then T1, then total grounded, then id
  if (GT0[x] + 0 != GT0[y] + 0) return GT0[x] + 0 > GT0[y] + 0
  if (GT1[x] + 0 != GT1[y] + 0) return GT1[x] + 0 > GT1[y] + 0
  if (GTOT[x] + 0 != GTOT[y] + 0) return GTOT[x] + 0 > GTOT[y] + 0
  return num(x) < num(y)
}
function item(r,    n, f, i, id, k, lab) {
  n = split(r, f, "|"); for (i = 1; i <= n; i++) f[i] = trim(f[i])
  id = f[1]; if (id == "" || (id in IT)) return
  IID[++NI] = id; IT[id] = f[2]; ITIER[id] = f[3]; ISTMT[id] = (n >= npos) ? f[npos] : ""; INF[id] = 0; IPN[id] = 0
  for (i = npos + 1; i <= n; i++) {
    k = index(f[i], ":"); if (k == 0) continue
    lab = substr(f[i], 1, k - 1)
    if (lab == "feature") { if (++INF[id] == 1) IFEAT[id] = trim(substr(f[i], k + 1)); continue }
    if (lab == "plain") { if (++IPN[id] == 1) IPLAIN[id] = trim(substr(f[i], k + 1)); continue }
    if (!((id, lab) in IL)) IL[id, lab] = trim(substr(f[i], k + 1))
  }
}
function answer(r,    n, f, i, id, k, lab) {
  n = split(r, f, "|"); for (i = 1; i <= n; i++) f[i] = trim(f[i])
  id = f[1]; if (id == "" || (id in AT)) return
  AID[++NA] = id; AT[id] = f[2]
  for (i = 4; i <= n; i++) {
    k = index(f[i], ":"); if (k == 0) continue
    lab = substr(f[i], 1, k - 1)
    if (!((id, lab) in AL)) AL[id, lab] = trim(substr(f[i], k + 1))
  }
}
BEGIN {
  G = (g094 == "yes"); P = (pause == "yes"); G5 = (g095 == "yes")
  split("functional nfr ux_flow data_entity", WL, " "); for (i in WL) DEM[WL[i]] = 1
  split("DIM-nfr-security DIM-nfr-privacy DIM-authorization DIM-consent DIM-data-integrity", WL, " "); for (i in WL) SENS[WL[i]] = 1
  # the stopword list of the evidence scan (vid-prd-growth-2026-09-24/dups.py)
  split("a an the and or of to in on for by with is are be its it that this as at from any every each no not never when while than then which who whose their there only one into out within without per can may must", WL, " ")
  for (i in WL) STOP[WL[i]] = 1
}
substr($0, 1, 1) == "\001" { sec = substr($0, 2); next }
sec == "ITEMS" { item($0); next }
sec == "ANS" { answer($0); next }
sec == "FEAT" { FR[++NFR] = $0; next }
sec == "GOALS" { if ($0 != "" && !($0 in GOAL)) { GOAL[$0] = 1; GORD[++NGOAL] = $0 } next }
sec == "FIND" {
  n = split($0, f, "|"); nt = split(f[4], tg, ",")
  for (i = 1; i <= nt; i++) for (j = 1; j <= nt; j++) if (i != j) FPAIR[trim(tg[i]), trim(tg[j])] = 1
  next }
sec == "OPEN" {
  if (!match($0, /VID-QUESTION: \(OQ-[0-9]+\)/)) next
  q = substr($0, RSTART + 15, RLENGTH - 16); if (q in OPEN) next
  rest = trim(substr($0, RSTART + RLENGTH)); d = ""
  if (match(rest, /^A-[0-9]+/)) { d = substr(rest, 1, RLENGTH); rest = trim(substr(rest, RLENGTH + 1)) }
  sub(/^(—|-+)[ \t]*/, "", rest)
  OPEN[q] = 1; OORD[++NOQ] = q; ODEC[q] = d; OTXT[q] = rest
  if (d != "") OBY[d] = OBY[d] (OBY[d] == "" ? "" : " ") q
  next }
sec == "RES" {
  if (!match($0, /^RESOLVED: \(OQ-[0-9]+\)/)) next
  q = substr($0, 12, RLENGTH - 12); rest = substr($0, RLENGTH + 1)
  if (!(q in RDEC)) { RORD[++NRQ] = q; RDEC[q] = match(rest, /A-[0-9]+/) ? substr(rest, RSTART, RLENGTH) : "" }
  next }
sec == "SEED" { SEEDTXT = SEEDTXT " " $0; next }
sec == "THESIS" { THTXT = THTXT " " $0; next }
sec == "SOURCES" { SRCTXT = SRCTXT " " $0; next }
sec == "SUMS" { split($0, SM2, "\t"); SUM[SM2[1]] = SM2[2]; next }
END {
  # --- join 16, the rules of the block itself: unique ids, AMENDED with an ancestor,
  # the goal a ### MVP focus label or `-`; the effective rows latest per id.
  nf = 0
  for (j = 1; j <= NFR; j++) {
    n = split(FR[j], f, "|"); for (i = 1; i <= n; i++) f[i] = trim(f[i])
    raw = f[1]; fid = raw; am = sub(/[ \t]+AMENDED$/, "", fid)
    if (n < 3) { if (G) gap("join 16 (" raw "): a features row under-parses (" n " field(s); FEAT-NN | goal | name)."); continue }
    if (n > 3 && G) gap("join 16 (" raw "): a features row carries " n " fields — FEAT-NN | goal | name; a stray | inside the name.")
    if (fid !~ /^FEAT-[0-9]+$/) { if (G) gap("join 16 (" raw "): a feature id is FEAT-NN, or FEAT-NN AMENDED for a rename."); continue }
    if (am) { if (G && !(fid in FSEEN)) gap("join 16 (" raw "): no earlier features row with id " fid " — an amendment needs an ancestor.") }
    else if (G && (fid in FSEEN)) gap("join 16: duplicate feature id " fid " — ids are stable and never reused; a rename or retirement is " fid " AMENDED, latest wins.")
    FSEEN[fid] = 1
    if (G && f[2] != "-" && !(f[2] in GOAL)) gap("join 16 (" raw "): goal \047" f[2] "\047 is no goal label in ### MVP focus — the goal the feature serves, or - for an outcome outside the ratified thesis.")
    if (!(fid in FGOAL)) FORD[++nf] = fid
    FGOAL[fid] = f[2]; FNAME[fid] = f[3]
  }
  if (G) {
    for (k = 1; k <= nf; k++) if (FGOAL[FORD[k]] == "-") note("join 16 (" FORD[k] "): goal - — serves no ratified goal (legal: an outcome outside the frozen thesis).")
    if (nf <= NGOAL) note("join 16: " nf " feature(s) for " NGOAL " goal(s) — a feature is narrower than a goal.")
  }
  for (k = 1; k <= NA; k++) { a = AID[k]; valset(AL[a, "A"], AV); for (v in AV) ATOK[a, v] = 1; split("", AV) }
  valset(SEEDTXT, SEEDV); valset(THTXT, THV); valset(SRCTXT, SRCV)
  for (j = 1; j <= NI; j++) {
    id = IID[j]; ty = IT[id]; ti = ITIER[id]; dem = (ty in DEM)
    au = IL[id, "authority"]; cv = IL[id, "confirms_via"]
    kind = cv; sub(/[\/ ].*/, "", kind); bl = cv; sub(/.*\//, "", bl)
    ph = IL[id, "phase"]; if (ph == "") ph = "pilot"
    if (dem) { NDEM++; if (ph == "pilot") NPILD++ }
    # --- join 16, the item side (waits for items): every demand item and
    # invariant carries feature: exactly once, a single FEAT-NN naming an
    # effective feature; a frame item may carry one under the same rules.
    fe = IFEAT[id]
    if (INF[id] == 0) { if (G && (dem || ty == "invariant")) gap("join 16 (" id "): no feature: — every demand item and invariant belongs to exactly one feature.") }
    else {
      if (G && INF[id] > 1) gap("join 16 (" id "): " INF[id] " feature: fields — an item belongs to exactly one feature.")
      if (fe !~ /^FEAT-[0-9]+$/) { if (G) gap("join 16 (" id "): feature: \047" fe "\047 is not a single FEAT-NN — no lists; an item belongs to exactly one feature.") }
      else if (!(fe in FGOAL)) { if (G) gap("join 16 (" id "): feature: " fe " names no declared feature — declare it in a ```vid-prd-features row.") }
      else { if (dem) { FDEM[fe]++; if (ph == "pilot") FPIL[fe]++ } if (ti == "T0") FT0[fe]++ }
    }
    # --- join 21 (v0.9.5 3.13): one plain sentence per demand item and invariant.
    if (G5 && (dem || ty == "invariant")) {
      if (IPN[id] == 0) gap("join 21 (" id "): no plain: — every demand item and invariant says its rule in one plain sentence (plain: <the rule in the owner\047s words>).")
      else {
        if (IPN[id] > 1) gap("join 21 (" id "): " IPN[id] " plain: fields — one plain sentence per item.")
        pl = IPLAIN[id]
        if (pl == "") gap("join 21 (" id "): plain: is empty.")
        if (match(pl, /[.?!] [A-Z0-9]/)) gap("join 21 (" id "): plain: holds more than one sentence — one sentence (write \047for example\047, not \047e.g.\047).")
        nw = split(pl, PW, /[ \t]+/); if (nw > 30) gap("join 21 (" id "): plain: runs to " nw " words — at most 30.")
        if (match(" " pl, /[^A-Za-z0-9_](REQ|INV|NG|A|OQ|FEAT|MECH|ROW|D)-[0-9]+/)) gap("join 21 (" id "): plain: names the id \047" substr(" " pl, RSTART + 1, RLENGTH - 1) "\047 — say the rule in words.")
        else if (match(" " pl, /[^A-Za-z0-9_](DIM|SRC)-[A-Za-z]/)) gap("join 21 (" id "): plain: names an id (\047" substr(" " pl, RSTART + 1, RLENGTH - 1) "…\047) — say the rule in words.")
        npv = vals(pl, PV); split("", SV); valset(ISTMT[id] " " IL[id, "fail-if"], SV)
        for (k = 1; k <= npv; k++) if (!(PV[k] in SV)) gap("join 21 (" id "): plain: holds the number \047" PV[k] "\047, which neither its statement nor its fail-if holds — the sentence says its own rule and adds nothing.")
      }
    }
    # --- source entries, matched by prefix (3.4): `A-NNN…`, `seed…`,
    # `thesis…`, `SRC-…`, the door sittings `fix `/`grade `/`design `.
    src = IL[id, "source"]; ne = split(src, E, ",")
    nv = 0; nsrc = 0; prop = 0; door = ""; cseed = 0; cth = 0; vl = ""; split("", CA); nw17 = 0; wl17 = ""; split("", W17)
    for (k = 1; k <= ne; k++) {
      e = trim(E[k]); if (e == "") continue
      if (e == "proposal") prop = 1
      if (match(e, /^A-[0-9]+/)) {
        a = substr(e, 1, RLENGTH); CA[a] = 1
        if (!((a, id) in GRD)) {
          GRD[a, id] = 1; GTOT[a]++; GIT[a] = add(GIT[a], id)
          if (ti == "T0") { GT0[a]++; T0CITE[a] = id } else if (ti == "T1") GT1[a]++; else if (ti == "T2") GT2[a]++
          if ((a in AT) && AT[a] == "model_proposed") { V[++nv] = a; vl = add(vl, a) }
        }
      }
      # v0.9.8.1 (R38, F-28): join 17 reads every A-NNN in the entry, parenthesised or not — one only this reading
      # finds is counted for the provisional rule, and refused for the authoritative one from grammar 0.9.8.1, reported before
      # v0.9.8.1 (R38 follow-up): only a whole identifier — no letter, digit, _ or - before it, no letter, digit or _ after
      # (SRC-DATA-005 is not A-005)
      if (!match(e, /^A-[0-9]+/)) { t17 = e; lc17 = ""; while (match(t17, /A-[0-9]+/)) { a = substr(t17, RSTART, RLENGTH); b17 = (RSTART > 1) ? substr(t17, RSTART - 1, 1) : lc17
          f17 = substr(t17, RSTART + RLENGTH, 1); lc17 = substr(a, length(a), 1); t17 = substr(t17, RSTART + RLENGTH)
          if (b17 ~ /[A-Za-z0-9_-]/ || f17 ~ /[A-Za-z0-9_]/) continue
          if ((a in AT) && AT[a] == "model_proposed" && !(a in CA) && !(a in W17)) { W17[a] = 1; nw17++; wl17 = add(wl17, a) } } }
      if (e ~ /^SRC-/) nsrc++
      else if (e ~ /^seed/) cseed = 1
      else if (e ~ /^thesis/) cth = 1
      else if (e ~ /^(fix|grade|design) /) door = e
    }
    # --- join 17: honest labels.
    if (G) {
      if (prop) gap("join 17 (" id "): source entry \047proposal\047 — retired; a ViD decision is a model_proposed ledger row, cited by its A-NNN.")
      if (au == "authoritative" && nv > 0) gap("join 17 (" id "): authoritative but cites " vl " — a ViD decision (model_proposed) grounds at most provisional; once the owner rules, the answer is restated human and the item amended.")
      if (au == "authoritative" && nv == 0 && nw17 > 0) { m17 = "join 17 (" id "): authoritative but its source: cites " wl17 " — a ViD decision (model_proposed) grounds at most provisional"
        if (g0981 == "yes") gap(m17 "; once the owner rules, the answer is restated human and the item amended."); else note(m17 " — reported, not refused, under grammar " grammar " (refused from grammar 0.9.8.1).") }
      if (au == "provisional" && kind == "owner-decision" && nv == 0 && nw17 == 0 && nsrc == 0) gap("join 17 (" id "): provisional on an owner decision but cites neither a ViD decision (a model_proposed A-NNN) nor a source document (SRC-) — cite the decision or document it rests on.")
    }
    # --- join 18: a T0 item (any type) resting on ViD decisions is
    # provisional, routed /yes to one open carrier per decision.
    if (ti == "T0") {
      split("", LQ); t = cv
      while (match(t, /OQ-[0-9]+/)) {
        q = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH); LQ[q] = 1
        if (!((q, id) in T0W)) { T0W[q, id] = 1; T0WAIT[q] = add(T0WAIT[q], id) }
      }
      if (G && nv > 0) {
        for (q in LQ) CHK[q] = 1
        if (au != "provisional") gap("join 18 (" id "): a T0 item resting on ViD decision(s) " vl " is provisional, confirms_via: owner-decision <one open question per decision>/yes — got \047" au "\047" (au == "pending" ? " (the pending form is excluded: join 7 forbids an answer settling a pending item)" : "") ".")
        else {
          if (bl != "yes") gap("join 18 (" id "): a T0 item resting on ViD decision(s) " vl " waits on the owner — confirms_via ends /yes, got /" bl ".")
          for (k = 1; k <= nv; k++) {
            a = V[k]
            if (!(a in OBY)) { gap("join 18 (" id "): ViD decision " a " has no open question — a must-never-break rule\047s ViD decision is asked: VID-QUESTION: (OQ-n) " a " — <the question>, listed in confirms_via."); continue }
            m = split(OBY[a], Q, " "); hit = 0
            for (i = 1; i <= m; i++) if (Q[i] in LQ) hit = 1
            if (!hit) gap("join 18 (" id "): confirms_via omits " OBY[a] ", the open question asking " a " — list each ViD decision\047s question.")
          }
        }
      }
    }
    # --- join 19: values traced — the statement only, of authoritative and
    # provisional owner-decision items; a door sitting reference is counted.
    if (au == "authoritative" || (au == "provisional" && kind == "owner-decision")) {
      if (door != "") { UNCH++; if (G && P) gap("join 19 (" id "): cites the door sitting \047" door "\047 at a pause — create-prd rows cite no door sitting; cite the decision that states each value.") }
      else if (G) {
        n = vals(ISTMT[id], VV)
        for (k = 1; k <= n; k++) {
          v = VV[k]; if (v == "0" || v == "1") continue
          ok = (cseed && (v in SEEDV)) || (cth && (v in THV)) || (nsrc && (v in SRCV))
          if (!ok) for (a in CA) if ((a, v) in ATOK) { ok = 1; break }
          if (!ok) gap("join 19 (" id "): value \047" v "\047 appears in none of its cited sources (" (src == "" ? "none" : src) ") — cite the decision that states it (an owner answer, or a ViD decision whose A: states it).")
        }
      }
    }
    if (!P) continue
    # --- the pause lists: sensitive, measurement and external-dependency, near-duplicate candidates.
    if ((ti == "T1" || ti == "T2") && nv > 0) {
      nc = split(IL[id, "covers"], CV, ","); hits = ""
      for (k = 1; k <= nc; k++) { c = trim(CV[k]); sub(/\/.*/, "", c); if (c in SENS) hits = add(hits, c) }
      if (hits != "") SL[++NSL] = id " | " ti " | " hits " | rests on " vl
    }
    if ((kind == "measurement" && IL[id, "derives"] != "golden-set") || kind == "external-dependency")
      ML[++NML] = id " | " au " | confirms_via: " cv (kind == "measurement" ? " | no derives: golden-set" : "")
    if (dem || ty == "non_goal" || ty == "invariant") {
      C[++NC] = id; ntoks(ISTMT[id], id, "S"); ntoks(ISTMT[id] " " IL[id, "fail-if"], id, "T")
    }
  }
  # --- join 18, the carriers: a must-never-break question (one a T0 item on a
  # ViD decision routes to, or any open carrier naming an answer) asks exactly
  # one ViD decision, named after its id.
  if (G) for (k = 1; k <= NOQ; k++) {
    q = OORD[k]; d = ODEC[q]
    if (!(q in CHK) && d == "") continue
    if (d == "") gap("join 18 (" q "): a must-never-break question names no ViD decision — VID-QUESTION: (" q ") A-NNN — <the question>, one decision per question.")
    else if (!(d in AT)) gap("join 18 (" q "): names " d ", which is no ledger answer.")
    else if (AT[d] != "model_proposed") gap("join 18 (" q "): names " d ", which is " AT[d] ", not a ViD decision — an answered question is rewritten RESOLVED: (" q ") " d " — ….")
  }
  for (k = 1; k <= NA; k++) {
    a = AID[k]
    if (AT[a] == "human" && AL[a, "importance"] == "priority") NPRI++
    if (AT[a] == "model_proposed") { NMP++; if (AL[a, "shown"] != "") NSHOWN++ }
  }
  # --- the importance floor (under --pause): a human answer settling a T0
  # item, cited by one, or resolving a carrier one routes to, is priority.
  if (G && P) for (k = 1; k <= NA; k++) {
    a = AID[k]; if (AT[a] != "human" || AL[a, "importance"] == "priority") continue
    why = ""; ns = split(AL[a, "settles"], S2, ",")
    for (i = 1; i <= ns && why == ""; i++) { r = trim(S2[i]); if ((r in IT) && ITIER[r] == "T0") why = "settles T0 " r }
    if (why == "" && (a in T0CITE)) why = "cited by T0 " T0CITE[a]
    for (i = 1; i <= NRQ && why == ""; i++) { q = RORD[i]; if (RDEC[q] == a && (q in T0WAIT)) why = "resolves " q ", which T0 " T0WAIT[q] " routes to" }
    if (why != "") gap("importance (" a "): a human answer shaping a must-never-break rule (" why ") carries importance: priority.")
  }
  # --- join 20 (under --pause): every model_proposed answer carries a current shown:.
  nd = 0
  if (P) for (k = 1; k <= NA; k++) {
    a = AID[k]; if (AT[a] != "model_proposed") continue
    lab = AL[a, "shown"]; s = lab; cur = (lab != "" && sub(/^pause-[0-9]+[ \t]+/, "", s) && s == SUM[a])
    if (cur) continue
    D[++nd] = a; REV[a] = (lab != "")
    if (G) gap("join 20 (" a "): " (lab != "" ? "revised since it was shown (shown: " lab " no longer matches its A:)" : "a ViD decision not yet shown to the owner") " — present it at this pause, then label it shown: pause-N " SUM[a] ".")
  }
  if (P) {
    print ""
    print "pause material (checks/prd.sh --pause, grammar " grammar ")"
    b1 = ""; b2 = ""
    for (k = 1; k <= nf; k++) {
      fe = FORD[k]; c = FPIL[fe] + 0
      if (b1 == "" || c > FPIL[b1] + 0 || (c == FPIL[b1] + 0 && num(fe) < num(b1))) { b2 = b1; b1 = fe }
      else if (b2 == "" || c > FPIL[b2] + 0 || (c == FPIL[b2] + 0 && num(fe) < num(b2))) b2 = fe
    }
    lg = (b1 == "") ? "none" : b1 " (" (FPIL[b1] + 0) ")" (b2 == "" ? "" : ", " b2 " (" (FPIL[b2] + 0) ")")
    printf "size: demand=%d pilot=%d grader-batches≈%.1f features=%d largest=%s\n", NDEM, NPILD, NDEM / 30, nf, lg
    nq = 0; for (k = 1; k <= NOQ; k++) if (OORD[k] in T0WAIT) nq++
    print "questions (must-never-break, each asking one ViD decision): " nq
    for (k = 1; k <= NOQ; k++) {
      q = OORD[k]; if (!(q in T0WAIT)) continue; d = ODEC[q]
      print "  " q (d != "" ? " " d : "") " — " OTXT[q] ((d in AT) ? " | recommended: " AL[d, "A"] : "") " | waiting: " T0WAIT[q]
    }
    for (i = 1; i <= nd; i++) for (j = i + 1; j <= nd; j++) if (before(D[j], D[i])) { x = D[i]; D[i] = D[j]; D[j] = x }
    print "new ViD decisions (not yet shown; ranked by T0, T1, total grounded, id): " nd
    for (k = 1; k <= nd; k++) {
      a = D[k]
      print "  " a (REV[a] ? " (revised)" : "") " | " SUM[a] " | grounds T0 " (GT0[a] + 0) " · T1 " (GT1[a] + 0) " · T2 " (GT2[a] + 0) " (items " (GIT[a] == "" ? "none" : GIT[a]) ") | A: " AL[a, "A"]
    }
    print "sensitive (T1/T2 resting on a ViD decision, covering security, privacy, authorization, consent or data integrity): " NSL + 0
    for (k = 1; k <= NSL; k++) print "  " SL[k]
    print "measurement and external-dependency (the routes join 19 does not trace): " NML + 0
    for (k = 1; k <= NML; k++) print "  " ML[k]
    npr = 0
    for (x = 1; x <= NC; x++) for (y = x + 1; y <= NC; y++) {
      a = C[x]; b = C[y]; sa = TN["S", a]; sb = TN["S", b]
      if (sa == 0 || sb == 0 || ((a, b) in FPAIR)) continue
      ov = shared("S", a, b) / (sa < sb ? sa : sb); if (ov < 0.6) continue
      k = shared("T", a, b); jc = k / (TN["T", a] + TN["T", b] - k); if (jc < 0.35) continue
      PR[++npr] = a " ~ " b " | overlap " sprintf("%.2f", ov) " · jaccard " sprintf("%.2f", jc)
    }
    print "near-duplicates (not yet ruled; statement overlap ≥0.6 and statement+fail-if Jaccard ≥0.35): " npr
    for (k = 1; k <= npr; k++) print "  " PR[k]
    print "features: " nf
    for (k = 1; k <= nf; k++) { fe = FORD[k]; print "  " fe " | " FGOAL[fe] " | " FNAME[fe] " | pilot demand " (FPIL[fe] + 0) " | T0 " (FT0[fe] + 0) }
    line = ""
    for (k = 1; k <= NGOAL; k++) { g = GORD[k]; c = 0; for (i = 1; i <= nf; i++) if (FGOAL[FORD[i]] == g) c++; line = add(line, g " " c) }
    c = 0; for (i = 1; i <= nf; i++) if (FGOAL[FORD[i]] == "-") c++; if (c) line = add(line, "- " c)
    print "features per goal: " (line == "" ? "none" : line)
    e = ""; c = 0; for (i = 1; i <= nf; i++) if (FDEM[FORD[i]] + 0 == 0) { c++; e = add(e, FORD[i]) }
    print "features with no demand item: " c (c ? " — " e : "")
    c = 0; for (j = 1; j <= NI; j++) { id = IID[j]; if ((IT[id] in DEM) || IT[id] == "invariant") c++ }
    print "plain sentences (every demand item and invariant, each beside its rule; the owner approves both): " c
    for (j = 1; j <= NI; j++) { id = IID[j]; if (!((IT[id] in DEM) || IT[id] == "invariant")) continue
      print "  " id " | plain: " (IPN[id] ? IPLAIN[id] : "(none)") " | rule: " ISTMT[id] }
  }
  printf "\001 %d %d %d %d %d %d %d\n", ngap, nnote, nf, NPRI, NSHOWN, NMP, UNCH
}'
JOUT=$( {
  printf '\001ITEMS\n'; [ -z "$EFF" ] || printf '%s\n' "$EFF"
  printf '\001ANS\n'; [ -z "$AEFF" ] || printf '%s\n' "$AEFF"
  printf '\001FEAT\n'; [ -z "$FEATRAW" ] || printf '%s\n' "$FEATRAW"
  printf '\001GOALS\n'; [ -z "$GOALS" ] || printf '%s\n' "$GOALS"
  printf '\001FIND\n'; [ -z "$FINDINGS" ] || printf '%s\n' "$FINDINGS"
  printf '\001OPEN\n'; [ -z "$OPENL" ] || printf '%s\n' "$OPENL"
  printf '\001RES\n'; [ -z "$RESL" ] || printf '%s\n' "$RESL"
  printf '\001SEED\n'; [ -z "$SEEDFLAT" ] || printf '%s\n' "$SEEDFLAT"
  printf '\001THESIS\n'; [ -z "$THESIS" ] || printf '%s\n' "$THESIS"
  printf '\001SOURCES\n'; [ -z "$SOURCES" ] || printf '%s\n' "$SOURCES"
  printf '\001SUMS\n'; [ -z "$SUMS" ] || printf '%s\n' "$SUMS"
} | LC_ALL=C awk -v g094="$G094" -v g095="$G095" -v g0981="$G0981" -v pause="$PAUSE" -v npos="$NPOS" -v sect="$SECT" -v grammar="$GRAMMAR" "$J094") \
  || { echo 'ViD prd: the 0.9.4 pass (joins 16-20) did not run — failing closed.' >&2; exit 1; }
JCOUNTS=$(printf '%s\n' "$JOUT" | sed -n '$p')
JBODY=$(printf '%s\n' "$JOUT" | sed '$d')
[ -z "$JBODY" ] || printf '%s\n' "$JBODY"
IFS=' ' read -r _ JG JN JF JP JS JM JU <<EOF
$JCOUNTS
EOF
GAPS=$((GAPS + JG)); NOTES=$((NOTES + JN))

# --- report (counts, never scores) -----------------------------------------
NITEMS=$(printf '%s\n' "$EFF" | grep -c . || true)
NOQ=$(grep -c 'VID-QUESTION: (OQ-' "$PRD" || true)
NROQ=$(grep -c '^RESOLVED: (OQ-' "$PRD" || true)
echo ''
if [ "$NPOS" -eq 5 ]; then P0REPORT="P0=$NP0/$NDEMAND "; else P0REPORT=''; fi
echo "prd: items=$NITEMS demand=$NDEMAND frame=$NFRAME non-goals=$NG ${P0REPORT}pilot=$NPILOT later=$NLATER authoritative=$NAUTH provisional=$NPROV (owner-decision=$NODPROV) pending=$NPEND blocking-confirms=$NBLOCK open-OQs=$NOQ resolved-OQs=$NROQ dims=$NDIMS (mechanism=$NMECHD nfr=$NNFRD proof=$NPROOFD) covered=$NCOV na=$NNA facets=$NFACETS answers=$((NHUM + NMOD)) (human=$NHUM model=$NMOD) findings=$NFIND arm-losing=$ARMLOSING arm-changed=$ARMCHANGED gaps=$GAPS grammar=$GRAMMAR notes=$NOTES features=$JF priority=$JP shown=$JS/$JM values-unchecked=$JU"
[ "$MODE" = report ] && exit 0
if [ "$GAPS" -gt 0 ]; then
  echo 'ViD prd: rejected — repair the named gaps; the court refuses to let a convicted artifact be presented as ratifiable.' >&2
  exit 1
fi
exit 0
