#!/bin/sh
# Purpose: the owner's panel's list (FB-5 A1), .vid/face/list.json, the one file hooks/face draws in ticket mode, and its sections 5
# and on as text. Run at the top of ViD's repository, in both GitHub modes. It reads nothing from GitHub and writes nothing to it, or
# to the project's records: its sources are the sort as it stands (queue.sh sorted), the owner's backlog (.vid/decide/queue/backlog)
# and, in GitHub manual alone (lib.sh manual), the call's read (.vid/round/read, GM-4 F3), the read before it (.vid/round/read.prev,
# kept by the connect at the call's start), the log (.vid/tw/log), the plan's steps and the setup's teams as the planner reads them
# (planner.sh steps and teams, GM-4 F10), STAGES.md's release names, the accepted records (.vid/decide/accepted-at and merges, the
# landings' resets in rulings, the handed record's rows) and the call's lines (next.sh triggers), kept in .vid/next/lines. It judges
# and sorts nothing: what stands in sections 1 to 4 is queue.sh's, and it counts nothing the call's lines count.
#   write [<lines file>]   the list, written whole by a rename; the lines .vid/next/lines by default, none kept is no lines; prints
#                      `list .vid/face/list.json`. No lock, no sync. A sort that cannot be read is refused, the list as it was; a
#                      plan that cannot be read keeps the plan and the teams last written, says so under the counts, exit 1
#   text [<lines file>]    GitHub manual: the plan and each team as text, a step a line
# The plan and the teams (GitHub manual's, as the plan page was). A step is on one card, in its lane's team and its release; a step
# of a lane no team holds, and a ticket of a step the plan no longer holds, each in a section of its own after the teams. Accepted:
# it has a ticket, each of its tickets has an acceptance recorded, and none of its tests was reset by a landing since; with no ticket,
# each of its tests is accepted on the handed record. Closed is not accepted. Else it is being built (pieces or an open pull request,
# or its ticket closed), taken (a `vid: claimed` comment or an assignee, as next.sh reads taken), sent with nobody on it, or not sent.
# A ticket not read at this call reads as the read before had it, else as taken, and its card says so. What a step builds on is
# the steps not accepted it builds on, directly or through others; its card names those no other of them builds on.
# A card's notes: blocked, the team's changes (the call's team-change moves), its tests reworded or retired (the call's counted
# lines), an open question, another ticket of the step, and what is new since the owner's last call: the two reads compared, a ticket
# sent, closed or taken, pieces given or done, pull requests opened or merged. A ticket a read could not read in part is left out of
# the comparison; with no read before, or one that failed whole (an `unread round` line and no `ticket` line), nothing is compared.
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
die() { echo "ViD next-page: $*" >&2; exit 2; }
ref() { echo "ViD next-page: refused — $*" >&2; exit 1; }
RD=.vid/round/read; PRV=.vid/round/read.prev; LOG=.vid/tw/log; QD=.vid/decide/queue; D=.vid/decide; LJ=.vid/face/list.json; PCA=.vid/face/plan.cache; VERB=${1:-}

# plan_: the planner's teams and steps in $T/pteams and $T/psteps, kept in .vid/face/plan.cache (`key <key>`, `T TAB <team line>`, `S TAB
# <step line>`, `end`) and read again only when the key changed: the cksum of what the two verbs read in GitHub manual, the plan
# block and RUN-STATE's mode: and stage:, the setup (.vid/tw/settings, .vid/plan/setup), the log and the stage each recorded writing names,
# the applied commit (its PRD.md, INVENTORY.md, STAGES.md, GRADING-CHECKLIST.md and ARCHITECTURE.md, never the working tree's), HEAD's PLAN.md, the
# budget, and the scripts themselves. Only `write` keeps it; a run that fails keeps nothing
plan_() { K=$({ set +e; plan_block; grep -E '^(mode|stage):' .vid/RUN-STATE.md; for f in .vid/tw/settings .vid/plan/setup .vid/tw/log .vid/budget "$HERE/planner.sh" "$HERE/stages.sh" "$HERE/prd.sh" "$HERE/lib.sh"; do echo "== $f"; cat "$f"; done
    grep -H '^- stage: ' .vid/tw/out/issue-*.md; _c=$(applied); git rev-parse "${_c:-none}^{commit}"; git rev-parse HEAD:./PLAN.md; } 2>/dev/null | cksum | tr ' ' '-')
  if [ -f "$PCA" ] && [ "$(sed -n 1p "$PCA")" = "key $K" ] && [ "$(tail -n 1 "$PCA")" = end ]; then sed -n 's/^T	//p' "$PCA" > "$T/pteams"; sed -n 's/^S	//p' "$PCA" > "$T/psteps"; return 0; fi
  lread "$T/pteams" planner teams && lread "$T/psteps" planner steps || return 1
  [ "$VERB" = write ] && mkdir -p .vid/face && { echo "key $K"; sed 's/^/T	/' "$T/pteams"; sed 's/^/S	/' "$T/psteps"; echo end; } | put "$PCA" || :; }

