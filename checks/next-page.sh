#!/bin/sh
# Purpose: GitHub manual's plan page and to-do log (GM-2 T12). Run at the top of ViD's repository, in GitHub manual only (lib.sh
# manual). It reads nothing from GitHub and writes nothing to it, or to the project's own files: its sources are the call's read
# (.vid/next/read), the read before it (.vid/next/read.prev, kept by next.sh read), the log (.vid/tw/log), the plan block, the
# plan's rows (planner.sh rows --newest, for a step's stage as next.sh reads it), the setup's teams, STAGES.md's stage names and
# the call's `next.sh triggers` lines, in the file the call hands it. It counts nothing the call's lines count: their counts and
# tiers are printed as they stand.
#   write <triggers file>   the page: one self-contained HTML file that opens offline, plan.html in the folder /vid view writes to
#                      (viewer/view.sh: ~/ViD Viewer/<the repository's folder name>/), beside its pages; prints `page <path>`.
#                      In order: what is new since the last call, the to-do list, what is not yet with the team counted by
#                      kind, the triggers by tier, then the plan by team, stage and track. Then the to-do log, appended (below)
#   todo-done <kind> <subject> <move|words> [<words>]   a done line for the to-do; the move runner calls it after each move it
#                      does (`move`); `/vid next done` calls it with the owner's words (`words`), refused unless the to-do is
#                      on the list. Its hash: the move's in .vid/next/moves (the last listing), else the to-do's newest line's
# The to-do log, .vid/next/todo, appended, tab-separated (GM-2 §5): `<at>\t<appeared|done>\t<kind> <subject>\t<hash>\t<move|
# records|words|->\t<words or ->`. The to-dos are the call's critical triggers first (`trigger critical`: kind its what, the hash
# of the trigger line with every count of days left out), then its moves (`move`: kind, subject and hash as the line gives them).
# A to-do is on the list while its newest line is `appeared`: logged so the first call it is raised, and again when its hash
# changes while it is on the list. It is done when the move that handles it is done (todo-done move), when the owner says so
# (todo-done words), or when the call's lines no longer raise it (`records`, by write, its hash `-`, so any later raising of it
# differs; a to-do done by a move or in words and then no longer raised gets that line too; while a part of the read is unread,
# a to-do no longer raised stays on the list, so a failed read neither drops it nor brings it back as new); a done one comes
# back, `appeared` again, when it is raised with a hash other than its done line's.
# What is new since the last call compares the two reads: each published ticket opened, closed, taken (as next.sh reads taken:
# a `vid: claimed` comment, an assignee or a sub-issue) or given units; each unit closed; each pull request of a ticket, or of
# one of its units, opened or merged; each question (a `Question:` comment head) the read before did not hold; each team change
# whose test the body names now and did not then, or did then and does not now; each important trigger shown (T9 shows one only
# when it is new or changed) but a team change, and each critical one first logged at this call. A ticket a read could not read
# in part is left out of the comparison, and the page says so. With no read before (the first call after the switch), or one
# that failed whole (an `unread round` line and no `ticket` line), it says it has nothing to compare with.
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
die() { echo "ViD next-page: $*" >&2; exit 2; }
ref() { echo "ViD next-page: refused — $*" >&2; exit 1; }
RD=.vid/next/read; PRV=.vid/next/read.prev; TODO=.vid/next/todo; LOG=.vid/tw/log
# clean <words>: the owner's words on one line, a tab or a newline one space, a " written ' (GM-2 §5)
clean() { printf '%s' "$1" | tr '\t\n\r' '   ' | tr '"' "'"; }

