#!/bin/sh
# Purpose: ViD court — the enriched PRD grammar (v0.8.1a skill, installed
# at init since v0.8.1b).
# Reads the five machine blocks in a PRD.md (```vid-prd items,
# ```vid-prd-contract, ```vid-prd-answers, ```vid-prd-mechanisms,
# ```vid-prd-findings; under grammar 0.9.4 ```vid-prd-features too) and runs
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
# 0.26.10.29.4 (phase 3 R4): --arms prints, one a line, each kept arm reworded and still open —
# `<id> arm <n> <retained|strengthened> | was: <old arm> | now: <the item's fail-if today>`: a predecessor arm an
# AMENDED row marks retained or strengthened that no arm of its fail-if equals exactly (join 14's split, white space
# normalised), until a later revision restores it exactly or the owner rules on that arm (a findings row targeting the
# item, evidence `arm <n>`, `accepted|overruled A-NNN` under a human, undelegated answer of the amending row's append
# or later, not one its source: cites; the block above the --arms mode says it whole). Read-only; silent and 0 when
# there is none or the file is absent; the review passes read it (the whole-set review's delta mode, the strength pass).
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
# T0 item carries `importance: priority`; 0.26.10.29.6 (S6): a NOTE in
# every other run, refusing nothing), both only under g094, and prints
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
# 0.26.10.29.3 (R1): --before <file>, the pre-consolidation PRD — the effective mechanism rows (base and appends,
# latest per id, AMENDED stripped, fields trimmed) must be the same in both files, row for row; each id that differs is
# a gap (consolidation keeps every mechanism as amended). checks/prd-consolidate.sh passes it.
# 0.26.10.29.3 (R2): join 14 reads the withdrawing answer's tier — an arm withdrawn under a model_proposed answer (ViD's
# draft) is a gap at commit (a NOTE on a legacy file, as every join 14 rule); under --pause it is not refused, and the
# pause material lists it last as an owner question, `arm N of REQ-x withdrawn under ViD's draft A-NNN`.
# An answer row may carry `delegated: yes` (a human answer ViD wrote under the owner's delegation; confirmed, it is
# restated without the field): an arm withdrawn under an answer whose effective row carries it is held the same way,
# whatever the order — `arm N of REQ-x withdrawn under A-NNN, a delegated answer not yet confirmed`.
# 0.26.10.29.3 (R9): every mode first runs `checks/eol.sh file` on its input and refuses a CR LF file with eol.sh's line,
# and the court does the same for the seed file a `Seed:` line points at (F53); a `## Seed` section cut short by the
# seed's own `## ` heading gives one join-11 advice line, SEED.md and its
# `Seed:` pointer, instead of one gap per excerpt found later in the file (F44).
# Usage: sh checks/prd.sh [PRD.md] [--report] [--pause] [--before <file>] · sh checks/prd.sh --effective|--failifs|--arms [PRD.md]
# serves: both (0.26.10.28.4, M9)
set -eu
_vidwsl=${0%/*}/lib/wsl.sh; [ ! -f "$_vidwsl" ] || . "$_vidwsl"   # 0.26.10.29.3 (R6): on native Windows, with the owner's yes, this court re-runs under WSL
IFS='
'
PRD=./PRD.md; MODE=default; PAUSE=no; BEFORE=''; _nb=no
for a in "$@"; do
  if [ "$_nb" = yes ]; then BEFORE=$a; _nb=no; continue; fi
  case "$a" in
  --report) MODE=report ;; --effective) MODE=effective ;; --failifs) MODE=failifs ;; --arms) MODE=arms ;; --pause) PAUSE=yes ;; --before) _nb=yes ;;
  --*) echo "ViD prd: unknown flag '$a' — the flags are --report, --pause, --before <file>, --effective, --failifs, --arms; refusing rather than reading it as a file." >&2; exit 1 ;;
  *) PRD=$a ;; esac; done
[ "$_nb" = no ] || { echo 'ViD prd: --before names no file — the pre-consolidation PRD follows it.' >&2; exit 1; }
[ -z "$BEFORE" ] || [ -f "$BEFORE" ] || { echo "ViD prd: --before '$BEFORE' does not exist — refusing rather than comparing with nothing." >&2; exit 1; }
[ -f "$PRD" ] || exit 0
# 0.26.10.29.3 (R9, F53): eol.sh's test on the input first, in every mode — a CR LF file is refused with its line, never
# misread and never stripped
_EOL=$(dirname "$0")/eol.sh; if [ -f "$_EOL" ]; then sh "$_EOL" file "${PRD#./}" || exit 1; fi
if [ "$MODE" = effective ] || [ "$MODE" = failifs ]; then
  if grep -q '^```vid-prd$' "$PRD"; then
    EFFR=$(sed -n '/^```vid-prd$/,/^```$/p' "$PRD" | grep -v '^```' | LC_ALL=C grep -v '^[[:space:]]*#' | LC_ALL=C grep -v '^[[:space:]]*$' | awk -F'|' '{
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
# gnum (0.26.11.1.2, R13): the same comparison, on all five components, against 0.26.11.1.2, the grammar whose fail-if is written in
# numbered parts, `fail-if: (1) <one failure>; (2) …` — arms_of then splits on the numbers, and join 3 refuses a fail-if
# that does not open `(1) `, numbers that skip and an empty part; an older grammar keeps its split and its checks.
GNUM=no
[ "$GRAMMAR" = legacy ] || GNUM=$(printf '%s\n' "$GRAMMAR" | awk -F. '{ split("0.26.11.1.2", w, ".")
  for (i = 1; i <= 5; i++) { a = $i + 0; if (a > w[i] + 0) { print "yes"; exit } if (a < w[i] + 0) { print "no"; exit } }
  print "yes" }')
# Positional fields (v0.9.1 3.8): legacy rows carry five (ID | type | tier |
# priority | statement); under `grammar: 0.9.1` the priority column is gone
# and rows carry four (ID | type | tier | statement). Labeled fields follow.
if [ "$GRAMMAR" = legacy ]; then NPOS=5; else NPOS=4; fi
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

# 0.26.10.29.3 (R6): the three block readers (blk here, --effective above, --before's file below) drop comment and
# blank lines in the C locale, so a line holding only white space outside ASCII is a row, in every locale
blk() { sed -n "/^\`\`\`$1\$/,/^\`\`\`\$/p" "$PRD" | grep -v '^```' | LC_ALL=C grep -v '^[[:space:]]*#' | LC_ALL=C grep -v '^[[:space:]]*$' || true; }
ITEMS_RAW=''; [ "$HASITEMS" = yes ] && ITEMS_RAW=$(blk vid-prd)
CONTRACT=$(blk vid-prd-contract)
ANSWERS=$(blk vid-prd-answers); MECHS=$(blk vid-prd-mechanisms)
if [ "$HASITEMS" = yes ] && [ "$MODE" != arms ]; then   # 0.26.10.29.4 (phase 3 R4): --arms reads, it judges nothing
  [ -n "$CONTRACT" ] || { echo 'ViD prd: items exist but no ```vid-prd-contract block — failing closed.' >&2; exit 1; }
  [ -n "$ANSWERS" ] || { echo 'ViD prd: items exist but no ```vid-prd-answers block — failing closed.' >&2; exit 1; }
fi

# 0.26.10.29.3 (R6): the field helpers set a variable instead of printing, and read with the shell's own pattern
# operators, so the loops over items, answers, amendments and the other blocks start no process per field: starting a
# process is slow on native Windows, and hooks always run there natively. Each gives the old helper's result
# (field: cut -d'|' -f n, trimmed; labeled: the first field opening `<label>:`, its value trimmed; nfields: awk's NF),
# with one known difference: white space outside ASCII is not white space to the PRD court. White space is the six
# characters of WS below (space, tab, newline, carriage return, vertical tab, form feed: what [[:space:]] is in the C
# locale), named one by one, so the verdict is the same under every shell and locale; the old pipelines took a
# no-break space or an em space for white space under a UTF-8 locale and not under C.
# A shape the pattern form would read differently (an id holding a character a grep pattern treats specially, a
# grounding with several A- or OQ- references) takes the old command, from a helper, in the C locale, where its
# [[:space:]] is those same six characters. The helpers are called from the loops, so such a shape still costs one
# process each time it is met; an ordinary id costs none.
NL='
'
TB=$(printf '\t'); CR=$(printf '\r'); VT=$(printf '\v'); FF=$(printf '\f')
WS=" $TB$NL$CR$VT$FF"
_trim() { _t=${FV%%[!"$WS"]*}; FV=${FV#"$_t"}; _t=${FV##*[!"$WS"]}; FV=${FV%"$_t"}; return 0; }
field() { # $1 row, $2 n → FV (a row with no | is its own every field, as cut prints it)
  case $1 in *'|'*) ;; *) FV=$1; _trim; return 0 ;; esac
  _s=$1; _i=1
  while [ "$_i" -lt "$2" ]; do case $_s in *'|'*) _s=${_s#*'|'} ;; *) FV=''; return 0 ;; esac; _i=$((_i + 1)); done
  FV=${_s%%'|'*}; _trim; return 0; }
labeled() { # $1 row, $2 label → LV, and LF=yes when a field opens `<label>:` at all
  _s=$1; LV=''; LF=no
  while :; do
    _f=${_s%%'|'*}; _f=${_f#"${_f%%[!"$WS"]*}"}
    case $_f in "$2":*) FV=${_f#"$2":}; _trim; LV=$FV; LF=yes; return 0 ;; esac
    case $_s in *'|'*) _s=${_s#*'|'} ;; *) return 0 ;; esac
  done; }
nfields() { NFV=0; [ -n "$1" ] || return 0; _s=$1; NFV=1; while :; do case $_s in *'|'*) _s=${_s#*'|'}; NFV=$((NFV + 1)) ;; *) return 0 ;; esac; done; }
_list() { # $1 a comma list → LS: its entries trimmed, the empty ones dropped, one a line (tr ',' '\n' | sed | grep -v '^$')
  LS=''; LN=0; _s=$1
  while :; do FV=${_s%%,*}; _trim; [ -z "$FV" ] || { LS=$LS$NL$FV; LN=$((LN + 1)); }; case $_s in *,*) _s=${_s#*,} ;; *) break ;; esac; done
  LS=${LS#"$NL"}; return 0; }
_inany() { # $1 lines, $2 one pattern a line: any pattern is a whole line of $1 (grep -qxF with several patterns)
  case $2 in *"$NL"*) ;; *) _in "$1" "$2"; return ;; esac
  _p=$2; while :; do _in "$1" "${_p%%"$NL"*}" && return 0; case $_p in *"$NL"*) _p=${_p#*"$NL"} ;; *) return 1 ;; esac; done; }
_sq() { SQ=$1; while :; do case $SQ in *'  '*) SQ=${SQ%%'  '*}' '${SQ#*'  '} ;; *) return 0 ;; esac; done; }   # tr -s ' '
_nraw() { # $1 a comma list → NRAW: its entries that hold any character (tr ',' '\n' | grep -c .)
  NRAW=0; _s=$1
  while :; do [ -z "${_s%%,*}" ] || NRAW=$((NRAW + 1)); case $_s in *,*) _s=${_s#*,} ;; *) return 0 ;; esac; done; }
_in() { case "$NL$1$NL" in *"$NL$2$NL"*) return 0 ;; esac; return 1; }   # $2 is a whole line of $1 (grep -qxF)
_amid() { FV=${1%AMENDED}; _t=${FV##*[!"$WS"]}; FV=${FV%"$_t"}; return 0; }   # sed 's/[[:space:]]*AMENDED$//'
_first() { case $2 in *"$1"*) _t=${2#*"$1"}; FM=$1${_t%%[!0-9]*} ;; *) FM='' ;; esac; return 0; }   # grep -o '<p>[0-9]*' | head -n 1
_all() { # $1 prefix, $2 text → FA (every match of '<p>[0-9]*', one a line, as grep -o prints them) and FN (their count)
  FA=''; FN=0; _t=$2
  while :; do case $_t in *"$1"*) _t=${_t#*"$1"}; _d=${_t%%[!0-9]*}; _t=${_t#"$_d"}; FA=$FA$NL$1$_d; FN=$((FN + 1)) ;; *) break ;; esac; done
  FA=${FA#"$NL"}; return 0; }
_key() { # $1 an id → KV, a variable-name form of it; '' when it holds more than letters, digits, _ and -
  case $1 in ''|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-]*) KV=''; return 0 ;; esac
  KV=''; _s=$1
  while :; do case $_s in *_*) KV=$KV${_s%%_*}_U; _s=${_s#*_} ;; *) KV=$KV$_s; break ;; esac; done
  _s=$KV; KV=''
  while :; do case $_s in *-*) KV=$KV${_s%%-*}_D; _s=${_s#*-} ;; *) KV=$KV$_s; break ;; esac; done
  return 0; }
_words() { _o=$IFS; IFS=" $TB"; set -f; set -- $1; set +f; IFS=$_o; W1=${1-}; W2=${2-}; W3=${3-}; return 0; }   # awk '{print $1}' …
_nth() { # $1 lines, $2 n → NTH, line n (sed -n 'Np')
  _s=$1; _i=1; NTH=''
  while [ "$_i" -lt "$2" ]; do case $_s in *"$NL"*) _s=${_s#*"$NL"} ;; *) return 0 ;; esac; _i=$((_i + 1)); done
  NTH=${_s%%"$NL"*}; return 0; }
normws() { # $1 → NW: every white-space character a space, runs squeezed, the ends trimmed (tr -s '[:space:]' ' ' | sed)
  _s=$1
  for _c in "$CR" "$VT" "$FF"; do
    while :; do case $_s in *"$_c"*) _s=${_s%%"$_c"*}" "${_s#*"$_c"} ;; *) break ;; esac; done
  done
  _o=$IFS; IFS=" $TB$NL"; set -f; set -- $_s; set +f; IFS=' '; NW="$*"; IFS=$_o; return 0; }
GAPS=0
gap() { echo "GAP  $*"; GAPS=$((GAPS + 1)); }
NOTES=0
note() { echo "NOTE  $*"; NOTES=$((NOTES + 1)); }
# strict: a 0.9.1 strictness — a gap under `grammar: 0.9.1`, a NOTE on a legacy file.
strict() { if [ "$GRAMMAR" = legacy ]; then note "$* — reported, not convicted (pre-0.9.1 grammar)"; else gap "$@"; fi; }
# 0.26.10.29.4 (phase 3 R4): join 14's arm split, defined here so that --arms (below) and join 14 read arms the same way.
# 0.26.10.29.3 (R6): arms_of splits in the shell — at each top-level " or ", "; or ", ", or ", the depth of the
# parentheses read in order — and sets ARMS (the arms, one a line, white space squeezed, as the awk split printed them,
# the trailing empty ones dropped as $(…) dropped them) and NARMS (the non-empty ones, the old `grep -c .`).
_depth() { _q=$1; while :; do case $_q in *[\(\)]*) ;; *) return 0 ;; esac
  _q=${_q#"${_q%%[\(\)]*}"}; case $_q in '('*) _d=$((_d + 1)) ;; *) [ "$_d" -eq 0 ] || _d=$((_d - 1)) ;; esac; _q=${_q#?}; done; }
_arm_push() { _o=$IFS; IFS=" $TB"; set -f; set -- $_cur; set +f; IFS=' '; _a="$*"; IFS=$_o
  ARMS=$ARMS$NL$_a; [ -z "$_a" ] || NARMS=$((NARMS + 1)); _cur=''; return 0; }
# Under GNUM the arms are the numbered parts: the text after `(1) `, then after each `; (<n+1>) ` in turn, the markers
# dropped; ARMBAD names what join 3 refuses — `unnumbered` (no opening `(1) `), `skip` (a part marker left in a part:
# a number skipped or repeated, a marker of any length, or one after another separator than `; `) or `empty` (a part
# with no text) — and is empty for a well-formed fail-if.
# _hasmark <part>: the part holds a marker, `(<digits>) ` anywhere or `(<digits>)` at its end.
_hasmark() { _hq=$1
  while :; do case $_hq in *'('*) ;; *) return 1 ;; esac
    _hq=${_hq#*'('}; _hm=${_hq%%')'*}; case $_hm in ''|*[!0-9]*) continue ;; esac
    case $_hq in "$_hm) "*|"$_hm)") return 0 ;; esac; done; }
arms_of() {
  _s=$1; _d=0; _cur=''; ARMS=''; NARMS=0; ARMBAD=''
  if [ "$GNUM" = yes ]; then
    case $_s in '(1) '*) _s=${_s#'(1) '} ;; *) ARMBAD=unnumbered; _cur=$_s; _arm_push; ARMS=${ARMS#"$NL"}; return 0 ;; esac
    _k=1; _s="$_s "
    while :; do _n=$((_k + 1))
      case $_s in *"; ($_n) "*) ;; *) break ;; esac
      _cur=${_s%%"; ($_n) "*}; _s=${_s#*"; ($_n) "}; _k=$_n
      _hasmark "$_cur" && ARMBAD=skip; _arm_push
    done
    _cur=${_s% }; _hasmark "$_cur" && ARMBAD=skip; _arm_push; ARMS=${ARMS#"$NL"}
    [ "$NARMS" -eq "$_k" ] || [ -n "$ARMBAD" ] || ARMBAD=empty
    while :; do case $ARMS in *"$NL") ARMS=${ARMS%"$NL"} ;; *) return 0 ;; esac; done
  fi
  while :; do
    case $_s in *' or '*) ;; *) break ;; esac
    _p=${_s%%' or '*}; _s=${_s#*' or '}; _depth "$_p"; _cur=$_cur$_p
    if [ "$_d" -eq 0 ]; then case $_cur in *';'|*',') _cur=${_cur%?} ;; esac; _arm_push; else _cur="$_cur or "; fi
  done
  _cur=$_cur$_s; _arm_push; ARMS=${ARMS#"$NL"}
  while :; do case $ARMS in *"$NL") ARMS=${ARMS%"$NL"} ;; *) return 0 ;; esac; done; }

# 0.26.10.29.4 (phase 3 R4): --arms, the kept arms reworded. For each AMENDED row whose `arms:` marks a predecessor arm
# `retained` or `strengthened`, the old arm is compared with every arm of the row's own fail-if, both split by arms_of
# and white space normalised (normws), as whole arms — never a text found inside a clause (the legacy arm-changed note
# in join 14 tests by substring; this does not), so an arm kept with a condition added is listed. An entry stays open
# until a later revision of the item (a row after the amending one) has an arm exactly equal to the old one, or a
# findings row targeting the item, its evidence opening `arm <n>`, is dispositioned `accepted A-NNN` or `overruled
# A-NNN`, where A-NNN's effective row is `human`, carries no `delegated: yes` (a delegated answer closes nothing until
# the owner confirms it, restated without the field), is none of the answers the amending row's `source:` cites, and
# lies in the amending row's own append or a later one (append order is time order; an answer of the same sitting
# counts, so an owner question ruled where it was raised is not asked again at every later review). Nothing else
# closes an entry. One line an open entry, `<id> arm <n> <disposition> | was: <old arm> | now: <the item's fail-if as
# it stands today>`; read-only, silent and 0 when there is none. One awk pass tags the rows; the loops start nothing.
# 0.26.10.29.4 (phase 3 R4, review): which answers one `source:` entry cites — join 17's reading, in one awk function
# that join 17 (the J094 program) and --arms both run, so the two never read a citation differently. An entry opening
# `A-<digits>` cites that id alone; any other entry cites each `A-<digits>` in it that is a whole identifier (no letter,
# digit, _ or - before it, no letter, digit or _ after: SRC-DATA-005 is not A-005, A-0081 is not A-008). C17L is 1 when
# the id led the entry. awk reads the text as text: nothing is split but at the list's commas, nothing expanded. (Its
# loop is written `for (; …; )`: the shell-text reader of prd-court-no-subshell-in-loops reads a `while` as the shell's.)
CITE17='function cites17(e, W,    t, lc, a, b, f, n) {
  split("", W); n = 0; C17L = 0
  if (match(e, /^A-[0-9]+/)) { W[++n] = substr(e, 1, RLENGTH); C17L = 1; return n }
  t = e; lc = ""
  for (; match(t, /A-[0-9]+/); ) { a = substr(t, RSTART, RLENGTH); b = (RSTART > 1) ? substr(t, RSTART - 1, 1) : lc
    f = substr(t, RSTART + RLENGTH, 1); lc = substr(a, length(a), 1); t = substr(t, RSTART + RLENGTH)
    if (b ~ /[A-Za-z0-9_-]/ || f ~ /[A-Za-z0-9_]/) continue
    W[++n] = a }
  return n }
'
if [ "$MODE" = arms ]; then
  # each row of the items (I), answers (A) and findings (F) blocks, as blk reads them, with its append's position:
  # 0 above `## Appends`, then 1, 2, … at each `### ` heading below it
  # and, for an item row, the answers its `source:` cites (cites17 over each comma entry, as join 17 reads the label:
  # the first field after the positional ones that opens `source:`), comma-joined
  TAGGED=$(LC_ALL=C awk -v npos="$NPOS" "$CITE17"'
    inb != "" { if ($0 == "```") { inb = ""; next }
      if ($0 ~ /^```/ || $0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) next
      cs = ""
      if (inb == "I") { n = split($0, F, "|")
        for (i = npos + 1; i <= n; i++) { x = F[i]; gsub(/^[ \t]+|[ \t]+$/, "", x); k = index(x, ":")
          if (k == 0 || substr(x, 1, k - 1) != "source") continue
          x = substr(x, k + 1); gsub(/^[ \t]+|[ \t]+$/, "", x); m = split(x, E, ",")
          for (j = 1; j <= m; j++) { e = E[j]; gsub(/^[ \t]+|[ \t]+$/, "", e); if (e == "") continue
            c = cites17(e, W); for (q = 1; q <= c; q++) cs = cs (cs == "" ? "" : ",") W[q] }
          break } }
      print inb "\t" pos "\t" cs "\t" $0; next }
    oth { if ($0 ~ /^```/) oth = 0; next }
    $0 == "```vid-prd" { inb = "I"; next }
    $0 == "```vid-prd-answers" { inb = "A"; next }
    $0 == "```vid-prd-findings" { inb = "F"; next }
    /^```/ { oth = 1; next }
    /^## / { app = ($0 ~ /^## Appends[[:space:]]*$/) ? 1 : (app ? 2 : 0); next }
    app == 1 && /^### / { pos++ }' "$PRD")
  RN=0; CANDS=''; RULES=''
  for l in $TAGGED; do
    tg=${l%%"$TB"*}; l=${l#*"$TB"}; ps=${l%%"$TB"*}; l=${l#*"$TB"}; cs=${l%%"$TB"*}; r=${l#*"$TB"}
    case $tg in
    A) field "$r" 1; _amid "$FV"; _key "$FV"; [ -z "$KV" ] || eval "_WA_$KV=\$r; _WQ_$KV=\$ps" ;;   # the latest row wins
    F) field "$r" 5; case $FV in 'accepted A-'*|'overruled A-'*) ;; *) continue ;; esac
      _first A- "$FV"; ua=$FM; labeled "$r" evidence
      case $LV in 'arm '[0-9]*) ;; *) continue ;; esac
      _t=${LV#'arm '}; un=${_t%%[!0-9]*}
      field "$r" 4; _list "$FV"
      for t in $LS; do RULES=$RULES$NL$t$TB$un$TB$ua; done ;;
    I) RN=$((RN + 1)); field "$r" 1; id=$FV; bid=$id
      case $id in *AMENDED) _amid "$id"; bid=$FV ;; esac
      _key "$bid"; k=$KV; [ -n "$k" ] || continue   # an id beyond letters, digits, _ and -: join 1 and 12 judge it
      labeled "$r" fail-if; arms_of "$LV"; CN=''; HL=''
      for a in $ARMS; do normws "$a"; CN=$CN$NL$NW; HL=$HL$NL$RN$TB$NW; done
      eval "_WE_$k=\$r; pred=\${_WP_$k-}; _WP_$k=\$r; _WH_$k=\${_WH_$k-}\$HL"
      case $id in *AMENDED) ;; *) continue ;; esac
      [ -n "$pred" ] || continue
      labeled "$pred" fail-if; [ -n "$LV" ] || continue; arms_of "$LV"; PARMS=$ARMS; NP=$NARMS
      labeled "$r" arms; _list "$LV"
      for e in $LS; do
        _words "$e"; ord=$W1; disp=$W2
        case $disp in retained|strengthened) ;; *) continue ;; esac
        case $ord in ''|*[!0-9]*) continue ;; esac
        [ "$ord" -ge 1 ] && [ "$ord" -le "$NP" ] || continue   # join 14 judges the ordinals
        _nth "$PARMS" "$ord"; normws "$NTH"; [ -n "$NW" ] || continue
        _in "$CN" "$NW" && continue
        CANDS=$CANDS$NL$RN$TB$ps$TB$k$TB$bid$TB$ord$TB$disp$TB$NW$TB$cs
      done ;;
    esac
  done
  for c in $CANDS; do
    crn=${c%%"$TB"*}; c=${c#*"$TB"}; cps=${c%%"$TB"*}; c=${c#*"$TB"}; k=${c%%"$TB"*}; c=${c#*"$TB"}
    bid=${c%%"$TB"*}; c=${c#*"$TB"}; ord=${c%%"$TB"*}; c=${c#*"$TB"}; disp=${c%%"$TB"*}; c=${c#*"$TB"}
    oa=${c%%"$TB"*}; cs=${c#*"$TB"}
    shut=no; eval "H=\${_WH_$k-}"
    for h in $H; do [ "${h%%"$TB"*}" -gt "$crn" ] && [ "${h#*"$TB"}" = "$oa" ] && { shut=yes; break; }; done   # restored
    if [ "$shut" = no ]; then
      # the answers the amending row's source: cites, as join 17 reads them (cites17, in the tagging pass): one a line
      SRCL=''; _s=$cs; while [ -n "$_s" ]; do SRCL=$SRCL$NL${_s%%,*}; case $_s in *,*) _s=${_s#*,} ;; *) _s='' ;; esac; done
      for u in $RULES; do   # ruled
        ut=${u%%"$TB"*}; u=${u#*"$TB"}; un=${u%%"$TB"*}; ua=${u#*"$TB"}
        [ "$ut" = "$bid" ] && [ "$un" = "$ord" ] || continue
        _in "$SRCL" "$ua" && continue
        _key "$ua"; [ -n "$KV" ] || continue
        eval "ar=\${_WA_$KV-}; ap=\${_WQ_$KV-}"
        [ -n "$ar" ] || continue
        field "$ar" 2; [ "$FV" = human ] || continue
        labeled "$ar" delegated; [ "$LV" != yes ] || continue
        [ "$ap" -ge "$cps" ] || continue
        shut=yes; break
      done
    fi
    [ "$shut" = no ] || continue
    eval "er=\${_WE_$k}"; labeled "$er" fail-if
    printf '%s arm %s %s | was: %s | now: %s\n' "$bid" "$ord" "$disp" "$oa" "$LV"
  done
  exit 0
fi

CATALOG='DIM-identity DIM-consent DIM-lifecycle DIM-operations DIM-feedback-intake DIM-trust-states DIM-authorization DIM-notifications DIM-data-integrity DIM-nfr-security DIM-nfr-privacy DIM-nfr-availability DIM-nfr-accessibility DIM-nfr-operability DIM-proof-thresholds DIM-instrumentation DIM-core-loop-continuity DIM-seo-technical DIM-i18n-locale'
DEMANDT='functional nfr ux_flow data_entity'
# OQ carriers: open (`VID-QUESTION: (OQ-n) …`, counted by coverage.sh) or
# resolved (`RESOLVED: (OQ-n) A-NNN — …`, the one line class the base may
# rewrite). References resolve against both; only open carriers count, and
# a pending item may not point at a resolved one.
# 0.26.10.29.3 (R6): both read once, here; an OQ- id of digits is looked up in the lists, anything else as before.
OQOPENL=''; for _l in $(grep -o 'VID-QUESTION: (OQ-[0-9]*)' "$PRD" || true); do _l=${_l#'VID-QUESTION: ('}; OQOPENL=$OQOPENL$NL${_l%')'}; done
OQEXL=''; for _l in $(grep -Eo '^(VID-QUESTION|RESOLVED): \(OQ-[0-9]*\)' "$PRD" || true); do _l=${_l#*'('}; OQEXL=$OQEXL$NL${_l%')'}; done
oq_open() { case $1 in OQ-*[!0-9]*) ;; OQ-*) _in "$OQOPENL" "$1"; return ;; esac; grep -q "VID-QUESTION: ($1)" "$PRD"; }
oq_exists() { case $1 in OQ-*[!0-9]*) ;; OQ-*) _in "$OQEXL" "$1"; return ;; esac; grep -Eq "^(VID-QUESTION|RESOLVED): \($1\)" "$PRD"; }

# --- join 12a: base ids unique, an AMENDED row's id exists earlier ---------
SEEN=''
for r in $ITEMS_RAW; do
  field "$r" 1; id=$FV
  case "$id" in
    *AMENDED) _amid "$id"; bid=$FV
      _in "$SEEN" "$bid" || gap "join 12: '$id' has no earlier row with id $bid — an amendment needs an ancestor."
      id=$bid ;;
    *) _in "$SEEN" "$id" && gap "join 12: duplicate id $id in the base — ids are stable and never reused." ;;
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
  field "$r" 1; aid=$FV
  case "$aid" in
    *AMENDED) _amid "$aid"; bid=$FV
      _in "$ASEEN" "$bid" || gap "join 12 ($aid): no earlier ledger row with id $bid — an amended answer needs an ancestor."
      aid=$bid ;;
    *) _in "$ASEEN" "$aid" && gap "join 12: duplicate answer id $aid in the ledger — restate a changed ruling as $aid AMENDED, latest wins." ;;
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
ANSIDS=''; for r in $AEFF; do field "$r" 1; ANSIDS=$ANSIDS$NL$FV; done; ANSIDS=${ANSIDS#"$NL"}
for r in $EFF; do
  field "$r" 1; id=$FV; nfields "$r"; nf=$NFV
  if [ "$nf" -lt "$NPOS" ]; then gap "join 1 ($id): row under-parses ($nf fields; $NPOS positional fields required)."; continue; fi
  i=$((NPOS + 1)); while [ "$i" -le "$nf" ]; do
    field "$r" "$i"; f=$FV
    case "$f" in fail-if:*|serves:*|authority:*|confirms_via:*|source:*|covers:*|derives:*|spans:*|cross-cutting:*|phase:*|arms:*|feature:*|plain:*) ;;
      *) gap "join 1 ($id): unlabeled field '$f' — a stray | inside a field, or an unknown label." ;; esac
    i=$((i + 1))
  done
  field "$r" 2; type=$FV; field "$r" 3; tier=$FV
  if [ "$NPOS" -eq 5 ]; then field "$r" 4; pri=$FV; field "$r" 5; stmt=$FV; else
    pri='-'; field "$r" 4; stmt=$FV
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
  labeled "$r" phase; ph=$LV
  case "$ph" in ''|pilot|later) ;; *) gap "join 15 ($id): unknown phase '$ph' — pilot | later." ;; esac
  if [ -z "$ph" ] && [ "$GRAMMAR" != legacy ]; then
    case "$type" in functional|nfr|ux_flow|data_entity|invariant) gap "join 15 ($id): no phase: under grammar $GRAMMAR — every demand item and invariant carries pilot | later (membership, not ranking)." ;; esac
  fi
  case "${ph:-pilot}" in pilot) NPILOT=$((NPILOT + 1)) ;; later) NLATER=$((NLATER + 1)) ;; esac
  [ "$type" = non_goal ] && NG=$((NG + 1))
  case "$type" in functional|nfr|ux_flow|data_entity|invariant) [ "$tier" = - ] && gap "join 2 ($id): demand items and invariants always carry a tier." ;; esac
  labeled "$r" fail-if; fi_=$LV; labeled "$r" serves; sv=$LV
  labeled "$r" authority; au=$LV; labeled "$r" confirms_via; cv=$LV
  labeled "$r" source; src=$LV; labeled "$r" covers; cov=$LV; labeled "$r" derives; dv=$LV
  # join 3 under GNUM (0.26.11.1.2, R13): the fail-if in numbered parts, one failure a part
  if [ "$GNUM" = yes ] && [ -n "$fi_" ]; then arms_of "$fi_"
    case $ARMBAD in
      unnumbered) gap "join 3 ($id): the fail-if does not open '(1) ' — under grammar $GRAMMAR it is written in numbered parts, fail-if: (1) <what a wrong product does>; (2) …, one failure a part." ;;
      skip) gap "join 3 ($id): the fail-if's part numbers skip or repeat — the parts run (1), (2), (3) … in order, each after '; '." ;;
      empty) gap "join 3 ($id): the fail-if has an empty part — each numbered part names one failure." ;;
    esac
  fi
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
        kind=${cv%%[/ ]*}; blocks=${cv##*/}
        case "$kind" in owner-decision|measurement|external-dependency) ;; *) gap "join 2 ($id): unknown confirms_via kind '$kind'." ;; esac
        case "$blocks" in yes|no) ;; *) gap "join 2 ($id): confirms_via blocks must be yes|no, got '$blocks'." ;; esac
        [ "$blocks" = yes ] && NBLOCK=$((NBLOCK + 1))
        [ "$au" = provisional ] && [ "$kind" = owner-decision ] && NODPROV=$((NODPROV + 1))
        if [ "$au" = pending ]; then
          _first OQ- "$cv"; oq=$FM
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
  labeled "$r" cross-cutting
  if [ "$LF" = yes ]; then
    [ -n "$LV" ] || gap "join 2 ($id): cross-cutting: names no surface — a marker nothing reads is decoration."
  fi
  if [ -n "$cov" ]; then
    if [ "$au" = pending ]; then gap "join 6 ($id): a pending item claims covers — an item awaiting a decision cannot also be decided."
    else _list "$cov"; for c in $LS; do
      COVERS="$COVERS
