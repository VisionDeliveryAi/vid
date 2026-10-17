#!/bin/sh
# Purpose: selftest case — prd.sh, v0.9.4 spec §7 case 1 (R1): older
# grammars are judged as today, the new labels apart. A 0.9.1 copy of the
# known-good fixture and the legacy fixture itself, each carrying
# `feature:` (naming a feature no block declares), `importance: priority`,
# a model_proposed answer with `shown:` and a `lens` findings row, acquit —
# the 0.9.3 court convicted every one of them as unknown — and the labels
# are ignored: no join 16-20 runs before 0.9.4, so the undeclared feature
# convicts nothing; the report counts them after `notes=`. The whitelists
# stay closed: a misspelt item label or answer label still convicts under
# 0.9.1. The other half of case 1 — every existing prd case passing
# unmodified — is the suite itself. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-older: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > "$2"
}
# labels <in> <out>: feature: on REQ-001, importance: on A-001, a lens row after F-05, and an
# appended model_proposed answer carrying shown:.
labels() {
  awk '
    /^REQ-001 \|/ { print $0 " | feature: FEAT-09"; next }
    /^A-001 \| human/ { print $0 " | importance: priority"; next }
    { print }
    /^F-05 \| audit/ { print "F-06 | lens | advisory | REQ-012 | repaired | evidence: arms: 1 retained, 2 retained — now: the footer lacks a support address, or mail to it bounces" }' "$1" > "$2"
  printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-answers\nA-007 | model_proposed | 2026-09-02 | Q: how long is a delivery failure kept in the log? | A: thirty days | settles: REQ-011 | shown: pause-1 12345\n```\n' >> "$2"
}
to091 "$FIXTURES/prd-known-good.md" B091.md
labels B091.md L091.md
grep -q '| feature: FEAT-09$' L091.md && grep -q '| importance: priority$' L091.md && grep -q '^F-06 | lens ' L091.md && grep -q '| shown: pause-1 12345$' L091.md || fail 'the planted labels are missing'
run L091.md
[ "$RC" -eq 0 ] || { printf '%s\n' "$OUT" | grep '^GAP' | head -5 >&2; fail 'a 0.9.1 file carrying the new labels convicts'; }
printf '%s\n' "$OUT" | grep -q '^GAP' && fail 'GAP lines on the 0.9.1 file'
printf '%s\n' "$OUT" | grep -q '^NOTE' && fail 'NOTE lines on the 0.9.1 file — the new labels are ignored, not reported'
printf '%s\n' "$OUT" | grep -q ' gaps=0 grammar=0.9.1 notes=0 features=0 priority=1 shown=1/1 values-unchecked=0$' || fail "0.9.1 report: $(printf '%s\n' "$OUT" | tail -1)"
# the legacy file: the same labels acquit, the priority column and P0 count untouched
labels "$FIXTURES/prd-known-good.md" LLEG.md
run LLEG.md
[ "$RC" -eq 0 ] || { printf '%s\n' "$OUT" | grep '^GAP' | head -5 >&2; fail 'a legacy file carrying the new labels convicts'; }
printf '%s\n' "$OUT" | grep -qE 'P0=[0-9]+/[0-9]+ pilot=[0-9]+ later=0 ' || fail 'the legacy report lost its P0 count'
printf '%s\n' "$OUT" | grep -q ' gaps=0 grammar=legacy notes=0 features=0 priority=1 shown=1/1 values-unchecked=0$' || fail "legacy report: $(printf '%s\n' "$OUT" | tail -1)"
# the whitelists stay closed under 0.9.1
sed 's/| feature: FEAT-09$/| featur: FEAT-09/' L091.md > M091.md
run M091.md; [ "$RC" -ne 0 ] || fail 'a misspelt item label acquits'
printf '%s\n' "$OUT" | grep -qF "GAP  join 1 (REQ-001): unlabeled field 'featur: FEAT-09'" || fail 'the misspelt item label is not named'
sed 's/| importance: priority$/| importanse: priority/' L091.md > I091.md
run I091.md; [ "$RC" -ne 0 ] || fail 'a misspelt answer label acquits under 0.9.1'
printf '%s\n' "$OUT" | grep -qF "GAP  join 1 (A-001): unlabeled field 'importanse: priority'" || fail 'the misspelt answer label is not named'
exit 0
