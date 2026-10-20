# Purpose: selftest fixture — a toy two-stage product for the stage cases (v0.26.10.5 §5). Sourced (Env: CHECKS, T).
# st_files: in the current directory, PRD.md (three features, five requirements, REQ-005 later), INVENTORY.md
# (grammar 0.9.3: ROW-001..ROW-006, ROW-006 mixed, RULE-001, HOS-001 protecting REQ-004, HOS-002 protecting REQ-001)
# and STAGES.md (stage 1: FEAT-01 FEAT-02; stage 2: FEAT-03; REQ-003 split to stage 2; ROW-006 placed in stage 2;
# FEAT-03 needs FEAT-01). The tests each row cites exist and name their rows. st_stages <lines…> rewrites the
# vid-stages block. st_close_repo <dir>: a repository holding them with the courts and readers a stage close reads
# (stages, prd, coverage, inventory, metrics, census, plan, event, lawfiles), a toy results reader, CLAUDE.md placing
# app/, app/main.py citing every requirement, every row stamped proved-red, RUN-STATE at `stage: 1`.
# st_rcpt [<id>=<status> …]: the full run of HEAD, every obligation's case passed unless named. st_keep <ROW ids…>:
# a KEPT verdict for each, quoted at HEAD.
st_prd() {
  cat > PRD.md <<'EOF'
# Toy PRD

```vid-prd-features
FEAT-01 | G1 | signing in
FEAT-02 | G1 | notes
FEAT-03 | G2 | sharing
```

```vid-prd
REQ-001 | functional | T0 | a person signs in | fail-if: a wrong password signs in | serves: access | phase: pilot | feature: FEAT-01
REQ-002 | functional | T1 | a person writes a note | fail-if: a saved note is lost | serves: notes | phase: pilot | feature: FEAT-02
REQ-003 | functional | T1 | a person tags a note | fail-if: a tag is lost | serves: notes | phase: pilot | feature: FEAT-02
REQ-004 | functional | T0 | a person shares a note | fail-if: a stranger reads it | serves: sharing | phase: pilot | feature: FEAT-03
REQ-005 | functional | T1 | a person shares to a group | fail-if: a group member misses it | serves: sharing | phase: later | feature: FEAT-03
```
EOF
}
st_inv() {
  mkdir -p tests/invariants
  for _x in a b c d e f rule hos1 hos2; do printf '# Purpose: toy ledger %s\n' "$_x" > "tests/invariants/test_$_x.py"; done
  printf 'def test_1(): pass  # ROW-001\n' >> tests/invariants/test_a.py
  printf 'def test_2(): pass  # ROW-002\n' >> tests/invariants/test_b.py
  printf 'def test_3(): pass  # ROW-003\n' >> tests/invariants/test_c.py
  printf 'def test_4(): pass  # ROW-004\n' >> tests/invariants/test_d.py
  printf 'def test_5(): pass  # ROW-005\n' >> tests/invariants/test_e.py
  printf 'def test_6(): pass  # ROW-006\n' >> tests/invariants/test_f.py
  printf 'def test_r(): pass  # RULE-001\n' >> tests/invariants/test_rule.py
  printf 'def test_h1(): pass  # HOS-001\n' >> tests/invariants/test_hos1.py
  printf 'def test_h2(): pass  # HOS-002\n' >> tests/invariants/test_hos2.py
  cat > INVENTORY.md <<'EOF'
# Inventory

```vid-inventory
grammar: 0.9.3
ROW-001 | behavior | REQ-001 | anonymous | n/a | a wrong password is refused | REQ-001 | tests/invariants/test_a.py
ROW-002 | behavior | REQ-002 | anonymous | n/a | a saved note survives | REQ-002 | tests/invariants/test_b.py
ROW-003 | behavior | REQ-003 | anonymous | n/a | a tag survives | REQ-003 | tests/invariants/test_c.py
ROW-004 | behavior | REQ-004 | anonymous | n/a | a stranger is refused | REQ-004 | tests/invariants/test_d.py
ROW-005 | behavior | REQ-005 | anonymous | n/a | a group member gets it | REQ-005 | tests/invariants/test_e.py
ROW-006 | journey | /notes | anonymous | n/a | write a note, then share it | REQ-002, REQ-004 | tests/invariants/test_f.py
rule | RULE-001 | every note write is logged | echo app/main.py | 1 | tests/invariants/test_rule.py
hostility | HOS-001 | read a shared note as a stranger | protects: REQ-004 | disable: drop the share check | tests/invariants/test_hos1.py
hostility | HOS-002 | sign in with a wrong password | protects: REQ-001 | disable: drop the password check | tests/invariants/test_hos2.py
```
EOF
}
st_stages() {
  { printf '# Stages\n\n```vid-stages\n'; for _l in "$@"; do printf '%s\n' "$_l"; done; printf '```\n'; } > STAGES.md
}
st_cut() {
  st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
    'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'needs: FEAT-03 needs FEAT-01 — ARCHITECTURE.md module table'
}
st_files() { st_prd; st_inv; st_cut; }

g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
st_close_repo() {
  mkdir -p "$1"; cd "$1"; git init -q
  mkdir -p checks/extractors app .vid/ledger-results
  for _c in stages.sh prd.sh coverage.sh inventory.sh metrics.sh census.sh plan.sh event.sh lawfiles; do cp "$CHECKS/$_c" checks/; done
  cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
  printf '.vid/\n' > .gitignore
  printf '# toy\n```vid-placement\napp\ntests\n```\n' > CLAUDE.md
  printf '# Purpose: toy app — REQ-001 REQ-002 REQ-003 REQ-004 REQ-005\n' > app/main.py
  st_files
  g add -A && g commit -qm 'the toy product'
  _s=$(git rev-parse --short=12 HEAD)
  sed "s#^\(.*| tests/invariants/test_[a-z0-9]*\.py\)\$#\1 | proved-red: $_s#" INVENTORY.md > INVENTORY.x && mv INVENTORY.x INVENTORY.md
  g add -A && g commit -qm 'every row stamped proved-red'
  printf 'run: active\nsession: S1\nplan: required\nstage: 1\nquestions: - · next Q1\nslice: 1 open\n' > .vid/RUN-STATE.md
}
st_file() { case "$1" in ROW-001) echo a ;; ROW-002) echo b ;; ROW-003) echo c ;; ROW-004) echo d ;; ROW-005) echo e ;; ROW-006) echo f ;; RULE-001) echo rule ;; HOS-001) echo hos1 ;; HOS-002) echo hos2 ;; esac; }
st_rcpt() {
  _h=$(git rev-parse --short=12 HEAD)
  { echo '<r>'
    for _i in ROW-001 ROW-002 ROW-003 ROW-004 ROW-005 ROW-006 RULE-001 HOS-001 HOS-002; do
      _st=passed; for _kv in "$@"; do [ "${_kv%%=*}" = "$_i" ] && _st=${_kv#*=}; done
      [ "$_st" = - ] && continue
      printf '<case name="tests/invariants/test_%s.py::t[%s]" status="%s" time="0.1"/>\n' "$(st_file "$_i")" "$_i" "$_st"
    done; echo '</r>'; } > ".vid/ledger-results/$_h.full.xml"
}
st_keep() { for _r in "$@"; do printf 'verdict slice=1 row=%s result=KEPT class=product brief=b1 quoted-at=%s at=2026-10-20T00:00:00Z\n' "$_r" "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events; done; }