$id $type $c"; done; fi
  fi
  _list "$src"
  for s in $LS; do
    case $s in A-*[!0-9]*) continue ;; A-*) ;; *) continue ;; esac   # grep '^A-[0-9]*$'
    _in "$ANSIDS" "$s" || gap "join 8 ($id): source cites $s but no such ledger row exists."
  done
  labeled "$r" spans; _list "$LV"
  for s in $LS; do
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
  _in "$IDS" "$ref" || gap "join 12 ($sid): spans cites $ref, which is no item in the effective set — an interaction falsifier must name the items it guards."
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
# arms_of, _depth and _arm_push are defined above, beside the field helpers (0.26.10.29.4, phase 3 R4: --arms reads
# with them before any join runs).
# The rows read so far, by id (AMENDED or not), the latest kept; the effective answers by id, the first kept. An id
# beyond letters, digits, _ and - is looked up by the old grep.
_rstore() { case $1 in *'|'*) ;; *) return 0 ;; esac
  field "$1" 1; case $FV in *["$WS"]AMENDED) _amid "$FV" ;; esac
  _key "$FV"; [ -z "$KV" ] || eval "_R_$KV=\$1"; return 0; }
_prior() { # $1 an id, $2 this row's number → PV: the latest row before it with that id
  _key "$1"; if [ -n "$KV" ]; then eval "PV=\${_R_$KV-}"; return 0; fi
  PV=$(printf '%s\n' "$ITEMS_RAW" | head -n $(($2 - 1)) | LC_ALL=C grep -E "^[[:space:]]*$1([[:space:]]+AMENDED)?[[:space:]]*\|" | tail -n 1 || true); return 0; }
