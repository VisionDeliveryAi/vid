#!/bin/sh
# Purpose: ViD court — provider seams (§3.4), presence-gated, fail-closed.
# Rule source: seam rows in INVENTORY.md's vid-inventory block
# (seam | SEAM-NNN | service | purpose | chosen | credentials: | probe: |
# evidence: | quirks: [| match: <tokens>]). Two judgments on the staged
# diff: (a) OWED-TOUCH — app-source additions matching an owed seam's
# match tokens are rejected naming the row; the probe comes before the
# first client line (tests/ is exempt: contract tests are the probe's own
# artifact). (b) DISCOVERY (§3.2 door 2) — a staged outbound destination
# (a scheme URL to a remote host) covered by no seam row demands one
# before the code lands; a content link that is no outbound call takes a
# ratified exception row naming class `seam`. Lockfile-shaped files
# (*.lock, *lock.json, *lock.yaml, *.sum) are toolchain records, not app
# outbound calls, and are excluded. Presence-gated: inactive without an
# INVENTORY.md machine block. Usage: sh checks/seams.sh
set -eu
IFS='
'

[ -f INVENTORY.md ] || exit 0
BLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
[ -n "$BLOCK" ] || exit 0
SEAMS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*seam[[:space:]]*\|' || true)
EXCS=$(printf '%s\n' "$BLOCK" | grep -E '^[[:space:]]*exception[[:space:]]*\|' || true)

field() { printf '%s\n' "$1" | cut -d'|' -f"$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
labeled() { # $1=row $2=label — value of a labeled field, empty if absent
  printf '%s\n' "$1" | tr '|' '\n' | sed -n 's/^[[:space:]]*'"$2"':[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//'
}

# Staged added lines in app source. Never *.md; tests/ (the probe's own
# artifact), checks/ (courts), design/ (spec), lockfile shapes (toolchain).
ADDED=$(git diff --cached -U0 -- . ':(exclude)*.md' ':(exclude)tests/' ':(exclude)checks/' ':(exclude)design/' ':(exclude)*.lock' ':(exclude)*lock.json' ':(exclude)*lock.yaml' ':(exclude)*.sum' 2>/dev/null | grep '^+' | grep -v '^+++' || true)
[ -n "$ADDED" ] || exit 0

FAIL=0

# (a) owed-touch: client code for a seam whose probe is still owed.
for row in $SEAMS; do
  id=$(field "$row" 2); svc=$(field "$row" 3)
  probe=$(labeled "$row" probe)
  case "$probe" in owed*) ;; *) continue ;; esac
  toks=$(labeled "$row" match); [ -n "$toks" ] || toks=$svc
  for t in $(printf '%s\n' "$toks" | tr ' ' '\n' | grep -v '^$'); do
    HITS=$(printf '%s\n' "$ADDED" | grep -iF -- "$t" || true)
    [ -n "$HITS" ] || continue
    echo "ViD seams: rejected — staged app-source additions touch seam $id ($svc), whose probe is still OWED:" >&2
    printf '%s\n' "$HITS" | head -n 3 | sed 's/^/    /' >&2
    echo 'Probe first (§3.3): the smallest real calls, contract tests over the captured response, then flip the row to probed(date) — or declare unreachable-risk(reason). Never client code from description.' >&2
    FAIL=1
  done
done

# (b) discovery (§3.2 door 2): outbound destinations no seam row covers.
URLS=$(printf '%s\n' "$ADDED" | grep -oE '[a-z][a-z0-9+.-]*://[A-Za-z0-9._-]+' | sort -u || true)
for u in $URLS; do
  host=${u#*://}
  # not external services: loopback, reserved example/test names, doc/schema
  # namespaces that appear in markup rather than calls.
  case "$host" in
    localhost|localhost.*|127.*|0.0.0.0|::1|*.local|*.test|*.internal|*.invalid|example.*|*.example|*.example.*|w3.org|*.w3.org|schema.org|*.schema.org|json-schema.org|purl.org) continue ;;
  esac
  COVERED=no
  for row in $SEAMS; do
    toks=$(labeled "$row" match); [ -n "$toks" ] || toks=$(field "$row" 3)
    for t in $(printf '%s\n' "$toks" | tr ' ' '\n' | grep -v '^$'); do
      case "$host" in *"$t"*) COVERED=yes; break ;; esac
    done
    [ "$COVERED" = yes ] && break
  done
  [ "$COVERED" = yes ] && continue
  EXCUSED=''
  for e in $EXCS; do
    [ "$(field "$e" 4)" = seam ] || continue
    subj=$(field "$e" 3)
    case "$host" in "$subj"|*"$subj") EXCUSED=$(field "$e" 2); break ;; esac
  done
  if [ -n "$EXCUSED" ]; then
    echo "EXC   seam-discovery  $host  ($EXCUSED: content link, ratified)"
    continue
  fi
  echo "ViD seams: rejected — staged addition reaches outbound destination '$host' and no seam row covers it (§3.2)." >&2
  echo "An external service is declared before its code lands: add the seam row (born 'probe: owed', a standalone law commit) — or, for a content link that is no outbound call, an exception row naming class 'seam'." >&2
  FAIL=1
done

exit $FAIL
