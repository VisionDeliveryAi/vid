# Purpose: selftest fixture — a toy ViD project with every kind of milestone, for the viewer's cases (v0.9.7.4 spec
# §2). Sourced after gated-run.sh and plan-run.sh (Env: CHECKS, T). view_project <dir> makes it there and enters it.
# Every commit and every event carries a fixed time (2026-01-01, UTC), so the milestones are known:
#   09:10 PRD ratified (thesis+contract), commit $C_R1 · 09:20 PRD ratified (final), $C_R2 · 09:30 the documents, $C_DOCS
#   10:00 setup done · 10:10 building started · 10:40 S1 closed (commit $C_S1, 10:35) · 10:50 slice 1 closed
#   11:20 checkpoint 1 (commit $C_LATE, 11:05) · now: HEAD ($C_HEAD, 11:30)
# The documents: a PRD (grammar 0.9.5; goals G1 G2, two users, features FEAT-01 FEAT-02, REQ-001 REQ-002 (phase
# later) INV-001, NG-001, answers A-001 human, A-002 human worded "Delegated by the owner", A-003 model_proposed and
# A-001 amended in an append), INVENTORY rows ROW-001..ROW-007 (ROW-004 later, ROW-005 under two capabilities (INV-001 in FEAT-02, REQ-001),
# ROW-006 a journey, ROW-007 owed), DECISIONS.md D-001, a design brief whose manifest names P01/default and
# P01/empty, and one canvas (design/screens/P Pages.dc.html) naming its runtime and stylesheet. The plan: S1
# (ROW-001..003, ROW-006) and S2 (ROW-004, ROW-005, ROW-007), kept in .vid/plans/. The records: receipts r1 (10:30:
# ROW-001..003 pass, ROW-006 fails) and r2 (11:10: ROW-006 passes), a builder's hand-back (ROW-001, ROW-002 pass;
# build-cost at 10:31), verdicts at 10:45 (ROW-001 KEPT, ROW-002 BREACHED class=test) with ROW-001's prose, question
# 1 asked 10:55 and answered 11:22 (open at the checkpoint), question 2 asked 11:25 and open (its RUN-STATE line), an agent open.
# vt <HH:MM>: the fixture's UTC time that minute; vcommit <HH:MM> <message>: a commit at that time;
# vrcpt <HH:MM> <rcpt arguments…>: a receipt (plan-run.sh's rcpt) published at that time.
vt() { printf '2026-01-01T%s:00Z' "$1"; }
vcommit() { GIT_AUTHOR_DATE=$(vt "$1") GIT_COMMITTER_DATE=$(vt "$1") g commit -qm "$2"; }
vrcpt() { _vt=$(vt "$1"); shift; rcpt "$@"; sed '$s/ at=[^ ]*$/ at='"$_vt"'/' .vid/metrics-events > .vid/e.x && mv .vid/e.x .vid/metrics-events; }
view_project() {
  GIT_AUTHOR_DATE=$(vt 09:00); GIT_COMMITTER_DATE=$(vt 09:00); export GIT_AUTHOR_DATE GIT_COMMITTER_DATE
  plan_repo "$1"
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
  : > .vid/metrics-events
  cat > PRD.md <<'PRD'
# Toy Shop — PRD
grammar: 0.9.5

## Thesis

### Primary users

- **Shopper** — buys things.
- **Shop owner** — runs the shop.

### MVP focus

- G1: Selling — a shopper finds a thing and buys it.
- G2: Running — the owner keeps the shelves true.

## Items

```vid-prd-features
FEAT-01 | G1 | Finding and buying
FEAT-02 | G2 | Keeping the shelves
```

```vid-prd
REQ-001 | functional | T1 | A shopper finds a thing by its name. | fail-if: a search by an item's name does not list it | phase: pilot | feature: FEAT-01 | plain: A shopper finds a thing by its name
REQ-002 | functional | T2 | The owner restocks a shelf. | fail-if: a restock leaves the count unchanged | phase: later | feature: FEAT-02 | plain: The owner restocks a shelf
INV-001 | invariant | T0 | No price is ever negative. | phase: pilot | feature: FEAT-02 | plain: No price is ever below zero
NG-001 | non_goal | - | No delivery. | phase: pilot
```

## Answer ledger

```vid-prd-answers
A-001 | human | 2026-01-01 | Q: Which currency? | A: Pounds. | settles: REQ-001
A-002 | human | 2026-01-01 | Q: Show stock? | A: Delegated by the owner, accepted as recommended — yes, as a count. | settles: REQ-002
A-003 | model_proposed | 2026-01-01 | A: Names are matched without case. | settles: REQ-001
```
PRD
  g add PRD.md; vcommit 09:10 'prd: pause 1'; C_R1=$(git rev-parse HEAD)
  printf '\n## Appends\n\n```vid-prd-answers\nA-001 AMENDED | human | 2026-01-01 | Q: Which currency? | A: Pounds and pence. | settles: REQ-001\n```\n' >> PRD.md
  g add PRD.md; vcommit 09:20 'prd: final'; C_R2=$(git rev-parse HEAD)
  awk -v a="$(git rev-parse --short HEAD~1)" -v b="$(git rev-parse --short HEAD)" '/^## Appends/ { print "## Ratifications\n\n- 2026-01-01 — thesis+contract — " a "\n- 2026-01-01 — final — " b "\n" } { print }' PRD.md > PRD.x && mv PRD.x PRD.md
  for f in s1 s2; do printf '# Purpose: ledger for %s\n' "$f" > "tests/invariants/test_$f.py"; done
  { printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n'
    printf 'ROW-001 | behavior | /find | shopper | P01/default | Searching an item'"'"'s name lists it | REQ-001 | tests/invariants/test_s1.py\n'
    printf 'ROW-002 | behavior | /find | shopper | - | An unknown name lists nothing | REQ-001 | tests/invariants/test_s1.py\n'
    printf 'ROW-003 | behavior | /find | shopper | - | control of ROW-001: the list shows the price | REQ-001 | tests/invariants/test_s1.py\n'
    printf 'ROW-004 | behavior | /shelf | owner | P01/empty | A restock raises the count | REQ-002 | tests/invariants/test_s2.py\n'
    printf 'ROW-005 | behavior | /shelf | owner | - | No price shown is below zero | INV-001, REQ-001 | tests/invariants/test_s2.py\n'
    printf 'ROW-006 | journey | journey:shopper | shopper | n/a | The shopper buys: finds an item and pays. transitions: 1. shopper at P01/default · search · submits a name · P01/default · the item listed | REQ-001 | tests/invariants/test_s1.py\n'
    printf 'ROW-007 | behavior | /shelf | owner | - | The shelf survives a restart | REQ-002 | owed: fixture-source — no restart harness yet\n'
    printf '```\n'; } > INVENTORY.md
  for i in 1 2 3 6; do printf 'def test_00%s(): pass  # ROW-00%s\n' "$i" "$i" >> tests/invariants/test_s1.py; done
  for i in 4 5; do printf 'def test_00%s(): pass  # ROW-00%s\n' "$i" "$i" >> tests/invariants/test_s2.py; done
  printf '# Decisions\n\n## Log\n\n- **D-001** Prices are held in pence | why: no rounding | enforced: convention | applies-to: REQ-001\n' > DECISIONS.md
  printf '# Design brief\n\n## Manifest\n\n```vid-design-manifest\nP01 | default | REQ-001 | pins: the list\nP01 | empty | REQ-002 | pins: the empty shelf\n```\n' > DESIGN-BRIEF.md
  mkdir -p design/screens
  printf '/* the canvas runtime */\nwindow.CANVAS_RUNTIME = 1;\n' > design/screens/support.js
  printf ':root { --shop: #123456; }\n' > design/screens/tokens.css
  { printf '<!DOCTYPE html>\n<html><head><script src="./support.js"></script></head><body>\n<link rel="stylesheet" href="tokens.css">\n'
    printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<div class="cc-state">the list</div>\n<!-- @screen P01 state=empty reqs=REQ-002 -->\n<div class="cc-state">the empty shelf</div>\n</body></html>\n'; } > "design/screens/P Pages.dc.html"
  g add -A; vcommit 09:30 'the documents'; C_DOCS=$(git rev-parse HEAD)
  printf 'stage name=init state=start session=S0 records=19 at=%s\n' "$(vt 09:00)" >> .vid/metrics-events
  printf 'stage name=init state=end session=S0 at=%s\n' "$(vt 10:00)" >> .vid/metrics-events
  printf 'stage name=develop state=start session=S1 records=19 at=%s\n' "$(vt 10:10)" >> .vid/metrics-events
  printf 'run: active\nsession: S1\nplan: required\nquestions: 1 open · next Q3\nslice: 2 open\n' > .vid/RUN-STATE.md
  plan 'step S1 | name: Shoppers find things | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-003 ROW-006 | lane: builder' \
    'step S2 | name: Owners restock | modules: app/s2 | builds-on: S1 | rows: ROW-004 ROW-005 ROW-007 | lane: builder' "shared: $PLANS_SHARED"
  sh checks/plan.sh change create 'two steps' --trigger initial --expect 'they build' > /dev/null
  sed '$s/ at=[^ ]*$/ at='"$(vt 10:11)"'/' .vid/metrics-events > .vid/e.x && mv .vid/e.x .vid/metrics-events
  printf '\n## Open product questions\n\n- Q2 · asked 2026-01-01 · gates ROW-004 · May a restock exceed the shelf? Recommended: no.\n' >> .vid/RUN-STATE.md
  printf 'step-start step=S1 plan=x base=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(vt 10:20)" >> .vid/metrics-events
  printf 'feature s1\n' > app/s1/main.py; g add -A; vcommit 10:25 'S1 code'
  vrcpt 10:30 r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-006=failed
  mkdir -p .vid/briefs/1
  printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: x\nROW-001 | pass | r1\nROW-002 | pass | r1\nROW-006 | not | r1 | the journey fails\n' > .vid/briefs/1/builder-1.return.md
  printf 'build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-1.md rows=3 rows-passed=2 peak=1 total=1 before-change=unknown at=%s\n' "$(vt 10:31)" >> .vid/metrics-events
  printf 'feature s1 v2\n' > app/s1/main.py; g add -A; vcommit 10:35 'S1 done'; C_S1=$(git rev-parse HEAD)
  printf 'step-closed step=S1 report=r1 at=%s\n' "$(vt 10:40)" >> .vid/metrics-events
  printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=.vid/briefs/1/grader-1.md quoted-at=x at=%s\n' "$(vt 10:45)" >> .vid/metrics-events
  printf 'verdict slice=1 row=ROW-002 result=BREACHED class=test brief=.vid/briefs/1/grader-1.md quoted-at=x at=%s\n' "$(vt 10:45)" >> .vid/metrics-events
  mkdir -p .vid/verdicts; printf '## slice 1 · grader-1 · KEPT\nThe test searches the name and reads the list.\n' > .vid/verdicts/ROW-001.md
  printf 'slice-close slice=1 sha=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(vt 10:50)" >> .vid/metrics-events
  printf 'question n=1 state=asked gates=ROW-004,ROW-005 at=%s\n' "$(vt 10:55)" >> .vid/metrics-events
  printf 'step-start step=S2 plan=x base=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(vt 11:00)" >> .vid/metrics-events
  printf 'feature s2\n' > app/s2/main.py; g add -A; vcommit 11:05 'S2 code'; C_LATE=$(git rev-parse HEAD)
  vrcpt 11:10 r2 HEAD inline ROW-006=passed ROW-005=passed
  printf 'checkpoint n=1 report=r2 built=4 regressions=0 base=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(vt 11:20)" >> .vid/metrics-events
  printf 'question n=1 state=answered at=%s\n' "$(vt 11:22)" >> .vid/metrics-events
  printf 'question n=2 state=asked gates=ROW-004 at=%s\n' "$(vt 11:25)" >> .vid/metrics-events
  printf 'agent-start session=S1 agent=b0b0b0b0b0b0 type=vid:builder at=%s\n' "$(vt 11:26)" >> .vid/metrics-events
  printf 'readme\n' > README.md; printf 'records: 19\n' > checks/records-version; g add -A; vcommit 11:30 'docs'; C_HEAD=$(git rev-parse HEAD)
}
# vview [args…]: the viewer at the plugin's path, its output in $T/out unless --out is given; prints its lines
VIEWER_SH="$CHECKS/../viewer/view.sh"
vview() { sh "$VIEWER_SH" "$@"; }
# vdata <snapshot file>: the snapshot's embedded data, one JSON object
vdata() { awk '/^<script>window\.VID_DATA=/ { on = 1; sub(/^<script>window\.VID_DATA=/, "") } on && /;<\/script>$/ { sub(/;<\/script>$/, ""); print; exit } on { print }' "$1"; }
