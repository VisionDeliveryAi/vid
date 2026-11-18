#!/bin/sh
# Purpose: selftest case — a ViD draft never takes a failure clause away on
# its own (0.26.10.29.3, R2). From the known-good fixture in its 0.9.1 form:
# REQ-012 AMENDED withdraws its second arm under A-007, a model_proposed
# answer settling REQ-012. checks/prd.sh refuses it at commit (join 14 names
# the arm and ViD's draft); under --pause it is not refused and the pause
# material lists the owner question "arm 2 of REQ-012 withdrawn under ViD's
# draft A-007". The same withdrawal under a human A-007 passes and lists
# nothing. The owner's two exits are both a human ruling on the answer, read
# from its effective row: A-007 restated human by an AMENDED row (the yes),
# or restated human with the no in its A: and REQ-012 amended with the arm
# back. A later REQ-012 AMENDED row alone — the shortened row restated, its
# statement reworded with the one arm kept, or the arm brought back — clears
# nothing while A-007 is ViD's draft: the gap and the pause line stand.
# Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "draft-withdrawal-is-owner-question: $*" >&2; exit 1; }
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > "$2"
}
to091 "$FIXTURES/prd-known-good.md" BASE.md
sh "$COURT" BASE.md >/dev/null 2>&1 || fail 'the 0.9.1 base does not acquit'
withdraw() { # tier → file
  { cat BASE.md; printf '\n### 2026-09-30 (the bounce arm)\n\n```vid-prd-answers\nA-007 | %s | 2026-09-30 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch; the bounce arm is withdrawn | settles: REQ-012\n```\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 withdrawn A-007\n```\n' "$1"; } > "$2"
}
withdraw model_proposed D.md
if sh "$COURT" D.md >out.txt 2>&1; then fail 'an arm withdrawn under a ViD draft passed at commit'; fi
grep '^GAP' out.txt | grep -F 'join 14 (REQ-012 AMENDED)' | grep -q 'A-007' || { grep '^GAP' out.txt >&2; fail 'the gap does not name the arm, REQ-012 and A-007'; }
sh "$COURT" D.md --pause >pause.txt 2>&1 || { grep '^GAP' pause.txt >&2; fail 'the withdrawal under a draft was refused under --pause (it is an owner question there)'; }
grep -qxF "  arm 2 of REQ-012 withdrawn under ViD's draft A-007" pause.txt || { cat pause.txt >&2; fail 'the pause material does not list the owner question'; }
# the owner's two exits are both a human ruling on the answer. The no: the answer restated human, its A: saying the
# clause stays, and the item amended with the arm back
BACKROW='REQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained'
{ cat D.md; printf '\n### 2026-10-02 (the owner says no)\n\n```vid-prd-answers\nA-007 AMENDED | human | 2026-10-02 | Q: may mail to the support address bounce at launch? | A: no — mail to the support address must not bounce; the clause stays | settles: REQ-012\n```\n\n```vid-prd\n%s\n```\n' "$BACKROW"; } > NO.md
sh "$COURT" NO.md >no.txt 2>&1 || { grep '^GAP' no.txt >&2; fail 'the owner said no (the answer restated human, the arm brought back), and the old withdrawal is still a gap'; }
sh "$COURT" NO.md --pause >npause.txt 2>&1 || fail 'the owner'"'"'s no was refused under --pause'
grep -qE "^  arm [0-9]+ of .* withdrawn under ViD's draft" npause.txt && fail 'a withdrawal the owner ruled against is still listed as an owner question'
# never a later amendment of the item alone: while the answer is ViD's draft, the withdrawal stays a gap and a question
stillheld() { # file, what
  if sh "$COURT" "$1" >held.txt 2>&1; then fail "$2, the answer still ViD's draft, and the withdrawal passed at commit"; fi
  grep '^GAP' held.txt | grep -F 'join 14 (REQ-012 AMENDED)' | grep -q 'A-007' || { grep '^GAP' held.txt >&2; fail "$2: the gap does not name REQ-012 and A-007"; }
  sh "$COURT" "$1" --pause >hpause2.txt 2>&1 || fail "$2: refused under --pause"
  grep -qxF "  arm 2 of REQ-012 withdrawn under ViD's draft A-007" hpause2.txt || fail "$2: the pause material no longer lists the owner question"
}
{ cat D.md; printf '\n### 2026-10-02 (the same row again)\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained\n```\n'; } > SAME.md
stillheld SAME.md 'a later AMENDED row restated the shortened item'
{ cat D.md; printf '\n### 2026-10-02 (the statement reworded)\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer names a support contact address in plain text. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained\n```\n'; } > REWORD.md
stillheld REWORD.md 'a later AMENDED row changed the statement and kept the one arm'
{ cat D.md; printf '\n### 2026-10-02 (the bounce arm stays)\n\n```vid-prd\n%s\n```\n' "$BACKROW"; } > BACK.md
stillheld BACK.md 'a later AMENDED row brought the arm back'
{ cat D.md; printf '\n### 2026-10-02 (the owner says yes)\n\n```vid-prd-answers\nA-007 AMENDED | human | 2026-10-02 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch; the bounce arm is withdrawn | settles: REQ-012\n```\n'; } > YES.md
sh "$COURT" YES.md >yes.txt 2>&1 || { grep '^GAP' yes.txt >&2; fail 'the answer restated human by an AMENDED row, and the withdrawal is still a gap'; }
sh "$COURT" YES.md --pause >ypause.txt 2>&1 || fail 'the answer restated human was refused under --pause'
grep -qE "^  arm [0-9]+ of .* withdrawn under ViD's draft" ypause.txt && fail 'a withdrawal under an answer restated human is still listed as a draft'
withdraw human H.md
sh "$COURT" H.md >/dev/null 2>&1 || fail 'the same withdrawal under a human answer was refused'
sh "$COURT" H.md --pause >hpause.txt 2>&1 || fail 'the human withdrawal was refused under --pause'
grep -qE "^  arm [0-9]+ of .* withdrawn under ViD's draft" hpause.txt && fail 'a withdrawal under a human answer was listed as a draft'
exit 0
