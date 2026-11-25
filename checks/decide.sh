#!/bin/sh
# Purpose: ViD's decision and the hold (v0.26.10.24.6). From the results reader's evidence it decides each row of a ticket, and the
# ticket; posts the decision on the pull request; counts the hold; puts what needs the owner on one queue page; records the
# owner's answers; and keeps merged, held and failing rows in .vid/tw/handed, where admission and the writer read them. It reads
# the evidence file, the published ticket, INVENTORY.md and .vid/decide/, and through github.sh the blocked label. It reads no
# code, runs nothing and starts no agent. A decision names reports, never their words, so no comment cites a file of the code.
#   decide --ticket <n> --pr <p> --head <commit> [--post]   writes .vid/decide/pr-<p>-<head12>.txt, the comment, and prints it;
#       with --post it posts that once a head, and again only if it changed. Refused, exit 1, with no evidence file for that head
#       FB-3 A1.3: --dry, in place of --post: decides nothing and writes nothing; prints `review` when the decision would be `accepted` but for
#       ViD's own review of the ticket, else nothing; FB-5 B1.8: and each `no Decisions section — #<p>` line
#   merged --pr <p>                                         that pull request's merge: its rows enter .vid/tw/handed
#   umap [--withdrawn]   (GM-4 E4, E9) each line of .vid/decide/unit-merges with its ticket as E4 maps it, `<p> TAB <ticket or -> TAB
#       <head> TAB <merge>`; --withdrawn keeps a withdrawn ticket as the unit's. Reads only
#   decide --ticket <n> --at <commit> [--post]   GM-4 E2 (GitHub manual, GM M8: only a ticket is decided, at a commit of main): the same
#       rules, every file keyed step-<n>-<commit12> where a pull request's is pr-<p>-<head12> (last-step-<n>, posted-step-<n>-<commit12>,
#       the evidence .vid/results/step-<n>-<commit12>.txt), `step-<n>` in the records' pull request column; the blocked label read on the
#       ticket's issue alone, from the call's read (.vid/round/read); the post one comment on the ticket's issue (github.sh comment).
#       A pull request of .vid/decide/unit-merges mapped to the ticket (its ticket line, or its sub-issue tree in the read's sub lines),
#       merged at or before the commit, whose description has no Decisions section, makes it `not yet`, one line
#       `no Decisions section — #<p>` each, against no row; the descriptions read again at each decision
#       FB-5 B1.4: the commit may be the head of the ticket's own pull request whose ask stands in .vid/decide/pr-asks: that pull request's description is
#       read too; the decision is posted on it (github.sh decide-post), its request lines, the first time, on the ticket too; with the issue closed
#       in the read the label is read by github.sh decide-blocked; and no accepted-at line is written: merged --ticket writes it, at the merge
#   merged --ticket <n>                                     GM-4 E4: the ticket's acceptance as its merge, from its newest decision:
#       its rows enter .vid/tw/handed as a pull request's do, and a skeleton's head report's engines (results.sh declare)
#   outside --ticket <n> --at <commit> --words "<w>" [--note "<why this commit>"] | outside --rows "<ids and ranges>" --words "<w>"   FB-3 A4, both modes: rows the owner
#       accepted outside ViD, a published ticket's or ones no published ticket holds, by their words alone: each, and each transition,
#       `accepted by ruling` in rulings and state, and in .vid/tw/handed, labelled with the words (FB-3 E1: and the note, ending
#       `; evidence: none, accepted outside ViD`); a deploy-owed one `owed`, with no ruling;
#       a known limit, a retired one, a record and one accepted already left, `left <row>: <why>`; each on the record; for a ticket its
#       accepted-at line; one `accepted-outside` event. Refused, nothing written: no words, no row, a row not in the inventory, and, of --rows, one
#       of a published ticket. It reads the plan's rows (planner.sh rows) and the log, and posts nothing; round.sh accept writes the merge lines
#   queue                                                   .vid/decide/queue.html: the headline, each held row with its record
#       and the four answers, the findings ranked
#   rule <row> accept|limit|amend|more <n> [--by <who>]   records the owner's answer for a held row; limit takes any row a decision has read
# .vid/decide/: counts (<row> <head12 or report id>, once each), limits (<row> <n>), rulings (date, row, word, words, who; tab),
# log (date, pull request, head12, row, state; tab), state (each row's newest decision), rows/<row>.txt (its record),
# pr-<p>-<head12>.rows (row, journey, state, what stands under a hold, fault, line, undone, t3, what it has failed as on this pull request, w or p, 1 when a later head must shrink past it, the same before this head; tab), last-pr-<p>
# v0.26.10.24.7: a row's state comes from runs alone. halted (pull request, row, i for an inconclusive fault): rows held until a ruling, by the shrink or an inconclusive fault;
# 0.26.11.1.4 (R3): an inconclusive fault's hold also until a later head that proves the row (accepted or passing), its line dropped then
# (head), record (the rows truly on the handed record, merged or there before a decision: a row held or failing beside them is not).
# v0.26.10.25.3: the evidence's engine lines, the split line and engine-split in .vid/tw/handed once a row (R11), analyst due once a ticket (R12):
# analyst (ticket, head12: the head whose decision says it).
# v0.26.10.25.4: a regression row a close found red, its fix not merged (close.sh owned), reads "its state stands" where it fails: no count, no stop,
# and no change to its line in the handed record but in a ticket of its own.
# v0.26.10.26.3 (R2): accepted-at (pull request, ticket, head12, at=<UTC>): one line a ticket, the first time a decision reads `ticket: accepted`;
# a decision file is overwritten at each decision, so this line alone keeps the time.
# v0.26.10.25.5 (R4): an id landed after a ticket was published (.vid/decide/landed) is decided from none of its evidence, and a merge takes
# nothing for it from a decision made before its landing. A `reset` ruling, the landing's, reads as none.
# FB-3 A1 (GitHub manual): a row passed in the team's own results at the commit is accepted: no red, no break, no covers: line is asked; a row with no
# case there is `evidence missing`, with no count, and the commit it passed at elsewhere named. The grade and the sort are ViD's own review's, one
# a ticket (none for a reached ticket or one that follows another): without it alone, `review missing — …`. Each `test it` line of its sort is a
# `request <row> — <its words>` line of the ticket's first decision after the review, held by `requests open` that once
# (requested-step-<n>, the commit12); a reviewer's words may name a file, the one exception to a decision's naming reports alone. The Decisions
# section holds a ticket whose published writing asks for it; another is told.
# FB-3 A2: a decision that reads `not yet` names each report branch of the ticket's left out, `report left out — vid-results/<id>: <why>`.
# 0.26.10.29.5 (DP-1 R8): it reads the pull request's description too, through github.sh pr-body: with no Decisions section (neither the
# line `Decisions: none` nor a `Decisions:` line with a `- ` line under it) the decision reads `ticket: not yet` with the one line
# `decisions missing — the pull request's description has no Decisions section, nor Decisions: none`, against no row; no row's state,
# count or hold moves for it, and the same head asked again once the section is there is answered without it.
# serves: tickets (0.26.10.28.4, M9)
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
die() { echo "ViD decide: $*" >&2; exit 2; }
ref() { echo "ViD decide: refused — $*" >&2; exit 1; }
D=.vid/decide; mkdir -p "$D/rows"; T=$(mktemp -d "$PWD/$D/tmp.XXXXXX"); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
touch "$D/counts" "$D/limits" "$D/rulings" "$D/log" "$D/state" "$D/record" "$D/halted" "$D/analyst" "$D/accepted-at"
# hset <row> <word> [fault-proven] [<label>]: the row's one line in the handed record, its mark kept; held keeps its row, whatever a transition's answer
hset() { mkdir -p .vid/tw; touch .vid/tw/handed; m=${3:-}; l=${4:-decision}; [ -n "$m" ] || m=$(sed -n "s/^row $1 [^ ]* \(fault-proven\).*/\1/p" .vid/tw/handed | tail -n 1)
  { grep -v "^row $1 " .vid/tw/handed || true; printf 'row %s %s%s | stand-in: %s\n' "$1" "$2" "${m:+ $m}" "$l"; } > "$T/h" || exit 1; put .vid/tw/handed < "$T/h" || exit 1; }
