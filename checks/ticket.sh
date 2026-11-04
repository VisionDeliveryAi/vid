#!/bin/sh
# Purpose: ViD tickets (v0.26.10.9 spec R11, R14, R17, R20, R21, R26) — the ticket's grammar and its one report
# reader, for ticket mode: ViD's planner sends the plan to an outside dev team as GitHub issues and reads back what
# their pull requests and CI return. It never calls the network: it reads what checks/github.sh fetched (.vid/tickets/
# in ViD's repository; any folder in the stand-in's clone) and the read-only copy of the code repository (.vid/code).
#   junit <xml>…           the one report reader: each JUnit XML `testcase` becomes `case <id> <passed|failed|skipped|
#                          error> <seconds>`, its id `<test path>::<name>` — the name itself when it holds `::`, else the
#                          testcase's `file` attribute (or its `classname`) joined to its name by `::`. A `failure`
#                          child is failed, an `error` child error, a `skipped` child skipped, none passed.
#   body <ticket> [--issue <n>] [--out <dir>]   a written ticket (a brief written with --ticket, or skeleton-body's
#                          file; its `written:` stamp must hold) as markdown parts of at most 60,000 bytes, split at
#                          section boundaries (`## <n>` lines; a larger section at line boundaries). Each part opens
#                          with a ```vid-ticket header — `issue= step= stage= kind=feature|fix|skeleton part=<k>/<n>
#                          hash=<the written: hash> base=<the code commit> branch=vid/<issue>`, and in part 1 `rows:`
#                          and `run:` — and ends with `<!-- vid-ticket end part=<k>/<n> -->`. Part 1 is the issue's
#                          body, parts 2 to n its comments. Writes <dir>/part-<k>.md (default .vid/tickets/parts/<the
#                          ticket's name>/) and prints each path.
#   fetch <issue> --from <dir> [--out <file>]   joins the parts found in the files of <dir> (an issue's body and its
#                          comments, as fetched; files without a vid-ticket header are skipped; CRLF read as LF);
#                          the body's (body.md's) hash= is the current writing, and a comment part of another
#                          hash= is an earlier writing's, skipped and named (an untaken ticket is rewritten by a new
#                          body and new comment parts, R13); refuses a missing or doubled part, parts of another
#                          issue, a part count or hash= that differ, and a joined ticket whose `written:` stamp is
#                          not its hash= or not its content's;
#                          writes the ticket (default <dir>/ticket.md).
#   return-check <body> [--ticket <file>]   the vid-return block (R21) in a pull request's description: refuses, naming
#                          the line, no block, two blocks, a missing section (ticket:, rows:, decisions:, discovered:,
#                          law-needed:, questions:), a row line that does not parse, a row doubled, not of the ticket
#                          or missing (with --ticket), an unknown state or discovery kind, a fail or not-run without a
#                          reason, a pass or fail without ci:; the skeleton ticket's block has `rows: none` and one
#                          `skeleton: <key>: <value>` line each for test-framework, test-dir, run-one, ci-workflow and
#                          report, and run-full when its ticket asks for it (v0.26.10.12 R1: a skeleton ticket written
#                          under this release; an older skeleton's block passes without it). Prints `return-check: ok`
#                          (exit 0) or the refusals (exit 1). v0.26.10.12 (R2): one `ci-scope: <selector>` line; with
#                          --ticket, equal to the selector of the ticket's CI scope (section 16), and required when
#                          the ticket has one; a ticket with none (written before 0.26.10.12) requires none.
#   skeleton-body --req <REQ-id> [--missing "<what>"] [--out <file>]   the skeleton ticket (R11), the dev team's first:
#                          what it asks for, stack-neutral (v0.26.10.12 R1: its CI runs a pull request's ci-scope:
#                          selection, every test only on a manual start of main, nothing on a push to main); quoted at ViD's HEAD — BASELINE.md's `## Stack` section,
#                          CLAUDE.md's vid-placement block, ARCHITECTURE.md's module table, INVENTORY.md's seam rows,
#                          the vid-hosting block's providers: line, and the golden-path example's requirement whole
#                          (its fail-if) from the effective PRD; with --missing, a fix of the skeleton (kind=skeleton)
#                          naming what is missing. Header `kind: skeleton`, `quoted-at:`, `base:` (the read-only
#                          copy's origin/main), and a `written: ticket.sh skeleton-body <hash>` stamp. Default
#                          .vid/tickets/skeleton.md.
#   import <pr>            a merged pull request, as R14 and R17 have it: the copy checked out at its merge commit;
#                          ViD's copy check (each of the ticket's test files present at the merge and byte-identical
#                          to ViD's copy at HEAD — the correction last sent is ViD's copy), recorded `copy-check pr=
#                          files= changed= missing=`; tests first (the first commit past the base on the branch's own
#                          first-parent line, claims and merges aside, adds exactly the ticket's test files) and, when its CI report shows a row's cases
#                          failing, `red-observed row= pr= commit=<code sha>` — else the row is counted "red not
#                          shown"; INVENTORY.md is never touched; the head's CI run, bound to the vid-code block's
#                          repo: and ci-workflow:, testing exactly the head, its report the artifact named for its
#                          attempt (vid-junit-<attempt>), every row of the ticket with a case under its test path
#                          naming it — published as .vid/ledger-results/<code sha>.ci-<run>-<attempt>.xml with .cases
#                          and .rows (no .tree) and `ledger-run type=ci report= repo= workflow= run= attempt= commit=
#                          pr=`; then the hand-back (<brief>.return.md, from the block) and `sh checks/brief.sh return
#                          <file> --agent pr:<n>`. No report, a run of another workflow or commit, an expected test
#                          missing: nothing is published (exit 1), the rows stay unverdicted. The skeleton ticket's
#                          own pull request, imported before the test facts exist, is bound to the workflow its
#                          block's `skeleton: ci-workflow:` line names. v0.26.10.12 (R5): a ticket with a CI scope
#                          (section 16) expects a case for every row of it at its stamped test path — its own rows and
#                          the alarm set's; the receipt's .rows stays the ticket's rows (no credit for any other); an
#                          alarm row failing in that run is red evidence: the receipt is published, then `sent back:`
#                          names it, the hand-back is not checked (exit 1). A ticket without one is read as before.
#   import --main <sha> --stage <n>   main's run at a stage's last merge (R18): the same binding, the expected tests
#                          every ROW of stages up to n citing a test; published with `pr=-` for stage-close --ci.
#                          v0.26.10.12 (R4): when the vid-code block names run-full:, the run is the one the newest
#                          `run-full started` event at that commit names (its run id and commit; its newest attempt,
#                          complete) and no other run of the workflow — a pull request's scoped run or a push run is
#                          refused; without run-full:, main's newest run there, as before.
#   plan-md                .vid/tickets/PLAN.md, the plan page's source (R26): per stage its card and its steps; per
#                          step its rows and requirements (counted), what it builds on, its tickets and their state —
#                          from the plan block, STAGES.md, INVENTORY.md, .vid/tickets/map and the ticket events;
#                          v0.26.10.12 (R7): and per stage its forecast line, printed too.
#   forecast [--stage <n>] (v0.26.10.12 R7) `ci-minutes forecast stage=<n>: scoped <m> min × <t> tickets + full <f>
#                          min × <k> runs ≈ <total> min (<source>)`, per stage or for one: a forecast, labelled as one;
#                          nothing gates on it, nothing reads an allowance or a bill. t: the stage's steps (a ticket
#                          each) and its fix tickets; k: the current stage's run-full started events since the last
#                          close, at least 1; m and f: the mean test time in the imported CI runs' reports (a pull
#                          request's scoped, main's full), "measured", else unknown until the skeleton's first run.
# The records: .vid/tickets/map (`milestone stage= number=`, `step step= number=`, `ticket number= step= kind= brief=
# parts=`, written by github.sh publish); .vid/tickets/pr-<n>/ and commit-<sha>/ (meta, body.md, runs, artifacts/,
# written by github.sh pull). A workflow name's spaces are written %20 in events.
# Usage: sh checks/ticket.sh junit <xml>… | body <ticket> [--issue <n>] [--out <dir>] | fetch <issue> --from <dir> [--out <file>] | return-check <body> [--ticket <file>] | skeleton-body --req <REQ-id> [--missing "<what>"] [--out <file>] | import <pr> | import --main <sha> --stage <n> | plan-md | forecast [--stage <n>]
set -u
IFS='
'
LIMIT=60000
usage() { echo 'ViD ticket: usage — sh checks/ticket.sh junit <xml>… | body <ticket> [--issue <n>] [--out <dir>] | fetch <issue> --from <dir> [--out <file>] | return-check <body> [--ticket <file>] | skeleton-body --req <REQ-id> [--missing "<what>"] [--out <file>] | import <pr> | import --main <sha> --stage <n> | plan-md | forecast [--stage <n>]' >&2; exit 2; }
tref() { echo "ViD ticket: refused — $*" >&2; exit 1; }
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
ev() { if [ -f checks/event.sh ]; then sh checks/event.sh "$1" > /dev/null 2>&1 && return 0; fi; mkdir -p .vid; printf '%s at=%s\n' "$1" "$(now)" >> .vid/metrics-events; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
# hk <file> <key>: a header value (lines 1–14), as brief.sh reads one
hk() { sed -n "1,14s/^.*$2:[[:space:]]*//p" "$1" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
# stamp <file>: the written: stamp's hash; content hash: the file without that line
stamp() { sed -nE 's/^written: (brief\.sh write|ticket\.sh skeleton-body) ([0-9a-f]*)[[:space:]]*$/\2/p' "$1" | head -n 1; }
chash() { awk '!d && /^written: (brief\.sh write|ticket\.sh skeleton-body) / { d = 1; next } { print }' "$1" | git hash-object --stdin; }
kind_of() { if grep -q '^kind: skeleton$' "$1"; then echo skeleton; else case "$(hk "$1" role)" in fixer) echo fix ;; *) echo feature ;; esac; fi; }
rows_of() { awk '/^## [0-9]/ { on = ($2 == 1); next } on' "$1" | grep -oE '^ROW-[0-9A-Za-z-]+' | awk '!s[$0]++'; }
# rowlines_of <ticket>: section 1's ROW lines, whole (the inventory rows at quoted-at)
rowlines_of() { awk '/^## [0-9]/ { on = ($2 == 1); next } on && /^[ \t]*ROW-/' "$1"; }
# scope_sel / scope_rows <ticket>: section 16's CI scope (v0.26.10.12 R2) — its selector; its `<ROW-id> <test path>
# ticket|alarm` lines. A ticket written before 0.26.10.12, or before the skeleton's run-full:, has none.
scope_sel() { awk '/^## [0-9]/ { on = ($2 == 16); next } on && /^### / { cs = ($0 == "### CI scope"); next } on && cs && /^selector: / { print substr($0, 11); exit }' "$1"; }
scope_rows() { awk '/^## [0-9]/ { on = ($2 == 16); next } on && /^### / { cs = ($0 == "### CI scope"); next } on && cs && /^ROW-[0-9A-Za-z-]+ tests\/[^ ]+ (ticket|alarm)$/' "$1"; }
has_scope() { [ -n "$(awk '/^## [0-9]/ { on = ($2 == 16); next } on && $0 == "### CI scope" { print 1; exit }' "$1")" ]; }
# tests_of <ticket>: section 16's acceptance test paths
tests_of() { awk '/^## [0-9]/ { on = ($2 == 16); next } on && /^### / { acc = ($0 == "### Acceptance tests"); next } on && acc && f == "" && /^#### / { print substr($0, 6); w = 1; next } w && NF == 0 { next } w { w = 0; f = $0; next } f != "" && $0 == f { f = "" }' "$1"; }
codekey() { [ -f ARCHITECTURE.md ] && sed -n '/^```vid-code[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md | sed -n "s/^$1:[[:space:]]*//p" | head -n 1 | sed 's/[[:space:]]*$//'; }
enc() { printf '%s' "$1" | sed 's/ /%20/g'; }
mapget() { [ -f .vid/tickets/map ] && awk -v w="$1" -v k="$2" -v v="$3" -v f="$4" 'function kv(x,  i) { for (i = 2; i <= NF; i++) if (index($i, x "=") == 1) return substr($i, length(x) + 2); return "" } $1 == w && kv(k) == v { o = kv(f) } END { print o }' .vid/tickets/map; }
# junit <xml>…: the reader
junit() {
  for _x in "$@"; do [ -f "$_x" ] && cat "$_x"; done | awk '
    function attr(s, a,   p, t, q) { p = index(s, " " a "=\""); if (!p) { p = index(s, "\t" a "=\""); if (!p) return "" } t = substr(s, p + length(a) + 3); q = index(t, "\""); return dec(substr(t, 1, q - 1)) }
    function dec(s) { gsub(/&lt;/, "<", s); gsub(/&gt;/, ">", s); gsub(/&quot;/, "\"", s); gsub(/&apos;/, "\047", s); gsub(/&amp;/, "\\&", s); return s }
    { all = all " " $0 }
    END {
      n = split(all, parts, /<testcase[ \t>]/)
      for (i = 2; i <= n; i++) {
        c = parts[i]; e = index(c, ">"); head = substr(c, 1, e); rest = substr(c, e + 1)
        if (substr(head, length(head) - 1, 1) == "/") body = ""; else { q = index(rest, "</testcase>"); body = (q ? substr(rest, 1, q - 1) : rest) }
        nm = attr(" " head, "name"); fl = attr(" " head, "file"); cl = attr(" " head, "classname"); tm = attr(" " head, "time"); if (tm == "") tm = 0
        if (index(nm, "::")) id = nm; else if (fl != "") id = fl "::" nm; else if (cl != "") id = cl "::" nm; else id = nm
        gsub(/[ \t]/, "_", id)
        st = "passed"; if (body ~ /<failure[ \t\/>]/) st = "failed"; else if (body ~ /<error[ \t\/>]/) st = "error"; else if (body ~ /<skipped[ \t\/>]/) st = "skipped"
        printf "case %s %s %s\n", id, st, tm
      }
    }'
}

# planprep: the plan block, the inventory's ROW requirements and each ROW's stage → $W/plan, $W/inv, $W/so; NS, LO; and
# each step's stage → $W/stepst (`<step>\t<stage>`: its first row's, else 1), as the plan page counts it
planprep() {
  [ -f .vid/RUN-STATE.md ] || tref 'no .vid/RUN-STATE.md'
  awk '/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md > "$W/plan"
  [ -s "$W/plan" ] || tref 'RUN-STATE has no vid-plan block'
  sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md 2>/dev/null | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } tr($1) ~ /^ROW-/ { print tr($1) "\t" tr($7) }' > "$W/inv"
  NS=1; [ -f STAGES.md ] && NS=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | sed -n 's/^[[:space:]]*STAGE-0*\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n | tail -n 1)
  LO=1; [ -f STAGES.md ] && sed -n '/^```vid-stages/,/^```$/p' STAGES.md | grep -qE '^[[:space:]]*STAGE-0+[[:space:]]*\|' && LO=0
  : > "$W/stageof"
  k=$LO; while [ "$k" -le "${NS:-1}" ]; do
    if [ -f STAGES.md ] && [ -f checks/stages.sh ]; then sh checks/stages.sh scope --upto "$k" 2>/dev/null | awk -v k="$k" '{ print $1 "\t" k }' >> "$W/stageof"; else cut -f1 "$W/inv" | awk '{ print $1 "\t1" }' >> "$W/stageof"; fi
    k=$((k + 1)); done
  awk -F'\t' '!s[$1]++' "$W/stageof" > "$W/so"
  awk -F'|' -v sof="$W/so" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN { while ((getline l < sof) > 0) { split(l, a, "\t"); SO[a[1]] = a[2] } }
    /^[ \t]*step[ \t]/ { id = tr($1); sub(/^step[ \t]+/, "", id); rw = ""; for (i = 2; i <= NF; i++) { x = tr($i); if (x ~ /^rows:/) rw = tr(substr(x, 6)) }
      n = split(rw, R, /[ \t]+/); st = ""; for (j = 1; j <= n; j++) if (st == "" && (R[j] in SO)) st = SO[R[j]]; if (st == "") st = 1; print id "\t" st }' "$W/plan" > "$W/stepst"
}
# forecast <stage>: the CI minutes forecast (v0.26.10.12 R7) — a forecast, labelled as one; nothing gates on it and
# nothing reads an allowance or a bill. tickets: the stage's steps, one ticket each, and its fix tickets so far; full
# runs: the run-full started events since the last stage-closed for the current stage (at least 1). Durations: the mean
# test time in the imported CI runs' reports (the sum of their cases' seconds) — a pull request's run scoped, main's
# (pr=-) full — labelled measured; else unknown until the skeleton's first run. After planprep.
forecast() {
  _t=$(awk -F'\t' -v k="$1" '$2 == k' "$W/stepst" | grep -c . || true)
  _f=$( [ -f .vid/tickets/map ] && awk -v sf="$W/stepst" -v k="$1" 'BEGIN { while ((getline l < sf) > 0) { split(l, a, "\t"); S[a[1]] = a[2] } }
    $1 == "ticket" && index($0, " kind=fix ") { for (i = 2; i <= NF; i++) if (index($i, "step=") == 1 && S[substr($i, 6)] == k) n++ } END { print n + 0 }' .vid/tickets/map || echo 0)
  _t=$((_t + ${_f:-0})); _k=1
  _cs=$(sed -n 's/^stage:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | awk '{ print $1 }')
  if [ "$1" = "$_cs" ] && [ -f .vid/metrics-events ]; then _r=$(awk '$1 == "stage-closed" { n = 0 } $1 == "run-full" && $2 == "started" { n++ } END { print n + 0 }' .vid/metrics-events); [ "$_r" -gt 1 ] && _k=$_r; fi
  if [ ! -f "$W/durs" ]; then
    { [ -f .vid/metrics-events ] && awk '$1 == "ledger-run" && index($0, " type=ci ") { r = ""; p = ""; for (i = 2; i <= NF; i++) { if (index($i, "report=") == 1) r = substr($i, 8); if (index($i, "pr=") == 1) p = substr($i, 4) } if (r != "" && !s[r]++) print r "\t" (p == "-" ? "full" : "scoped") }' .vid/metrics-events; } | while IFS='	' read -r _rn _rk; do
      [ -f ".vid/ledger-results/$_rn.cases" ] && awk -v k="$_rk" '$1 == "case" { s += $4 } END { print k "\t" s + 0 }' ".vid/ledger-results/$_rn.cases"
    done > "$W/durs"
  fi
  awk -F'\t' -v st="$1" -v t="$_t" -v k="$_k" '{ if ($1 == "scoped") { sa += $2; na++ } else { sf += $2; nf++ } }
    END { m = na ? sprintf("%.1f", sa / na / 60) : "unknown"; f = nf ? sprintf("%.1f", sf / nf / 60) : "unknown"
      tot = (na && nf) ? sprintf("%.1f", sa / na / 60 * t + sf / nf / 60 * k) : "unknown"
      if (!na && !nf) src = "unknown until the skeleton\047s first run"
      else if (na && nf) src = "measured: the mean test time in the reports of " na " pull-request and " nf " full runs"
      else if (na) src = "measured: the mean test time in the reports of " na " pull-request runs; the full run unknown until its first run"
      else src = "measured: the mean test time in the reports of " nf " full runs; the scoped run unknown until a ticket\047s first run"
      printf "ci-minutes forecast stage=%s: scoped %s min × %s tickets + full %s min × %s runs ≈ %s min (%s)\n", st, m, t, f, k, tot, src }' "$W/durs"
}

CMD=${1:-}; [ $# -gt 0 ] && shift
case "$CMD" in
  junit)
    [ $# -ge 1 ] || usage
    junit "$@"; exit 0 ;;

  body)
    TF=${1:-}; [ -n "$TF" ] && [ -f "$TF" ] || usage; shift
    ISS=pending; OD=''
    while [ $# -gt 0 ]; do case "$1" in --issue) ISS=${2:-}; shift 2 ;; --out) OD=${2:-}; shift 2 ;; *) usage ;; esac; done
    H=$(stamp "$TF"); [ -n "$H" ] || tref "$TF carries no written: stamp — write it with brief.sh write --ticket or ticket.sh skeleton-body"
    [ "$H" = "$(chash "$TF")" ] || tref "$TF changed after writing (its stamp reads $H) — write it again"
    K=$(kind_of "$TF"); BASE=$(hk "$TF" base); [ -n "$BASE" ] || tref "$TF names no base: — it is not a ticket"
    STP=$(hk "$TF" step); [ -n "$STP" ] || STP=-
    STG=$(awk '/^## 16 / { on = 1; next } on && /^stage: / { print $2; exit }' "$TF"); [ -n "$STG" ] || STG=$(sed -n 's/^stage:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | awk '{ print $1 }'); [ -n "$STG" ] || STG=1
    if [ "$K" = skeleton ]; then RW=none; RUN=-; else
      RW=$(rows_of "$TF" | paste -sd ' ' -); [ -n "$RW" ] || RW=none
      RUN=$(awk '/^## [0-9]/ { on = ($2 == 6); next } on && index($0, " -- ") { s = $0; sub(/.* -- /, "", s); print s; exit }' "$TF"); [ -n "$RUN" ] || RUN=-
    fi
    [ -n "$OD" ] || { _nm=$(basename "$TF" .md); case "$TF" in .vid/briefs/*) _nm=$(printf '%s' "${TF#.vid/briefs/}" | sed 's#\.md$##; s#/#-#g') ;; esac; OD=.vid/tickets/parts/$_nm; }
    mkdir -p "$OD"; rm -f "$OD"/part-*.md
    # the header's largest form (part 1, a two-digit count), for the budget
    hdr() { printf '```vid-ticket\nissue=%s step=%s stage=%s kind=%s part=%s/%s hash=%s base=%s branch=vid/%s\n' "$ISS" "$STP" "$STG" "$K" "$1" "$2" "$H" "$BASE" "$ISS"
      [ "$1" = 1 ] && printf 'rows: %s\nrun: %s\n' "$RW" "$RUN"; printf '```\n'; }
    HB=$(( $(hdr 1 99 | wc -c) + 48 ))
    BUD=$((LIMIT - HB))
    # pack: line ranges, sections whole where they fit, a larger section at line boundaries
    awk -v bud="$BUD" '
      { L[NR] = length($0) + 1; if ($0 ~ /^## [0-9]/) S[NR] = 1 }
      END {
        ns = 0; st[++ns] = 1; for (i = 2; i <= NR; i++) if (S[i]) st[++ns] = i; st[ns + 1] = NR + 1
        p = 1; from = 1; size = 0
        for (k = 1; k <= ns; k++) {
          a = st[k]; b = st[k + 1] - 1; z = 0; for (i = a; i <= b; i++) z += L[i]
          if (size + z <= bud) { size += z; continue }
          if (size > 0) { print from "\t" a - 1; from = a; size = 0 }
          if (z <= bud) { size = z; continue }
          for (i = a; i <= b; i++) {
            if (L[i] > bud) { print "LINE\t" i; exit 1 }
            if (size + L[i] > bud) { print from "\t" i - 1; from = i; size = 0 }
            size += L[i]
          }
        }
        if (NR >= from) print from "\t" NR
      }' "$TF" > "$W/ranges" || tref "line $(sed -n 's/^LINE\t//p' "$W/ranges") of $TF is longer than a part can hold"
    NP=$(grep -c . "$W/ranges"); k=0
    while IFS='	' read -r a b; do
      k=$((k + 1)); o="$OD/part-$k.md"
      { hdr "$k" "$NP"; sed -n "${a},${b}p" "$TF"; printf '<!-- vid-ticket end part=%s/%s -->\n' "$k" "$NP"; } > "$o"
      [ "$(wc -c < "$o")" -le "$LIMIT" ] || tref "part $k of $TF is over $LIMIT bytes"
      printf '%s\n' "$o"
    done < "$W/ranges"
    exit 0 ;;

  fetch)
    ISS=${1:-}; [ -n "$ISS" ] || usage; shift
    FD=''; OUT=''
    while [ $# -gt 0 ]; do case "$1" in --from) FD=${2:-}; shift 2 ;; --out) OUT=${2:-}; shift 2 ;; *) usage ;; esac; done
    [ -n "$FD" ] && [ -d "$FD" ] || usage
    [ -n "$OUT" ] || OUT=$FD/ticket.md
    : > "$W/idx"; : > "$W/stale"
    # the issue's body (body.md, as github.sh saves it) is the current writing: a comment part of another hash= is an
    # earlier writing's (R13: an untaken ticket is rewritten by a new body and new comment parts) and is skipped
    CUR=''; [ -f "$FD/body.md" ] && CUR=$(tr -d '\r' < "$FD/body.md" | awk 'NF && !s { s = 1; if ($0 !~ /^```vid-ticket/) exit; next } s { print; exit }' | tr ' ' '\n' | sed -n 's/^hash=//p')
    for f in "$FD"/*; do
      [ -f "$f" ] || continue; [ "$f" = "$OUT" ] && continue
      tr -d '\r' < "$f" > "$W/one"
      awk 'NF { if ($0 ~ /^```vid-ticket[ \t]*$/) f = 1; exit } END { exit !f }' "$W/one" || continue
      _h=$(awk 'NF && !s { s = 1; next } s && /^```[ \t]*$/ { exit } s' "$W/one" | head -n 1)
      _i=$(printf '%s\n' "$_h" | tr ' ' '\n' | sed -n 's/^issue=//p'); _p=$(printf '%s\n' "$_h" | tr ' ' '\n' | sed -n 's/^part=//p'); _x=$(printf '%s\n' "$_h" | tr ' ' '\n' | sed -n 's/^hash=//p')
      [ "$_i" = "$ISS" ] || tref "$f holds a part of issue ${_i:-?}, not $ISS"
      if [ -n "$CUR" ] && [ "$_x" != "$CUR" ]; then printf '%s\n' "${f##*/}" >> "$W/stale"; continue; fi
      _k=${_p%%/*}; _n=${_p#*/}
      case "$_k$_n" in ''|*[!0-9]*) tref "$f: a part header without part=<k>/<n>" ;; esac
      grep -qx "$_k" "$W/idx.k" 2>/dev/null && tref "part $_k of issue $ISS appears twice"
      printf '%s\n' "$_k" >> "$W/idx.k"; printf '%s\t%s\t%s\n' "$_k" "$_n" "$_x" >> "$W/idx"
      awk -v e="<!-- vid-ticket end part=$_p -->" 'NF && !s { s = 1; next } s == 1 && /^```[ \t]*$/ { s = 2; next } s == 2 { if ($0 == e || substr($0, 1, length(e)) == e) { f = 1; exit } print } END { exit !f }' "$W/one" > "$W/c.$_k" || tref "part $_k of issue $ISS has no end line (it was cut)"
    done
    [ -s "$W/idx" ] || tref "no part of issue $ISS in $FD"
    [ "$(cut -f2 "$W/idx" | sort -u | grep -c .)" -eq 1 ] || tref "the parts of issue $ISS disagree on their count"
    [ "$(cut -f3 "$W/idx" | sort -u | grep -c .)" -eq 1 ] || tref "the parts of issue $ISS disagree on hash="
    N=$(cut -f2 "$W/idx" | head -n 1); X=$(cut -f3 "$W/idx" | head -n 1)
    k=1; : > "$W/joined"
    while [ "$k" -le "$N" ]; do [ -f "$W/c.$k" ] || tref "part $k of $N of issue $ISS is missing$( [ -s "$W/stale" ] && printf ' (skipped as an earlier writing, its hash= not the body'"'"'s: %s)' "$(paste -sd ' ' "$W/stale")")"; cat "$W/c.$k" >> "$W/joined"; k=$((k + 1)); done
    S=$(stamp "$W/joined"); [ "$S" = "$X" ] || tref "the joined ticket's written: stamp (${S:-none}) is not the parts' hash= ($X)"
    [ "$S" = "$(chash "$W/joined")" ] || tref "the joined ticket does not hash to its written: stamp — a part was changed"
    mkdir -p "$(dirname "$OUT")"; cp "$W/joined" "$OUT"
    echo "ViD ticket: issue $ISS joined from $N parts → $OUT"
    [ -s "$W/stale" ] && echo "    skipped as an earlier writing: $(paste -sd ' ' "$W/stale")"
    exit 0 ;;

  return-check)
    BF=${1:-}; [ -n "$BF" ] && [ -f "$BF" ] || usage; shift
    TKF=''; [ "${1:-}" = --ticket ] && TKF=${2:-}
    [ -z "$TKF" ] || [ -f "$TKF" ] || usage
    tr -d '\r' < "$BF" > "$W/b"
    NB=$(grep -cE '^```vid-return( 1)?[ \t]*$' "$W/b" || true)
    [ "$NB" -eq 0 ] && { echo 'return-check: refused — no ```vid-return block in the description'; exit 1; }
    [ "$NB" -gt 1 ] && { echo "return-check: refused — $NB vid-return blocks; the description holds one"; exit 1; }
    awk '/^```vid-return( 1)?[ \t]*$/ { on = 1; next } on && /^```[ \t]*$/ { exit } on { print NR "\t" $0 }' "$W/b" > "$W/blk"
    TK=''; TROWS=''
    if [ -n "$TKF" ]; then TK=$(kind_of "$TKF"); rows_of "$TKF" > "$W/want"; else : > "$W/want"; fi
    # v0.26.10.12 (R1): run-full is asked of a skeleton ticket written under this release, whose body asks for it
    NRF=0; [ "$TK" = skeleton ] && grep -q '^skeleton: run-full:' "$TKF" && NRF=1
    # v0.26.10.12 (R2): one ci-scope: line; with --ticket, the ticket's selector when its CI scope names one
    WSC=0; WSS=''; [ -n "$TKF" ] && has_scope "$TKF" && { WSC=1; WSS=$(scope_sel "$TKF"); }
    awk -F'\t' -v kind="$TK" -v wf="$W/want" -v nrf="$NRF" -v wsc="$WSC" -v wss="$WSS" '
      function r(m) { print "line " $1 ": " m; bad = 1 }
      function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      BEGIN { while ((getline l < wf) > 0) if (l != "") { WANT[l] = 1; nw++ } split("test-framework test-dir run-one ci-workflow report", SK, " ") }
      { l = $2; t = tr(l) }
      t == "" { next }
      t ~ /^ticket:/ { have["ticket"] = 1; v = tr(substr(t, 8)); if (v !~ /^#[0-9]+$/) r("ticket: takes #<issue number>, not \"" v "\""); sec = ""; next }
      t ~ /^rows:/ { have["rows"] = 1; v = tr(substr(t, 6)); sec = "rows"; if (v == "none") rnone = 1; else if (v != "") r("rows: is followed by one line per row, or reads rows: none"); next }
      t ~ /^ci-scope:/ { nci++; CIS = tr(substr(t, 10)); if (CIS == "") r("ci-scope: names the ticket'"'"'s selector, as its CI scope gives it"); sec = ""; next }
      t ~ /^skeleton:/ { v = tr(substr(t, 10)); k = v; sub(/:.*/, "", k); val = v; sub(/^[^:]*:/, "", val); val = tr(val); if (val == "") r("skeleton: " k " has no value"); SKL[k] = 1; sec = ""; next }
      t ~ /^(decisions|discovered|law-needed|questions):/ { s = t; sub(/:.*/, "", s); have[s] = 1; sec = s; if (tr(substr(t, length(s) + 2)) != "") r(s ": is followed by its list (- … lines, or - none)"); next }
      sec == "rows" {
        if (t ~ /^- none$/) next
        n = split(t, w, /[ \t]+/); id = w[1]
        if (id !~ /^[^\/]+\/ROW-[0-9A-Za-z-]+$/) { r("a row line reads <REQ-id>/<ROW-id> pass|fail|not-run ci: <run id> [reason: <one line>]: " t); next }
        row = id; sub(/^[^\/]*\//, "", row); st = w[2]
        if (row in SEEN) { r(row " appears twice"); next } SEEN[row] = 1; nr++
        if (nw && !(row in WANT)) r(row " is not a row of the ticket")
        if (st != "pass" && st != "fail" && st != "not-run") { r(row ": unknown state \"" st "\" (pass, fail or not-run)"); next }
        ci = ""; rs = ""; p = index(t, " ci:"); q = index(t, " reason:")
        if (p) { ci = substr(t, p + 4); if (q > p) ci = substr(t, p + 4, q - p - 4); ci = tr(ci) }
        if (q) rs = tr(substr(t, q + 8))
        if ((st == "pass" || st == "fail") && ci == "") r(row ": a " st " names its CI run (ci: <run id>)")
        if ((st == "fail" || st == "not-run") && rs == "") r(row ": a " st " gives its reason (reason: <one line>)")
        next }
      sec == "discovered" {
        if (t ~ /^- none$/) next
        if (t !~ /^- /) { r("discovered: items are - <kind>: <one line>: " t); next }
        x = tr(substr(t, 3)); k = x; sub(/:.*/, "", k); k = tr(k)
        if (k != "early-technical" && k != "user-visible" && k != "new-work" && k != "blocked-by") { r("unknown discovery kind \"" k "\" (early-technical, user-visible, new-work, blocked-by)"); next }
        if (k == "blocked-by" && x !~ /^blocked-by:[ \t]*#[0-9]+$/) r("blocked-by: takes #<ticket>")
        next }
      sec == "law-needed" { if (t ~ /^- none$/) next; if (t !~ /^- ROW-[0-9A-Za-z-]+:[ \t]*[^ \t]/) r("law-needed: items are - <ROW-id>: <why the test or requirement looks wrong>: " t); next }
      sec == "decisions" || sec == "questions" { if (t !~ /^- [^ \t]/) r(sec ": items are - <one line>: " t); next }
      { r("not part of the block: " t) }
      END {
        split("ticket rows decisions discovered law-needed questions", M, " ")
        for (i = 1; i <= 6; i++) if (!(M[i] in have)) { print "the block has no " M[i] ": section"; bad = 1 }
        skel = (kind == "skeleton" || (kind == "" && rnone))
        if (skel) { if (!rnone) { print "the skeleton ticket'"'"'s block reads rows: none"; bad = 1 }
          for (i = 1; i <= 5; i++) if (!(SK[i] in SKL)) { print "the skeleton ticket'"'"'s block has no skeleton: " SK[i] ": line"; bad = 1 }
          if (nrf && !("run-full" in SKL)) { print "the skeleton ticket'"'"'s block has no skeleton: run-full: line (its ticket asks how the full run is started)"; bad = 1 } }
        else if (rnone) { print "rows: none belongs to the skeleton ticket; a feature or fix ticket lists its rows"; bad = 1 }
        if (nw) for (x in WANT) if (!(x in SEEN)) { print x " of the ticket is missing from rows:"; bad = 1 }
        if (nci > 1) { print "ci-scope: appears " nci " times; the block holds one"; bad = 1 }
        else if (wsc && !nci) { print "the block has no ci-scope: line — the ticket'"'"'s CI scope gives its selector: " wss; bad = 1 }
        else if (wsc && CIS != "" && CIS != wss) { print "ci-scope: reads \"" CIS "\", not the ticket'"'"'s selector \"" wss "\""; bad = 1 }
        exit bad }' "$W/blk" > "$W/rc" && { echo 'return-check: ok'; exit 0; }
    echo 'return-check: refused —'; sed 's/^/    /' "$W/rc"; exit 1 ;;

  skeleton-body)
    REQ=''; MISS=''; OUT=.vid/tickets/skeleton.md
    while [ $# -gt 0 ]; do case "$1" in --req) REQ=${2:-}; shift 2 ;; --missing) MISS=${2:-}; shift 2 ;; --out) OUT=${2:-}; shift 2 ;; *) usage ;; esac; done
    [ -n "$REQ" ] || usage
    QH=$(git rev-parse HEAD 2>/dev/null) || tref 'no commit at HEAD — the skeleton ticket quotes ViD'"'"'s records at HEAD'
    BASE=$(git -C .vid/code rev-parse -q --verify 'refs/remotes/origin/main^{commit}' 2>/dev/null) || tref "the read-only copy (.vid/code) has no origin/main — the code repository's main must exist (its root commit), then git -C .vid/code fetch"
    git show HEAD:PRD.md > "$W/prd" 2>/dev/null || tref 'no PRD.md at HEAD'
    [ -f checks/prd.sh ] || tref 'checks/prd.sh is missing — the effective-set reader'
    sh checks/prd.sh --effective "$W/prd" > "$W/eff" 2>/dev/null || : > "$W/eff"
    RL=$(awk -F'|' -v r="$REQ" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); sub(/[ \t]+AMENDED$/, "", x) } x == r { l = $0 } END { print l }' "$W/eff")
    [ -n "$RL" ] || tref "$REQ is no item of the effective PRD at HEAD"
    sec() { git show "HEAD:$1" 2>/dev/null | awk -v h="$2" 'on && /^## / { exit } index($0, h) == 1 { on = 1 } on'; }
    blk() { git show "HEAD:$1" 2>/dev/null | sed -n "/^\`\`\`$2[[:space:]]*\$/,/^\`\`\`[[:space:]]*\$/p"; }
    modt() { git show HEAD:ARCHITECTURE.md 2>/dev/null | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^[ \t]*\|/ { if (done) next; if (!intab) { n = split($0, c, "|"); for (k = 2; k < n; k++) if (tr(c[k]) == "Module") intab = 1 } if (intab) print; next } { if (intab) done = 1 }'; }
    mkdir -p "$(dirname "$OUT")"
    {
      printf 'kind: skeleton\nquoted-at: %s\nbase: %s\n' "$QH" "$BASE"
      [ -n "$MISS" ] && printf 'fix: %s\n' "$(printf '%s' "$MISS" | tr '\n' ' ')"
      printf '\n## 1 what this ticket asks for\n\n'
      [ -n "$MISS" ] && printf 'This is a fix of the skeleton: what the merged skeleton does not bear out is named in section 8; the rest stands as first asked.\n\n'
      cat <<'ASK'
The code skeleton, built from the specification quoted below, before any feature:
- the toolchain and lockfile of the stack decided in section 2 — no tool the specification did not decide;
- the layout of the placement block (section 3), with a place for each module of section 4;
- one golden-path example wired end to end that renders a placeholder — wired so the skeleton is real, not so the
  requirement in section 7 is met;
- a test set-up in which the product side's acceptance tests can run through the product's public surface only,
  under `tests/` (the acceptance tests of later tickets live there);
- a CI workflow that:
  - on a pull request (opened, synchronize, reopened, edited), reads the `ci-scope:` line of the pull request's
    vid-return block and runs only the tests it selects; when the line is missing or unreadable it runs every test.
    The description is read through an environment variable, never pasted into a shell step;
  - on a manual start of main, runs every test on the commit it is started on (the run's own commit; no commit
    input);
  - runs nothing on a push to main (you may add your own runs; ViD reads none);
  - checks out the exact commit (the pull request's head commit, not the merge preview; on a manual start, the run's
    own commit), and always publishes a per-test report in JUnit XML as an artifact named for the run attempt,
    `vid-junit-<run attempt>`. Each testcase's `name` is `<test path>::<test name>`, or its `file` attribute is the
    test's path from the repository root; the test name carries the ROW id the test is for;
- in the pull request's return block, one `skeleton:` line each for test-framework, test-dir (under tests/), run-one
  (the command that runs named tests), ci-workflow (the workflow's name), report (the artifact's name) and run-full
  (how the full run is started).
ASK
      printf '\n## 2 the stack (BASELINE.md'"'"'s ## Stack at %s)\n\n' "$QH"; sec BASELINE.md '## Stack' | sed 1d | grep . || echo none
      printf '\n## 3 the placement (CLAUDE.md'"'"'s vid-placement block)\n\n'; blk CLAUDE.md vid-placement | grep . || echo none
      printf '\n## 4 the modules (ARCHITECTURE.md'"'"'s module table)\n\n'; modt | grep . || echo none
      printf '\n## 5 the seams (INVENTORY.md'"'"'s seam rows)\n\n'; git show HEAD:INVENTORY.md 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | grep -E '^[[:space:]]*seam[[:space:]]*\|' || echo none
      printf '\n## 6 the external services (the vid-hosting block'"'"'s providers:)\n\n'; blk ARCHITECTURE.md vid-hosting | grep -E '^providers:' || echo none
      printf '\n## 7 the golden-path example'"'"'s requirement (the effective PRD at %s)\n\n%s\n' "$QH" "$RL"
      [ -n "$MISS" ] && printf '\n## 8 what is missing\n\n%s\n' "$MISS"
      cat <<'INS'

## 9 instructions

1. Claim it: fetch, then create this ticket's branch (its header's `branch=`) from its base (`base=`, the code
   repository's root commit) with one empty commit, pushed only if the branch does not exist yet:

       git fetch origin
       claim=$(git commit-tree <base>^{tree} -p <base> -m "claim #<issue> <your name>")
       git push --force-with-lease=refs/heads/vid/<issue>: origin "$claim":refs/heads/vid/<issue>

2. Build what section 1 asks for on that branch; any path is yours.
3. Blocked? Open a draft pull request with the question in its block's `questions:`, label this ticket `blocked`.
4. Done: open a pull request from the branch, "Closes #<issue>", with this block at the end of its description.

## 10 the return block (vid-return 1)

```vid-return
ticket: #<issue>
rows: none
skeleton: test-framework: <its name>
skeleton: test-dir: tests/<the folder>
skeleton: run-one: <the command that runs named tests>
skeleton: ci-workflow: <the workflow's name>
skeleton: report: vid-junit-<run attempt>
skeleton: run-full: <how the full run is started>
decisions:
  - none
discovered:
  - none
law-needed:
  - none
questions:
  - none
```
INS
    } > "$W/body"
    H=$(git hash-object "$W/body")
    awk -v h="$H" '{ print } NR == 3 { print "written: ticket.sh skeleton-body " h }' "$W/body" > "$W/out"
    # the stamp line goes after the header (kind, quoted-at, base, and fix: when given)
    if [ -n "$MISS" ]; then awk -v h="$H" '{ print } NR == 4 { print "written: ticket.sh skeleton-body " h }' "$W/body" > "$W/out"; fi
    cp "$W/out" "$OUT"
    [ "$(chash "$OUT")" = "$H" ] || tref 'the stamp does not hold (internal)'
    echo "ViD ticket: the skeleton ticket → $OUT"; exit 0 ;;

  import)
    [ $# -ge 1 ] || usage
    REPO=$(codekey repo); WF=$(codekey ci-workflow)
    [ -n "$REPO" ] || tref "ARCHITECTURE.md's vid-code block names no repo: — the code repository"
    # the skeleton ticket's own pull request is imported before the test facts exist: its workflow is the one its block
    # names (`skeleton: ci-workflow: <name>`), checked against the merged code afterwards (vid-replan)
    if [ -z "$WF" ] && [ "$1" != --main ] && [ -f ".vid/tickets/pr-$1/meta" ]; then
      _tk=$(tr ' ' '\n' < ".vid/tickets/pr-$1/meta" | sed -n 's/^ticket=//p'); _br=$(mapget ticket number "$_tk" brief)
      if [ -n "$_br" ] && [ -f "$_br" ] && [ "$(kind_of "$_br")" = skeleton ]; then
        WF=$(tr -d '\r' < ".vid/tickets/pr-$1/body.md" | sed -n 's/^[[:space:]]*skeleton:[[:space:]]*ci-workflow:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//')
      fi
    fi
    [ -n "$WF" ] || tref "ARCHITECTURE.md's vid-code block names no ci-workflow: yet — the skeleton's test facts come first"
    git -C .vid/code rev-parse -q --verify HEAD > /dev/null 2>&1 || tref 'no read-only copy at .vid/code'
    # selrun <dir> <sha>: the newest attempt of the newest run of the workflow, repository and commit → RUN, ATT; else WHY
    selrun() {
      RUN=''; ATT=''; WHY=''
      [ -f "$1/runs" ] || { WHY="no CI run was fetched for $2"; return 1; }
      _l=$(awk -v s="$2" -v w="$(enc "$WF")" -v r="$REPO" 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
        $1 == "run" && index(kv("sha"), s) == 1 && kv("workflow") == w && kv("repo") == r { id = kv("id") + 0; a = kv("attempt") + 0; if (id > bi || (id == bi && a > ba)) { bi = id; ba = a } } END { if (bi) print bi "\t" ba }' "$1/runs")
      if [ -n "$_l" ]; then RUN=${_l%%	*}; ATT=${_l#*	}; return 0; fi
      if awk -v s="$2" 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" } $1 == "run" && index(kv("sha"), s) == 1 { f = 1 } END { exit !f }' "$1/runs"; then
        WHY="the runs that tested $2 are not of the repository $REPO and workflow $WF (a run of another workflow or repository)"
      elif grep -q '^run ' "$1/runs"; then WHY="no run of $WF tested $2 — the runs fetched tested another commit"
      else WHY="no CI run was fetched for $2"; fi
      return 1
    }
    # selbound <dir> <sha>: the full run ViD started at that commit (v0.26.10.12 R4) — BRUN and BSHA from its `run-full
    # started` event — its newest attempt fetched there, complete, of the workflow and repository → RUN, ATT; any other
    # run of the workflow is never read; else WHY
    selbound() {
      RUN=''; ATT=''; WHY=''
      [ -f "$1/runs" ] || { WHY="no CI run was fetched for $2 (sh checks/github.sh pull --commit $2)"; return 1; }
      _l=$(awk -v id="$BRUN" -v w="$(enc "$WF")" -v r="$REPO" 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
        $1 == "run" && kv("id") == id && kv("workflow") == w && kv("repo") == r && kv("attempt") + 0 >= ba { ba = kv("attempt") + 0; st = kv("status"); sh = kv("sha") } END { if (ba) print ba "\t" st "\t" sh }' "$1/runs")
      [ -n "$_l" ] || { WHY="the full run $BRUN that ViD started was not fetched at $2 (sh checks/github.sh pull --commit $2 once it is complete)"; return 1; }
      _st=$(printf '%s' "$_l" | cut -f2); _sh=$(printf '%s' "$_l" | cut -f3)
      case "$_sh" in "$BSHA"*) ;; *) WHY="run $BRUN tested $_sh, not $BSHA, the commit its run-full started event names"; return 1 ;; esac
      [ "$_st" = completed ] || { WHY="the full run $BRUN is not complete (status=$_st) — pull --commit again once it is"; return 1; }
      RUN=$BRUN; ATT=$(printf '%s' "$_l" | cut -f1)
    }
    # report <dir> <run> <attempt>: the report's xml files → $W/xml (their list); else WHY
    report() {
      _a="$1/artifacts/$2-$3"
      if [ -f "$_a.none" ] || [ ! -d "$_a" ]; then WHY="run $2 attempt $3 has no report named vid-junit-$3 (the artifact of an earlier attempt, or none, cannot stand in)"; return 1; fi
      find "$_a" -type f -name '*.xml' | LC_ALL=C sort > "$W/xml"
      [ -s "$W/xml" ] || { WHY="the artifact vid-junit-$3 of run $2 holds no JUnit XML file"; return 1; }
    }
    # expect <rowlines file> <cases file>: every row with a test path has a case under it naming it → missing ids
    expect() { awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { id = tr($1); t = tr($8); sub(/[ \t].*/, "", t); if (t ~ /^tests\//) print id "\t" t }' "$1" | while IFS='	' read -r _id _p; do
        awk -v id="$_id" -v p="$_p::" 'BEGIN { alt = id; gsub(/-/, "_", alt) } $1 == "case" && index($2, p) == 1 && (index($2, id) || index($2, alt)) { f = 1 } END { exit !f }' "$2" || printf '%s (%s)\n' "$_id" "$_p"
      done; }
    publish() { # <sha> <run> <attempt> <pr|-> <rows file> [stage]
      _rn="$(printf '%s' "$1" | cut -c1-12).ci-$2-$3.xml"; mkdir -p .vid/ledger-results
      while IFS= read -r _x; do cat "$_x"; done < "$W/xml" > ".vid/ledger-results/$_rn"
      cp "$W/cases" ".vid/ledger-results/$_rn.cases"; cp "$5" ".vid/ledger-results/$_rn.rows"
      ev "ledger-run type=ci report=$_rn repo=$REPO workflow=$(enc "$WF") run=$2 attempt=$3 commit=$(printf '%s' "$1" | cut -c1-12) pr=$4${6:+ stage=$6} status=0"
      RN=$_rn; echo "receipt: .vid/ledger-results/$_rn ($(grep -c . "$W/cases") cases; rows: $(paste -sd ' ' "$5"))"
    }
    if [ "$1" = --main ]; then
      SHA=${2:-}; [ "${3:-}" = --stage ] && STG=${4:-} || usage
      [ -n "$SHA" ] && [ -n "$STG" ] || usage
      D=.vid/tickets/commit-$SHA; [ -d "$D" ] || D=$(ls -d .vid/tickets/commit-"$SHA"* 2>/dev/null | head -n 1)
      [ -n "$D" ] && [ -d "$D" ] || tref "main's runs at $SHA were not fetched (sh checks/github.sh pull --commit $SHA)"
      [ -f checks/stages.sh ] && [ -f STAGES.md ] && { sh checks/stages.sh scope --upto "$STG" > "$W/scope" 2>/dev/null || tref "the scope of stages up to $STG cannot be read"; } || sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^ROW-/) print x }' > "$W/scope"
      sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' -v sf="$W/scope" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 } { x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t) } (x in S) && t ~ /^tests\// { print }' > "$W/rowlines"
      awk -F'|' '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); print x }' "$W/rowlines" > "$W/rows"
      if [ -n "$(codekey run-full)" ]; then
        # v0.26.10.12 (R4): only a full run ViD started closes a stage — the newest run-full started event at that commit
        _bl=$(awk -v s="$SHA" '$1 == "run-full" && $2 == "started" { x = ""; for (i = 3; i <= NF; i++) if (index($i, "sha=") == 1) x = substr($i, 5); if (x != "" && (index(s, x) == 1 || index(x, s) == 1)) l = $0 } END { print l }' .vid/metrics-events 2>/dev/null)
        [ -n "$_bl" ] || tref "no full run ViD started tested $SHA (no run-full started event names it: sh checks/github.sh run-full) — a pull request's run, or a run on a push to main, never closes a stage; nothing published"
        BRUN=$(printf '%s\n' "$_bl" | tr ' ' '\n' | sed -n 's/^run=//p'); BSHA=$(printf '%s\n' "$_bl" | tr ' ' '\n' | sed -n 's/^sha=//p')
        selbound "$D" "$SHA" || tref "no receipt for main at $SHA — $WHY; nothing published, the stage cannot close"
      else selrun "$D" "$SHA" || tref "no receipt for main at $SHA — $WHY; nothing published, the stage cannot close"; fi
      report "$D" "$RUN" "$ATT" || tref "no receipt for main at $SHA — $WHY; nothing published, the stage cannot close"
      junit $(cat "$W/xml") > "$W/cases"
      MISSX=$(expect "$W/rowlines" "$W/cases")
      [ -z "$MISSX" ] || tref "main's run $RUN at $SHA lacks expected tests: $(printf '%s\n' "$MISSX" | paste -sd ',' - | sed 's/,/, /g'); nothing published, the stage cannot close"
      FULL=$(git -C .vid/code rev-parse -q --verify "$SHA^{commit}" 2>/dev/null || echo "$SHA")
      publish "$FULL" "$RUN" "$ATT" - "$W/rows" "$STG"; exit 0
    fi
    N=$1; D=.vid/tickets/pr-$N
    [ -f "$D/meta" ] || tref "pull request $N was not fetched (sh checks/github.sh pull)"
    mk() { tr ' ' '\n' < "$D/meta" | sed -n "s/^$1=//p" | head -n 1; }
    TK=$(mk ticket); HS=$(mk head); MG=$(mk merge); PST=$(mk state)
    [ "$PST" = merged ] || tref "pull request $N is $PST, not merged — nothing in an open or draft pull request is read for grading"
    BR=$(mapget ticket number "$TK" brief); [ -n "$BR" ] && [ -f "$BR" ] || tref "ticket #$TK is not in .vid/tickets/map with its brief"
    K=$(kind_of "$BR"); BASE=$(hk "$BR" base)
    git -C .vid/code cat-file -e "$MG^{commit}" 2>/dev/null && git -C .vid/code cat-file -e "$HS^{commit}" 2>/dev/null || tref "the merge $MG or the head $HS is not in the read-only copy — git -C .vid/code fetch"
    git -C .vid/code checkout -q --detach "$MG" 2>/dev/null || tref "the read-only copy cannot be checked out at $MG"
    echo "import: pull request $N (ticket #$TK, $K), head $HS, merged as $MG"
    # ViD's copy check
    tests_of "$BR" > "$W/tests"; NF=0; NC=0; NM=0
    for p in $(cat "$W/tests"); do
      NF=$((NF + 1))
      if ! git -C .vid/code cat-file -e "$MG:$p" 2>/dev/null; then NM=$((NM + 1)); echo "copy-check: $p missing at the merge"; continue; fi
      git -C .vid/code show "$MG:$p" > "$W/cf"; git show "HEAD:$p" > "$W/vf" 2>/dev/null || : > "$W/vf"
      if cmp -s "$W/cf" "$W/vf"; then echo "copy-check: $p unchanged"; else NC=$((NC + 1)); echo "copy-check: $p changed at the merge — a fix ticket restores it"; fi
    done
    ev "copy-check pr=$N files=$NF changed=$NC missing=$NM"
    # tests first: the first commit past the base, claims (empty) and merges aside
    TFC=''; FIRST=''
    for c in $(git -C .vid/code rev-list --reverse --first-parent "$BASE..$HS" 2>/dev/null); do   # the branch's own line (a resume merges origin/main)
      [ "$(git -C .vid/code rev-list --parents -n 1 "$c" | wc -w)" -gt 2 ] && continue
      git -C .vid/code diff-tree --no-commit-id -r --name-status "$c" > "$W/ns"
      [ -s "$W/ns" ] || continue
      FIRST=$c
      if ! grep -qv '^A	' "$W/ns" && [ "$(cut -f2 "$W/ns" | LC_ALL=C sort)" = "$(LC_ALL=C sort "$W/tests")" ]; then TFC=$c; fi
      break
    done
    rowlines_of "$BR" > "$W/rowlines"; rows_of "$BR" > "$W/rows"
    if [ "$K" != skeleton ]; then
      if [ -z "$TFC" ] && [ -n "$FIRST" ]; then echo "tests first: not found — the first commit $FIRST does not add exactly the ticket's tests"
      elif [ -z "$TFC" ]; then echo 'tests first: not found — no commit past the base'; fi
      RED=''
      if [ -n "$TFC" ] && selrun "$D" "$TFC" && report "$D" "$RUN" "$ATT"; then
        junit $(cat "$W/xml") > "$W/tfcases"
        for id in $(cat "$W/rows"); do
          if awk -v id="$id" 'BEGIN { alt = id; gsub(/-/, "_", alt) } $1 == "case" && (index($2, id) || index($2, alt)) && $3 == "failed" { f = 1 } END { exit !f }' "$W/tfcases"; then
            ev "red-observed row=$id pr=$N commit=$(printf '%s' "$TFC" | cut -c1-12)"; RED="$RED $id"
          fi
        done
      fi
      echo "tests first: ${TFC:-none}; red observed:${RED:- none}"
      for id in $(cat "$W/rows"); do case " $RED " in *" $id "*) ;; *) echo "red not shown: $id" ;; esac; done
    fi
    # the head's CI run
    RN=''
    if ! selrun "$D" "$HS"; then echo "no receipt: $WHY — nothing published; the rows stay unverdicted"; exit 1; fi
    if ! report "$D" "$RUN" "$ATT"; then echo "no receipt: $WHY — nothing published; the rows stay unverdicted"; exit 1; fi
    junit $(cat "$W/xml") > "$W/cases"
    # v0.26.10.12 (R5): a ticket with a CI scope — every row of it (its own and the alarm set's) has a case at its
    # stamped test path; a ticket without one (written before 0.26.10.12) is read as before, every row of the ticket
    : > "$W/alarm"
    if [ "$K" != skeleton ] && has_scope "$BR"; then
      scope_rows "$BR" | awk '{ print $1 " | | | | | | | " $2 }' > "$W/exprows"
      scope_rows "$BR" | awk '$3 == "alarm" { print $1 "\t" $2 }' | while IFS='	' read -r _id _p; do
        awk -v id="$_id" -v p="$_p::" 'BEGIN { alt = id; gsub(/-/, "_", alt) } $1 == "case" && index($2, p) == 1 && (index($2, id) || index($2, alt)) && ($3 == "failed" || $3 == "error") { print id " (" $2 " " $3 ")"; exit }' "$W/cases"
      done > "$W/alarm"
    else cp "$W/rowlines" "$W/exprows"; fi
    MISSX=$(expect "$W/exprows" "$W/cases")
    if [ -n "$MISSX" ]; then echo "no receipt: run $RUN attempt $ATT lacks expected tests: $(printf '%s\n' "$MISSX" | paste -sd ',' - | sed 's/,/, /g') — nothing published; the rows stay unverdicted"; exit 1; fi
    publish "$HS" "$RUN" "$ATT" "$N" "$W/rows"
    # an alarm row red in that run is red evidence: the ticket is sent back — no hand-back, its rows stay unverdicted
    if [ -s "$W/alarm" ]; then
      echo "sent back: the alarm set is red in run $RUN attempt $ATT — $(paste -sd ',' "$W/alarm" | sed 's/,/, /g'); the hand-back is not checked and the ticket's rows stay unverdicted — a fix ticket of its step with the ticket's rows, these riding its CI scope's alarm set (vid-replan §3)"
      exit 1
    fi
    # the hand-back, from the block
    if [ "$K" = skeleton ]; then
      awk '/^```vid-return/ { on = 1; next } on && /^```/ { exit } on && /^skeleton:/' "$D/body.md" | sed 's/^/skeleton line: /'
      exit 0
    fi
    if sh "$0" return-check "$D/body.md" --ticket "$BR" > "$W/rcout" 2>&1; then
      RF=${BR%.md}.return.md
      { printf 'brief: %s\nbranch: vid/%s\ncommit: %s\n\n' "$BR" "$TK" "$HS"
        tr -d '\r' < "$D/body.md" | awk '/^```vid-return/ { on = 1; next } on && /^```/ { exit } on && /^[ \t]*rows:/ { r = 1; next } on && r && /^[ \t]*[a-z-]+:/ && $0 !~ /\/ROW-/ { r = 0 } on && r' | while IFS= read -r l; do
          _t=$(printf '%s\n' "$l" | sed 's/^[[:space:]]*//'); _id=$(printf '%s\n' "$_t" | awk '{ print $1 }' | sed 's#^[^/]*/##'); _st=$(printf '%s\n' "$_t" | awk '{ print $2 }')
          _rs=$(printf '%s\n' "$_t" | sed -n 's/.* reason:[[:space:]]*//p')
          case "$_st" in pass) printf '%s | pass | %s\n' "$_id" "$RN" ;; *) printf '%s | not | %s | %s: %s\n' "$_id" "$RN" "$_st" "${_rs:-no reason}" ;; esac
        done; } > "$RF"
      echo "hand-back: $RF"
      sh checks/brief.sh return "$RF" --agent "pr:$N" || echo "hand-back refused — the rows stay unverdicted until it is corrected"
    else
      echo "hand-back: not checked — the return block does not hold:"; sed 's/^/    /' "$W/rcout"
    fi
    exit 0 ;;

  plan-md|forecast)
    planprep
    if [ "$CMD" = forecast ]; then
      FS1=''; [ "${1:-}" = --stage ] && FS1=${2:-}
      if [ -n "$FS1" ]; then forecast "$FS1"; else k=$LO; while [ "$k" -le "${NS:-1}" ]; do forecast "$k"; k=$((k + 1)); done; fi
      exit 0
    fi
    tstate() { [ -f .vid/metrics-events ] && awk -v i="$1" 'function kv(k,  j) { for (j = 2; j <= NF; j++) if (index($j, k "=") == 1) return substr($j, length(k) + 2); return "" } $1 == "ticket" && kv("issue") == i { s = kv("state") } END { print s }' .vid/metrics-events; }
    {
      printf '# The plan\n\nFrom the records at %s: the plan block, STAGES.md, INVENTORY.md, .vid/tickets/map and the ticket events. Counts only.\n' "$(now)"
      SK=$(mapget ticket kind skeleton number)
      k=$LO; while [ "$k" -le "${NS:-1}" ]; do
        _snm=$( [ -f STAGES.md ] && sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' -v k="$k" '{ x = $1; gsub(/[ \t]/, "", x); sub(/^STAGE-0*/, "", x); if (x == "") x = 0; if (x == k) { n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print n } }')
        printf '\n## Stage %s%s\n\n' "$k" "${_snm:+ — $_snm}"
        if [ -f STAGES.md ]; then awk -v k="$k" 'on && /^## / { exit } $0 ~ "^## Stage " k "( |$)" { on = 1; next } on' STAGES.md | sed '/^<!--/,/-->$/d' | grep . || echo '(no card)'; else echo 'One stage: no STAGES.md.'; fi
        printf '\n'
        if [ "$k" = "$LO" ]; then if [ -n "$SK" ]; then _ss=$(tstate "$SK"); printf 'The skeleton ticket: #%s, %s\n\n' "$SK" "${_ss:-published}"; else printf 'The skeleton ticket: not published\n\n'; fi; fi
        printf '| step | name | rows | requirements | builds on | tickets | state |\n|---|---|---|---|---|---|---|\n'
        awk -F'|' -v k="$k" -v sof="$W/so" -v invf="$W/inv" '
          function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
          BEGIN { FS = "|"; while ((getline l < sof) > 0) { split(l, a, "\t"); SO[a[1]] = a[2] } while ((getline l < invf) > 0) { split(l, a, "\t"); DF[a[1]] = a[2] } }
          /^[ \t]*step[ \t]/ { id = tr($1); sub(/^step[ \t]+/, "", id); nm = "-"; md = "-"; bo = "-"; rw = ""
            for (i = 2; i <= NF; i++) { x = tr($i); if (x ~ /^name:/) { nm = tr(substr(x, 6)) } else if (x ~ /^builds-on:/) { bo = tr(substr(x, 11)) } else if (x ~ /^rows:/) { rw = tr(substr(x, 6)) } }
            n = split(rw, R, /[ \t]+/); st = ""; nr = 0; split("", Q); nq = 0
            for (j = 1; j <= n; j++) { if (R[j] == "") continue; nr++; if (st == "" && (R[j] in SO)) st = SO[R[j]]; m = split(DF[R[j]], d, /[ ,]+/); for (q = 1; q <= m; q++) if (d[q] ~ /^(REQ|INV)-/ && !(d[q] in Q)) { Q[d[q]] = 1; nq++ } }
            if (st == "") st = 1
            if (st == k) print id "\t" nm "\t" nr "\t" nq "\t" bo }' "$W/plan" | while IFS='	' read -r id nm nr nq bo; do
            tks=$( [ -f .vid/tickets/map ] && awk -v s="$id" 'function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" } $1 == "ticket" && kv("step") == s { print kv("number") }' .vid/tickets/map)
            tl=$(for t in $tks; do printf '#%s ' "$t"; done | sed 's/ $//'); sl=$(for t in $tks; do printf '%s ' "$(tstate "$t" | sed 's/^$/published/')"; done | sed 's/ $//')
            printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$id" "$nm" "$nr" "$nq" "$bo" "${tl:--}" "${sl:-not published}"
          done
        printf '\n%s\n' "$(forecast "$k")"
        k=$((k + 1)); done
    } > "$W/pm"
    mkdir -p .vid/tickets; cp "$W/pm" .vid/tickets/PLAN.md
    echo "ViD ticket: the plan page's source → .vid/tickets/PLAN.md"; grep '^ci-minutes forecast ' .vid/tickets/PLAN.md; exit 0 ;;

  *) usage ;;
esac
