#!/bin/sh
# Purpose: ViD develop's plan and its gate (v0.9.6 spec 3.1–3.6; R1, R2,
# R4–R6). Develop's alone: every other verb finds the gate off.
#   gate               prints `on <the run's home>` and exits 0 when a 0.9.6
#                      develop run is in progress, else `off <why>` and exit
#                      1. The run's HOME is the worktree whose
#                      .vid/RUN-STATE.md holds the run — this worktree when
#                      it has one, else the path its .vid/home names. The
#                      gate needs, at the home: RUN-STATE's `plan: required`
#                      (written by 0.9.6 develop at its start); `run:` active
#                      or waiting (a `stopped …` run, the owner's pause
#                      included, and a `complete` run are off); and the
#                      newest `stage … state=start` event (by its last
#                      `at=`, file order breaking a tie) is `stage
#                      name=develop`, with no `stage name=develop state=end`
#                      after it. A worktree with neither RUN-STATE nor
#                      .vid/home has no gated run — unless, from v0.9.7.0.1,
#                      home-of finds the one live run among the repository's
#                      checkouts (two or more: `off ambiguous …`, exit 3).
#                      checks/test.sh and
#                      checks/hooks/post-commit read it; nothing else changes
#                      when it is off.
#   home-of            v0.9.7.0.1 (3.1, R1–R4): the one home resolver —
#                      plan.sh, event.sh, run.sh and hooks/record.sh find the
#                      home through it. Prints the home's absolute path and
#                      exits 0, or prints why there is none and exits 1, or
#                      names the live runs and exits 3 when there are two or
#                      more. In order: (1) this checkout's top level when it
#                      holds .vid/RUN-STATE.md (stale or not); (2) the path
#                      .vid/home names, when that holds .vid/RUN-STATE.md;
#                      (3) only when 1 and 2 find nothing: each checkout of
#                      `git worktree list` (the main one included) whose
#                      RUN-STATE passes the gate — exactly one is the home,
#                      none is no home, two or more is ambiguous. `gate`
#                      prints `off ambiguous …` and exits 3 then; the
#                      admission, the other gated subcommands and redstamp
#                      refuse (exit 1) instead of reading it as "rules off".
#                      Outside a live run nothing is discovered: records
#                      stay local.
#                      v0.26.10.3 (R8, F-42): a stopped run still owns its live
#                      agents. With `run: stopped …` (the stage still
#                      develop's), `gate` read in a checkout other than the
#                      home answers `on <home>` only when a live agent or an
#                      unfinished Codex job of that run is bound to this
#                      checkout's branch (checks/testenv.sh bound: R10's one
#                      rule); home-of's step 3 also finds that home for such a
#                      checkout. The home itself, and a checkout with only a
#                      .vid/home path and no live agent bound, read it off.
#   home --brief <f>   a builder worktree records its run's home in .vid/home:
#                      the worktree holding the brief file <f>. The builder
#                      runs it as its first act; receipts, events and the
#                      post-commit `amended` events then land at the home.
# v0.9.6 (3.1–3.5, Phase D) — the plan block and the two rules:
#   check              validates the ```vid-plan block in RUN-STATE's "## The
#                      plan" section; exits 1 naming the line on: a line that
#                      does not parse; a step without name:, modules: or rows:;
#                      an unknown id in builds-on:, or a cycle; a row in two
#                      steps, or not a row of INVENTORY.md (a range ROW-a..ROW-b
#                      expands, every row in it must exist); no shared: line.
#                      Overlapping module prefixes are not refused.
#                      v0.9.7.0.9 (3.6, R7): a step's lane: is `builder`,
#                      absent (read as builder) or `orchestrator (<why>)`
#                      with a non-empty reason; check and change refuse a
#                      bare `orchestrator` — `step <id>: lane orchestrator
#                      needs its reason — lane: orchestrator (<why>)` — and
#                      any other lane. The reader keeps the lane as written.
#   change <what> "<why>"   the one way a plan change is accepted: validates
#                      the block, refuses a change that leaves a row of a
#                      started step in no step (unless owed, held or later),
#                      and admits rows added to a started step like a new
#                      step (rules A and B below — a refusal keeps the old
#                      hash); then copies the block to .vid/plans/<hash>.plan
#                      (kept, never edited) and writes `plan-change
#                      what=<create|add|drop|split|merge|reorder|lanes|rows|other>
#                      hash=<12 hex> why="<one line>"`. `other` naming
#                      `unverified-rows=<n>` raises the budget to n.
#                      v0.9.7.0.11 (3.8, R8): a started step's charge is
#                      cumulative — its start plan's rows plus every row an
#                      accepted change added to it (each recorded plan after
#                      its start); rule A and the orphan check use it. A
#                      change admits under rule B only the rows a started
#                      step gains against the same step of the last recorded
#                      plan; with none recorded, against the start plans.
#   start <id>         the orchestrator's admission of a step it builds
#                      itself, at HEAD's tree.
#                      v0.9.7.0.11 (3.8a, R16): admission's "changed without
#                      a recorded change" compares, when the raw hashes
#                      differ, the block and the last recorded plan in
#                      canonical form (each step's rows: a sorted set, runs
#                      of whitespace one space); equal is unchanged and the
#                      recorded hash is used. Step order still counts;
#                      hashes stay raw.
#   admit --brief <f>  a builder or fixer brief's admission (checks/brief.sh
#                      calls it): the brief's `step:` must name a step and its
#                      `## 1` rows must all be that step's; judged at the tree
#                      of its `quoted-at` commit. Other roles are outside the
#                      rules.
#   Admission (start, admit), inside the gate only: the block's hash must
#   equal the latest `plan-change` event's; a started step (a `step-start`
#   event names it) is always admitted; a step made only of rows that already
#   belonged to a started step is admitted without either rule; otherwise it
#   is refused while the checking worktree has uncommitted changes on the
#   step's currency paths, and RULE B: every step in its builds-on: must be
#   passing — each row passing on current results (checks/evidence.sh) or
#   owed, held or later; RULE A: the rows of started steps not passing, with
#   the new step's rows not passing, each counted once, must stay within
#   .vid/budget unverified-rows (default 60). The first admission writes
#   `step-start step=<id> plan=<hash>`. A refusal names the gap. Nothing is
#   judged at commit (spec 9.18). v0.9.6.2 (3.4, R4): rules A and B, dirty
#   currency paths, an unrecorded plan hash, a step not in the plan and, for
#   admit, rows not of the step each also write `refused phase=admission
#   by=<rule> attempt=<id> step=<id>` at the home.
#   v0.26.10.5 (R6): with STAGES.md at the home, admission (start, admit)
#   first refuses a step holding a row outside stages 1 to the current one
#   (RUN-STATE's `stage:`; checks/stages.sh scope) — started or not, with
#   no exception for a pull-forward — `refused … by=stage`.
#   map [--all]        the currency map checks/evidence.sh reads (`<row>
#                      <step> <paths>`): the block's rows, and every row that
#                      ever belonged to a started step (rebuilt from
#                      .vid/plans/ and the step-start events); --all adds
#                      every other INVENTORY row. v0.9.6.1 (3.4, R4): every
#                      row's set of paths is EMPTY — a row's result goes
#                      stale only on its own test path or its amendment,
#                      which checks/evidence.sh adds itself; a change under a
#                      step's modules, those it builds on, or the shared
#                      paths no longer re-opens a passed row. Rules A and B,
#                      the claim and the progress update read this one rule.
#                      (The admission's refusal of uncommitted changes on a
#                      step's currency paths is unchanged.)
#   parse [<file>]     the block (or a kept plan file) normalised, or its
#                      refusals.
#   redstamp --staged  the pre-commit hook's one gated call (v0.9.6 3.11,
#                      R11): a ROW row whose `proved-red:` stamp is new or
#                      changed in the staged INVENTORY.md is refused unless the
#                      newest `red-observed row=<id> report=<receipt>
#                      case=<case id> assertion="…"` event for it names a valid
#                      receipt (published by checks/test.sh, not invalidated)
#                      in which that case's status is `failed` — never
#                      `error` (setup or collection) and never absent. Which
#                      assertion is the row's promise stays the orchestrator's
#                      judgment, recorded in the event. Outside the gate it is
#                      off (a 0.9.5 run: one note, never a refusal).
# v0.9.6.2 (3.3, R3) — every plan change is a decision, recorded:
#   change <what> "<why>" --trigger <t>[,<t>…] [--evidence <ref>[,<ref>…]]
#          --expect "<one line>" [--alternatives "<one line>"]
#                      under the gate --trigger and --expect are required.
#                      Triggers: initial test-evidence owner-answer
#                      agent-failure cost discovered-dependency scope-change
#                      gate-refusal unknown; any but initial and unknown needs
#                      a reference. A reference must exist: receipt:<name>[#<case>]
#                      (a file in .vid/ledger-results/, the case in its .cases),
#                      question:Q<n> (a `question n=<n>` event), agent:<id> (an
#                      `agent-start` event), refusal:<attempt> (a `refused`
#                      event), step:<id> (a step of the candidate or the last
#                      accepted plan), commit:<sha>. Accepted or refused, the
#                      change writes .vid/plans/decisions/<id>.why once (id=,
#                      at=, result=accepted|refused, what=, prev= the last
#                      accepted plan's hash or none, candidate= the raw block's
#                      hash taken before any validation, commit= HEAD, trigger=,
#                      evidence=, expect=, alternatives=, and refusal=<first
#                      line> when refused) and keeps the candidate block whole
#                      as <id>.plan beside it. The id is the UTC time plus the
#                      candidate hash (`-2`, `-3` … when that id is taken). A
#                      refusal writes no plan-change event and the plan keeps
#                      its recorded hash; an accepted change's `plan-change`
#                      carries decision=<id>. Outside the gate, a note as
#                      before, whatever the arguments.
#   charged            every row that ever belonged to a started step, as
#                      `<row> <step> <plan hash>` — rebuilt from the events
#                      and .vid/plans/, never from RUN-STATE.
# v0.9.6.1 (3.5, R5): the first admission writes `step-start step=<id>
#   plan=<hash> base=<commit>`, the commit HEAD at admission (12 hex).
#   base <id>          prints `base step=<id> commit=<sha> from=<source>`: the
#                      commit a step's diff starts from — the `base=` of its
#                      first `step-start` (from=step-start); for a step started
#                      before 0.9.6.1, the `quoted-at` of its first builder (or
#                      fixer) brief — first by its `brief-check … result=ok`
#                      event, then by path (from=brief); failing that, the
#                      commit HEAD was on at the `step-start` time
#                      (from=step-start-time). Refused for a step never started.
# v0.9.7.2 (3.1–3.5; R1–R7) — breadth first, the owner's strategy:
#   strategy <depth-first|breadth-first> --by owner --words "<the owner's words>"
#                      sets RUN-STATE's `strategy:` (missing: depth first) —
#                      refused without both; the words kept verbatim in
#                      .vid/plans/decisions/<id>.why; records `strategy
#                      set=<s> by=owner decision=<id>`. Setting breadth first
#                      runs the breadth-first checks below on the plan in the
#                      block, when there is one; depth first is always
#                      allowed, and then every marker below is inert.
#   A step line may end `| kind: hardening`; the parsed step line gains it as
#   its 7th column (`-` for a feature step), so every reader keeps its
#   columns. The block may carry one `protected: <ROW ids or ranges>` line,
#   parsed as `prot <id>` lines; `change` refuses a change that removes an id
#   from it, under either strategy (it only grows).
#   Under breadth first (`check`, `change`, `strategy breadth-first`): nothing
#   builds on a hardening step; no protected row — `sh checks/inventory.sh
#   protected` at the home, plus the protected: line — sits in any hardening
#   step, whatever the reason. `change` works out the rows newly in a
#   hardening step against the last recorded plan (PREV; none at create): a
#   change placing any needs what=edge. For each such row whose verdicts hold
#   an open product BREACHED (checks/metrics.sh step-state: any transition,
#   amendments applied, no class read as product), every feature step that
#   built on its PREV step directly and is not done must be named in `--not-needed-by
#   <id>[,<id>…] "<why>"` (a partial list is refused); the ids and the why
#   go in the decision and the event (`not-needed-by=`). Rule A leaves out
#   charged rows parked in an unstarted hardening step (R6); a hardening
#   step's own admission counts its parked rows as new (rule A runs even when
#   all its rows are charged). The graded gate (R7, the owner's option b):
#   admitting any new step needs each step in its builds-on closed at its
#   current rows and graded (metrics.sh step-state) — a split of charged rows
#   too; a started step is never refused. A refusal names the rows and is
#   recorded `refused … by=graded`.
# Usage: sh checks/plan.sh gate | home-of | home --brief <f> | check | change <what> "<why>" [--trigger … --expect … ] [--not-needed-by <ids> "<why>"] | strategy <s> --by owner --words "<…>" | start <id> | admit --brief <f> | map [--all] | charged | base <id> | parse [<file>] | redstamp --staged
set -u
IFS='
'
usage() { echo 'ViD plan: usage — sh checks/plan.sh gate | home-of | home --brief <f> | check | change <what> "<why>" --trigger <t>[,<t>…] [--evidence <ref>[,<ref>…]] --expect "<one line>" [--alternatives "<one line>"] [--not-needed-by <id>[,<id>…] "<why>"] | strategy <depth-first|breadth-first> --by owner --words "<the owner'"'"'s words>" | start <id> | admit --brief <f> | map [--all] | charged | base <id> | parse [<file>] | redstamp --staged' >&2; exit 2; }
top() { git rev-parse --show-toplevel 2>/dev/null || pwd -P; }
# bound_here <home>: this checkout's branch has a live agent or an unfinished Codex job of the run at <home> bound to it
# (v0.26.10.3 R8, R10: checks/testenv.sh bound, the one liveness rule; without it, nothing is bound)
bound_here() {
  _bt="$(dirname "$0")/testenv.sh"; [ -f "$_bt" ] || return 1
  _bb=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) && [ -n "$_bb" ] && [ "$_bb" != HEAD ] || return 1
  sh "$_bt" bound --home "$1" --branch "$_bb" > /dev/null 2>&1
}
# home_of: the run's home, absolute (exit 0); nothing (exit 1); the live runs, one per line (exit 3)
home_of() {
  _t=$(top)
  if [ -f "$_t/.vid/RUN-STATE.md" ]; then printf '%s\n' "$_t"; return 0; fi
  if [ -f "$_t/.vid/home" ]; then
    _h=$(sed -n 1p "$_t/.vid/home")
    if [ -n "$_h" ] && [ -f "$_h/.vid/RUN-STATE.md" ]; then printf '%s\n' "$_h"; return 0; fi
  fi
  # v0.9.7.0.1 (3.1, R1, R2): the one live run among the repository's checkouts; v0.26.10.3 (R8): a stopped run's home
  # too, for a checkout a live agent or job of that run is bound to (bound_here)
  _live=''; _n=0
  for _w in $(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do
    [ -f "$_w/.vid/RUN-STATE.md" ] || continue
    if ! gate_at "$_w" >/dev/null 2>&1; then
      gate_at "$_w" stopped >/dev/null 2>&1 && [ "$(cd "$_w" 2>/dev/null && pwd -P)" != "$(cd "$_t" && pwd -P)" ] && bound_here "$_w" || continue
    fi
    _live="$_live$_w
"; _n=$((_n + 1))
  done
  [ "$_n" -eq 0 ] && return 1
  printf '%s' "$_live"
  [ "$_n" -eq 1 ] && return 0
  return 3
}
# gate_at <home> [stopped]: exit 0 when on; prints the reason when off. With `stopped`, a `run: stopped …` passes too
# (v0.26.10.3 R8: the rest of the rule unchanged) — read only for a checkout a live agent of that run is bound to.
gate_at() {
  _rs="$1/.vid/RUN-STATE.md"; _ev="$1/.vid/metrics-events"
  [ "$(sed -n 's/^plan:[[:space:]]*//p' "$_rs" | head -n 1 | sed 's/[[:space:]]*$//')" = required ] || { echo 'no plan: key — a 0.9.5 run, or not develop; rules off'; return 1; }
  _run=$(sed -n 's/^run:[[:space:]]*//p' "$_rs" | head -n 1 | awk '{ print $1 }')
  case "$_run" in active|waiting) ;; stopped) [ "${2:-}" = stopped ] || { echo "run: stopped — the gate needs active or waiting"; return 1; } ;; *) echo "run: ${_run:-none} — the gate needs active or waiting"; return 1 ;; esac
  [ -f "$_ev" ] || { echo 'no events — no develop stage has started'; return 1; }
  _st=$(awk 'function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
    function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "stage" { a = lastat(); if (a == "") a = "0000"; printf "%s\t%09d\t%s\t%s\n", a, NR, kv("name"), kv("state") }' "$_ev" | sort -t "$(printf '\t')" -k1,1 -k2,2n \
    | awk -F'\t' '$4 == "start" { last = $3; ended = 0; next } $3 == "develop" && $4 == "end" && last == "develop" { ended = 1 } END { if (last != "develop") print "other:" last; else if (ended) print "ended"; else print "develop" }')
  case "$_st" in
    develop) return 0 ;;
    ended) echo 'the develop stage has ended'; return 1 ;;
    *) echo "the verb in progress is ${_st#other:} — not develop"; return 1 ;;
  esac
}