for r in $AEFF; do field "$r" 1; _key "$FV"; [ -z "$KV" ] || eval "[ -n \"\${_A_$KV+x}\" ] || _A_$KV=\$r"; done
_arow() { # $1 an answer id → PV: its effective row
  _key "$1"; if [ -n "$KV" ]; then eval "PV=\${_A_$KV-}"; return 0; fi
  PV=$(printf '%s\n' "$AEFF" | LC_ALL=C grep -E "^[[:space:]]*$1[[:space:]]*\|" | head -n 1 || true); return 0; }
_settles_has() { # $1 an answer row, $2 an id: its settles: names the id
  labeled "$1" settles; _key "$2"
  if [ -n "$KV" ]; then _list "$LV"; _in "$LS" "$2"; return; fi
  printf '%s\n' "$LV" | tr ',' '\n' | LC_ALL=C sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -qx "$2"; }
ARMLOSING=0; ARMCHANGED=0; RN=0; PREVR=''; DRAFTW=''
for r in $ITEMS_RAW; do
  [ "$RN" -eq 0 ] || _rstore "$PREVR"
  RN=$((RN + 1)); PREVR=$r
  field "$r" 1; id=$FV
  case "$id" in *AMENDED) ;; *) continue ;; esac
  _amid "$id"; bid=$FV
  _prior "$bid" "$RN"; pred=$PV
  [ -n "$pred" ] || continue                                   # join 12 names the missing ancestor
  labeled "$pred" fail-if; pfi=$LV; [ -n "$pfi" ] || continue  # a frame row has no arms
  arms_of "$pfi"; PARMS=$ARMS; NP=$NARMS
  labeled "$r" fail-if; cfi=$LV; arms_of "$cfi"; CARMS=$ARMS; NC=$NARMS
  labeled "$r" arms; ac=$LV
  if [ -z "$ac" ]; then
    if [ "$GRAMMAR" != legacy ]; then
      gap "join 14 ($id): no arms: — an amendment accounts for every arm of the row it supersedes ($NP arm(s); retained · strengthened · moved <id> · withdrawn <A-NNN>)."
    else
      changed=0; normws "$cfi"; cn=$NW
      for a in $PARMS; do case "$cn" in *"$a"*) ;; *) changed=1 ;; esac; done
      if [ "$NC" -lt "$NP" ]; then note "join 14 ($id): arm-losing — $NP arm(s) before, $NC after, no arms: accounting (pre-0.9.1 grammar, reported)"; ARMLOSING=$((ARMLOSING + 1))
      elif [ "$changed" -eq 1 ]; then note "join 14 ($id): arm-changed — $NP arm(s) before and after, an arm's text no longer found, no arms: accounting (pre-0.9.1 grammar, reported)"; ARMCHANGED=$((ARMCHANGED + 1)); fi
    fi
    continue
  fi
  _nraw "$ac"; NE=$NRAW
  [ "$NE" -eq "$NP" ] || strict "join 14 ($id): arms: carries $NE entr(y/ies) for a predecessor with $NP arm(s) — one entry per arm, by ordinal."
  k=0
  _list "$ac"
  for e in $LS; do
    k=$((k + 1))
    _words "$e"; ord=$W1; disp=$W2; ref=$W3
    case "$ord" in ''|*[!0-9]*) strict "join 14 ($id): arms: entry '$e' has no ordinal."; continue ;; esac
    if [ "$ord" -lt 1 ] || [ "$ord" -gt "$NP" ] || [ "$ord" -ne "$k" ]; then strict "join 14 ($id): arms: entry '$e' is out of order — ordinals run 1..$NP in the predecessor's order."; continue; fi
    _nth "$PARMS" "$ord"; arm=$NTH
    case "$disp" in
      retained|strengthened) ;;
      moved)
        _prior "$ref" "$RN"; tgt=$PV
        if [ -z "$tgt" ]; then strict "join 14 ($id): arm $ord moved to $ref, which has no row before this one — the receiving revision precedes the move."
        else labeled "$tgt" fail-if; normws "$LV"; tn=$NW; case "$tn" in *"$arm"*) ;; *) strict "join 14 ($id): arm $ord moved to $ref, but $ref's revision before this row does not carry it (\"$arm\")." ;; esac; fi ;;
      withdrawn)
        _arow "$ref"; arow=$PV
        if [ -z "$arow" ]; then strict "join 14 ($id): arm $ord withdrawn under $ref, which is no effective answer."
        else _settles_has "$arow" "$bid" || strict "join 14 ($id): arm $ord withdrawn under $ref, whose settles: does not name $bid."; fi
        # 0.26.10.29.3 (R2): a ViD draft never takes a failure clause away on its own — the owner is asked at the pause
        FV=''; LV=''; if [ -n "$arow" ]; then labeled "$arow" delegated; field "$arow" 2; fi   # FV its tier, LV its delegated:
        if [ "$FV" = model_proposed ]; then
          if [ "$PAUSE" = yes ]; then DRAFTW="$DRAFTW
  arm $ord of $bid withdrawn under ViD's draft $ref"
          else strict "join 14 ($id): arm $ord withdrawn under $ref, ViD's draft (model_proposed) — a draft never takes a failure clause away on its own: ask the owner at the pause (--pause lists it), restate the answer human on their yes, or keep the arm."; fi
        # and so with an answer given under the owner's delegation (its effective row carries delegated: yes), until it is confirmed
        elif [ "$LV" = yes ]; then
          if [ "$PAUSE" = yes ]; then DRAFTW="$DRAFTW
  arm $ord of $bid withdrawn under $ref, a delegated answer not yet confirmed"
          else strict "join 14 ($id): arm $ord withdrawn under $ref, a delegated answer not yet confirmed (its row carries delegated: yes) — an answer given under a delegation never takes a failure clause away: ask the owner at the pause (--pause lists it), restate the answer human without the field on their yes, or keep the arm."; fi
        fi ;;
      *) strict "join 14 ($id): arms: disposition '$disp' is not retained · strengthened · moved <id> · withdrawn <A-NNN>." ;;
    esac
  done