word() { sed -n "s/^row $1 \([^ |]*\).*/\1/p" .vid/tw/handed 2>/dev/null | tail -n 1; }
hdrop() { { grep -v "^row $1 " .vid/tw/handed || true; } > "$T/h" || exit 1; put .vid/tw/handed < "$T/h" || exit 1; }
onrec() { grep -qxF "$1" "$D/record"; }
# the items of the seventh column, row TAB item: from the inventory, or where none is from the ticket
# GM-4 E12: in GitHub manual the inventory at the applied commit (lib.sh applied), so no decision carries a pending change
invat_() { if manual; then _a=$(applied); [ -n "$_a" ] && git show "$_a:INVENTORY.md" 2>/dev/null; else cat INVENTORY.md; fi; }
items() { { if [ -f INVENTORY.md ]; then invat_ | sed -n 's/^\(ROW-[0-9]\)/> \1/p'; else cat "$1"; fi; } | awk -F'|' '/^> ROW-[0-9]/ { a = $1; sub(/^> */, "", a); gsub(/[ \t]/, "", a); n = split($7, w, /[ ,\t]+/); for (i = 1; i <= n; i++) if (w[i] != "") print a "\t" w[i] }'; }
# the decision: a table, read off the evidence lines. Inputs by -v; writes the comment to CO, the rows to RO, the counts back to CF
DE='function why(a, b) { return (a == "") ? b : (b == "") ? a : a "; " b }
  function sibs(b,   i, it, k, s, n, o, x) { s = ""; n = 0
    for (k in own) { split(k, x, SUBSEP); if (x[1] != b) continue; it = x[2]; for (i = 1; i <= ni; i++) if (irow[i] != b && item[i] == it && !((b, irow[i]) in done)) { done[b, irow[i]] = 1; o[++n] = irow[i] } }
    for (i = 2; i <= n; i++) { x[1] = o[i]; k = i - 1; while (k > 0 && o[k] > x[1]) { o[k + 1] = o[k]; k-- } o[k + 1] = x[1] }
    for (i = 1; i <= n; i++) s = s o[i] ", "; split("", done); return " — siblings: " s (n ? "and " : "") "any other test with the same data pattern" }
  function heldby(r, b,   k) { if (b != r && rul[b] != "limit" && cnt[b] + 0 >= ((b in lim) ? lim[b] : 2)) return 1; for (k in cnt) if (index(k, r "-T") == 1 && rul[k] != "limit" && cnt[k] + 0 >= ((k in lim) ? lim[k] : 2)) return 1; return 0 }
  function earlier(r,   f, l, a, v, g) { f = RD "/" r ".txt"; v = ""; g = ""; while ((getline l < f) > 0) { split(l, a, "\t"); if (a[3] == "answered") { if (g != "") v = " — earlier: " g ", answered by " a[2]; g = "" } else if (a[3] == "failing") { g = a[4]; sub(/ — (siblings|earlier):.*$/, "", g); sub(/^held — /, "", g); sub(/^failing, /, "", g) } } close(f); return v }
  # FB-7 C6: nocase, whether a missing row is so for want of a case: a part of its reason, but `T2: no case` of a row whose tests-first run held none
  function nocase(x, rd0,   n, w, j) { n = split(x, w, /; /); for (j = 1; j <= n; j++) if (w[j] ~ /^no case( in [^ ]+)?$/ || (rd0 == "n/a" && w[j] ~ /^T[0-9]+: no case( in [^ ]+)?$/)) return 1; return 0 }
  BEGIN { FS = "\t"; SP = 0; NCW = "evidence missing — no case of it in the results at this commit (a test is found by the row\047s id in its name)"
    while ((getline l < CF) > 0) { split(l, x, " "); cnt[x[1]]++; if (x[2] ~ /-/) ev[x[1]]++; have[x[1] " " x[2]] = 1; c0[++n0] = l }
    while ((getline l < LF) > 0) { split(l, x, " "); lim[x[1]] = x[2] }
    while ((getline l < UF) > 0) { split(l, x, "\t"); rul[x[2]] = x[3] } while ((getline l < SF) > 0) { split(l, x, "\t"); sf[x[1]] = x[2] } while ((getline l < HF) > 0) { split(l, x, "\t"); hal[x[2]] = (x[3] == "") ? 1 : 2 }
    while ((getline l < NCF) > 0) noc[l] = 1   # GM-4 E3: amended since the decision before, so its fault proof is not carried
    while ((getline l < PF) > 0) { split(l, x, "\t"); b1 = x[1]; sub(/-T[0-9]+$/, "", b1); pf[x[1]] = x[3]; pv[x[1]] = ((x[1] in noc) || (b1 in noc)) ? "" : x[5]; sb[x[1]] = (PH == H) ? x[11] : x[9]; if (x[10] == 1) { was[x[1]] = 1; nw++ }; NQ[x[1]] = (MAN == "" && x[6] == NCW) }   # FB-7 C6: NQ, a row with no case then, which by itself owes no break; one owed before it is kept owed (nc, below)
    while ((getline l < IF) > 0) { split(l, x, "\t"); ni++; irow[ni] = x[1]; item[ni] = x[2]; own[x[1], x[2]] = 1 } while ((getline l < OWF) > 0) cfl[l] = 1; while ((getline l < STF) > 0) stl[l] = 1 }
  /^ticket [0-9]+, pull request / { HEAD = $0; sub(/^.* head /, "", HEAD); next } /^ticket [0-9]+, at / { HEAD = $0; sub(/^.* at /, "", HEAD); next }
  /^request: / { RQL[++nrq] = substr($0, 10); next }
  $1 == "near" && NF == 3 { NE[$2] = $3; next } $1 == "fin" && NF == 3 { FN[$2] = $3; gsub(/ /, ", ", FN[$2]); next }
  /^report / { split($0, w, " "); st = w[4]; sub(/:$/, "", st); if (w[2] == "T2") { if (w[3] == "none") t2 = "red-" N; else t2 = w[3] } else if (w[2] == "head") { nhd++; hs = (w[3] == "none") ? "none" : st; hid = (w[3] == "none") ? KP "-" H : w[3] } else if (w[2] == "sort") { gs = (w[3] == "none") ? "none" : st; gid = w[3] } else if (w[2] == "grade") { gg = (w[3] == "none") ? "none" : st; ggid = w[3] } else if (w[2] == "skipped") SKL[++nsk] = w[3] ": " substr($0, 17 + length(w[3])); next }
  /^open grade line: / { if (rul[substr($0, 18)] != "limit") ol = 1; next }
  /^list: / { ls[substr($0, 7)] = 1; next }
  /^retested: / { for (j = 2; j <= split($0, w, " "); j++) { sent[w[j]] = 1; rt[w[j]] = 1 } next }
  /^engine [^ ]+: [0-9]+ could not run$/ { eg[++neg] = $0; next }
  $1 == "split" && NF == 4 { print $2 "\t" $3 " " $4 > SPF; nsp++; ns2 = split($3 " " $4, w, " "); for (j = 1; j <= ns2; j++) if (!(w[j] in se)) { se[w[j]] = 1; SE = SE (SE == "" ? "" : " ") w[j] } next }
  /^setup errors [^ ]+: [0-9]+ cases over [0-9]+ runs$/ { split($0, w, " "); if (w[4] + 0 > an) { an = w[4] + 0; ae = w[3]; sub(/:$/, "", ae); ak = w[7] } next }
  NF == 6 { b0 = $1; sub(/-T[0-9]+$/, "", b0); if (($1 in stl) || (b0 in stl)) next; i = ++n; r[i] = $1; ki[i] = $2; rd[i] = $3; t[i] = $4; f[i] = $5; re[i] = $6; nc[i] = ($4 == "missing" && (MAN != "" || nocase($6, $3))); next }
  END { if (hid == "") { hid = KP "-" H } if (MAN != "" && nhd > 1) hid = "results-at-" H
    for (i = 1; i <= n; i++) { R = r[i]; B = R; sub(/-T[0-9]+$/, "", B); if ((t[i] == "failed" || nc[i]) && ki[i] == "regression") { nl = split(re[i], w, /; /); ok = 1; hl = 0; for (j = 1; j <= nl; j++) if (w[j] ~ /^T[0-9]+: no case( in [^ ]+)?$/ && rul[R "-" substr(w[j], 1, index(w[j], ":") - 1)] == "limit") hl = 1; else if (w[j] !~ /^no case( in [^ ]+)?$/) ok = 0; if (ok && hl) { t[i] = "passed"; nc[i] = 0 } }
      rc = (pf[R] == "failing" || (pf[R] == "evidence missing" && !NQ[R]) || (R in sent) || (B in sent) || t[i] == "failed" || t[i] == "setup"); if (pv[R] ~ /^proven/ ? (!(R in rt) && !(B in rt) && f[i] !~ /^(proven|not-proven)/ && (!rc || (f[i] ~ /^(n\/a|waits|inconclusive)/ && !(MAN == "" && nc[i])))) : (pv[R] ~ /^inconclusive/ && !rc && f[i] ~ /^(n\/a|missing|waits)/)) f[i] = pv[R]; else if (pv[R] ~ /^proven/ && f[i] ~ /^missing/ && !(R in rt) && !(B in rt)) kp[i] = pv[R]; if (f[i] ~ /^proven/) anyp = 1 }
    for (i = 1; i <= n; i++) { R = r[i]; B = R; sub(/-T[0-9]+$/, "", B); fe = (f[i] ~ / extra$/); fv = f[i]; sub(/ extra$/, "", fv); ih = 0
      prod = 0; weak = 0; fr = ""; mr = ""; K = ""
      if (t[i] == "failed") { prod = 1; fr = why(fr, "its test failed, " ((R in FN) ? FN[R] : hid)) }
      if (fv == "not-proven") { weak = 1; fr = why(fr, "its fault not proven, " hid) }
      if (rd[i] == "missing") { tk = (match(re[i], /T2 [^ ,:]+/) ? substr(re[i], RSTART + 3, RLENGTH - 3) : t2); mr = why(mr, "T2 refused, " tk); K = K " " tk }
      if (t[i] == "setup") { mr = why(mr, "its test could not run, " hid); K = K " " hid }
      # FB-3 A1.2, FB-7 C6: a row with no case in the results at the commit is not tested yet: no count is spent on it (GitHub manual, each row its results lack; GitHub auto, not one with no covers: line beside it)
      if (nc[i] && (MAN != "" || !index("; " re[i] ";", "; no covers: line;"))) { w0 = (MAN != "" && hs != "read") ? "no results at this commit" : index(re[i], "since its amendment") ? "no case in results sent since its amendment" : index(re[i], "no case ran") ? "no case of it ran at this commit" : "no case of it in the results at this commit"; mr = why(mr, w0 ((R in NE) ? "; passed at " NE[R] ", not at this commit" : "") (w0 ~ /^no case of it in/ ? " (a test is found by the row\047s id in its name)" : "")) }
      else if (t[i] == "missing") { w0 = index(re[i], "no covers:") ? "no covers: line, " : (hs == "refused") ? "report refused, " : "no head report, "; mr = why(mr, w0 hid); K = K " " hid }
      if (!fe && fv == "missing" && !(KD == "skeleton" && anyp)) { mr = why(mr, "no fault folder, " hid); if (!index(K, " " hid)) K = K " " hid }
      S = ""; undo = 0
      if (rul[R] == "limit") S = "known limit"; else if (rul[R] == "accept") { if (t[i] == "failed" || t[i] == "setup") undo = 1; else if (MAN != "" || !nc[i]) S = "accepted by ruling" }
      if (S == "" && ki[i] == "regression" && (B in cfl) && (t[i] == "failed" || t[i] == "setup" || nc[i])) { S = "its state stands"; prod = 0; weak = 0 }
      if (S == "") { if (prod || weak) S = "failing"; else if (mr != "") S = "evidence missing"; else if (BL != "") S = "question open"
        else if (t[i] == "owed") S = (ki[i] != "regression" || index(re[i], "retested")) ? "owed" : "its state stands"
        else if (ki[i] == "regression" || ki[i] == "retested") S = "passing"
        else if (MAN != "" || rd[i] == "red" || fv == "proven" || (KD == "skeleton" && anyp)) S = "accepted"; else { S = "evidence missing"; if (fv == "inconclusive") { ih = 1; mr = "fault inconclusive, " hid } else mr = "no red and no proven fault" } }
      L = (R in lim) ? lim[R] : 2; wash = (cnt[R] + 0 >= L && sf[R] == "held"); ruled = (S == "known limit" || S == "accepted by ruling"); s0 = sb[R]; fst = (S == "failing" && (s0 == "" || (prod && !index(s0, "p")))); fp = (fst && sf[R] != "held")
      if (!ruled) { if (S == "failing") { if (!(R " " H in have)) { have[R " " H] = 1; cnt[R]++; ad[++na] = R " " H } } else if (S == "evidence missing") { nk = split(K, kk, " "); for (j = 1; j <= nk; j++) if (!(R " " kk[j] in have)) { have[R " " kk[j]] = 1; cnt[R]++; ev[R]++; ad[++na] = R " " kk[j] } } }
      if ((S == "accepted" || S == "passing") && (R in hal) && hal[R] == 2) { delete hal[R]; print R > HX }   # 0.26.11.1.4 (R3): a head that proves the row releases its inconclusive halt
      if ((S == "accepted" || S == "passing" || S == "accepted by ruling") && !wash && !(R in hal)) { cnt[R] = 0; drop[R] = 1 }
      FI = S; if (ih && !(R in hal)) { hal[R] = 2; print P "\t" R "\ti" >> HN } if (!ruled && S != "its state stands" && ((((S == "evidence missing" && sf[R] != "held") ? ev[R] : cnt[R]) + 0 >= L && !fp) || heldby(R, B) || (R in hal))) FI = "held"
      if (S == "failing") TX = "failing, a " (prod ? "product failure" : "weak test") " — " why(fr, mr) (weak ? sibs(B) : "") earlier(R); else if (S == "evidence missing") TX = S " — " mr; else TX = S
      if ((R in hal) && hal[R] == 1) TX = "held — it did not shrink — " TX; else if (FI == "held") TX = (S == "failing" || S == "evidence missing" || S == "question open") ? "held — " TX : "held — it passes at this head, and waits on an answer"
      FIa[i] = FI; TXa[i] = TX; Sa[i] = S; pa[i] = prod; ua[i] = undo; Ba[i] = B; s0a[i] = s0; se[i] = s0 ((S == "failing" && !index(s0, prod ? "p" : "w")) ? (prod ? "p" : "w") : ""); fs[i] = (S == "failing" && (PH != H || (R in was) || (pf[R] != "failing" && pf[R] != "held"))); mv = (S == "failing" && prod && !index(s0, "p") && ((R in was) || (R in ls))); if (S == "failing" && !mv) { nn++; rs[i] = 1 } }
    if (PH != "" && PH != H && nw && nn && nn >= nw) for (i = 1; i <= n; i++) if (rs[i] && !(r[i] in hal)) { hal[r[i]] = 1; print P "\t" r[i] >> HN; FIa[i] = "held"; sub(/^held — /, "", TXa[i]); TXa[i] = "held — it did not shrink — " TXa[i] }
    for (i = 1; i <= n; i++) { R = r[i]; B = Ba[i]; FI = FIa[i]; TX = TXa[i]; S = Sa[i]; prod = pa[i]; undo = ua[i]
      if (FI == "failing" && prod) SP = 1; if (FI == "held" && S == "failing" && prod) SP = 1
      if (FI !~ /^(accepted|accepted by ruling|owed|known limit|passing|its state stands)$/) NOT = 1
      print R "\t" B "\t" FI "\t" S "\t" ((i in kp) ? kp[i] : f[i]) "\t" TX "\t" undo "\t" t[i] "\t" se[i] "\t" fs[i] "\t" s0a[i] > RO
      LN[i] = R " " TX; JB[i] = (R != B) ? B : ""; if (R != B && FI !~ /^(accepted|accepted by ruling|owed|known limit|passing|its state stands)$/) JN[B] = 1
      f2 = RD "/" R ".txt"; o = 0; dup = 0; while ((getline l < f2) > 0) { split(l, a, "\t"); o = (a[3] != "answered"); if (a[2] == H && a[4] == TX) dup = 1 } close(f2)
      if ((S == "failing" || S == "evidence missing") && !dup) { print NOWT "\t" H "\t" S "\t" TX >> f2; close(f2) } else if ((S == "accepted" || S == "passing" || S == "owed") && o) { print NOWT "\t" H "\tanswered" >> f2; close(f2) } }
    # FB-3 A1.4 (GitHub manual): the review is ViD own, once; RVF, for --dry, says the decision lacks it alone. A `test it` line of its sort asks an added test, once
    if (MAN != "") { if (KD != "reached" && FW == "") { if (gg != "read") SL = "review missing — " ((NONE != "") ? "no merged pull request names this ticket" : (gg == "refused") ? "ViD\047s own review could not be read, " ggid : "ViD\047s own review of this ticket is not made yet"); else if (ol && gs != "read") SL = "review missing — the lines ViD\047s own review left open are not sorted yet" }
      if (RQH != "" && nrq) NOT = 1 }
    else if (KD != "reached" && FW == "") { if (gg != "read") SL = "sort evidence missing — " ((gg == "refused") ? "grade report refused, " ggid : "no grade report"); else if (ol && gs != "read") SL = "sort evidence missing — " ((gs == "refused") ? "sort report refused, " gid : "no sort report"); if (SL != "") NOT = 1 } if (BL != "" || n == 0) NOT = 1
    if (DMS != "") NOT = 1   # 0.26.10.29.5 (DP-1 R8): a description with no Decisions section: a line of the ticket, against no row
    while ((getline l < DMF) > 0) { DML[++ndm] = l; if (DMT == "" && TRU == "") NOT = 1 }   # GM-4 E2: a unit merged under the ticket with no section, a line each
    if (MAN != "" && SL != "") { if (NOT) SL = ""; else { if (NONE == "") print "review" > RVF; NOT = 1 } }   # not yet for another reason: no review is asked
    printf "vid: decision %s\nticket: %s\n", HEAD, (NOT ? "not yet" : "accepted") > CO
    for (i = 1; i <= n; i++) { print LN[i] >> CO; if (JB[i] != "" && JB[i + 1] != JB[i]) print JB[i] " " ((JB[i] in JN) ? "not accepted, by a transition above" : "accepted") >> CO }
    for (i = 1; i <= neg; i++) print eg[i] >> CO
    if (KD != "skeleton" && (nsp || (SPH + 0 && NASK + 0 < split(DECL, w, " ")))) { AL = DECL; nd = split(SE, w, " "); for (j = 1; j <= nd; j++) if (index(" " DECL " ", " " w[j] " ") == 0) AL = AL (AL == "" ? "" : " ") w[j]; print "split — every engine is now asked: " AL >> CO }
    if (an >= 5 && (AH == "" || AH == H)) { print "analyst due — " ae ", " an " cases could not run over " ak " runs" >> CO; if (AH == "") print N "\t" H > ANF }
    if (SL != "") print SL >> CO; if (DMS != "") print "decisions missing — the pull request\047s description has no Decisions section, nor Decisions: none" >> CO; if (TRU == "") for (i = 1; i <= ndm; i++) print DML[i] >> CO; if (RQH != "" && nrq) { for (i = 1; i <= nrq; i++) print "request " RQL[i] >> CO; print "requests open — each request above asks for one added test, this once: a later ask is not held by it" >> CO } if (NOT && TRU == "") for (i = 1; i <= nsk; i++) print "report left out — vid-results/" SKL[i] >> CO; if (SP) print "Fix the whole harm, not the instance named: name what must not happen, find every other way to it, and fix those too." >> CO
    for (i = 1; i <= n0; i++) { split(c0[i], x, " "); if (!(x[1] in drop)) print c0[i] > CN } for (i = 1; i <= na; i++) { split(ad[i], x, " "); if (!(x[1] in drop)) print ad[i] >> CN } close(CN)
    for (k in drop) print k > DR }'