# --- v0.9.6 Phase D: the plan block ------------------------------------------------
TMPD=''
tmpd() { [ -n "$TMPD" ] || { TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT; }; }
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
h256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -c1-12; else sha256sum | cut -c1-12; fi; }
# block <RUN-STATE>: the vid-plan block's lines, trailing space trimmed
block() { awk '/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b { print }' "$1" | sed 's/[[:space:]]*$//'; }
# canon: a plan block in canonical form (v0.9.7.0.11 3.8a, R16) — runs of whitespace one space, each step line's rows: a
# sorted set; step order and every other field as they are
canon() { awk '{ gsub(/[ \t]+/, " "); sub(/^ /, ""); sub(/ $/, "") }
  /^step / { n = split($0, f, "|"); o = ""
    for (i = 1; i <= n; i++) { x = f[i]; sub(/^ /, "", x); sub(/ $/, "", x)
      if (x ~ /^rows:/) { m = split(substr(x, 6), r, " "); k = 0; split("", u)
        for (j = 1; j <= m; j++) if (r[j] != "" && !(r[j] in u)) { u[r[j]] = 1; v[++k] = r[j] }
        for (a = 2; a <= k; a++) { t = v[a]; b = a - 1; while (b > 0 && v[b] > t) { v[b + 1] = v[b]; b-- } v[b + 1] = t }
        x = "rows:"; for (j = 1; j <= k; j++) x = x " " v[j] }
      o = o (i > 1 ? " | " : "") x }
    print o; next }
  { print }'; }
# events <type>: that type's lines at the home, in time order (file order breaks a tie)
events() { [ -f "$H/.vid/metrics-events" ] || return 0; awk -v t="$1" "$AWKAT"' $1 == t { a = lastat(); if (a == "") a = "0000"; printf "%s\t%09d\t%s\n", a, NR, $0 }' "$H/.vid/metrics-events" | sort -t "$(printf '\t')" -k1,1 -k2,2n | cut -f3-; }
evkv() { printf '%s\n' "$1" | awk "$AWKAT"' { print kv("'"$2"'") }'; }
invids() { [ -f "$H/INVENTORY.md" ] && sed -n '/^```vid-inventory/,/^```$/p' "$H/INVENTORY.md" | sed '1d;$d' | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); print id }'; }
# parse_block <block file> <inventory ids file or ''>: normalised lines, or ERR lines (exit 1)
parse_block() {
  awk -v invf="$2" -v lanechk="${LANECHK:-}" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function err(m) { print "ERR\tline " NR ": " m; bad = 1 }
    function erre(m) { print "ERR\t" m; bad = 1 }
    function put(r, s, pr) { if (pr) { if (chk && !(r in INV)) err("protected: " r " is not a row of INVENTORY.md"); if (!(r in PROT)) { PROT[r] = 1; PO[++npo] = r } } else addrow(r, s) }
    # toks: a rows: or protected: value — ROW ids and ranges ROW-a..ROW-b
    function toks(rw, s, pr,   m, t, q, tok, ra, rb, da, db, w, lo, hi, v) { m = split(rw, t, /[ \t]+/)
      for (q = 1; q <= m; q++) { tok = t[q]; if (tok == "") continue
        if (tok ~ /^ROW-[0-9]+\.\.ROW-[0-9]+$/) { ra = tok; sub(/\.\..*/, "", ra); rb = tok; sub(/.*\.\./, "", rb); da = substr(ra, 5); db = substr(rb, 5); w = length(da); lo = da + 0; hi = db + 0
          if (hi < lo || hi - lo > 20000) { err((pr ? "protected:" : "step " s ":") " the range " tok " is backwards or too wide"); continue }
          for (v = lo; v <= hi; v++) put(sprintf("ROW-%0" w "d", v), s, pr) }
        else if (tok ~ /^ROW-[0-9A-Za-z-]+$/) put(tok, s, pr)
        else err((pr ? "protected:" : "step " s ":") " \047" tok "\047 is neither a ROW id nor a range ROW-a..ROW-b") } }
    function addrow(r, s) { if (r in RSTEP) { if (RSTEP[r] != s) err(r " is in two steps: " RSTEP[r] " and " s); return }
      if (chk && !(r in INV)) err(r " (step " s ") is not a row of INVENTORY.md"); RSTEP[r] = s; RORD[++nr] = r }
    function visit(s,   n, a, k) { if (COL[s] == 1) { cyc = s; return 1 } if (COL[s] == 2) return 0; COL[s] = 1
      n = split(BO[s], a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-" && (a[k] in SEEN)) if (visit(a[k])) return 1
      COL[s] = 2; return 0 }
    function reach(s, root,   n, a, k) { if ((root, s) in RCH) return; RCH[root, s] = 1
      n = split(BO[s], a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-" && (a[k] in SEEN)) reach(a[k], root) }
    BEGIN { if (invf != "") { chk = 1; while ((getline l < invf) > 0) INV[l] = 1 } }
    { line = $0 }
    line ~ /^[ \t]*$/ || line ~ /^[ \t]*#/ { next }
    line ~ /^[ \t]*shared:/ { v = line; sub(/^[ \t]*shared:[ \t]*/, "", v); v = trim(v); if (v == "") { err("shared: names no path"); next } nsh++; SH = SH (SH == "" ? "" : " ") v; next }
    line ~ /^[ \t]*protected:/ { v = line; sub(/^[ \t]*protected:[ \t]*/, "", v); v = trim(v)
      if (nprl++) { err("a second protected: line — the plan carries one, which only grows"); next }
      if (v == "") { err("protected: names no row"); next } toks(v, "", 1); next }
    line ~ /^[ \t]*step[ \t]/ {
      n = split(line, f, "|"); id = trim(f[1]); sub(/^step[ \t]+/, "", id); id = trim(id)
      if (id == "" || id ~ /[ \t]/) { err("a step line is: step <id> | name: … | modules: … | builds-on: … | rows: … | lane: … [| kind: hardening]"); next }
      if (id in SEEN) { err("step " id " is declared twice (an id is never reused)"); next }
      SEEN[id] = 1; ORD[++ns] = id
      nm = ""; md = ""; bo = ""; rw = ""; ln = ""; kd = ""
      for (k = 2; k <= n; k++) { x = trim(f[k]); if (x == "") continue
        if (x ~ /^name:/) nm = trim(substr(x, 6))
        else if (x ~ /^modules:/) md = trim(substr(x, 9))
        else if (x ~ /^builds-on:/) bo = trim(substr(x, 11))
        else if (x ~ /^rows:/) rw = trim(substr(x, 6))
        else if (x ~ /^lane:/) ln = trim(substr(x, 6))
        else if (x ~ /^kind:/) kd = trim(substr(x, 6))
        else err("step " id ": unknown field \047" x "\047") }
      if (nm == "") err("step " id " has no name:")
      if (md == "") err("step " id " has no modules:")
      if (rw == "") err("step " id " has no rows:")
      # v0.9.7.0.9 (3.6, R7): under check and change, a lane is builder, absent (read as builder) or orchestrator (<why>)
      if (lanechk && ln != "" && ln != "-" && ln != "builder") {
        lr = ln; if (lr ~ /^orchestrator[ \t]*\(.*\)$/) { sub(/^orchestrator[ \t]*\(/, "", lr); sub(/\)$/, "", lr); lr = trim(lr) } else lr = ""
        if (lr == "") { if (ln ~ /^orchestrator/) err("step " id ": lane orchestrator needs its reason — lane: orchestrator (<why>)")
          else err("step " id ": lane \047" ln "\047 is neither builder nor orchestrator (<why>)") } }
      # v0.9.7.2 (3.2, R2): kind: hardening, or absent (a feature step)
      if (kd != "" && kd != "hardening") err("step " id ": kind is hardening, or absent (a feature step) — not \047" kd "\047")
      NAME[id] = nm; MOD[id] = md; BO[id] = (bo == "" ? "-" : bo); LANE[id] = (ln == "" ? "-" : ln); KIND[id] = (kd == "" ? "-" : kd)
      toks(rw, id, 0)
      next }
    { err("does not parse — a line is `step <id> | …`, `shared: <paths>`, blank, or a # comment") }
    END {
      if (nsh == 0) erre("no shared: line — name the paths every step depends on (the harness, the fakes, the compose file, migrations)")
      for (i = 1; i <= ns; i++) { s = ORD[i]; n = split(BO[s], a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-" && !(a[k] in SEEN)) erre("step " s " builds on " a[k] ", which is no step of the plan") }
      for (i = 1; i <= ns; i++) if (visit(ORD[i])) { erre("builds-on: has a cycle through " cyc); break }
      if (bad) exit 1
      for (i = 1; i <= ns; i++) { s = ORD[i]; printf "step\t%s\t%s\t%s\t%s\t%s\t%s\n", s, NAME[s], MOD[s], BO[s], LANE[s], KIND[s] }
      printf "shared\t%s\n", SH
      for (i = 1; i <= ns; i++) { s = ORD[i]; reach(s, s); P = ""
        for (j = 1; j <= ns; j++) if ((s, ORD[j]) in RCH) { n = split(MOD[ORD[j]], a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && !((s, a[k]) in PD)) { PD[s, a[k]] = 1; P = P (P == "" ? "" : " ") a[k] } }
        n = split(SH, a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && !((s, a[k]) in PD)) { PD[s, a[k]] = 1; P = P (P == "" ? "" : " ") a[k] }
        printf "cur\t%s\t%s\n", s, P }
      for (i = 1; i <= nr; i++) printf "row\t%s\t%s\n", RORD[i], RSTEP[RORD[i]]
      for (i = 1; i <= npo; i++) printf "prot\t%s\n", PO[i]
    }' "$1"
}
# load_plan: the home's current block → $TMPD/block, $TMPD/parsed (or refusals on stderr, exit 1), PLANHASH
load_plan() {
  tmpd
  block "$H/.vid/RUN-STATE.md" > "$TMPD/block"
  [ -s "$TMPD/block" ] || { echo "ViD plan: refused — RUN-STATE has no \`\`\`vid-plan block under \"## The plan\"." >&2; return 1; }
  invids > "$TMPD/inv" || : > "$TMPD/inv"
  if ! parse_block "$TMPD/block" "$TMPD/inv" > "$TMPD/parsed"; then
    echo 'ViD plan: refused — the plan block does not hold:' >&2; sed -n 's/^ERR\t/    /p' "$TMPD/parsed" >&2; return 1
  fi
  PLANHASH=$(h256 < "$TMPD/block")
}
# started: the charged rows — every row that ever belonged to a started step — as `<row> <step> <plan>` in $TMPD/charged; started steps in $TMPD/started
# v0.9.7.0.11 (3.8, R8): the charge is cumulative — a started step's rows in its start plan, then its rows in every plan an
# accepted change recorded after its start (each a .vid/plans/<hash>.plan, named by its plan-change event), in time order
pplan() { [ -f "$TMPD/p.$1" ] || { [ -f "$H/.vid/plans/$1.plan" ] && parse_block "$H/.vid/plans/$1.plan" '' > "$TMPD/p.$1" 2>/dev/null; } || : > "$TMPD/p.$1"; }
started() {
  tmpd; : > "$TMPD/charged"; : > "$TMPD/started"
  [ -f "$H/.vid/metrics-events" ] && awk "$AWKAT"' $1 == "step-start" || $1 == "plan-change" { a = lastat(); if (a == "") a = "0000"; printf "%s\t%09d\t%s\n", a, NR, $0 }' "$H/.vid/metrics-events" | sort -t "$(printf '\t')" -k1,1 -k2,2n | cut -f3- > "$TMPD/sp"
  for l in $(cat "$TMPD/sp" 2>/dev/null); do
    case "$l" in
      step-start*)
        st=$(evkv "$l" step); ph=$(evkv "$l" plan); [ -n "$st" ] || continue
        printf '%s\n' "$st" >> "$TMPD/started"
        [ -n "$ph" ] || continue; pplan "$ph"
        awk -F'\t' -v s="$st" -v h="$ph" '$1 == "row" && $3 == s { print $2 "\t" s "\t" h }' "$TMPD/p.$ph" >> "$TMPD/charged" ;;
      plan-change*)
        ph=$(evkv "$l" hash); [ -n "$ph" ] && [ -s "$TMPD/started" ] || continue; pplan "$ph"
        awk -F'\t' -v h="$ph" -v sf="$TMPD/started" 'BEGIN { while ((getline x < sf) > 0) S[x] = 1 } $1 == "row" && ($3 in S) { print $2 "\t" $3 "\t" h }' "$TMPD/p.$ph" >> "$TMPD/charged" ;;
    esac
  done
  awk -F'\t' '!seen[$1]++' "$TMPD/charged" > "$TMPD/charged.u"; mv "$TMPD/charged.u" "$TMPD/charged"
  sort -u "$TMPD/started" -o "$TMPD/started"
}
# mkmap <out> [all]: the currency map — block rows by their step; charged rows no longer in the block by the plan they were admitted under; with `all`, every other INVENTORY row;
# v0.9.6.1 (3.4): each with an empty set of paths
mkmap() {
  awk -F'\t' -v pd="$TMPD" -v all="${2:-}" -v invf="$TMPD/inv" '
    BEGIN { while ((getline l < (pd "/parsed")) > 0) { split(l, a, "\t"); if (a[1] == "row") { RST[a[2]] = a[3]; ORD[++n] = a[2] } } }
    { CH[$1] = $2 "\t" $3; CO[++m] = $1 }
    END {
      for (i = 1; i <= n; i++) { r = ORD[i]; print r "\t" RST[r] "\t"; done[r] = 1 }
      for (i = 1; i <= m; i++) { r = CO[i]; if (r in done) continue; split(CH[r], a, "\t"); print r "\t" a[1] "@" a[2] "\t"; done[r] = 1 }
      if (all == "all") while ((getline r < invf) > 0) if (!(r in done)) { print r "\t-\t"; done[r] = 1 }
    }' "$TMPD/charged" > "$1" || { echo 'ViD plan: refused — the currency map could not be built.' >&2; return 1; }
}
# states <tree-ish>: $TMPD/states from checks/evidence.sh over $TMPD/map
states() { ( cd "$H" && sh checks/evidence.sh rows --at "$1" --map "$TMPD/map" ${VID_EVIDENCE_LEGACY:+--legacy} ) > "$TMPD/states" || { echo 'ViD plan: refused — checks/evidence.sh could not read the evidence.' >&2; return 1; }; }
okstate() { case "$1" in pass|owed|deploy-owed|held|later) return 0 ;; *) return 1 ;; esac; }
budget() {
  _b=''; _s=''; [ -f "$H/.vid/budget" ] && { _b=$(sed -n 's/^unverified-rows=\([0-9][0-9]*\).*/\1/p' "$H/.vid/budget" | tail -n 1); _s=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' "$H/.vid/budget" | head -n 1); }
  _base=$((60 * ${_s:-1})); [ -n "$_b" ] || _b=60
  if [ "$_b" -gt "$_base" ] && ! events plan-change | grep ' what=other ' | grep -q "unverified-rows=$_b\([^0-9]\|$\)"; then
    echo "ViD plan: note — .vid/budget unverified-rows=$_b was raised without a recorded \`plan-change what=other\` naming it; admitting under $_base." >&2; _b=$_base
  fi
  echo "$_b"
}
# v0.9.6.2 (3.4, R4): an admission refusal is recorded at the home —
# `refused phase=admission by=<dirty-currency|rule-B|rule-A|unrecorded-plan|no-step|rows-not-of-step|stage> attempt=<UTC time plus 4 hex> step=<id>`
refused_ev() {
  mkdir -p "$H/.vid" 2>/dev/null || return 0
  printf 'refused phase=admission by=%s attempt=%s step=%s at=%s\n' "$1" "$(date -u '+%Y%m%dT%H%M%SZ')-$(od -An -N2 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$H/.vid/metrics-events"
}
# --- v0.9.7.2 (3.1–3.5; R1–R7): breadth first ---
# strat: the run's strategy — RUN-STATE's `strategy:` line; missing, or anything but breadth-first, is depth first
strat() { case "$(sed -n 's/^strategy:[[:space:]]*//p' "$H/.vid/RUN-STATE.md" 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//')" in breadth-first) echo breadth-first ;; *) echo depth-first ;; esac; }
# prot_set: R4's protected rows → $TMPD/prot (`<ROW><TAB><from>`): checks/inventory.sh's derivation at the home, and the plan's protected: line
prot_set() {
  [ -f "$H/checks/inventory.sh" ] || { echo "ViD plan: refused — no checks/inventory.sh at the run's home: the protected rows cannot be derived." >&2; return 1; }
  ( cd "$H" && sh checks/inventory.sh protected ) > "$TMPD/protinv" 2> "$TMPD/protinv.err" || { echo "ViD plan: refused — checks/inventory.sh protected failed: $(head -n 1 "$TMPD/protinv.err")" >&2; return 1; }
  { awk '$1 == "protected" && $2 ~ /^ROW-/ { f = $3; sub(/^from=/, "", f); print $2 "\t" f }' "$TMPD/protinv"
    awk -F'\t' '$1 == "prot" { print $2 "\tdesignated" }' "$TMPD/parsed"; } > "$TMPD/prot"
}
# breadth_checks: nothing builds on a hardening step (3.2); no protected row sits in one — every hardening row checked (R4)
breadth_checks() {
  _bad=$(awk -F'\t' '$1 == "step" { K[$2] = $7; B[$2] = $5; O[++n] = $2 } END { for (i = 1; i <= n; i++) { s = O[i]; m = split(B[s], a, /[ \t]+/); for (k = 1; k <= m; k++) if ((a[k] in K) && K[a[k]] == "hardening") print "    step " s " builds on " a[k] ", a hardening step" } }' "$TMPD/parsed")
  if [ -n "$_bad" ]; then echo 'ViD plan: refused — under breadth first nothing builds on a hardening step:' >&2; printf '%s\n' "$_bad" >&2; return 1; fi
  prot_set || return 1
  _bad=$(awk -F'\t' 'FILENAME == ARGV[1] { P[$1] = (($1 in P) ? P[$1] "," : "") $2; next } $1 == "step" && $7 == "hardening" { K[$2] = 1; next } $1 == "row" && ($3 in K) && ($2 in P) { print "    " $2 " in hardening step " $3 " (protected: " P[$2] ")" }' "$TMPD/prot" "$TMPD/parsed")
  if [ -n "$_bad" ]; then echo 'ViD plan: refused — a protected row never sits in a hardening step, whatever the reason:' >&2; printf '%s\n' "$_bad" >&2; return 1; fi
  return 0
}
# stepstate <ids, comma-separated>: checks/metrics.sh step-state at the home → $TMPD/ss; exit 1 when it cannot be read
stepstate() { ( cd "$H" && sh checks/metrics.sh step-state "$1" ) > "$TMPD/ss" 2> "$TMPD/ss.err" && grep -q '^step-state ' "$TMPD/ss"; }
# graded_gate <step>: R7 — every step in its builds-on closed at its current rows and graded; a refusal names the rows
graded_gate() {
  _bo=$(awk -F'\t' -v s="$1" '$1 == "step" && $2 == s { print $5 }' "$TMPD/parsed" | tr ' ' '\n' | grep -v '^-$' | grep -v '^$' | paste -sd, -)
  [ -n "$_bo" ] || return 0
  if ! stepstate "$_bo"; then echo "ViD plan: refused — the graded gate cannot read the steps $1 builds on (checks/metrics.sh step-state): $(head -n 1 "$TMPD/ss.err")" >&2; refused_ev graded "$1"; return 1; fi
  _g=$(awk 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "step-state" { s = kv("step"); O[++n] = s; C[s] = kv("closed"); G[s] = kv("graded"); CL[s] = kv("close"); next }
    $1 == "not-closed" { s = kv("step"); r = kv("row"); NC[s] = NC[s] (NC[s] == "" ? "" : " ") r; nc[s]++; next }
    $1 == "ungraded" { s = kv("step"); r = kv("row"); UG[s] = UG[s] (UG[s] == "" ? "" : " ") r; ug[s]++ }
    END { for (i = 1; i <= n; i++) { s = O[i]
      if (C[s] != "yes") { if (CL[s] == "none") printf "    %s is not closed: never closed\n", s; else printf "    %s is not closed at its current rows: %d rows (%s)\n", s, nc[s], NC[s] }
      else if (G[s] != "yes") printf "    %s is closed, not graded: %d rows (%s)\n", s, ug[s], UG[s] } }' "$TMPD/ss")
  [ -z "$_g" ] && return 0
  echo "ViD plan: refused — the graded gate: $1 starts only when every step it builds on is closed and graded:" >&2; printf '%s\n' "$_g" >&2
  echo "    Grade a closed step's rows from its close (sh checks/brief.sh write --role grader --catch-up <step> --slice <N>); close an unclosed one first." >&2
  refused_ev graded "$1"; return 1
}
# dep_safeguard: R5 — over $TMPD/newh (`<row> <hardening step> <PREV step or ->`), the dependents taken from PREV ($_pv):
# the feature steps there whose builds-on names the row's step (a hardening step is where edge work goes, not a core path)
dep_safeguard() {
  awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "step" && $7 != "hardening") { n = split($5, a, /[ \t]+/); for (k = 1; k <= n; k++) if (a[k] != "-" && a[k] != "") D[a[k]] = D[a[k]] (D[a[k]] == "" ? "" : " ") $2 } next }
    $3 != "-" && D[$3] != "" { print $1 "\t" $3 "\t" D[$3] }' "$_pv" "$TMPD/newh" > "$TMPD/deps"
  [ -s "$TMPD/deps" ] || return 0
  # the steps read: the hardening steps holding the moved rows (their breaches), and every dependent still in the plan (done)
  _q=$( { cut -f2 "$TMPD/newh"; cut -f3 "$TMPD/deps" | tr ' ' '\n'; } | grep -v '^$' | sort -u | while IFS= read -r _x; do grep -q "^step	$_x	" "$TMPD/parsed" && printf '%s\n' "$_x"; done | paste -sd, -)
  stepstate "$_q" || { echo "ViD plan: refused — the dependency safeguard cannot read step-state (checks/metrics.sh): $(head -n 1 "$TMPD/ss.err")" >&2; return 1; }
  _need=$(awk -F'\t' -v sf="$TMPD/ss" 'function kv(l, k,   n, a, i) { n = split(l, a, " "); for (i = 2; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }
    BEGIN { while ((getline l < sf) > 0) { split(l, a, " "); if (a[1] == "breach") BR[kv(l, "row")] = 1; else if (a[1] == "step-state") DN[kv(l, "step")] = kv(l, "done") } }
    ($1 in BR) { n = split($3, d, " "); for (k = 1; k <= n; k++) if ((d[k] in DN) && DN[d[k]] != "yes") print $1 "\t" d[k] }' "$TMPD/deps")
  [ -n "$_need" ] || return 0
  _miss=$(printf '%s\n' "$_need" | cut -f2 | sort -u | while IFS= read -r _x; do case ",$NNB," in (*",$_x,"*) ;; (*) printf '%s\n' "$_x" ;; esac; done | paste -sd, -)
  [ -z "$_miss" ] && return 0
  echo "ViD plan: refused — the dependency safeguard: a row with an open product breach moves to hardening while a step that built on its step is not done:" >&2
  printf '%s\n' "$_need" | awk -F'\t' '{ printf "    %s, needed by %s (not done)\n", $1, $2 }' >&2
  if [ -n "$NNB" ]; then echo "    --not-needed-by names $NNB, not every such step: $_miss is missing." >&2
  else echo "    Fix it first, or name every such step and why it doesn't need the row: --not-needed-by $(printf '%s\n' "$_need" | cut -f2 | sort -u | paste -sd, -) \"<why>\"." >&2; fi
  return 1
}
# rules <step> <tree-ish> <new rows file> [dirty-check yes|no]: rules A and B for a step whose rows are new; prints the refusal, exit 1
rules() {
  _s=$1; _at=$2; _nr=$3
  CURP=$(awk -F'\t' -v s="$_s" '$1 == "cur" && $2 == s { print $3 }' "$TMPD/parsed")
  if [ "${4:-yes}" = yes ]; then
    # shellcheck disable=SC2086
    _d=$(IFS=' '; git status --porcelain -- $CURP 2>/dev/null | grep -v ' \.vid/' | head -n 5)
    if [ -n "$_d" ]; then echo "ViD plan: refused — $_s: the checking worktree has uncommitted changes on its currency paths (commit or restore them first; an unseen edit to what it builds on can neither pass nor hide):" >&2; printf '%s\n' "$_d" | sed 's/^/    /' >&2; refused_ev dirty-currency "$_s"; return 1; fi
  fi
  mkmap "$TMPD/map" || return 1
  states "$_at" || return 1
  GAP=''
  for _b in $(awk -F'\t' -v s="$_s" '$1 == "step" && $2 == s { print $5 }' "$TMPD/parsed" | tr ' ' '\n' | grep -v '^-$' | grep -v '^$'); do
    _g=$(awk -F'\t' -v b="$_b" 'NR == FNR { if ($1 == "row" && $3 == b) R[$2] = 1; next } ($1 in R) && $2 != "pass" && $2 != "owed" && $2 != "deploy-owed" && $2 != "held" && $2 != "later" { printf "%s%s %s", (n++ ? ", " : ""), $1, ($2 == "never" ? "never run" : ($2 == "stale" ? "never run on the current code" : $2 " — " $3)) }' "$TMPD/parsed" "$TMPD/states")
    [ -n "$_g" ] && GAP="$GAP
    $_s builds on $_b, which is not passing: $_g"
  done
  if [ -n "$GAP" ]; then echo "ViD plan: refused — rule B:$GAP" >&2; echo "    Fix $_s's prerequisite, or change the plan (sh checks/plan.sh change split \"…\"): a red row split into its own step that $_s does not build on." >&2; refused_ev rule-B "$_s"; return 1; fi
  _bud=$(budget)
  # v0.9.7.2 (3.2, R6): under breadth first, charged rows now parked in an unstarted hardening step leave rule A's count
  _cf=$TMPD/charged
  if [ "$(strat)" = breadth-first ]; then
    awk -F'\t' -v sf="$TMPD/started" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 } FILENAME == ARGV[1] { if ($1 == "step" && $7 == "hardening" && !($2 in S)) K[$2] = 1; else if ($1 == "row" && ($3 in K)) P[$2] = 1; next } !($1 in P)' "$TMPD/parsed" "$TMPD/charged" > "$TMPD/charged.a"; _cf=$TMPD/charged.a
  fi
  _u=$(awk -F'\t' 'FILENAME == ARGV[1] { C[$1] = 1; next } FILENAME == ARGV[2] { N[$1] = 1; next } (($1 in C) || ($1 in N)) && $2 != "pass" && $2 != "owed" && $2 != "deploy-owed" && $2 != "held" && $2 != "later" { n++; if ($1 in N && !($1 in C)) k++ } END { print n + 0, k + 0 }' "$_cf" "$_nr" "$TMPD/states")
  _tot=${_u% *}; _new=${_u#* }
  if [ "$_tot" -gt "$_bud" ]; then
    echo "ViD plan: refused — rule A: $_tot unverified rows would exceed unverified-rows=$_bud ($((_tot - _new)) rows of started steps are not passing on current results; $_new of $_s's new rows are not). Turn started rows green, or split $_s smaller." >&2; refused_ev rule-A "$_s"; return 1
  fi
  return 0
}
# admit_step <step> <tree-ish>: the admission (start, admit)
admit_step() {
  _s=$1; _at=$2
  load_plan || return 1
  _lh=$(events plan-change | tail -n 1 | awk "$AWKAT"' { print kv("hash") }')
  if [ -z "$_lh" ]; then echo "ViD plan: refused — the plan has no recorded change: run sh checks/plan.sh change create \"<why>\"." >&2; refused_ev unrecorded-plan "$_s"; return 1; fi
  # v0.9.7.0.11 (3.8a, R16): a raw-hash mismatch is no change when the block equals the last recorded plan in canonical form
  if [ "$_lh" != "$PLANHASH" ] && [ -f "$H/.vid/plans/$_lh.plan" ] && [ "$(canon < "$TMPD/block")" = "$(canon < "$H/.vid/plans/$_lh.plan")" ]; then PLANHASH=$_lh; fi
  if [ "$_lh" != "$PLANHASH" ]; then echo "ViD plan: refused — the plan changed without a recorded change (block $PLANHASH, last recorded $_lh): run sh checks/plan.sh change <what> \"<why>\"." >&2; refused_ev unrecorded-plan "$_s"; return 1; fi
  grep -q "^step	$_s	" "$TMPD/parsed" || { echo "ViD plan: refused — no step $_s in the plan." >&2; refused_ev no-step "$_s"; return 1; }
  # v0.26.10.5 (R6): with STAGES.md at the home, a step holding a row outside stages 1 to the current one is refused,
  # started or not, a pull-forward or not — the next stage's steps are planned when the current one closes
  if [ -f "$H/STAGES.md" ] && [ -f "$H/checks/stages.sh" ]; then
    ( cd "$H" && sh checks/stages.sh scope ) > "$TMPD/stscope" 2> "$TMPD/stscope.err" || { echo "ViD plan: refused — the stage scope cannot be read (checks/stages.sh scope): $(head -n 1 "$TMPD/stscope.err")" >&2; refused_ev stage "$_s"; return 1; }
    _cur=$( cd "$H" && sh checks/stages.sh current )
    _out=$(awk -F'\t' 'NR == FNR { S[$1] = 1; next } $1 == "row" && $3 == s && !($2 in S) { printf "%s%s", (n++ ? ", " : ""), $2 }' s="$_s" "$TMPD/stscope" "$TMPD/parsed")
    if [ -n "$_out" ]; then
      echo "ViD plan: refused — $_s holds rows outside stages 1 to $_cur (the current stage): $_out. A later stage's rows are planned when the current stage closes; a pull-forward brings the minimum piece forward and never admits a later row (proven by this stage's rows that use it)." >&2
      refused_ev stage "$_s"; return 1
    fi
  fi
  started
  if grep -qx "$_s" "$TMPD/started"; then echo "ViD plan: $_s already started — admitted (a started step is never refused again)"; return 0; fi
  _bf=$(strat)
  # v0.9.7.2 (3.5, R7): the graded gate — every admission of a new step under breadth first, a split of charged rows too
  if [ "$_bf" = breadth-first ]; then graded_gate "$_s" || return 1; fi
  awk -F'\t' -v s="$_s" '$1 == "row" && $3 == s { print $2 }' "$TMPD/parsed" > "$TMPD/steprows"
  awk -F'\t' 'FILENAME == ARGV[1] { C[$1] = 1; next } !($1 in C)' "$TMPD/charged" "$TMPD/steprows" > "$TMPD/newrows"
  # v0.9.7.2 (3.2): a hardening step's admission runs rule A with its parked rows counted as new rows
  if [ "$_bf" = breadth-first ] && [ "$(awk -F'\t' -v s="$_s" '$1 == "step" && $2 == s { print $7 }' "$TMPD/parsed")" = hardening ]; then cp "$TMPD/steprows" "$TMPD/newrows"; fi
  if [ -s "$TMPD/newrows" ]; then rules "$_s" "$_at" "$TMPD/newrows" yes || return 1; fi
  mkdir -p "$H/.vid"; printf 'step-start step=%s plan=%s base=%s at=%s\n' "$_s" "$PLANHASH" "$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$H/.vid/metrics-events"
  if [ -s "$TMPD/newrows" ]; then echo "ViD plan: admitted $_s under plan $PLANHASH"; else echo "ViD plan: admitted $_s under plan $PLANHASH — its rows all belonged to a started step, so neither rule applies"; fi
  return 0
}
# step_base <step>: `base step=<id> commit=<sha> from=step-start|brief|step-start-time` (v0.9.6.1 3.5)
step_base() {
  _l=$(events step-start | awk "$AWKAT"' kv("step") == "'"$1"'"' | head -n 1)
  [ -n "$_l" ] || { echo "ViD plan: refused — step $1 was never started (no step-start event names it)." >&2; return 1; }
  _b=$(evkv "$_l" base)
  if [ -n "$_b" ]; then echo "base step=$1 commit=$_b from=step-start"; return 0; fi
  # before 0.9.6.1: the first builder (or fixer) brief naming the step
  tmpd; : > "$TMPD/bq"
  for _f in $(find "$H/.vid/briefs" -type f -name '*.md' 2>/dev/null | sort); do
    _hd=$(sed -n '1,12p' "$_f")
    _ro=$(printf '%s\n' "$_hd" | sed -n 's/^.*role:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]].*$//')
    _st=$(printf '%s\n' "$_hd" | sed -n 's/^.*step:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]].*$//')
    _qa=$(printf '%s\n' "$_hd" | sed -n 's/^.*quoted-at:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]].*$//')
    case "$_ro" in builder|fixer) ;; *) continue ;; esac
    [ "$_st" = "$1" ] && [ -n "$_qa" ] || continue
    _rel=${_f#"$H"/}
    _at=$(events brief-check | awk "$AWKAT"' kv("result") == "ok" && (kv("path") == "'"$_rel"'" || kv("path") == "'"$_f"'") { a = lastat(); if (a != "") { print a; exit } }')
    printf '%s\t%s\t%s\n' "${_at:-9999}" "$_rel" "$_qa" >> "$TMPD/bq"
  done
  _q=$(sort -t "$(printf '\t')" -k1,1 -k2,2 "$TMPD/bq" | head -n 1 | cut -f3)
  if [ -n "$_q" ] && _c=$(git rev-parse -q --verify "$_q^{commit}" 2>/dev/null); then
    echo "base step=$1 commit=$(git rev-parse --short=12 "$_c") from=brief"; return 0; fi
  _a=$(printf '%s\n' "$_l" | awk "$AWKAT"' { print lastat() }')
  if [ -n "$_a" ] && _c=$(git rev-list -1 --before="$_a" HEAD 2>/dev/null) && [ -n "$_c" ]; then
    echo "base step=$1 commit=$(git rev-parse --short=12 "$_c") from=step-start-time"; return 0; fi
  echo "ViD plan: refused — step $1 has no base: its step-start carries no base=, no builder brief names it, and no commit precedes its start time." >&2
  return 1
}
# v0.9.6.2 (3.3): the decision arguments and their references
TRIGGERS='initial test-evidence owner-answer agent-failure cost discovered-dependency scope-change gate-refusal unknown'
# decide_args: refuses (stderr, exit 1) a change whose decision arguments do not hold
decide_args() {
  if [ -n "$ARGERR" ]; then echo "ViD plan: refused — $ARGERR." >&2; return 1; fi
  if [ -z "$TRIG" ] || [ -z "$EXPECT" ]; then
    echo "ViD plan: refused — a plan change under the gate is a decision: name its trigger and its expected effect, --trigger <t>[,<t>…] [--evidence <ref>[,<ref>…]] --expect \"<one line>\" (triggers: $(printf '%s' "$TRIGGERS" | sed 's/ /, /g'))." >&2; return 1; fi
  case "$EXPECT$ALTS" in *'
'*) echo 'ViD plan: refused — --expect and --alternatives are one line each.' >&2; return 1 ;; esac
  _need=no
  for _t in $(printf '%s\n' "$TRIG" | tr ',' '\n'); do
    case " $TRIGGERS " in *" $_t "*) ;; *) echo "ViD plan: refused — '$_t' is no trigger (triggers: $(printf '%s' "$TRIGGERS" | sed 's/ /, /g'))." >&2; return 1 ;; esac
    case "$_t" in initial|unknown) ;; *) _need=yes ;; esac
  done
  if [ "$_need" = yes ] && [ -z "$EVID" ]; then echo "ViD plan: refused — the trigger $TRIG needs at least one evidence reference: --evidence receipt:<name>[#<case>] | question:Q<n> | agent:<id> | refusal:<attempt> | step:<id> | commit:<sha>." >&2; return 1; fi
  for _r in $(printf '%s\n' "$EVID" | tr ',' '\n'); do
    [ -n "$_r" ] || continue
    ref_ok "$_r" || { echo "ViD plan: refused — the evidence reference '$_r' does not resolve; the plan keeps its recorded hash." >&2; return 1; }
  done
  return 0
}
# ref_ok <ref>: exit 0 when the reference names something that exists
ref_ok() {
  case "$1" in
    receipt:*)
      _n=${1#receipt:}; _c=''; case "$_n" in *'#'*) _c=${_n#*#}; _n=${_n%%#*} ;; esac
      case "$_n" in ''|*/*|.*) return 1 ;; esac
      [ -f "$H/.vid/ledger-results/$_n" ] || return 1
      [ -z "$_c" ] || awk -v c="$_c" '$1 == "case" && $2 == c { f = 1 } END { exit f ? 0 : 1 }' "$H/.vid/ledger-results/$_n.cases" 2>/dev/null ;;
    question:Q*) _q=${1#question:Q}; [ -n "$_q" ] && events question | awk -v q="$_q" "$AWKAT"' kv("n") == q { f = 1 } END { exit f ? 0 : 1 }' ;;
    agent:*) _a=${1#agent:}; [ -n "$_a" ] && events agent-start | awk -v a="$_a" "$AWKAT"' kv("agent") == a { f = 1 } END { exit f ? 0 : 1 }' ;;
    refusal:*) _a=${1#refusal:}; [ -n "$_a" ] && events refused | awk -v a="$_a" "$AWKAT"' kv("attempt") == a { f = 1 } END { exit f ? 0 : 1 }' ;;
    step:*)
      _s=${1#step:}; [ -n "$_s" ] || return 1
      for _f in "$TMPD/block" "$H/.vid/plans/$PREV.plan"; do
        [ -f "$_f" ] && awk -v s="$_s" '{ l = $0; sub(/^[ \t]*/, "", l) } l ~ /^step[ \t]/ { split(l, a, "|"); id = a[1]; sub(/^step[ \t]+/, "", id); gsub(/[ \t]+$/, "", id); if (id == s) f = 1 } END { exit f ? 0 : 1 }' "$_f" && return 0
      done
      return 1 ;;
    commit:*) _c=${1#commit:}; [ -n "$_c" ] && git rev-parse -q --verify "$_c^{commit}" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}
# write_decision <accepted|refused> [<refusal line>]: .vid/plans/decisions/<DID>.why and <DID>.plan, written once
write_decision() {
  _dd="$H/.vid/plans/decisions"; mkdir -p "$_dd" || return 0
  cp "$TMPD/block" "$_dd/$DID.plan"
  { printf 'id=%s\nat=%s\nresult=%s\nwhat=%s\nprev=%s\ncandidate=%s\ncommit=%s\n' "$DID" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" "$WHAT" "$PREV" "$CAND" "$(git rev-parse --short=12 HEAD 2>/dev/null || echo none)"
    printf 'trigger=%s\nevidence=%s\nexpect=%s\nalternatives=%s\n' "${TRIG:--}" "${EVID:--}" "${EXPECT:--}" "${ALTS:--}"
    [ -z "${NNB:-}" ] || printf 'not-needed-by=%s\nnot-needed-why=%s\n' "$NNB" "$NNW"
    if [ "$1" = refused ]; then printf 'refusal=%s\n' "$2"; fi
  } > "$_dd/$DID.why.tmp" && mv "$_dd/$DID.why.tmp" "$_dd/$DID.why"
}
# change_body: the 0.9.6 checks of a plan change and, when they hold, the kept plan (run in a subshell; a refusal exits 1)
change_body() {
  LANECHK=1; load_plan || exit 1
  started
  # a row of a started step may not be left in no step, unless owed, held or later
  awk -F'\t' 'NR == FNR { if ($1 == "row") P[$2] = 1; next } !($1 in P) { print $1 "\t" $2 "\t" $3 }' "$TMPD/parsed" "$TMPD/charged" > "$TMPD/orph"
  if [ -s "$TMPD/orph" ]; then
    cp "$TMPD/orph" "$TMPD/map.o"
    awk -F'\t' '{ print $1 "\t-\t" }' "$TMPD/orph" > "$TMPD/map"
    states HEAD || exit 1
    BADO=$(awk -F'\t' '$2 != "owed" && $2 != "deploy-owed" && $2 != "held" && $2 != "later" { printf "%s%s", (n++ ? " " : ""), $1 }' "$TMPD/states")
    if [ -n "$BADO" ]; then echo "ViD plan: refused — this change leaves rows of started steps in no step: $BADO. Their charge follows the row: keep them in a step (they stay counted), or show them owed, held or later." >&2; exit 1; fi
  fi
  # rows added to a started step are admitted like a new step — v0.9.7.0.11 (3.8, R8): only the rows it gains against the
  # same step of the last recorded plan ($PREV); with none recorded, against the charge (its start plans), as before
  _pv=''; [ "${PREV:-none}" != none ] && [ -f "$H/.vid/plans/$PREV.plan" ] && { pplan "$PREV"; _pv="$TMPD/p.$PREV"; }
  # v0.9.7.2 (3.3, R4): the plan's protected: line only grows, under either strategy
  if [ -n "$_pv" ]; then
    _rm=$(awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "prot") N[$2] = 1; next } $1 == "prot" && !($2 in N) { printf "%s%s", (n++ ? " " : ""), $2 }' "$TMPD/parsed" "$_pv")
    [ -z "$_rm" ] || { echo "ViD plan: refused — the plan's protected: line only grows; this change removes $_rm." >&2; exit 1; }
  fi
  # v0.9.7.2 (3.2–3.4; R3–R5): under breadth first — the placement checks, the rows newly in hardening (PREV; none at create), the safeguard
  if [ "$(strat)" = breadth-first ]; then
    breadth_checks || exit 1
    if [ -n "$_pv" ]; then
      awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "step") K[$2] = $7; else if ($1 == "row") S[$2] = $3; next }
        $1 == "step" { HK[$2] = ($7 == "hardening"); next } $1 == "row" && HK[$3] && (!($2 in S) || K[S[$2]] != "hardening") { print $2 "\t" $3 "\t" (($2 in S) ? S[$2] : "-") }' "$_pv" "$TMPD/parsed" > "$TMPD/newh"
      if [ -s "$TMPD/newh" ] && [ "$WHAT" != edge ]; then
        echo "ViD plan: refused — this $WHAT change places rows in a hardening step: $(cut -f1 "$TMPD/newh" | paste -sd ' ' -). A move into hardening is its own recorded change: sh checks/plan.sh change edge \"<why>\" …" >&2; exit 1
      fi
      if [ -s "$TMPD/newh" ]; then dep_safeguard || exit 1; fi
    fi
  fi
  for st in $(cat "$TMPD/started"); do
    grep -q "^step	$st	" "$TMPD/parsed" || continue
    if [ -n "$_pv" ]; then awk -F'\t' -v s="$st" 'FILENAME == ARGV[1] { if ($1 == "row" && $3 == s) C[$2] = 1; next } $1 == "row" && $3 == s && !($2 in C) { print $2 }' "$_pv" "$TMPD/parsed" > "$TMPD/added"
    else awk -F'\t' -v s="$st" 'FILENAME == ARGV[1] { C[$1] = 1; next } $1 == "row" && $3 == s && !($2 in C) { print $2 }' "$TMPD/charged" "$TMPD/parsed" > "$TMPD/added"; fi
    [ -s "$TMPD/added" ] || continue
    if ! rules "$st" HEAD "$TMPD/added" no; then echo "ViD plan: refused — rows added to the started step $st are admitted like a new step; the plan keeps its recorded hash." >&2; exit 1; fi
  done
  mkdir -p "$H/.vid/plans"
  [ -f "$H/.vid/plans/$PLANHASH.plan" ] || cp "$TMPD/block" "$H/.vid/plans/$PLANHASH.plan"
  if [ "$WHAT" = other ]; then
    NB=$(printf '%s\n' "$WHY" | sed -n 's/.*unverified-rows=\([0-9][0-9]*\).*/\1/p' | head -n 1)
    if [ -n "$NB" ]; then { [ -f "$H/.vid/budget" ] && grep -v '^unverified-rows=' "$H/.vid/budget"; printf 'unverified-rows=%s\n' "$NB"; } > "$H/.vid/budget.tmp"; mv "$H/.vid/budget.tmp" "$H/.vid/budget"; fi
  fi
}
need_gate() { # $1=what: inside the gate H is set; ambiguous, refused; outside, a note and exit 0
  G=$(sh "$0" gate 2>/dev/null); _grc=$?
  case "$G" in 'on '*) H=${G#on }; return 0 ;; esac
  [ "$_grc" -eq 3 ] && { echo "ViD plan: refused — ${G#off } — $1 cannot tell which run this checkout belongs to." >&2; exit 1; }
  echo "ViD plan: note — ${G#off } — $1 is off (a 0.9.5 run, or not develop)."; exit 0
}