done

# --- contract: join 9 ------------------------------------------------------
# 0.26.10.29.3 (R6): a covers line ending ` <dim>[/<facet>]`, and a contract row by its dimension (the first kept),
# read without a process; a dimension or facet beyond letters, digits, _, - and / takes the old grep.
_covend() { case $1 in *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_/-]*|'') printf '%s\n' "$COVERS" | grep -q " $1\$"; return ;; esac
  case "$COVERS$NL" in *" $1$NL"*) return 0 ;; esac; return 1; }
for r in $CONTRACT; do case $r in *'|'*) ;; *) continue ;; esac; field "$r" 1; _key "$FV"; [ -z "$KV" ] || eval "[ -n \"\${_C_$KV+x}\" ] || _C_$KV=\$r"; done
_crow() { _key "$1"; if [ -n "$KV" ]; then eval "PV=\${_C_$KV-}"; return 0; fi
  PV=$(printf '%s\n' "$CONTRACT" | LC_ALL=C grep "^[[:space:]]*$1[[:space:]]*|" | head -n 1); return 0; }
NDIMS=0; DIMIDS=''; NCOV=0; NNA=0; NMECHD=0; NNFRD=0; NPROOFD=0; NFACETS=0
for r in $CONTRACT; do
  field "$r" 1; dim=$FV; nfields "$r"; nf=$NFV
  if [ "$nf" -lt 4 ]; then gap "join 1 ($dim): contract row under-parses ($nf fields; 4 positional fields required)."; continue; fi
  NDIMS=$((NDIMS + 1)); DIMIDS="$DIMIDS