todo_done() {
  U='usage — sh checks/next-page.sh todo-done <kind> <subject> <move|words> [<words>]'; [ $# -ge 3 ] || die "$U"
  K=$1; shift; S=''; H=''
  while [ $# -gt 0 ]; do case $1 in move|words) H=$1; shift; break ;; esac; S="${S:+$S }$1"; shift; done
  [ -n "$H" ] && [ -n "$S" ] && [ $# -le 1 ] || die "$U"
  WD=$(clean "${1:-}"); [ -n "$WD" ] || WD=-
  [ "$H" = move ] || [ "$WD" != - ] || ref "a to-do done in words needs the owner's words"
  KEY="$K $S"
  LAST=$(awk -F'\t' -v k="$KEY" '$3 == k { l = $2 "\t" $4 } END { print l }' "$TODO" 2>/dev/null || true)
  [ "$H" = move ] || [ "${LAST%%"$TAB"*}" = appeared ] || ref "\"$KEY\" is no to-do on the list (.vid/next/todo)"
  HS=$(awk -F'\t' -v k="$K" -v s="$S" '$1 == k && $2 == s { h = $3 } END { print h }' .vid/next/moves 2>/dev/null || true)
  [ -n "$HS" ] || { [ -z "$LAST" ] || HS=${LAST#*"$TAB"}; }; [ -n "$HS" ] || HS=-
  mkdir -p .vid/next; printf '%s\tdone\t%s\t%s\t%s\t%s\n' "$(now)" "$KEY" "$HS" "$H" "$WD" >> "$TODO"
  echo "todo done $KEY"; }

# inputs: every source as tagged lines into $T/f, read by the one awk program below
inputs() {
  : > "$T/f"
  awk -F'\t' '!/^#/ { print "RW\t" $1 "\t" $5 "\t" $6 }' "$T/rows" >> "$T/f"
  sed 's/^/X	/' "$1" >> "$T/f"
  [ ! -f "$RD" ] || sed 's/^/C	/' "$RD" >> "$T/f"
  if [ -f "$PRV" ]; then echo PREV >> "$T/f"; sed 's/^/P	/' "$PRV" >> "$T/f"; fi
  { cat "$LOG" 2>/dev/null || true; } | awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "withdrawn" { W[$2] = 1 } ($1 == "published" || $1 == "amended") && $2 ~ /^[0-9]+$/ { if (!($2 in S)) O[++n] = $2; S[$2] = kv("step"); r = kv("rows"); gsub(/,/, " ", r); R[$2] = (r == "-" ? "" : r) }
    END { for (i = 1; i <= n; i++) if (!(O[i] in W)) print "PUB\t" O[i] "\t" (S[O[i]] == "" ? "-" : S[O[i]]) "\t" R[O[i]] }' >> "$T/f"
  plan_block | awk -F'|' "$RNG"' function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^[ \t]*step[ \t]/ { id = tr($1); sub(/^step[ \t]+/, "", id); ln = "-"; rw = ""; nm = ""
      for (i = 2; i <= NF; i++) { x = tr($i); if (x ~ /^lane:/) ln = tr(substr(x, 6)); else if (x ~ /^rows:/) rw = substr(x, 6); else if (x ~ /^name:/) nm = tr(substr(x, 6)) }
      gsub(/[ \t,]+/, " ", rw); m = split(rw, t, " "); r = ""; for (j = 1; j <= m; j++) if (t[j] != "") r = r " " rng(t[j])
      print "ST\t" id "\t" (ln == "" ? "-" : ln) "\t" nm "\t" substr(r, 2) }' >> "$T/f"
  # the setup's teams, as next.sh's teams_ reads them: none, devagent of one
  { cat .vid/tw/settings 2>/dev/null || true; } | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^team:/ { l = tr(substr($0, 6)); n = split(l, a, "|"); for (i = 1; i <= n; i++) a[i] = tr(a[i])
      if (n == 4 && a[1] ~ /^[a-z][a-z0-9]*$/ && a[4] ~ /^[1-9][0-9]*$/ && !(a[1] in s)) { s[a[1]] = 1; print "TEAM\t" a[1] "\t" a[4] "\t" a[2]; k++ } }
    END { if (!k) print "TEAM\tdevagent\t1\t-" }' >> "$T/f"
  { awk '/^```vid-stages/ { b = 1; next } b && /^```/ { exit } b' STAGES.md 2>/dev/null || true; } |
    awk -F'|' '$1 ~ /^STAGE-[0-9]+[ \t]*$/ { s = $1; sub(/^STAGE-/, "", s); gsub(/[ \t]/, "", s); n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print "SN\t" (s + 0) "\t" n }' >> "$T/f"
  [ ! -f "$TODO" ] || sed 's/^/TD	/' "$TODO" >> "$T/f"
  # each critical trigger's to-do hash: its line with every count of days left out (T9's change)
  awk -F'\t' '$1 == "trigger" && $2 == "critical" { print $3 " " $4 "\t" $0 }' "$1" | while IFS="$TAB" read -r k l; do
    printf 'TH\t%s\t%s\n' "$k" "$(printf '%s\n' "$l" | sed -E 's/[0-9]+ days?//g' | git hash-object --stdin)"; done >> "$T/f"
  for r in "$RD" "$PRV"; do [ ! -f "$r" ] || awk -F'\t' '$1 == "ticket" { print $2 "\t" $5 }' "$r"; done | sort -u | while IFS="$TAB" read -r n c; do
    printf 'TE\t%s\t%s\n' "$n" "$(epoch "$c")"; done >> "$T/f"
  printf 'CFG\trepo\t%s\nCFG\tpx\t%s\nCFG\tnow\t%s\nCFG\tnowt\t%s\nCFG\tapplied\t%s\nCFG\ttitle\t%s\n' "$(skey repo)" "$(skey labels-prefix)" "$(date -u +%s)" "$(now)" "$(applied | cut -c1-12)" "$TITLE" >> "$T/f"; }

write() {
  [ -f "$1" ] || ref "no triggers file at $1"
  P=$(pwd -P); NAME=$(basename "$P"); OUT="$HOME/ViD Viewer/$NAME"
  case "$OUT/" in "$P/"*) ref "the viewer's folder $OUT is inside the project; nothing is written there" ;; esac
  mkdir -p "$OUT" .vid/next || ref "cannot write $OUT"
  TITLE=$({ git show HEAD:PRD.md 2>/dev/null || cat PRD.md 2>/dev/null || true; } | sed -n '1s/^# //p' | sed 's/[[:space:]]*—[[:space:]]*PRD[[:space:]]*$//')
  [ -n "$TITLE" ] || TITLE=$NAME
  mustread "$T/rows" planner rows --newest
  inputs "$1"
  awk -F'\t' -v TL="$T/tl" -v PG="$T/page" '
    function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); gsub(/"/, "\\&quot;", s); gsub(/\047/, "\\&#39;", s); return s }
    function num(s) { return s ~ /^[0-9]+$/ }
    function add(a, x) { return a == "" ? x : a ", " x }
    function pl_(n, w) { return n " " w (n == 1 ? "" : "s") }
    function iss(n) { return (REPO == "" ? "#" n : "<a href=\"https://github.com/" REPO "/issues/" n "\">#" n "</a>") }
    function pr(n) { return (REPO == "" ? "#" n : "<a href=\"https://github.com/" REPO "/pull/" n "\">#" n "</a>") }
    function o(s) { print s > PG }
    function gs(s) { return G[s] == "" ? "?" : G[s] }
    # stg <rows>: the stage most of the rows of class planned, moved or owed are in, the earliest on a tie (next.sh, the planner)
    function stg(l,   m, A, j, x, N, b) { m = split(l, A, " "); split("", N); b = ""
      for (j = 1; j <= m; j++) { x = A[j]; if (RC[x] ~ /^(planned|moved|owed)$/ && num(RG[x])) N[RG[x]]++ }
      for (x in N) if (b == "" || N[x] > N[b] || (N[x] == N[b] && x + 0 < b + 0)) b = x; return b }
    # tk <read> <n>: the published ticket n names: n itself, or the ticket whose unit it is
    function tk(r, n) { return (n in ISPUB) ? n : ((r, n) in C2T) ? C2T[r, n] : (("C", n) in C2T) ? C2T["C", n] : (("P", n) in C2T) ? C2T["P", n] : "" }
    function taken(r, n) { return index("\001" IH[r, n] "\001", "\001vid: claimed") || (TA[r, n] != "" && TA[r, n] != "-") || UT[r, n] + 0 > 0 }
    function names(r, n, id,   i, m, w, j) { for (i = 1; i <= NB[r, n]; i++) { m = split(BL[r, n, i], w, /[^A-Za-z0-9_-]+/); for (j = 1; j <= m; j++) if (w[j] == id) return 1 } return 0 }
    function nw(k, t) { NEW[++nn] = k SUBSEP t }
    function tests(l,   m, a) { m = split(l, a, " "); return m ? "<details><summary>" m "</summary>" esc(l) "</details>" : "none" }
    # card <step> <ticket or "">: one step, not issued, or one ticket of it
    function card(s, n,   cls, ch, f, u, cl, j, c, pl, p, ws, m, wa, d, lab, tkn, bl, qa) {
      if (n == "") { ws = ""; m = split(WN["publish", s], wa, "\001"); for (j = 2; j <= m; j++) ws = ws "<div>" esc(wa[j]) "</div>"
        o("<article class=\"card not-issued\" data-step=\"" esc(s) "\" data-state=\"not-issued\"><div class=\"id\"><span class=\"muted\">Not issued</span><span class=\"step\">" esc(s) " · lane " esc(SL[s]) "</span></div><h3>" esc(SNM[s]) "</h3><div class=\"chips\">" ((s in PM) ? "<span class=\"chip\">Publishable</span>" : "<span class=\"chip\">Not listed to publish</span>") "</div><dl class=\"facts\"><dt>Tests</dt><dd>" tests(SR[s]) "</dd></dl>" (ws == "" ? "" : "<div class=\"warns\">" ws "</div>") "</article>")
        return }
      if (!HAS["C", n]) { o("<article class=\"card\" data-step=\"" esc(s) "\" data-ticket=\"" n "\" data-state=\"unread\"><div class=\"id\">" iss(n) "<span class=\"step\">" esc(s) "</span></div><h3>" esc(SNM[s] == "" ? "ticket #" n : SNM[s]) "</h3><div class=\"chips\"><span class=\"chip warn\">Not read at this call</span></div></article>"); return }
      tkn = taken("C", n); bl = index(IL["C", n], "," PX "blocked,") > 0
      cls = (bl ? "attn" : TST["C", n] == "CLOSED" ? "closed" : "open") (tkn ? " taken" : "")
      lab = (TST["C", n] == "CLOSED" ? "Closed" : "Open") " · " (tkn ? "taken" : "not taken")
      ch = "<span class=\"chip " (TST["C", n] == "CLOSED" ? "ok" : "acc") "\">" lab "</span>" (bl ? "<span class=\"chip crit\">Blocked</span>" : "")
      c = 0; for (j = 1; j <= nqi; j++) { split(QI[j], qa, SUBSEP); if (tk("C", qa[1]) == n) c++ } if (c) ch = ch "<span class=\"chip warn\">" pl_(c, "open question") "</span>"
      if (TCN[n]) ch = ch "<span class=\"chip warn\">" pl_(TCN[n], "team change") " waiting</span>"
      u = UT["C", n] + 0; cl = 0; for (j = 1; j <= u; j++) if (SS["C", n, SK["C", n, j]] == "CLOSED") cl++
      pl = ""; for (j = 1; j <= NOP["C"]; j++) { p = OPO["C", j]; if (tk("C", OP["C", p]) == n) pl = add(pl, pr(p)) }
      d = (TE[n] + 0 > 0 && NOW + 0 > 0) ? int((NOW - TE[n]) / 86400) : ""
      f = "<dt>Tests</dt><dd>" tests(TR[n]) "</dd><dt>Pull requests</dt><dd>" (pl == "" ? "none open" : pl) "</dd><dt>Issued</dt><dd>" esc(substr(TCR["C", n], 1, 10)) (d == "" ? "" : " · " pl_(d, "day")) "</dd>"
      o("<article class=\"card " cls "\" data-step=\"" esc(s) "\" data-ticket=\"" n "\" data-state=\"" tolower(TST["C", n]) "\" data-taken=\"" (tkn ? "yes" : "no") "\" data-units=\"" cl "/" u "\"><div class=\"id\">" iss(n) "<span class=\"step\">" esc(s) ((s in INPLAN) ? " · lane " esc(SL[s]) : "") "</span></div><h3>" esc(SNM[s] == "" ? "ticket #" n : SNM[s]) "</h3><div class=\"chips\">" ch "</div>" \
        (u ? "<div class=\"units\"><div class=\"lbl\"><span>Units</span><span>" cl " of " u " closed</span></div><div class=\"bar\"><span style=\"width:" int(cl * 100 / u) "%\"></span></div></div>" : "") "<dl class=\"facts\">" f "</dl></article>") }
    $1 == "RW" { RG[$2] = $3; RC[$2] = $4; next }
    $1 == "PREV" { PREV = 1; next }
    $1 == "CFG" { if ($2 == "repo") REPO = $3; else if ($2 == "px") PX = $3; else if ($2 == "now") NOW = $3; else if ($2 == "nowt") NOWT = $3; else if ($2 == "applied") APL = $3; else TITLE = $3; next }
    $1 == "PUB" { TO[++nt] = $2; TS_[$2] = $3; TR[$2] = $4; ISPUB[$2] = 1; if ($3 != "-") STK[$3] = STK[$3] " " $2; next }
    $1 == "ST" { SO[++ns] = $2; SL[$2] = $3; SNM[$2] = $4; SR[$2] = $5; INPLAN[$2] = 1; next }
    $1 == "TEAM" { TM[++nm] = $2; TAR[$2] = $4; NL[$2] = $3; for (i = 1; i <= $3; i++) { l = ($3 == 1 ? $2 : $2 "-" i); LT[l] = $2; LS[$2, i] = l } nlan += $3; next }
    $1 == "SN" { SNAME[$2] = $3; next }
    $1 == "TD" { k = $4; if ($3 == "appeared" && (!(k in LST) || LST[k] == "done")) FIRST[k] = $2; LST[k] = $3; LH[k] = $5; next }
    $1 == "TH" { THS[$2] = $3; next }
    $1 == "TE" { TE[$2] = $3; next }
    $1 == "X" { t = $2
      if (t == "count") { if (!($3 in CNT)) CK[++ncnt] = $3; CNT[$3] = $4 }
      else if (t == "unread") { UNX[++nux] = $3 " " $4 ": " $5 }
      else if (t == "trigger") TRG[++ntr] = $3 SUBSEP $4 SUBSEP $5 SUBSEP $6
      else if (t == "tiers") { HASTIERS = 1; for (i = 3; i <= NF; i++) { split($i, kv, "="); TIER[kv[1]] = kv[2]; TIO[++nti] = kv[1] } }
      else if (t == "question") { h = substr($0, length($1 $2 $3) + 4); QT[$3] = h; q = $3; sub(/^#/, "", q); sub(/:.*/, "", q); QI[++nqi] = q SUBSEP $3 SUBSEP h }
      else if (t == "move") { MV[++nmv] = $3 SUBSEP $4 SUBSEP $5 SUBSEP $6; if ($3 == "publish") PM[$4] = 1
        if ($3 == "team-change") { s = $4; sub(/^#/, "", s); split(s, a, " "); TCN[a[1]]++; TCI[++ntc] = a[1] SUBSEP a[2] SUBSEP $4 } }
      else if (t == "warning") WN[$3, $4] = WN[$3, $4] "\001" $6
      next }
    $1 == "C" || $1 == "P" { r = $1; t = $2
      if (t == "ticket") { HAS[r, $3] = 1; if (r == "P") PT = 1; TST[r, $3] = $4; TA[r, $3] = $5; TCR[r, $3] = $6 }
      else if (t == "body") { NB[r, $3]++; BL[r, $3, NB[r, $3]] = substr($0, length($1 $2 $3) + 4) }
      else if (t == "sub") { if (!((r, $3, $5) in SS)) { UT[r, $3]++; SK[r, $3, UT[r, $3]] = $5 } SS[r, $3, $5] = $6; C2T[r, $5] = $3 }
      else if (t == "issue") { IL[r, $3] = "," $4 ","; IH[r, $3] = $5 }
      else if (t == "open") { OP[r, $3] = $4; OPO[r, ++NOP[r]] = $3; OH[r, $3] = $11 }
      else if (t == "merged") { MG[r, $3] = $4; MGO[r, ++NMG[r]] = $3 }
      else if (t == "unread") { UNL[r, ++NUN[r]] = $3 SUBSEP $4 SUBSEP $5; if ($3 == "round") RB[r] = 1; if (r == "C") ANYU = 1 }
      next }
    END {
      # with exactly one lane, a step naming none is that lane'"'"'s, as the planner reads it
      if (nlan == 1) for (i = 1; i <= ns; i++) if (SL[SO[i]] == "-" || SL[SO[i]] == "") SL[SO[i]] = LS[TM[1], 1]
      if (nux) ANYU = 1
      # a read before that failed whole (an unread round line and no ticket line) is nothing to compare with
      if (PREV && RB["P"] && !PT) { PREV = 0; PFAIL = 1 }
      # a ticket left out of the comparison: a read that holds an unread line naming it or one of its units
      for (r = 1; r <= 2; r++) { x = (r == 1 ? "C" : "P"); for (i = 1; i <= NUN[x]; i++) { split(UNL[x, i], a, SUBSEP); if (a[2] == "-") continue; n = tk(x, a[2]); if (n != "") BAD[n] = 1 } }
      # ---- the to-dos: the critical triggers, then the moves; the log -----------------------------------------------------
      for (i = 1; i <= ntr; i++) { split(TRG[i], a, SUBSEP); if (a[1] != "critical") continue; k = a[2] " " a[3]; if (k in IT) continue
        IT[k] = 1; IO[++ni] = k; IK[k] = "trigger"; IHS[k] = THS[k]; IW[k] = a[2]; IS[k] = a[3]; IE[k] = a[4] }
      for (i = 1; i <= nmv; i++) { split(MV[i], a, SUBSEP); k = a[1] " " a[2]; if (k in IT) continue
        IT[k] = 1; IO[++ni] = k; IK[k] = "move"; IHS[k] = a[3]; IW[k] = a[1]; IS[k] = a[2]; IE[k] = a[4] }
      for (i = 1; i <= ni; i++) { k = IO[i]; h = IHS[k]
        if (!(k in LST) || (LST[k] == "done" && LH[k] != h)) { print NOWT "\tappeared\t" k "\t" h "\t-\t-" > TL; FIRST[k] = NOWT; FRESH[k] = 1; ON[++non] = k }
        else if (LST[k] == "appeared") { if (LH[k] != h) print NOWT "\tappeared\t" k "\t" h "\t-\t-" > TL; ON[++non] = k } }
      # one the lines no longer raise: done by the records, or, with a part of the read unread, kept on the list as it stands
      # (its hash -, so any later raising of it differs and it comes back); one done with a hash, not raised, gets that line too
      for (k in LST) if (!(k in IT) && (LST[k] == "appeared" || LH[k] != "-")) { if (ANYU) { if (LST[k] == "appeared") { ON[++non] = k; IK[k] = "kept" } }
        else { print NOWT "\tdone\t" k "\t-\trecords\t-" > TL; if (LST[k] == "appeared") RDONE[++nrd] = k } }
      # ---- what is new since the last call --------------------------------------------------------------------------------
      if (PREV) {
        for (i = 1; i <= nt; i++) { n = TO[i]; if (!HAS["C", n] || (n in BAD)) continue
          if (!HAS["P", n] || (TST["P", n] == "CLOSED" && TST["C", n] == "OPEN")) nw("opened #" n, iss(n) " opened")
          else if (TST["P", n] == "OPEN" && TST["C", n] == "CLOSED") nw("closed #" n, iss(n) " closed")
          if (!RB["C"] && !RB["P"] && taken("C", n) && !(HAS["P", n] && taken("P", n))) nw("taken #" n, iss(n) " taken by the team")
          g = 0; for (j = 1; j <= UT["C", n]; j++) if (!(("P", n, SK["C", n, j]) in SS)) g++
          if (g) nw("units #" n, iss(n) " given " pl_(g, "unit"))
          for (j = 1; j <= UT["C", n]; j++) { c = SK["C", n, j]; if (SS["C", n, c] == "CLOSED" && SS["P", n, c] != "CLOSED") nw("unit-closed #" c, "unit " iss(c) " of " iss(n) " closed") } }
        if (!RB["C"] && !RB["P"]) {
          for (i = 1; i <= NOP["C"]; i++) { p = OPO["C", i]; n = tk("C", OP["C", p]); if (n == "" || (n in BAD) || (("P", p) in OP) || (("P", p) in MG)) continue; nw("pr-opened #" p, "pull request " pr(p) " opened, for " iss(n)) }
          for (i = 1; i <= NMG["C"]; i++) { p = MGO["C", i]; n = tk("C", MG["C", p]); if (n == "" || (n in BAD) || (("P", p) in MG)) continue; nw("pr-merged #" p, "pull request " pr(p) " merged, for " iss(n)) }
          for (i = 1; i <= nqi; i++) { split(QI[i], a, SUBSEP); q = a[1]; h = a[3]; n = tk("C", q); if (n != "" && (n in BAD)) continue
            if (index("\001" IH["P", q] "\001", "\001" h "\001") || index("\001" OH["P", q] "\001", "\001" h "\001")) continue
            nw("question " a[2], "a question on " iss(q) ": " esc(h)) } }
        for (i = 1; i <= ntc; i++) { split(TCI[i], a, SUBSEP); n = a[1]; if ((n in BAD) || !HAS["C", n] || names("C", n, a[2]) == names("P", n, a[2])) continue
          nw("team-change " a[3], "the team " (names("C", n, a[2]) ? "added " : "dropped ") esc(a[2]) " on " iss(n)) }
        for (i = 1; i <= ntr; i++) { split(TRG[i], a, SUBSEP); k = a[2] " " a[3]
          if ((a[1] == "important" && a[2] !~ /^team-(added|dropped)$/) || (a[1] == "critical" && (k in FRESH))) nw("trigger " k, "trigger, " a[1] ": " esc(k) ", " esc(a[4])) } }
      # ---- the page ---------------------------------------------------------------------------------------------------------
      o("<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">")
      o("<title>" esc(TITLE) ": the plan</title>\n<style>")
      o(":root{--bg:#f5f6f8;--surface:#fff;--fg:#17202b;--muted:#5b6676;--line:#dde2e9;--accent:#2f5fd0;--accent-soft:#e6edfb;--ok:#1f7a4d;--ok-soft:#e3f3ea;--warn:#9a6200;--warn-soft:#fbf0db;--crit:#b42335;--crit-soft:#fbe5e8;--idle:#6b7482;--idle-soft:#eceff3;--taken:#eef3fd;color-scheme:light}")
      o("@media (prefers-color-scheme:dark){:root:not([data-theme=\"light\"]){--bg:#11161d;--surface:#18202a;--fg:#e6ebf2;--muted:#9aa5b4;--line:#2a3542;--accent:#7ea2f2;--accent-soft:#1e2b45;--ok:#5cc794;--ok-soft:#16302a;--warn:#e3b25a;--warn-soft:#33290f;--crit:#f07a8a;--crit-soft:#3a1c23;--idle:#a2abb8;--idle-soft:#232c37;--taken:#1b2638;color-scheme:dark}}")
      o("*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,-apple-system,\"Segoe UI\",sans-serif}")
      o(".wrap{max-width:1240px;margin:0 auto;padding:28px 16px 56px;display:grid;gap:28px}h1,h2,h3{margin:0;line-height:1.25}h1{font-size:1.6rem}h2{font-size:1.15rem}h3{font-size:1rem}")
      o(".mono,.cmd{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:.85em}.muted{color:var(--muted)}a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}")
      o(".meta{display:flex;flex-wrap:wrap;gap:6px 18px;color:var(--muted);font-size:.9rem}.meta b{color:var(--fg);font-weight:500}")
      o(".summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}.panel{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:18px 20px;display:grid;gap:12px;align-content:start;min-width:0}")
      o(".panel h2 .n{font-size:.85rem;color:var(--muted);font-weight:400;margin-left:8px}ul.list{list-style:none;margin:0;padding:0;display:grid;gap:8px}ul.list li{min-width:0;overflow-wrap:anywhere}")
      o(".todo li{padding:10px 12px;border:1px solid var(--line);border-radius:8px}.todo li.crit{border-color:var(--crit);background:var(--crit-soft)}.cmd{display:block;margin-top:4px;color:var(--muted);overflow-wrap:anywhere}")
      o(".warnbox{background:var(--warn-soft);color:var(--warn);border-radius:8px;padding:8px 12px}.counts{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px}.count .v{display:block;font-size:1.6rem;font-weight:600}.count .k{font-size:.82rem;color:var(--muted)}")
      o(".chips{display:flex;flex-wrap:wrap;gap:6px}.chip{display:inline-block;border-radius:999px;padding:2px 10px;font-size:.8rem;font-weight:500;background:var(--idle-soft);color:var(--idle);white-space:nowrap}.chip.ok{background:var(--ok-soft);color:var(--ok)}.chip.warn{background:var(--warn-soft);color:var(--warn)}.chip.crit{background:var(--crit-soft);color:var(--crit)}.chip.acc{background:var(--accent-soft);color:var(--accent)}")
      o(".team{display:grid;gap:18px;border-top:2px solid var(--line);padding-top:14px}.stage{display:grid;gap:12px}.stage-head{display:flex;flex-wrap:wrap;gap:8px 16px;align-items:baseline;border-bottom:1px solid var(--line);padding-bottom:6px}.stage-head .s{font-size:.85rem;color:var(--muted)}")
      o(".tracks{display:grid;grid-auto-flow:column;grid-auto-columns:minmax(250px,1fr);gap:14px;overflow-x:auto}.track{display:grid;gap:12px;align-content:start}.track-head{font-size:.82rem;color:var(--muted)}")
      o(".card{background:var(--surface);border:1px solid var(--line);border-top:3px solid var(--idle);border-radius:10px;padding:12px 14px;display:grid;gap:8px;min-width:0}.card.taken{background:var(--taken)}.card.open{border-top-color:var(--accent)}.card.closed{border-top-color:var(--ok)}.card.attn{border-top-color:var(--crit)}.card.not-issued{border-style:dashed;border-top-style:solid;border-top-color:var(--line)}")
      o(".card .id{display:flex;justify-content:space-between;gap:8px}.card .id .step{font-size:.82rem;color:var(--muted)}.facts{display:grid;grid-template-columns:auto 1fr;gap:2px 12px;font-size:.85rem;margin:0}.facts dt{color:var(--muted)}.facts dd{margin:0;overflow-wrap:anywhere}")
      o(".units .lbl{display:flex;justify-content:space-between;font-size:.82rem;color:var(--muted)}.bar{height:6px;border-radius:999px;background:var(--idle-soft);overflow:hidden}.bar>span{display:block;height:100%;background:var(--ok)}.warns{font-size:.82rem;color:var(--warn)}details{font-size:.85rem}summary{cursor:pointer}footer{color:var(--muted);font-size:.82rem;border-top:1px solid var(--line);padding-top:12px}")
      o("</style></head><body><div class=\"wrap\">")
      o("<header><h1>" esc(TITLE) ": the plan</h1><div class=\"meta\"><span>Mode <b>GitHub manual</b></span><span>Written <b>" NOWT "</b></span><span>Applied spec <b class=\"mono\">" (APL == "" ? "none recorded" : esc(APL)) "</b></span></div></header>")
      if (ANYU) { s = ""; for (i = 1; i <= nux; i++) s = s "<li>" esc(UNX[i]) "</li>"; if (!nux) for (i = 1; i <= NUN["C"]; i++) { split(UNL["C", i], a, SUBSEP); s = s "<li>" esc(a[1] " " a[2] ": " a[3]) "</li>" }
        o("<section class=\"warnbox\" id=\"unread\"><b>Not all of it could be read at this call.</b> Nothing unread is counted, and no to-do leaves the list for it.<ul>" s "</ul></section>") }
      # what is new
      o("<section class=\"summary\"><div class=\"panel\" id=\"new\"><h2>New since your last call<span class=\"n\">" (PREV ? nn + 0 : "") "</span></h2>")
      if (PFAIL) o("<p class=\"muted\" data-new=\"none\">The read at your last call failed whole: there is nothing to compare with.</p>")
      else if (!PREV) o("<p class=\"muted\" data-new=\"none\">This is the first call after the switch: there is no read before it to compare with.</p>")
      else if (!nn) o("<p class=\"muted\">Nothing has changed since your last call.</p>")
      else { o("<ul class=\"list\">"); for (i = 1; i <= nn; i++) { split(NEW[i], a, SUBSEP); o("<li data-new=\"" esc(a[1]) "\">" a[2] "</li>") } o("</ul>") }
      x = 0; for (n in BAD) x++; if (PREV && x) o("<p class=\"muted\">" pl_(x, "ticket") " could not be read in full at this call or the last, and " (x > 1 ? "are" : "is") " left out of this comparison.</p>")
      o("</div>")
      # the to-do list
      o("<div class=\"panel\" id=\"todo\"><h2>Your to-do<span class=\"n\">" non + 0 "</span></h2>")
      if (!non) o("<p class=\"muted\">Nothing waits on you.</p>")
      else { o("<ul class=\"list todo\">")
        for (i = 1; i <= non; i++) { k = ON[i]; w = IW[k]; s = IS[k]; e = IE[k]; t = "<b>" esc(k) "</b>"
          if (IK[k] == "kept") t = t ": not raised at this call, whose read is unread in part; kept on the list"
          else if (IK[k] == "trigger") t = t ", critical: " esc(e) "<span class=\"cmd\">/vid next decline " esc(k) " &quot;…&quot;</span>"
          else if (w == "answer") t = t ": answer " esc(QT[s] == "" ? "the question" : QT[s]) "<span class=\"cmd\">/vid next answer " esc(s) " [&quot;there&quot;] &quot;…&quot;</span>"
          else if (w == "team-change") t = t ": take it in or decline it, " esc(e) "<span class=\"cmd\">/vid next team-change " esc(s) " yes|no &quot;…&quot;</span>"
          else if (w == "analyse" || w == "apply") t = t ": " esc(e) "<span class=\"cmd\">/vid next " esc(w) "</span>"
          else t = t ": " esc(e) "<span class=\"cmd\">/vid next " esc(k) " &quot;…&quot;</span>"
          if (IK[k] == "move") { m = split(WN[w, s], wa, "\001"); for (j = 2; j <= m; j++) t = t "<span class=\"warns\">Warning: " esc(wa[j]) "</span>" }
          t = t "<span class=\"cmd\">/vid next done " esc(k) " &quot;…&quot; · on the list since " esc(FIRST[k]) "</span>"
          o("<li" (IK[k] == "trigger" ? " class=\"crit\"" : "") " data-todo=\"" esc(k) "\">" t "</li>") }
        o("</ul>") }
      if (nrd) { s = ""; for (i = 1; i <= nrd; i++) s = add(s, esc(RDONE[i])); o("<p class=\"muted\">Off the list, no longer raised: " s ".</p>") }
      o("</div></section>")
      # the counts and the tiers, as the call printed them
      o("<section class=\"panel\" id=\"counts\"><h2>Not yet with the team<span class=\"n\">each test counted once</span></h2><div class=\"counts\">")
      if ("total" in CNT) o("<div class=\"count\" data-count=\"total\"><span class=\"v\">" esc(CNT["total"]) "</span><span class=\"k\">in all</span></div>")
      for (i = 1; i <= ncnt; i++) if (CK[i] != "total") o("<div class=\"count\" data-count=\"" esc(CK[i]) "\"><span class=\"v\">" esc(CNT[CK[i]]) "</span><span class=\"k\">" esc(CK[i]) "</span></div>")
      if (!ncnt) o("<p class=\"muted\">The call printed no count.</p>")
      o("</div><h2>Triggers by tier</h2>")
      if (HASTIERS) { s = ""; for (i = 1; i <= nti; i++) { k = TIO[i]; s = s "<span class=\"chip" (k == "critical" ? " crit" : k == "important" ? " warn" : "") "\" data-tier=\"" esc(k) "\">" esc(TIER[k]) " " esc(k) "</span>" } o("<div class=\"chips\">" s "</div>") }
      if (ntr) { o("<ul class=\"list\">"); for (t = 1; t <= 3; t++) { tn = (t == 1 ? "critical" : t == 2 ? "important" : "minor"); for (i = 1; i <= ntr; i++) { split(TRG[i], a, SUBSEP); if (a[1] == tn) o("<li data-trigger=\"" esc(a[2] " " a[3]) "\"><span class=\"chip" (tn == "critical" ? " crit" : tn == "important" ? " warn" : "") "\">" tn "</span> " esc(a[2] " " a[3]) ": " esc(a[4]) "</li>") } } o("</ul>") }
      else if (!HASTIERS) o("<p class=\"muted\">The call showed no trigger.</p>")
      o("</section>")
      # the plan, by team, then stage, then track; a lane no team holds, then a ticket of no step, after
      for (i = 1; i <= ns; i++) { s = SO[i]; G[s] = stg(SR[s]); STT[s] = (SL[s] in LT) ? LT[SL[s]] : "" }
      for (ti = 1; ti <= nm + 1; ti++) { tm = (ti > nm ? "" : TM[ti]); split("", GS); ng = 0
        for (i = 1; i <= ns; i++) { s = SO[i]; if (STT[s] != tm) continue; g = gs(s); if (!(g in GS)) { GS[g] = 1; GL[++ng] = g } }
        if (tm == "" && !ng) continue
        for (i = 1; i < ng; i++) for (j = i + 1; j <= ng; j++) if (GL[j] != "?" && (GL[i] == "?" || GL[j] + 0 < GL[i] + 0)) { x = GL[i]; GL[i] = GL[j]; GL[j] = x }
        if (tm == "") o("<section class=\"team\" data-team=\"-\"><h2>Lanes no team of the setup holds</h2>")
        else o("<section class=\"team\" data-team=\"" esc(tm) "\"><h2>Team " esc(tm) (TAR[tm] != "-" && TAR[tm] != "" ? " · " esc(TAR[tm]) : "") "</h2>")
        if (!ng) o("<p class=\"muted\">No step of the plan is in this team'"'"'s lanes.</p>")
        for (gi = 1; gi <= ng; gi++) { g = GL[gi]; c1 = 0; c2 = 0; c3 = 0; split("", LG); nlg = 0
          for (i = 1; i <= ns; i++) { s = SO[i]; if (STT[s] != tm || gs(s) != g) continue; c1++; if (tm == "" && !(SL[s] in LG)) { LG[SL[s]] = 1; LO_[++nlg] = SL[s] }
            if (STK[s] != "") { c2++; m = split(STK[s], a, " "); cl = 1; for (j = 1; j <= m; j++) if (TST["C", a[j]] != "CLOSED") cl = 0; if (cl) c3++ } }
          if (tm != "") { nlg = NL[tm]; for (j = 1; j <= nlg; j++) LO_[j] = LS[tm, j] }
          o("<div class=\"stage\" data-stage=\"" esc(g) "\"><div class=\"stage-head\"><h3>" (g == "?" ? "In no stage" : "Stage " esc(g) (SNAME[g] != "" ? " · " esc(SNAME[g]) : "")) "</h3><span class=\"s\">" pl_(c1, "step") " · " c2 " issued · " c3 " closed</span></div><div class=\"tracks\">")
          for (j = 1; j <= nlg; j++) { ln = LO_[j]; o("<div class=\"track\" data-lane=\"" esc(ln) "\"><div class=\"track-head\">lane " esc(ln) "</div>")
            for (i = 1; i <= ns; i++) { s = SO[i]; if (SL[s] != ln || STT[s] != tm || gs(s) != g) continue
              if (STK[s] == "") card(s, ""); else { m = split(STK[s], a, " "); for (x = 1; x <= m; x++) card(s, a[x]) } }
            o("</div>") }
          o("</div></div>") }
        o("</section>") }
      x = 0; for (i = 1; i <= nt; i++) if (!(TS_[TO[i]] in INPLAN)) x++
      if (x) { o("<section class=\"team\" data-team=\"no-step\"><h2>Tickets of no step in the plan</h2><div class=\"tracks\"><div class=\"track\">"); for (i = 1; i <= nt; i++) if (!(TS_[TO[i]] in INPLAN)) card(TS_[TO[i]], TO[i]); o("</div></div></section>") }
      o("<footer>Written by /vid next from this call'"'"'s read of GitHub and ViD'"'"'s records, after its moves. Its counts and tiers are the call'"'"'s own lines; nothing on it is a new rule.</footer>")
      o("</div></body></html>") }' "$T/f"
  [ ! -s "$T/tl" ] || cat "$T/tl" >> "$TODO"
  put "$OUT/plan.html" < "$T/page"
  echo "page $OUT/plan.html"; }

manual || ref 'this project is not in GitHub manual (lib.sh manual): the plan page is GitHub manual'"'"'s'
case "${1:-}" in
  write) [ $# -eq 2 ] || die 'usage — sh checks/next-page.sh write <triggers file>'; write "$2" ;;
  todo-done) shift; todo_done "$@" ;;
  *) die 'usage — sh checks/next-page.sh write <triggers file> | todo-done <kind> <subject> <move|words> [<words>]' ;;
esac
