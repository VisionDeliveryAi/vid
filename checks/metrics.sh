#!/bin/sh
# Purpose: ViD metrics — the develop dataset as counts, not prose (§10;
# definitions: DEVELOP-METRICS.md). Emits one ```vid-metrics machine block
# — the five groups: progress, honesty, evidence, cost, friction — per run
# and per slice, from four substrates: INVENTORY.md, the census and
# self-test reports, git history, and .vid/metrics-events (one line per
# event, recorded by develop, the pre-commit hook, and watchdog.sh):
#   verdict slice=N claimed=X breached=Y
#   re-verdict slice=N round=R breached=Z
#   attempts row=ID n=K · reverted row=ID · regressions slice=N n=M
#   tokens slice=N phase=build|verdict|fix|re-verdict|review n=T
#     (review: the delta coherence review an append door spawns — v0.9.1
#     3.2; slice=0 before develop's first slice)
#   rows-paid slice=N n=K · owed-close slice=N n=K
#   paid row=ID via=ledger|browser|census|deploy (the proof channel per paid
#     row — v0.9.1 3.6; a deploy-owed row paid by anything but deploy trips)
#   wall-clock slice=N seconds=S · ledger-run seconds=S
#   build-cost role= slice=N step= brief= rows= rows-passed= peak= total=
#     before-change= (v0.9.7.0.7 3.5: printed as a `cost` line, per slice)
#   incident slice=N <what> · agent-death slice=N <which>
#   stall op=<op> elapsed=<s> envelope=<s> · failif-amendment n=K
#   v0.9.2 (3.6, 3.8, 3.9b; R9, R10, R14, R16, R18):
#   verdict slice=N row=ID result=KEPT|BREACHED [transition=k/n]  (per row,
#     per transition for a journey; the latest governs; `reverted row=ID`
#     invalidates every earlier verdict for that row)
#   ledger-run seconds=S kind=full|scoped report=<name>  (written by test.sh)
#   invalidated slice=N <why> · adjudicated class=<name> <promoted|advisory|deleted> [counts]
#   engine-only breach row=ID engine=<name>
# The rows headline (3.8, R10) opens the block — rows, never tests, in
# buckets covering every row exactly once: kept (every case passed in the
# latest export-backed full report for HEAD AND the latest per-row verdict
# is KEPT) · unverdicted · breached · red (a materialised row any of whose
# collected cases is not passed, or absent) · owed · deploy-owed; with no
# such receipt it prints `receipt: none — materialised rows unverified` and
# no kept count. `claim --from <report> --to <report>` prints the slice
# claim (3.6): every materialised row all of whose cases pass in --to and
# whose latest verdict is not KEPT, plus every row not fully passing in
# --from and fully passing in --to. Two tripwires: a second full run since
# the last slice close with no `invalidated`/`incident` event between; a
# report-only extractor class with no `adjudicated` event once slice 2 has
# closed. Reports are read through checks/extractors/results.sh.
# Two principles, binding: a metric without a tripwire is vanity — every
# line is blocked elsewhere (a court), escalates (a develop law), or is
# marked uncalibrated; and COUNTS, NEVER SCORES — no quality index, no
# percentage target, no confidence rating. Miss rate and owed count are
# UNCALIBRATED: report-only this release, calibrated in v0.9 on real data
# — no threshold is set here (setting a bar before the data is the
# measured v0.5 mistake). An absent substrate reports "uncounted", never
# a silent zero. Law-commit counting is the mechanically verifiable
# subset: a commit touching checks/, or touching only rule-source files
# (checks/lawfiles); region-level law rides those same commits under the
# §4.1 standalone rule.
# v0.9.6: every join from a row (or REQ, or RULE) id to its cases also reads
# the id in the spelling a test function's name must use — `ROW_042` for
# ROW-042 — as checks/evidence.sh does (measured: 955 of the 1,239 cases of
# a live project's first full run named their row that way, and none joined).
# v0.9.3 (3.5–3.13, R8–R11, R15, R18, R22) — gated on `grammar: 0.9.3` as the
# inventory block's first fence line; the 0.9.3 events, the row engine and
# the early-exit subcommands are defined where they are computed, below.
#   verdict slice=N row=ID result=KEPT|BREACHED class=product|test|harness
#     [transition=k/n] brief=<path> quoted-at=<sha>  (the grader's return)
#   amended row=ID sha=<commit>  (checks/hooks/post-commit) · reissued row=ID
#     why=<owner answer id>  (the one session-written release) · completion
#     unmet=U strict-gaps=G  (`completion --record`)
#   `attempts row=ID n=K` and `reverted row=ID` are no longer written; legacy
#   events are read as 0.9.2 read them.
# Usage: sh checks/metrics.sh [--slice N] | sh checks/metrics.sh claim --from <report> --to <report> [--steps <ids>]
#        sh checks/metrics.sh close-rows --steps <ids> | provisional | checkpoint [--n 1|2 --to <report>]   (v0.9.6.1: inside a 0.9.6 develop run)
#        sh checks/metrics.sh claim --batch <id> [--from <batch id|receipt>] | close-freeze --steps <ids> --out <dir> --tree <tree> | batch-judge <frozen dir> <rows> <receipts>   (v0.9.7.0.12)
#        sh checks/metrics.sh receipt | row-state <id…>|--table | closure | completion [--record]
#        sh checks/metrics.sh fix-population --base <sha>          (the last five: grammar 0.9.3)
#        sh checks/metrics.sh timing                                (v0.9.5 3.15: durations from the events; any grammar)
#        sh checks/metrics.sh step-state <id>[,<id>…]|--all | defer --kind product|test --row <id> --why "<…>" --from brief:<path>#<row>|receipt:<name> [--by <who>] | defer-resolved --row <id> --by <commit|brief>   (v0.9.7.2)
#        sh checks/metrics.sh delegated --answer <A-id>   (v0.9.7.4)
#        sh checks/metrics.sh test-state [--rows <ROW-id,…>]   (v0.9.8: written, passing, proven per row — derived)
#        sh checks/metrics.sh to-confirm [--rows <ROW-id,…>]   (v0.26.10.3: the rows whose law changed and no resolution covers — R2)
#        sh checks/metrics.sh proof --row <id> --brief <grader brief> --fault <patch> --target <case> --control <case> --clean <receipt|none> --red <receipt|none>   (v0.9.8)
# Always exits 0 — a reporter, not a gate; the blocking lives in the
# courts that own each number.
set -eu
IFS='
'

SLICE=''
if [ "${1:-}" = "--slice" ]; then SLICE=${2:?slice number}; fi
EV=.vid/metrics-events

# --- the receipt and the rows (v0.9.2 3.6/3.8) ------------------------------
IBLOCK=''; [ -f INVENTORY.md ] && IBLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' || true)
read_report() { # $1=report file → `case <id> <status> <seconds>` lines, or nothing
  [ -f "$1" ] && [ -f checks/extractors/results.sh ] && sh checks/extractors/results.sh "$1" 2>/dev/null | grep -E '^case ' || true
}
# row_cases <cases> <row id> <cited path> <derived-from>: the row's collected cases
row_cases() {
  rc=$(printf '%s\n' "$1" | awk -v p="$3::" -v id="$2" 'BEGIN { alt = id; gsub(/-/, "_", alt) } index($2, p)==1 && (index($2, id) || index($2, alt)) { print }')
  if [ -z "$rc" ]; then
    for q in $(printf '%s\n' "$4" | tr ' ,' '\n\n' | grep -v '^$'); do
      rc=$(printf '%s\n' "$1" | awk -v p="$3::" -v id="$q" 'BEGIN { alt = id; gsub(/-/, "_", alt) } index($2, p)==1 && (index($2, id) || index($2, alt)) { print }')
      [ -n "$rc" ] && break
    done
  fi
  printf '%s\n' "$rc"
}
# row_green <cases> <row id> <path> <derived-from>: green | red
row_green() {
  rc=$(row_cases "$1" "$2" "$3" "$4")
  [ -n "$rc" ] || { echo red; return 0; }
  if printf '%s\n' "$rc" | awk '$3!="passed"' | grep -q .; then echo red; else echo green; fi
}
# latest_verdict <row id>: KEPT | BREACHED | NONE from the per-row verdict
# events (per transition for a journey: KEPT only when every transition's
# latest is KEPT); a `reverted row=ID` event wipes what came before it.
latest_verdict() {
  [ -f "$EV" ] || { echo NONE; return 0; }
  awk -v id="$1" '
    $1=="reverted" { for (i=2;i<=NF;i++) if ($i=="row=" id) { split("", v); nt=0; plain=""; any=0 } ; next }
    $1=="verdict" {
      r=""; res=""; tr=""
      for (i=2;i<=NF;i++) { if (index($i,"row=")==1) r=substr($i,5); if (index($i,"result=")==1) res=substr($i,8); if (index($i,"transition=")==1) tr=substr($i,12) }
      if (r!=id || res=="") next
      any=1
      if (tr=="") { plain=res } else { split(tr, a, "/"); v[a[1]+0]=res; if (a[2]+0>nt) nt=a[2]+0 }
    }
    END {
      if (!any) { print "NONE"; exit }
      if (nt>0) { for (k=1;k<=nt;k++) { if (v[k]=="") { print "NONE"; exit } if (v[k]!="KEPT") { print "BREACHED"; exit } } print "KEPT"; exit }
      print (plain=="" ? "NONE" : plain)
    }' "$EV"
}
materialised_rows() { # ROW rows citing a test: `id<TAB>path<TAB>derived-from`
  printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t !~ /^tests\//) next; sub(/ .*/,"",t); id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); d=$7; gsub(/^[ \t]+|[ \t]+$/,"",d); print id "\t" t "\t" d }'
}


# --- v0.9.3 (3.6, 3.7, 3.10, 3.13; R8–R11, R15, R18, R22) — the row engine ------
# Gated: every line below reads only under an inventory block whose first
# fence line is `grammar: 0.9.3` (0.9.3 satisfies every 0.9.2 check); a 0.9.2
# or legacy block keeps every line above and below byte for byte. ONE
# computation, read by the headline, the claim, `row-state`, `closure`,
# `completion` and coverage.sh's ROW pass: one pass over the events file
# gives each row its latest eligible verdict, class, attempts and hold; one
# join over the rows and the current receipts gives its bucket.
#   Verdict events: `verdict slice=N row=ID result=KEPT|BREACHED
#     class=product|test|harness [transition=k/n] brief=<path> quoted-at=<sha>`
#     (a BREACHED without class= is read as product; a verdict without brief=
#     counts its slice as its round). `amended row=ID sha=<commit>` (written by
#     checks/hooks/post-commit) wipes the row's verdicts and restarts its
#     history; a verdict whose quoted-at is not the amendment's commit or a
#     descendant of it is ineligible — recorded, ignored. `reissued row=ID
#     why=<answer id>` releases a hold; a legacy `reverted row=ID` wipes as in
#     0.9.2 and releases a hold.
#   Rounds, attempts and holds are COMPUTED, never written: a round is one
#     distinct brief among a row's eligible verdicts, its class the highest
#     of its BREACHED verdicts (product > test > harness); attempts = product
#     rounds since the row's latest KEPT or amendment; held reason=bound = two
#     product rounds since the latest KEPT, reissue, amendment or legacy
#     reversion; reason=test likewise for test rounds; reason=harness for two
#     harness rounds with no commit touching tests/invariants/harness.* or
#     docker-compose.test.yml between their briefs' quoted-at commits.
#   v0.9.7.0.4 (3.2; R1–R6), records 8: a BREACHED verdict may carry
#     `scope="<question>"`, and `reissued … rounds=<N>` grants an allowance of
#     N further breached briefs of any class. The scope flag, the allowance
#     and its own counter (distinct breached brief ids since that re-issue)
#     end only on `reissued`, `amended` or a COMPLETE KEPT brief — a plain
#     KEPT, or a journey brief whose every transition is KEPT — never on the
#     transient KEPT computed midway through a journey brief; the counters
#     above keep their resets. Held order: reason=scope (flagged, latest not
#     KEPT), then bound, test, harness, then reason=rounds (the counter has
#     reached the allowance). `allow` and the counter are the last columns.
#   Buckets: kept · unverdicted (no verdict, or latest BREACHED class test or
#     harness and not held) · breached (latest BREACHED class product, or
#     held) · red · owed · deploy-owed.
#   The receipt (3.10, R15): the newest `<S>.full.xml` for which `git diff
#     --name-only S HEAD` lists only paths under .vid/, and `<S>.deployed.xml`
#     with it. When docker-compose.test.yml's x-vid-harness declares
#     `deployed-selector:`, every row of kind journey or actor `(process)` is
#     read from the deployed report alone; otherwise `deployed: none declared`.
case "$(printf '%s\n' "$IBLOCK" | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in 'grammar: 0.9.3') IG93=yes ;; *) IG93=no ;; esac
TMP93=''
tmp93() { [ -n "$TMP93" ] || { TMP93=$(mktemp -d); trap 'rm -rf "$TMP93"' EXIT; }; }
ddeclared() { # the harness contract declares a deployed selector
  [ -f docker-compose.test.yml ] || return 1
  awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); if (v!="") f=1 } END { exit f?0:1 }' docker-compose.test.yml
}
receipt93() { # sets RECEIPT (current full report or '') and DREPORT (its deployed twin or '')
  RECEIPT=''; DREPORT=''; _bn=''
  git rev-parse -q --verify HEAD >/dev/null 2>&1 || return 0
  for _f in .vid/ledger-results/*.full.xml; do
    [ -f "$_f" ] || continue
    _s=${_f##*/}; _s=${_s%.full.xml}
    case "$_s" in *.*) continue ;; esac
    git rev-parse -q --verify "$_s^{commit}" >/dev/null 2>&1 || continue
    [ -z "$(git diff --name-only "$_s" HEAD -- . ':(exclude).vid' 2>/dev/null)" ] || continue
    _n=$(git rev-list --count "$_s..HEAD" 2>/dev/null || echo 999999)
    if [ -z "$_bn" ] || [ "$_n" -lt "$_bn" ]; then _bn=$_n; RECEIPT=$_f; fi
  done
  if [ -n "$RECEIPT" ] && [ -f "${RECEIPT%.full.xml}.deployed.xml" ]; then DREPORT="${RECEIPT%.full.xml}.deployed.xml"; fi
  return 0
}
# v0.9.7.2 (3.6, 3.8; R5, R9, R12): four more columns — gk gn (a journey's graded transitions, k of n; 0 0 for a
# plain row), bcs (the classes of its current BREACHED verdicts, any transition, comma-separated in the order product,
# test, harness; - when none) and pre (1 when it had a verdict before its latest amendment)
vstate93() { # → $TMP93/vstate: id latest class attempts P T harness-quoted-list lastslice held allow ar gk gn bcs pre
  tmp93; : > "$TMP93/vstate"
  [ -f "$EV" ] || return 0
  _cand=$(awk 'function kv(k, i) { for (i=2;i<=NF;i++) if (index($i, k "=")==1) return substr($i, length(k)+2); return "" }
    $1=="amended" { am[kv("row")]=kv("sha"); next }
    $1=="verdict" { r=kv("row"); q=kv("quoted-at"); if (r!="" && (r in am) && q!="" && q!=am[r]) print NR, am[r], q }' "$EV")
  _inel=''
  if [ -n "$_cand" ]; then
    _inel=$(printf '%s\n' "$_cand" | while read -r _nr _a _q; do git merge-base --is-ancestor "$_a" "$_q" 2>/dev/null || printf '%s ' "$_nr"; done)
  fi
  awk -v inel=" $_inel " '
    function kv(k, i) { for (i=2;i<=NF;i++) if (index($i, k "=")==1) return substr($i, length(k)+2); return "" }
    function rk(c) { return c=="product" ? 3 : (c=="test" ? 2 : (c=="harness" ? 1 : 3)) }
    function cn(n) { return n==3 ? "product" : (n==2 ? "test" : "harness") }
    function latest(r,  k, n) {
      if (!any[r]) return "NONE"
      n=nt[r]+0
      if (n>0) { for (k=1;k<=n;k++) { if (!((r SUBSEP k) in tv)) return "NONE"; if (tv[r,k]!="KEPT") return "BREACHED" } return "KEPT" }
      return (plain[r]=="" ? "NONE" : plain[r])
    }
    function wipe(r,  key, a) { for (key in tv) { split(key, a, SUBSEP); if (a[1]==r) { delete tv[key]; delete tc[key] } } nt[r]=0; plain[r]=""; plainc[r]=""; any[r]=0; if (vb[r]) pre[r]=1 }
    function holdreset(r) { hg[r]++; hseq[r]=0 }
    function attreset(r) { ag[r]++ }
    function allowend(r) { xg[r]++; allow[r]=0; ar[r]=0; sc[r]=0 }
    { seen[kv("row")]=1 }
    $1=="amended" { r=kv("row"); if (r=="") next; wipe(r); holdreset(r); attreset(r); allowend(r); next }
    $1=="reverted" { r=kv("row"); if (r=="") next; wipe(r); holdreset(r); next }
    $1=="reissued" { r=kv("row"); if (r=="") next; holdreset(r); allowend(r); allow[r]=kv("rounds")+0; next }
    $1=="verdict" {
      r=kv("row"); res=kv("result"); if (r=="" || res=="") next
      vb[r]=1
      if (index(inel, " " NR " ")) next
      c=kv("class"); tr=kv("transition"); b=kv("brief"); q=kv("quoted-at"); sl=kv("slice")
      if (b=="") b="slice:" sl
      if (res=="BREACHED" && c=="") c="product"
      any[r]=1
      if (tr=="") { plain[r]=res; plainc[r]=c } else { split(tr, a, "/"); tv[r, a[1]+0]=res; tc[r, a[1]+0]=c; if (a[2]+0>nt[r]) nt[r]=a[2]+0 }
      if (res=="BREACHED") {
        ls[r]=sl
        hk=r SUBSEP hg[r]+0 SUBSEP b
        if (!(hk in hr)) { hseq[r]++; hn[hk]=hseq[r]; hr[hk]=0; hq[hk]=q }
        if (rk(c)>hr[hk]) hr[hk]=rk(c)
        if (c=="product") ab[r SUBSEP ag[r]+0 SUBSEP b]=1
        if (kv("scope")!="") sc[r]=1
        xk=r SUBSEP xg[r]+0 SUBSEP b
        if (allow[r]+0>0 && !(xk in xb)) { xb[xk]=1; ar[r]++ }
      }
      if (tr=="") { if (res=="KEPT") allowend(r) }
      else { bk=r SUBSEP b; bv[bk, a[1]+0]=res; full=(a[2]+0>0)
        for (k=1;k<=a[2]+0;k++) if (!((bk SUBSEP k) in bv) || bv[bk, k]!="KEPT") { full=0; break }
        if (full) allowend(r) }
      if (latest(r)=="KEPT") { holdreset(r); attreset(r) }
    }
    END {
      for (key in hr) { split(key, a, SUBSEP); r=a[1]; if (a[2]!=hg[r]+0) continue
        if (hr[key]==3) P[r]++; else if (hr[key]==2) T[r]++; else { H[r, hn[key]]=(hq[key]=="" ? "-" : hq[key]); if (hn[key]>HM[r]) HM[r]=hn[key] } }
      for (key in ab) { split(key, a, SUBSEP); if (a[2]==ag[a[1]]+0) AT[a[1]]++ }
      for (r in seen) { if (r=="") continue
        L=latest(r); C="-"
        if (L=="BREACHED") { best=0
          if (nt[r]+0>0) { for (k=1;k<=nt[r];k++) if (tv[r,k]=="BREACHED" && rk(tc[r,k])>best) best=rk(tc[r,k]) }
          else best=rk(plainc[r])
          C=cn(best) }
        hl=""; for (k=1;k<=HM[r]+0;k++) if ((r SUBSEP k) in H) hl=hl (hl==""?"":",") H[r,k]
        gk=0; split("", BC); for (k=1;k<=nt[r]+0;k++) if ((r SUBSEP k) in tv) { gk++; if (tv[r,k]=="BREACHED") BC[rk(tc[r,k])]=1 }
        if (plain[r]=="BREACHED") BC[rk(plainc[r])]=1
        bcs=""; for (k=3;k>=1;k--) if (k in BC) bcs=bcs (bcs==""?"":",") cn(k)
        printf "%s\t%s\t%s\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\n", r, L, C, AT[r]+0, P[r]+0, T[r]+0, (hl==""?"-":hl), (ls[r]==""?"-":ls[r]), sc[r]+0, allow[r]+0, ar[r]+0, gk, nt[r]+0, (bcs==""?"-":bcs), pre[r]+0 }
    }' "$EV" > "$TMP93/vstate.raw"
  while IFS='	' read -r _r _l _c _a _p _t _h _s _sc _al _ar _gk _gn _bc _pr; do
    _held=-
    if [ "$_l" != KEPT ]; then
      if [ "$_sc" = 1 ]; then _held=scope
      elif [ "$_p" -ge 2 ]; then _held=bound
      elif [ "$_t" -ge 2 ]; then _held=test
      elif [ "$_h" != - ]; then
        _streak=0; _prev=''
        for _q in $(printf '%s\n' "$_h" | tr ',' '\n'); do
          if [ "$_streak" -gt 0 ] && [ "$_prev" != - ] && [ "$_q" != - ] \
             && [ -n "$(git log --format=%h "$_prev..$_q" -- 'tests/invariants/harness.*' docker-compose.test.yml 2>/dev/null)" ]; then _streak=1
          else _streak=$((_streak + 1)); fi
          _prev=$_q
        done
        [ "$_streak" -ge 2 ] && _held=harness
      fi
      if [ "$_held" = - ] && [ "$_al" -gt 0 ] && [ "$_ar" -ge "$_al" ]; then _held=rounds; fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_r" "$_l" "$_c" "$_a" "$_p" "$_t" "$_h" "$_s" "$_held" "$_al" "$_ar" "$_gk" "$_gn" "$_bc" "$_pr"
  done < "$TMP93/vstate.raw" > "$TMP93/vstate"
}
rows93() { # $1=full report or '' $2=deployed report or '' $3=out file — one line per ROW row:
  # id bucket latest class held slice attempts kind derived detail allow ar gk gn bcs pre (tab-separated; v0.9.7.2: the last four from vstate93)
  tmp93
  read_report "${1:-/nonexistent}" > "$TMP93/rc"
  read_report "${2:-/nonexistent}" > "$TMP93/dc"
  printf '%s\n' "$IBLOCK" | grep -E '^[[:space:]]*ROW-' > "$TMP93/rows" || true
  _dd=no; ddeclared && _dd=yes
  awk -F'\t' -v rcf="$TMP93/rc" -v dcf="$TMP93/dc" -v vsf="$TMP93/vstate" -v rrep="${1:-}" -v drep="${2:-}" -v dd="$_dd" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function load(f, pre,   line, a, p) { while ((getline line < f) > 0) { split(line, a, " "); if (a[1]!="case") continue; p=a[2]; sub(/::.*/, "", p); n[pre, p]++; cid[pre, p, n[pre, p]]=a[2]; cst[pre, p, n[pre, p]]=a[3] } close(f) }
    function pick(pre, p, tok,   i, out, alt) { out=""; alt=tok; gsub(/-/, "_", alt); for (i=1;i<=n[pre, p]+0;i++) if (index(cid[pre, p, i], tok) || index(cid[pre, p, i], alt)) out=out i " "; return out }
    function judge(pre, p, id, der,   sel, k, m, t, idx, bad) {
      sel=pick(pre, p, id)
      if (sel=="") { m=split(der, t, /[ ,]+/); for (k=1;k<=m;k++) { if (t[k]=="") continue; sel=pick(pre, p, t[k]); if (sel!="") break } }
      if (sel=="") return "ABSENT"
      m=split(sel, idx, " "); bad=""
      for (k=1;k<=m;k++) { if (idx[k]=="") continue; if (cst[pre, p, idx[k]]!="passed") bad=bad cid[pre, p, idx[k]] " " cst[pre, p, idx[k]] "; " }
      if (bad=="") return "GREEN"
      sub(/; $/, "", bad); return "not green: " bad
    }
    BEGIN {
      load(rcf, "f"); load(dcf, "d")
      FS="\t"; while ((getline line < vsf) > 0) { split(line, v, "\t"); VL[v[1]]=v[2]; VC[v[1]]=v[3]; VA[v[1]]=v[4]; VS[v[1]]=v[8]; VH[v[1]]=v[9]; VW[v[1]]=v[10]; VR[v[1]]=v[11]; VX[v[1]]=v[12] "\t" v[13] "\t" v[14] "\t" v[15] } close(vsf)
      FS="|"
    }
    {
      id=trim($1); kind=trim($2); actor=trim($4); der=trim($7); t=trim($8)
      L=(id in VL) ? VL[id] : "NONE"; C=(id in VC) ? VC[id] : "-"; H=(id in VH) ? VH[id] : "-"; S=(id in VS) ? VS[id] : "-"; A=(id in VA) ? VA[id] : 0
      if (t ~ /^owed: paid by \/vid deploy/) { b="deploy-owed"; d=t }
      else if (t ~ /^owed:/) { b="owed"; d=t }
      else if (t ~ /^tests\//) {
        p=t; sub(/ .*/, "", p)
        pop=(dd=="yes" && (kind=="journey" || actor=="(process)"))
        if (rrep=="") { b="red"; d="receipt: none — no current export-backed full report" }
        else if (pop && drep=="") { b="red"; d="absent from the deployed-shape report (no " rrep; sub(/\.full\.xml$/, ".deployed.xml", d); d=d " beside the receipt)" }
        else {
          g=judge(pop ? "d" : "f", p, id, der)
          if (g=="ABSENT") { b="red"; d=pop ? "absent from the deployed-shape report " drep : "absent from " rrep " (no collected case in " p " names " id " or its REQ)" }
          else if (g!="GREEN") { b="red"; d=g (pop ? " (deployed-shape report)" : "") }
          else if (H!="-") { b="breached"; d="held reason=" H "; latest BREACHED class=" C " (slice " S ")" }
          else if (L=="KEPT") { b="kept"; d="green, latest verdict KEPT" }
          else if (L=="BREACHED" && C=="product") { b="breached"; d="green, latest verdict BREACHED class=product (slice " S ")" }
          else if (L=="BREACHED") { b="unverdicted"; d="green, latest verdict BREACHED class=" C " (slice " S ") — the instrument, not the product" }
          else { b="unverdicted"; d="green, no verdict" }
        }
      }
      else { b="red"; d="unrecognized test field \047" t "\047" }
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\n", id, b, L, C, H, S, A, kind, der, d, VW[id]+0, VR[id]+0, ((id in VX) ? VX[id] : "0\t0\t-\t0")
    }' "$TMP93/rows" > "$3"
}
# v0.9.8.1 (R30, F-19): holdflags93 <table> — information only, after the closure lines: `hold FLAG unqueued row=<id>
# reason=<r>` for a computed hold no open question names (a `question n= state=asked gates=` listing the row, or
# `all`, with no later `state=answered`), and `hold FLAG unreleased row=<id> q=<n>` for a held row whose gating
# question (gates= naming the row, not `all`) is answered with no `reissued row=` or `amended row=` for it after the
# answer (such a row is reported unreleased, not also unqueued). At most 20 lines of each kind, then `(+N more)`. It
# gates nothing and changes no state, count or completion.
holdflags93() {
  _hev=/dev/null; [ -f "$EV" ] && _hev=$EV
  awk -F'\t' 'NR == FNR { if ($5 != "-" && $5 != "") { H[$1] = $5; HO[++nh] = $1 } next }
    function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    { FS = " "; $0 = $0 }
    $1 == "question" { q = kv("n"); st = kv("state")
      if (st == "asked") { G[q] = kv("gates"); OPEN[q] = 1; delete ANS[q] }
      else if (st == "answered") { delete OPEN[q]; ANS[q] = FNR } next }
    ($1 == "reissued" || $1 == "amended") { r = kv("row"); if (r != "") LAST[r] = FNR }
    END {
      for (i = 1; i <= nh; i++) { id = HO[i]; queued = 0; rel = ""
        for (q in G) { n = split(G[q], g, ","); named = 0; all = 0
          for (k = 1; k <= n; k++) { if (g[k] == id) named = 1; if (g[k] == "all") all = 1 }
          if ((named || all) && (q in OPEN)) queued = 1
          if (named && (q in ANS) && !(LAST[id] > ANS[q])) rel = q }
        if (queued) continue
        if (rel != "") { if (++nr <= 20) print "hold FLAG unreleased row=" id " q=" rel }   # its answer came, the row was never released
        else if (++nu <= 20) print "hold FLAG unqueued row=" id " reason=" H[id] }
      if (nu > 20) print "hold FLAG unqueued (+" nu - 20 " more)"
      if (nr > 20) print "hold FLAG unreleased (+" nr - 20 " more)" }' "$1" "$_hev" 2>/dev/null || true
}
laters93() { # the effective `later` demand items (v0.9.1 3.6)
  [ -f PRD.md ] && grep -q '^```vid-prd$' PRD.md || return 0
  sed -n '/^```vid-prd$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | awk -F'|' '{
    id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id); t=$2; gsub(/^[ \t]+|[ \t]+$/,"",t); ph="pilot"
    for (i=3;i<=NF;i++) { f=$i; gsub(/^[ \t]+|[ \t]+$/,"",f); if (f ~ /^phase:/) { sub(/^phase:[ \t]*/,"",f); ph=f } }
    if (id ~ /^REQ-[0-9]+$/ && (t=="functional"||t=="nfr"||t=="ux_flow"||t=="data_entity")) last[id]=ph; if (!(id in s)) { o[++n]=id; s[id]=1 }
  } END { for (i=1;i<=n;i++) if (last[o[i]]=="later") print o[i] }'
}
closure93() { # $1=table → the five closure lines (3.13), first match wins
  awk -F'\t' -v nl="$(laters93 | grep -c . || true)" '
    { id=$1; b=$2; C=$4; H=$5; d=$10 }
    b=="deploy-owed" { D=D " " id; nd++; next }
    b=="kept" { next }
    (b=="owed" && d ~ /^owed:[ \t]*owner-decision/) || H!="-" { A=A " " id; na++; next }
    (b=="unverdicted" && (C=="test" || C=="harness")) { I=I " " id; ni++; next }
    { U=U " " id; nu++ }
    END {
      print "closure contract-ambiguity n=" na+0 A
      print "closure invalid-test-evidence n=" ni+0 I
      print "closure unfinished-implementation n=" nu+0 U
      print "closure deploy-owed n=" nd+0 D
      print "closure later n=" nl+0
    }' "$1"
}

