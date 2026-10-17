# Purpose: selftest fixture — a row's authority (v0.9.8 spec 3.3, R5, R6). Sourced after brief-write.sh (Env: CHECKS,
# T). au_repo <dir>: the brief-write toy plugin and repository, then its records replaced at one commit: PRD.md with
# two items (REQ-001 citing A-001 in its source:, REQ-002 citing A-002) and an answers block, A-001 restated AMENDED in
# an append; INVENTORY.md with ROW-201 (REQ-001, marker P01/empty, divergence: DIF-001) and ROW-202 (REQ-002); and
# DECISIONS.md with D-301 citing REQ-001, D-302 labelled applies-to P01, D-303 applies-to DIF-001, D-304 scope:
# project, D-305 citing no id and unlabelled, D-306 citing REQ-002; and design/screens/p01.html holding P01/empty.
# For ROW-201 the non-builder join gives D-301, D-302 and D-303 — never D-304 (builders only), D-305 or D-306.
au_prd() { # [<A-001's amended answer>] [<REQ-001's statement>]
  cat <<P
# Toy — PRD

grammar: 0.9.3

\`\`\`vid-prd
REQ-001 | functional | T1 | ${2:-A link lasts seven days.} | fail-if: a link works after seven days | serves: a stated lifetime | authority: authoritative | source: A-001 | phase: pilot | plain: a link lasts a week
REQ-002 | functional | T1 | A code is six characters. | fail-if: a code has another length | serves: short codes | authority: authoritative | source: A-002 | phase: pilot | plain: codes are short
\`\`\`

\`\`\`vid-prd-answers
A-001 | human | 2026-10-01 | Q: how long does a link last? | A: seven days | settles: REQ-001
A-002 | human | 2026-10-01 | Q: how long is a code? | A: six characters | settles: REQ-002
\`\`\`

## Appends

### Append 2026-10-05 (owner answer)

\`\`\`vid-prd-answers
A-001 AMENDED | human | 2026-10-05 | Q: how long does a link last? | A: ${1:-seven days, counted from creation} | settles: REQ-001
\`\`\`
P
}
au_dec() { # [<D-301's rule>] [<D-302's label>]
  printf '# DECISIONS\n\n'
  printf -- '- **D-301** %s | why: REQ-001 says so | enforced: convention\n' "${1:-REQ-001 counts the lifetime in whole seconds}"
  printf -- '- **D-302** the empty state shows one sentence | %s | why: nothing to list | enforced: convention\n' "${2:-applies-to: P01}"
  printf -- '- **D-303** the test lifetime is shortened | why: the clock | enforced: convention | applies-to: DIF-001\n'
  printf -- '- **D-304** every page uses one font | why: one look | enforced: convention | scope: project\n'
  printf -- '- **D-305** logs are plain text | why: simple | enforced: convention\n'
  printf -- '- **D-306** REQ-002 codes use a safe alphabet | why: no ambiguity | enforced: convention\n'
}
au_repo() {
  bw_plugin; bw_repo "$1"
  au_prd > PRD.md; au_dec > DECISIONS.md
  printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-201 | behavior | REQ-001 | anonymous | P01/empty | a link refuses after seven days | REQ-001 | tests/invariants/links.sh | divergence: DIF-001 | proved-red: %s\nROW-202 | behavior | REQ-002 | anonymous | n/a | a code is six characters | REQ-002 | tests/invariants/links.sh | proved-red: %s\n```\n' "$(git rev-parse --short=12 HEAD)" "$(git rev-parse --short=12 HEAD)" > INVENTORY.md
  mkdir -p design/screens; printf '<section data-marker="P01/empty">nothing yet</section>\n' > design/screens/p01.html
  printf '# Purpose: toy ledger\ntest_ROW_201() { :; }\ntest_ROW_202() { :; }\n' > tests/invariants/links.sh
  cp "$CHECKS/event.sh" checks/
  g add -A && g commit -qm 'the authority records'
}
# au_ids <brief> <section>: the D-, A- or ROW- ids that open the section's lines, sorted
au_ids() { awk -v n="$2" '/^## [0-9]/ { on = ($2 == n); next } on' "$1" | grep -oE '^(- \*\*)?(D|A)-[0-9]+' | sed 's/^- \*\*//' | sort -u | paste -sd ' ' -; }
# au_stamp: both rows' proved-red: stamps moved to HEAD, committed — the rows' baseline is then this commit
au_stamp() { H=$(git rev-parse --short=12 HEAD); sed "s/proved-red: [0-9a-f]*/proved-red: $H/" INVENTORY.md > i && mv i INVENTORY.md; g add INVENTORY.md && g commit -qm 'stamps'; }
# au_flags: the rows `inventory.sh --report` lists authority-changed, `<row> <what>` a line
au_flags() { VID_COURT_EVENT=off sh checks/inventory.sh --report 2>/dev/null | sed -n 's/^authority-changed row=\([^ ]*\) since=[^ ]* what=\(.*\)$/\1 \2/p'; }
# au_ts: the checks test-state reads, with the passing states taken from $T/states (VID_EVIDENCE_STATES)
au_ts() { cp "$CHECKS/metrics.sh" "$CHECKS/evidence.sh" checks/; [ -f checks/plan.sh ] || cp "$CHECKS/plan.sh" checks/; g add -A && g commit -qm 'the readers'; }
# au_attest <event> <row> <result> [<helpers>]: an attestation of the row at HEAD — commit, its test file's blob, the
# helpers' blobs, the obligation's cksum and the row's authority digest — appended to the events
au_attest() {
  _f=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' -v r="$2" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t); print t }')
  _o=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' -v r="$2" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { o = $6; gsub(/^[ \t]+|[ \t]+$/, "", o); print o }' | cksum | cut -d' ' -f1)
  _h=-; [ -n "${4:-}" ] && _h=$(for p in $(printf '%s\n' "$4" | tr ',' ' '); do printf '%s@%s,' "$p" "$(git rev-parse "HEAD:$p")"; done | sed 's/,$//')
  _d=$(sh checks/brief.sh authority --row "$2" | sed -n 's/^digest //p')
  mkdir -p .vid; printf '%s row=%s result=%s commit=%s file=%s blob=%s helpers=%s obligation=%s authority=%s at=2026-10-12T00:00:00Z\n' "$1" "$2" "$3" "$(git rev-parse --short=12 HEAD)" "$_f" "$(git rev-parse "HEAD:$_f")" "$_h" "$_o" "$_d" >> .vid/metrics-events
}
# au_state <row>: its test-state line's fields after the row id
au_state() { sh checks/metrics.sh test-state --rows "$1" | sed -n "s/^test-state row=$1 //p"; }
# au_more: rows ROW-203 (REQ-001, tests/invariants/other.sh), ROW-204 (REQ-009, tests/invariants/third.sh) and ROW-205
# (REQ-008, tests/invariants/fourth.sh), their files, and tests/invariants/helpers.sh, committed
au_more() {
  printf '# Purpose: a shared helper\nfresh() { :; }\n' > tests/invariants/helpers.sh
  for f in other third fourth; do printf '# Purpose: toy ledger %s\n' "$f" > "tests/invariants/$f.sh"; done
  printf 'test_ROW_203() { :; }\n' >> tests/invariants/other.sh; printf 'test_ROW_204() { :; }\n' >> tests/invariants/third.sh; printf 'test_ROW_205() { :; }\n' >> tests/invariants/fourth.sh
  awk '/^```$/ && !d { print "ROW-203 | behavior | REQ-001 | anonymous | n/a | a link answers before it expires | REQ-001 | tests/invariants/other.sh"
      print "ROW-204 | behavior | REQ-009 | anonymous | n/a | a deleted code never resolves | REQ-009 | tests/invariants/third.sh"
      print "ROW-205 | behavior | REQ-008 | anonymous | n/a | a sixty-first link is refused | REQ-008 | tests/invariants/fourth.sh"; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
  g add -A && g commit -qm 'three more rows'
}