# inputs <lines file>: every source as tagged lines into $T/f, read by the one awk program below; NOP when the plan could not be read
inputs() { NOP=''
  title=$({ git show HEAD:PRD.md 2>/dev/null || cat PRD.md 2>/dev/null || true; } | sed -n '1s/^# //p' | sed 's/[[:space:]]*—[[:space:]]*PRD[[:space:]]*$//')
  { printf 'CFG\ttitle\t%s\nCFG\tnowt\t%s\n' "${title:-$(basename "$(pwd -P)")}" "$(now)"; sed 's/^/S	/' "$T/sorted"
    [ ! -f "$QD/backlog" ] || awk -F'\t' '$3 != "done" { print "B\t" $1 "\t" $5 }' "$QD/backlog"; } > "$T/f"
  manual || { echo 'CFG	auto	1' >> "$T/f"; return 0; }
  if plan_; then :; else NOP=1; : > "$T/pteams"; : > "$T/psteps"; echo 'CFG	noplan	1' >> "$T/f"; fi
  { awk -F'\t' 'NF >= 4 { print "TEAM\t" $1 "\t" $4 "\t" $2 }' "$T/pteams"
    awk -F'\t' '{ print "ST\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $9 }' "$T/psteps"
    [ ! -f "$1" ] || sed 's/^/X	/' "$1"
    [ ! -f "$RD" ] || sed 's/^/C	/' "$RD"
    if [ -f "$PRV" ]; then echo PREV; sed 's/^/P	/' "$PRV"; fi
    { cat "$LOG" 2>/dev/null || true; } | awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      $1 == "withdrawn" { W[$2] = 1 } ($1 == "published" || $1 == "amended") && $2 ~ /^[0-9]+$/ { if (!($2 in S)) { O[++n] = $2; A[$2] = kv("at") } if ($1 == "published") delete W[$2]; S[$2] = kv("step"); if (kv("kind") != "") K[$2] = kv("kind"); r = kv("rows"); gsub(/,/, " ", r); R[$2] = (r == "-" ? "" : r) }
      END { for (i = 1; i <= n; i++) if (!(O[i] in W)) print "PUB\t" O[i] "\t" (S[O[i]] == "" ? "-" : S[O[i]]) "\t" R[O[i]] "\t" K[O[i]] "\t" A[O[i]] }'
    { awk '/^```vid-stages/ { b = 1; next } b && /^```/ { exit } b' STAGES.md 2>/dev/null || true; } |
      awk -F'|' '$1 ~ /^STAGE-[0-9]+[ \t]*$/ { s = $1; sub(/^STAGE-/, "", s); gsub(/[ \t]/, "", s); n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print "SN\t" (s + 0) "\t" n }'
    { cat "$D/accepted-at" 2>/dev/null || true; } | awk 'NF >= 2 { print "AC\t" $2 }'
    { cat "$D/merges" 2>/dev/null || true; } | awk -F'\t' '$2 != "" { print "AC\t" $2 }'
    { cat "$D/rulings" 2>/dev/null || true; } | awk -F'\t' 'NF >= 3 { print "RU\t" $2 "\t" $3 }'
    { cat .vid/tw/handed 2>/dev/null || true; } | awk '$1 == "row" { print "HS\t" $2 "\t" $3 }'
    if [ -f "$QD/ids" ] && [ -f "$QD/items" ]; then awk -F'\t' '$1 ~ /^question:[0-9]+:/ { split($1, a, ":"); print "QU\t" a[2] }' "$QD/items"; fi; } >> "$T/f"
  for r in "$RD" "$PRV"; do [ ! -f "$r" ] || awk -F'\t' '$1 == "ticket" { print $2 "\t" $5 }' "$r"; done | sort -u | while IFS="$TAB" read -r n c; do
    printf 'TE\t%s\t%s\n' "$n" "$(epoch "$c")"; done >> "$T/f"
  awk -F'\t' '$1 == "PUB" && $6 != "" { print $2 "\t" $6 }' "$T/f" | while IFS="$TAB" read -r n c; do printf 'PE\t%s\t%s\n' "$n" "$(epoch "$c")"; done > "$T/pe"; cat "$T/pe" >> "$T/f"
  printf 'CFG\trepo\t%s\nCFG\tpx\t%s\nCFG\tnow\t%s\n' "$(skey repo)" "$(skey labels-prefix)" "$(date -u +%s)" >> "$T/f"; }