# --- v0.9.5 (3.11, 3.15; R11, R13) — time on every event, and `timing` ---------
# Every event line ends ` at=<UTC>` (YYYY-MM-DDTHH:MM:SSZ). A reader takes a
# line's LAST `at=` token and uses it only in that exact form, since a
# free-text event may carry the string; a line without one is untimed and
# stays readable. `timing` reads the events only, writes nothing, and orders
# the timed lines by that time (file order breaks a tie), never by position
# alone. Stages: `stage name=<verb> state=start|end|pause-N session=<id>
# [records=<n>]`; an `end` closes the latest open `start` of the same name,
# a pause attaches to it, and a `start` with no `end` prints `open`.
# Slices: the wall between a slice's latest `slice-open` and `slice-close`;
# the rows `paid` inside that window, by the row's INVENTORY `kind`; the
# product rounds, by kind — a round is one distinct brief among a row's
# product-class BREACHED verdicts (metrics' own definition), counted in the
# slice its first verdict falls in, a history no KEPT or amendment removes;
# the hook's seconds and attempts from .vid/hook-times lines in the window.
# Questions: the window from `question n=<n> state=asked` to the next
# `state=answered` for n. A negative span (a clock step) prints `uncounted`.
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function ep(t,  y, m, d, H, M, S) { y = substr(t, 1, 4) + 0; m = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0; H = substr(t, 12, 2) + 0; M = substr(t, 15, 2) + 0; S = substr(t, 18, 2) + 0
  if (m <= 2) { y--; m += 12 } return (365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d - 719469) * 86400 + H * 3600 + M * 60 + S }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