$dim"
  field "$r" 3; cat_=$FV; field "$r" 4; dem=$FV
  case "$cat_" in mechanism) NMECHD=$((NMECHD + 1)) ;; nfr) NNFRD=$((NNFRD + 1)) ;; proof) NPROOFD=$((NPROOFD + 1)) ;;
    *) gap "join 9 ($dim): unknown category '$cat_'." ;; esac
  case "$dem" in required|case-by-case) ;; *) gap "join 9 ($dim): unknown demand '$dem'." ;; esac
  case " $CATALOG " in *" $dim "*) ;; *) labeled "$r" prompt; [ -n "$LV" ] || gap "join 9 ($dim): a panel-added dimension with no prompt: — a dimension that cannot name its defect class does not enter." ;; esac
  labeled "$r" facets; _list "$LV"; facets=$LS
  [ -n "$facets" ] && NFACETS=$((NFACETS + LN))
  [ "$HASITEMS" = yes ] || continue   # coverage/status closure waits for items (pause-1 artifact).
  labeled "$r" status; st=$LV
  case "$st" in
    'na owner'*) NNA=$((NNA + 1)) ;;
    na*) gap "join 9 ($dim): status '$st' — an NA is legal only with an owner attribution; you propose, you never disposition." ;;
    covered)
      NCOV=$((NCOV + 1))
      if [ -n "$facets" ]; then
        for f in $facets; do
          _covend "$dim/$f" || gap "join 9 ($dim): facet '$f' is cited by no item and the dimension carries no owner NA — one citation must not collapse a compound dimension's facets."
        done
      else
        _covend "$dim" || gap "join 9 ($dim): written status 'covered' but no item cites it and it carries no owner NA."
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
  if ! _in "$DIMIDS" "$dim"; then gap "join 9 ($cid): covers cites $dim, which is not in the ratified contract — a ghost dimension."; continue; fi
  _crow "$dim"; drow=$PV
  labeled "$drow" facets; _list "$LV"; dfacets=$LS
  if [ -n "$facet" ]; then
    _in "$dfacets" "$facet" || gap "join 9 ($cid): covers cites $dim/$facet but '$facet' is not a declared facet — a ghost facet."
  elif [ -n "$dfacets" ]; then gap "join 9 ($cid): $dim declares facets — citations must be facet-qualified."; fi
  labeled "$drow" covered_by; _list "$LV"; elig=$LS
  _in "$elig" "$ctype" || gap "join 9 ($cid): type '$ctype' is not in $dim's covered_by list — an ineligible citation is a named GAP, never a silent drop."
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
    # 0.26.10.29.3 (R9, F53): the seed file is read by exact text too — the same test, the same refusal
    if [ -f "$_EOL" ]; then sh "$_EOL" file "${SEEDPATH#./}" || exit 1; fi
    got=$(sha256 "$SEEDPATH")
    [ "$got" = "$SEEDHASH" ] || gap "join 11: $SEEDFILE's sha256 ($got) differs from the Seed: line ($SEEDHASH) — the seed is never edited after consolidation."
    SEEDFLAT=$(tr '\n' ' ' < "$SEEDPATH" | tr -s ' ')
  else
    gap "join 11: the Seed: line points at $SEEDFILE, which does not exist beside the PRD — the seed is the highest authority and must be present."
    SEEDFLAT=''
  fi
