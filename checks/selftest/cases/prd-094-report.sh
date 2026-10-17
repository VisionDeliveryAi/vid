#!/bin/sh
# Purpose: selftest case — prd.sh's report fields (v0.9.4 spec §3.1, §7
# case 9), appended after `notes=` so every older pattern holds:
# features=F (effective features), priority=P (effective human answers
# carrying `importance: priority`), shown=S/M (effective model_proposed
# answers carrying `shown:`, of all effective model_proposed answers),
# values-unchecked=U (items join 19 could not trace: a door sitting
# reference on an authoritative or provisional owner-decision item). A
# planted fixture is counted exactly — an amended feature counts once, a
# superseded priority does not count, `importance: normal` is not priority,
# a door reference on a measurement item is not in scope — and any
# miscount fails the case. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-report: $*" >&2; exit 1; }
cp "$FIXTURES/prd-094-good.md" G.md
sh "$COURT" G.md --report 2>&1 | grep -q ' notes=0 features=3 priority=1 shown=2/2 values-unchecked=0$' || fail "fixture: $(sh "$COURT" G.md --report 2>&1 | tail -1)"
awk '
  /^FEAT-03 \| G1 / { print; print "FEAT-04 | G2 | saved-search sharing"; next }
  /^A-001 \| human/ { print $0 " | importance: priority"; next }
  /^A-003 \| human/ { print $0 " | importance: normal"; next }
  /^A-004 \| human/ { print $0 " | importance: priority"; next }
  /^A-005 \| model_proposed/ { sub(/ \| shown: pause-1 [0-9]+$/, ""); print; next }
  { print }' G.md > P.md
cat >> P.md <<'APP'

### 2026-09-03 (/vid fix correction)

```vid-prd-features
FEAT-02 AMENDED | G2 | synonym-aware search and ranking
```

```vid-prd-answers
A-004 AMENDED | human | 2026-09-03 | Q: is organic search an MVP channel? | A: no — distribution is email-first; technical SEO is out for MVP | settles: DIM-seo-technical
A-010 | model_proposed | 2026-09-03 | Q: how long is a delivery failure kept? | A: thirty days | settles: REQ-011
```

```vid-prd
REQ-040 | functional | T2 | An unsubscribe takes effect within 72 hours. | fail-if: a digest arrives more than 72 hours after an unsubscribe | serves: the corrected exit | authority: authoritative | source: fix 2026-09-03 | phase: pilot | feature: FEAT-03
REQ-041 | functional | T2 | A saved search's results page shows at most 50 matches. | fail-if: a results page shows a 51st match | serves: the corrected page size | authority: authoritative | source: design 2026-09-03 P02/results | phase: pilot | feature: FEAT-02
REQ-042 | nfr | T2 | Digest assembly finishes within 20 minutes of the daily run. | fail-if: a digest is assembled more than 20 minutes after the run | serves: digests arrive on time | authority: provisional | confirms_via: measurement/no | source: grade 2026-09-03 finding 2 | phase: pilot | feature: FEAT-01
```
APP
sh "$COURT" P.md >/dev/null 2>&1 || { sh "$COURT" P.md --report 2>&1 | grep '^GAP' | head -3 >&2; fail 'the planted fixture convicts'; }
OUT=$(sh "$COURT" P.md --report 2>&1 | tail -1)
printf '%s\n' "$OUT" | grep -q ' gaps=0 grammar=0.9.4 notes=0 features=4 priority=2 shown=1/3 values-unchecked=2$' || fail "planted: $OUT"
exit 0