timed() { # $1=file → `<at><TAB><seq><TAB><line>` for its timed lines, in time order
  [ -f "$1" ] || return 0
  awk "$AWKAT"' { a = lastat(); if (a != "") printf "%s\t%d\t%s\n", a, NR, $0 }' "$1" | sort -t "$(printf '\t')" -k1,1 -k2,2n
}
if [ "${1:-}" = timing ]; then
  [ -f "$EV" ] || { echo 'timing uncounted (no .vid/metrics-events)'; exit 0; }
  timed "$EV" | cut -f3- | awk "$AWKAT"'
    $1 == "stage" { nm = kv("name"); st = kv("state"); a = lastat(); if (nm == "" || st == "") next
      if (st == "start") { n++; SN[n] = nm; SA[n] = a; SS[n] = kv("session"); OP[n] = 1; next }
      for (k = n; k >= 1; k--) if (OP[k] && SN[k] == nm) break
      if (st == "end") { if (k >= 1) { SE[k] = a; OP[k] = 0 } else { no++; ON[no] = nm; OA[no] = a } }
      else if (st ~ /^pause-[0-9]+$/ && k >= 1) SP[k] = SP[k] " " st "=" a
      next }
    END {
      for (k = 1; k <= n; k++) {
        if (OP[k]) { e = "open"; s = "-" } else { e = SE[k]; d = ep(SE[k]) - ep(SA[k]); s = (d < 0 ? "uncounted" : d) }
        printf "timing stage name=%s start=%s end=%s seconds=%s%s%s\n", SN[k], SA[k], e, s, SP[k], (SS[k] == "" ? "" : " session=" SS[k]) }
      for (k = 1; k <= no; k++) printf "timing stage name=%s start=- end=%s seconds=uncounted  # an end with no open start\n", ON[k], OA[k]
      if (n + no == 0) print "timing stages none (no timed stage events)"
    }'
  KINDS=$(printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { id = $1; k = $2; gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", k); print id "\t" k }')
  HTF=/dev/null; [ -f .vid/hook-times ] && HTF=.vid/hook-times
  tmp93; printf '%s\n' "$KINDS" > "$TMP93/kinds"
  { timed "$EV" | cut -f3-; printf '\001HOOK\n'; timed "$HTF" | cut -f3-; } | awk -v kf="$TMP93/kinds" "$AWKAT"'
    BEGIN { while ((getline l < kf) > 0) { split(l, p, "\t"); if (p[1] != "") KIND[p[1]] = p[2] } close(kf) }
    $0 == "\001HOOK" { hook = 1; next }
    hook { a = lastat(); H[++nh] = ep(a); HS[nh] = kv("seconds") + 0; next }
    { a = lastat(); e = ep(a) }
    $1 == "slice-open" { s = kv("slice"); if (!(s in SO)) SORD[++ns] = s; SO[s] = a; next }
    $1 == "slice-close" { SC[kv("slice")] = a; next }
    $1 == "paid" { P[++np] = e; PK[np] = (kv("row") in KIND) ? KIND[kv("row")] : "unknown"; next }
    $1 == "verdict" && kv("row") != "" && kv("result") == "BREACHED" && (kv("class") == "" || kv("class") == "product") {
      r = kv("row"); b = kv("brief"); if (b == "") b = "slice:" kv("slice")
      if (!((r, b) in RF)) { RF[r, b] = e; R[++nr] = e; RK[nr] = (r in KIND) ? KIND[r] : "unknown" } next }
    $1 == "question" { q = kv("n"); st = kv("state")
      if (st == "asked") { nq++; QN[nq] = q; QA[nq] = a; QOPEN[q] = nq }
      else if (st == "answered" && (q in QOPEN)) { QE[QOPEN[q]] = a; delete QOPEN[q] }
      next }
    function list(arr, cnt,   k, out) { out = ""; for (k in cnt) out = out (out == "" ? "" : ",") k ":" cnt[k]; return out == "" ? "none" : out }
    END {
      for (i = 1; i <= ns; i++) { s = SORD[i]; lo = ep(SO[s]); hi = (s in SC) ? ep(SC[s]) : 9999999999
        if (s in SC) { d = hi - lo; sec = (d < 0 ? "uncounted" : d); end = SC[s] } else { sec = "-"; end = "open" }
        split("", C1); split("", C2); hs = 0; ha = 0
        for (k = 1; k <= np; k++) if (P[k] >= lo && P[k] <= hi) C1[PK[k]]++
        for (k = 1; k <= nr; k++) if (R[k] >= lo && R[k] <= hi) C2[RK[k]]++
        for (k = 1; k <= nh; k++) if (H[k] >= lo && H[k] <= hi) { hs += HS[k]; ha++ }
        printf "timing slice n=%s start=%s end=%s seconds=%s paid=%s product-rounds=%s hook-seconds=%d hook-attempts=%d\n", s, SO[s], end, sec, list(x, C1), list(x, C2), hs, ha }
      for (i = 1; i <= nq; i++) { if (i in QE) { d = ep(QE[i]) - ep(QA[i]); sec = (d < 0 ? "uncounted" : d); end = QE[i] } else { sec = "-"; end = "open" }
        printf "timing question n=%s asked=%s answered=%s seconds=%s\n", QN[i], QA[i], end, sec }
    }'
  exit 0
fi

# --- v0.26.10.3 (R2): the to-confirm state, and its one resolution rule ---------------------------------------------
# A row is TO CONFIRM when it has a `law-changed row=<id> sha=<L> item=<REQ-id,…>` (checks/hooks/post-commit: an item
# it derives from changed its effective fail-if; its own obligation did not) that no resolution covers. A resolution —
# `authority-kept row= sha=<S>` (checks/brief.sh authority --kept) or `amended row= sha=<S>` — covers L only when L is
# an ancestor of S (S incorporates the change; S = L counts) and S is an ancestor of the HEAD evaluated (S has landed):
# a resolution on a branch not merged, or made on a branch forked before L, never counts. A change at an L the HEAD
# evaluated does not hold is not a change to that HEAD's law and puts nothing to confirm. Verdicts, attempts, holds,
# allowances and evidence are untouched (checks/evidence.sh reads only `amended`); completion counts the rows unmet.
# This function is the rule; `to-confirm` prints it for checks/brief.sh authority --changed and checks/inventory.sh.
#   sh checks/metrics.sh to-confirm [--rows <ROW-id,…>]   → `to-confirm row=<id> since=<L> item=<ids>` per row (its
#   earliest uncovered change, the items of every uncovered one), then `to-confirm rows=<n>`
toconfirm93() { # $1=out file → `<row><TAB><L><TAB><items>` per row to confirm, sorted by row
  : > "$1"
  [ -f "$EV" ] && grep -q '^law-changed ' "$EV" 2>/dev/null || return 0
  git rev-parse -q --verify HEAD > /dev/null 2>&1 || return 0
  _tw=$(mktemp -d)
  awk 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "law-changed" && kv("row") != "" && kv("sha") != "" { print "L\t" kv("row") "\t" kv("sha") "\t" NR "\t" kv("item"); next }
    ($1 == "authority-kept" || $1 == "amended") && kv("row") != "" && kv("sha") != "" { print "S\t" kv("row") "\t" kv("sha") "\t" NR }' "$EV" > "$_tw/ev"
  awk -F'\t' 'NR == FNR { if ($1 == "L") L[$2] = 1; next } ($2 in L)' "$_tw/ev" "$_tw/ev" > "$_tw/ev3"   # the rows with a change
  # each distinct commit: does the HEAD evaluated hold it?
  cut -f3 "$_tw/ev3" | sort -u | while IFS= read -r _c; do
    if git merge-base --is-ancestor "$_c" HEAD 2> /dev/null; then printf '%s\tyes\n' "$_c"; else printf '%s\tno\n' "$_c"; fi
  done > "$_tw/inhead"
  # the pairs to judge: a change and a resolution of the same row, both held by HEAD
  awk -F'\t' 'FILENAME == ARGV[1] { H[$1] = $2; next } H[$3] != "yes" { next } $1 == "L" { NL[$2]++; LS[$2, NL[$2]] = $3 } $1 == "S" { NS[$2]++; SS[$2, NS[$2]] = $3 }
    END { for (r in NL) for (i = 1; i <= NL[r]; i++) for (j = 1; j <= NS[r] + 0; j++) { k = LS[r, i] "\t" SS[r, j]; if (!(k in P)) { P[k] = 1; print k } } }' "$_tw/inhead" "$_tw/ev3" > "$_tw/pairs"
  while IFS='	' read -r _l _s; do
    if [ "$_l" = "$_s" ] || git merge-base --is-ancestor "$_l" "$_s" 2> /dev/null; then printf '%s\t%s\n' "$_l" "$_s"; fi
  done < "$_tw/pairs" > "$_tw/covers"
  awk -F'\t' 'FILENAME == ARGV[1] { H[$1] = $2; next } FILENAME == ARGV[2] { C[$1, $2] = 1; next }
    H[$3] != "yes" { next }
    $1 == "S" { NS[$2]++; SS[$2, NS[$2]] = $3; next }
    $1 == "L" { NL[$2]++; LS[$2, NL[$2]] = $3; LI[$2, NL[$2]] = $5 }
    END { for (r in NL) { since = ""; items = ""
        for (i = 1; i <= NL[r]; i++) { cov = 0; for (j = 1; j <= NS[r] + 0; j++) if ((LS[r, i], SS[r, j]) in C) { cov = 1; break }
          if (cov) continue
          if (since == "") since = LS[r, i]
          n = split(LI[r, i], it, ","); for (k = 1; k <= n; k++) if (it[k] != "" && !((r, it[k]) in SEEN)) { SEEN[r, it[k]] = 1; items = items (items == "" ? "" : ",") it[k] } }
        if (since != "") print r "\t" since "\t" (items == "" ? "-" : items) } }' "$_tw/inhead" "$_tw/covers" "$_tw/ev3" | sort > "$1"
  rm -rf "$_tw"
}
if [ "${1:-}" = to-confirm ]; then
  shift; TCR=''
  while [ $# -gt 0 ]; do case "$1" in --rows) TCR=${2:-}; shift 2 ;; *) echo 'metrics to-confirm: usage — sh checks/metrics.sh to-confirm [--rows <ROW-id,…>]' >&2; exit 2 ;; esac; done
  tmp93; toconfirm93 "$TMP93/tc"
  if [ -n "$TCR" ]; then printf '%s\n' "$TCR" | tr ', ' '\n\n' | grep -v '^$' > "$TMP93/tcw"; awk -F'\t' 'NR == FNR { W[$1] = 1; next } ($1 in W)' "$TMP93/tcw" "$TMP93/tc" > "$TMP93/tc2" && mv "$TMP93/tc2" "$TMP93/tc"; fi
  awk -F'\t' '{ printf "to-confirm row=%s since=%s item=%s\n", $1, $2, $3; n++ } END { printf "to-confirm rows=%d\n", n + 0 }' "$TMP93/tc"
  exit 0
fi

# --- v0.9.3 early-exit subcommands (3.5, 3.6, 3.10, 3.13) — the engine above ---
case "${1:-}" in receipt|row-state|closure|completion|fix-population)
  SUB=$1; shift
  if [ "$IG93" != yes ]; then
    if [ "$SUB" = receipt ]; then   # the 0.9.2 lookup: HEAD's own report, exactly
      HS=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)
      if [ -f ".vid/ledger-results/$HS.full.xml" ]; then echo "receipt=.vid/ledger-results/$HS.full.xml deployed=none-declared"; else echo 'receipt=none deployed=none-declared'; fi
      exit 0
    fi
    echo "metrics $SUB: the inventory block does not open with grammar: 0.9.3 — $SUB reads the 0.9.3 row engine (v0.9.3 R22); nothing computed"
    exit 0
  fi
  receipt93
  DDESC=none-declared; ddeclared && DDESC=${DREPORT:-none}
  if [ "$SUB" = receipt ]; then echo "receipt=${RECEIPT:-none} deployed=$DDESC"; exit 0; fi
  vstate93
  rows93 "$RECEIPT" "$DREPORT" "$TMP93/table"
  case "$SUB" in
    row-state)
      if [ "${1:-}" = --table ]; then cat "$TMP93/table"; exit 0; fi
      for id in "$@"; do
        case "$id" in
          ROW-*)
            awk -F'\t' -v id="$id" '$1==id { f=1
              if ($2=="kept") print id ": kept"
              else if ($2=="owed") print id ": " $10
              else if ($2=="breached" && $5!="-") print id ": " $10
              else print id ": " $2 " (" $10 ")" }
              END { if (!f) print id ": no such row" }' "$TMP93/table" ;;
          REQ-*)
            awk -F'\t' -v id="$id" '{ n=split($9, t, /[ ,]+/); for (k=1;k<=n;k++) if (t[k]==id) { c[$2]++; f=1; break } }
              END { if (!f) { print id ": no row derives from it"; exit }
                s="kept " c["kept"]+0 " · red " c["red"]+0 " · owed " c["owed"]+0
                if (c["unverdicted"]) s=s " · unverdicted " c["unverdicted"]
                if (c["breached"]) s=s " · breached " c["breached"]
                if (c["deploy-owed"]) s=s " · deploy-owed " c["deploy-owed"]
                print id ": " s }' "$TMP93/table" ;;
          RULE-*)
            RROW=$(printf '%s\n' "$IBLOCK" | grep -E "^[[:space:]]*rule[[:space:]]*\|[[:space:]]*$id[[:space:]]*\|" | head -n 1 || true)
            if [ -z "$RROW" ]; then echo "$id: no such rule row"; continue; fi
            RT=$(printf '%s\n' "$RROW" | awk -F'|' '{ n=NF; while (n > 3 && $n ~ /^[[:space:]]*(origin|proved-red|paid-at):/) n--; print $n }' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            case "$RT" in
              owed*|OWED*) echo "$id: $RT" ;;
              tests/*)
                RP=${RT%% *}
                read_report "${RECEIPT:-/nonexistent}" | awk -v p="$RP::" -v id="$id" -v rid="$id" -v rec="${RECEIPT:-none}" '
                  BEGIN { alt = id; gsub(/-/, "_", alt) }
                  index($2, p)==1 && (index($2, id) || index($2, alt)) { n++; if ($3!="passed") bad=bad $2 " " $3 "; " }
                  END { if (rec=="none") print rid ": red (receipt: none)"; else if (!n) print rid ": red (absent from " rec ")"; else if (bad!="") { sub(/; $/,"",bad); print rid ": red (not green: " bad ")" } else print rid ": green (its census judges the sites; no verdict)" }' ;;
              *) echo "$id: red (unrecognized test field '$RT')" ;;
            esac ;;
          *) echo "$id: not a ROW, RULE or REQ id" ;;
        esac
      done
      exit 0 ;;
    closure)
      closure93 "$TMP93/table"
      holdflags93 "$TMP93/table"
      exit 0 ;;
    completion)
      REC=no; [ "${1:-}" = --record ] && REC=yes
      CL=$(closure93 "$TMP93/table")
      U=$(printf '%s\n' "$CL" | awk '$2=="contract-ambiguity"||$2=="invalid-test-evidence"||$2=="unfinished-implementation" { sub(/^n=/,"",$3); u+=$3 } END { print u+0 }')
      ND=$(printf '%s\n' "$CL" | awk '$2=="deploy-owed" { sub(/^n=/,"",$3); print $3+0 }')
      NL=$(printf '%s\n' "$CL" | awk '$2=="later" { sub(/^n=/,"",$3); print $3+0 }')
      # v0.26.10.3 (R2): never complete while a row is to confirm — each counted unmet (once: a row the closure
      # already counts unmet is not counted again) and named
      toconfirm93 "$TMP93/tc"
      TCL=''
      if [ -s "$TMP93/tc" ]; then
        TCL="to confirm: $(grep -c . "$TMP93/tc") ($(cut -f1 "$TMP93/tc" | paste -sd ' ' -))"
        TCX=$(printf '%s\n' "$CL" | awk 'NR == FNR { if ($2=="contract-ambiguity"||$2=="invalid-test-evidence"||$2=="unfinished-implementation") for (i=4;i<=NF;i++) M[$i]=1; next } { split($0, a, "\t"); if (!(a[1] in M)) n++ } END { print n+0 }' - "$TMP93/tc")
        U=$((U + TCX))
      fi
      G=uncounted
      if [ -f checks/coverage.sh ]; then
        CS=$(VID_COURT_EVENT=off sh checks/coverage.sh --strict 2>/dev/null | grep '^REQs: ' | tail -n 1 || true)
        [ -n "$CS" ] && G=$(printf '%s\n' "$CS" | sed -n 's/.*[[:space:]]gaps: \([0-9]*\).*open VID-QUESTION markers: \([0-9]*\).*/\1 \2/p' | awk '{ print $1 + $2 }')
      fi
      G=${G:-uncounted}
      # v0.9.5 (3.1, R1): an open develop question (a `Q<n>` line in RUN-STATE's
      # "Open product questions") is a strict gap, as an open VID-QUESTION is.
      NQO=$( [ -f .vid/RUN-STATE.md ] && awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+/ { n++ } END { print n + 0 }' .vid/RUN-STATE.md || echo 0)
      case "$G" in ''|*[!0-9]*) ;; *) G=$((G + NQO)) ;; esac
      # v0.9.6 (3.10, R10): under a 0.9.6 develop run (`checks/plan.sh gate`
      # on) everything the project still runs is a strict gap, listed
      # `leftover <what>` after the closure; with the gate off, unchanged.
      LO=''
      if [ -f checks/plan.sh ] && [ -f checks/testenv.sh ] && sh checks/plan.sh gate >/dev/null 2>&1; then
        LO=$(sh checks/testenv.sh leftovers 2>/dev/null | grep '^leftover ' || true)
        NLO=$(printf '%s\n' "$LO" | grep -c . || true)
        case "$G" in ''|*[!0-9]*) ;; *) G=$((G + NLO)) ;; esac
      fi
      # v0.9.7.2 (3.9, R13): the predicate above unchanged; under breadth first every hardening step done as well
      HND=''
      if [ -f checks/plan.sh ] && sh checks/plan.sh gate >/dev/null 2>&1 && [ "$(sed -n 's/^strategy:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//')" = breadth-first ]; then
        SSO=$(sh checks/metrics.sh step-state --all 2>/dev/null || true)
        if printf '%s\n' "$SSO" | grep -q '^step-state '; then
          HND=$(printf '%s\n' "$SSO" | awk '$1 == "step-state" { k = ""; d = ""; s = ""; for (i = 2; i <= NF; i++) { if ($i ~ /^kind=/) k = substr($i, 6); if ($i ~ /^done=/) d = substr($i, 6); if ($i ~ /^step=/) s = substr($i, 6) } if (k == "hardening" && d != "yes") printf "%s%s", (n++ ? ", " : ""), s }')
        else HND='unread (checks/metrics.sh step-state)'; fi
      fi
      printf '%s\n' "$CL"
      [ -n "$TCL" ] && printf '%s\n' "$TCL"
      [ -n "$LO" ] && printf '%s\n' "$LO"
      [ -n "$HND" ] && echo "hardening not done: $HND"
      echo "completion unmet=$U strict-gaps=$G"
      if [ "$U" -eq 0 ] && [ "$G" = 0 ] && [ -z "$HND" ]; then
        echo "complete, $ND rows at deploy, $NL later"
      else
        echo "not complete — unmet $U, strict gaps $G${HND:+, hardening not done: $HND} (the closure above; checks/coverage.sh --strict names every gap)"
      fi
      if [ "$REC" = yes ]; then
        mkdir -p .vid; printf 'completion unmet=%s strict-gaps=%s at=%s\n' "$U" "$G" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
        if [ "$U" -eq 0 ] && [ "$G" = 0 ] && [ -z "$HND" ] && [ -f .vid/RUN-STATE.md ]; then
          sed 's/^run:[[:space:]].*/run: complete/' .vid/RUN-STATE.md > "$TMP93/rs" && cat "$TMP93/rs" > .vid/RUN-STATE.md
        fi
      fi
      exit 0 ;;
    fix-population)
      [ "${1:-}" = --base ] && [ -n "${2:-}" ] || { echo 'metrics fix-population: --base <sha> is required (the commit before the fix began)' >&2; exit 2; }
      BASE=$2
      git rev-parse -q --verify "$BASE^{commit}" >/dev/null 2>&1 || { echo "metrics fix-population: $BASE is no commit" >&2; exit 2; }
      git diff --name-only "$BASE" HEAD > "$TMP93/changed"
      # the seam table: module path, dependents (3.13 — the changed modules plus their declared dependents)
      MODS=''
      if [ -f ARCHITECTURE.md ]; then
        MODS=$(grep -E '^\|' ARCHITECTURE.md | grep -vE '^\|[[:space:]:-]*\|' | awk -F'|' '{
          m=$2; gsub(/[ \t`]/,"",m); if (m=="Module" || m=="" || m ~ /^\{\{/) next
          if (m !~ /\// && m ~ /\./) gsub(/\./,"/",m)
          d=$6; gsub(/`/,"",d); gsub(/^[ \t]+|[ \t]+$/,"",d); gsub(/[ \t]*,[ \t]*/,",",d); print m "\t" d }' || true)
      fi
      RADIUS=$(printf '%s\n' "$MODS" | awk -F'\t' -v chf="$TMP93/changed" '
        BEGIN { while ((getline f < chf) > 0) { g=f; gsub(/\/src\//,"/",g); sub(/^src\//,"",g); ch[++nc]=g } }
        $1!="" { m[++nm]=$1; dep[$1]=$2 }
        END {
          for (i=1;i<=nm;i++) for (j=1;j<=nc;j++) if (ch[j]==m[i] || index(ch[j], m[i] "/")==1) { hit[m[i]]=1; break }
          for (x in hit) { r[x]=1; d=dep[x]
            if (d=="all") { for (i=1;i<=nm;i++) r[m[i]]=1 }
            else if (d!="none" && d!="") { n=split(d, a, ","); for (k=1;k<=n;k++) if (a[k]!="") r[a[k]]=1 } }
          for (x in r) if (x !~ /^(tests|checks|design)(\/|$)/) print x }' | sort -u)
      : > "$TMP93/cited"
      if [ -n "$RADIUS" ]; then
        git ls-files | awk -v rad="$(printf '%s\n' "$RADIUS" | tr '\n' ' ')" 'BEGIN { n=split(rad, R, " ") }
          { f=$0; if (f ~ /\.md$/ || f ~ /^(tests|checks|design)\//) next; g=f; gsub(/\/src\//,"/",g); sub(/^src\//,"",g)
            for (i=1;i<=n;i++) if (R[i]!="" && (g==R[i] || index(g, R[i] "/")==1)) { print f; break } }' > "$TMP93/radfiles"
        while IFS= read -r _f; do [ -f "$_f" ] && grep -hoE '(REQ-[0-9]+|[A-Za-z0-9_-]+/[A-Za-z0-9_-]+)' "$_f" 2>/dev/null || true; done < "$TMP93/radfiles" | sort -u > "$TMP93/cited"
      fi
      BLOCKB=$(git show "$BASE:INVENTORY.md" 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' | grep -E '^[[:space:]]*ROW-' || true)
      printf '%s\n' "$BLOCKB" > "$TMP93/baserows"
      HARN=no; grep -qE '^(tests/invariants/harness\.|docker-compose\.test\.yml$)' "$TMP93/changed" && HARN=yes
      printf '%s\n' "$IBLOCK" | grep -E '^[[:space:]]*ROW-' | awk -F'|' -v tf="$TMP93/table" -v cf="$TMP93/cited" -v chf="$TMP93/changed" -v bf="$TMP93/baserows" -v harn="$HARN" '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        BEGIN {
          while ((getline l < tf) > 0) { split(l, a, "\t"); L[a[1]]=a[3]; H[a[1]]=a[5]; HC[a[1]]=a[4] }
          while ((getline l < cf) > 0) cited[l]=1
          while ((getline l < chf) > 0) ch[l]=1
          while ((getline l < bf) > 0) { split(l, a, "|"); bt[trim(a[1])]=trim(a[8]) }
        }
        { id=trim($1); t=trim($8); der=trim($7); why=""
          if (t !~ /^tests\//) next
          p=t; sub(/ .*/, "", p)
          if (!(id in bt) || bt[id] !~ /^tests\//) { if (id in bt && bt[id] ~ /^owed:[ \t]*reverted/) why=why ",re-paid"; else why=why ",materialised" }
          if (L[id]!="KEPT") { n=split(der, tk, /[ ,]+/); for (k=1;k<=n;k++) if (tk[k]!="" && (tk[k] in cited)) { why=why ",cited-in-radius"; break } }
          if (p in ch) why=why ",test-changed"
          if (harn=="yes" && (H[id]=="harness" || ((H[id]=="scope" || H[id]=="rounds") && HC[id]=="harness"))) why=why ",harness-held"
          if (why!="") { sub(/^,/, "", why); print "regrade row=" id " why=" why; N++ } }
        END { printf "regrade rows=%d\n", N+0 }' > "$TMP93/pop"
      sed '$d' "$TMP93/pop"
      echo "$(tail -n 1 "$TMP93/pop") base=$BASE radius=$(printf '%s\n' "$RADIUS" | grep -v '^$' | tr '\n' ' ' | sed 's/ $//;s/^$/none/')"
      exit 0 ;;
  esac
  ;;
esac

# --- v0.9.6.1 (3.2, 3.3; R2, R3) — the close under the gate --------------------
# Inside a 0.9.6 develop run (`sh checks/plan.sh gate` on), read at the run's
# home; outside it every line below is off and the claim is 0.9.6's.
#   close-rows --steps <id>[,<id>…]   the rows a slice close must re-run:
#     `base step=<id> commit=<sha> from=<source>` for each closing step (the
#     commit its diff starts from — `sh checks/plan.sh base`), then one
#     `required row=<id> sets=<n,…> step=<id> phase=<1|2>` line per row, each
#     row once with every set it is in (v0.9.7.0.12 3.1, R1: before, once under
#     its lowest set, `set=`), ordered by its lowest; phase 1 holds the rows in
#     any of sets 1, 4 or 5 — the likeliest to fail — and phase 2 the rest, the
#     two phases of a close batch (checks/test.sh); then `note <text>` for each note of set 5, and
#     `close-rows steps=<ids> required=<n>`. ELIGIBLE rows are the rows of
#     the closing steps and of the CLOSED steps (a `step-closed` event names
#     them), never owed, deploy-owed, held or `later`; a step started but not
#     closed contributes nothing. The sets: 1 the closing steps' rows; 2 the
#     rows of every step in their builds-on: (direct only); 3 the alarm set —
#     every eligible row of INVENTORY kind journey, shell or reachability,
#     and every MATERIALISED hostility probe (a `hostility` row citing a test
#     with `proved-red:`), `step=-`; 4 every eligible row whose result is
#     not a pass (checks/evidence.sh: red, stale — its own test changed, or
#     amended — or never run); 5 the builder's rows, read from
#     .vid/close/<slice>.rows (<slice> from RUN-STATE's `slice:`), one line
#     per row `ROW-id | <one-line reason>`, and `note | <what was checked>`
#     for a shared or uncited change; blank and # lines are skipped. Refused
#     (exit 1, naming the line): a row line with no reason, a row that is not
#     eligible, a line that does not parse, a missing file (write it, even
#     empty, from the closing steps' diff first). ViD never computes set 5
#     and never builds a selection: the list is what the caller turns into
#     the runner's syntax.
#   claim --from <report> --to <report> --steps <id>[,<id>…]   when --to is a
#     selected close's receipt (`.close.xml`, kept name or copy, read with
#     its `.close.deployed.xml`): COMPLETENESS first — for every required
#     row (close-rows' list), every EXPECTED case must be in the close's
#     receipt of the row's shape (the deployed one for a journey or actor
#     `(process)` row when the harness declares deployed-selector:) and
#     passed. The expected cases are those naming the row in the newest
#     POPULATION RUN — a valid checkpoint or whole-ledger full receipt,
#     newest by the commit it tested — so a close never supplies its own
#     denominator. A row with none there, or whose test path changed since
#     that run, is PROVISIONAL: it needs one case in the close and every
#     one passed, and is printed `provisional row=<id>` after its claim
#     line; completion still reads only the full receipt (R6). A missing
#     case prints `not-run row=<id> case=<case id>` (`case=-` for a
#     provisional row with none), a case not passed `failed row=<id>
#     case=<case id>`; then the claim exits 2 with no `claim` line. Known
#     limit, accepted (spec 3.3): a variant added after the population run
#     and left out of every selection is caught only at the next checkpoint
#     or the final run. The BEFORE state is every row's state under R4 as of
#     --from's publication (`checks/evidence.sh rows --at <its commit>
#     --until <its time>`), so a row absent from a sparse --from keeps its
#     earlier result and a KEPT row not selected is never claimed re-paid.
#     The claim covers the eligible rows passing in --to: `held row=<id>
#     reason=<r>`, or `claim row=<id> why=unverdicted|breached`, or, for a
#     KEPT row not passing before, `claim row=<id> why=re-paid`; then `claim
#     rows=<n> held=<h> provisional=<p> from=<report> to=<report>
#     steps=<ids>`, and one `step-closed step=<id> report=<--to's name>`
#     event per step. The final full close (--to a `.full.xml` with
#     --steps) takes the same handling without the completeness check — a
#     full run is complete by construction. A `.close.xml` without --steps
#     is refused; a `.full.xml` without --steps is 0.9.6's claim (a run
#     that closed a slice under 0.9.6 keeps that workflow).
#     v0.9.7.0.11 (3.1, R1): a --to receipt carrying its request's frozen
#     rows (`<report>.rows`) passes only the rows it credits (`sh
#     checks/evidence.sh credit`); a row it reached outside them is not
#     claimed. A checkpoint's judging reads it the same way.
#   v0.9.7.1 (3.10, R10): VID_EVIDENCE_STATES names the states at HEAD a caller already read on `plan.sh map --all`
#   (the progress update); cl_prepare then reads them instead of reading the evidence again.
#   provisional   the rows of closed steps passing on current results whose
#     population is not yet confirmed — no case in the newest population
#     run, or their test path changed since it — one `provisional row=<id>`
#     each, then `provisional rows=<k>`; the progress update counts them
#     apart (spec 3.3).
gate_home() { [ -f checks/plan.sh ] || return 1; _g=$(sh checks/plan.sh gate 2>/dev/null) || return 1; case "$_g" in 'on '*) printf '%s\n' "${_g#on }" ;; *) return 1 ;; esac; }
# cl_prepare <closing steps, space- or comma-separated>: the plan, the states, the eligible rows, the probes → $TMP93
cl_prepare() {
  tmp93
  sh checks/plan.sh parse > "$TMP93/parsed" 2> "$TMP93/err" || { cat "$TMP93/err" >&2; echo 'ViD metrics: the plan block does not hold.' >&2; return 1; }
  sh checks/plan.sh map --all > "$TMP93/map" 2>/dev/null || { echo 'ViD metrics: no currency map (checks/plan.sh map).' >&2; return 1; }
  # v0.9.7.1 (3.10, R10): the progress update reads the states at HEAD once, on the same map, and hands them here
  if [ -n "${VID_EVIDENCE_STATES:-}" ] && [ -s "${VID_EVIDENCE_STATES:-}" ]; then cp "$VID_EVIDENCE_STATES" "$TMP93/states"
  else sh checks/evidence.sh rows --at HEAD --map "$TMP93/map" > "$TMP93/states" || { echo 'ViD metrics: checks/evidence.sh could not read the evidence.' >&2; return 1; }; fi
  : > "$TMP93/closed"; [ -f "$EV" ] && awk "$AWKAT"' $1 == "step-closed" && kv("step") != "" { print kv("step") }' "$EV" | sort -u > "$TMP93/closed"
  printf '%s\n' "$1" | tr ' ,' '\n\n' | grep -v '^$' > "$TMP93/closing" || true
  for _s in $(cat "$TMP93/closing"); do
    grep -q "^step	$_s	" "$TMP93/parsed" || { echo "ViD metrics: refused — no step $_s in the plan." >&2; return 1; }
  done
  awk -F'\t' 'FILENAME == ARGV[1] || FILENAME == ARGV[2] { S[$1] = 1; next } FILENAME == ARGV[3] { if ($1 == "row" && ($3 in S)) R[$2] = $3; next }
    ($1 in R) && $2 != "owed" && $2 != "deploy-owed" && $2 != "held" && $2 != "later" { print $1 "\t" R[$1] "\t" $2 }' "$TMP93/closed" "$TMP93/closing" "$TMP93/parsed" "$TMP93/states" > "$TMP93/elig"
  printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { for (i = 1; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i); t = $8; sub(/ .*/, "", t); print $1 "\t" $2 "\t" $4 "\t" $7 "\t" t }' > "$TMP93/inv"
  printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*hostility[[:space:]]*$/ { id = $2; gsub(/^[ \t]+|[ \t]+$/, "", id); t = ""; pr = 0
      for (i = 3; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^tests\//) { t = f; sub(/ .*/, "", t) } if (f ~ /^proved-red:[ \t]*[^ \t]/) pr = 1 }
      if (id ~ /^HOS-/ && t != "" && pr) print id "\t" t }' > "$TMP93/probes"
}
# cl_required <set 5: yes|no>: $TMP93/req (`<id> <set> <step>`), $TMP93/notes; refusals on stderr, exit 1
cl_required() {
  awk -F'\t' -v pf="$TMP93/parsed" -v cf="$TMP93/closing" -v inf="$TMP93/inv" '
    BEGIN { while ((getline l < cf) > 0) C[l] = 1
      while ((getline l < pf) > 0) { split(l, a, "\t"); if (a[1] == "step" && (a[2] in C)) { n = split(a[5], b, /[ \t]+/); for (k = 1; k <= n; k++) if (b[k] != "" && b[k] != "-") BO[b[k]] = 1 } }
      while ((getline l < inf) > 0) { split(l, a, "\t"); KIND[a[1]] = a[2] } }
    { r = $1; s = $2; st = $3; set = ""
      if (s in C) set = set ",1"; if (s in BO) set = set ",2"; if (KIND[r] == "journey" || KIND[r] == "shell" || KIND[r] == "reachability") set = set ",3"
      if (st == "red" || st == "stale" || st == "never") set = set ",4"
      if (set != "") print r "\t" substr(set, 2) "\t" s }' "$TMP93/elig" > "$TMP93/req"
  awk -F'\t' '{ print $1 "\t3\t-" }' "$TMP93/probes" >> "$TMP93/req"
  : > "$TMP93/notes"
  [ "$1" = yes ] || return 0
  _sl=$(sed -n 's/^slice:[[:space:]]*\([0-9][0-9]*\).*/\1/p' .vid/RUN-STATE.md 2>/dev/null | head -n 1)
  [ -n "$_sl" ] || { echo 'ViD metrics: refused — RUN-STATE names no open slice (`slice: <N> open`), so there is no .vid/close/<slice>.rows to read.' >&2; return 1; }
  RF=.vid/close/$_sl.rows
  [ -f "$RF" ] || { echo "ViD metrics: refused — no $RF. Write it first from the closing steps' diff (git diff <base>..HEAD, the base lines above): one line per row you know the change affected, \`ROW-id | <one-line reason>\`, and \`note | <what you checked>\` for a change to shared: paths or uncited code. Empty when you name none." >&2; return 1; }
  awk -F'|' -v ef="$TMP93/elig" -v rf="$TMP93/req" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN { while ((getline l < ef) > 0) { split(l, a, "\t"); E[a[1]] = a[2] } while ((getline l < rf) > 0) { split(l, a, "\t"); Q[a[1]] = 1 } }
    /^[ \t]*$/ || /^[ \t]*#/ { next }
    { k = trim($1); v = ""; if (index($0, "|")) { v = $0; sub(/^[^|]*\|/, "", v); v = trim(v) } }
    k == "note" { if (v == "") print "BAD\tline " NR ": a note says what was checked — note | <what>"; else print "NOTE\t" v; next }
    k ~ /^ROW-[0-9A-Za-z-]+$/ {
      if (v == "") { print "BAD\tline " NR ": " k " has no reason — ROW-id | <one-line reason>"; next }
      if (!(k in E)) { print "BAD\tline " NR ": " k " is not eligible — not a row of a closing or closed step, or owed, held or later"; next }
      if (!(k in Q)) { Q[k] = 1; print "ADD\t" k "\t5\t" E[k] } else if (!(k in F)) print "FIVE\t" k; F[k] = 1; next }
    { print "BAD\tline " NR ": does not parse — a line is `ROW-id | <reason>` or `note | <what was checked>`" }' "$RF" > "$TMP93/set5"
  if grep -q '^BAD' "$TMP93/set5"; then echo "ViD metrics: refused — $RF:" >&2; sed -n 's/^BAD\t/    /p' "$TMP93/set5" >&2; return 1; fi
  # v0.9.7.0.12 (3.1, R1): a listed row already required keeps its sets and gains 5
  awk -F'\t' -v ff="$TMP93/set5" 'BEGIN { while ((getline l < ff) > 0) { split(l, a, "\t"); if (a[1] == "FIVE") V[a[2]] = 1 } } ($1 in V) { $2 = $2 ",5" } { print }' OFS='\t' "$TMP93/req" > "$TMP93/req.5" && mv "$TMP93/req.5" "$TMP93/req"
  sed -n 's/^ADD\t//p' "$TMP93/set5" >> "$TMP93/req"
  sed -n 's/^NOTE\t/note /p' "$TMP93/set5" > "$TMP93/notes"
  return 0
}
# cl_resolve <receipt path>: `<kept name>\t<at>\t<tree>\t<base>` of the valid published receipt it names —
# a kept name, or a copy (<sha>.<kind>.xml: the newest kept receipt of that commit and kind); exit 1 if none
cl_resolve() {
  _b=${1##*/}
  _k=$(timed "$EV" | cut -f3- | awk -v b="$_b" "$AWKAT"' $1 == "invalidated" { I[kv("report")] = 1; next }
    $1 == "ledger-run" { r = kv("report"); if (r != "" && r != "none" && !index(r, ".proof.")) { n++; A[n] = r; T[n] = lastat() } }   # v0.9.8 (R15): never a proof receipt
    END { sha = b; sub(/\..*/, "", sha); rest = substr(b, length(sha) + 2)
      for (i = n; i >= 1; i--) { if (A[i] in I) continue
        if (A[i] == b) { print A[i] "\t" T[i]; exit }
        if (index(A[i], sha ".run-") == 1) { x = substr(A[i], length(sha) + 6); d = index(x, "."); if (d > 1 && substr(x, d + 1) == rest) { print A[i] "\t" T[i]; exit } } } }')
  [ -n "$_k" ] || return 1
  _n=${_k%%	*}
  [ -f ".vid/ledger-results/$_n" ] || return 1
  if [ -f ".vid/ledger-results/$_n.tree" ]; then
    _t=$(sed -n 's/^tree=//p' ".vid/ledger-results/$_n.tree" | head -n 1); _s=$(sed -n 's/^base=//p' ".vid/ledger-results/$_n.tree" | head -n 1)
  else _s=${_n%%.*}; _t=$(git rev-parse -q --verify "$_s^{tree}" 2>/dev/null || true); fi
  [ -n "$_t" ] || return 1
  printf '%s\t%s\n' "$_k" "$_t	$_s"
}
# cl_twin <kept name>: its deployed-shape twin's name
cl_twin() { case "$1" in *.close.xml) echo "${1%.close.xml}.close.deployed.xml" ;; *.checkpoint.xml) echo "${1%.checkpoint.xml}.checkpoint.deployed.xml" ;; *.full.xml) echo "${1%.full.xml}.deployed.xml" ;; *) echo "$1.none" ;; esac; }
# cl_population [<kept name to leave out>]: `<kept>\t<tree>\t<base>` of the newest valid full or checkpoint receipt (inline), newest by the commit it tested, publication breaking a tie; nothing if none
cl_population() {
  _best=''; _bb=''; _bt=''
  for _r in $(timed "$EV" | cut -f3- | awk "$AWKAT"' $1 == "invalidated" { I[kv("report")] = 1; next }
      $1 == "ledger-run" && (kv("kind") == "full" || kv("kind") == "checkpoint") { r = kv("report"); if (r != "" && r != "none" && !index(r, ".proof.")) { n++; A[n] = r } }
      END { for (i = 1; i <= n; i++) if (!(A[i] in I)) print A[i] }'); do
    [ "$_r" = "${1:-}" ] && continue
    [ -f ".vid/ledger-results/$_r" ] || continue
    if [ -f ".vid/ledger-results/$_r.tree" ]; then _t=$(sed -n 's/^tree=//p' ".vid/ledger-results/$_r.tree" | head -n 1); _s=$(sed -n 's/^base=//p' ".vid/ledger-results/$_r.tree" | head -n 1)
    else _s=${_r%%.*}; _t=$(git rev-parse -q --verify "$_s^{tree}" 2>/dev/null || true); fi
    [ -n "$_t" ] || continue
    if [ -n "$_best" ] && [ "$_bb" != "$_s" ] && git merge-base --is-ancestor "$_s" "$_bb" 2>/dev/null; then continue; fi
    _best=$_r; _bb=$_s; _bt=$_t
  done
  [ -n "$_best" ] && printf '%s\t%s\t%s\n' "$_best" "$_bt" "$_bb"
  return 0
}
# cl_judge <ids file: id<TAB>required yes|no> <population inline> <population deployed> <to inline> <to deployed> <changed paths file> <mode close|checkpoint|batch>
#   → PASS id · PROV id · NOTRUN id case · FAILED id case (FAILED only in close mode: a checkpoint's red is a result, not a refusal;
#   v0.9.7.0.12 batch mode is close mode with a skipped case not covered — NOTRUN — rather than red)
cl_judge() {
  for _f in "$2" "$3" "$4" "$5"; do if [ -f "$_f" ]; then read_report "$_f"; fi > "$TMP93/j.$(printf '%s' "$_f" | cksum | cut -d' ' -f1)"; done
  # v0.9.7.0.11 (3.1, R1): a receipt carrying its request's frozen rows (.rows) passes only the rows it credits (checks/evidence.sh credit)
  : > "$TMP93/credit"
  if [ -f "$4" ] && [ -f "$4.rows" ]; then sh checks/evidence.sh credit "$4" 2>/dev/null | awk '{ print "ti\t" $1 }' >> "$TMP93/credit"; echo 'ti	-' >> "$TMP93/credit"; fi
  if [ -f "$5" ] && [ -f "$5.rows" ]; then sh checks/evidence.sh credit "$5" 2>/dev/null | awk '{ print "td\t" $1 }' >> "$TMP93/credit"; echo 'td	-' >> "$TMP93/credit"; fi
  _dd=no; ddeclared && _dd=yes; [ -n "${CLDD:-}" ] && _dd=$CLDD   # v0.9.7.0.12: a batch judges by its frozen harness
  _hp=no; [ -f "$2" ] && _hp=yes
  awk -F'\t' -v inf="$TMP93/inv" -v prf="$TMP93/probes" -v chf="$6" -v crf="$TMP93/credit" -v dd="$_dd" -v hasp="$_hp" -v mode="$7" \
      -v f1="$TMP93/j.$(printf '%s' "$2" | cksum | cut -d' ' -f1)" -v f2="$TMP93/j.$(printf '%s' "$3" | cksum | cut -d' ' -f1)" \
      -v f3="$TMP93/j.$(printf '%s' "$4" | cksum | cut -d' ' -f1)" -v f4="$TMP93/j.$(printf '%s' "$5" | cksum | cut -d' ' -f1)" '
    function load(f, pre,   line, a, p) { while ((getline line < f) > 0) { split(line, a, " "); if (a[1] != "case") continue; p = a[2]; sub(/::.*/, "", p); k = ++n[pre, p]; cid[pre, p, k] = a[2]; cst[pre, p, k] = a[3] } close(f) }
    function pk(pre, p, tok,   i, out, alt) { out = ""; alt = tok; gsub(/-/, "_", alt); for (i = 1; i <= n[pre, p] + 0; i++) if (index(cid[pre, p, i], tok) || index(cid[pre, p, i], alt)) out = out i " "; return out }
    function bad(c) { return (mode == "batch" && G[c] == "skipped") ? "NOTRUN" : "FAILED" }
    function pick(pre, p, id, der,   sel, m, t, k) { sel = pk(pre, p, id); if (sel == "") { m = split(der, t, /[ ,]+/); for (k = 1; k <= m; k++) { if (t[k] == "") continue; sel = pk(pre, p, t[k]); if (sel != "") break } } return sel }
    BEGIN { load(f1, "pi"); load(f2, "pd"); load(f3, "ti"); load(f4, "td")
      while ((getline l < inf) > 0) { split(l, a, "\t"); KIND[a[1]] = a[2]; ACT[a[1]] = a[3]; DER[a[1]] = a[4]; TST[a[1]] = a[5] }
      while ((getline l < prf) > 0) { split(l, a, "\t"); KIND[a[1]] = "hostility"; TST[a[1]] = a[2] }
      while ((getline l < chf) > 0) CHG[l] = 1
      while ((getline l < crf) > 0) { split(l, a, "\t"); if (a[2] == "-") HC[a[1]] = 1; else CR[a[1], a[2]] = 1 } }
    { id = $1; req = $2; p = TST[id]; if (p !~ /^tests\//) { if (req == "yes") print "NOTRUN\t" id "\t-"; next }
      pop = (dd == "yes" && (KIND[id] == "journey" || ACT[id] == "(process)")); pp = pop ? "pd" : "pi"; tp = pop ? "td" : "ti"
      got = pick(tp, p, id, DER[id]); m = split(got, gi, " "); split("", G); ng = 0; allp = 1
      for (k = 1; k <= m; k++) { if (gi[k] == "") continue; c = cid[tp, p, gi[k]]; G[c] = cst[tp, p, gi[k]]; ng++; if (G[c] != "passed") allp = 0 }
      if (ng > 0 && allp && (!(tp in HC) || (tp, id) in CR)) print "PASS\t" id
      if (req != "yes") next
      ex = (hasp == "yes") ? pick(pp, p, id, DER[id]) : ""
      if (ex == "" || (p in CHG)) { print "PROV\t" id; if (ng == 0) print "NOTRUN\t" id "\t-"
        if (mode == "close" || mode == "batch") for (c in G) if (G[c] != "passed") print bad(c) "\t" id "\t" c
        next }
      m = split(ex, ei, " "); split("", X)
      for (k = 1; k <= m; k++) { if (ei[k] == "") continue; c = cid[pp, p, ei[k]]; X[c] = 1
        if (!(c in G)) print "NOTRUN\t" id "\t" c; else if ((mode == "close" || mode == "batch") && G[c] != "passed") print bad(c) "\t" id "\t" c }
      if (mode == "close" || mode == "batch") for (c in G) if (!(c in X) && G[c] != "passed") print bad(c) "\t" id "\t" c
    }' "$1"
}
if [ "${1:-}" = close-rows ]; then
  shift; STEPS=''
  while [ $# -gt 0 ]; do case "$1" in --steps) STEPS=${2:-}; shift 2 ;; *) echo "metrics close-rows: unknown argument $1" >&2; exit 2 ;; esac; done
  [ -n "$STEPS" ] || { echo 'metrics close-rows: --steps <id>[,<id>…] is required' >&2; exit 2; }
  CH=$(gate_home) || { echo 'metrics close-rows: off — not inside a develop run under a 0.9.6 plan (sh checks/plan.sh gate); a close there is the whole-ledger run.'; exit 0; }
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || { echo 'metrics close-rows: the inventory block does not open with grammar: 0.9.3 — nothing computed'; exit 0; }
  cl_prepare "$STEPS" || exit 1
  _bad=no
  for _s in $(cat "$TMP93/closing"); do sh checks/plan.sh base "$_s" || _bad=yes; done
  [ "$_bad" = no ] || exit 1
  cl_required yes || exit 1
  sort -t "$(printf '\t')" -k2,2n -k1,1 "$TMP93/req" | awk -F'\t' '{ print "required row=" $1 " sets=" $2 " step=" $3 " phase=" ($2 ~ /(^|,)[145](,|$)/ ? 1 : 2) }'
  cat "$TMP93/notes"
  echo "close-rows steps=$(tr '\n' ',' < "$TMP93/closing" | sed 's/,$//') required=$(grep -c . "$TMP93/req" || true)"
  exit 0
fi
# v0.9.7.0.12 (3.2, 3.3, 3.5; R2, R3, R5) — the close batch's frozen inputs and its chunk judge (checks/test.sh's
# batch supervisor calls both; the claim by batch reads what close-freeze wrote):
#   close-freeze --steps <ids> --out <dir> --tree <tree>   close-rows' computation, frozen into <dir>: `required`
#     (`<id> <sets> <step> <phase> <shape inline|deployed>` per row, tab-separated — the shape the row is paid in: deployed
#     for a journey or actor `(process)` row when the harness declares deployed-selector:), `inv` and `probes` (the rows'
#     kind, actor, derived-from and test path, as the judge reads them), `population` (`<receipt path> <tree> <base>
#     <deployed twin path or ->` of the newest population run — never a batch's own chunk, which is a close — or empty),
#     `chg` (the paths changed between the population's tree and <tree>) and `dd` (yes|no). Refusals as close-rows'.
#   batch-judge <frozen dir> <rows file> <receipts file>   one chunk against the frozen expected cases: the receipts file
#     holds `<receipt path> <inline|deployed>`; prints cl_judge's batch-mode lines (PASS, PROV, NOTRUN, FAILED) for the
#     chunk's rows, crediting only that chunk's receipts (each through its .rows).
if [ "${1:-}" = close-freeze ]; then
  shift; STEPS=''; FOUT=''; FTREE=''
  while [ $# -gt 0 ]; do case "$1" in --steps) STEPS=${2:-}; shift 2 ;; --out) FOUT=${2:-}; shift 2 ;; --tree) FTREE=${2:-}; shift 2 ;; *) echo "metrics close-freeze: unknown argument $1" >&2; exit 2 ;; esac; done
  [ -n "$STEPS" ] && [ -n "$FOUT" ] && [ -n "$FTREE" ] || { echo 'metrics close-freeze: --steps <ids> --out <dir> --tree <tree> are required' >&2; exit 2; }
  mkdir -p "$FOUT"; FOUT=$(cd "$FOUT" && pwd)
  CH=$(gate_home) || { echo 'ViD metrics: refused — close-freeze runs inside a develop run under a 0.9.6 plan.' >&2; exit 1; }
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || { echo 'ViD metrics: refused — the inventory block does not open with grammar: 0.9.3.' >&2; exit 1; }
  cl_prepare "$STEPS" || exit 1
  cl_required yes || exit 1
  _dd=no; ddeclared && _dd=yes; echo "$_dd" > "$FOUT/dd"
  awk -F'\t' -v inf="$TMP93/inv" -v dd="$_dd" 'BEGIN { while ((getline l < inf) > 0) { split(l, a, "\t"); K[a[1]] = a[2]; A[a[1]] = a[3] } }
    { sh = (dd == "yes" && (K[$1] == "journey" || A[$1] == "(process)")) ? "deployed" : "inline"
      print $1 "\t" $2 "\t" $3 "\t" ($2 ~ /(^|,)[145](,|$)/ ? 1 : 2) "\t" sh }' "$TMP93/req" > "$FOUT/required"
  cp "$TMP93/inv" "$FOUT/inv"; cp "$TMP93/probes" "$FOUT/probes"
  RD=$(pwd)/.vid/ledger-results; : > "$FOUT/population"; : > "$FOUT/chg"
  POP=$(cl_population); PN=$(printf '%s\n' "$POP" | cut -f1)
  if [ -n "$PN" ]; then
    PT=$(printf '%s\n' "$POP" | cut -f2); PB=$(printf '%s\n' "$POP" | cut -f3); PD=$(cl_twin "$PN"); [ -f "$RD/$PD" ] && PD=$RD/$PD || PD=-
    printf '%s\t%s\t%s\t%s\n' "$RD/$PN" "$PT" "$PB" "$PD" > "$FOUT/population"
    git diff --no-renames --name-only "$PT" "$FTREE" -- > "$FOUT/chg" 2>/dev/null || true
  fi
  echo "close-freeze steps=$(tr '\n' ',' < "$TMP93/closing" | sed 's/,$//') required=$(grep -c . "$FOUT/required" || true) phase1=$(awk -F'\t' '$4 == 1' "$FOUT/required" | grep -c . || true) population=${PN:-none}"
  exit 0
fi
if [ "${1:-}" = batch-judge ]; then
  FZ=${2:-}; JR=${3:-}; JC=${4:-}
  [ -d "$FZ" ] && [ -f "$JR" ] && [ -f "$JC" ] || { echo 'metrics batch-judge: <frozen dir> <rows file> <receipts file>' >&2; exit 2; }
  tmp93; cp "$FZ/inv" "$TMP93/inv"; cp "$FZ/probes" "$TMP93/probes"
  awk 'NF { print $1 "\tyes" }' "$JR" > "$TMP93/ids"
  PI=$(cut -f1 "$FZ/population" | head -n 1); PD=$(cut -f4 "$FZ/population" | head -n 1); [ "$PD" = - ] && PD=''
  JI=$(awk -F'\t' '$2 == "inline" { print $1; exit }' "$JC"); JD=$(awk -F'\t' '$2 == "deployed" { print $1; exit }' "$JC")
  CLDD=$(cat "$FZ/dd" 2>/dev/null || echo no) cl_judge "$TMP93/ids" "$PI" "$PD" "$JI" "$JD" "$FZ/chg" batch
  exit 0
fi
if [ "${1:-}" = provisional ]; then
  CH=$(gate_home) || { echo 'metrics provisional: off — not inside a develop run under a 0.9.6 plan.'; exit 0; }
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || { echo 'metrics provisional: the inventory block does not open with grammar: 0.9.3 — nothing computed'; exit 0; }
  cl_prepare '' || exit 1
  awk -F'\t' '$3 == "pass" { print $1 "\tyes" }' "$TMP93/elig" > "$TMP93/ids"
  POP=$(cl_population); PN=$(printf '%s\n' "$POP" | cut -f1); PT=$(printf '%s\n' "$POP" | cut -f2)
  : > "$TMP93/chg"; [ -n "$PT" ] && git diff --no-renames --name-only "$PT" 'HEAD^{tree}' -- > "$TMP93/chg" 2>/dev/null
  RD=.vid/ledger-results; PD=''; [ -n "$PN" ] && PD=$(cl_twin "$PN")
  cl_judge "$TMP93/ids" "${PN:+$RD/$PN}" "${PD:+$RD/$PD}" '' '' "$TMP93/chg" checkpoint | awk -F'\t' '$1 == "PROV" { print "provisional row=" $2; n++ } END { print "provisional rows=" n + 0 }'
  exit 0
fi
# v0.9.7.0.12 (3.5, R5): claim --batch <id> [--from <batch id|receipt>] — one claim over a close batch (checks/test.sh
# --batch), read from its ticket at the run's home: one tree (every constituent receipt's .tree names the batch's);
# every chunk of its layout has its newest sub-ticket's receipts (published, its retry's, or adopted) — a chunk whose
# newest receipt is red can't be left out, so a red or missing one refuses; the frozen population reference re-checked
# (still published, not invalidated) and never one of the batch's own chunks; 0.9.7.0.11's credit per receipt (each
# chunk judged on its own receipts, which credit its rows through their .rows), joined; completeness over the frozen
# required rows with the close's rules. --from <batch> takes that batch's last publication as the before-state's
# boundary. On success one `step-closed step=<id> report=<the newest constituent> batch=<id>` per step.
if [ "${1:-}" = claim ] && [ "$IG93" = yes ] && printf '%s\n' "$@" | grep -qx -- --batch && CH=$(gate_home); then
  shift; BID=''; FROM=''
  while [ $# -gt 0 ]; do case "$1" in --batch) BID=${2:-}; shift 2 ;; --from) FROM=${2:-}; shift 2 ;; *) echo "metrics claim: $1 does not go with --batch (claim --batch <id> [--from <batch id|receipt>])" >&2; exit 2 ;; esac; done
  [ -n "$BID" ] || { echo 'metrics claim: --batch <id> names the batch ticket' >&2; exit 2; }
  FROMA=''; case "$FROM" in ''|*/*|*.xml) [ -z "$FROM" ] || { [ -f "$FROM" ] || { echo "metrics claim: $FROM missing" >&2; exit 2; }; FROMA=$(cd "$(dirname "$FROM")" && pwd)/${FROM##*/}; } ;; esac
  cd "$CH" || exit 2
  BT=.vid/requests/$BID; FZ=$BT/frozen
  [ -f "$BT/batch" ] && [ -f "$FZ/required" ] || { echo "metrics claim: refused — no close batch $BID at the run's home (.vid/requests/$BID/batch)." >&2; exit 2; }
  tmp93; cp "$FZ/inv" "$TMP93/inv"; cp "$FZ/probes" "$TMP93/probes"
  BTR=$(sed -n 's/^tree=//p' "$BT/batch" | head -n 1); STEPS=$(sed -n 's/^steps=//p' "$BT/batch" | head -n 1)
  RD=.vid/ledger-results; : > "$TMP93/judged"; : > "$TMP93/cons"; BAD=''
  # the population reference, frozen at the batch's start, re-checked
  PI=$(cut -f1 "$FZ/population" | head -n 1); PD=$(cut -f4 "$FZ/population" | head -n 1); [ "$PD" = - ] && PD=''
  if [ -n "$PI" ] && ! cl_resolve "$PI" > /dev/null; then echo "claim refused — the batch's population run ${PI##*/} is no longer a valid published receipt (invalidated or gone); request the batch again"; exit 2; fi
  for _n in $(cut -f1 "$BT/layout"); do
    _cd=$BT/chunks/$_n; [ -d "$_cd-retry" ] && _cd=$_cd-retry
    if [ ! -s "$_cd/receipts" ]; then echo "not-run chunk=${_cd##*/} — no receipt"; BAD=yes; continue; fi
    while IFS="$(printf '\t')" read -r _rp _sh; do
      _rn=${_rp##*/}
      [ "$(sed -n 's/^tree=//p' "$RD/$_rn.tree" 2>/dev/null | head -n 1)" = "$BTR" ] || { echo "mixed tree chunk=${_cd##*/} report=$_rn — not the batch's tree $BTR"; BAD=yes; }
      _res=$(cl_resolve "$RD/$_rn") || { echo "not-run chunk=${_cd##*/} report=$_rn — not a valid published receipt"; BAD=yes; continue; }
      printf '%s\t%s\n' "$_rn" "$(printf '%s\n' "$_res" | cut -f2)" >> "$TMP93/cons"
    done < "$_cd/receipts"
    awk 'NF { print $1 "\tyes" }' "$_cd/rows" > "$TMP93/ids"
    _ji=$(awk -F'\t' '$2 == "inline" { print $1; exit }' "$_cd/receipts"); _jd=$(awk -F'\t' '$2 == "deployed" { print $1; exit }' "$_cd/receipts")
    CLDD=$(cat "$FZ/dd" 2>/dev/null || echo no) cl_judge "$TMP93/ids" "$PI" "$PD" "${_ji:+$RD/${_ji##*/}}" "${_jd:+$RD/${_jd##*/}}" "$FZ/chg" batch >> "$TMP93/judged"
  done
  # completeness over the frozen required rows: each judged with its own chunk; a required row no chunk holds is not run
  awk -F'\t' 'NR == FNR { if ($1 == "PASS" || $1 == "NOTRUN" || $1 == "FAILED" || $1 == "PROV") J[$2] = 1; next } !($1 in J) { print "NOTRUN\t" $1 "\t-" }' "$TMP93/judged" "$FZ/required" >> "$TMP93/judged"
  if [ -n "$BAD" ] || grep -qE '^(NOTRUN|FAILED)' "$TMP93/judged"; then
    awk -F'\t' '$1 == "NOTRUN" { print "not-run row=" $2 " case=" $3 } $1 == "FAILED" { print "failed row=" $2 " case=" $3 }' "$TMP93/judged"
    echo "claim refused — the batch lacks or fails an expected case of a required row, or a chunk (population: ${PI:+${PI##*/}}${PI:-none}); no row is claimed and no step closes"
    exit 2
  fi
  # the before state: as of --from's publication — a batch's last publication, or a receipt's
  : > "$TMP93/before"
  sh checks/plan.sh map --all > "$TMP93/map" 2>/dev/null || { echo 'ViD metrics: no currency map (checks/plan.sh map).' >&2; exit 2; }
  if [ -n "$FROM" ]; then
    if [ -z "$FROMA" ]; then
      FB_=.vid/requests/$FROM; [ -f "$FB_/batch" ] && [ -f "$FB_/receipts" ] || { echo "metrics claim: refused — --from $FROM is neither a receipt nor a close batch at the run's home." >&2; exit 2; }
      FB=$(sed -n 's/^base=//p' "$FB_/batch" | head -n 1)
      FAT=$(cut -f2 "$FB_/receipts" | while IFS= read -r _rp; do cl_resolve "$RD/${_rp##*/}" | cut -f2; done | sort | tail -n 1)
      [ -n "$FAT" ] || { echo "metrics claim: refused — the batch $FROM holds no valid published receipt; the before state is read as of its last publication." >&2; exit 2; }
    else
      FR=$(cl_resolve "$FROMA") || { echo "metrics claim: refused — $FROM names no valid published receipt; the before state is read as of its publication." >&2; exit 2; }
      FAT=$(printf '%s\n' "$FR" | cut -f2); FB=$(printf '%s\n' "$FR" | cut -f4)
    fi
    sh checks/evidence.sh rows --at "$FB" --map "$TMP93/map" --until "$FAT" > "$TMP93/before" || { echo 'metrics claim: the before state could not be read.' >&2; exit 2; }
  fi
  vstate93
  awk -F'\t' -v vf="$TMP93/vstate" -v bf="$TMP93/before" -v jf="$TMP93/judged" '
    BEGIN { while ((getline l < vf) > 0) { split(l, a, "\t"); L[a[1]] = a[2]; H[a[1]] = a[9] }
      while ((getline l < bf) > 0) { split(l, a, "\t"); B[a[1]] = a[2] }
      while ((getline l < jf) > 0) { split(l, a, "\t"); if (a[1] == "PASS") P[a[2]] = 1; if (a[1] == "PROV") V[a[2]] = 1 } }
    { id = $1; if (!(id in P)) next
      lv = (id in L) ? L[id] : "NONE"; h = (id in H) ? H[id] : "-"
      if (h != "-") { print "held row=" id " reason=" h; nh++; next }
      if (lv != "KEPT") { print "claim row=" id " why=" (lv == "NONE" ? "unverdicted" : "breached"); n++ }
      else if (B[id] != "pass") { print "claim row=" id " why=re-paid"; n++ }
      else next
      if (id in V) { print "provisional row=" id; np++ } }
    END { printf "claim rows=%d held=%d provisional=%d", n + 0, nh + 0, np + 0 }' "$FZ/required"
  echo " from=${FROM:-none} batch=$BID steps=$STEPS"
  LAST=$(awk -F'\t' '{ print $2 "\t" $1 }' "$TMP93/cons" | sort | tail -n 1 | cut -f2)
  for _s in $(printf '%s\n' "$STEPS" | tr ',' ' '); do printf 'step-closed step=%s report=%s batch=%s at=%s\n' "$_s" "$LAST" "$BID" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"; done
  exit 0
fi
if [ "${1:-}" = claim ] && [ "$IG93" = yes ] && CH=$(gate_home); then
  shift; FROM=''; TO=''; STEPS=''
  while [ $# -gt 0 ]; do case "$1" in --from) FROM=$2; shift 2 ;; --to) TO=$2; shift 2 ;; --steps) STEPS=$2; shift 2 ;; *) echo "metrics claim: unknown argument $1" >&2; exit 2 ;; esac; done
  [ -n "$TO" ] || { echo 'metrics claim: --to <report> is required' >&2; exit 2; }
  [ -f "$TO" ] || { echo "metrics claim: $TO missing" >&2; exit 2; }
  case "$TO" in *.proof.*) echo "metrics claim: $TO is a proof receipt — never an ordinary one: it credits and claims nothing (checks/evidence.sh ordinary)" >&2; exit 2 ;; esac   # v0.9.8 (R15)
  case "$TO" in *.live.*) echo "metrics claim: $TO is a .live. report — a claim is computed over export-backed reports" >&2; exit 2 ;;
    *.checkpoint.xml|*.checkpoint.deployed.xml) echo "metrics claim: $TO is a checkpoint — it is recorded by sh checks/metrics.sh checkpoint, never claimed" >&2; exit 2 ;;
    *.close.deployed.xml) echo "metrics claim: $TO is a close's deployed-shape receipt — name its inline one; the twin is read with it" >&2; exit 2 ;; esac
  MODE=''
  case "$TO" in *.close.xml) MODE=close; [ -n "$STEPS" ] || { echo 'metrics claim: refused — a selected close is claimed with --steps <id>[,<id>…], the steps it closes.' >&2; exit 2; } ;;
    *.full.xml) [ -n "$STEPS" ] && MODE=full ;; esac
  if [ -n "$MODE" ]; then
    TOA=$(cd "$(dirname "$TO")" && pwd)/${TO##*/}; FROMA=''; [ -n "$FROM" ] && { [ -f "$FROM" ] || { echo "metrics claim: $FROM missing" >&2; exit 2; }; FROMA=$(cd "$(dirname "$FROM")" && pwd)/${FROM##*/}; }
    cd "$CH" || exit 2
    TOR=$(cl_resolve "$TOA") || { echo "metrics claim: refused — $TO names no valid published receipt (a ledger-run event, the file, not invalidated)." >&2; exit 2; }
    TON=$(printf '%s\n' "$TOR" | cut -f1); TOT=$(printf '%s\n' "$TOR" | cut -f3)
    cl_prepare "$STEPS" || exit 2
    if [ "$MODE" = close ]; then cl_required yes || exit 2; else cl_required no || exit 2; fi
    POP=$(cl_population "$TON"); PN=$(printf '%s\n' "$POP" | cut -f1); PT=$(printf '%s\n' "$POP" | cut -f2)
    : > "$TMP93/chg"; [ -n "$PT" ] && git diff --no-renames --name-only "$PT" "$TOT" -- > "$TMP93/chg" 2>/dev/null
    TOD=$(cl_twin "$TON"); PD=''; [ -n "$PN" ] && PD=$(cl_twin "$PN")
    # the ids judged: the required rows (completeness, a close only), and every eligible row (passing in --to)
    { if [ "$MODE" = close ]; then cut -f1 "$TMP93/req" | awk '{ print $0 "\tyes" }'; fi; cut -f1 "$TMP93/elig" | awk '{ print $0 "\tno" }'; } | awk -F'\t' '!s[$1]++' > "$TMP93/ids"
    RD=.vid/ledger-results
    cl_judge "$TMP93/ids" "${PN:+$RD/$PN}" "${PD:+$RD/$PD}" "$RD/$TON" "$RD/$TOD" "$TMP93/chg" close > "$TMP93/judged"
    if [ "$MODE" = close ] && grep -qE '^(NOTRUN|FAILED)' "$TMP93/judged"; then
      awk -F'\t' '$1 == "NOTRUN" { print "not-run row=" $2 " case=" $3 } $1 == "FAILED" { print "failed row=" $2 " case=" $3 }' "$TMP93/judged"
      echo "claim refused — the close lacks or fails an expected case of a required row (population: ${PN:-none yet}); no row is claimed and no step closes"
      exit 2
    fi
    # the before state: every row under R4 as of --from's publication
    : > "$TMP93/before"
    if [ -n "$FROMA" ]; then
      FR=$(cl_resolve "$FROMA") || { echo "metrics claim: refused — $FROM names no valid published receipt; the before state is read as of its publication." >&2; exit 2; }
      FAT=$(printf '%s\n' "$FR" | cut -f2); FB=$(printf '%s\n' "$FR" | cut -f4)
      sh checks/evidence.sh rows --at "$FB" --map "$TMP93/map" --until "$FAT" > "$TMP93/before" || { echo 'metrics claim: the before state could not be read.' >&2; exit 2; }
    fi
    vstate93
    awk -F'\t' -v vf="$TMP93/vstate" -v bf="$TMP93/before" -v jf="$TMP93/judged" -v ef="$TMP93/elig" '
      BEGIN { while ((getline l < vf) > 0) { split(l, a, "\t"); L[a[1]] = a[2]; H[a[1]] = a[9] }
        while ((getline l < bf) > 0) { split(l, a, "\t"); B[a[1]] = a[2] }
        while ((getline l < jf) > 0) { split(l, a, "\t"); if (a[1] == "PASS") P[a[2]] = 1; if (a[1] == "PROV") V[a[2]] = 1 } }
      { id = $1; if (!(id in P)) next
        lv = (id in L) ? L[id] : "NONE"; h = (id in H) ? H[id] : "-"
        if (h != "-") { print "held row=" id " reason=" h; nh++; next }
        if (lv != "KEPT") { print "claim row=" id " why=" (lv == "NONE" ? "unverdicted" : "breached"); n++ }
        else if (B[id] != "pass") { print "claim row=" id " why=re-paid"; n++ }
        else next
        if (id in V) { print "provisional row=" id; np++ } }
      END { printf "claim rows=%d held=%d provisional=%d", n + 0, nh + 0, np + 0 }' "$TMP93/elig"
    echo " from=${FROM:-none} to=$TO steps=$(tr '\n' ',' < "$TMP93/closing" | sed 's/,$//')"
    for _s in $(cat "$TMP93/closing"); do printf 'step-closed step=%s report=%s at=%s\n' "$_s" "$TON" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"; done
    exit 0
  fi
  if [ -n "$FROM" ]; then set -- claim --from "$FROM" --to "$TO"; else set -- claim --to "$TO"; fi
fi

# --- v0.9.7.2 (3.6, 3.7, 3.11; R9–R11, R15) — done, computed; deferrals as records; rows first seen passing ---------
#   step-state <id>[,<id>…]|--all   inside a 0.9.6 develop run, at its home. Per step one line `step-state step=<id>
#     kind=feature|hardening closed=yes|no graded=yes|no done=yes|no eligible=<n> close=batch:<id>|report:<name>|none`,
#     then the rows holding each, `<what> step=<id> row=<id>`: not-closed, ungraded, not-kept, `owed-hostility … by=<id>`,
#     `held … reason=<r> question=<Q<n>|none>`, and `breach` (an open product BREACHED, any transition — the
#     safeguard's reading, plan.sh R5). ELIGIBLE as the close defines it (cl_prepare): the step's rows not owed,
#     deploy-owed, held or later. CLOSED: the step's newest step-closed covers every row now eligible — a batch's frozen
#     required set; a report's claim, the step's rows in the plan in force at the close (a `.full.xml` covers every row);
#     event order alone proves nothing. GRADED: every eligible row has an eligible verdict of any class (vstate93) — a
#     journey every transition (k of n), an amended row graded again. DONE: closed; every eligible row KEPT, its KEPT
#     later than any open deferral of it; no unpaid hostility obligation of a protected row of the step (checks/
#     inventory.sh protected's `owed` lines — R4's whole set); no held row. Computed at every call, for both kinds;
#     the first time a step is done it appends `step-done step=<id>`, a stamp never read back. A step's kind is
#     hardening only under breadth first. And once per feature step, `step-rows-passing step=<id> tree=<12>
#     receipts=<names>`, the first time every row of the step passes — or is owed, held or later, one at least
#     passing — on receipts of one tree, by checks/evidence.sh's rule: the time it was seen.
#   defer --kind product|test --row <id> --why "<one line>" --from brief:<path>#<row>|receipt:<name> [--by <who>]
#     breadth first only. Refused unless the row sits in a hardening step and holds an eligible BREACHED verdict of
#     that kind (test: test or harness); refused for a protected row, and for a row already deferred. A feature-step
#     row is refused — a test-class breach there goes to a test-author pass at once (R10). Writes `deferred row=
#     kind= why="…" from= by=<who, default develop>`.
#   defer-resolved --row <id> --by <commit | the brief of a verdict on the row>   an open deferral's disposition,
#     never a verdict: `deferred-resolved row= by=commit:<12>|verdict:<brief>`. A fresh verdict makes a row KEPT.
ss_strat() { case "$(sed -n 's/^strategy:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//')" in breadth-first) echo breadth-first ;; *) echo depth-first ;; esac; }
# ss_prot: R4's whole protected set → $TMP93/pinv (inventory.sh protected's lines) and $TMP93/prot (`<row> <from>`, the plan's protected: line too)
ss_prot() {
  : > "$TMP93/pinv"; [ -f checks/inventory.sh ] && { sh checks/inventory.sh protected > "$TMP93/pinv" 2>/dev/null || : > "$TMP93/pinv"; }
  { awk '$1 == "protected" { f = $3; sub(/^from=/, "", f); print $2 "\t" f }' "$TMP93/pinv"; awk -F'\t' '$1 == "prot" { print $2 "\tdesignated" }' "$TMP93/parsed"; } > "$TMP93/prot"
}
# ss_compute <ids, comma-separated, or --all>: the step-state lines on stdout; stamps appended to the events
ss_compute() {
  tmp93
  if [ "$1" = --all ]; then _sl=$(sh checks/plan.sh parse 2>/dev/null | awk -F'\t' '$1 == "step" { print $2 }' | paste -sd, -); else _sl=$1; fi
  [ -n "$_sl" ] || { echo 'ViD metrics: the plan names no step.' >&2; return 1; }
  cl_prepare "$_sl" || return 1
  vstate93; ss_prot
  awk "$AWKAT"' $1 == "plan-change" { h = kv("hash") } $1 == "step-closed" && kv("step") != "" { s = kv("step"); R[s] = kv("report"); B[s] = kv("batch"); P[s] = h }
    END { for (s in R) print s "\t" R[s] "\t" (B[s] == "" ? "-" : B[s]) "\t" (P[s] == "" ? "-" : P[s]) }' "$EV" > "$TMP93/closes"
  # each closed step's coverage: the batch's frozen required set; a report's claim — the step's rows in the plan in force then
  : > "$TMP93/cov"
  while IFS='	' read -r _s _r _b _p; do
    grep -qxF -- "$_s" "$TMP93/closing" || continue
    if [ "$_b" != - ]; then [ -f ".vid/requests/$_b/frozen/required" ] && awk -F'\t' -v s="$_s" '{ print s "\t" $1 }' ".vid/requests/$_b/frozen/required" >> "$TMP93/cov"
    else case "$_r" in
      *.full.xml) printf '%s\t*\n' "$_s" >> "$TMP93/cov" ;;
      *) if [ "$_p" != - ] && [ -f ".vid/plans/$_p.plan" ]; then
           [ -f "$TMP93/kp.$_p" ] || sh checks/plan.sh parse ".vid/plans/$_p.plan" > "$TMP93/kp.$_p" 2>/dev/null   # each kept plan parsed once
           awk -F'\t' -v s="$_s" '$1 == "row" && $3 == s { print s "\t" $2 }' "$TMP93/kp.$_p" >> "$TMP93/cov"
         fi ;;
    esac; fi
  done < "$TMP93/closes"
  awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+/ { print }' .vid/RUN-STATE.md 2>/dev/null > "$TMP93/qs" || : > "$TMP93/qs"
  : > "$TMP93/stamps"
  awk -v pd="$TMP93" -v st="$(ss_strat)" "$AWKAT"'
    function whole(s, id,   p, q, b, a) { q = s; while ((p = index(q, id)) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; a = substr(q, p + length(id), 1); if (b !~ /[A-Za-z0-9_-]/ && a !~ /[A-Za-z0-9_-]/) return 1; q = substr(q, p + 1) } return 0 }
    function out(w, s, r, x) { L[s] = L[s] w " step=" s " row=" r x "\n" }
    BEGIN { FS = "\t"
      while ((getline l < (pd "/closing")) > 0) if (l != "") QO[++nq] = l
      while ((getline l < (pd "/parsed")) > 0) { split(l, a, "\t"); if (a[1] == "step") K[a[2]] = (st == "breadth-first" && a[7] == "hardening") ? "hardening" : "feature"; else if (a[1] == "row") { SR[a[3]] = SR[a[3]] " " a[2]; NR_[a[3]]++ } }
      while ((getline l < (pd "/states")) > 0) { split(l, a, "\t"); ST[a[1]] = a[2]; DT[a[1]] = a[3] }
      while ((getline l < (pd "/vstate")) > 0) { split(l, a, "\t"); VL[a[1]] = a[2]; VH[a[1]] = a[9]; GK[a[1]] = a[12] + 0; GN[a[1]] = a[13] + 0; BCS[a[1]] = a[14] }
      while ((getline l < (pd "/pinv")) > 0) { split(l, a, " "); if (a[1] == "owed") { b = a[3]; sub(/^by=/, "", b); OW[a[2]] = OW[a[2]] " " b } }
      while ((getline l < (pd "/cov")) > 0) { split(l, a, "\t"); if (a[2] == "*") ALL[a[1]] = 1; else COV[a[1], a[2]] = 1 }
      while ((getline l < (pd "/closes")) > 0) { split(l, a, "\t"); CL[a[1]] = (a[3] != "-") ? "batch:" a[3] : "report:" a[2] }
      while ((getline l < (pd "/qs")) > 0) QS[++nqs] = l
      FS = " " }
    { r = kv("row") }
    $1 == "verdict" && r != "" { LV[r] = NR }
    $1 == "deferred" && r != "" { DF[r] = NR }
    $1 == "deferred-resolved" && r != "" { delete DF[r] }
    $1 == "step-done" { SD[kv("step")] = 1 }
    $1 == "step-rows-passing" { RP[kv("step")] = 1 }
    END {
      for (i = 1; i <= nq; i++) { s = QO[i]; n = split(SR[s], rr, " "); e = 0; cl = (s in CL); nc = 0; ug = 0; nk = 0; ow = 0; hd = 0
        rp = (K[s] == "feature" && !(s in RP)); np = 0; tk = ""; rc = ""; split("", RCS)
        for (j = 1; j <= n; j++) { r = rr[j]; if (r == "") continue; x = ST[r]
          if (x == "held") { q = "none"; for (k = 1; k <= nqs; k++) if (whole(QS[k], r)) { q = QS[k]; sub(/^- /, "", q); sub(/[ \t].*/, "", q); break }
            out("held", s, r, " reason=" (VH[r] == "" ? "-" : VH[r]) " question=" q); hd++ }
          if (BCS[r] ~ /product/) out("breach", s, r, "")
          if (r in OW) { m = split(OW[r], ob, " "); for (k = 1; k <= m; k++) if (ob[k] != "") { out("owed-hostility", s, r, " by=" ob[k]); ow++ } }
          if (x == "pass") { np++; d = DT[r]; key = "now"; rcp = d
              if (d ~ /^passed at /) { key = d; sub(/^passed at /, "", key); sub(/ \(.*$/, "", key); rcp = d; sub(/^.*\(/, "", rcp); sub(/\)$/, "", rcp); if (index(key, ",")) rp = 0 }
              if (tk == "") tk = key; else if (tk != key) rp = 0
              if (!(rcp in RCS)) { RCS[rcp] = 1; rc = rc (rc == "" ? "" : ",") rcp } }
          else if (x != "owed" && x != "deploy-owed" && x != "held" && x != "later") rp = 0
          if (x == "owed" || x == "deploy-owed" || x == "held" || x == "later") continue
          e++
          if (!(s in ALL) && !((s, r) in COV)) { out("not-closed", s, r, ""); nc++ }
          g = (VL[r] != "" && VL[r] != "NONE" && (GN[r] == 0 || GK[r] == GN[r]))
          if (!g) { out("ungraded", s, r, ""); ug++ }
          if (!(VL[r] == "KEPT" && (!(r in DF) || LV[r] > DF[r]))) { out("not-kept", s, r, ""); nk++ } }
        closed = (cl && nc == 0); done = (closed && ug == 0 && nk == 0 && ow == 0 && hd == 0)
        printf "step-state step=%s kind=%s closed=%s graded=%s done=%s eligible=%d close=%s\n", s, (s in K) ? K[s] : "feature", closed ? "yes" : "no", ug ? "no" : "yes", done ? "yes" : "no", e, cl ? CL[s] : "none"
        printf "%s", L[s]
        if (done && !(s in SD)) print "STAMP\t" s > (pd "/stamps")
        if (rp && np > 0) print "RPASS\t" s "\t" tk "\t" rc > (pd "/stamps") }
    }' "$EV"
  _now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  while IFS='	' read -r _k _s _x _y; do
    case "$_k" in
      STAMP) printf 'step-done step=%s at=%s\n' "$_s" "$_now" >> "$EV" ;;
      RPASS) if [ "$_x" = now ]; then _tr=$(git rev-parse --short=12 'HEAD^{tree}' 2>/dev/null); else _tr=$(git rev-parse --short=12 "$_x^{tree}" 2>/dev/null); fi
        [ -n "$_tr" ] && printf 'step-rows-passing step=%s tree=%s receipts=%s at=%s\n' "$_s" "$_tr" "$_y" "$_now" >> "$EV" ;;
    esac
  done < "$TMP93/stamps"
  return 0
}
if [ "${1:-}" = step-state ]; then
  [ -n "${2:-}" ] || { echo 'metrics step-state: <id>[,<id>…] or --all' >&2; exit 2; }
  CH=$(gate_home) || { echo 'metrics step-state: off — not inside a develop run under a 0.9.6 plan (sh checks/plan.sh gate).' >&2; exit 2; }
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || { echo 'metrics step-state: the inventory block does not open with grammar: 0.9.3 — nothing computed' >&2; exit 2; }
  ss_compute "$2" || exit 2
  exit 0
