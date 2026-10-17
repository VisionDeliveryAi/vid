#!/bin/sh
# Purpose: ViD court — import boundaries, rule source ARCHITECTURE.md's seam
# table (Module = repo path; Public surface leads with backticked import
# specifiers; Dependents = comma-separated module paths, or all/none). Three
# rules: public surface only (never a module's internals), direction, declared
# adjacency. Default reads the staged diff and fails closed; --report scans a
# whole tree and lists violations without failing (retrofit mode, §5.4 —
# "Import court: report-only" in ARCHITECTURE.md keeps the hook in that mode
# until the owner's cutover commit). Presence-gated: inactive when the seam
# table has no parseable Module rows.
# The ledger side (v0.8.1d — behavior-keying as a court): a ledger test file
# (tests/invariants/test*) and every other file under tests/ (dataset and
# fixture generators) may import a seam-table module only when that
# module's Dependents column names tests/invariants (or tests) — the harness
# entry a ledger must boot declares it; internals do not. Harness files
# under tests/invariants/ not named test* (fixtures, helpers) and the
# non-law tier tests/scaffolding/ are exempt. Same mode switch as the rest.
# Usage: sh checks/imports.sh [--report [dir]]
set -eu
IFS='
'

# SCOPE: what to scan (staged diff, or a whole tree with --report).
# FAILMODE: "Import court: enforce" in ARCHITECTURE.md fails closed; the line
# absent or "report-only" = the §5.4 retrofit default — violations are listed,
# never fatal, and the mode is stated so it is never silent.
SCOPE=diff
ROOT=.
if [ "${1:-}" = "--report" ]; then SCOPE=tree; ROOT=${2:-.}; fi
ARCH="$ROOT/ARCHITECTURE.md"
[ -f "$ARCH" ] || { echo "ViD imports: $ARCH missing — failing closed." >&2; exit 1; }
FAILMODE=report
grep -qE '^Import court:[[:space:]]*enforce' "$ARCH" && FAILMODE=enforce
[ "$SCOPE" = tree ] && FAILMODE=report

field() { printf '%s\n' "$1" | cut -d'|' -f"$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/`//g'; }

# Seam rows: "path<TAB>surface-specifiers(space-sep)<TAB>dependents(space-sep)"
TABLE=''
for row in $(grep -E '^\|' "$ARCH" | grep -vE '^\|[[:space:]:-]*\|' || true); do
  mod=$(field "$row" 2)
  case "$mod" in Module|''|\{\{*) continue ;; esac
  case "$mod" in
    */*) ;;
    *.*) mod=$(printf '%s\n' "$mod" | tr '.' '/') ;;   # dotted module labels → repo paths
  esac
  surf=$(printf '%s\n' "$row" | cut -d'|' -f5 | grep -oE '`[^` ]+`' | tr -d '`' | tr '\n' ' ' || true)
  deps=$(field "$row" 6 | tr ',' ' ')
  TABLE="$TABLE$mod	$surf	$deps
"
done
if [ -z "$TABLE" ]; then
  echo 'ViD imports: no parseable Module rows in the seam table — court inactive (retrofit: see templates/ARCHITECTURE.md column contract).'
  exit 0
fi

# All helpers set *_OUT variables — no command substitution in the hot loop.

norm() { # collapse /src/ segments so seam paths match src layouts
  _rest=${1#./}; NORM_OUT=''
  while :; do
    case "$_rest" in
      */src/*) NORM_OUT="$NORM_OUT${_rest%%/src/*}/"; _rest=${_rest#*/src/} ;;
      *) NORM_OUT="$NORM_OUT$_rest"; break ;;
    esac
  done
  NORM_OUT=${NORM_OUT%/src}
}