case "${1:-}" in
  gate)
    H=$(home_of); _hrc=$?
    case "$_hrc" in
      0) ;;
      3) printf 'off ambiguous — %s live develop runs among this repository'"'"'s checkouts (%s); record this checkout'"'"'s home first: sh checks/plan.sh home --brief <your brief file>\n' "$(printf '%s\n' "$H" | grep -c .)" "$(printf '%s\n' "$H" | paste -sd ',' - | sed 's/,/, /g')"; exit 3 ;;
      *) echo 'off no run here — neither .vid/RUN-STATE.md nor .vid/home, and no live run among the repository'"'"'s checkouts'; exit 1 ;;
    esac
    if WHY=$(gate_at "$H"); then printf 'on %s\n' "$H"; exit 0; fi
    # v0.26.10.3 (R8): a stopped run still owns its live agents — a checkout other than the home, its branch bound to a
    # live agent or an unfinished Codex job of that run, reads the gate on; the home itself, and a checkout with only a
    # .vid/home path, read it off; a complete run, or one whose develop stage ended, is off everywhere
    if [ "$(cd "$(top)" && pwd -P)" != "$(cd "$H" && pwd -P)" ] && gate_at "$H" stopped > /dev/null 2>&1 && bound_here "$H"; then printf 'on %s\n' "$H"; exit 0; fi
    printf 'off %s\n' "$WHY"; exit 1 ;;
  home-of)
    H=$(home_of); _hrc=$?
    case "$_hrc" in
      0) printf '%s\n' "$H"; exit 0 ;;
      3) printf 'ambiguous — %s live develop runs among this repository'"'"'s checkouts (%s); record this checkout'"'"'s home first: sh checks/plan.sh home --brief <your brief file>\n' "$(printf '%s\n' "$H" | grep -c .)" "$(printf '%s\n' "$H" | paste -sd ',' - | sed 's/,/, /g')"; exit 3 ;;
      *) echo 'no home — neither .vid/RUN-STATE.md nor .vid/home, and no live run among the repository'"'"'s checkouts'; exit 1 ;;
    esac ;;
  home)
    [ "${2:-}" = --brief ] && [ -n "${3:-}" ] || usage
    [ -f "$3" ] || { echo "ViD plan: refused — no brief at $3" >&2; exit 1; }
    H=$(cd "$(dirname "$3")" && git rev-parse --show-toplevel 2>/dev/null) || { echo "ViD plan: refused — $3 is in no git worktree" >&2; exit 1; }
    [ -f "$H/.vid/RUN-STATE.md" ] || { echo "ViD plan: refused — the brief's worktree ($H) holds no .vid/RUN-STATE.md; the home is the worktree that holds the run" >&2; exit 1; }
    T=$(top)
    if [ "$(cd "$T" && pwd -P)" = "$(cd "$H" && pwd -P)" ]; then echo "ViD plan: this worktree is the run's home ($H) — nothing to record"; exit 0; fi
    mkdir -p "$T/.vid"; printf '%s\n' "$H" > "$T/.vid/home"
    echo "ViD plan: home $H recorded in $T/.vid/home — receipts, events and amendments land there"
    exit 0 ;;
  check)
    need_gate 'the plan check'
    LANECHK=1; load_plan || exit 1
    _bfn=''
    if [ "$(strat)" = breadth-first ]; then breadth_checks || exit 1; _bfn=" · breadth first: $(awk -F'\t' '$1 == "step" && $7 == "hardening"' "$TMPD/parsed" | grep -c . || true) hardening steps, $(cut -f1 "$TMPD/prot" | sort -u | grep -c . || true) protected rows"; fi
    echo "ViD plan: ok — hash $PLANHASH, $(grep -c '^step	' "$TMPD/parsed") steps, $(grep -c '^row	' "$TMPD/parsed") rows$_bfn"
    exit 0 ;;
  strategy)
    # v0.9.7.2 (3.1, R1): the owner's strategy, in the owner's words
    [ $# -ge 2 ] || usage
    SS=$2; shift 2; SBY=''; SW=''
    while [ $# -gt 0 ]; do
      case "$1" in --by|--words) [ $# -ge 2 ] || usage; if [ "$1" = --by ]; then SBY=$2; else SW=$2; fi; shift 2 ;; *) usage ;; esac
    done
    case "$SS" in depth-first|breadth-first) ;; *) usage ;; esac
    if [ "$SBY" != owner ] || [ -z "$(printf '%s' "$SW" | tr -d '[:space:]')" ]; then
      echo "ViD plan: refused — the strategy is the owner's choice: --by owner --words \"<the owner's words, verbatim>\"." >&2; exit 1; fi
    need_gate 'the strategy'
    tmpd
    if [ "$SS" = breadth-first ]; then
      block "$H/.vid/RUN-STATE.md" > "$TMPD/b0"
      if [ -s "$TMPD/b0" ]; then
        LANECHK=1; load_plan || exit 1
        breadth_checks || { echo 'ViD plan: the strategy is unchanged.' >&2; exit 1; }
      fi
    fi
    _dd="$H/.vid/plans/decisions"; mkdir -p "$_dd"
    DID="$(date -u '+%Y%m%dT%H%M%SZ')-strategy"
    if [ -e "$_dd/$DID.why" ]; then _k=2; while [ -e "$_dd/$DID-$_k.why" ]; do _k=$((_k + 1)); done; DID="$DID-$_k"; fi
    { printf 'id=%s\nat=%s\nresult=accepted\nwhat=strategy\nset=%s\nby=owner\ncommit=%s\nwords:\n' "$DID" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$SS" "$(git rev-parse --short=12 HEAD 2>/dev/null || echo none)"
      printf '%s\n' "$SW"; } > "$_dd/$DID.why.tmp" && mv "$_dd/$DID.why.tmp" "$_dd/$DID.why"
    RSF="$H/.vid/RUN-STATE.md"
    if grep -q '^strategy:' "$RSF"; then awk -v n="strategy: $SS" '/^strategy:/ && !d { print n; d = 1; next } { print }' "$RSF" > "$RSF.tmp"
    else awk -v n="strategy: $SS" '{ print } /^plan:/ && !d { print n; d = 1 }' "$RSF" > "$RSF.tmp"; grep -q '^strategy:' "$RSF.tmp" || { cat "$RSF"; echo "strategy: $SS"; } > "$RSF.tmp"; fi
    cat "$RSF.tmp" > "$RSF"; rm -f "$RSF.tmp"
    printf 'strategy set=%s by=owner decision=%s at=%s\n' "$SS" "$DID" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$H/.vid/metrics-events"
    echo "ViD plan: strategy $SS, set by the owner — decision $DID (.vid/plans/decisions/$DID.why)"
    exit 0 ;;
  parse)
    if [ -n "${2:-}" ]; then parse_block "$2" ''; exit $?; fi
    need_gate 'parsing the plan'; load_plan || exit 1; cat "$TMPD/parsed"; exit 0 ;;
  redstamp)
    [ "${2:-}" = --staged ] || usage
    G=$(sh "$0" gate 2>/dev/null); _grc=$?
    [ "$_grc" -eq 3 ] && { echo "ViD plan: refused — ${G#off } — the red-stamp check cannot tell which run this checkout belongs to." >&2; exit 1; }
    case "$G" in 'on '*) H=${G#on } ;; 'off no run here'*) exit 0 ;; *) echo "ViD plan: note — ${G#off } — the red-stamp check is off."; exit 0 ;; esac
    tmpd
    stamps() { git show "$1INVENTORY.md" 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id)
        for (i = 2; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^proved-red:/) { sub(/^proved-red:[ \t]*/, "", f); print id "\t" f } } }'; }
    stamps HEAD: > "$TMPD/old"; stamps : > "$TMPD/new"
    awk -F'\t' 'FILENAME == ARGV[1] { O[$0] = 1; next } !($0 in O) { print $1 }' "$TMPD/old" "$TMPD/new" | sort -u > "$TMPD/stamped"
    [ -s "$TMPD/stamped" ] || exit 0
    RD="$H/.vid/ledger-results"; BAD=''
    for id in $(cat "$TMPD/stamped"); do
      l=$(events red-observed | awk "$AWKAT"' kv("row") == "'"$id"'"' | tail -n 1)
      if [ -z "$l" ]; then BAD="$BAD
    $id: no red-observed event names it — record the red you observed first: sh checks/event.sh 'red-observed row=$id report=<receipt> case=<case id> assertion=\"<the failing assertion>\"'"; continue; fi
      rp=$(evkv "$l" report); cs=$(evkv "$l" case)
      case "$rp" in *.proof.*) BAD="$BAD
    $id: the red-observed receipt '$rp' is a proof receipt — never an ordinary one (checks/evidence.sh ordinary): observe the row red on an ordinary prove-red"; continue ;; esac   # v0.9.8 (R15)
      if ! events ledger-run | awk "$AWKAT"' { print kv("report") }' | grep -qxF -- "$rp" || events invalidated | awk "$AWKAT"' { print kv("report") }' | grep -qxF -- "$rp" || [ ! -f "$RD/$rp" ]; then
        BAD="$BAD
    $id: the red-observed receipt '$rp' is not a valid receipt (published by checks/test.sh, present, not invalidated)"; continue; fi
      if [ -f "$RD/$rp.cases" ]; then st=$(awk -v c="$cs" '$1 == "case" && $2 == c { s = $3 } END { print s }' "$RD/$rp.cases")
      else st=$( [ -f checks/extractors/results.sh ] && sh checks/extractors/results.sh "$RD/$rp" 2>/dev/null | awk -v c="$cs" '$1 == "case" && $2 == c { s = $3 } END { print s }'); fi
      case "$st" in
        failed) ;;
        '') BAD="$BAD
    $id: case '$cs' is absent from $rp — a missing case is nothing, never red" ;;
        error) BAD="$BAD
    $id: case '$cs' ended in error in $rp — that is its setup or collection, not the row's check" ;;
        *) BAD="$BAD
    $id: case '$cs' is '$st' in $rp, not failed" ;;
      esac
    done
    if [ -n "$BAD" ]; then echo "ViD plan: rejected — a proved-red stamp needs the row's case observed failing on its real check:$BAD" >&2; exit 1; fi
    echo "ViD plan: proved-red stamps joined to their observed red: $(tr '\n' ' ' < "$TMPD/stamped")"
    exit 0 ;;
  charged)
    need_gate 'the charged rows'; started; cat "$TMPD/charged"; exit 0 ;;
  base)
    [ -n "${2:-}" ] || usage
    need_gate 'the step base'
    step_base "$2"; exit $? ;;
  map)
    need_gate 'the currency map'; load_plan || exit 1; started
    if [ "${2:-}" = --all ]; then mkmap "$TMPD/map" all; else mkmap "$TMPD/map"; fi
    cat "$TMPD/map"; exit 0 ;;
  change)
    WHAT=${2:-}; WHY=${3:-}
    case "$WHAT" in create|add|drop|split|merge|reorder|lanes|rows|other|edge) ;; *) usage ;; esac
    [ -n "$WHY" ] || usage
    case "$WHY" in *'