# make <lines file>: $T/head (the sort's part of the list, one line), $T/board (the plan, then the teams, a line each) and $T/text
make() {
  [ -f .vid/tw/settings ] || ref 'this is no ticket-mode project: there is no .vid/tw/settings here'
  if ! sh "$HERE/queue.sh" sorted > "$T/sorted" 2> "$T/err"; then sed 's/^/    /' "$T/err" >&2; ref 'the sort could not be read (queue.sh sorted); the list is as it was'; fi
  inputs "$1"; : > "$T/text"
  awk -F'\t' -v HD="$T/head" -v BD="$T/board" -v TX="$T/text" "$BLKL"'
    function js(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); gsub(/[\001-\037]/, "", s); return "\"" s "\"" }
    function pl(n, w) { return n " " w (n == 1 ? "" : "s") }
    function add(a, x) { return a == "" ? x : a "," x }
    function list(a, n,   i, s) { s = ""; for (i = 1; i <= n; i++) s = s (i == 1 ? "" : i == n ? " and " : ", ") a[i]; return s }
    function nm(l) { return (l in NAME) ? NAME[l] : l }
    function gs(s,   g) { g = STG[s]; return g ~ /^[0-9]+$/ ? g + 0 : -1 }
    function gn(g) { return g < 0 ? "In no release" : SNAME[g] }
    function rname(g) { return g < 0 ? "In no release" : "Release " g (SNAME[g] == "" ? "" : " · " SNAME[g]) }
    function flag(i,   c) { c = "abcdefghijklmnopqrstuvwxyz"; return (i > 26 ? substr(c, int((i - 1) / 26), 1) : "") substr(c, (i - 1) % 26 + 1, 1) }
    function day(t,   m) { if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) return ""; m = substr("JanFebMarAprMayJunJulAugSepOctNovDec", (substr(t, 6, 2) - 1) * 3 + 1, 3)
      return (substr(t, 9, 2) + 0) " " m (substr(t, 1, 4) == substr(NOWT, 1, 4) ? "" : " " substr(t, 1, 4)) }
    # tk <read> <n>: the published ticket n names: n itself, or the ticket whose piece it is
    function tk(r, n) { return (n in ISPUB) ? n : ((r, n) in C2T) ? C2T[r, n] : (("C", n) in C2T) ? C2T["C", n] : (("P", n) in C2T) ? C2T["P", n] : "" }
    function taken(r, n) { return index("\001" IH[r, n] "\001", "\001vid: claimed") || (TA[r, n] != "" && TA[r, n] != "-") || UT[r, n] + 0 > 0 }
    function names(r, n, id,   i, m, w, j) { for (i = 1; i <= NB[r, n]; i++) { m = split(BL[r, n, i], w, /[^A-Za-z0-9_-]+/); for (j = 1; j <= m; j++) if (w[j] == id) return 1 } return 0 }
    function note(s, t) { NOTE[s, ++NN[s]] = t }
    function person(s, l,   a, m, i) { if (l == "" || l == "-") return; m = split(l, a, ","); for (i = 1; i <= m; i++) if (a[i] != "" && a[i] != "-" && !((s, nm(a[i])) in WS)) { WS[s, nm(a[i])] = 1; WP[s, ++NW[s]] = nm(a[i]) } }
    function ok(x) { return x ~ /^(accepted|accepted-by-ruling|owed|paid|held|known-limit)$/ }
    # step_ <s>: one step, or a ticket of no step (s its key), from its tickets: its state, its pieces, its people, its notes
    function step_(s,   m, a, i, j, n, r, u, c, acc, all, cl, opn, tkn, mt, w, x, k, q) {
      m = split(STK[s], a, " "); all = (m > 0); MAIN[s] = ""; split("", SEEN)
      for (i = 1; i <= m; i++) { n = a[i]; acc = (n in AC); x = 0; k = split(TR[n], w, " ")
        for (j = 1; j <= k; j++) { if (RUL[w[j]] == "reset" && !ok(HS[w[j]])) x++; if (!(w[j] in SEEN)) { SEEN[w[j]] = 1; TIDS[s] = TIDS[s] (TIDS[s] == "" ? "" : " ") w[j]; NT[s]++ } }
        if (acc && x) { acc = 0; note(s, pl(x, "test") " changed after " (TK[n] ~ /^(step|skeleton)$/ ? "the step" : "#" n) " was accepted") }
        if (!acc) all = 0
        # the ticket it is named by: the newest of its own kind not closed, else the newest
        mt = (TK[n] ~ /^(step|skeleton)$/) * 4 + (TST["C", n] != "CLOSED") * 2
        if (MAIN[s] == "" || mt >= BEST) { MAIN[s] = n; BEST = mt } }
      if (!m) { TIDS[s] = SR[s]; NT[s] = split(SR[s], w, " "); all = (NT[s] > 0); for (j = 1; j <= NT[s]; j++) if (HS[w[j]] !~ /^(accepted|accepted-by-ruling|paid)$/) all = 0 }
      opn = 0; tkn = 0; cl = (m > 0); PC[s] = 0; DN[s] = 0; NPL[s] = 0; RDY[s] = 0; DRF[s] = 0; NW[s] = 0; x = 0
      for (i = 1; i <= m; i++) { n = a[i]; r = HAS["C", n] ? "C" : HAS["P", n] ? "P" : ""
        if (r != "C") note(s, "#" n " was not read at this call" (r == "P" ? ": it is as the call before read it" : ""))
        if (r == "") { tkn = 1; cl = 0; continue }
        if (TST[r, n] != "CLOSED") cl = 0
        if (taken(r, n)) tkn = 1
        if (blkl(IL[r, n], PX) != "" && TST[r, n] != "CLOSED") { BLK[s] = 1; note(s, "The team marked #" n " blocked") }
        person(s, TA[r, n]); u = UT[r, n] + 0; PC[s] += u
        for (j = 1; j <= u; j++) { c = SK[r, n, j]; if (SS[r, n, c] == "CLOSED") DN[s]++; else person(s, SA[r, n, c]) } }
      for (j = 1; j <= NOP_["C"]; j++) { k = OPO["C", j]; q = tk("C", OP["C", k]); if (q == "" || SOF[q] != s) continue
        NPL[s]++; PLN[s, NPL[s]] = k; PLD[s, NPL[s]] = OD["C", k]; if (OD["C", k]) DRF[s]++; else RDY[s]++; person(s, OA["C", k]) }
      for (i = 1; i <= m && !NW[s]; i++) for (j = 1; j <= UT["C", a[i]]; j++) person(s, SA["C", a[i], SK["C", a[i], j]])
      ST[s] = all ? "accepted" : !m ? "unsent" : (PC[s] || NPL[s] || cl) ? "building" : tkn ? "taken" : "nobody"
      FILL[s] = all ? 100 : PC[s] ? int(DN[s] * 100 / PC[s]) : 0
      n = MAIN[s]; WHEN[s] = (n == "") ? "" : HAS["C", n] ? TCR["C", n] : HAS["P", n] ? TCR["P", n] : TAT[n]; x = (n in TE) ? TE[n] : PE[n]
      DAYS[s] = (x + 0 > 0 && NOW + 0 > x) ? int((NOW - x) / 86400) : 0
      for (j = 1; j <= NW[s]; j++) w[j] = WP[s, j]; WHO[s] = list(w, NW[s])
      if (cl && !all) note(s, "Its ticket is closed; it is not accepted yet")
      split("", w); for (i = 1; i <= m; i++) { n = a[i]; w["+"] += TADD[n]; w["-"] += TDROP[n]; w["q"] += QN[n] }
      if (w["+"]) note(s, pl(w["+"], "test") " added by the team")
      if (w["-"]) note(s, pl(w["-"], "test") " dropped by the team")
      if (m) { k = split(TIDS[s], q_, " "); x = 0; c = 0; for (j = 1; j <= k; j++) { if (CTD["restated", q_[j]]) x++; if (CTD["retired", q_[j]]) c++ }
        if (x) note(s, x " of its tests " (x == 1 ? "was" : "were") " reworded; its ticket holds the older words")
        if (c) note(s, c " of its tests " (c == 1 ? "is" : "are") " retired; its ticket still holds " (c == 1 ? "it" : "them")) }
      if (w["q"]) note(s, pl(w["q"], "question") " of the team " (w["q"] == 1 ? "waits" : "wait") " for an answer")
      for (i = 1; i <= m; i++) if (a[i] != MAIN[s]) note(s, "Also #" a[i] (TK[a[i]] == "" || TK[a[i]] == "step" ? "" : ", a " TK[a[i]] " ticket") (!HAS["C", a[i]] ? "" : TST["C", a[i]] == "CLOSED" ? ", closed" : ", open"))
      x = ""; for (i = 1; i <= m; i++) if (NEWS[a[i]] != "") x = x (x == "" ? "" : ", ") NEWS[a[i]]
      if (x != "") note(s, "Since your last call: " x) }
    function card(s,   i, b, u) {
      b = "{\"id\":" js(SID[s]) ",\"name\":" js(SNM[s]) ",\"flag\":" js(FLAG[s]) ",\"state\":" js(ST[s]) ",\"ticket\":" (MAIN[s] + 0) ",\"url\":" js(MAIN[s] == "" || REPO == "" ? "" : "https://github.com/" REPO "/issues/" MAIN[s]) ",\"done\":" DN[s] ",\"pieces\":" PC[s] ",\"who\":" js(WHO[s]) ",\"ready\":" RDY[s] ",\"drafts\":" DRF[s] ",\"pulls\":["
      for (i = 1; i <= NPL[s]; i++) b = b (i > 1 ? "," : "") "{\"n\":" PLN[s, i] ",\"url\":" js(REPO == "" ? "" : "https://github.com/" REPO "/pull/" PLN[s, i]) ",\"draft\":" (PLD[s, i] ? "true" : "false") "}"
      b = b "],\"sent\":" js(day(WHEN[s])) ",\"days\":" DAYS[s] ",\"buildsOn\":["; for (i = 1; i <= NON[s]; i++) b = b (i > 1 ? "," : "") js(SNM[ON[s, i]])
      b = b "],\"holdsUp\":" HU[s] + 0 ",\"tests\":" NT[s] + 0 ",\"testIds\":["; u = split(TIDS[s], c_, " "); for (i = 1; i <= u; i++) b = b (i > 1 ? "," : "") js(c_[i])
      b = b "],\"notes\":["; for (i = 1; i <= NN[s]; i++) b = b (i > 1 ? "," : "") js(NOTE[s, i])
      return b "]}" }
    function tline(s,   t, i) { t = SID[s] " · " SNM[s] " · " SAY[ST[s]] (MAIN[s] == "" ? "" : " · #" MAIN[s]) (PC[s] ? " · " DN[s] " of " pl(PC[s], "piece") " done" : "") (WHO[s] == "" ? "" : " · " WHO[s])
      if (NPL[s]) { t = t " · pull requests " RDY[s] " ready, " pl(DRF[s], "draft") ":"; for (i = 1; i <= NPL[s]; i++) t = t " #" PLN[s, i] }
      if (day(WHEN[s]) != "") t = t " · sent " day(WHEN[s]) ", " pl(DAYS[s], "day") " ago"
      if (ST[s] != "accepted" && (s in INPLAN)) { t = t " · builds on "; for (i = 1; i <= NON[s]; i++) t = t (i > 1 ? "; " : "") SNM[ON[s, i]]; if (!NON[s]) t = t "nothing that is not accepted" }
      if (HU[s]) t = t " · holds up " pl(HU[s], "later step")
      t = t " · " pl(NT[s] + 0, "test"); for (i = 1; i <= NN[s]; i++) t = t " · " NOTE[s, i]
      print t > TX }
    # tally <array of states> <n>: "3 steps: 1 accepted, 2 being built"
    function tally(a, n,   i, c, s) { for (i = 1; i <= n; i++) c[ST[a[i]]]++; s = ""
      for (i = 1; i <= 5; i++) if (c[SO_[i]]) s = s (s == "" ? "" : ", ") c[SO_[i]] " " SW[SO_[i]]
      return pl(n, "step") (s == "" ? "" : ": " s) }
    function who_(g, st,   i, j, n, w, h) { n = 0; for (i = 1; i <= ns; i++) if (gs(SO[i]) == g && ST[SO[i]] == st) for (j = 1; j <= NW[SO[i]]; j++) if (!(WP[SO[i], j] in h)) { h[WP[SO[i], j]] = 1; w[++n] = WP[SO[i], j] } return list(w, n) }
    $1 == "S" { l = $0; sub(/^S\t/, "", l); if (l == "") next; k = l; sub(/ .*/, "", k); v = (index(l, " ") ? substr(l, index(l, " ") + 1) : "")
      if (k == "sorted") SAT = v; else if (k == "state") STATE = v; else if (k == "unsorted") { if (!(v in UNS)) nun++; UNS[v] = 1 }
      else if (k == "release") { x = v; sub(/ .*/, "", x); RW[x + 0] = substr(v, length(x) + 2) } else if (k == "name") { x = v; sub(/ .*/, "", x); NAME[x] = substr(v, length(x) + 2) }
      else if (k == "line") { split(v, a, " "); L = ++nl; LK[L] = a[1]; LN[L] = a[2]; LI[L] = (a[3] == "-" ? "" : a[3]); cur = L; m = split(LI[L], b, ","); for (i = 1; i <= m; i++) if (!(b[i] in AT)) AT[b[i]] = (a[1] == "todo" ? a[2] : a[1] == "waiting" ? "Waiting" : a[1] == "changed" ? "Changed" : a[1] == "plan" ? "The plan" : "The rest") }
      else if (k == "ask") { AQ[cur, ++NA[cur]] = v }
      else if (k == "about") AB[cur, NA[cur]] = v
      else if (k == "message") AM[cur, NA[cur]] = v
      else if (k == "choice") ACH[cur, NA[cur], ++NC[cur, NA[cur]]] = v
      else if (k == "choose") { x = v; sub(/ .*/, "", x); AP[cur, NA[cur]] = x + 0; AW[cur, NA[cur]] = (index(v, " ") ? substr(v, index(v, " ") + 1) : "") }
      else V[cur, k] = v
      next }
    $1 == "B" { if ($2 in HELD) next; HELD[$2] = 1; HO[++nh] = $2; HW[$2] = $3; next }
    $1 == "CFG" { if ($2 == "repo") REPO = $3; else if ($2 == "px") PX = $3; else if ($2 == "now") NOW = $3; else if ($2 == "nowt") NOWT = $3; else if ($2 == "title") TITLE = $3; else if ($2 == "auto") AUTO = 1; else if ($2 == "noplan") NOPLAN = 1; next }
    $1 == "PUB" { TO[++nt] = $2; TS_[$2] = $3; TR[$2] = $4; TK[$2] = $5; TAT[$2] = $6; ISPUB[$2] = 1; next }
    $1 == "ST" { s = $2; SO[++ns] = s; SID[s] = s; SNM[s] = $3; STG[s] = $4; SR[s] = $5; gsub(/,/, " ", $6); SB[s] = $6; SL[s] = $7; INPLAN[s] = 1; next }
    $1 == "TEAM" { TM[++ntm] = $2; TAR[$2] = $4; NL[$2] = $3; for (i = 1; i <= $3; i++) { l = ($3 == 1 ? $2 : $2 "-" i); LT[l] = $2; LS[$2, i] = l } nlan += $3; next }
    $1 == "SN" { SNAME[$2] = $3; next }
    $1 == "AC" { AC[$2] = 1; next }
    $1 == "RU" { RUL[$2] = $3; next }
    $1 == "HS" { HS[$2] = $3; next }
    $1 == "QU" { QN0[$2]++; next }
    $1 == "TE" { TE[$2] = $3; next }
    $1 == "PE" { PE[$2] = $3; next }
    $1 == "PREV" { PREV = 1; next }
    $1 == "X" { t = $2
      if (t == "count") { if (!($3 in CNT)) CK[++ncnt] = $3; CNT[$3] = $4 }
      else if (t == "counted") CTD[$3, $4] = 1
      else if (t == "unread") UX[++nux] = $3 ($4 == "" || $4 == "-" ? "" : " " $4) ": " $5
      else if (t == "context" && $3 == "report") RPX[++nrp] = $5   # FB-3 A2
      else if (t == "tiers") { for (i = 3; i <= NF; i++) { split($i, kv, "="); TIER[kv[1]] = kv[2] } }
      else if (t == "move" && $3 == "team-change") { s = $4; sub(/^#/, "", s); split(s, a, " "); TC[++ntc] = a[1] SUBSEP a[2] }
      next }
    $1 == "C" || $1 == "P" { r = $1; t = $2
      if (t == "ticket") { HAS[r, $3] = 1; if (r == "P") PT = 1; TST[r, $3] = $4; TA[r, $3] = $5; TCR[r, $3] = $6 }
      else if (t == "body") { NB[r, $3]++; BL[r, $3, NB[r, $3]] = substr($0, length($1 $2 $3) + 4) }
      else if (t == "sub") { if (!((r, $3, $5) in SS)) { UT[r, $3]++; SK[r, $3, UT[r, $3]] = $5 } SS[r, $3, $5] = $6; SA[r, $3, $5] = $7; C2T[r, $5] = $3 }
      else if (t == "issue") { IL[r, $3] = "," $4 ","; IH[r, $3] = $5 }
      else if (t == "open") { OP[r, $3] = $4; OPO[r, ++NOP_[r]] = $3; OD[r, $3] = ($6 == "true"); OA[r, $3] = $12 }   # C2: its author, the last column
      else if (t == "merged") { MG[r, $3] = $4; MGO[r, ++NMG[r]] = $3 }
      else if (t == "unread") { UNL[r, ++NUN[r]] = $3 SUBSEP $4 SUBSEP $5; if ($3 == "round") RB[r] = 1 }
      next }
    END {
      split("accepted building taken nobody unsent", SO_, " "); SW["accepted"] = "accepted"; SW["building"] = "being built"; SW["taken"] = "taken"; SW["nobody"] = "nobody has"; SW["unsent"] = "not sent yet"
      SAY["accepted"] = "Accepted"; SAY["building"] = "Being built"; SAY["taken"] = "Taken"; SAY["nobody"] = "Nobody has it"; SAY["unsent"] = "Not sent yet"
      # ---- the plan and the teams -------------------------------------------------------------------------------------------
      plan = "{\"releases\":[],\"hold\":{\"open\":0,\"others\":0,\"built\":0,\"rows\":[]}}"; teams = "[]"
      if (!AUTO && !NOPLAN) {
        # with exactly one lane, a step naming none is that lane'"'"'s, as the planner reads it
        if (nlan == 1) for (i = 1; i <= ns; i++) if (SL[SO[i]] == "-" || SL[SO[i]] == "") SL[SO[i]] = LS[TM[1], 1]
        if (PREV && RB["P"] && !PT) PREV = 0
        for (q in QN0) { n = tk("C", q); if (n != "") QN[n] += QN0[q] }
        for (i = 1; i <= ntc; i++) { split(TC[i], a, SUBSEP); if (names("C", a[1], a[2])) TADD[a[1]]++; else TDROP[a[1]]++ }
        # what is new since the last call: a ticket left out of the comparison is one a read holds an unread line of, or of its piece
        for (k = 1; k <= 2; k++) { r = (k == 1 ? "C" : "P"); for (i = 1; i <= NUN[r]; i++) { split(UNL[r, i], a, SUBSEP); if (a[2] == "-") continue; n = tk(r, a[2]); if (n != "") BAD[n] = 1 } }
        if (PREV) for (i = 1; i <= nt; i++) { n = TO[i]; if (!HAS["C", n] || (n in BAD)) continue; x = ""
          if (!HAS["P", n] || (TST["P", n] == "CLOSED" && TST["C", n] == "OPEN")) x = add(x, "opened")
          else if (TST["P", n] == "OPEN" && TST["C", n] == "CLOSED") x = add(x, "closed")
          if (!RB["C"] && !RB["P"] && taken("C", n) && !(HAS["P", n] && taken("P", n))) x = add(x, "taken")
          g = 0; c = 0; for (j = 1; j <= UT["C", n]; j++) { k = SK["C", n, j]; if (!(("P", n, k) in SS)) g++; if (SS["C", n, k] == "CLOSED" && SS["P", n, k] != "CLOSED") c++ }
          if (g) x = add(x, pl(g, "piece") " given"); if (c) x = add(x, pl(c, "piece") " done")
          if (!RB["C"] && !RB["P"]) {
            for (j = 1; j <= NOP_["C"]; j++) { p = OPO["C", j]; if (tk("C", OP["C", p]) == n && !(("P", p) in OP) && !(("P", p) in MG)) x = add(x, "pull request #" p " opened") }
            for (j = 1; j <= NMG["C"]; j++) { p = MGO["C", j]; if (tk("C", MG["C", p]) == n && !(("P", p) in MG)) x = add(x, "pull request #" p " merged") } }
          gsub(/,/, ", ", x); NEWS[n] = x }
        # the steps, then the tickets of a step the plan no longer holds, each by a key of its own
        for (i = 1; i <= nt; i++) { n = TO[i]; s = TS_[n]; if (!(s in INPLAN)) { s = "gone " TS_[n]; if (!(s in SID)) { SID[s] = TS_[n] == "-" ? "#" n : TS_[n]; SNM[s] = "a ticket of no step in the plan"; GONE[++ngone] = s } } SOF[n] = s; STK[s] = STK[s] (STK[s] == "" ? "" : " ") n }
        for (i = 1; i <= ns; i++) step_(SO[i])
        for (i = 1; i <= ngone; i++) step_(GONE[i])
        # what each step not accepted builds on: every step not accepted it reaches (REA)
        for (i = 1; i <= ns; i++) { s = SO[i]; if (ST[s] == "accepted") continue; nq = 0; split("", sn); m = split(SB[s], a, " "); for (j = 1; j <= m; j++) if ((a[j] in INPLAN) && !(a[j] in sn)) { sn[a[j]] = 1; qq[++nq] = a[j] }
          for (h = 1; h <= nq; h++) { x = qq[h]; if (x != s && ST[x] != "accepted") { REA[s, x] = 1; NRE[s]++; HU[x]++ } m = split(SB[x], a, " "); for (j = 1; j <= m; j++) if ((a[j] in INPLAN) && !(a[j] in sn)) { sn[a[j]] = 1; qq[++nq] = a[j] } } }
        for (i = 1; i <= ns; i++) { s = SO[i]; if (ST[s] == "accepted") continue; open++; if (!NRE[s] && HU[s]) { HR[++nhr] = s; FLAG[s] = flag(nhr) }
          for (j = 1; j <= ns; j++) { x = SO[j]; if (!((s, x) in REA)) continue; y = 0; for (h = 1; h <= ns; h++) if (((s, SO[h]) in REA) && ((SO[h], x) in REA)) { y = 1; break } if (!y) ON[s, ++NON[s]] = x } }
        for (i = 1; i <= ns; i++) { s = SO[i]; if (ST[s] == "accepted" || FLAG[s] != "") continue; others++; for (j = 1; j <= nhr; j++) if ((s, HR[j]) in REA) { built++; break } }
        # the releases
        ng = 0; split("", GS); for (i = 1; i <= ns; i++) { g = gs(SO[i]); if (!(g in GS)) { GS[g] = 1; GL[++ng] = g } }
        for (i = 1; i < ng; i++) for (j = i + 1; j <= ng; j++) if (GL[j] != -1 && (GL[i] == -1 || GL[j] < GL[i])) { x = GL[i]; GL[i] = GL[j]; GL[j] = x }
        print "5. The plan: " pl(ng, "release") ", " pl(ns + 0, "step") ", " pl(ntm, "team") > TX
        plan = "{\"releases\":["
        for (gi = 1; gi <= ng; gi++) { g = GL[gi]; split("", CC); nn = 0; fl = ""; nfl = 0; bs = ""; box = ""
          for (i = 1; i <= ns; i++) { s = SO[i]; if (gs(s) != g) continue; nn++; CC[ST[s]]++; if (ST[s] == "nobody" && FLAG[s] != "") { fl = fl (fl == "" ? "" : ", ") FLAG[s]; nfl++ } if (BLK[s] && ST[s] != "accepted") bs = bs (bs == "" ? "" : "; ") SNM[s]
            box = add(box, "{\"id\":" js(s) ",\"name\":" js(SNM[s]) ",\"state\":" js(ST[s]) ",\"fill\":" FILL[s] ",\"flag\":" js(FLAG[s]) "}") }
          say = ""
          if (CC["accepted"] == nn) say = "All accepted."
          else if (CC["unsent"] == nn) say = "None sent yet."
          else { if (CC["building"]) { w = who_(g, "building"); say = CC["building"] " being built" (w == "" ? "" : ", by " w) }
            if (CC["taken"]) { w = who_(g, "taken"); say = say (say == "" ? "" : "; ") CC["taken"] " taken" (w == "" ? "" : ", by " w) }
            if (CC["unsent"]) say = say (say == "" ? "" : "; ") CC["unsent"] " not sent yet"
            if (say != "") say = say "." }
          st = ""; if (CC["nobody"]) st = CC["nobody"] " sent and nobody has " (CC["nobody"] == 1 ? "it" : "them") (nfl ? "; " fl (nfl == 1 ? " waits" : " wait") " on nothing" : "") "."
          if (bs != "") st = st (st == "" ? "" : " ") "Blocked: " bs "."
          plan = plan (gi > 1 ? "," : "") "{\"n\":" g ",\"name\":" js(gn(g)) ",\"accepted\":" CC["accepted"] + 0 ",\"steps\":[" box "],\"say\":" js(say) ",\"stuck\":" js(st) ",\"words\":" js(g in RW ? RW[g] : "") "}"
          print rname(g) ": " CC["accepted"] + 0 " of " pl(nn, "step") " accepted." (say == "" || say == "All accepted." ? "" : " " say) (st == "" ? "" : " " st) (g in RW ? " " RW[g] : "") > TX }
        plan = plan "],\"hold\":{\"open\":" open + 0 ",\"others\":" others + 0 ",\"built\":" built + 0 ",\"rows\":["
        if (nhr) print "What holds the rest up: " pl(nhr, "step") "; " pl(open, "step") " not accepted, and " built + 0 " of the other " others + 0 " build on " (nhr == 1 ? "it" : "them") "." > TX
        for (i = 1; i <= nhr; i++) { s = HR[i]
          plan = plan (i > 1 ? "," : "") "{\"flag\":" js(FLAG[s]) ",\"id\":" js(s) ",\"name\":" js(SNM[s]) ",\"who\":" js(WHO[s]) ",\"done\":" DN[s] ",\"pieces\":" PC[s] ",\"state\":" js(ST[s]) ",\"days\":" DAYS[s] ",\"by\":" HU[s] + 0 "}"
          print FLAG[s] ". " SNM[s] " (" s "): " (WHO[s] != "" ? WHO[s] : ST[s] == "unsent" ? "not sent yet" : ST[s] == "nobody" ? "nobody has it, " pl(DAYS[s], "day") : SW[ST[s]]) (PC[s] ? ", " DN[s] " of " pl(PC[s], "piece") " done" : "") "; " HU[s] + 0 " build on it" > TX }
        plan = plan "]}}"
        # the teams, each its releases, each the tracks of the team; a lane no team holds, then a ticket of no step, after
        teams = ""; for (i = 1; i <= ns; i++) STT[SO[i]] = (SL[SO[i]] in LT) ? LT[SL[SO[i]]] : ""
        for (ti = 1; ti <= ntm + 2; ti++) { tm = (ti > ntm ? "" : TM[ti]); nn = 0; split("", A)
          if (ti == ntm + 2) for (i = 1; i <= ngone; i++) A[++nn] = GONE[i]; else for (i = 1; i <= ns; i++) if (STT[SO[i]] == tm) A[++nn] = SO[i]
          if (ti > ntm && !nn) continue
          tn = (ti <= ntm ? nm(tm) : ti == ntm + 1 ? "Lanes no team of the setup holds" : "Tickets of no step in the plan"); tw = (ti == ntm + 2 ? pl(nn, "ticket") : tally(A, nn)); rel = ""
          print ++sec + 5 ". " (ti <= ntm ? "Team " : "") tn ": " tw > TX
          if (ti == ntm + 2) { cs = ""; for (i = 1; i <= nn; i++) { cs = add(cs, card(A[i])); tline(A[i]) } rel = "{\"n\":-1,\"name\":\"\",\"words\":\"\",\"tracks\":[{\"name\":\"\",\"cards\":[" cs "]}]}" }
          else for (gi = 1; gi <= ng; gi++) { g = GL[gi]; split("", G_); n = 0; for (i = 1; i <= nn; i++) if (gs(A[i]) == g) G_[++n] = A[i]
            if (!n) continue
            print "  " rname(g) ": " tally(G_, n) > TX; trk = ""; nlg = 0; split("", LG)
            if (ti <= ntm) { nlg = NL[tm]; for (j = 1; j <= nlg; j++) LO_[j] = LS[tm, j] } else for (i = 1; i <= n; i++) if (!(SL[G_[i]] in LG)) { LG[SL[G_[i]]] = 1; LO_[++nlg] = SL[G_[i]] }
            for (j = 1; j <= nlg; j++) { cs = ""; for (i = 1; i <= n; i++) if (SL[G_[i]] == LO_[j]) { cs = add(cs, card(G_[i])); tline(G_[i]) }
              trk = add(trk, "{\"name\":" js(ti > ntm ? "lane " LO_[j] : NL[tm] == 1 ? nm(tm) : nm(tm) ", track " j) ",\"cards\":[" cs "]}") }
            rel = add(rel, "{\"n\":" g ",\"name\":" js(gn(g)) ",\"words\":" js(tally(G_, n)) ",\"tracks\":[" trk "]}") }
          teams = add(teams, "{\"name\":" js(tn) ",\"kind\":" js(ti > ntm ? "other" : "team") ",\"area\":" js(ti > ntm || TAR[tm] == "-" ? "" : TAR[tm]) ",\"words\":" js(tw) ",\"releases\":[" rel "]}") }
        teams = "[" teams "]" }
      printf "\"plan\":%s,\n\"teams\":%s}\n", plan, teams > BD
      # ---- the sort, as it stands -------------------------------------------------------------------------------------------
      todo = ""; wait = ""; chg = ""
      for (i = 1; i <= nl; i++) { k = LK[i]; w = V[i, "what"]; if (w == "") w = V[i, "title"]
        if (k == "todo") { m = split(LI[i], b, ","); x = ""; for (j = 1; j <= m; j++) x = add(x, js(b[j])); y = ""
          for (j = 1; j <= NA[i]; j++) { z = ""; for (h = 1; h <= NC[i, j]; h++) z = add(z, js(ACH[i, j, h])); y = add(y, "{\"ask\":" js(AQ[i, j]) ",\"about\":" js(AB[i, j]) ",\"choose\":" AP[i, j] + 0 ",\"why\":" js(AW[i, j]) ",\"choices\":[" z "],\"message\":" js(AM[i, j]) "}") }
          todo = add(todo, "{\"n\":" js(LN[i]) ",\"ids\":[" x "],\"title\":" js(V[i, "title"]) ",\"do\":" js(V[i, "do"]) ",\"isNew\":" (V[i, "new"] == "" ? "false" : "true") ",\"new\":" js(V[i, "new"]) ",\"what\":" js(V[i, "what"]) ",\"asks\":[" y "],\"then\":" js(V[i, "then"]) ",\"details\":" js(V[i, "details"]) "}") }
        else if (k == "waiting") wait = add(wait, "{\"who\":" js(V[i, "who"]) ",\"what\":" js(w) ",\"since\":" js(V[i, "since"]) ",\"details\":" js(V[i, "details"]) "}")
        else if (k == "changed") chg = add(chg, js(w))
        else if (k == "later") R["later"] = add(R["later"], "{\"when\":" js(V[i, "then"]) ",\"what\":" js(w) "}")
        else if (k != "plan") R[k] = add(R[k], js(w)) }
      hold = ""; for (i = 1; i <= nh; i++) { x = HO[i]; hold = add(hold, "{\"id\":" js(x) ",\"words\":" js(HW[x]) ",\"where\":" js((x in UNS) || !(x in AT) ? "not sorted yet" : AT[x]) "}") }
      # the counts, as the call printed them, each with what it means
      M["total"] = "tests not with the team as they stand now, each counted once"; M["to-place"] = "of them with no step yet"; M["added"] = "of them added since the version the team has"; M["retired"] = "of them retired since the version the team has"
      M["restated"] = "of them reworded since their ticket was written"; M["reset"] = "of them changed since the version the team has, in no ticket"; M["unpublished"] = "of them in no ticket sent yet"
      M["critical"] = "changes that call for a re-plan now"; M["important"] = "changes that may call for a re-plan, new or changed at the last call"; M["unchanged"] = "such changes, as they were at an earlier call"; M["minor"] = "small changes, taken in at the next re-plan"; M["declined"] = "such changes you declined"
      cnt = ""; for (i = 1; i <= ncnt; i++) { k = CK[i]; if (k == "total" || CNT[k] + 0) cnt = add(cnt, "{\"n\":" CNT[k] + 0 ",\"words\":" js((k in M) ? M[k] : k) "}") }
      n = split("critical important unchanged minor declined", a, " "); for (i = 1; i <= n; i++) if (TIER[a[i]] + 0) cnt = add(cnt, "{\"n\":" TIER[a[i]] + 0 ",\"words\":" js(M[a[i]]) "}")
      if (nux) { x = ""; for (i = 1; i <= nux; i++) x = x (i > 1 ? "; " : "") UX[i]; cnt = add(cnt, "{\"n\":" nux ",\"words\":" js((nux == 1 ? "part" : "parts") " could not be read at the last call, and nothing is counted from " (nux == 1 ? "it" : "them") ": " x) "}") }
      if (nrp) { x = ""; for (i = 1; i <= nrp; i++) x = x (i > 1 ? "; " : "") RPX[i]; cnt = add(cnt, "{\"n\":" nrp ",\"words\":" js("of the team\047s report branches left out, and nothing of them counted: " x) "}") }
      if (NOPLAN) cnt = add(cnt, "{\"n\":1,\"words\":\"plan could not be read: the plan and the teams are as last worked out\"}")
      print "{\"format\":1,\"written\":" js(NOWT) ",\"title\":" js(TITLE) ",\"state\":" js(STATE == "" ? "none" : STATE) ",\"sortedAt\":" js(SAT) ",\"unsorted\":" nun + 0 "," > HD
      print "\"todo\":[" todo "],\"waiting\":[" wait "],\"changed\":[" chg "]," > HD
      print "\"rest\":{\"vid\":[" R["vid"] "],\"later\":[" R["later"] "],\"team\":[" R["team"] "],\"suggested\":[" R["suggested"] "],\"leftOut\":[" R["left-out"] "],\"holds\":[" hold "],\"counts\":[" cnt "]}," > HD
    }' "$T/f"
  # a plan that could not be read: the plan and the teams last written stand
  if [ -n "$NOP" ] && [ -f "$LJ" ] && grep -q '^"plan":' "$LJ" && grep -q '^"teams":.*}$' "$LJ"; then grep -E '^"(plan|teams)":' "$LJ" > "$T/board"; fi; }

LN=${2:-.vid/next/lines}
case "${1:-}" in
  write) [ $# -le 2 ] || die 'usage — sh checks/next-page.sh write|text [<lines file>]'; [ $# -lt 2 ] || [ -f "$2" ] || ref "no lines file at $2"
    make "$LN"; mkdir -p .vid/face || ref 'cannot write .vid/face'; cat "$T/head" "$T/board" | put "$LJ" || ref "$LJ could not be written"; echo "list $LJ"; [ -z "$NOP" ] || exit 1 ;;
  text) [ $# -le 2 ] || die 'usage — sh checks/next-page.sh write|text [<lines file>]'; [ $# -lt 2 ] || [ -f "$2" ] || ref "no lines file at $2"
    manual || ref 'the plan and the teams are GitHub manual'"'"'s (lib.sh manual)'
    make "$LN"; [ -z "$NOP" ] || exit 1; cat "$T/text" ;;
  *) die 'usage — sh checks/next-page.sh write|text [<lines file>]' ;;
esac
