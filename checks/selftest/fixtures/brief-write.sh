# Purpose: selftest fixture — the brief writer's toy project (v0.9.7.0.5
# spec 3.3; §6 W-1…W-5). Sourced by a case after it has made $T (Env:
# CHECKS, T). bw_plugin makes a toy plugin root at $T/plugin — develop's
# role table, the grader's pass, the test-author's pass with its boundary
# rule — and exports CLAUDE_PLUGIN_ROOT to it, so the cases never depend
# on ViD's own skills (a project runs them too). bw_repo <dir> copies the
# brief-verdict fixture there, adds the two law sections its CLAUDE.md
# lacks and a GRADING-CHECKLIST.md, copies brief.sh and prd.sh, commits,
# and enters it. bw_out: the path the last `write` printed.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
HDR='Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role — `vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose for a role without one) with no authoring-session and no build-session context. It receives only what this file lists under `receives:` and nothing under `must not receive:`; a re-run is never told the previous verdict; a pass whose prompt carries anything the calling session believes is VOID and is re-spawned. Independence is a mechanism here, not a property.'
EXCL='Do not read under `.vid/` beyond the receipt named above.'
bw_plugin() {
  P="$T/plugin"; mkdir -p "$P/skills/vid-develop" "$P/skills/vid-verify/passes" "$P/skills/vid-test-inventory/passes" "$P/skills/vid-test-writing"
  cat > "$P/skills/vid-develop/SKILL.md" <<'SK'
# toy develop

## Spawned roles

| role | receives | must not receive |
|---|---|---|
| builder | 1–3, 5–12 | another batch's brief or verdicts |
| fixer | 1–8 (7 carries the counterexample) | another batch's brief |
| grader (slice close) | 1–6; the toy grader's extras | item 7; `.vid/verdicts/` |
| test-author | what the toy pass lists | what it lists |

## Slice close
SK
  { printf '%s\n\n' "$HDR"; printf '# toy grader pass\n\nOne verdict per row against its Fail-if.\nReturn one line per row: ROW-<id> | KEPT|BREACHED|ROW-AMBIGUOUS | class=<…> | <evidence>\n'; } > "$P/skills/vid-verify/passes/grader.md"
  { printf '%s\n\n' "$HDR"; printf '# toy test-author pass\n\nWhat the role receives and returns.\n'; } > "$P/skills/vid-test-inventory/passes/test-author.md"
  printf '# toy test-writing skill\n\n**The boundary rule (R6), verbatim:** *A promise is proved at the\ncheapest boundary that observes it.*\n\nThe rest of the craft.\n' > "$P/skills/vid-test-writing/SKILL.md"   # v0.9.8 (R1): the craft moved here
  CLAUDE_PLUGIN_ROOT=$P; export CLAUDE_PLUGIN_ROOT
}
bw_repo() {
  mkdir -p "$1"; cd "$1"; git init -q
  cp -R "$CHECKS/selftest/fixtures/brief-verdict/tree/." .
  mkdir -p checks; cp "$CHECKS/brief.sh" "$CHECKS/prd.sh" checks/
  printf '\n## Import law\n\n- Every import crosses a seam the table declares.\n\n## Law-change rule (law, §4.1)\n\n- A law change is its own standalone commit.\n' >> CLAUDE.md
  printf '# Linkling — GRADING CHECKLIST\n\n## Standing lines (every project)\n\n- A refusal stores nothing.\n' > GRADING-CHECKLIST.md
  printf '.vid/\n' > .gitignore
  g add -A && g commit -qm root
}
# v0.9.7.1 (3.2c): a builder's or fixer's brief needs the run manager's selection; the toy's is its ledger folder
bw_write() {
  case " $* " in *' --role builder '*|*' --role fixer '*) case " $* " in *' --selection '*) ;; *) set -- "$@" --selection tests/invariants ;; esac ;; esac
  sh checks/brief.sh write "$@" > "$T/wout" 2>&1; }