else
  SEEDFLAT=$(sed -n '/^## Seed$/,/^## /p' "$PRD" | tr '\n' ' ' | tr -s ' ')
  # 0.26.10.29.3 (R9, F44): the section ends at the next `## ` line. When that line is none of the PRD's own section
  # headings it is the seed's own: an excerpt missing from the section but found before the PRD's own next section is the
  # seed's text cut short — one advice gap, never one gap per excerpt
  SEEDEND=$(sed -n '/^## Seed$/,/^## /p' "$PRD" | sed '1d' | grep '^## ' | head -n 1 || true)
  SEEDOWN='Sources|Thesis|Actors and journeys|Mechanisms|Content contract|Criticality tiers|Items|Answer ledger|Open decisions|Findings|Ratifications|Appends'
  SEEDALL=''
  if [ -n "$SEEDEND" ] && ! printf '%s\n' "$SEEDEND" | grep -qE "^## ($SEEDOWN)\$"; then
    SEEDALL=$(awk -v own="^## ($SEEDOWN)\$" '/^## Seed$/ { s = 1; next } s && $0 ~ own { exit } s' "$PRD" | tr '\n' ' ' | tr -s ' ')
  fi
fi
SEEDEARLY=0
MECHGOALS=''; for r in $MECHS; do field "$r" 2; MECHGOALS=$MECHGOALS$NL$FV; done; MECHGOALS=${MECHGOALS#"$NL"}
for g in $(sed -n '/^### MVP focus$/,/^###/p' "$PRD" | grep -oE '^- *G[0-9]+' | grep -oE 'G[0-9]+' || true); do
  _in "$MECHGOALS" "$g" || gap "join 11: goal $g has no mechanisms row — a goal with no mechanism and no open question is a wish and will be refused."
done
for r in $MECHS; do
  field "$r" 1; mid=$FV; field "$r" 4; gr=$FV
  case "$gr" in
    'stated: seed "'*'"')
      ex=${gr#'stated: seed "'}; ex=${ex%'"'}; _sq "$ex"; ex=$SQ
      case "$SEEDFLAT" in *"$ex"*) ;; *) case "${SEEDALL:-}" in *"$ex"*) SEEDEARLY=$((SEEDEARLY + 1)) ;; *) gap "join 11 ($mid): seed excerpt \"$ex\" does not appear verbatim in the Seed section — the join is checked mechanically." ;; esac ;; esac ;;
    'stated: answer A-'*)
      _all A- "$gr"; aref=$FA
      _inany "$ANSIDS" "$aref" || gap "join 11 ($mid): stated: answer $aref but no such ledger row exists." ;;
    'open: OQ-'*)
      _all OQ- "$gr"; oref=$FA
      oq_exists "$oref" || gap "join 11 ($mid): open: $oref but no such carrier exists under Open decisions." ;;
    *) gap "join 2 ($mid): unknown grounding '$gr' — stated: seed \"…\" | stated: answer A-NNN | open: OQ-n." ;;
  esac
done

[ "$SEEDEARLY" -eq 0 ] || gap "join 11: the ## Seed section ends at the seed's own heading '$SEEDEND', so $SEEDEARLY seed excerpt(s) after it are not read as seed. A seed with its own '## ' headings goes to SEED.md beside the PRD, verbatim, with the header line 'Seed: SEED.md (sha256 <its hash>)' from its first commit (the import door), which this court reads."