'*) echo 'ViD plan: refused — the reason is one line.' >&2; exit 2 ;; esac
    shift 3
    # v0.9.6.2 (3.3): the decision arguments, read here, judged inside the gate
    TRIG=''; EVID=''; EXPECT=''; ALTS=''; ARGERR=''; NNB=''; NNW=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --not-needed-by)   # v0.9.7.2 (3.4, R5): the steps that don't need the moved rows, and why
          if [ $# -lt 3 ] || [ -z "$2" ] || [ -z "$3" ]; then ARGERR='--not-needed-by takes the steps and the why: --not-needed-by <id>[,<id>…] "<why>"'; shift $#; continue; fi
          NNB=$2; NNW=$3; shift 3 ;;
        --trigger|--evidence|--expect|--alternatives)
          if [ $# -lt 2 ]; then ARGERR="$1 has no value"; shift; continue; fi
          case "$1" in --trigger) TRIG=$2 ;; --evidence) EVID=$2 ;; --expect) EXPECT=$2 ;; --alternatives) ALTS=$2 ;; esac
          shift 2 ;;
        *) ARGERR="'$1' is no argument of plan.sh change"; shift ;;
      esac
    done
    case "$NNW" in *'
'*) echo 'ViD plan: refused — the --not-needed-by why is one line.' >&2; exit 2 ;; esac
    need_gate 'plan change'
    tmpd
    block "$H/.vid/RUN-STATE.md" > "$TMPD/block"
    CAND=$(h256 < "$TMPD/block")
    PREV=$(events plan-change | tail -n 1 | awk "$AWKAT"' { print kv("hash") }'); PREV=${PREV:-none}
    DID="$(date -u '+%Y%m%dT%H%M%SZ')-$CAND"
    if [ -e "$H/.vid/plans/decisions/$DID.why" ]; then _k=2; while [ -e "$H/.vid/plans/decisions/$DID-$_k.why" ]; do _k=$((_k + 1)); done; DID="$DID-$_k"; fi
    if ! ( decide_args && change_body ) 2> "$TMPD/err"; then
      cat "$TMPD/err" >&2
      write_decision refused "$(grep -m 1 'refused' "$TMPD/err" || sed -n 1p "$TMPD/err")"
      echo "ViD plan: decision $DID recorded as refused (.vid/plans/decisions/$DID.why)" >&2
      exit 1
    fi
    cat "$TMPD/err" >&2
    write_decision accepted
    W1=$(printf '%s' "$WHY" | tr '"' "'")
    PLANHASH=$CAND   # the accepted block is the candidate: load_plan hashed the same lines
    printf 'plan-change what=%s hash=%s decision=%s%s why="%s" at=%s\n' "$WHAT" "$PLANHASH" "$DID" "${NNB:+ not-needed-by=$NNB}" "$W1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$H/.vid/metrics-events"
    echo "ViD plan: change recorded — what=$WHAT hash=$PLANHASH decision=$DID (kept in .vid/plans/$PLANHASH.plan)"
    exit 0 ;;
  start)
    [ -n "${2:-}" ] || usage
    need_gate 'admission'
    admit_step "$2" HEAD; exit $? ;;
  admit)
    [ "${2:-}" = --brief ] && [ -f "${3:-}" ] || usage
    need_gate 'admission'
    BF=$3
    hv() { sed -n "1,12s/^.*$1:[[:space:]]*//p" "$BF" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
    ROLE=$(hv role); STEP=$(hv step); QAT=$(hv quoted-at)
    case "$ROLE" in builder|fixer) ;; *) echo "ViD plan: a $ROLE brief is outside the rules — it starts no step"; exit 0 ;; esac
    [ -n "$STEP" ] || { echo "ViD plan: refused — a $ROLE brief names its step in the header (step: <id>)." >&2; exit 1; }
    git cat-file -e "$QAT^{commit}" 2>/dev/null || { echo "ViD plan: refused — quoted-at '$QAT' names no commit." >&2; exit 1; }
    load_plan || exit 1
    grep -q "^step	$STEP	" "$TMPD/parsed" || { echo "ViD plan: refused — the brief names step $STEP, which is no step of the plan." >&2; refused_ev no-step "$STEP"; exit 1; }
    OUTR=$(awk '/^## [0-9]/ { on = ($2 == 1); next } on' "$BF" | grep -oE '^ROW-[0-9A-Za-z-]+' | awk -F'\t' -v s="$STEP" -v pf="$TMPD/parsed" 'BEGIN { while ((getline l < pf) > 0) { split(l, a, "\t"); if (a[1] == "row" && a[3] == s) R[a[2]] = 1 } } !($1 in R) { printf "%s%s", (n++ ? " " : ""), $1 }')
    [ -z "$OUTR" ] || { echo "ViD plan: refused — the brief's rows are not all rows of step $STEP: $OUTR." >&2; refused_ev rows-not-of-step "$STEP"; exit 1; }
    admit_step "$STEP" "$QAT"; exit $? ;;
  *) usage ;;
esac