bw_out() { sed -n 's/^ViD brief write: //p' "$T/wout" | head -n 1; }
# v0.9.7.0.7 (3.2; §6 B-1…B-6) — bw_builder, after bw_repo: the toy gains what a builder brief
# joins. INVENTORY markers (ROW-101 P01/empty, ROW-102 P02/populated, ROW-104 P03/form), a row
# ROW-120 whose id extends ROW-12's, rule rows citing REQ-004, REQ-0041 and nothing, a surface
# ledger file whose parameter table names ROW_104 and ROW-120, decisions naming screen codes,
# ARCHITECTURE rows `tests.invariants` and `app/other`, and a kept plan in force (.vid/plans/
# <hash>.plan with its plan-change event): S1 (modules app/, rows 101 102), S2 (modules app
# tests/invariants/, builds on S1, rows 104 120 105).
bw_builder() {
  sed -e 's#^\(ROW-101 | behavior | REQ-001 | anonymous | \)n/a#\1P01/empty#' \
      -e 's#^\(ROW-102 | behavior | REQ-002 | anonymous | \)n/a#\1P02/populated#' \
      -e 's#^\(ROW-104 | behavior | REQ-004 | anonymous | \)n/a#\1P03/form#' INVENTORY.md > INVENTORY.new
  awk '/^```$/ && !d { print "ROW-120 | surface | /delete/ | anonymous | P03/form | the deletion form wears its marker and token field | REQ-004 | tests/invariants/surfaces.sh"
      print "rule | RULE-001 | a deletion never succeeds without the token | checks/extractors/invariant.token.sh | 0 | owed: census-armed — armed with the first deletion site | origin: REQ-004"
      print "rule | RULE-002 | every limit counts characters | checks/extractors/invariant.limit.sh | 0 | owed: census-armed — armed with the first limit | origin: REQ-0041"
      print "rule | RULE-003 | every store write is atomic | checks/extractors/invariant.atomic.sh | 0 | owed: census-armed — armed with the first write | "; d = 1 } { print }' INVENTORY.new > INVENTORY.md
  rm -f INVENTORY.new
  printf '# Purpose: surface ledger (toy) — one case per screen row, from the table below.\nSURFACES="\nROW_104 P03/form token-field\nROW-120 P03/form marker\n"\n' > tests/invariants/surfaces.sh
  cat >> DECISIONS.md <<'DEC'