# --- 0.26.10.29.3 (R1): with --before, the effective mechanism rows match the pre-consolidation file's -------
if [ -n "$BEFORE" ]; then
  MEFFAWK='function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    NF { id = trim($1); sub(/[ \t]+AMENDED$/, "", id); out = id; for (i = 2; i <= NF; i++) out = out " | " trim($i)
      row[id] = out; if (!(id in seen)) { order[++n] = id; seen[id] = 1 } }
    END { for (i = 1; i <= n; i++) print row[order[i]] }'
  BMEFF=$(sed -n '/^```vid-prd-mechanisms$/,/^```$/p' "$BEFORE" | grep -v '^```' | LC_ALL=C grep -v '^[[:space:]]*#' | LC_ALL=C grep -v '^[[:space:]]*$' | awk -F'|' "$MEFFAWK" || true)
  NMEFF=''; [ -z "$MECHS" ] || NMEFF=$(printf '%s\n' "$MECHS" | awk -F'|' "$MEFFAWK")
  # the whole row is compared (a row's text may hold a tab): the first character says which file, the row follows it
  for l in $( { printf '%s\n' "$BMEFF" | awk 'NF { print "B" $0 }'; printf '%s\n' "$NMEFF" | awk 'NF { print "N" $0 }'; } | awk '
      { w = substr($0, 1, 1); r = substr($0, 2); id = r; sub(/[ \t]*\|.*/, "", id); if (!(id in s)) { o[++n] = id; s[id] = 1 } if (w == "B") B[id] = r; else N[id] = r }
      END { for (k = 1; k <= n; k++) { id = o[k]
        if (!(id in N)) print id " is in the pre-consolidation file'"'"'s effective mechanisms and missing here"
        else if (!(id in B)) print id " is here and in no effective mechanism row of the pre-consolidation file"
        else if (B[id] != N[id]) print id "'"'"'s effective row differs from the pre-consolidation file'"'"'s (\"" B[id] "\")" } }'); do
    gap "join 11 (--before $BEFORE): $l — consolidation keeps every mechanism as amended."
  done
fi

# --- answers: joins 7 and 8 ------------------------------------------------
NHUM=0; NMOD=0
MECHIDS=''; for r in $MECHS; do field "$r" 1; MECHIDS=$MECHIDS$NL$FV; done; MECHIDS=${MECHIDS#"$NL"}
for r in $AEFF; do
  field "$r" 1; aid=$FV; field "$r" 2; at=$FV
  case "$at" in human) NHUM=$((NHUM + 1)) ;; model_proposed) NMOD=$((NMOD + 1)) ;;
    *) gap "join 2 ($aid): unknown answer tier '$at'." ;; esac
  nfields "$r"; nf=$NFV; i=4
  while [ "$i" -le "$nf" ]; do
    field "$r" "$i"; f=$FV
    case "$f" in Q:*|A:*|settles:*|unchanged:*|importance:*|shown:*|delegated:*) ;;
      *) strict "join 1 ($aid): unlabeled field '$f' on an answer row — a stray | inside a field, or an unknown label (Q:, A:, settles:, unchanged:, importance:, shown:, delegated:)." ;; esac
    i=$((i + 1))
  done
  labeled "$r" settles; st=$LV
  [ -n "$st" ] || { gap "join 8 ($aid): a live answer that traces to nothing — settles: is empty."; continue; }
  _list "$st"
  for ref in $LS; do
    if _in "$PENDING" "$ref" || _in "$PENDOQ" "$ref"; then
      gap "join 7 ($aid): settles $ref while it is still pending — the record can never hold a pending item whose answer already exists."
    elif [ "$ref" = thesis ] || [ "$ref" = contract ] || _in "$IDS" "$ref" || _in "$MECHIDS" "$ref" \
      || _in "$DIMIDS" "$ref" || { case "$ref" in OQ-*) oq_exists "$ref" ;; *) false ;; esac; }; then :
    else gap "join 8 ($aid): settles '$ref' resolves to no item, mechanism, dimension, OQ carrier, the thesis, or the contract."; fi
  done
  # unchanged: (v0.9.1 3.2, R14-i) — bare item ids the ruling examined and left
  # standing; the delta review's propagation ledger. Every id must exist.
  # 0.26.10.29.3 (phase 2 R3): an answer id or a mechanism id too, since propagation now reaches every kind of row
  labeled "$r" unchanged; _list "$LV"
  for ref in $LS; do
    _in "$IDS" "$ref" || _in "$ANSIDS" "$ref" || _in "$MECHIDS" "$ref" \
      || gap "join 8 ($aid): unchanged: names '$ref', which is no item, answer or mechanism in the effective set — a ruling leaves standing only what exists."
  done
done