# GM-4 E4: umap, each line of .vid/decide/unit-merges with its ticket: `<p> TAB <ticket or -> TAB <head> TAB <merge>`. Its ticket is
# the published ticket its ticket line names, or the one whose sub-issue tree, in the read's sub lines, holds the issue it names
# GM-4 E9: --withdrawn keeps a withdrawn ticket as the unit's (the later work a candidate holds, close.sh laterw); `decide.sh umap
# [--withdrawn]` prints these lines and writes nothing under .vid/decide but its own scratch
umap() { _rd=.vid/round/read; [ -f "$_rd" ] || _rd=/dev/null; awk -F'\t' -v L=.vid/tw/log -v KW="${1:-}" 'BEGIN { while ((getline l < L) > 0) { split(l, x, " "); if (x[1] == "published") P[x[2]] = 1; else if (x[1] == "withdrawn" && KW != "--withdrawn") delete P[x[2]] } }
    FILENAME == ARGV[1] { if ($1 == "sub") S[$4] = $2; next } { t = $2; if (!(t in P)) t = (t in S) ? S[t] : "-"; print $1 "\t" t "\t" $3 "\t" $4 }' "$_rd" "$D/unit-merges"; }
cmd_decide() { N=''; P=''; HD=''; POST=''; AT=''; DRY=''; while [ $# -gt 0 ]; do case $1 in --post) POST=1; shift ;; --dry) DRY=1; shift ;; --ticket) N=$2; shift 2 ;; --pr) P=$2; shift 2 ;; --head) HD=$2; shift 2 ;; --at) AT=$2; shift 2 ;; *) die "unknown $1" ;; esac; done
  if [ -n "$AT" ]; then [ -n "$N" ] && [ -z "$P$HD" ] || die 'usage — sh checks/decide.sh decide --ticket <n> --at <commit> [--post]'; HD=$AT; P=step-$N; KP=step-$N
  else [ -n "$N" ] && [ -n "$P" ] && [ -n "$HD" ] && [ -z "$DRY" ] || die 'usage — sh checks/decide.sh decide --ticket <n> --pr <p> --head <commit> [--post] | --ticket <n> --at <commit> [--post]'; KP=pr-$P; fi
  H=$(printf %s "$HD" | cut -c1-12); E=.vid/results/$KP-$H.txt; [ -f "$E" ] || ref "no evidence file at $E: read the reports first"
  F=.vid/tw/out/issue-$N.md; [ -f "$F" ] || die "no published ticket at $F"; KD=$(sed -n 's/^- kind: //p' "$F" | head -n 1); FW=$(sed -n 's/^- follows: //p' "$F" | head -n 1)   # FW: a follow-up's (0.26.10.28.10, R1)
  # 0.26.10.29.5 (DP-1 R8): the description read as the blocked label is, through github.sh; no Decisions section (decisions.sh section's
  # one reader: neither `Decisions: none` nor a `Decisions:` line with a `- ` line under it) makes the ticket not yet, beside every other line
  # FB-5 B1.4 (GitHub manual): PA, the step's own pull request whose ask stands at this head (round.sh's pr-asks): its description is read too, the
  # reply goes on it, and with the ticket closed in the read the label is read as GitHub auto reads one
  PA=''; [ -z "$AT" ] || ! manual || PA=$(awk -F'\t' -v n="$N" -v c="$HD" '$2 == n && $3 == c { p = $1 } END { if (p != "") print p }' "$D/pr-asks" 2>/dev/null || true)
  DMS=''; : > "$T/dms"; if [ -z "$AT" ]; then sh "$HERE/github.sh" pr-body "$P" > "$T/body" || die 'the description could not be read'; [ "$(sh "$HERE/decisions.sh" section "$T/body" | head -n 1)" != missing ] || DMS=1
    BL=$(sh "$HERE/github.sh" decide-blocked "$N" "$P") || die 'the labels could not be read'
  else   # GM-4 E2: each unit merged under the ticket at or before the commit, its description read again now; the label on the ticket alone
    { [ -z "$PA" ] || printf '%s\t%s\t-\t%s\n' "$PA" "$N" "$HD"; [ ! -s "$D/unit-merges" ] || umap | awk -F'\t' -v p="$PA" '$1 != p'; } | while IFS=$TAB read -r up ut uh um; do [ "$ut" = "$N" ] && [ "$um" != - ] || continue
      git --git-dir=.vid/code merge-base --is-ancestor "$um" "$HD" 2>/dev/null || continue
      sh "$HERE/github.sh" pr-body "$up" > "$T/ub" || die "the description of pull request $up could not be read"
      [ "$(sh "$HERE/decisions.sh" section "$T/ub" | head -n 1)" != missing ] || echo "no Decisions section — #$up" >> "$T/dms"; done
    [ -f .vid/round/read ] || die "no read of this call (.vid/round/read): the ticket's labels come from it"
    BL=$(awk -F'\t' -v n="$N" -v px="$(skey labels-prefix)" "$BLKL"'$1 == "issue" && $2 == n && blkl($3, px) != "" { print "blocked"; exit }' .vid/round/read)
    # FB-6 A1.2: a closed ticket's line in the read (github.sh round-read) is no open issue's, so its own pull request's label holds it as before
    [ -z "$PA" ] || { awk -F'\t' -v n="$N" '$1 == "issue" && $2 == n { f = 1 } END { exit !f }' .vid/round/read && ! gclosed "$N"; } || BL=$(sh "$HERE/github.sh" decide-blocked "$N" "$PA") || die 'the labels could not be read'; fi
  # FB-3 A1 (GitHub manual): MAN; DMT, the ticket as published asks for no Decisions section, so a unit without one is told and holds nothing;
  # NONE, the review found no merged pull request of the ticket (review.sh prepare's none-step-<n>, at this commit); RQH, the review's requests hold this decision:
  # never posted yet, or posted at this commit and no ask since (round.sh accept drops posted- at an ask); rows/ a copy for --dry
  # FB-5 B1.8: TRU, the team's own rules on record (team-rules): the two lines about form alone leave the decision, and the section holds nothing;
  # the owner is told them by round.sh's lacks line, from --dry and the evidence
  MAN=''; DMT=''; NONE=''; RQH=''; TRU=''; RDD=$D/rows; : > "$T/rv"; if [ -n "$AT" ] && manual; then MAN=1; TRU=$(skey team-rules); grep -q '^Decisions: ' "$F" || DMT=1; [ "$(cat "$D/review/none-step-$N" 2>/dev/null || true)" != "$HD" ] || NONE=1
    RQ=$(cat "$D/requested-step-$N" 2>/dev/null || true); if [ -z "$RQ" ] || { [ "$RQ" = "$H" ] && [ -f "$D/posted-$KP-$H" ]; }; then RQH=1; fi; fi
  [ -z "$DRY" ] || { cp -R "$D/rows" "$T/rows" && RDD=$T/rows; } || exit 1
  items "$F" > "$T/items"; : > "$T/new" ; : > "$T/dr"; : > "$T/ro"; : > "$T/co"; : > "$T/hn"; : > "$T/hx"; PH=$(cut -c1-12 "$D/last-$KP" 2>/dev/null || true)
  DECL=$(sed -n 's/^engines \([^|]*\)|.*/\1/p' .vid/tw/handed 2>/dev/null | tail -n 1 | sed 's/ *$//'); SPH=$(grep -c '^engine-split ' .vid/tw/handed 2>/dev/null || true); : > "$T/sp"; : > "$T/an"
  NASK=$(awk '/^## / { s = substr($0, 4); next } s == "Engines" && /^- (primary|also): / { n++ } END { print n + 0 }' "$F"); AH=$(awk -F'\t' -v n="$N" '$1 == n { print $2; exit }' "$D/analyst")
  # GM-4 E3: in GitHub manual nothing is dropped for a landing; the results reader's one list (results.sh amends) leaves out what does not count
  : > "$T/stale"; manual || [ ! -f .vid/tw/log ] || awk -v n="$N" '$1 == "published" && $2 == n { p = 1; next } p && $1 == "landed" { for (i = 2; i <= NF; i++) if ($i ~ /^ids=/) { m = split(substr($i, 5), a, ","); for (j = 1; j <= m; j++) print a[j] } }' .vid/tw/log > "$T/stale"   # R4 (v0.26.10.25.5): no evidence from a ticket published before a landing, by the log's order
  sh "$HERE/close.sh" owned > "$T/ow" 2>/dev/null || : > "$T/ow"; OWN=" $(sed -n 's/^- rows: //p' "$F" | head -n 1) "
  # GM-4 E3 (GitHub manual): the tests the newest amendment naming them (added= or restated=) made after the decision before (PH's), so
  # nothing that decision proved is carried past the amendment
  : > "$T/noc"; if manual && [ -n "$PH" ] && [ -f .vid/tw/log ]; then PW=$(awk -F'\t' -v p="$P" -v h="$PH" '$2 == p && $3 == h { t = $1 } END { print t }' "$D/log")
    [ -z "$PW" ] || awk -v n="$N" -v w="$PW" '$1 == "amended" && $2 == n { a = ""; for (i = 3; i <= NF; i++) if ($i ~ /^at=/) a = substr($i, 4); if (a <= w) next; for (i = 3; i <= NF; i++) if ($i ~ /^(added|restated)=/) { m = split(substr($i, index($i, "=") + 1), q, ","); for (j = 1; j <= m; j++) if (q[j] != "" && q[j] != "-") print q[j] } }' .vid/tw/log > "$T/noc"; fi
  W=$(now); awk -v N="$N" -v P="$P" -v KP="$KP" -v NCF="$T/noc" -v DMF="$T/dms" -v MAN="$MAN" -v DMT="$DMT" -v TRU="$TRU" -v NONE="$NONE" -v RQH="$RQH" -v RVF="$T/rv" -v H="$H" -v KD="$KD" -v FW="$FW" -v BL="$BL" -v DMS="$DMS" -v DECL="$DECL" -v SPH="$SPH" -v NASK="$NASK" -v AH="$AH" -v SPF="$T/sp" -v ANF="$T/an" -v NOWT="$W" -v RD="$RDD" -v CF="$D/counts" -v LF="$D/limits" -v UF="$D/rulings" -v IF="$T/items" -v SF="$D/state" -v PF="$D/$KP-$PH.rows" -v PH="$PH" -v HF="$D/halted" -v OWF="$T/ow" -v STF="$T/stale" -v HN="$T/hn" -v HX="$T/hx" -v CO="$T/co" -v RO="$T/ro" -v CN="$T/new" -v DR="$T/dr" "$DE" "$E"; [ -z "$DRY" ] || { cat "$T/rv" "$T/dms"; return 0; }; if [ -n "$MAN" ] && [ -z "$PA" ] && [ "$(sed -n 2p "$T/co")" = 'ticket: not yet' ] && gclosed "$N"; then echo "$CLOSEDL" >> "$T/co"; fi; cat "$T/hn" >> "$D/halted"; cat "$T/an" >> "$D/analyst"
  [ ! -s "$T/hx" ] || { awk -F'\t' 'FILENAME == ARGV[1] { x[$1] = 1; next } !(($2 in x) && $3 == "i")' "$T/hx" "$D/halted" > "$T/h3" || exit 1; put "$D/halted" < "$T/h3" || exit 1; }   # 0.26.11.1.4 (R3): the released rows' i lines, as rule drops a line
  while IFS=$TAB read -r r e; do mkdir -p .vid/tw; grep -q "^engine-split $r " .vid/tw/handed 2>/dev/null || printf 'engine-split %s | stand-in: %s\n' "$r" "$e" >> .vid/tw/handed; done < "$T/sp"   # R11: once a row, never unwritten
  put "$D/counts" < "$T/new" || exit 1; for r in $(cat "$T/dr"); do grep -v "^$r " "$D/limits" > "$T/l" || true; put "$D/limits" < "$T/l" || exit 1; done
  put "$D/$KP-$H.rows" < "$T/ro" || exit 1; put "$D/$KP-$H.txt" < "$T/co" || exit 1; printf '%s\n' "$(sed -n '1s/^vid: decision //p' "$T/co")" > "$T/lp" || exit 1; put "$D/last-$KP" < "$T/lp" || exit 1
  if [ -z "$PA" ] && [ "$(sed -n 2p "$T/co")" = 'ticket: accepted' ] && ! awk -v n="$N" '$2 == n { f = 1 } END { exit !f }' "$D/accepted-at"; then printf '%s %s %s at=%s\n' "$P" "$N" "$H" "$W" >> "$D/accepted-at"; fi   # v0.26.10.26.3 (R2): once a ticket; FB-5 B1.4: a pull request's head's, at its merge (merged)
  { cut -f1,3 "$T/ro" | while IFS=$TAB read -r r s; do printf '%s\t%s\t%s\t%s\t%s\n' "$W" "$P" "$H" "$r" "$s"; done; } >> "$D/log"
  awk -F'\t' -v P="$P" -v H="$H" -v W="$W" 'FILENAME == ARGV[1] { n[$1] = $3 "\t" $4 "\t" P "\t" H "\t" W; next } !($1 in n) { print } END { for (r in n) print r "\t" n[r] }' "$T/ro" "$D/state" > "$T/s" || exit 1; put "$D/state" < "$T/s" || exit 1
  awk -F'\t' '$7 == 1 { print $1 }' "$T/ro" | while read -r r; do printf '%s\t%s\tundone\ta later head failed it\tdecide\n' "$W" "$r" >> "$D/rulings"; [ "$(word "${r%-T[0-9]*}")" != accepted-by-ruling ] || hset "${r%-T[0-9]*}" failing; done
  # the handed record: a held row at once; a recorded row to failing, and back when accepted again (FB-5 B1.4: at a pull request's head, at its merge)
  awk -F'\t' '{ s[$2] = s[$2] " " $3 } END { for (b in s) print b "\t" s[b] }' "$T/ro" | while IFS=$TAB read -r b ss; do grep -qxF "$b" "$T/ow" && case $OWN in *" $b "*) false ;; *) true ;; esac && continue; w=$(word "$b"); case $w in ''|held|failing|accepted-by-ruling|known-limit) ;; *) onrec "$b" || echo "$b" >> "$D/record" ;; esac
    case " $ss " in *' held '*) hset "$b" held ;; *' failing '*) [ -z "$w" ] || hset "$b" failing ;; *'evidence missing'*|*'question open'*) ;;
      *) [ "$w" = failing ] && [ -z "$PA" ] || continue; if ! onrec "$b"; then hdrop "$b"; else case $ss in *owed*) [ "$w" = paid ] || hset "$b" owed ;; *) hset "$b" accepted ;; esac; fi ;; esac; done
  if [ -n "$POST" ] && ! cmp -s "$D/posted-$KP-$H" "$T/co"; then
    # FB-5 B1.4: on the pull request asked on; its request lines on the ticket too, the first time they are asked
    if [ -n "$PA" ]; then if [ -z "$RQ" ] && grep '^request ' "$T/co" > "$T/rql"; then sh "$HERE/github.sh" comment "$N" --body-file "$T/rql" > /dev/null || die 'the requests could not be posted on the ticket'; fi; sh "$HERE/github.sh" decide-post "$PA" "$T/co" > /dev/null || die 'the decision could not be posted'
    elif [ -n "$AT" ]; then sh "$HERE/github.sh" comment "$N" --body-file "$T/co" > /dev/null || die 'the decision could not be posted'   # GM-4 E2: on the ticket's issue
    else sh "$HERE/github.sh" decide-post "$P" "$T/co" > /dev/null || die 'the decision could not be posted'; fi; put "$D/posted-$KP-$H" < "$T/co" || exit 1
    [ -z "$MAN" ] || ! grep -q '^requests open — ' "$T/co" || { printf '%s\n' "$H" > "$T/rq" && put "$D/requested-step-$N" < "$T/rq"; } || exit 1; fi   # FB-3 A1.4
  cat "$T/co"; }