module_of() { # longest seam-path prefix of a repo path
  norm "$1"; _np=$NORM_OUT; MODULE_OF_OUT=''
  for _t in $TABLE; do
    _m=${_t%%	*}
    case "$_np" in
      "$_m"/*|"$_m") [ ${#_m} -gt ${#MODULE_OF_OUT} ] && MODULE_OF_OUT=$_m ;;
    esac
  done
  :
}

canon() { # resolve ../ and ./ in a slash path
  CANON_OUT=''
  _oldifs=$IFS; IFS=/
  for _seg in $1; do
    case "$_seg" in
      ''|'.') ;;
      '..') CANON_OUT=${CANON_OUT%/*} ;;
      *) CANON_OUT="$CANON_OUT/$_seg" ;;
    esac
  done
  IFS=$_oldifs
  CANON_OUT=${CANON_OUT#/}
}

deps_of() { # dependents field of a module row
  DEPS_OUT=''
  for _t in $TABLE; do
    case "$_t" in "$1	"*) DEPS_OUT=" ${_t##*	} " ;; esac
  done
  :
}

VIOLATIONS=0
LAST_FILE=''; LAST_FROM=''
check_import() { # $1=file $2=specifier
  f=$1; s=$2
  ledger=no
  case "$f" in
    checks/*|design/*|tests/scaffolding/*) return 0 ;;
    tests/invariants/*)
      case "${f##*/}" in test*) ledger=yes ;; *) return 0 ;; esac ;;
    tests/*) ledger=yes ;;
  esac
  if [ "$f" = "$LAST_FILE" ]; then from=$LAST_FROM; else
    module_of "$f"; from=$MODULE_OF_OUT; LAST_FILE=$f; LAST_FROM=$from
  fi
  case "$s" in
    ./*|../*)
      canon "${f%/*}/$s"
      module_of "$CANON_OUT"; to=$MODULE_OF_OUT
      [ -n "$to" ] || return 0
      [ "$to" = "$from" ] && return 0
      echo "ViD imports: $f imports '$s' — relative import reaching into $to; use its public surface specifier." >&2
      VIOLATIONS=$((VIOLATIONS + 1)); return 0 ;;
  esac
  # bare specifier: match against declared surfaces and module paths
  _o=$IFS; IFS=.; set -- $s; IFS=/; sslash="$*"; IFS=$_o
  to=''; entry=no
  for _t in $TABLE; do
    m=${_t%%	*}; _rest=${_t#*	}; surf=${_rest%%	*}
    _o=$IFS; IFS=' '
    for sp in $surf; do
      if [ "$s" = "$sp" ]; then to=$m; entry=yes; break; fi
      case "$s" in "$sp"/*) to=$m; entry=no ;; esac
    done
    IFS=$_o
    [ "$entry" = yes ] && break
    if [ "$s" = "$m" ] || [ "$sslash" = "$m" ]; then to=$m; entry=yes; break; fi
    case "$sslash" in "$m"/*) [ -z "$to" ] && { to=$m; entry=no; } ;; esac
  done
  [ -n "$to" ] || return 0            # external dependency — not ours to police
  [ "$to" = "$from" ] && return 0     # a module's own internals are its own
  if [ "$entry" = no ]; then
    echo "ViD imports: $f imports '$s' — deeper than $to's declared public surface." >&2
    VIOLATIONS=$((VIOLATIONS + 1)); return 0
  fi
  deps_of "$to"
  if [ "$ledger" = yes ]; then
    case "$DEPS_OUT" in
      *' all '*|*' tests/invariants '*|*' tests '*) return 0 ;;
    esac
    echo "ViD imports: $f imports '$s' — a ledger test enters the product only through its public surface; $to does not name tests/invariants among its dependents (declare it for the harness entry only, never for internals)." >&2
    VIOLATIONS=$((VIOLATIONS + 1)); return 0
  fi
  case "$DEPS_OUT" in
    *' all '*) return 0 ;;
    *" $from "*) [ -n "$from" ] && return 0 ;;
  esac
  echo "ViD imports: $f imports '$s' — ${from:-<unmapped file>} is not a declared dependent of $to (ARCHITECTURE.md)." >&2
  VIOLATIONS=$((VIOLATIONS + 1))
}

# One awk pass turns source (or a staged diff) into "file<TAB>specifier" pairs.
AWK_EXTRACT='
function emit(file, line,    s, t) {
  s = ""
  if (match(line, /(from|import|require)[[:space:]]*\(?[[:space:]]*"[^"]+"/)) {
    t = substr(line, RSTART, RLENGTH); sub(/^[^"]*"/, "", t); sub(/"$/, "", t); s = t
  } else if (match(line, /(from|import|require)[[:space:]]*\(?[[:space:]]*'\''[^'\'']+'\''/)) {
    t = substr(line, RSTART, RLENGTH); sub(/^[^'\'']*'\''/, "", t); sub(/'\''$/, "", t); s = t
  } else if (match(line, /^[[:space:]]*(from|import)[[:space:]]+[A-Za-z_][A-Za-z0-9_.]*/)) {
    t = substr(line, RSTART, RLENGTH); sub(/^[[:space:]]*(from|import)[[:space:]]+/, "", t); s = t
  }
  if (s != "") print file "\t" s
}'

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if [ "$SCOPE" = tree ]; then
  (cd "$ROOT" && grep -rnE '^[[:space:]]*(import|export[[:space:]]+.*from|from[[:space:]])|require\(' \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.py' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=dist \
    --exclude-dir=checks --exclude-dir=design . 2>/dev/null || true) \
  | awk "$AWK_EXTRACT"'
    { line = $0; file = line; sub(/:.*/, "", file); sub(/^\.\//, "", file)
      sub(/^[^:]*:[0-9]*:/, "", line); emit(file, line) }' > "$TMP"
else
  git diff --cached -U0 -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.py' 2>/dev/null \
  | awk "$AWK_EXTRACT"'
    /^\+\+\+ b\// { cur = substr($0, 7); next }
    /^\+\+\+/ { cur = ""; next }
    /^\+/ { if (cur != "") emit(cur, substr($0, 2)) }' > "$TMP"
fi

while IFS='	' read -r f spec; do
  [ -n "$f" ] && check_import "$f" "$spec"
done < "$TMP"

if [ "$FAILMODE" = enforce ]; then
  if [ "$VIOLATIONS" -gt 0 ]; then
    echo "ViD imports: rejected — $VIOLATIONS boundary violation(s). A module is entered only through its declared public surface, only by its declared dependents." >&2
    exit 1
  fi
  exit 0
fi
if [ "$SCOPE" = tree ] || [ "$VIOLATIONS" -gt 0 ]; then
  echo "ViD imports (report-only — cutover: 'Import court: enforce' in ARCHITECTURE.md): $VIOLATIONS boundary violation(s)."
fi
exit 0