- **D-201** the P03 form keeps its token field last | why: the eye ends on the secret | enforced: convention
- **D-202** the P01 empty state shows one sentence | why: nothing else to say | enforced: convention
- **D-203** the P01 notice repeats REQ-004's wording | why: one wording | enforced: convention
- **D-204** P01 and P03 share one header | why: one layout | enforced: convention
DEC
  printf '| tests.invariants | the ledger | none | none | - |\n| app/other | an unrelated module | none | none | - |\n' >> ARCHITECTURE.md
  g add -A && g commit -qm builder
  mkdir -p .vid/plans
  printf 'step S1 | name: links | modules: app/ | builds-on: - | rows: ROW-101 ROW-102 | lane: builder\nstep S2 | name: deletion | modules: app tests/invariants/ | builds-on: S1 | rows: ROW-104 ROW-120 ROW-105 | lane: builder\nshared: tests/invariants/harness.sh\n' > .vid/plans/0123456789ab.plan
  printf 'plan-change what=create hash=0123456789ab decision=x why="toy" at=2026-10-02T10:00:00Z\n' >> .vid/metrics-events
}
# v0.9.7.0.7 (3.3; §6 C-1…C-4) — bw_return, after bw_builder: the hand-back's toy run. checks/
# gains evidence.sh and event.sh; a builder brief for S1 (ROW-101, ROW-102) is written as
# .vid/briefs/1/builder-1.md; three receipts in .vid/ledger-results/ with .tree and .cases: GREEN
# (both rows' cases passed) and RED (ROW-101's case failed), each named by a ledger-run event, and
# STRAY (both passed, no event). bw_transcript <file> <cwd> <kind> writes an agent transcript in
# Claude Code's shape: kind `edit` — calls of context 1502, 3000 (a failed Edit under app/, and, on
# a second line of the same message, a Bash naming app/ with no write), 5000 (an Edit under app/
# that succeeds) and 4000 (a Write outside the modules, its text holding an escaped usage), so peak
# 5000, total 13502, before-change 5000; `shell` — the same with a call of 2500 before, a Bash
# writing into app/ (`> app/links.sh`), so before-change `2500 shell`; `none` — no product
# mutation, so before-change unknown. bw_agent <id> <kind>: the transcript under a parent path
# and the agent-start event naming it.
bw_return() {
  cp "$CHECKS/evidence.sh" "$CHECKS/event.sh" checks/; g add -A && g commit -qm 'evidence and events'
  bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || { cat "$T/wout" >&2; return 1; }
  R=.vid/ledger-results; mkdir -p "$R"; S=$(git rev-parse --short=12 HEAD); TRE=$(git rev-parse 'HEAD^{tree}')
  for k in GREEN RED STRAY; do
    printf '<report/>\n' > "$R/$S.run-$k.xml"; printf 'tree=%s\nbase=%s\nshape=inline\n' "$TRE" "$S" > "$R/$S.run-$k.xml.tree"
    a=passed; [ $k = RED ] && a=failed
    printf 'case tests/invariants/links.sh::test_row101[ROW-101] %s 0.1\ncase tests/invariants/links.sh::test_row102[ROW-102] passed 0.1\n' "$a" > "$R/$S.run-$k.xml.cases"
  done
  for k in GREEN RED; do printf 'ledger-run seconds=3 kind=scoped report=%s.run-%s.xml status=0 role=builder at=2026-10-02T11:00:00Z\n' "$S" "$k" >> .vid/metrics-events; done
  GREEN=$S.run-GREEN.xml; RED=$S.run-RED.xml; STRAY=$S.run-STRAY.xml
}
bw_transcript() { # $1=file $2=cwd $3=kind
  _c=$2
  a() { printf '{"parentUuid":"p","isSidechain":true,"agentId":"x","message":{"model":"m","id":"%s","type":"message","role":"assistant","content":[%s],"stop_reason":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":%s,"ephemeral_1h_input_tokens":0},"output_tokens":9}},"type":"assistant","uuid":"u","cwd":"%s"}\n' "$1" "$2" "$3" "$4" "$3" "$_c"; }
  r() { printf '{"parentUuid":"p","isSidechain":true,"type":"user","message":{"role":"user","content":[{"tool_use_id":"%s","type":"tool_result","content":"%s","is_error":%s}]},"uuid":"u","cwd":"%s"}\n' "$1" "$2" "$3" "$_c"; }
  tu() { printf '{"type":"tool_use","id":"%s","name":"%s","input":%s}' "$1" "$2" "$3"; }
  # the inputs are built in variables first: a "{…,…}" inside "$(…)" is brace-expanded by some shells
  _e1="{\"file_path\":\"$_c/app/links.sh\",\"old_string\":\"a\",\"new_string\":\"b\"}"
  _e2="{\"file_path\":\"$_c/app/links.sh\",\"old_string\":\"b\",\"new_string\":\"c\"}"
  _w="{\"file_path\":\"$_c/docs/notes.md\",\"content\":\"\\\"usage\\\":{\\\"input_tokens\\\":999999}\"}"
  {
    printf '{"parentUuid":null,"isSidechain":true,"type":"user","message":{"role":"user","content":"Your brief: .vid/briefs/1/builder-1.md"},"uuid":"u","cwd":"%s"}\n' "$_c"
    a msg_1 "$(tu toolu_1 Read '{"file_path":".vid/briefs/1/builder-1.md"}')" 500 1000; r toolu_1 'the brief' false
    if [ "$3" = shell ]; then a msg_s "$(tu toolu_s Bash '{"command":"printf x > app/links.sh 2>/dev/null"}')" 500 1998; r toolu_s '' false; fi
    if [ "$3" != none ]; then
      a msg_2 "$(tu toolu_2 Edit "$_e1")" 1000 1998; r toolu_2 '<tool_use_error>String to replace not found</tool_use_error>' true
      a msg_2 "$(tu toolu_3 Bash '{"command":"ls app/ 2>/dev/null; grep -n link app/links.sh 2>&1"}')" 1000 1998; r toolu_3 'links.sh' false
      a msg_3 "$(tu toolu_4 Edit "$_e2")" 2000 2998; r toolu_4 'The file has been updated.' false
    else
      a msg_2 "$(tu toolu_3 Bash '{"command":"ls app/"}')" 1000 1998; r toolu_3 'links.sh' false
      a msg_3 "$(tu toolu_4 Read '{"file_path":"app/links.sh"}')" 2000 2998; r toolu_4 'text' false
    fi
    a msg_4 "$(tu toolu_5 Write "$_w")" 1000 2998; r toolu_5 'File created' false
  } > "$1"
}
bw_agent() { # $1=agent id $2=kind
  _p="$T/projects/the session.jsonl"; mkdir -p "${_p%.jsonl}/subagents"; : > "$_p"
  bw_transcript "${_p%.jsonl}/subagents/agent-$1.jsonl" "$(pwd -P)" "$2"
  printf 'agent-start session=S1 agent=%s type=general-purpose transcript="%s" at=2026-10-02T11:00:00Z\n' "$1" "$_p" >> .vid/metrics-events
}