cmd_merged() { P=''; KP=''; NT=''; case ${1:-} in --pr) P=${2:-}; KP=pr-$P ;; --ticket) NT=${2:-}; P=step-$NT; KP=$P ;; esac; [ -n "${2:-}" ] || die 'usage — sh checks/decide.sh merged --pr <p> | --ticket <n>'
  [ -f "$D/last-$KP" ] || ref "no decision for ${NT:+ticket }${NT:-pull request $P}"
  HD=$(cat "$D/last-$KP"); H=$(printf %s "$HD" | cut -c1-12); sh "$HERE/close.sh" owned > "$T/ow" 2>/dev/null || : > "$T/ow"   # a passing regression row a close owns stays failing
  awk -F'\t' '{ b = $2; if (!(b in s)) { s[b] = $3; o[++n] = b } else if ($3 !~ /^(accepted|owed|passing|known limit|accepted by ruling)$/ || s[b] == "accepted") s[b] = $3; if ($5 ~ /^proven/) p[b] = 1 } END { for (i = 1; i <= n; i++) print o[i] "\t" s[o[i]] "\t" (p[o[i]] ? "fault-proven" : "") }' "$D/$KP-$H.rows" > "$T/m"
  DW=$(awk -F'\t' -v p="$P" -v h="$H" '$2 == p && $3 == h { t = $1 } END { print t }' "$D/log"); awk -v t="$DW" '$3 >= t { print $1 }' "$D/landed" > "$T/stale" 2>/dev/null || : > "$T/stale"   # R4: nothing from a decision before a landing, or in its second
  # GM-4 E3: in GitHub manual the results reader's one list holds what counts from an amendment; FB-5 B1.4: but a head accepted on its own pull request
  # (pr-asks) is on record only at its merge, so a test landed since that decision stays off the record, as in GitHub auto
  ! manual || [ -n "$(awk -F'\t' -v n="$NT" -v c="$HD" '$2 == n && $3 == c { print $1; exit }' "$D/pr-asks" 2>/dev/null)" ] || : > "$T/stale"
  while IFS=$TAB read -r b s m; do grep -qxF "$b" "$T/stale" && continue; awk -F'\t' -v b="$b" -v p="$P" '($1 == b || index($1, b "-T") == 1) && $4 != p { f = 1 } END { exit !f }' "$D/state" && continue; case $s in accepted) hset "$b" accepted "$m" ;; 'accepted by ruling') hset "$b" accepted-by-ruling "$m" ;; owed) [ "$(word "$b")" = paid ] || hset "$b" owed "$m" ;; 'known limit') hset "$b" known-limit "$m" ;;
      passing) w=$(word "$b"); grep -qxF "$b" "$T/ow" || case $w in failing|held) hset "$b" accepted "$m" ;; esac ;; esac; case $s in accepted|'accepted by ruling'|owed|'known limit'|passing) onrec "$b" || echo "$b" >> "$D/record" ;; esac; done < "$T/m"
  if [ -n "$NT" ]; then awk -v n="$NT" '$2 == n { f = 1 } END { exit !f }' "$D/accepted-at" || printf '%s %s %s at=%s\n' "$P" "$NT" "$H" "$(now)" >> "$D/accepted-at"   # FB-5 B1.4
    [ "$(sed -n 's/^- kind: //p' ".vid/tw/out/issue-$NT.md" 2>/dev/null | head -n 1)" != skeleton ] || sh "$HERE/results.sh" declare --ticket "$NT" --at "$HD" > /dev/null   # GM-4 E4
    echo "accepted ticket $NT: its rows are on the record"; return 0; fi
  sh "$HERE/results.sh" declare --pr "$P" --head "$HD" > /dev/null; echo "merged pull request $P: its rows are on the record"; }