fi
# --- v0.9.8 (3.2, R13): test-state — derived, read-only, never a gate ------------------------------------------------
# Per row (amendment 3: no review column): written (its test field cites a file under tests/), passing
# (checks/evidence.sh, unchanged) and proven (its latest `test-proven result=proven` still current: the test file's
# block for the row — its changed lines touch no line naming the row, nor the lines from the first naming it to the
# line before the next naming another row, the evidence reader's block rule at row grain — and every helper it records
# unchanged, its obligation unchanged, and its authority unchanged since the attestation's commit (checks/brief.sh
# authority --changed); else stale; inconclusive; failed when a later `verdict … class=test proof=` names it).
# Attestation fields: row= result= commit= file= blob= helpers=<path@blob,…|-> obligation=<cksum> authority=<digest>. Completion and done are unchanged: nothing reads this but the progress table.
# ts_block <old blob> <new blob> <row>: exit 0 when the change touches the row's block (a file gone or unreadable: 0)
ts_block() {
  [ "$1" = "$2" ] && return 1
  git cat-file -e "$1" 2>/dev/null && git cat-file -e "$2" 2>/dev/null || return 0
  git diff -U0 "$1" "$2" > "$TMP93/tsd" 2>/dev/null; git cat-file blob "$2" > "$TMP93/tsf" 2>/dev/null
  awk -v r="$3" 'BEGIN { a = r; gsub(/-/, "_", a) }
    function names(s, id,   p, q, o, x, y) { q = s; o = 0; while ((p = index(q, id)) > 0) { x = (o + p > 1) ? substr(s, o + p - 1, 1) : ""; y = substr(s, o + p + length(id), 1)
        if (x !~ /[A-Za-z0-9]/ && y !~ /[0-9A-Za-z]/) return 1; o += p; q = substr(s, o + 1) } return 0 }
    function mine(s) { return names(s, r) || names(s, a) }
    function other(s,   t, m) { t = s; while (match(t, /ROW[-_][0-9]+/)) { m = substr(t, RSTART, RLENGTH); gsub(/_/, "-", m); if (m != r) return 1; t = substr(t, RSTART + RLENGTH) } return 0 }
    FILENAME == ARGV[1] { if (/^@@/) { h = $0; sub(/^@@ -[0-9,]+ \+/, "", h); sub(/ @@.*/, "", h); c = split(h, x, ","); st = x[1] + 0; w = (c > 1) ? x[2] + 0 : 1
          if (w == 0) { CH[st] = 1; CH[st + 1] = 1 } else for (q = st; q < st + w; q++) CH[q] = 1; next }
        if (/^(\+\+\+|---) /) next; if (/^[-+]/ && mine($0)) hit = 1; next }
    { L[FNR] = $0; n = FNR }
    END { if (hit) exit 0; b = 0; for (i = 1; i <= n; i++) if (mine(L[i])) { b = i; break } if (!b) exit 0
      e = n; for (i = b + 1; i <= n; i++) if (!mine(L[i]) && other(L[i])) { e = i - 1; break }
      for (i = b; i <= e; i++) if (i in CH) exit 0; exit 1 }' "$TMP93/tsd" "$TMP93/tsf"
}
if [ "${1:-}" = test-state ]; then
  shift; TSR=''
  while [ $# -gt 0 ]; do case "$1" in --rows) TSR=${2:-}; shift 2 ;; *) echo 'metrics test-state: usage — sh checks/metrics.sh test-state [--rows <ROW-id,…>]' >&2; exit 2 ;; esac; done
  tmp93
  printf '%s\n' "$IBLOCK" | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } tr($1) ~ /^ROW-/ { t = tr($8); sub(/[ \t].*/, "", t); print tr($1) "\t" tr($6) "\t" t }' > "$TMP93/tsrows"
  if [ -n "$TSR" ]; then printf '%s\n' "$TSR" | tr ', ' '\n\n' | grep -v '^$' > "$TMP93/tswant"; awk -F'\t' 'NR == FNR { W[$1] = 1; next } ($1 in W)' "$TMP93/tswant" "$TMP93/tsrows" > "$TMP93/x" && mv "$TMP93/x" "$TMP93/tsrows"; fi
  # the latest attestation of each kind per row, with its order in the events
  { [ -f "$EV" ] && awk 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      $1 == "test-proven" && kv("row") != "" { V[kv("row")] = NR "\t" $0 }
      $1 == "verdict" && kv("proof") != "" && kv("row") != "" { F[kv("row")] = NR }
      END { for (k in V) print "V\t" k "\t" V[k]; for (k in F) print "F\t" k "\t" F[k] }' "$EV"; } > "$TMP93/tsatt" || : > "$TMP93/tsatt"
  # passing: the evidence reader over the plan's map, else the rows with no paths
  if [ -f checks/plan.sh ] && sh checks/plan.sh map --all > "$TMP93/tsmap" 2>/dev/null && [ -s "$TMP93/tsmap" ]; then :; else cut -f1 "$TMP93/tsrows" | awk '{ print $0 "\t-\t" }' > "$TMP93/tsmap"; fi
  : > "$TMP93/tspass"
  if [ -n "${VID_EVIDENCE_STATES:-}" ] && [ -f "${VID_EVIDENCE_STATES:-}" ]; then cp "$VID_EVIDENCE_STATES" "$TMP93/tspass"   # the progress update's own reading at HEAD
  elif [ -f checks/evidence.sh ]; then sh checks/evidence.sh rows --at HEAD --map "$TMP93/tsmap" > "$TMP93/tspass" 2>/dev/null || : > "$TMP93/tspass"; fi
  # each proof to judge: `<kind>\t<row>\t<commit>\t<file>\t<blob>\t<helpers>\t<obligation>`
  awk -F'\t' 'function kv(s, k,   n, a, i) { n = split(s, a, " "); for (i = 2; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }
    $1 == "V" && kv($4, "result") == "proven" { print $1 "\t" $2 "\t" kv($4, "commit") "\t" kv($4, "file") "\t" kv($4, "blob") "\t" kv($4, "helpers") "\t" kv($4, "obligation") }' "$TMP93/tsatt" > "$TMP93/tsjudge"
  : > "$TMP93/tsstale"; : > "$TMP93/tsbase"
  while IFS='	' read -r _k _r _c _f _b _h _o; do
    _why=''
    _ob=$(awk -F'\t' -v r="$_r" '$1 == r { print $2 }' "$TMP93/tsrows" | cksum | cut -d' ' -f1)
    [ "$_ob" = "$_o" ] || _why=obligation
    if [ -z "$_why" ] && [ -n "$_h" ] && [ "$_h" != - ]; then
      for _hp in $(printf '%s\n' "$_h" | tr ',' '\n'); do [ "$(git rev-parse -q --verify "HEAD:${_hp%@*}" 2>/dev/null)" = "${_hp##*@}" ] || { _why="helper ${_hp%@*}"; break; }; done
    fi
    if [ -z "$_why" ]; then _nb=$(git rev-parse -q --verify "HEAD:$_f" 2>/dev/null || echo gone); ts_block "$_b" "$_nb" "$_r" && _why="test $_f"; fi
    if [ -n "$_why" ]; then printf '%s\t%s\t%s\n' "$_k" "$_r" "$_why" >> "$TMP93/tsstale"; else printf '%s\t%s\n' "$_r" "$_c" >> "$TMP93/tsbase.$_k"; fi
  done < "$TMP93/tsjudge"
  # authority, for the rest: one reading per kind (each row against its own attestation's commit)
  for _k in V; do
    [ -s "$TMP93/tsbase.$_k" ] || continue
    sh checks/brief.sh authority --changed --base "$TMP93/tsbase.$_k" 2>/dev/null | sed -n 's/^authority-changed row=\([^ ]*\) .* what=\(.*\)$/\1\t\2/p' | awk -F'\t' -v k="$_k" '{ print k "\t" $1 "\tauthority " $2 }' >> "$TMP93/tsstale"
  done
  awk -F'\t' -v af="$TMP93/tsatt" -v pf="$TMP93/tspass" -v sf="$TMP93/tsstale" '
    function kv(s, k,   n, a, i) { n = split(s, a, " "); for (i = 2; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }
    BEGIN { while ((getline l < af) > 0) { split(l, a, "\t"); if (a[1] == "V") { O[a[1], a[2]] = a[3] + 0; A[a[1], a[2]] = a[4] } else O[a[1], a[2]] = a[3] + 0 }
      while ((getline l < pf) > 0) { split(l, a, "\t"); PS[a[1]] = a[2] }
      while ((getline l < sf) > 0) { split(l, a, "\t"); if (!((a[1], a[2]) in ST)) ST[a[1], a[2]] = a[3] } }
    { r = $1; w = ($3 ~ /^tests\//) ? "yes" : "no"
      if (!(("V", r) in A)) pv = "no"; else { res = kv(A["V", r], "result"); if (res == "proven") pv = (("V", r) in ST) ? "stale" : "yes"; else pv = res }
      if ((("F", r) in O) && (!(("V", r) in O) || O["F", r] > O["V", r])) pv = "failed"
      ps = (r in PS) ? PS[r] : "never"; if (ps == "pass") ps = "yes"
      why = ""; if (("V", r) in ST) why = " proof-stale=\"" ST["V", r] "\""
      printf "test-state row=%s written=%s passing=%s proven=%s%s\n", r, w, ps, pv, why
      n++; if (w == "yes") nw++; if (ps == "yes") np++; if (pv == "yes") nv++ }
    END { printf "test-state rows=%d written=%d passing=%d proven=%d\n", n, nw, np, nv }' "$TMP93/tsrows"
  exit 0
fi
# --- v0.9.8 (3.4, R4): the fault proof, judged and recorded — measured, never a gate on done or completion --------
# `proof --row <id> --brief <grader brief> --fault <patch> --target <case> --control <case> --clean <receipt|none>
# --red <receipt|none>`: the grader named the fault as a patch against the commit its brief quotes (Q); the run manager
# ran, in a proof worktree at Q, a clean baseline and then the faulted run, each a --purpose proof request. A receipt
# named here must be a proof receipt (refused otherwise, nothing recorded). CONCLUSIVE when the baseline's tree is Q's
# and its target and control cases passed, the faulted run's tree is Q's with exactly the patch applied, its control
# passed and its target ran to a verdict: the target failed → `test-proven … result=proven`; the target passed → the
# test is weak: `verdict slice=<the brief's> row= result=BREACHED class=test proof=<the faulted receipt> brief=
# quoted-at=`, routed as any test breach. Anything else is `test-proven … result=inconclusive why=<…>` and no verdict:
# a patch that does not apply at Q (unappliable), no baseline or no faulted receipt (no-baseline, no-fault-run), a
# tree not Q's or not Q plus the patch (baseline-tree, fault-tree), a run of the wrong shape (shape: a journey or
# actor (process) row reads deployed receipts when the harness declares deployed-selector:, every other row inline
# ones), a case absent (missing-case), a baseline case not passed (baseline-failed), the faulted control not passed
# (control-failed) or the target neither failed nor passed (target-<status>). A case is named as its receipt's .cases
# names it, or by its tail after `::`. The record carries the proof's commit, the test file's blob, the obligation and
# the authority digest at Q, so metrics.sh test-state reads it current or stale.
if [ "${1:-}" = proof ]; then
  shift; PRR=''; PRB=''; PRF=''; PRT=''; PRC=''; PRCL=''; PRRD=''
  pusage() { echo 'ViD metrics: usage — sh checks/metrics.sh proof --row <ROW-id> --brief <grader brief> --fault <patch> --target <case> --control <case> --clean <receipt|none> --red <receipt|none>' >&2; exit 2; }
  prefuse() { echo "ViD metrics: proof refused — $* (nothing recorded)" >&2; exit 1; }
  while [ $# -gt 0 ]; do [ $# -ge 2 ] || pusage; case "$1" in --row) PRR=$2 ;; --brief) PRB=$2 ;; --fault) PRF=$2 ;; --target) PRT=$2 ;; --control) PRC=$2 ;; --clean) PRCL=$2 ;; --red) PRRD=$2 ;; *) pusage ;; esac; shift 2; done
  [ -n "$PRR" ] && [ -n "$PRB" ] && [ -n "$PRF" ] && [ -n "$PRT" ] && [ -n "$PRC" ] && [ -n "$PRCL" ] && [ -n "$PRRD" ] || pusage
  [ -f "$PRB" ] || prefuse "no brief $PRB"
  PQ=$(sed -n '1,14s/^quoted-at:[[:space:]]*//p' "$PRB" | head -n 1 | awk '{ print $1 }'); PSL=$(sed -n '1,14s/^.*slice:[[:space:]]*\([^ ]*\).*/\1/p' "$PRB" | head -n 1)
  [ "$(sed -n '1,14s/^role:[[:space:]]*\([a-z-]*\).*/\1/p' "$PRB" | head -n 1)" = grader ] || prefuse "$PRB is no grader brief: the fault is the grader's"
  PQF=$(git rev-parse -q --verify "$PQ^{commit}" 2>/dev/null) || prefuse "the brief's quoted-at $PQ names no commit here"
  [ -f "$PRF" ] || prefuse "no patch $PRF"
  RD=.vid/ledger-results
  for _r in "$PRCL" "$PRRD"; do
    [ "$_r" = none ] && continue
    case "${_r##*/}" in *.proof.*) ;; *) prefuse "${_r##*/} is an ordinary receipt — a proof's runs are --purpose proof requests (checks/test.sh), whose receipts nothing credits" ;; esac
    [ -f "$RD/${_r##*/}" ] && [ -f "$RD/${_r##*/}.tree" ] && [ -f "$RD/${_r##*/}.cases" ] || prefuse "no proof receipt ${_r##*/} here (with its .tree and .cases)"
  done
  tmp93
  PFILE=$(printf '%s\n' "$IBLOCK" | awk -F'|' -v r="$PRR" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r && !f++ { t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t); print t }')
  [ -n "$PFILE" ] || prefuse "no row $PRR in INVENTORY.md"
  pfrec() { # <result> <why>
    _ob=$(git show "$PQ:INVENTORY.md" 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | awk -F'|' -v r="$PRR" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { o = $6; gsub(/^[ \t]+|[ \t]+$/, "", o); print o; exit }' | cksum | cut -d' ' -f1)
    _dg=$( [ -f checks/brief.sh ] && sh checks/brief.sh authority --row "$PRR" --at "$PQ" 2>/dev/null | sed -n 's/^digest //p'); _bl=$(git rev-parse -q --verify "$PQ:$PFILE" 2>/dev/null || echo none)
    printf 'test-proven row=%s result=%s why=%s fault=%s clean=%s red=%s target=%s control=%s commit=%.12s file=%s blob=%s helpers=- obligation=%s authority=%s brief=%s at=%s\n' "$PRR" "$1" "$2" "$PRF" "${PRCL##*/}" "${PRRD##*/}" "$PRT" "$PRC" "$PQF" "$PFILE" "$_bl" "$_ob" "${_dg:-unknown}" "$PRB" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    echo "ViD metrics: test-proven row=$PRR result=$1 why=$2"; exit 0; }
  # the fault applies at Q, and the tree it makes
  GIT_INDEX_FILE=$TMP93/pidx git read-tree "$PQF" 2>/dev/null || prefuse 'the quoted commit could not be read'
  GIT_INDEX_FILE=$TMP93/pidx git apply --cached --check "$PRF" > /dev/null 2>&1 || pfrec inconclusive unappliable
  GIT_INDEX_FILE=$TMP93/pidx git apply --cached "$PRF" > /dev/null 2>&1; PFT=$(GIT_INDEX_FILE=$TMP93/pidx git write-tree)
  [ "$PRCL" != none ] || pfrec inconclusive no-baseline
  [ "$PRRD" != none ] || pfrec inconclusive no-fault-run
  ptk() { sed -n "s/^$1=//p" "$RD/${2##*/}.tree" | head -n 1; }
  # the shape the row's evidence takes
  PKA=$(printf '%s\n' "$IBLOCK" | awk -F'|' -v r="$PRR" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r && !f++ { k = $2; a = $4; gsub(/^[ \t]+|[ \t]+$/, "", k); gsub(/^[ \t]+|[ \t]+$/, "", a); print k " " a }')
  PSH=inline; if [ "${PKA%% *}" = journey ] || [ "${PKA#* }" = '(process)' ]; then ddeclared && PSH=deployed; fi
  for _r in "$PRCL" "$PRRD"; do _s=$(ptk shape "$_r"); [ "${_s:-inline}" = "$PSH" ] || pfrec inconclusive shape; done
  [ "$(ptk base "$PRCL" | cut -c1-12)" = "$(printf '%.12s' "$PQF")" ] && [ "$(ptk tree "$PRCL")" = "$(git rev-parse "$PQF^{tree}")" ] || pfrec inconclusive baseline-tree
  [ "$(ptk base "$PRRD" | cut -c1-12)" = "$(printf '%.12s' "$PQF")" ] && [ "$(ptk tree "$PRRD")" = "$PFT" ] || pfrec inconclusive fault-tree
  pst() { awk -v c="$1" '$1 == "case" { id = $2; t = id; sub(/.*::/, "", t); if (id == c || t == c || (length(id) > length(c) && substr(id, length(id) - length(c) - 1) == "::" c)) { s = $3; f = 1 } } END { print (f ? s : "absent") }' "$RD/${2##*/}.cases"; }
  CT=$(pst "$PRT" "$PRCL"); CC=$(pst "$PRC" "$PRCL"); RT=$(pst "$PRT" "$PRRD"); RC=$(pst "$PRC" "$PRRD")
  for _x in "$CT" "$CC" "$RT" "$RC"; do [ "$_x" = absent ] && pfrec inconclusive missing-case; done
  [ "$CT" = passed ] && [ "$CC" = passed ] || pfrec inconclusive baseline-failed
  [ "$RC" = passed ] || pfrec inconclusive "control-$RC"
  case "$RT" in
    failed) pfrec proven - ;;
    passed) printf 'verdict slice=%s row=%s result=BREACHED class=test proof=%s brief=%s quoted-at=%s at=%s\n' "${PSL:--}" "$PRR" "${PRRD##*/}" "$PRB" "$PQ" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
      echo "ViD metrics: BREACHED class=test row=$PRR proof=${PRRD##*/} — the target passed on the fault: the test is weak; route it as a test breach (vid-verify)"; exit 0 ;;
    *) pfrec inconclusive "target-$RT" ;;
  esac
fi
if [ "${1:-}" = defer ] || [ "${1:-}" = defer-resolved ]; then
  SUB=$1; shift; DK=''; DR=''; DW=''; DFR=''; DB=''
  dusage() { echo 'ViD metrics: usage — sh checks/metrics.sh defer --kind product|test --row <id> --why "<one line>" --from brief:<path>#<row>|receipt:<name> [--by <who>] | defer-resolved --row <id> --by <commit|brief>' >&2; exit 2; }
  dref() { echo "ViD metrics: refused — $*" >&2; exit 1; }
  while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || dusage
    case "$SUB $1" in
      'defer --kind') DK=$2 ;; 'defer --why') DW=$2 ;; 'defer --from') DFR=$2 ;; *' --row') DR=$2 ;; *' --by') DB=$2 ;; *) dusage ;;
    esac; shift 2
  done
  [ -n "$DR" ] || dusage
  CH=$(gate_home) || dref "$SUB runs inside a develop run under a 0.9.6 plan (sh checks/plan.sh gate)."
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || dref 'the inventory block does not open with grammar: 0.9.3.'
  tmp93
  DOPEN=$(awk -v r="$DR" "$AWKAT"' kv("row") == r && $1 == "deferred" { o = NR } kv("row") == r && $1 == "deferred-resolved" { o = 0 } END { print o + 0 }' "$EV" 2>/dev/null || echo 0)
  if [ "$SUB" = defer-resolved ]; then
    [ -n "$DB" ] || dusage
    [ "$DOPEN" -gt 0 ] || dref "$DR has no open deferral."
    if _c=$(git rev-parse -q --verify "$DB^{commit}" 2>/dev/null); then DBY="commit:$(git rev-parse --short=12 "$_c")"
    elif awk -v r="$DR" -v b="$DB" "$AWKAT"' $1 == "verdict" && kv("row") == r && kv("brief") == b { f = 1 } END { exit f ? 0 : 1 }' "$EV"; then DBY="verdict:$DB"
    else dref "--by $DB is neither a commit nor the brief of a verdict on $DR."; fi
    printf 'deferred-resolved row=%s by=%s at=%s\n' "$DR" "$DBY" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    echo "ViD metrics: the deferral of $DR resolved by $DBY — a disposition; a fresh verdict is what makes the row KEPT"
    exit 0
  fi
  [ "$(ss_strat)" = breadth-first ] || dref "deferrals as records are breadth first's (RUN-STATE strategy: breadth-first); under depth first a finding is routed as before."
  case "$DK" in product|test) ;; *) dusage ;; esac
  [ -n "$(printf '%s' "$DW" | tr -d '[:space:]')" ] || dusage
  case "$DW" in *'
