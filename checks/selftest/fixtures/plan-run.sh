# Purpose: selftest fixture — a toy develop run under a 0.9.6 plan, for the
# plan and evidence cases (v0.9.6 spec 3.1–3.6, 3.11, 3.15; §7 cases 20–35).
# Sourced after gated-run.sh (Env: CHECKS, T). plan_repo <dir> makes a gated
# repository with the plan's courts and readers (plan.sh, evidence.sh,
# metrics.sh, prd.sh, brief.sh, event.sh), a results reader, three modules
# app/s1 app/s2 app/s3, a shared harness file, and rows written by
# rows <step> <from> <to> (ROW-<nnn>, behavior, cited tests/invariants/test_<step>.py,
# the test file naming each row). plan <lines…> writes RUN-STATE's plan
# block; commit_all commits. rcpt <name> <tree-ish> <shape> <ROW=status …>
# publishes a receipt as checks/test.sh would inside the gate: the report,
# <name>.tree (tree=, base=, frozen-at=, shape=), <name>.cases and the
# `ledger-run` event. A status `-` leaves the row's case out. v0.9.6.1: the
# event's kind is $RCPT_KIND (default scoped); a key ROW-nnn~<variant>
# writes a second case of the row, named …[ROW-nnn-<variant>].
PLANS_SHARED='tests/invariants/harness.py docker-compose.test.yml'
plan_repo() {
  gated_repo "$1"
  cp "$CHECKS/evidence.sh" "$CHECKS/metrics.sh" "$CHECKS/prd.sh" "$CHECKS/brief.sh" "$CHECKS/event.sh" checks/
  [ -f "$CHECKS/progress.sh" ] && cp "$CHECKS/progress.sh" checks/
  mkdir -p checks/extractors app/s1 app/s2 app/s3 tests/invariants
  printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
  for m in s1 s2 s3; do printf '# Purpose: toy module %s\n' "$m" > "app/$m/main.py"; done
  printf '# Purpose: the shared harness\n' > tests/invariants/harness.py
  printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md
  printf '# CLAUDE.md\n' > CLAUDE.md
  g add -A && g commit -qm 'the plan fixture'
  gate_on
}
# rows <step> <from> <to> [kind]: ROW rows cited to tests/invariants/test_<step>.py, the test naming each
rows() {
  _f="tests/invariants/test_$1.py"; [ -f "$_f" ] || printf '# Purpose: ledger for %s\n' "$1" > "$_f"
  _i=$2
  while [ "$_i" -le "$3" ]; do
    _r=$(printf 'ROW-%03d' "$_i")
    printf 'def test_%s(): pass  # %s\n' "$_i" "$_r" >> "$_f"
    awk -v r="$_r | ${4:-behavior} | s$_i | anon | - | x | REQ-001 | $_f" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > INVENTORY.md.x && mv INVENTORY.md.x INVENTORY.md
    _i=$((_i + 1))
  done
}
commit_all() { g add -A && g commit -qm "${1:-work}"; }
plan() { # the lines of the vid-plan block, one argument each
  { sed '/^## The plan/,$d' .vid/RUN-STATE.md; printf '## The plan\n\n```vid-plan\n'; for _l in "$@"; do printf '%s\n' "$_l"; done; printf '```\n'; } > .vid/RUN-STATE.x && mv .vid/RUN-STATE.x .vid/RUN-STATE.md
}
# rcpt <name> <tree-ish> <shape> <ROW-nnn=status …>
rcpt() {
  _n=$1; _t=$2; _s=$3; shift 3
  mkdir -p .vid/ledger-results
  { printf '<report>\n'
    for _kv in "$@"; do _r=${_kv%%=*}; _st=${_kv#*=}; [ "$_st" = - ] && continue
      _v=''; case "$_r" in *~*) _v="-${_r#*~}"; _r=${_r%%~*} ;; esac
      _f=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' -v r="$_r" '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id == r { t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); print t }')
      printf '<case name="%s::test_%s[%s%s]" status="%s" time="0.1"/>\n' "$_f" "${_r#ROW-}" "$_r" "$_v" "$_st"; done
    printf '</report>\n'; } > ".vid/ledger-results/$_n"
  sh checks/extractors/results.sh ".vid/ledger-results/$_n" > ".vid/ledger-results/$_n.cases"
  printf 'tree=%s\nbase=%s\nfrozen-at=%s\nshape=%s\n' "$(git rev-parse "$_t^{tree}")" "$(git rev-parse --short=12 "$_t^{commit}" 2>/dev/null || git rev-parse --short=12 HEAD)" "$(utcnow)" "$_s" > ".vid/ledger-results/$_n.tree"
  printf 'ledger-run seconds=1 kind=%s report=%s status=0 tree=x run=%s at=%s\n' "${RCPT_KIND:-scoped}" "$_n" "$_n" "$(utcnow)" >> .vid/metrics-events
  sleep 1   # receipts are ordered by their time
}
# state <row> [tree-ish]: the row's state on current results (evidence.sh over the plan's map)
state() { sh checks/plan.sh map --all > "$T/map" 2>/dev/null; sh checks/evidence.sh rows --at "${2:-HEAD}" --map "$T/map" | awk -F'\t' -v r="$1" '$1 == r { print $2 }'; }
# brief <file> <role> <step or -> <ROW-ids…>: a brief quoting the rows verbatim at HEAD; a test-author brief carries the independence paragraph;
# section 6 lists the role's test request and its wait (v0.9.7.0.2: a test-author proves red, the others iterate)
brief() {
  _bf=$1; _ro=$2; _st=$3; shift 3
  mkdir -p "$(dirname "$_bf")"
  { printf 'role: %s    slice: 1' "$_ro"; [ "$_st" != - ] && printf '    step: %s' "$_st"; printf '\nquoted-at: %s\n' "$(git rev-parse --short=12 HEAD)"
    printf 'receives: the rows    must not receive: another batch'"'"'s brief\n\n'
    [ "$_ro" = test-author ] && { sed -n "s/^HDR='\(.*\)'$/\1/p" checks/brief.sh; printf '\n'; }
    printf '## 1 rows\n\n'
    for _r in "$@"; do sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | grep -E "^[[:space:]]*$_r[[:space:]]*\|"; done
    _ty=iterate; [ "$_ro" = test-author ] && _ty=prove-red
    printf '\n## 6 test requests\n\nsh checks/test.sh request --type %s --role %s --rows %s --why "the brief'"'"'s rows" -- tests/invariants\nsh checks/test.sh wait <ticket>\n' "$_ty" "$_ro" "$(echo "$@" | tr ' ' ',')"; } > "$_bf"
}