st() { awk -F'\t' -v r="$1" -v c="$2" '$1 == r { print $c }' "$D/state"; }
cmd_rule() { R=${1:-}; V=${2:-}; [ -n "$R" ] && [ -n "$V" ] || die 'usage — sh checks/decide.sh rule <row> accept|limit|amend|more <n> [--by <who>]'; shift 2; BY=owner; A=''
  while [ $# -gt 0 ]; do case $1 in --by) BY=${2:-owner}; shift 2 ;; *) A="$A${A:+ }$1"; shift ;; esac; done; S=$(st "$R" 2); U=$(st "$R" 3); B=${R%-T[0-9]*}
  RF=$D/pr-$(st "$R" 4)-$(st "$R" 5).rows; case $(st "$R" 4) in step-*) RF=$D/$(st "$R" 4)-$(st "$R" 5).rows ;; esac   # GM-4 E2: a ticket's decision
  case $V in accept|amend|more) [ "$S" = held ] || ref "$R is not held" ;; limit) [ -n "$S" ] || ref "no decision holds $R" ;; *) die "unknown answer $V" ;; esac
  case $V in accept) [ "$U" = 'evidence missing' ] && [ "$(awk -F'\t' -v r="$R" '$1 == r { print $8 }' "$RF" | head -n 1)" = passed ] || ref "$R does not pass with only its evidence missing: it is $U" ;; more) case $A in ''|0*|*[!0-9]*) die 'more needs its number' ;; esac ;; esac
  printf '%s\t%s\t%s\t%s\t%s\n' "$(now)" "$R" "$V" "$A" "$BY" >> "$D/rulings"; n=$(awk -v r="$R" '$1 == r { c++ } END { print c + 0 }' "$D/counts")
  setst() { awk -F'\t' -v OFS='\t' -v r="$R" -v s="$1" '$1 == r { $2 = s } { print }' "$D/state" > "$T/s" || exit 1; put "$D/state" < "$T/s" || exit 1; }
  others() { [ "$B" != "$R" ] && awk -F'\t' -v b="$B" -v r="$R" '$1 != r && index($1, b "-T") == 1 && $2 == "held" { f = 1 } END { exit !f }' "$D/state"; }
  awk -F'\t' -v r="$R" '$2 != r' "$D/halted" > "$T/h2" || exit 1; put "$D/halted" < "$T/h2" || exit 1; case $V in more|amend) awk -F'\t' -v OFS='\t' '{ $10 = 0; print }' "$RF" > "$T/rf" || exit 1; put "$RF" < "$T/rf" || exit 1 ;; esac
  case $V in accept) grep -v "^$R " "$D/counts" > "$T/c" || true; put "$D/counts" < "$T/c" || exit 1; setst 'accepted by ruling'; others || if onrec "$B"; then hset "$B" accepted-by-ruling; else hdrop "$B"; fi ;;
    limit) setst 'known limit'; others || hset "$B" known-limit ;; more) for k in $R $(awk -v b="$B" '$1 == b || index($1, b "-T") == 1 { print $1 }' "$D/counts" | sort -u); do c=$(awk -v r="$k" '$1 == r { c++ } END { print c + 0 }' "$D/counts"); { grep -v "^$k " "$D/limits" || true; echo "$k $((c + A))"; } > "$T/l" || exit 1; put "$D/limits" < "$T/l" || exit 1; done; setst failing; others || hset "$B" failing ;; esac
  echo "recorded: $R $V${A:+ $A}, by $BY"; }
