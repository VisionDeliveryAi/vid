#!/bin/sh
# Purpose: GitHub manual's plan page (GM-2 T12). Run at the top of ViD's repository, in GitHub manual only (lib.sh manual). It
# reads nothing from GitHub and writes nothing to it, or to the project's own files: its sources are the call's read
# (.vid/round/read, GM-4 F3), the read before it (.vid/round/read.prev, kept by the connect at the call's start), the log
# (.vid/tw/log), the plan block, the plan's steps and the setup's teams as the planner reads them (planner.sh steps and teams,
# GM-4 F10), STAGES.md's stage names, the owner's queue (.vid/decide/queue: its open lines, what the last call raised) and the
# call's `next.sh triggers` lines, in the file the call hands it. It counts nothing the call's lines count: their counts and
# tiers are printed as they stand.
#   write <triggers file>   the page: one self-contained HTML file that opens offline, plan.html in the folder /vid view writes to
#                      (viewer/view.sh: ~/ViD Viewer/<the repository's folder name>/), beside its pages; prints `page <path>`.
#                      In order: what is new since the last call, the to-do list, what is not yet with the team counted by
#                      kind, the triggers by tier, then the plan by team, stage and track.
# The to-do list (GM-4 F4) is the owner's queue: each open `Q<n>` line, in its order, a move or a trigger the last call raised by
# its kind and subject, with the command that does it, answers it or takes it off the list (/vid next done), and when it was
# first asked. Nothing is logged here: an answer is the queue's (queue.sh answer).
# What is new since the last call compares the two reads: each published ticket opened, closed, taken (as next.sh reads taken:
# a `vid: claimed` comment, an assignee or a sub-issue) or given units; each unit closed; each pull request of a ticket, or of
# one of its units, opened or merged; each question (a `Question:` comment head) the read before did not hold; each team change
# whose test the body names now and did not then, or did then and does not now; each important trigger shown (T9 shows one only
# when it is new or changed) but a team change, and each critical one first raised at this call (queue.sh raise). A ticket a read could not read
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
RD=.vid/round/read; PRV=.vid/round/read.prev; LOG=.vid/tw/log; QD=.vid/decide/queue
# clean <words>: the owner's words on one line, a tab or a newline one space, a " written ' (GM-2 §5)
clean() { printf '%s' "$1" | tr '\t\n\r' '   ' | tr '"' "'"; }

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
  # GM-4 F10: the setup's teams and each step's stage as the planner reads them (planner.sh teams, steps), never written again here
  mustread "$T/pteams" planner teams; awk -F'\t' 'NF >= 4 { print "TEAM\t" $1 "\t" $4 "\t" $2 }' "$T/pteams" >> "$T/f"
  mustread "$T/psteps" planner steps; awk -F'\t' '{ print "PST\t" $1 "\t" $3 }' "$T/psteps" >> "$T/f"
  { awk '/^```vid-stages/ { b = 1; next } b && /^```/ { exit } b' STAGES.md 2>/dev/null || true; } |
    awk -F'|' '$1 ~ /^STAGE-[0-9]+[ \t]*$/ { s = $1; sub(/^STAGE-/, "", s); gsub(/[ \t]/, "", s); n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print "SN\t" (s + 0) "\t" n }' >> "$T/f"
  # GM-4 F4: the owner's queue's open lines, `QL <Q n> <key> <asked at> <words>` in its order, and each critical trigger first
  # raised at the newest raise (FR <its key>)
  if [ -f "$QD/items" ] && [ -f "$QD/ids" ]; then awk -F'\t' 'FILENAME == ARGV[1] { N[$1] = $2; A[$1] = $3; next } ($1 in N) { print "QL\t" N[$1] "\t" $1 "\t" A[$1] "\t" $3 }' "$QD/ids" "$QD/items" >> "$T/f"; fi
  if [ -f "$QD/raised" ]; then awk -F'\t' -v g="$(cat "$QD/raises" 2>/dev/null || echo 0)" '$2 == g && $3 == "critical" { print "FR\t" $1 }' "$QD/raised" >> "$T/f"; fi
  for r in "$RD" "$PRV"; do [ ! -f "$r" ] || awk -F'\t' '$1 == "ticket" { print $2 "\t" $5 }' "$r"; done | sort -u | while IFS="$TAB" read -r n c; do
    printf 'TE\t%s\t%s\n' "$n" "$(epoch "$c")"; done >> "$T/f"
  printf 'CFG\trepo\t%s\nCFG\tpx\t%s\nCFG\tnow\t%s\nCFG\tnowt\t%s\nCFG\tapplied\t%s\nCFG\ttitle\t%s\n' "$(skey repo)" "$(skey labels-prefix)" "$(date -u +%s)" "$(now)" "$(applied | cut -c1-12)" "$TITLE" >> "$T/f"; }