'*) dref 'the why is one line.' ;; esac
  case "$DFR" in
    brief:*'#'*) _bp=${DFR#brief:}; _bp=${_bp%%#*}; [ -f "$_bp" ] || dref "--from $DFR: no brief at $_bp" ;;
    receipt:?*) _rn=${DFR#receipt:}; case "$_rn" in */*|.*) dref "--from $DFR: a receipt is named, not pathed" ;; esac; [ -f ".vid/ledger-results/$_rn" ] || dref "--from $DFR: no such receipt" ;;
    *) dref '--from is brief:<path>#<row> or receipt:<name>' ;;
  esac
  sh checks/plan.sh parse > "$TMP93/parsed" 2> "$TMP93/err" || dref "the plan block does not hold: $(head -n 1 "$TMP93/err")"
  DSTP=$(awk -F'\t' -v r="$DR" '$1 == "row" && $2 == r { print $3 }' "$TMP93/parsed")
  [ -n "$DSTP" ] || dref "$DR is in no step of the plan."
  if [ "$(awk -F'\t' -v s="$DSTP" '$1 == "step" && $2 == s { print $7 }' "$TMP93/parsed")" != hardening ]; then
    [ "$DK" = test ] && dref "$DR sits in feature step $DSTP: a test-class breach on a core row goes to a test-author pass at once, never deferred."
    dref "$DR sits in feature step $DSTP: a core row is never deferred — only a row in a hardening step is."
  fi
  ss_prot
  DPR=$(awk -F'\t' -v r="$DR" '$1 == r { printf "%s%s", (n++ ? "," : ""), $2 }' "$TMP93/prot")
  [ -z "$DPR" ] || dref "$DR is protected ($DPR): a protected row is never deferred."
  [ "$DOPEN" -eq 0 ] || dref "$DR is already deferred; resolve that one first (defer-resolved)."
  vstate93
  DBC=$(awk -F'\t' -v r="$DR" '$1 == r { print $14 }' "$TMP93/vstate")
  case "$DK:$DBC" in product:*product*|test:*test*|test:*harness*) ;; *) dref "$DR holds no eligible BREACHED verdict of class $DK (its open breaches: ${DBC:--}): a finding without a verdict goes through grading first, which records it." ;; esac
  W1=$(printf '%s' "$DW" | tr '"' "'")
  printf 'deferred row=%s kind=%s why="%s" from=%s by=%s at=%s\n' "$DR" "$DK" "$W1" "$DFR" "${DB:-develop}" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
  echo "ViD metrics: deferred $DR ($DK, hardening step $DSTP) from $DFR"
  exit 0