cmd_queue() { Q=$D/queue.md; { printf '# ViD: what waits on the owner\n\n'
    awk -F'\t' '{ c[$2]++ } END { for (s in c) printf "%d %s\n", c[s], s }' "$D/state" | sort -k2 | awk 'BEGIN { printf "Rows, by each one\047s newest decision: " } { printf "%s%s", (n++ ? ", " : ""), $0 } END { print "." }'
    printf '\n## Held\n\n'; for r in $(awk -F'\t' '$2 == "held" { print $1 }' "$D/state" | sort); do printf '### %s\n\n' "$r"; [ ! -f "$D/rows/$r.txt" ] || awk -F'\t' '{ print "- " $1 ", at " $2 ": " (($3 == "answered") ? "answered" : $4) }' "$D/rows/$r.txt"
      printf '\nAnswers: accept it by ruling, only if its tests pass and its evidence is what is missing; rule it a known limit; amend it; allow it N more counts.\n\n'; done
    printf '\n## Findings\n\n| Severity | Tag | Finding |\n|---|---|---|\n'; awk -F'\t' '{ print $2 "\t" $3 }' "$D/log" | sort -u | while IFS=$TAB read -r p h; do case $p in step-*) cat ".vid/results/$p-$h.txt" 2>/dev/null || true ;; *) cat ".vid/results/pr-$p-$h.txt" 2>/dev/null || true ;; esac; done | awk '/^finding: / && !seen[$0]++ { t = $2; s = $3; r = $0; sub(/^finding: [a-z]+ /, "", r); if (s ~ /^(high|medium|low)$/) sub(/^[a-z]+ /, "", r); else s = "-"; sub(/^— /, "", r); gsub(/\|/, "/", r); print ((s == "high") ? 1 : (s == "medium") ? 2 : (s == "low") ? 3 : 4) "\t" ((t == "bug") ? 1 : 2) "\t| " s " | " t " | " r " |" }' | sort -t"$TAB" -s -k1,1n -k2,2n | cut -f3-; } > "$T/q" || exit 1; put "$Q" < "$T/q" || exit 1
  sh "$HERE/page.sh" "$Q" --out "$D/queue.html"; }
