#!/bin/sh
# Purpose: selftest case — the PRD writer changes nothing it refuses (FB-1 A2). On the 0.9.4 good fixture: an edits file
# that breaks the court (a demand row's fail-if dropped, before the final ratification) exits 1, prints the court's gap and
# leaves PRD.md byte for byte, as does a valid edit followed by that one; after the final ratification a `row` and a
# `field` on a base row exit 2 naming an AMENDED row in an append, and a `text` exits 2; a `text` whose old text occurs
# twice exits 2; an unknown operation, an unclosed `append`, and a bad line after a valid edit each exit 2. Every refusal
# leaves PRD.md as it was and no work file beside it. Env: CHECKS.
set -eu
fail() { echo "prd-apply-refuses: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
[ -f "$CHECKS/prd-apply.sh" ] || fail 'checks/prd-apply.sh is missing: no writer applies a sitting'
FX="$CHECKS/selftest/fixtures/prd-094-good.md"
mkdir pre post
sed '/^- .* — final — /d' "$FX" > pre/PRD.md; cp "$FX" post/PRD.md
cp pre/PRD.md pre.md; cp post/PRD.md post.md
# refused <dir> <exit> <what> <edits…>: the writer exits <exit> and the PRD in <dir> is unchanged
refused() { d=$1 x=$2 w=$3; shift 3; printf '%s\n' "$@" > ed.txt; set +e; sh "$CHECKS/prd-apply.sh" "$d/PRD.md" ed.txt > out.txt 2>&1; got=$?; set -e
  [ "$got" = "$x" ] || { cat out.txt >&2; fail "$w exited $got, not $x"; }
  cmp -s "$d.md" "$d/PRD.md" || fail "$w changed PRD.md"
  [ -z "$(ls -A "$d" | grep -v '^PRD.md$' || true)" ] || fail "$w left a file beside PRD.md: $(ls -A "$d")"; }
refused pre 1 'a dropped fail-if' 'field REQ-001 fail-if'
grep -q '^GAP  join 3 (REQ-001)' out.txt || { cat out.txt >&2; fail "the court's gap is not printed"; }
refused pre 1 'a valid edit then a court-breaking one' 'field REQ-006 phase later' 'field REQ-001 fail-if'
refused post 2 'a base row after the final ratification' 'row REQ-001 | functional | T1 | A subscriber receives one digest per saved search per day. | fail-if: a digest repeats a job | serves: trust | authority: authoritative | source: seed, A-001 | phase: pilot | feature: FEAT-01'
grep -q 'REQ-001 AMENDED' out.txt || { cat out.txt >&2; fail 'the refusal of a base row names no AMENDED row'; }
refused post 2 'a base field after the final ratification' 'field REQ-006 phase later'
refused post 2 'a text edit after the final ratification' 'text' 'Job seekers in niche trades' '--' 'Job seekers in skilled trades' 'end'
refused pre 2 'a text whose old text occurs twice' 'text' 'two source feeds' '--' 'three source feeds' 'end'
refused pre 2 'an unknown operation' 'rename REQ-001 REQ-099'
refused pre 2 'an append never closed' 'append "owner answer"' 'row A-010 | human | 2026-08-30 | Q: q? | A: a | settles: REQ-001'
refused pre 2 'a bad line after a valid edit' 'field REQ-006 phase later' 'field'
echo 'prd-apply-refuses: ok'