fi

# --- v0.9.7.4 (3.9, R10) — the delegated mark -----------------------------------
#   delegated --answer <A-id>   marks an answer ViD wrote under the owner's delegation: `delegated answer=<A-id>
#     at=`. Refused for an id that is not in the PRD's effective answer ledger (every ```vid-prd-answers block,
#     the latest row per id, AMENDED stripped — checks/prd.sh's own rule), for an answer of tier model_proposed
#     (already ViD's), and for an id already marked. The mark says how the answer was made, never when: readers
#     apply it wherever the answer is live. Run at the project's home (PRD.md and .vid/ beside it).
if [ "${1:-}" = delegated ]; then
  [ "${2:-}" = --answer ] && [ -n "${3:-}" ] && [ $# -eq 3 ] || { echo 'ViD metrics: usage — sh checks/metrics.sh delegated --answer <A-id>' >&2; exit 2; }
  DA=$3
  dlref() { echo "ViD metrics: refused — $*" >&2; exit 1; }
  case "$DA" in A-[0-9]*) ;; *) dlref "$DA is not an answer id (A-NNN)." ;; esac
  [ -f PRD.md ] && [ -d .vid ] || dlref 'run at the project'"'"'s home: PRD.md and .vid/ are not here.'
  DT=$(sed -n '/^```vid-prd-answers$/,/^```$/p' PRD.md | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' -v a="$DA" '
    { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); sub(/[ \t]+AMENDED$/, "", id); if (id != a) next; t = $2; gsub(/^[ \t]+|[ \t]+$/, "", t); tier = t; f = 1 }
    END { if (f) print tier }')
  [ -n "$DT" ] || dlref "$DA is not in the PRD's effective answer ledger."
  [ "$DT" != model_proposed ] || dlref "$DA is of tier model_proposed: it is already ViD's, so there is no delegation to mark."
  if [ -f "$EV" ] && awk -v a="$DA" "$AWKAT"' $1 == "delegated" && kv("answer") == a { f = 1 } END { exit f ? 0 : 1 }' "$EV"; then dlref "$DA is already marked delegated."; fi
  printf 'delegated answer=%s at=%s\n' "$DA" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
  echo "ViD metrics: $DA marked delegated (tier $DT)"
  exit 0
fi