# FB-3 A4: outside, rows accepted outside ViD by the owner's words (the header)
cmd_outside() { N=''; AT=''; WD=''; IDS=''; RW=''; NT=''; u='usage — sh checks/decide.sh outside --ticket <n> --at <commit> --words "<w>" [--note "<why this commit>"] | --rows "<ids>" --words "<w>"'
  while [ $# -ge 2 ]; do case $1 in --ticket) N=$2 ;; --at) AT=$2 ;; --note) NT=$(printf %s "$2" | tr '\t\n|"' "  /'") ;; --rows) IDS=$2; RW=1 ;; --words) WD=$2 ;; *) die "$u" ;; esac; shift 2; done; [ $# -eq 0 ] || die "$u"
  if [ -n "$RW" ]; then [ -z "$N$AT$NT" ] || die "$u"; else [ -n "$N" ] && [ -n "$AT" ] || die "$u"; fi
  WD=$(printf %s "$WD" | tr '\t\n|"' "  /'" | sed 's/^ *//; s/ *$//'); [ -n "$WD" ] || ref "no words: an acceptance outside ViD goes on record only in the owner's words"
  mustread "$T/pr" planner rows
  # the published tickets not withdrawn, each row of their newest log line: `<row> TAB <ticket>`
  awk '$1 == "withdrawn" { delete R[$2]; next } ($1 == "published" || ($1 == "amended" && ($2 in R))) { x = ""; for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) x = substr($i, 6); if (x != "" || $1 == "published") R[$2] = x } END { for (n in R) { m = split(R[n], a, ","); for (i = 1; i <= m; i++) if (a[i] != "" && a[i] != "-") print a[i] "\t" n } }' .vid/tw/log > "$T/tkr" 2>/dev/null || : > "$T/tkr"
  : > "$T/rtd"; if [ -n "$N" ]; then awk -F'\t' -v n="$N" '$2 == n { print $1 }' "$T/tkr" > "$T/ids"
    # GM-3 U4: the tests the ticket lists retired
    { sed -n 's/^- \([^ ]*\) marks: retired;.*/\1/p' ".vid/tw/out/issue-$N.md" 2>/dev/null; awk -v n="$N" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { k = split(l, w, " "); for (i = 3; i <= k; i++) if (w[i] ~ /^retired=/) { m = split(substr(w[i], 9), q, ","); for (j = 1; j <= m; j++) if (q[j] != "" && q[j] != "-") print q[j] } }' .vid/tw/log; } | sort -u > "$T/rtd"; awk 'FILENAME == ARGV[1] { s[$1] = 1; next } !($1 in s)' "$T/ids" "$T/rtd" > "$T/rt2"; cat "$T/rt2" >> "$T/ids"
  else printf '%s\n' "$IDS" | awk "$RNG"'{ n = split($0, t, /[ ,\t]+/); for (i = 1; i <= n; i++) if (t[i] != "") { m = split(rng(t[i]), e, " "); for (j = 1; j <= m; j++) if (!(e[j] in s)) { s[e[j]] = 1; print e[j] } } }' > "$T/ids"
    [ -s "$T/ids" ] || ref 'no row is named'
    x=$(awk -F'\t' 'FILENAME == ARGV[1] { if ($2 == "row" || $2 == "record") K[$1] = 1; next } !($1 in K) { print $1 }' "$T/pr" "$T/ids" | paste -sd ' ' -); [ -z "$x" ] || ref "not in the inventory: $x"
    x=$(awk -F'\t' 'FILENAME == ARGV[1] { W[$1] = 1; next } $1 in W { printf "%s%s (ticket #%s)", (n++ ? ", " : ""), $1, $2 }' "$T/ids" "$T/tkr"); [ -z "$x" ] || ref "in a published ticket: $x; /vid:vid-accept-step <ticket> <commit> accepted \"<your words>\" records a ticket's"; fi
  W=$(now); L="owner at $W, words \"$WD\"${NT:+, $NT}; evidence: none, accepted outside ViD"; P=${N:+step-$N}; P=${P:--}; H=$(printf %s "${AT:--}" | cut -c1-12); DONE=''
  # its rows as they read now: the row, what it becomes or why it is left, and its transitions
  awk -F'\t' -v HF=.vid/tw/handed -v UF="$D/rulings" -v RF="$T/rtd" -v PF="$T/pr" 'BEGIN { while ((getline l < HF) > 0) { split(l, w, " "); if (w[1] == "row") S[w[2]] = w[3] } while ((getline l < UF) > 0) { split(l, x, "\t"); U[x[2]] = x[3] } while ((getline l < RF) > 0) R[l] = 1
      while ((getline l < PF) > 0) { split(l, x, "\t"); if (x[2] == "tr") { if (U[x[1]] != "limit") T[x[3]] = T[x[3]] " " x[1] } else { K[x[1]] = x[2]; C[x[1]] = x[6]; M[x[1]] = x[7] } } }
    { r = $1; z = S[r]; v = "ok"; if (r in R) v = "retired"; else if (z == "known-limit" || C[r] == "limit" || U[r] == "limit") v = "a known limit"; else if (K[r] == "record") v = "a record, not a test"; else if (z ~ /^(accepted|accepted-by-ruling|paid)$/) v = "accepted already"; else if (z == "owed") v = "owed already"; else if (M[r] ~ /(^| )(owed-[a-z]+|seam)( |$)/) v = "owed"; print r "\t" v "\t" T[r] }' "$T/ids" > "$T/od" || exit 1
  while IFS=$TAB read -r r v tr <&7; do case $v in ok) s='accepted by ruling'; hset "$r" accepted-by-ruling '' "$L" ;; owed) s=owed; hset "$r" owed '' "$L" ;; *) echo "left $r: $v"; continue ;; esac
    DONE="$DONE${DONE:+,}$r"; for x in $r $tr; do [ "$v" = owed ] || printf '%s\t%s\taccept\t%s\towner\n' "$W" "$x" "$WD" >> "$D/rulings"; done
    # as a decision's lines are: a journey's transitions, else the row itself; nothing it was counted or held for stands
    for x in ${tr:-$r}; do printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$x" "$s" "$s" "$P" "$H" "$W"; done >> "$T/os"; for x in $r $tr; do echo "$x"; done >> "$T/ox"; onrec "$r" || echo "$r" >> "$D/record"; done 7< "$T/od"
  if [ -n "$DONE" ]; then awk -F'\t' 'FILENAME == ARGV[1] { n[$1] = 1; next } !($1 in n)' "$T/os" "$D/state" > "$T/s" && cat "$T/os" >> "$T/s" && put "$D/state" < "$T/s" || exit 1
    awk 'FILENAME == ARGV[1] { n[$1] = 1; next } !($1 in n)' "$T/ox" "$D/counts" > "$T/c" && put "$D/counts" < "$T/c" || exit 1; awk -F'\t' 'FILENAME == ARGV[1] { n[$1] = 1; next } !($2 in n)' "$T/ox" "$D/halted" > "$T/h2" && put "$D/halted" < "$T/h2" || exit 1; fi
  [ -z "$N" ] || awk -v n="$N" '$2 == n { f = 1 } END { exit !f }' "$D/accepted-at" || printf '%s %s %s at=%s\n' "$P" "$N" "$H" "$W" >> "$D/accepted-at"
  ev "accepted-outside ticket=${N:--} rows=${DONE:--} commit=$H words=\"$WD\"${NT:+ note=\"$NT\"}"; n=$(printf '%s' "$DONE" | awk -F, '{ print NF }'); echo "recorded ${n:-0} rows accepted outside ViD, by the owner's words${DONE:+ — $DONE}"; }
CMD=${1:-}; [ $# -gt 0 ] && shift
case $CMD in
  decide) cmd_decide "$@" ;; merged) cmd_merged "$@" ;; rule) cmd_rule "$@" ;; outside) cmd_outside "$@" ;; queue) cmd_queue "$@" ;;
  umap) case ${1:-} in ''|--withdrawn) [ ! -f "$D/unit-merges" ] || umap "${1:-}" ;; *) die 'usage — sh checks/decide.sh umap [--withdrawn]' ;; esac ;;   # GM-4 E9
  *) die 'usage — sh checks/decide.sh decide|merged|outside|queue|rule|umap …' ;;
esac