write() {
  [ -f "$1" ] || ref "no triggers file at $1"
  P=$(pwd -P); NAME=$(basename "$P"); OUT="$HOME/ViD Viewer/$NAME"
  case "$OUT/" in "$P/"*) ref "the viewer's folder $OUT is inside the project; nothing is written there" ;; esac
  mkdir -p "$OUT" || ref "cannot write $OUT"
  TITLE=$({ git show HEAD:PRD.md 2>/dev/null || cat PRD.md 2>/dev/null || true; } | sed -n '1s/^# //p' | sed 's/[[:space:]]*—[[:space:]]*PRD[[:space:]]*$//')
  [ -n "$TITLE" ] || TITLE=$NAME
  mustread "$T/rows" planner rows --newest
  inputs "$1"
  awk -F'\t' -v PG="$T/page" '
    function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); gsub(/"/, "\\&quot;", s); gsub(/\047/, "\\&#39;", s); return s }
    function num(s) { return s ~ /^[0-9]+$/ }
    function add(a, x) { return a == "" ? x : a ", " x }
    function pl_(n, w) { return n " " w (n == 1 ? "" : "s") }
    function iss(n) { return (REPO == "" ? "#" n : "<a href=\"https://github.com/" REPO "/issues/" n "\">#" n "</a>") }
    function pr(n) { return (REPO == "" ? "#" n : "<a href=\"https://github.com/" REPO "/pull/" n "\">#" n "</a>") }
    function o(s) { print s > PG }
    function gs(s) { return G[s] == "" ? "?" : G[s] }
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
    # qk <key>: a raised item'"'"'s kind (its what) and subject, `<kind> <subject>`, its raising (@<since>) left out
    function qk(k,   a, x, s, i) { split(k, a, ":"); x = (a[1] == "move") ? 3 : 4; s = k; for (i = 1; i <= x; i++) sub(/^[^:]*:/, "", s); sub(/@[0-9]+$/, "", s); return a[2] " " s }
    $1 == "QL" { QLO[++nql] = $2 SUBSEP $3 SUBSEP $4 SUBSEP $5; if ($3 ~ /^question:/) { q = $3; sub(/^question:/, "", q); n = q; sub(/:.*/, "", n); QI[++nqi] = n SUBSEP "#" q SUBSEP $5 } next }
    $1 == "FR" { FRESH[qk($2)] = 1; next }
    $1 == "PST" { PSTG[$2] = $3; next }
    $1 == "TE" { TE[$2] = $3; next }
    $1 == "X" { t = $2
      if (t == "count") { if (!($3 in CNT)) CK[++ncnt] = $3; CNT[$3] = $4 }
      else if (t == "unread") { UNX[++nux] = $3 " " $4 ": " $5 }
      else if (t == "trigger") TRG[++ntr] = $3 SUBSEP $4 SUBSEP $5 SUBSEP $6
      else if (t == "tiers") { HASTIERS = 1; for (i = 3; i <= NF; i++) { split($i, kv, "="); TIER[kv[1]] = kv[2]; TIO[++nti] = kv[1] } }
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
      o("<div class=\"panel\" id=\"todo\"><h2>Your to-do<span class=\"n\">" nql + 0 "</span></h2>")
      if (!nql) o("<p class=\"muted\">Nothing waits on you.</p>")
      else { o("<ul class=\"list todo\">")
        # GM-4 F4: the owner'"'"'s queue, each open line; a move or trigger the last call raised by its kind and subject, the re-plan
        # moves as next-move.sh takes them (GM-3 U6), planning-analysis with no subject, implement-replan with the words alone
        for (i = 1; i <= nql; i++) { split(QLO[i], a, SUBSEP); qn = a[1]; k = a[2]; e = a[4]; cr = (k ~ /^trigger:[^:]*:critical:/)
          if (k ~ /^(move|trigger):/) { ks = qk(k); w = ks; sub(/ .*/, "", w); s = substr(ks, length(w) + 2); t = "<b>" esc(ks) "</b> <span class=\"muted\">" esc(qn) "</span>" }
          else { ks = qn; t = "<b>" esc(qn) "</b>" }
          if (k ~ /^trigger:/) t = t ", " (cr ? "critical" : "important") ": " esc(e) "<span class=\"cmd\">/vid next decline " esc(ks) " &quot;…&quot;</span>"
          else if (k !~ /^move:/) t = t ": " esc(e) "<span class=\"cmd\">/vid next answer " esc(qn) " … &quot;…&quot;</span>"
          else if (w == "team-change") t = t ": take it in or decline it, " esc(e) "<span class=\"cmd\">/vid next team-change " esc(s) " yes|no &quot;…&quot;</span>"
          else if (w == "planning-analysis") t = t ": " esc(e) "<span class=\"cmd\">/vid next planning-analysis</span>"
          else if (w == "implement-replan") t = t ": " esc(e) "<span class=\"cmd\">/vid next implement-replan &quot;…&quot;</span>"
          else t = t ": " esc(e) "<span class=\"cmd\">/vid next " esc(ks) " &quot;…&quot;</span>"
          if (k ~ /^move:/) { m = split(WN[w, s], wa, "\001"); for (j = 2; j <= m; j++) t = t "<span class=\"warns\">Warning: " esc(wa[j]) "</span>" }
          if (k ~ /^move:/ || cr) t = t "<span class=\"cmd\">/vid next done " esc(ks) " &quot;…&quot; · on the list since " esc(a[3]) "</span>"
          else t = t "<span class=\"cmd\">on the list since " esc(a[3]) "</span>"
          o("<li" (cr ? " class=\"crit\"" : "") " data-todo=\"" esc(ks) "\" data-q=\"" esc(qn) "\">" t "</li>") }
        o("</ul>") }
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
      for (i = 1; i <= ns; i++) { s = SO[i]; G[s] = PSTG[s]; STT[s] = (SL[s] in LT) ? LT[SL[s]] : "" }
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
  put "$OUT/plan.html" < "$T/page"
  echo "page $OUT/plan.html"; }

manual || ref 'this project is not in GitHub manual (lib.sh manual): the plan page is GitHub manual'"'"'s'
case "${1:-}" in
  write) [ $# -eq 2 ] || die 'usage — sh checks/next-page.sh write <triggers file>'; write "$2" ;;
  *) die 'usage — sh checks/next-page.sh write <triggers file>' ;;
esac