# --- v0.9.6.1 (3.8, R8) — checkpoints, run beside the build --------------------
# Only with two or more proved test environments (.vid/budget stacks>=2 and
# testenv=proved): below that no checkpoint is ever due (it would take the
# only slot). BUILT rows are the rows of closed steps, never owed, held or
# `later`; the plan's rows are the rows of its block.
#   checkpoint                        prints `checkpoint due n=<1|2> built=<b>
#     plan=<p>` when one is due and not yet recorded (the default report and
#     the progress update show the same line), else `checkpoint none due
#     built=<b> plan=<p>` (or why there are none). Checkpoint 1 is due once
#     3·b ≥ p; checkpoint 2 once 3·b ≥ 2·p (v0.9.7.0.12 3.7, R7: whatever
#     checkpoint 1 found). Never more than two.
#   checkpoint --population   v0.9.7.0.12 (3.7, R7): the checkpoint's one
#     population, one id a line — the eligible rows of closed steps (BUILT
#     above) and the materialised hostility probes. `checks/test.sh request
#     --type checkpoint` asks for these rows (frozen into the ticket and the
#     receipt's .rows), the caller's selection runs them, and the recording
#     below judges completeness over the receipt's frozen .rows.
#   checkpoint --n <1|2> --to <report>   after `sh checks/test.sh --role
#     checkpoint -- <selection>`: its receipt (kept name or copy
#     <head>.checkpoint.xml, read with its .checkpoint.deployed.xml) must
#     hold every expected case of every built row and every materialised
#     hostility probe — v0.9.7.0.12: of the population frozen into its .rows,
#     when it carries one (spec 3.3's completeness, against the population run
#     before it; a row with none there needs one case) — a missing one prints
#     `not-run row=<id> case=<case id>` and exits 2, recording nothing; a
#     failing case is a result, not a refusal. A REGRESSION is a built row
#     whose previous result under R4 (checks/evidence.sh, as of just before
#     the checkpoint's publication) was a pass and whose result in the
#     checkpoint is not. It writes `checkpoint n=<n> report=<kept name>
#     built=<b> regressions=<k> base=<the commit it tested>` — work committed
#     while it ran is not in it — and prints `regression row=<id>` for each.
#     Refused: a checkpoint that is not due, one already recorded, or a
#     report that is not a published checkpoint receipt. Its results enter
#     the ordinary evidence: a failing row is red, required at the next close
#     (set 4) and blocks, under rule B, the steps building on it.
cp_status() { # → CPN (1|2|'') CPB CPP CPWHY
  CPN=''; CPWHY=''
  _st=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' .vid/budget 2>/dev/null | head -n 1)
  CPB=$(grep -c . "$TMP93/elig" || true); CPP=$(grep -c '^row	' "$TMP93/parsed" || true)
  # v0.9.7.0.10 (R14): proved on this harness, as checks/test.sh admits
  if [ "${_st:-1}" -lt 2 ] || ! { [ -f docker-compose.test.yml ] && grep -qxF "testenv=proved harness=$(cksum < docker-compose.test.yml | cut -d' ' -f1)" .vid/budget 2>/dev/null; }; then CPWHY="fewer than two proved test environments on this harness (.vid/budget stacks=${_st:-1}) — a checkpoint would take the only slot"; return 0; fi
  _c1=$(awk "$AWKAT"' $1 == "checkpoint" && kv("n") == "1" { r = kv("regressions") } END { print r }' "$EV" 2>/dev/null)   # recorded (any count)
  _c2=$(awk "$AWKAT"' $1 == "checkpoint" && kv("n") == "2" { f = 1 } END { print f + 0 }' "$EV" 2>/dev/null)
  if [ -z "$_c1" ]; then
    if [ $((3 * CPB)) -ge "$CPP" ] && [ "$CPP" -gt 0 ]; then CPN=1; else CPWHY='checkpoint 1 is due at one third of the plan'"'"'s rows'; fi
  elif [ "$_c2" -gt 0 ]; then CPWHY='both checkpoints are recorded — never a third'
  elif [ $((3 * CPB)) -ge $((2 * CPP)) ]; then CPN=2
  else CPWHY='checkpoint 2 is due at two thirds of the plan'"'"'s rows'; fi
  return 0
}
cp_line() { # the one line the report, the status and the progress update print, or nothing
  CH2=$(gate_home) || return 0
  ( cd "$CH2" || exit 0; [ "$IG93" = yes ] || exit 0; cl_prepare '' 2>/dev/null || exit 0; cp_status
    [ -n "$CPN" ] && echo "checkpoint due n=$CPN built=$CPB plan=$CPP" ) || true
}
if [ "${1:-}" = checkpoint ]; then
  shift; CPNA=''; TO=''
  CPPOP=no
  while [ $# -gt 0 ]; do case "$1" in --n) CPNA=${2:-}; shift 2 ;; --to) TO=${2:-}; shift 2 ;; --population) CPPOP=yes; shift ;; *) echo "metrics checkpoint: unknown argument $1" >&2; exit 2 ;; esac; done
  CH=$(gate_home) || { echo 'metrics checkpoint: off — not inside a develop run under a 0.9.6 plan.'; exit 0; }
  TOA=''; if [ -n "$TO" ]; then [ -f "$TO" ] || { echo "metrics checkpoint: $TO missing" >&2; exit 2; }; TOA=$(cd "$(dirname "$TO")" && pwd)/${TO##*/}; fi
  cd "$CH" || exit 2
  [ "$IG93" = yes ] || { echo 'metrics checkpoint: the inventory block does not open with grammar: 0.9.3 — nothing computed'; exit 0; }
  cl_prepare '' || exit 2
  if [ "$CPPOP" = yes ]; then { cut -f1 "$TMP93/elig"; cut -f1 "$TMP93/probes"; } | grep -v '^$' | awk '!s[$0]++'; exit 0; fi
  cp_status
  if [ -z "$TO" ] && [ -z "$CPNA" ]; then
    if [ -n "$CPN" ]; then echo "checkpoint due n=$CPN built=$CPB plan=$CPP"; else echo "checkpoint none due built=$CPB plan=$CPP — $CPWHY"; fi
    exit 0
  fi
  case "$CPNA" in 1|2) ;; *) echo 'metrics checkpoint: --n 1|2 and --to <report> record a checkpoint' >&2; exit 2 ;; esac
  [ -n "$TO" ] || { echo 'metrics checkpoint: --to <report> is required' >&2; exit 2; }
  case "$TO" in *.checkpoint.xml) ;; *) echo "metrics checkpoint: refused — $TO is not a checkpoint receipt (<head>.run-<id>.checkpoint.xml or <head>.checkpoint.xml)." >&2; exit 2 ;; esac
  [ "$CPN" = "$CPNA" ] || { echo "metrics checkpoint: refused — checkpoint $CPNA is not due (built=$CPB plan=$CPP${CPWHY:+: $CPWHY})." >&2; exit 2; }
  TOR=$(cl_resolve "$TOA") || { echo "metrics checkpoint: refused — $TO names no valid published receipt." >&2; exit 2; }
  TON=$(printf '%s\n' "$TOR" | cut -f1); TOAT=$(printf '%s\n' "$TOR" | cut -f2); TOT=$(printf '%s\n' "$TOR" | cut -f3); TOB=$(printf '%s\n' "$TOR" | cut -f4)
  timed "$EV" | cut -f3- | awk -v r="$TON" "$AWKAT"' $1 == "ledger-run" && kv("report") == r { k = kv("kind") } END { exit (k == "checkpoint" ? 0 : 1) }' || { echo "metrics checkpoint: refused — $TON was not published as a checkpoint (ledger-run kind=checkpoint)." >&2; exit 2; }
  # v0.9.7.0.12 (3.7, R7): the population the request froze (the receipt's .rows), else today's built rows and probes
  if [ -s ".vid/ledger-results/$TON.rows" ]; then grep -v '^$' ".vid/ledger-results/$TON.rows" | awk '{ print $1 "\tyes" }' > "$TMP93/ids"
  else { cut -f1 "$TMP93/elig"; cut -f1 "$TMP93/probes"; } | awk '{ print $0 "\tyes" }' > "$TMP93/ids"; fi
  POP=$(cl_population "$TON"); PN=$(printf '%s\n' "$POP" | cut -f1); PT=$(printf '%s\n' "$POP" | cut -f2)
  : > "$TMP93/chg"; [ -n "$PT" ] && git diff --no-renames --name-only "$PT" "$TOT" -- > "$TMP93/chg" 2>/dev/null
  RD=.vid/ledger-results; PD=''; [ -n "$PN" ] && PD=$(cl_twin "$PN")
  cl_judge "$TMP93/ids" "${PN:+$RD/$PN}" "${PD:+$RD/$PD}" "$RD/$TON" "$RD/$(cl_twin "$TON")" "$TMP93/chg" checkpoint > "$TMP93/judged"
  if grep -q '^NOTRUN' "$TMP93/judged"; then
    awk -F'\t' '$1 == "NOTRUN" { print "not-run row=" $2 " case=" $3 }' "$TMP93/judged"
    echo "checkpoint refused — its selection left out an expected case of a built row (population: ${PN:-none yet}); nothing recorded"
    exit 2
  fi
  # the previous result under R4: as of just before the checkpoint's publication
  PRE=$(printf '%s\n' "$TOAT" | awk "$AWKAT"' { e = ep($0) - 1; d = int(e / 86400); s = e - d * 86400; z = d + 719468; era = int(z / 146097); doe = z - era * 146097
      yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
      mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); if (m <= 2) y++
      printf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", y, m, dd, int(s / 3600), int((s % 3600) / 60), s % 60 }')
  sh checks/evidence.sh rows --at "$TOB" --map "$TMP93/map" --until "$PRE" > "$TMP93/before" || { echo 'metrics checkpoint: the previous results could not be read.' >&2; exit 2; }
  awk -F'\t' -v jf="$TMP93/judged" 'BEGIN { while ((getline l < jf) > 0) { split(l, a, "\t"); if (a[1] == "PASS") P[a[2]] = 1 } }
    FILENAME == ARGV[1] { B[$1] = $2; next } ($1 in B) && B[$1] == "pass" && !($1 in P) { print "regression row=" $1 }' "$TMP93/before" "$TMP93/ids" > "$TMP93/reg"
  cat "$TMP93/reg"
  NREG=$(grep -c . "$TMP93/reg" || true)
  printf 'checkpoint n=%s report=%s built=%s regressions=%s base=%s at=%s\n' "$CPNA" "$TON" "$CPB" "$NREG" "$TOB" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
  echo "checkpoint n=$CPNA report=$TON built=$CPB regressions=$NREG base=$TOB — it tested $TOB; work committed while it ran is not in it"
  exit 0
fi
# the claim under 0.9.3: the same predicates over the engine's buckets; a held
# row is skipped and named (3.6); the deployed twin of each report is read for
# the deployed population (3.3).
if [ "${1:-}" = claim ] && [ "$IG93" = yes ]; then
  shift; FROM=''; TO=''
  while [ $# -gt 0 ]; do case "$1" in --from) FROM=$2; shift 2 ;; --to) TO=$2; shift 2 ;; *) echo "metrics claim: unknown argument $1" >&2; exit 2 ;; esac; done
  [ -n "$TO" ] || { echo 'metrics claim: --to <report> is required' >&2; exit 2; }
  [ -f "$TO" ] || { echo "metrics claim: $TO missing" >&2; exit 2; }
  case "$TO" in *.proof.*) echo "metrics claim: $TO is a proof receipt — never an ordinary one: it credits and claims nothing (checks/evidence.sh ordinary)" >&2; exit 2 ;; esac   # v0.9.8 (R15)
  case "$TO" in *.live.*) echo "metrics claim: $TO is a .live. report — a claim is computed over export-backed reports" >&2; exit 2 ;; esac
  vstate93
  TOD=''; [ -f "${TO%.full.xml}.deployed.xml" ] && TOD="${TO%.full.xml}.deployed.xml"
  rows93 "$TO" "$TOD" "$TMP93/to"
  : > "$TMP93/from"
  if [ -n "$FROM" ]; then FROMD=''; [ -f "${FROM%.full.xml}.deployed.xml" ] && FROMD="${FROM%.full.xml}.deployed.xml"; rows93 "$FROM" "$FROMD" "$TMP93/from"; fi
  awk -F'\t' -v ff="$TMP93/from" -v hasfrom="${FROM:+yes}" '
    BEGIN { while ((getline l < ff) > 0) { split(l, a, "\t"); fb[a[1]]=a[2] } }
    { id=$1; b=$2; L=$3; H=$5
      if (b!="kept" && b!="unverdicted" && b!="breached") next
      was="red"; if (hasfrom=="yes" && (id in fb) && fb[id]!="red") was="green"
      if (H!="-") { print "held row=" id " reason=" H; nh++; next }
      if (L!="KEPT") { print "claim row=" id " why=" (L=="NONE" ? "unverdicted" : "breached"); n++ }
      else if (was=="red") { print "claim row=" id " why=re-paid"; n++ } }
    END { printf "claim rows=%d held=%d", n+0, nh+0 }' "$TMP93/to"
  echo " from=${FROM:-none} to=$TO"
  exit 0
fi

# --- claim --from <report> --to <report> (v0.9.2 3.6, round 4) ------------------
if [ "${1:-}" = claim ]; then
  shift; FROM=''; TO=''
  while [ $# -gt 0 ]; do case "$1" in --from) FROM=$2; shift 2 ;; --to) TO=$2; shift 2 ;; *) echo "metrics claim: unknown argument $1" >&2; exit 2 ;; esac; done
  [ -n "$TO" ] || { echo 'metrics claim: --to <report> is required' >&2; exit 2; }
  [ -f "$TO" ] || { echo "metrics claim: $TO missing" >&2; exit 2; }
  case "$TO" in *.proof.*) echo "metrics claim: $TO is a proof receipt — never an ordinary one: it credits and claims nothing (checks/evidence.sh ordinary)" >&2; exit 2 ;; esac   # v0.9.8 (R15)
  case "$TO" in *.live.*) echo "metrics claim: $TO is a .live. report — a claim is computed over export-backed reports" >&2; exit 2 ;; esac
  TOC=$(read_report "$TO"); FROMC=''; [ -n "$FROM" ] && FROMC=$(read_report "$FROM")
  N=0
  for m in $(materialised_rows); do
    id=${m%%	*}; rest=${m#*	}; path=${rest%%	*}; der=${rest#*	}
    [ "$(row_green "$TOC" "$id" "$path" "$der")" = green ] || continue
    lv=$(latest_verdict "$id")
    was=red; [ -n "$FROM" ] && was=$(row_green "$FROMC" "$id" "$path" "$der")
    if [ "$lv" != KEPT ]; then
      case "$lv" in NONE) why=unverdicted ;; *) why=breached ;; esac
      echo "claim row=$id why=$why"; N=$((N + 1))
    elif [ "$was" = red ]; then
      echo "claim row=$id why=re-paid"; N=$((N + 1))    # a kept row that was not fully passing at slice start is judged again
    fi
  done
  echo "claim rows=$N from=${FROM:-none} to=$TO"
  exit 0
fi

evgrep() { # events, optionally filtered to --slice
  [ -f "$EV" ] || return 0
  if [ -n "$SLICE" ]; then grep -E "^$1 " "$EV" 2>/dev/null | grep -E "slice=$SLICE( |\$)" || true
  else grep -E "^$1 " "$EV" 2>/dev/null || true; fi
}
evall() { [ -f "$EV" ] && grep -E "^$1 " "$EV" 2>/dev/null || true; }
kv() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1; }

echo '```vid-metrics'

# --- the rows headline (v0.9.2 3.8, R10) — the first line, rows never tests ---
if [ -f INVENTORY.md ] && [ "$IG93" = yes ]; then
  # v0.9.3: the engine's buckets; the receipt by the currency rule (3.10)
  receipt93; vstate93; rows93 "$RECEIPT" "$DREPORT" "$TMP93/table"
  NR=$(printf '%s\n' "$IBLOCK" | grep -cE '^[[:space:]]*ROW-' || true)
  DDESC='deployed: none declared'; ddeclared && DDESC="deployed ${DREPORT:-none — no <S>.deployed.xml beside the receipt}"
  if [ -z "$RECEIPT" ]; then
    HEADSHA=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)
    awk -F'\t' -v nr="$NR" -v hs="$HEADSHA" '{ c[$2]++; if ($2=="red" || $2=="kept" || $2=="unverdicted" || $2=="breached") m++ } END { printf "rows: receipt: none — materialised rows unverified · materialised %d · owed %d · deploy-owed %d (rows %d; no current export-backed full report for HEAD %s — current means every change since it lies under .vid/ — or no results reader)\n", m+0, c["owed"]+0, c["deploy-owed"]+0, nr, hs }' "$TMP93/table"
  else
    awk -F'\t' -v nr="$NR" -v rec="$RECEIPT" -v dd="$DDESC" '{ c[$2]++; if ($5!="-") h++ } END { u=c["unverdicted"]+c["breached"]+c["red"]+c["owed"]; printf "rows: kept %d · unverdicted %d · breached %d · red %d · owed %d · deploy-owed %d (unmet %d; held %d; rows %d; receipt %s; %s)\n", c["kept"]+0, c["unverdicted"]+0, c["breached"]+0, c["red"]+0, c["owed"]+0, c["deploy-owed"]+0, u, h+0, nr, rec, dd }' "$TMP93/table"
  fi
elif [ -f INVENTORY.md ]; then
  NR=$(printf '%s\n' "$IBLOCK" | grep -cE '^[[:space:]]*ROW-' || true)
  NO=$(printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t ~ /^owed:/ && t !~ /^owed: paid by \/vid deploy/) c++ } END { print c+0 }')
  ND=$(printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t ~ /^owed: paid by \/vid deploy/) c++ } END { print c+0 }')
  HEADSHA=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)
  REPORT=".vid/ledger-results/$HEADSHA.full.xml"
  RC=''; [ -f "$REPORT" ] && RC=$(read_report "$REPORT")
  NM=$(materialised_rows | grep -c . || true)
  if [ -z "$RC" ]; then
    echo "rows: receipt: none — materialised rows unverified · materialised $NM · owed $NO · deploy-owed $ND (rows $NR; no export-backed full report for HEAD $HEADSHA, or no results reader)"
  else
    K=0; U=0; B=0; R=0
    for m in $(materialised_rows); do
      id=${m%%	*}; rest=${m#*	}; path=${rest%%	*}; der=${rest#*	}
      if [ "$(row_green "$RC" "$id" "$path" "$der")" = red ]; then R=$((R + 1)); continue; fi
      case "$(latest_verdict "$id")" in KEPT) K=$((K + 1)) ;; BREACHED) B=$((B + 1)) ;; *) U=$((U + 1)) ;; esac
    done
    OTHERR=$((NR - NM - NO - ND)); [ "$OTHERR" -gt 0 ] && R=$((R + OTHERR))   # an unrecognised test field is red, never silent
    echo "rows: kept $K · unverdicted $U · breached $B · red $R · owed $NO · deploy-owed $ND (unmet $((U + B + R + NO)); rows $NR; receipt $REPORT)"
  fi
fi

# --- progress ---------------------------------------------------------------
if [ -f INVENTORY.md ]; then
  BLOCK=$IBLOCK
  NROW=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*ROW-' || true)
  NRULE=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*rule[[:space:]]*\|' || true)
  NSEAM=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*seam[[:space:]]*\|' || true)
  NPROVED=$(printf '%s\n' "$BLOCK" | grep -c 'proved-red:' || true)
  NOWED=$(printf '%s\n' "$BLOCK" | grep -cE '\|[[:space:]]*owed' || true)
  echo "progress rows ROW=$NROW rule=$NRULE seam=$NSEAM proved-red=$NPROVED owed-now=$NOWED  # owed count: uncalibrated — report-only, v0.9 calibrates; no threshold set"
  SO=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*seam.*probe:[[:space:]]*owed' || true)
  SP=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*seam.*probe:[[:space:]]*probed' || true)
  SU=$(printf '%s\n' "$BLOCK" | grep -cE '^[[:space:]]*seam.*probe:[[:space:]]*unreachable-risk' || true)
  echo "progress seam-probes owed=$SO probed=$SP unreachable-risk=$SU  # tripwire: an owed seam blocks its client code (checks/seams.sh)"
  # v0.9.6.1 (3.8): a checkpoint due and not yet run — inside a 0.9.6 develop run only
  if [ "$IG93" = yes ]; then CPL=$(cp_line); [ -n "$CPL" ] && echo "$CPL  # run it beside the build: sh checks/test.sh request --type checkpoint --role orchestrator --why \"checkpoint <n>\" -- <every built row> [--deployed-selection <…>], then sh checks/metrics.sh checkpoint --n <n> --to <its receipt>"; fi
else
  echo 'progress uncounted (no INVENTORY.md)'
fi
PAID=$(evgrep rows-paid)
if [ -n "$PAID" ]; then
  for l in $PAID; do echo "progress slice=$(kv "$l" slice) rows-paid=$(kv "$l" n)"; done
fi
# v0.9.3 (3.8, R7): the slice against modules — `slice-modules slice=N <paths>`
# (RUN-STATE is rewritten; the event is the history) and the seam-table
# changes between `slice-open` and `slice-close` (the slice's commits touching
# ARCHITECTURE.md). Rows are never attributed to modules.
if [ "$IG93" = yes ]; then
  for l in $(evgrep slice-open); do
    sl=$(kv "$l" slice); OS=$(kv "$l" sha)
    CS=$(evall slice-close | grep -E "slice=$sl( |\$)" | tail -n 1 || true); CS=$(kv "$CS" sha)
    MOD=$(evall slice-modules | grep -E "slice=$sl( |\$)" | tail -n 1 | cut -d' ' -f3- | tr ' ' '\n' | grep -v '^at=' | grep -c . || true)   # v0.9.5 3.11: the time is no module
    SC=uncounted
    if [ -n "$OS" ] && git rev-parse -q --verify "$OS^{commit}" >/dev/null 2>&1; then SC=$(git rev-list --count "$OS..${CS:-HEAD}" -- ARCHITECTURE.md 2>/dev/null || echo uncounted); fi
    echo "progress slice=$sl modules n=$MOD seam-changes n=$SC$( [ -z "$CS" ] && echo ' (open)')  # the slice against modules (3.8); a seam change mid-slice is information, never a fault"
  done
fi
OC=$(evgrep owed-close)
if [ -n "$OC" ]; then
  for l in $OC; do echo "progress slice=$(kv "$l" slice) owed-at-close=$(kv "$l" n)  # trajectory: spikes are information, not failures"; done
fi

# --- honesty ----------------------------------------------------------------
VD=$(evgrep verdict)
if [ -n "$VD" ]; then
  for l in $VD; do
    echo "honesty slice=$(kv "$l" slice) verdict claimed=$(kv "$l" claimed) breached=$(kv "$l" breached)  # miss rate: uncalibrated — report-only, v0.9 calibrates; no threshold set"
  done
else
  echo 'honesty verdict uncounted (no verdict events in .vid/metrics-events — develop records these at slice close)'
fi
# per-row verdicts (v0.9.2 3.6): counts per slice, transitions counted apart
PRV=$(evgrep verdict | grep ' row=' || true)
if [ -n "$PRV" ]; then
  for sl in $(printf '%s\n' "$PRV" | tr ' ' '\n' | sed -n 's/^slice=//p' | sort -u); do
    RK=$(printf '%s\n' "$PRV" | grep "slice=$sl " | grep -v 'transition=' | grep -c 'result=KEPT' || true)
    RB=$(printf '%s\n' "$PRV" | grep "slice=$sl " | grep -v 'transition=' | grep -c 'result=BREACHED' || true)
    TK=$(printf '%s\n' "$PRV" | grep "slice=$sl " | grep 'transition=' | grep -c 'result=KEPT' || true)
    TB=$(printf '%s\n' "$PRV" | grep "slice=$sl " | grep 'transition=' | grep -c 'result=BREACHED' || true)
    if [ "$IG93" = yes ]; then
      CLS=$(printf '%s\n' "$PRV" | grep "slice=$sl " | grep 'result=BREACHED' | awk '{ c="product"; for (i=2;i<=NF;i++) if (index($i,"class=")==1) c=substr($i,7); n[c]++ } END { printf "product=%d test=%d harness=%d", n["product"]+0, n["test"]+0, n["harness"]+0 }')
      echo "honesty slice=$sl row-verdicts kept=$RK breached=$RB transition-verdicts kept=$TK breached=$TB classes $CLS  # the latest eligible per row governs; test and harness are the instrument's, never an attempt"
    else
    echo "honesty slice=$sl row-verdicts kept=$RK breached=$RB transition-verdicts kept=$TK breached=$TB  # the latest per row governs; a reverted row is unverdicted until its next KEPT"
    fi
  done