# --- findings: join 13 — the sitting record, dispositions resolving --------
# 0.26.10.29.3 (phase 2 R3, R6): a target may name an answer that exists, or another document by form only —
# `<doc>` or `<doc>:<id>`, <doc> one the final pass reads (or STAGES.md), <id> letters, digits, `.`, `_` and `-`. The
# id is never looked up: those files change under develop, and consolidation runs this court where they are absent.
_doctarget() {
  _d=${1%%:*}
  case $1 in *:*) case ${1#*:} in ''|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*) return 1 ;; esac ;; esac
  case $_d in
    DESIGN-BRIEF.md|ARCHITECTURE.md|DECISIONS.md|BASELINE.md|INVENTORY.md|GRADING-CHECKLIST.md|STAGES.md) return 0 ;;
    design/*) case "/$_d/" in */../*|*/./*|*["$WS"]*) return 1 ;; esac; return 0 ;;
  esac
  return 1; }
# The ratification sha covers what the owner was shown, not only what they
# decided. Presence-gated: a run whose sittings were clean carries no block.
FINDINGS=$(blk vid-prd-findings)
NFIND=0; FSEEN=''
for r in $FINDINGS; do
  field "$r" 1; fid=$FV; nfields "$r"; nf=$NFV
  NFIND=$((NFIND + 1))
  if [ "$nf" -lt 5 ]; then gap "join 13 ($fid): findings row under-parses ($nf fields; 5 positional fields required)."; continue; fi
  i=6; while [ "$i" -le "$nf" ]; do
    field "$r" "$i"; f=$FV
    case "$f" in evidence:*) ;; *) gap "join 13 ($fid): unlabeled field '$f' — a stray | inside a field, or an unknown label." ;; esac
    i=$((i + 1))
  done
  _in "$FSEEN" "$fid" && gap "join 13: duplicate finding id $fid."
  FSEEN="$FSEEN
$fid"
  field "$r" 2; pass=$FV; field "$r" 3; sev=$FV; field "$r" 4; tgt=$FV; field "$r" 5; disp=$FV
  # 0.26.10.29.3 (phase 2 R6): `final`, the final pass's rows; 0.26.10.29.4 (phase 3 R1): `strength`, the strength pass's
  case "$pass" in red-team|audit|review|lens|final|strength) ;; *) gap "join 13 ($fid): unknown pass '$pass' — red-team | audit | review | lens | final | strength." ;; esac
  case "$sev" in blocking|advisory) ;; *) gap "join 13 ($fid): unknown severity '$sev'." ;; esac
  case "$disp" in
    repaired) ;;
    'overruled A-'*|'accepted A-'*)
      _first A- "$disp"; aref=$FM
      _in "$ANSIDS" "$aref" || gap "join 13 ($fid): disposition cites $aref but no such ledger row exists." ;;
    'routed OQ-'*)
      _first OQ- "$disp"; oref=$FM
      oq_exists "$oref" || gap "join 13 ($fid): routed to $oref but no such carrier exists under Open decisions." ;;
    noted)
      [ "$sev" = blocking ] && gap "join 13 ($fid): a blocking finding merely noted — a lock that can be taken while the red team still objects is a signature on an unread document." ;;
    '') gap "join 13 ($fid): no disposition — a blocking finding must carry a resolving disposition before its pause commits." ;;
    *) gap "join 13 ($fid): unknown disposition '$disp' — repaired | overruled A-NNN | accepted A-NNN | routed OQ-n | noted." ;;
  esac
  _list "$tgt"
  for t in $LS; do
    if [ "$t" = thesis ] || [ "$t" = seed ] || _in "$IDS" "$t" \
      || _in "$MECHIDS" "$t" || _in "$DIMIDS" "$t" || _in "$ANSIDS" "$t" || _doctarget "$t"; then :
    else gap "join 13 ($fid): target '$t' resolves to no item, mechanism, dimension, answer, the thesis, or the seed, and names no other document by form (<doc> or <doc>:<id>; <doc> one of DESIGN-BRIEF.md, a path under design/, ARCHITECTURE.md, DECISIONS.md, BASELINE.md, INVENTORY.md, GRADING-CHECKLIST.md, STAGES.md) — a finding with no target cannot be repaired or verified."; fi
  done
done

# 0.26.10.29.3 (phase 2 R2): every `review:` line (at a line's start, outside any fence) has one of the closed forms —
#   review: <delta|whole|final>, round <r>, <n> findings          this phase's line, counted
#     … , read: <files>          the final pass's read list: required on a final line, refused on any other
#     … , 0 findings, see <heading>   a whole or final review's repair append: its rows are under that `### ` heading
#                                     of `## Findings`, so it counts 0 and carries no read list
#   review: <delta|whole>, <n> findings                           phase 1's line: round 1, read for its form only
# and a line carrying `round` counts the rows of every vid-prd-findings block between its own heading and the next
# (every round and both readers, merged; comment and blank lines are not rows, as blk reads them). Phase 1's lines never
# had the count rule and the append-only record cannot mend one, so their count is not judged; nothing here reads git,
# so a ratified PRD adopted into a new project reads as it did. One awk pass, whatever the PRD's size.
# A fence opened by a run of n backticks closes only on a line that is a run of at least n backticks and nothing else.
RVGAPS=$(LC_ALL=C awk '
  function judge(   i) { for (i = 1; i <= nl; i++) if (cnt[i] != nf) print "join 13: \047" ln[i] "\047 under \047" head "\047 counts " cnt[i] " finding(s), but the vid-prd-findings block(s) there hold " nf " row(s) — <n> is the rows under the line'"'"'s own heading, every round and reader merged."; nl = 0; nf = 0 }
  function bad(why) { print "join 13: review: line \047" $0 "\047 under \047" head "\047 " why }
  BEGIN { head = "(the top of the file)"; fence = "" }
  fence != "" { if ($0 ~ /^```+$/ && length($0) >= fl) fence = ""; else if (fence == "f" && $0 !~ /^[[:space:]]*(#|$)/) nf++; next }
  /^```/ { match($0, /^`+/); fl = RLENGTH; fence = ($0 == "```vid-prd-findings") ? "f" : "o"; next }
  /^#+ / { judge(); head = $0; if ($0 ~ /^## /) inf = ($0 == "## Findings"); else if (inf && $0 ~ /^### /) { h = substr($0, 5); sub(/[[:space:]]+$/, "", h); FH[h] = 1 }; next }
  !/^review:/ { next }
  { l = $0; sub(/[[:space:]]+$/, "", l) }
  l ~ /^review: (delta|whole), [0-9]+ findings?$/ { next }
  l !~ /^review: [a-z]+, / { bad("is not of a known form — review: delta | whole | final, round <r>, <n> findings."); next }
  { m = l; sub(/^review: /, "", m); sub(/,.*/, "", m) }
  m != "delta" && m != "whole" && m != "final" { bad("names the unknown mode \047" m "\047 — delta | whole | final."); next }
  l !~ /^review: [a-z]+, round [0-9]+, [0-9]+ findings?(, read: [^[:space:],][^,]*|, see [^[:space:]].*)?$/ {
    bad("is not of a known form — review: " m ", round <r>, <n> findings, then , read: <files> on a final review or , see <heading> on a whole or final repair append; phase 1'"'"'s review: delta | whole, <n> findings."); next }
  { t = l; sub(/^review: [a-z]+, round /, "", t); r = t + 0; sub(/^[0-9]+, /, "", t); n = t + 0; tail = t; sub(/^[0-9]+ findings?/, "", tail) }
  r < 1 { bad("names round " r " — rounds count from 1."); next }
  tail ~ /^, see / {
    s = substr(tail, 7)
    if (m == "delta") { bad("is a see line on a delta review — a delta review'"'"'s rows are in its own section."); next }
    if (n != 0) { bad("counts " n " finding(s) on a see line — a repair append holds no rows; they are under its review'"'"'s heading."); next }
    see[++ns] = s; seeline[ns] = $0; seehead[ns] = head }
  tail ~ /^, read: / && m != "final" { bad("carries read: on a " m " review — only a final review lists what it read."); next }
  tail == "" && m == "final" { bad("is a final review with no read: list — review: final, round <r>, <n> findings, read: <files>."); next }
  { ln[++nl] = $0; cnt[nl] = n }
  END { judge(); for (i = 1; i <= ns; i++) if (!(see[i] in FH)) print "join 13: review: line \047" seeline[i] "\047 under \047" seehead[i] "\047 names no ### heading under ## Findings — see <the heading'"'"'s text>." }' "$PRD")
for l in $RVGAPS; do gap "$l"; done

# --- resolved carriers: the answer a RESOLVED line cites must exist --------
for l in $(grep -E '^RESOLVED: \(OQ-[0-9]+\)' "$PRD" || true); do
  _first OQ- "$l"; oref=$FM
  _first A- "$l"; aref=$FM
  if [ -z "$aref" ] || ! _in "$ANSIDS" "$aref"; then
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
  # 0.26.10.29.3 (R6): each text to its own file, one cksum over them all (the sum of a file is the sum of its bytes,
  # as `printf '%s\n' <text> | cksum` gave it), joined back to the ids in order.
  SUMD=$(mktemp -d); trap 'rm -rf "$SUMD"' EXIT
  n=0; SUMF=''
  for l in $ATXT; do n=$((n + 1)); printf '%s\n' "${l#*"$TAB"}" > "$SUMD/$n"; printf '%s\n' "${l%%"$TAB"*}" >> "$SUMD/ids"; SUMF=$SUMF$NL$n; done
  [ "$n" -eq 0 ] || SUMS=$NL$(cd "$SUMD" && cksum $SUMF | awk -v t="$TAB" 'NR == FNR { id[FNR] = $0; next } { print id[FNR] t $1 }' ids -)
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
        npv = vals(pl, PV); split("", SV); fv21 = IL[id, "fail-if"]; if (gnum == "yes") { sub(/^\([0-9]+\) /, "", fv21); gsub(/; \([0-9]+\) /, "; ", fv21) } valset(ISTMT[id] " " fv21, SV)
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
      # 0.26.10.29.4 (phase 3 R4, review): the answers the entry cites, through cites17 (above J094), which --arms runs too
      nc17 = cites17(e, C17)
      if (C17L) {
        a = C17[1]; CA[a] = 1
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
      if (!C17L) for (j17 = 1; j17 <= nc17; j17++) { a = C17[j17]
          if ((a in AT) && AT[a] == "model_proposed" && !(a in CA) && !(a in W17)) { W17[a] = 1; nw17++; wl17 = add(wl17, a) } }
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
  # 0.26.10.29.6 (S6): outside a pause the same list prints as notes, so a missing mark is seen when the answer is
  # written; a note refuses nothing.
  if (G) for (k = 1; k <= NA; k++) {
    a = AID[k]; if (AT[a] != "human" || AL[a, "importance"] == "priority") continue
    why = ""; ns = split(AL[a, "settles"], S2, ",")
    for (i = 1; i <= ns && why == ""; i++) { r = trim(S2[i]); if ((r in IT) && ITIER[r] == "T0") why = "settles T0 " r }
    if (why == "" && (a in T0CITE)) why = "cited by T0 " T0CITE[a]
    for (i = 1; i <= NRQ && why == ""; i++) { q = RORD[i]; if (RDEC[q] == a && (q in T0WAIT)) why = "resolves " q ", which T0 " T0WAIT[q] " routes to" }
    if (why == "") continue
    if (P) gap("importance (" a "): a human answer shaping a must-never-break rule (" why ") carries importance: priority.")
    else note("importance (" a "): a human answer shaping a must-never-break rule (" why ") carries importance: priority — set the mark now; a pause refuses it.")
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
} | LC_ALL=C awk -v g094="$G094" -v g095="$G095" -v g0981="$G0981" -v gnum="$GNUM" -v pause="$PAUSE" -v npos="$NPOS" -v sect="$SECT" -v grammar="$GRAMMAR" "$CITE17$J094") \
  || { echo 'ViD prd: the 0.9.4 pass (joins 16-20) did not run — failing closed.' >&2; exit 1; }
JCOUNTS=$(printf '%s\n' "$JOUT" | sed -n '$p')
JBODY=$(printf '%s\n' "$JOUT" | sed '$d')
[ -z "$JBODY" ] || printf '%s\n' "$JBODY"
# 0.26.10.29.3 (R2): the last section of the pause material — each arm withdrawn under ViD's draft, an owner question
if [ "$PAUSE" = yes ]; then
  echo "owner questions (an arm withdrawn under ViD's draft, or under a delegated answer not yet confirmed — asked here, a gap at commit until the owner's ruling restates the answer human): $(printf '%s' "$DRAFTW" | grep -c . || true)"
  [ -z "$DRAFTW" ] || printf '%s\n' "$DRAFTW" | grep .
fi
IFS=' ' read -r _ JG JN JF JP JS JM JU <<EOF
$JCOUNTS
EOF
GAPS=$((GAPS + JG)); NOTES=$((NOTES + JN))

# --- report (counts, never scores) -----------------------------------------
NITEMS=$(printf '%s\n' "$EFF" | grep -c . || true)
# 0.26.10.29.3 (R4): open-OQs= counts carrier lines — a line that begins `VID-QUESTION: (OQ-` — never a mention inside
# a line (the template's own comment names two as examples); every hand-back that states open questions quotes it
NOQ=$(grep -c '^VID-QUESTION: (OQ-' "$PRD" || true)
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