fi
# v0.9.3 (3.1): the trace that a verdict came through the brief format —
# verdicts after the first `slice-open` (legacy events are exempt) whose
# `brief=` has no earlier `brief-check path=<brief> result=ok`.
if [ "$IG93" = yes ] && [ -f "$EV" ]; then
  VWB=$(awk 'function kv(k, i) { for (i=2;i<=NF;i++) if (index($i, k "=")==1) return substr($i, length(k)+2); return "" }
    $1=="slice-open" { armed=1; next }
    $1=="brief-check" && kv("result")=="ok" { ok[kv("path")]=1; next }
    $1=="verdict" && armed && kv("row")!="" { b=kv("brief"); if (b=="" || !(b in ok)) n++ }
    END { print n+0 }' "$EV")
  if [ "$VWB" -gt 0 ]; then echo "honesty FLAG verdicts-without-brief n=$VWB  # 3.1: a verdict whose brief was never checked ok by checks/brief.sh — nothing can see a spawn; this is the trace that the verdict came through the format"; fi
fi
EO=$(evall 'engine-only breach' | grep -c . || true)
[ "$EO" -gt 0 ] && echo "honesty engine-only-breaches n=$EO  # R18: one recorded breach reverts the one-engine scoped-run rule for the project"
RV=$(evgrep re-verdict)
for l in $RV; do
  echo "honesty slice=$(kv "$l" slice) re-verdict round=$(kv "$l" round) breached=$(kv "$l" breached)  # develop law: the breached set must strictly shrink or the loop halts"
done
AT=$(evall attempts)
if [ -n "$AT" ]; then
  A1=$(printf '%s\n' "$AT" | grep -c 'n=1' || true); A2=$(printf '%s\n' "$AT" | grep -c 'n=2' || true)
  echo "honesty attempts-to-KEPT one=$A1 two=$A2  # two attempts revert the row to owed (develop law)"
fi
NREV=$(evall reverted | grep -c . || true)
if [ "$IG93" = yes ]; then
  echo "honesty legacy-reverted=$NREV  # 0.9.2 reversions carried by an upgraded project; 0.9.3 never reverts — a row past the bound is held (3.6)"
else
echo "honesty rows-reverted-to-owed n=$NREV  # the two-attempt bound firing: honest debt, queued for the owner"
fi
# the proof channel per paid row (v0.9.1 3.6): a row born `owed: paid by /vid
# deploy gate N` is paid only by that rung — a sandbox proof of it is the
# tripwire (no test-runner-triggered proof of a schedule's consumption).
PD=$(evall paid)
if [ -n "$PD" ]; then
  NPD=0; NSB=0
  for l in $PD; do
    NPD=$((NPD + 1)); rid=$(kv "$l" row); via=$(kv "$l" via)
    if [ -n "$BLOCK" ] && printf '%s\n' "$BLOCK" | grep -E "^[[:space:]]*$rid[[:space:]]*\|" | grep -qE '\|[[:space:]]*owed: paid by /vid deploy' && [ "$via" != deploy ]; then
      echo "honesty FLAG sandbox-proof row=$rid via=$via  # tripwire (3.6): a deploy-owed row is paid only by /vid deploy's rung"
      NSB=$((NSB + 1))
    fi
  done
  echo "honesty paid rows=$NPD deploy-owed-paid-by-sandbox=$NSB  # counts, never scores"
fi
RG=$(evgrep regressions)
if [ -n "$RG" ]; then
  RGT=0
  for l in $RG; do RGT=$((RGT + $(kv "$l" n))); done
  echo "honesty regressions total=$RGT  # tripwire (F2, calibrated in v0.7): above zero → investigate; enforced in develop"
else
  echo 'honesty regressions uncounted (no regression events recorded)'
fi

# --- evidence ---------------------------------------------------------------
if [ -f checks/census.sh ]; then
  CEN=$(VID_COURT_EVENT=off sh checks/census.sh --report 2>&1 || true)
  SUM=$(printf '%s\n' "$CEN" | grep '^census: ' | tail -n 1 || true)
  if [ -n "$SUM" ]; then
    echo "evidence census ${SUM#census: }  # blocked at every commit by checks/census.sh"
  else
    echo 'evidence census uncounted (census inactive — no rows, no extractors)'
  fi
  # F7 tripwire, new in v0.8: a rule row whose population is exactly one is
  # a hand-list wearing a rule's clothes (v0.7 grade finding #11).
  for l in $(printf '%s\n' "$CEN" | sed -n 's/^census \([A-Za-z0-9_-]*\): \([0-9][0-9]*\) sites.*/\1 \2/p'); do
    rid=${l%% *}; pop=${l#* }
    [ "$pop" -eq 1 ] && echo "evidence FLAG population=1 rule=$rid  # F7 tripwire: one-site denominator — widen the census command or justify the row"
  done
  NVAC=$(printf '%s\n' "$CEN" | grep -c '^VAC ' || true)
  echo "evidence vacuity-reports n=$NVAC  # report-only pending a measured false-positive rate"
  NREND=$(printf '%s\n' "$CEN" | grep -c '^REND ' || true)
  echo "evidence rendered-vs-cited-reports n=$NREND  # §9, report-only pending a measured false-positive rate"
  # v0.9.2 3.9b (R14): every report-only class is adjudicated at the first
  # slice close — promoted, advisory, or deleted, a standalone law commit
  # with an `adjudicated class=<name>` event; unadjudicated past slice 1 flags.
  MAXSL=$(evall verdict | grep ' claimed=' | tr ' ' '\n' | sed -n 's/^slice=//p' | sort -n | tail -n 1 || true)
  if [ "${MAXSL:-0}" -ge 2 ]; then
    for cls in vacuity rendered strength; do
      ls checks/extractors/"$cls".*.sh >/dev/null 2>&1 || continue
      evall adjudicated | grep -q "class=$cls\( \|\$\)" && continue
      echo "evidence FLAG report-only-unadjudicated class=$cls  # tripwire (3.9b): sample 10 reports at the first slice close, then promote, keep advisory, or delete — a standalone law commit"
    done
  fi
else
  echo 'evidence census uncounted (no checks/census.sh)'
fi
if [ -f checks/selftest/run.sh ]; then
  STOUT=$(sh checks/selftest/run.sh 2>&1 || true)
  CONV=$(printf '%s\n' "$STOUT" | grep -oE '[0-9]+/[0-9]+ courts convict' | tail -n 1 || true)
  if [ -n "$CONV" ]; then
    echo "evidence courts-convicting $CONV  # a court failing open is a build failure (checks/selftest)"
  else
    echo 'evidence courts-convicting FAILING — a known-bad fixture passed; fix the court before anything else lands'
  fi
else
  echo 'evidence courts-convicting uncounted (no checks/selftest/run.sh)'
fi
if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  LAWT=0; LAWB=0; ADEL=0
  LAWFILES=$(grep -v '^#' checks/lawfiles 2>/dev/null | grep -v '^[[:space:]]*$' | cut -d' ' -f1 | sort -u || true)
  for c in $(git rev-list HEAD 2>/dev/null); do
    # the root commit is the ratification act itself — exempt from the
    # standalone rule (v0.7 init law), so it is neither law nor bundled.
    git rev-parse -q --verify "$c^" >/dev/null 2>&1 || continue
    FILES=$(git show --pretty=format: --name-only "$c" 2>/dev/null | grep -v '^$' || true)
    [ -n "$FILES" ] || continue
    ISLAW=no
    printf '%s\n' "$FILES" | grep -q '^checks/' && ISLAW=yes
    if [ "$ISLAW" = no ] && [ -n "$LAWFILES" ]; then
      ONLYLAW=yes
      for f in $FILES; do printf '%s\n' "$LAWFILES" | grep -qxF "$f" || { ONLYLAW=no; break; }; done
      [ "$ONLYLAW" = yes ] && ISLAW=yes
    fi
    if [ "$ISLAW" = yes ]; then
      LAWT=$((LAWT + 1))
      if printf '%s\n' "$FILES" | grep -q '^checks/'; then
        NON=$(printf '%s\n' "$FILES" | grep -v '^checks/' | grep -v '^tests/invariants/' || true)
        for f in $NON; do printf '%s\n' "$LAWFILES" | grep -qxF "$f" || { LAWB=$((LAWB + 1)); break; }; done
      fi
    else
      D=$(git show -U0 --pretty=format: "$c" -- tests/invariants/ 2>/dev/null | grep '^-' | grep -v '^---' | grep -cE '\bassert\b|\bexpect\(|def test_|\bit\(|\btest\(' || true)
      ADEL=$((ADEL + ${D:-0}))
    fi
  done
  echo "evidence law-commits total=$LAWT bundled=$LAWB  # bundled law is hook-blocked (§4.1); above zero here means the hook was bypassed"
  echo "evidence assertion-deletions-outside-law-commits n=$ADEL  # tripwire (F4): above zero is evidence decay; hook-blocked"
else
  echo 'evidence law-commits uncounted (not a git repository)'
fi
FA=0
for l in $(evall failif-amendment); do FA=$((FA + $(kv "$l" n))); done
echo "evidence failif-amendments n=$FA  # F9: legitimate, and counted — uncounted amendments are indistinguishable from moving the goalposts"

# --- cost -------------------------------------------------------------------
TK=$(evgrep tokens)
if [ -n "$TK" ]; then
  for sl in $(printf '%s\n' "$TK" | tr ' ' '\n' | sed -n 's/^slice=//p' | sort -un); do
    B=0; V=0; F=0; R=0; RV=0
    for l in $TK; do
      [ "$(kv "$l" slice)" = "$sl" ] || continue
      n=$(kv "$l" n)
      case "$(kv "$l" phase)" in
        build) B=$((B + n)) ;; verdict) V=$((V + n)) ;; fix) F=$((F + n)) ;; re-verdict) R=$((R + n)) ;; review) RV=$((RV + n)) ;;
      esac
    done
    VER=$((V + F + R))
    if [ "$B" -gt 0 ]; then
      RATIO=$(awk "BEGIN{printf \"%.2f\", $VER/$B}")
      echo "cost slice=$sl tokens build=$B verdict=$V fix=$F re-verdict=$R review=$RV verify-overhead=$VER ratio=$RATIO  # a price paid, never a target"
    else
      echo "cost slice=$sl tokens build=$B verdict=$V fix=$F re-verdict=$R review=$RV verify-overhead=$VER"
    fi
  done
else
  echo 'cost tokens uncounted (no token events — develop records tokens by phase per slice; the append doors record phase=review)'
fi
WC=$(evgrep wall-clock)
for l in $WC; do echo "cost slice=$(kv "$l" slice) wall-clock-seconds=$(kv "$l" seconds)"; done
# v0.9.7.0.7 (3.5, R9): each builder's and fixer's cost, as its hand-back recorded it (brief.sh return)
for l in $(evgrep build-cost); do echo "cost $(printf '%s\n' "$l" | sed 's/ at=[^ ]*$//')"; done
LR=$(evall ledger-run | tail -n 1)
[ -n "$LR" ] && echo "cost ledger-run-seconds last=$(kv "$LR" seconds)  # trend: degrades as browser timeouts accumulate"
# v0.9.2 3.6: per-class seconds from the last named report — browser = the
# files the surface and journey rows cite, behavior = the rest, setup = the
# wall clock the cases do not account for.
# v0.9.3 (3.3): the per-class split reads the last `kind=full` run — a
# deployed pass or a scoped run after it is not the ledger's whole cost.
if [ "$IG93" = yes ]; then LR=$(evall ledger-run | grep ' kind=full ' | tail -n 1 || true); fi
LRREP=$(kv "${LR:-}" report)
if [ -n "$LRREP" ] && [ "$LRREP" != none ] && [ -f ".vid/ledger-results/$LRREP" ]; then
  LRC=$(read_report ".vid/ledger-results/$LRREP")
  BFILES=$(printf '%s\n' "$IBLOCK" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { k=$2; gsub(/^[ \t]+|[ \t]+$/,"",k); if (k!="surface" && k!="journey") next; t=$8; gsub(/^[ \t]+|[ \t]+$/,"",t); if (t ~ /^tests\//) { sub(/ .*/,"",t); print t } }' | sort -u)
  SPLIT=$(printf '%s\n' "$LRC" | awk -v bf="$(printf '%s\n' "$BFILES" | tr '\n' ' ')" -v total="$(kv "$LR" seconds)" 'BEGIN { n=split(bf, arr, " "); for (i=1;i<=n;i++) if (arr[i]!="") isb[arr[i]]=1 } { f=$2; sub(/::.*/, "", f); if (f in isb) b+=$4; else h+=$4 } END { u=total-b-h; if (u<0) u=0; printf "browser=%.0f behavior=%.0f setup=%.0f", b, h, u }')
  echo "cost ledger-run seconds=$(kv "$LR" seconds) $SPLIT kind=$(kv "$LR" kind) report=$LRREP  # per-class seconds from the receipt (3.6); a price paid, never a target"
fi
# v0.9.2 3.7 (R16): the full run is paid once at slice close; a second full
# run before the next slice close, with no invalidated or incident event
# between, is the tripwire. v0.9.6.1 (3.1): a selected close (`kind=close`)
# counts as a full run. v0.9.7.0.12 (3.5, R5): a close batch's chunk runs
# (`batch=<id>`) count once, as one close.
if [ -f "$EV" ]; then
  FR=$(awk '
    $1=="ledger-run" { k=""; b=""; for (i=2;i<=NF;i++) { if (index($i,"kind=")==1) k=substr($i,6); else if (index($i,"batch=")==1) b=substr($i,7) } if (k!="full" && k!="close") next
      if (b != "" && b == lastb) next; lastb=b
      if (armed) { print "FLAG after=" last; armed=0 } else { armed=1; last=$0 } ; next }
    $1=="verdict" { for (i=2;i<=NF;i++) if (index($i,"claimed=")==1) armed=0 ; next }
    $1=="invalidated" || $1=="incident" { armed=0 }' "$EV" | grep -c '^FLAG' || true)
  [ "$FR" -gt 0 ] && echo "cost FLAG full-runs-per-pass n=$FR  # tripwire (R16): a second full run or close inside one pass without an invalidated or incident event — scope the run, pay the close once at slice close"
fi

# v0.9.3 (3.13, R7, R17): court seconds per slice and four FLAG lines, the
# one-site pattern; nothing happens but the line. Budgets from .vid/budget
# (numbers only; defaults claims-per-slice=60 wall-hours-per-slice=8
# court-seconds=300 — spec §9.1).
if [ "$IG93" = yes ] && [ -f "$EV" ]; then
  bget() { _v=''; [ -f .vid/budget ] && _v=$(sed -n "s/^$1=\([0-9][0-9]*\).*/\1/p" .vid/budget | head -n 1); echo "${_v:-$2}"; }
  BCL=$(bget claims-per-slice 60); BWH=$(bget wall-hours-per-slice 8); BCS=$(bget court-seconds 300)
  awk -v want="$SLICE" 'function kv(k, i) { for (i=2;i<=NF;i++) if (index($i, k "=")==1) return substr($i, length(k)+2); return "" }
    $1=="slice-open" { cur=kv("slice"); next } $1=="slice-close" { cur=""; next }
    $1=="court" { s=(cur=="" ? "-" : cur); if (!(s in tot)) ord[++n]=s; tot[s]+=kv("seconds"); per[s]=per[s] " " kv("name") "=" kv("seconds") }
    END { for (i=1;i<=n;i++) { s=ord[i]; if (want!="" && s!=want) continue; printf "cost slice=%s courts seconds=%d%s  # court runtime, measured before it is budgeted (3.13)\n", s, tot[s], per[s] } }' "$EV"
  awk -v b="$BCS" 'function kv(k, i) { for (i=2;i<=NF;i++) if (index($i, k "=")==1) return substr($i, length(k)+2); return "" }
    $1=="court" && kv("seconds")+0 > b+0 { printf "cost FLAG court-over-budget court=%s seconds=%s budget=%s  # tripwire (3.13): the incremental census is a candidate only after this number exists\n", kv("name"), kv("seconds"), b }' "$EV"
  # v0.9.6 (3.5): under a 0.9.6 develop run rule A (checks/plan.sh) replaces this FLAG
  CPS=on; if [ -f checks/plan.sh ] && sh checks/plan.sh gate >/dev/null 2>&1; then CPS=off; fi
  for l in $(evgrep verdict | grep ' claimed=' || true); do
    [ "$CPS" = on ] || break
    c=$(kv "$l" claimed); [ -n "$c" ] && [ "$c" -gt "$BCL" ] && echo "cost FLAG claims-per-slice slice=$(kv "$l" slice) n=$c budget=$BCL  # tripwire (3.13): a line, never a stop" || true
  done
  for l in $(evgrep wall-clock); do
    w=$(kv "$l" seconds); if [ -n "$w" ] && [ "$w" -gt $((BWH * 3600)) ]; then t=$((w * 10 / 3600)); echo "cost FLAG wall-per-slice slice=$(kv "$l" slice) hours=$((t / 10)).$((t % 10)) budget=$BWH  # tripwire (3.13): a line, never a stop"; fi
  done
  for l in $(evall stall); do
    echo "cost FLAG pass-over-envelope op=$(kv "$l" op) elapsed=$(kv "$l" elapsed) envelope=$(kv "$l" envelope)  # tripwire (3.13): a session-written stall; the observer writes none"
  done
fi
# v0.9.5 (3.7, R7): the hook per slice, from .vid/hook-times lines timed inside
# the slice's window — attempts, total and median seconds, the five costliest
# courts by total. Information only; the next run's target is §1's.
if [ -f .vid/hook-times ] && [ -f "$EV" ]; then
  { timed "$EV" | cut -f3- | grep -E '^slice-(open|close) '; printf '\001HOOK\n'; timed .vid/hook-times | cut -f3-; } | awk -v want="$SLICE" "$AWKAT"'
    $0 == "\001HOOK" { hook = 1; next }
    !hook && $1 == "slice-open" { s = kv("slice"); if (!(s in SO)) ORD[++ns] = s; SO[s] = ep(lastat()); next }
    !hook && $1 == "slice-close" { SC[kv("slice")] = ep(lastat()); next }
    hook { nh++; HE[nh] = ep(lastat()); HT[nh] = kv("seconds") + 0
      for (i = 3; i <= NF; i++) { f = $i; k = index(f, "="); if (k == 0) continue; nm = substr(f, 1, k - 1); v = substr(f, k + 1); if (nm == "at" || nm == "seconds" || nm == "result") continue
        if (v ~ /^[0-9]+$/) { HC[nh, nm] = v + 0; CN[nm] = 1 } } }
    END {
      for (i = 1; i <= ns; i++) { s = ORD[i]; if (want != "" && s != want) continue; lo = SO[s]; hi = (s in SC) ? SC[s] : 9999999999
        m = 0; tot = 0; split("", V); split("", CT)
        for (k = 1; k <= nh; k++) if (HE[k] >= lo && HE[k] <= hi) { V[++m] = HT[k]; tot += HT[k]; for (c in CN) if ((k, c) in HC) CT[c] += HC[k, c] }
        if (m == 0) continue
        for (a = 1; a <= m; a++) for (b = a + 1; b <= m; b++) if (V[b] < V[a]) { t = V[a]; V[a] = V[b]; V[b] = t }
        med = (m % 2) ? V[(m + 1) / 2] : (V[m / 2] + V[m / 2 + 1]) / 2
        top = ""; for (r = 1; r <= 5; r++) { best = ""; for (c in CT) if (!(c in USED) && (best == "" || CT[c] > CT[best])) best = c; if (best == "") break; USED[best] = 1; top = top " " best "=" CT[best] } split("", USED)
        printf "cost slice=%s hook attempts=%d seconds=%d median=%s costliest%s  # 3.7: the hook, measured before its courts are rewritten\n", s, m, tot, med, top }
    }'
fi

# --- friction ---------------------------------------------------------------
NI=$(evgrep incident | grep -c . || true)
ND=$(evgrep agent-death | grep -c . || true)
NS=$(evall stall | grep -c . || true)
echo "friction incidents=$NI agent-deaths=$ND stalls-detected=$NS  # stalls observed mechanically by checks/watchdog.sh (F12)"
# v0.9.5 (3.1, R1): the gated-work tripwire — a `paid` event or a KEPT verdict
# for a row a question gates, timed inside that question's open window (its
# `question n=<n> state=asked gates=<ROW-ids and paths, comma-separated, or
# all>` and `question n=<n> state=answered` events). Information, never a
# refusal.
if [ -f "$EV" ]; then
  timed "$EV" | cut -f3- | awk "$AWKAT"'
    $1 == "question" { n = kv("n"); st = kv("state"); a = lastat()
      if (st == "asked") { w++; WN[w] = n; WA[w] = a; WE[w] = ""; WG[w] = "," kv("gates") "," ; OPENW[n] = w }
      else if (st == "answered" && (n in OPENW)) { WE[OPENW[n]] = a; delete OPENW[n] }
      next }
    ($1 == "paid" || ($1 == "verdict" && kv("result") == "KEPT")) && kv("row") != "" { r = kv("row"); a = lastat()
      for (k = 1; k <= w; k++) if (a >= WA[k] && (WE[k] == "" || a <= WE[k]) && (index(WG[k], "," r ",") || WG[k] == ",all,") && !((WN[k], r) in seen)) {
        seen[WN[k], r] = 1; printf "question FLAG gated-work q=%s row=%s  # 3.1: work a question gates was paid or kept while the question was open — information, never a refusal\n", WN[k], r } }'
fi
# v0.9.5 (3.12, R12): the slice summary's tripwires, over every slice whose
# `slice-close` carries a time (an upgraded project's earlier slices are
# exempt): a slice with no `## <UTC> — slice <N>` section in .vid/SUMMARY.md;
# "Went back: nothing" beside a `regressions slice=N n>0` event; a DECISIONS.md
# D-NNN or a model_proposed PRD answer added between the slice's open and close
# commits and not named under "Decided for you". v0.9.7.3 (3.9, R9): only a
# D-id absent from DECISIONS.md at the slice's open commit — a relabelled or
# otherwise changed line raises no flag.
if [ -f "$EV" ]; then
  for l in $(awk "$AWKAT"' $1 == "slice-open" { o[kv("slice")] = kv("sha") } $1 == "slice-close" && lastat() != "" { s = kv("slice"); print s "\t" o[s] "\t" kv("sha") }' "$EV"); do
    sl=${l%%	*}; rest=${l#*	}; so=${rest%%	*}; sc=${rest#*	}
    SEC=$( [ -f .vid/SUMMARY.md ] && awk -v s="$sl" '$0 ~ "^## .* — slice " s "$" { on = 1; print; next } on && /^## / { exit } on' .vid/SUMMARY.md || true)
    if [ -z "$SEC" ]; then echo "summary FLAG missing slice=$sl  # 3.12: no section in .vid/SUMMARY.md for this closed slice"; continue; fi
    RG=$(evall regressions | grep -E "slice=$sl( |\$)" | tr ' ' '\n' | sed -n 's/^n=//p' | awk '{ t += $1 } END { print t + 0 }')
    if [ "$RG" -gt 0 ] && printf '%s\n' "$SEC" | grep -iE 'Went back:' | sed 's/.*[Ww]ent back:[*]*//' | grep -qiE '^[[:space:]]*nothing[.[:space:]]*$'; then
      echo "summary FLAG went-back slice=$sl  # 3.12: \"Went back: nothing\" beside $RG regression(s)"
    fi
    DEC=$(printf '%s\n' "$SEC" | awk '/Decided for you:/ { on = 1 } on')
    if [ -n "$so" ] && [ -n "$sc" ] && git rev-parse -q --verify "$so^{commit}" >/dev/null 2>&1 && git rev-parse -q --verify "$sc^{commit}" >/dev/null 2>&1; then
      OLDD=$(git show "$so:DECISIONS.md" 2>/dev/null | grep -oE '^- \*\*D-[0-9]+' | grep -oE 'D-[0-9]+' || true)
      IDS=$( { git diff "$so" "$sc" -- DECISIONS.md 2>/dev/null | grep -E '^\+- \*\*D-[0-9]+' | grep -oE 'D-[0-9]+' | grep -vxF -e "${OLDD:-no-such-id}" | head -n 999
               git diff "$so" "$sc" -- PRD.md 2>/dev/null | grep '^+' | grep -v '^+++' | grep -E '^\+[[:space:]]*A-[0-9]+([[:space:]]+AMENDED)?[[:space:]]*\|[[:space:]]*model_proposed' | grep -oE 'A-[0-9]+' | head -n 999; } | awk '!s[$0]++')
      for id in $IDS; do
        printf '%s\n' "$DEC" | grep -qE "(^|[^0-9A-Za-z-])$id([^0-9]|\$)" || echo "summary FLAG undisclosed slice=$sl id=$id  # 3.12: a decision taken for the owner this slice, not named under \"Decided for you\""
      done
    fi
  done
fi
# v0.9.5 (3.11): a line after the project's first timed line that carries no
# time — its writer skipped checks/event.sh (the last-token rule, above).
if [ -f "$EV" ]; then
  NOAT=$(awk "$AWKAT"' NF == 0 { next } { h = (lastat() != "") } armed && !h { n++ } h { armed = 1 } END { print n + 0 }' "$EV")
  [ "$NOAT" -gt 0 ] && echo "records FLAG no-at n=$NOAT  # 3.11: an event line after the first timed one carries no at= — a writer that skipped checks/event.sh"
fi

echo '```'
exit 0
