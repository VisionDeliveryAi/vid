#!/bin/sh
# Purpose: ViD's one voice to the owner in ticket mode (v0.26.10.25.3, R1–R7). It keeps what waits on the owner as RUN-STATE's
# `Q<n>` lines, the form observe.sh reads, from ViD's records alone: held rows, the dev side's questions, a ticket's findings, a close
# that could not finish. It reads no code. Run at the top of ViD's repository.
#   sync                 the open-questions section and its `questions:` key, from the records; prints `question <n> <k>` for a
#                        dev-side question with no answer and no line, `finding <ticket> <severity> <words>` once each, `unreleased <row>`;
#                        v0.26.10.26.3 (R3): `regression <step>/<ask> <n>` once for each close whose numbers give regressions introduced above 0
#   recommend Q<n> <letter> "<why>"            the session's own recommendation for a held row
#   ask <n>:<k>                                a dev-side question only the owner can answer becomes a `Q<n>` line; v0.26.10.26.7 (R8): and
#                                              one `RM: this question waits on the lead (Q<n>)…` comment on <n>, the question's text never quoted
#   ask draft <n>                              (v0.26.10.25.5) a counted change, drafted by checks/land.sh draft, asked once: yes lands it
#                                              (checks/land.sh <n>), no declines it; a held row's amend and a finding's fix or row print a
#                                              `door:` line, for /vid fix's ticket-mode branch to draft
#   answer <Q<n>|<n>:<k>> [--by RM|delegate|stand-in] … held row: a | b <N> | c | d "<words>"; question: "<words>", posted as `RM:`; findings:
#                                              <finding> fix|row|known|no "<words>"; close: again|limit "<words>". Recorded with who and an event
#   control pause|continue "<words>"           `run: stopped owner asked to pause` or `run: active`, recorded
#   control seed production|synthetic "<words>" (0.26.11.1.1, R6) the owner's word for staging's data, theirs alone (no --by), with who
#                                              and when; production refused before a production deploy has passed
# 0.26.11.1.1: a D1 refused twice for a duty not done is also answered known "<words>" (the owner's: .vid/decide/duties-known); a
#   passed D2's duty missing or not done is `pduty:<issue>:<duty>`, the owner's known; a seam row not marked real at staging is
#   `stand-in`, the owner's limit "<words>" (paid against it) or again (D1 and CS afresh); a staging that stays up is up in addresses
#   status                                     where things stand, one fixed block; v0.26.10.26.3 (R1): then the stage, now, left, tests,
#                                              the test state, debt, landings, cost, hardening and estimate lines, from the records alone;
#                                              0.26.10.29.5 (DP-1 R4): its delegated answers are every answer not given by the owner
#                                              (lib.sh notowner), then `merged with no decisions stated: #<p>, …` and
#                                              `decisions refused: #<p>, …`, each `none` when there is none
#   addresses <N>                              (v0.26.10.28.8, R7) stage N's newest candidate's addresses, read only: `test site: <a>, up`,
#                                              `…, taken down after its run` or `test site: not known yet`; `rehearsal copy:` the same;
#                                              `live copy: <a>` once D2 passed. The status's stage line ends with the same
#   cost [<step>]                              (v0.26.10.26.3, R2) a line a published ticket under its step: published to accepted, heads,
#                                              accepted at the first decision, held, accepted to closed; then ViD's rounds
#   defect <step> "<words>"                    ViD's own defect, an entry in .vid/VID-FINDINGS.md, counted
#   lesson <rows,…> "<cause>"                  a `lesson` line in the handed record, for the next ticket of those rows
# v0.26.10.25.4: close items are each step's newest ask's (R3), a red one's line with the three numbers (R4), a row red again after a fix
# answered again (another fix ticket) or limit; the status's fix line. 0.26.10.29.2 (R7): a close asked again after its fix whose red
# rows did not shrink, `shrink <the close before it>@<rows now,> <rows now> · before: <rows then>` (keyed by its rows, so a later one is
# its own question), answered the same way.
# Records: .vid/decide/queue/ (ids, answers, questions, recommend, seen, updated), .vid/tw/known-findings.
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
[ -f .vid/RUN-STATE.md ] || { echo "ViD queue: run it at the top of ViD's repository" >&2; exit 2; }
D=.vid/decide; Q=$D/queue; RS=.vid/RUN-STATE.md; RD=.vid/round/read; HAND=.vid/tw/handed; TAB=$(printf '\t'); SOH=$(printf '\001'); BY=''   # who answers: set by answer alone, never read from the environment (v0.26.10.28.8)
mkdir -p "$Q" .vid/round; touch "$Q/ids" "$Q/answers" "$Q/questions" "$Q/recommend" "$Q/seen"
die() { echo "ViD queue: $*" >&2; exit 1; }
PX=$(skey labels-prefix)
# items: `<key> TAB <gates> TAB <the item's words>`, each open item once, from the records as they stand
held_items() { awk -F'\t' '$1 == "open" { print $2 "\t" $3 "\t" substr($4, 1, 12) }' "$RD" 2>/dev/null | while IFS=$TAB read -r p t h; do f=$D/pr-$p-$h.rows; [ -f "$f" ] || continue
    pt=$(awk -v n="$t" '$1 == "published" && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^at=/) { print substr($i, 4); exit } }' .vid/tw/log 2>/dev/null | head -n 1)
    awk -F'\t' -v t="$t" -v PT="$pt" -v LF="$D/landed" -v RF="$Q/recommend" -v AF="$Q/answers" 'BEGIN { while ((getline l < LF) > 0) { split(l, x, " "); LT[x[1]] = x[3] } while ((getline l < RF) > 0) { split(l, x, "\t"); R[x[1]] = x[2] " — " x[3] }
        while ((getline l < AF) > 0) { split(l, x, "\t"); r = x[2]; sub(/^held:/, "", r); b = r; sub(/-T[0-9]+$/, "", b); if (x[3] == "d" && !((b in LT) && LT[b] > x[1])) AM[x[2]] = 1 } }
      { b = $1; sub(/-T[0-9]+$/, "", b) } (b in LT) && PT != "" && LT[b] > PT { next }   # v0.26.10.25.5 R4: a landed row leaves a ticket published before its landing
      $3 == "held" && ("held:" $1 in AM) { print "held:" $1 "\t#" t "\theld " $1 " · #" t " · amended by the owner: SP drafts it through /vid fix, and its draft is asked as its own line"; next }
      $3 == "held" { w = $6; sub(/^held — /, "", w); a = ($4 == "evidence missing" && $8 == "passed"); weak = index($6, "a weak test") && index($6, "not proven"); prod = index($6, "a product failure") || index($6, "passes at this head")
        r = ("held:" $1 in R) ? R["held:" $1] : a ? "a — its tests pass and its evidence alone is missing" : weak ? "c — the corrected test still misses its break" : "b — 1 more round"
        print "held:" $1 "\t#" t "\theld " $1 " · #" t " · " w " · how far? " (a ? "(a) accept by ruling " : "") "(b) N more rounds (c) a known limit (d) amend · recommended: " r }' "$f"; done; }
q_items() { awk -F'\t' -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } } $4 == "asked" && !("question:" $1 in D) { print "question:" $1 "\t#" substr($1, 1, index($1, ":") - 1) "\t" $3 }' "$Q/questions"; }
# a ticket's findings: its newest evidence file's `finding:` lines; a line for the ticket, and one for each high one
fnd() { ls -t .vid/results/pr-"$1"-*.txt 2>/dev/null | head -n 1 | xargs -I{} sed -n 's/^finding: //p' {} 2>/dev/null; }
f_items() { awk -F'\t' '($1 == "open" || $1 == "merged") && $3 != "-" { print $2 "\t" $3 }' "$RD" 2>/dev/null >> "$Q/prs"; sort -u "$Q/prs" > "$Q/prs.t" || exit 1; put "$Q/prs" < "$Q/prs.t" || exit 1; while IFS=$TAB read -r p t; do fnd "$p" > "$Q/f.$p"; [ -s "$Q/f.$p" ] || continue
    awk -v t="$t" -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); if (x[2] ~ "^finding:" t ":") D[x[2]] = 1 } }
      { k = "finding:" t ":" NR; if (k in D) next; s = ($2 ~ /^(high|medium|low)$/) ? $2 : "low"; c[s]++; o++; if (s == "high") print k "\tnothing\tfinding of #" t ", high · " $0 " · rule it: fix, a row, known, or no · .vid/decide/queue.html" }
      END { if (o) print "findings:" t "\tnothing\tfindings of #" t " · " c["high"] + 0 " high, " c["medium"] + 0 " medium, " c["low"] + 0 " low · rule each: fix, a row, known, or no · .vid/decide/queue.html" }' "$Q/f.$p"; done < "$Q/prs"; }
nk() { k0=''; for d in $(ls "$D/close/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/close/$1/$d/ask" ] && k0=$d; done; echo "$k0"; }
# v0.26.10.26.1: a stage's newest candidate's items too, `close:stage-<N>/<c>:…`; its rest chunk and S1, lost, answered again alone
# 0.26.10.29.2 (R2): none of a candidate a re-cut withdrew; (R7) a close with a shrink item open asks that question alone, its red items
# held back until it is answered
snc() { c0=''; for d in $(ls "$D/stage/$1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/stage/$1/$d/ask" ] && c0=$d; done; echo "$c0"; }
cdir() { case $1 in stage-*) x=${1#stage-}; echo "$D/stage/${x%%/*}/${x#*/}" ;; *) echo "$D/close/$1" ;; esac; }
c_items() { { for s in $(ls "$D/close" 2>/dev/null); do k=$(nk "$s"); [ -n "$k" ] && [ ! -f "$D/close/$s/$k/withdrawn" ] && ! grep -q "^closed $s " "$HAND" 2>/dev/null && echo "$s $k"; done
    for x in $(ls "$D/stage" 2>/dev/null); do k=$(snc "$x"); [ -n "$k" ] && [ ! -f "$D/stage/$x/$k/withdrawn" ] && echo "stage-$x $k" && echo "stage-$x $k/d1" && echo "stage-$x $k/cs" && echo "stage-$x $k/w1" && echo "stage-$x $k/rh" && echo "stage-$x $k/cr"; for o in $(ls "$D/stage/$x" 2>/dev/null | grep -E '^[0-9]+$'); do echo "stage-$x $o/d2"; echo "stage-$x $o/cp"; done; done; } | while read -r s k; do F=$(cdir "$s/$k"); f=$F/items; [ -f "$f" ] || continue
    awk -v s="$s" -v sk="$s/$k" -v NB="$(cat "$F/numbers" 2>/dev/null)" -v A="$Q/answers" -v SM="$F/same" -v IF="$f" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } while ((getline l < SM) > 0) SA[l] = 1; while ((getline l < IF) > 0) if (l ~ /^shrink /) { split(l, y, " "); if (!(("close:" sk ":shrink:" y[2]) in D)) SH = 1 } close(IF) }
    { k = "close:" sk ":" $1 ":" $2 (($NF ~ /^#[0-9]+$/) ? ":" substr($NF, 2) : ""); if (k in D) next; if ($1 == "red" && SH) next; if ($NF ~ /^#[0-9]+$/) $NF = ""; w = substr($0, length($1 $2) + 3)
      if ($1 == "red") print k "\tstep " s "\tthe close of " s ", chunk " $2 ", failing: " w (NB == "" ? "" : " · " NB) " · a fix ticket is written for them; answer limit to rule them known limits"
      else if ($1 == "twice") print k "\tstep " s "\tthe close of " s ", " $2 " failed again after its fix: " w (NB == "" ? "" : " · " NB) " · answer again for another fix ticket, or limit"
      else if ($1 == "shrink") { sub(/ · before: /, " · red at the close before it: ", w); print k "\tstep " s "\tthe close of " s " did not shrink after its fix: red now: " w (NB == "" ? "" : " · " NB) " · answer again for a fix ticket, or limit to rule the rows red now known limits" }   # 0.26.10.29.2 (R7)
      else if (sk ~ /\/w1$/) { sub(/^twice: /, "", w); sub(/^— /, "", w); print k "\t" s "\tthe walk W1 of " s ": " ($1 == "refused" ? "its return refused twice: " : "not done — ") w " · answer again: the walker starts again, at the same staged commit" ($1 != "refused" && w ~ /^browser: none( |$)/ ? "; or, yours alone, close without the walk: the stage closes with the walk a known limit" : "") }   # 0.26.10.28.6 (R1 (b))
      else if (sk ~ /\/d2$/) print k "\t" s "\tthe production deploy of " s ": " w " · answer again"
      else if ($1 == "notdone") print k "\t" s "\tthe staging deploy D1 of " s ": its report refused twice: " w " · answer again; or, yours alone, known \"<words>\": the duty a known limit of this project"   # 0.26.11.1.1 (R3)
      else if ($1 == "stand-in") { n0 = s; sub(/^stage-/, "", n0); print k "\t" s "\tstand-in " n0 " " $2 " — " w " · yours alone: answer limit \"<words>\" to pay it against the stand-in, a known limit, or again once the real service is on, to deploy and run staging afresh at this candidate" }   # 0.26.11.1.1 (R4)
      else if ($2 == "d1" || $2 == "rh") print k "\t" s "\tthe " ($2 == "rh" ? "rehearsal RH" : "staging deploy D1") " of " s ": " ($1 == "lost" ? "lost twice" : $1 == "refused" ? "its report refused twice: " substr(w, 8) : $1 == "failed" ? "failed twice at " substr(w, 4) ", which DevAgent says needs no product change" : "failed at " substr(w, 4) ", needing a product change, and its row was declined") " · answer again" (($1 == "declined") ? " to okay the same commit again" : "")
      else if ($2 == "p1cx" || $2 == "s1") print k "\t" s "\tthe close of " s ", " ($2 == "s1" ? "its grade S1" : "its rest chunk p1cx") ", lost twice · answer again"
      else print k "\tstep " s "\tthe close of " s ", chunk " $2 ", lost twice; its rows could not run: " w (($1 == "lost" && ($2 in SA)) ? " · the same as the attempt before, at this commit, so a bare again reads the same · answer again with what must change first, which DevAgent is told, or limit" : " · answer again, or limit") }' "$f"; done; }
# v0.26.10.25.5 (R1, R3): a draft asked, its count in words, until it lands or the owner says no
d_items() { for x in $(ls "$D/drafts" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do X=$D/drafts/$x; [ -f "$X/asked" ] && [ ! -f "$X/landed" ] && [ ! -f "$X/declined" ] && [ ! -f "$X/replaced" ] || continue
    w=$(cat "$X/state" 2>/dev/null); printf 'draft:%s\tthe spec\tdraft %s by SP: %s · %s%s · answer yes to land it, or no\n' "$x" "$x" "$(cat "$X/why")" "$(cat "$X/words" 2>/dev/null)" "${w:+ · $w}"; done; }
# v0.26.10.26.4 (R2): every finding of a stage, `key TAB stage TAB candidate TAB source TAB words`: each line of every candidate's
# findings (S1's grades and finding: lines; an unmatched case keyed by its name, once) and of its W1's (but a withdrawn walk's); and
# each moved here by `later <M>`, at this stage's newest candidate, once it has one
s_all() { for x in $(ls "$D/stage" 2>/dev/null | sort -n); do for c in $(ls "$D/stage/$x" | grep -E '^[0-9]+$' | sort -n); do F=$D/stage/$x/$c; [ -f "$F/named" ] || continue
      [ ! -f "$F/findings" ] || awk -v x="$x" -v c="$c" '{ if ($1 == "unmatched") print "stage:" x ":case:" $2 "\t" x "\t" c "\tthe rest chunk\t" $0; else print "stage:" x ":" c ":" NR "\t" x "\t" c "\t" ($1 == "grade" ? "S1" : "S1") "\t" $0 }' "$F/findings"
      [ ! -f "$F/w1/findings" ] || awk -F'\t' -v x="$x" -v c="$c" '{ w = $2; sub(/^W1 /, "", w); print "stage:" x ":" c ":w" NR "\t" x "\t" c "\tW1\t" w }' "$F/w1/findings"; done
    m=$(ls "$D/stage/$x" | grep -E '^[0-9]+$' | sort -n | while read -r c; do [ -f "$D/stage/$x/$c/named" ] && echo "$c"; done | tail -n 1)
    [ -z "$m" ] || awk -F'\t' -v x="$x" -v c="$m" '$2 == x { print "stage:" x ":moved:" $1 "\t" x "\t" c "\tmoved from " $4 "\t" $3 }' "$Q/moves" 2>/dev/null; done | awk -F'\t' '!s[$1]++'; }
s_items() { s_all | awk -F'\t' -v A="$Q/answers" -v RF="$Q/recommend" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } while ((getline l < RF) > 0) { split(l, x, "\t"); R[x[1]] = x[2] " — " x[3] } }
    !($1 in D) { print $1 "\tstage " $2 "\tstage " $2 "'"'"'s finding (" $4 ", candidate " $3 "): " $5 " · rule it: row, no, known, or later <M>" (($1 in R) ? " · recommended: " R[$1] : "") }'; }
# v0.26.10.27.1 (R3, R6): the owner's production yes, `production:<N>:<c>:<rh issue>`, open until a yes (a no keeps it open, declined),
# superseded once its candidate is no longer the newest closed one; an interrupted production deploy, `production-lost:<issue>`
p_items() { L0=$(sed -n 's/^stage-closed \([0-9]*\) | stand-in: RM at [0-9a-f]* candidate \([0-9]*\).*/\1\/\2/p' "$HAND" 2>/dev/null | tail -n 1)
  for f in $(ls "$D"/stage/*/*/yes 2>/dev/null); do x=${f%/yes}; x=${x#$D/stage/}; [ "$x" = "$L0" ] || continue; IFS=$TAB read -r k w < "$f"; X=$(cat "$D/stage/$x/commit"); p=$(awk -F'\t' 'NF { c = $1 } END { print c }' "$D/production" 2>/dev/null)
    if [ -n "$p" ] && [ "$p" != none ] && [ "$p" != "$X" ] && ! git --git-dir=.vid/code merge-base --is-ancestor "$p" "$X" 2>/dev/null; then continue; fi
    awk -F'\t' -v k="$k" '$2 == k && $3 == "yes" { f = 1 } END { exit f }' "$Q/answers" || continue; n=$(awk -F'\t' -v k="$k" '$2 == k && $3 == "no" { f = 1 } END { print f + 0 }' "$Q/answers")
    la=$(liveaddr); if [ -n "$la" ]; then la=" · Production runs now at $la."; elif [ -f "$D/stage/$x/cs/issue-closed" ] && ! stays "$D/stage/$x"; then la=' · The test site was taken down after its run.'; fi   # v0.26.10.28.8 (R7)
    printf '%s\tproduction\t%s%s%s%s\n' "$k" "$w" "$la" "$([ "$n" = 1 ] && echo ' · declined: the owner may still say yes')" "$(! oopen || echo ' · A grade of the whole product is offered first: answer grade, or yes without it.')"; done
  [ -f "$D/production-lost" ] && awk -F'\t' '{ l[$1] = $0; if (!($1 in o)) o[$1] = ++n } END { for (i in l) print o[i] "\t" l[i] }' "$D/production-lost" | sort -n | cut -f2- | while IFS=$TAB read -r i n c st; do k=production-lost:$i
    [ "$st" != settled ] || continue; grep -q "^[^	]*	$k	" "$Q/answers" && continue   # v0.26.10.27.3: the newest line of each, hidden once settled
    printf '%s\tproduction\tProduction'"'"'s deploy (#%s, stage %s) %s: DevAgent is asked what production runs now · %s\n' "$k" "$i" "$n" "$([ "$st" = reported ] && echo 'failed, and no recovery was reported' || echo 'has not reported')" "$( { [ "$st" = started ] || awk -F'\t' -v i="$i" '$1 == "issue" && $2 == i && index($4, "vid: started") { f = 1 } END { exit !f }' "$RD" 2>/dev/null; } && echo 'it started: only DevAgent'"'"'s vid: recovered settles it' || echo 'answer known "<the commit production runs>", or known none')"; done; return 0; }
# v0.26.10.27.4 (R4): the grade offered before the first go-live, on every production item while production has no commit and the
# owner has answered neither grade nor yes ($Q/offer: `grade <ask>` or `yes`); ohold: that grade ask neither withdrawn nor read with
# every finding ruled, which refuses every production yes, on any item
pcom() { awk -F'\t' 'NF && $1 != "none" { c = $1 } END { print c }' "$D/production" 2>/dev/null; }
oopen() { [ ! -f "$Q/offer" ] && [ -z "$(pcom)" ]; }
ohold() { n=$(sed -n 's/^grade //p' "$Q/offer" 2>/dev/null); [ -n "$n" ] && [ ! -f "$D/grade/$n/withdrawn" ] || return 1; [ -f "$D/grade/$n/done" ] || return 0; g_items | grep -q "^grade:$n:"; }
# v0.26.10.27.2 (R1, R2): an owner's grade ask's findings, `grade:<n>:<j>` (j its line of the read), each grade but pass and each finding
# line, from the ask's commit alone (a vs word shown in its requirement's item), ranked high, absent, facade, medium, partial, low, then
# findings with no severity; and `grade:<n>:lost`, while the ask is lost
g_items() { for n in $(ls "$D/grade" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do X=$D/grade/$n
    [ ! -f "$X/lost" ] || [ -f "$X/withdrawn" ] || printf '0\t%s\t0\tgrade:%s:lost\tgrade #%s\tgrade ask #%s could not be read: no report came, asked again once · answer again for another ask, or no to withdraw it\n' "$n" "$n" "$n" "$n"
    [ -f "$X/done" ] && [ -f "$X/read" ] || continue; vs=$(sed -n "s/^vs$TAB//p" "$X/ask" | head -n 1)
    awk -F'\t' -v n="$n" -v vs="$vs" -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } R["high"] = 1; R["absent"] = 2; R["facade"] = 3; R["medium"] = 4; R["partial"] = 5; R["low"] = 6 }
      NR == 1 { next } { k = "grade:" n ":" (NR - 1); if (k in D) next }
      $1 == "grade" && $3 != "pass" { print R[$3] "\t" n "\t" NR "\t" k "\tgrade #" n "\tgrade ask #" n ": " $2 " " $3 " — " $4 ($5 != "" ? " · vs " vs ": " $5 " — " $6 : "") " · rule it: row, fix, no, or known" }
      $1 == "finding" { w = $2; v = w; sub(/^finding: [a-z]+ ?/, "", v); v = (v ~ /^(high|medium|low) /) ? substr(v, 1, index(v, " ") - 1) : ""; print ((v in R) ? R[v] : 7) "\t" n "\t" NR "\t" k "\tgrade #" n "\tgrade ask #" n "'"'"'s " w " · rule it: row, fix, no, or known" }' "$X/read"; done | sort -t"$TAB" -k1,1n -k2,2n -k3,3n | cut -f4-; }   # ranked across every ask, a lost one first
# v0.26.10.26.7 (R2, W-2): the setup hold is a question like any other wait, answered by continue
# v0.26.10.28.8 (R9): with no stage after the held one (no STAGES.md, one stage, or its last), no stage is named that does not exist
hstage() { sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" | sort -n | head -n 1; }
h_items() { holding || return 0; n=$(hstage); if [ "$((n + 1))" -le "$(qfin)" ]; then printf 'hold:%s\tstage %s\tstage %s waits until staging has passed once · answer continue to build on\n' "$n" "$((n + 1))" "$((n + 1))"
  else printf 'hold:%s\tnothing\tstaging has not passed once yet; stage %s is the last stage, so nothing waits on it · answer continue to clear the hold\n' "$n" "$n"; fi; }
# v0.26.10.26.7 (R13, W-15): the compaction question, while .claude/settings.json sets no autoCompactWindow and no context-window event answers it
x_items() { grep -q '"autoCompactWindow"' .claude/settings.json 2>/dev/null && return 0; grep -q '^context-window ' .vid/metrics-events 2>/dev/null && return 0
  printf 'context:window\tnothing\tmay ViD set this project'"'"'s compaction point to 300,000 tokens, so this session compacts before its context grows costly? · answer yes or no\n'; }
# 0.26.11.1.1 (R3): each duty a passed production deploy left missing or not done, `pduty:<issue>:<duty>`, until the owner's known or a
# later passed production report (by its okay's asked time) saying it done
u_items() { for f in $(ls "$D"/stage/*/*/d2*/read 2>/dev/null); do [ "$(head -n 1 "$f" | cut -f2)" = passed ] || continue; i=$(sed -n "s/^issue$TAB//p" "${f%/read}/ask" | head -n 1); a=$(sed -n "s/^asked$TAB//p" "${f%/read}/ask" | head -n 1)
    awk -F'\t' -v i="$i" -v a="$a" '$1 == "duty" { print a "\t" i "\t" $2 "\t" $3 "\t" $4 }' "$f"; done | sort | awk -F'\t' -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } }
    { k = "pduty:" $2 ":" $3 } $4 == "done" { for (j in O) if (U[j] == $3) delete O[j]; next } ($4 == "missing" || $4 == "not done") && !(k in D) { O[k] = ++n; U[k] = $3; W[k] = ($4 == "missing") ? "not answered" : $5 }
    END { for (k in O) print O[k] "\t" k "\tproduction\tproduction duty " U[k] ": " W[k] " · yours alone: answer known \"<words>\", or a later production deploy reports it done" }' | sort -n | cut -f2-; }
items() { held_items; q_items; f_items; c_items; s_items; p_items; u_items; d_items; g_items; h_items; x_items; }
num() { awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$Q/ids"; }
nextq() { n=$(sed -n 's/^questions:.*next Q\([0-9][0-9]*\).*/\1/p' "$RS" | head -n 1); m=$(awk -F'\t' '{ sub(/^Q/, "", $2); if ($2 + 0 > m) m = $2 + 0 } END { print m + 1 }' "$Q/ids"); a=$(awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+ / { sub(/^- Q/, ""); sub(/ .*/, ""); if ($0 + 0 > m) m = $0 + 0 } END { print m + 1 }' "$RS"); for x in "$m" "$a"; do [ "${n:-0}" -ge "$x" ] || n=$x; done; echo "$n"; }
cmd_sync() { items > "$Q/it0" || exit 1; put "$Q/items" < "$Q/it0" || exit 1; : > "$Q/lines"
  while IFS=$TAB read -r k g w; do n=$(num "$k"); if [ -z "$n" ]; then n=Q$(nextq); printf '%s\t%s\t%s\n' "$k" "$n" "$(stamp)" >> "$Q/ids"; ev "queue-asked $n what=${k%%:*}"; fi
    a=$(awk -F'\t' -v k="$k" '$1 == k { print $3; exit }' "$Q/ids"); printf -- '- %s · asked %s · gates %s · %s\n' "$n" "$a" "$g" "$w" >> "$Q/lines"; done < "$Q/items"
  # the section: our lines, and the session's own planning questions as they were
  qsec() { cat > "$Q/rs0" || return 1; awk -F'\t' '{ print $2 }' "$Q/ids" > "$Q/ours"; k=$(( $(grep -c . "$Q/lines") + $(awk -v O="$Q/ours" 'BEGIN { while ((getline l < O) > 0) o[l] = 1 } /^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+ / && !($2 in o) { n++ } END { print n + 0 }' "$Q/rs0") )); nq=$(nextq)
  awk -v L="$Q/lines" -v O="$Q/ours" -v K="questions: $k open · next Q$nq" 'BEGIN { while ((getline l < O) > 0) ours[l] = 1 }
    /^questions:/ { print K; kd = 1; next }
    /^## Open product questions/ { print; print ""; while ((getline l < L) > 0) print l; on = 1; next } on && /^## / { on = 0 }
    on && /^- Q[0-9]+ / { q = $2; if (q in ours) next } on && !NF { next } { print } END { if (!kd) {} }' "$Q/rs0" > "$Q/rs" || return 1
  grep -q '^questions:' "$Q/rs" || sed "1a\\
questions: $k open · next Q$nq" "$Q/rs" > "$Q/rs2" && mv "$Q/rs2" "$Q/rs" 2>/dev/null; grep -q '^## Open product questions' "$Q/rs" || { printf '\n## Open product questions\n\n' >> "$Q/rs"; cat "$Q/lines" >> "$Q/rs"; } || return 1; cat "$Q/rs"; }
  rs_edit qsec || exit 1   # 0.26.10.28.4 (9.3 R2): through the run record's one writer
  awk -F'\t' -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } } $4 == "seen" && !("question:" $1 in D) { print "question " substr($1, 1, index($1, ":") - 1) " " substr($1, index($1, ":") + 1) }' "$Q/questions"
  cmd_regress | while IFS= read -r l; do grep -qxF "$l" "$Q/seen" || { echo "$l" >> "$Q/seen"; echo "$l"; }; done   # v0.26.10.26.3 (R3): once a close
  for f in "$Q"/f.*; do [ -f "$f" ] || continue; p=${f##*.}; t=$(awk -F'\t' -v p="$p" '($1 == "open" || $1 == "merged") && $2 == p { print $3; exit }' "$RD"); awk -v t="$t" '{ s = ($2 ~ /^(high|medium|low)$/) ? $2 : "low"; w = $0; sub(/^[^—]*— /, "", w); print "finding " t " " s " " substr(w, 1, 60) }' "$f"; done | while IFS= read -r l; do grep -qxF "$l" "$Q/seen" || { echo "$l" >> "$Q/seen"; echo "$l"; }; done
  # an answer the owner gave on a held row that the next decision still holds (but amend)
  awk -F'\t' '$5 == "owner" && $2 ~ /^held:/ && $3 != "d" { sub(/^held:/, "", $2); print $2 "\t" $1 }' "$Q/answers" | while IFS=$TAB read -r r when; do
    grep -q "^held:$r$TAB" "$Q/items" && awk -F'\t' -v r="$r" -v w="$when" '$4 == r && $1 > w && $5 == "held" { f = 1 } END { exit !f }' "$D/log" && echo "unreleased $r"; done; return 0; }
# v0.26.10.26.7 (R2, R13): the hold's and the compaction question's lines, once; only the sync verb prints them, so a silent
# sync inside ask or answer never marks one seen unprinted
announce() { awk -F'\t' '$1 ~ /^hold:/ { k = $1; sub(/^hold:/, "", k); print "hold " k }' "$Q/items" | while IFS= read -r l; do grep -qxF "$l" "$Q/seen" || { echo "$l" >> "$Q/seen"; echo "$l $(num "hold:${l#hold }")"; }; done
  ! grep -q '^context:window	' "$Q/items" || grep -qx 'context-window' "$Q/seen" || { echo 'context-window' >> "$Q/seen"; echo "context-window $(num context:window)"; }; return 0; }
# dev-side questions, from the round's read: a comment whose first line begins `Question:`, or a role's prefix and `question`
cmd_scan() { awk -F'\t' -v Q="$Q/questions" 'BEGIN { while ((getline l < Q) > 0) { split(l, x, "\t"); K[x[1]] = 1 } }
    function sc(n, h,   c, i, m, rm) { m = split(h, c, "\001"); for (i = 1; i <= m; i++) if (c[i] ~ /^RM: /) rm = rm "\001" c[i]
        for (i = 1; i <= m; i++) if (c[i] ~ /^Question:/ || c[i] ~ /^[A-Z][A-Z]: [Qq]uestion/) { k = n ":" i; if (k in K) continue; a = index(rm, c[i]) ? "answered" : "seen"; gsub(/\t/, " ", c[i]); print k "\t" n "\t" c[i] "\t" a >> Q } }
    $1 == "open" { sc($2, $10) } $1 == "merged" { sc($2, $6) } $1 == "issue" { sc($2, $4) }' "$RD" 2>/dev/null; }
qn() { awk -F'\t' -v q="$1" '$2 == q { print $1; exit }' "$Q/ids"; }
rec() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(stamp)" "$1" "$2" "$3" "$4" "$5" >> "$Q/answers"; ev "queue-answered what=${1%%:*} by=$4"; }
unblock() { n=$1; awk -F'\t' -v n="$n" -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); D[x[2]] = 1 } } $2 == n && $4 != "answered" && !("question:" $1 in D) { f = 1 } END { exit f }' "$Q/questions" && sh "$HERE/github.sh" label "$n" --remove blocked > /dev/null 2>&1 || true; }
# v0.26.10.28.8: who answered — owner (the default: the owner's own words), RM (from the spec),
# delegate (RM in the owner's place, under the owner's delegation), or stand-in (the round's, for an absent answerer), recorded as
# given; what is the owner's alone refuses every one but the owner
cmd_answer() { [ $# -ge 2 ] || die 'usage — answer <Q<n>|<n>:<k>> [--by RM|delegate|stand-in] …'; t=$1; QT=$1; shift; BY=owner; [ "$1" = --by ] && { BY=$2; shift 2; }
  case $BY in owner|RM|delegate|stand-in) ;; *) die "--by $BY: the owner (no --by), RM, delegate, or stand-in (the round's, for an absent answerer)" ;; esac
  case $t in Q[0-9]*) k=$(qn "$t"); [ -n "$k" ] || die "$t is no line of the queue" ;; *:*) k=question:$t ;; *) die "no question $t" ;; esac
  case $k in
    held:*) r=${k#held:}; v=$1; shift; case $v in a) w=accept ;; b) w="more ${1:-1}"; [ $# -gt 0 ] && shift ;; c) w=limit ;; d) w=amend ;; *) die 'a held row: a, b <N>, c or d' ;; esac
      sh "$HERE/decide.sh" rule "$r" $w --by "$BY" > /dev/null || die "the ruling on $r was refused"; rec "$k" "$v" "$*" "$BY" "${w%% *}"
      [ "$v" != d ] || echo "door: /vid fix — amend ${r%-T[0-9]*} in the owner's words: $*" ;;
    question:*) i=${k#question:}; n=${i%%:*}; [ "$BY" = owner ] || ! cat "$D"/stage/*/*/d2/ask 2>/dev/null | awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { f = 1 } END { exit !f }' || die "a question on a production okay is the owner's alone"; l=$(awk -F'\t' -v i="$i" '$1 == i { print $3; exit }' "$Q/questions"); [ -n "$l" ] || die "no question $i"
      printf 'RM: %s\n\n%s\n' "$l" "$*" > "$Q/post"; sh "$HERE/github.sh" comment "$n" --body-file "$Q/post" > /dev/null || die "the answer on #$n could not be posted"
      rec "$k" - "$*" "$BY" "$([ "$BY" = owner ] && echo answered || echo delegated)"; unblock "$n" ;;
    findings:*|finding:*) tk=${k#*:}; tk=${tk%%:*}; f=$1; v=$2; shift 2; case $v in fix|row|known|no) ;; *) die 'a finding: fix, row, known or no' ;; esac
      p=$(awk -F'\t' -v t="$tk" '$2 == t { p = $1 } END { print p }' "$Q/prs" 2>/dev/null); [ -n "$p" ] || p=$(awk -F'\t' -v t="$tk" '($1 == "open" || $1 == "merged") && $3 == t { print $2; exit }' "$RD"); l=$(fnd "$p" | sed -n "${f}p"); [ -n "$l" ] || die "no finding $f of #$tk"
      [ "$v" != known ] || { grep -qxF "$l" .vid/tw/known-findings 2>/dev/null || echo "$l" >> .vid/tw/known-findings; }; rec "finding:$tk:$f" "$v" "$*" "$BY" "$([ "$v" = no ] || [ "$v" = known ] && echo ruled || echo 'to the door: SP drafts its row')"
      case $v in fix|row) echo "finding:$tk:$f" >> "$Q/doors"; echo "door: /vid fix — a new row for the finding of #$tk: $l (the owner: $*) · draft it with --for finding:$tk:$f" ;; esac ;;
    production:*) [ "$BY" = owner ] || die 'the production yes is the owner'"'"'s alone'; v=${1:-}; [ $# -gt 0 ] && shift; case $v in yes|no|grade) ;; *) die 'production: yes, no or grade' ;; esac
      if [ "$v" = grade ]; then oopen || die 'no grade is offered here: answered already, or production has a commit'   # v0.26.10.27.4 (R4)
        LV=$(sh "$HERE/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u | paste -sd ' ' -)
        # the ask at the item's own candidate
        PC=$(cat "$D/stage/$(echo "$k" | cut -d: -f2)/$(echo "$k" | cut -d: -f3)/commit" 2>/dev/null); sh "$HERE/grade.sh" ask --reqs "$LV" ${PC:+--commit "$PC"} > "$Q/ga" 2>&1 || die "the grade could not be asked: $(tail -n 1 "$Q/ga")"; n=$(sed -n 's/^asked \([0-9]*\) grade .*/\1/p' "$Q/ga")
        echo "grade $n" > "$Q/offer"; rec "$k" grade "$*" "$BY" "grade ask #$n"; ev "production-grade ask=$n"; echo "asked $n grade before the first go-live"
      else if [ "$v" = yes ]; then ! ohold || die "the production yes waits: the grade before the first go-live, ask #$(sed -n 's/^grade //p' "$Q/offer"), is out or has findings unruled"; [ -f "$Q/offer" ] || ! oopen || echo yes > "$Q/offer"; fi
      rec "$k" "$v" "$*" "$BY" "$([ "$v" = yes ] && echo approved || echo declined)"; [ "$v" != yes ] || ev "production-yes stage=$(echo "$k" | cut -d: -f2) candidate=$(echo "$k" | cut -d: -f3)"; fi ;;
    production-lost:*) [ "$BY" = owner ] || die 'what production runs is the owner'"'"'s word, or DevAgent'"'"'s'; i=${k#production-lost:}; v=${1:-}; [ "$v" = known ] || die 'known "<commit>" or known none'; shift; cm=${1:?}; shift
      # a deploy that started and has not reported, by the snapshot or by the issue as it stands now, is DevAgent's to settle
      st=$(awk -F'\t' -v i="$i" '$1 == i { print $4 }' "$D/production-lost" | tail -n 1); [ "$st" != settled ] || die "#$i is settled already"
      if [ "$st" = started ] || awk -F'\t' -v i="$i" '$1 == "issue" && $2 == i && index($4, "vid: started") { f = 1 } END { exit !f }' "$RD" 2>/dev/null; then die "#$i started: only DevAgent's vid: recovered settles it"; fi
      p0=$(awk -F'\t' 'NF { c = $1 } END { print c }' "$D/production" 2>/dev/null); [ "$cm" != none ] || [ -z "$p0" ] || [ "$p0" = none ] || die 'known none is for a first deploy, before any production'
      L=$(awk -F'\t' -v i="$i" '$1 == i { print $2 "/" $3 }' "$D/production-lost" | tail -n 1); printf '%s\t%s\t%s\n' "$([ "$cm" = none ] && echo none || git --git-dir=.vid/code rev-parse "$cm" 2>/dev/null || echo "$cm")" "known #$i" "$(stamp)" >> "$D/production"
      echo "known $cm" > "$Q/kc" || exit 1; put "$D/stage/$L/d2/closed" < "$Q/kc" || exit 1; rm -f "$D/stage/$L/d2/atcand"; printf '%s\t%s\tsettled\n' "$i" "$(echo "$L" | tr / '\t')" >> "$D/production-lost"
      X0=$(sed -n "s/^commit$TAB//p" "$D/stage/$L/d2/ask"); w0="production of $(printf %.12s "$X0") reconciled at $(printf %.12s "$cm"): again re-arms its okay #$((i * 1000))"; grep -qxF "$w0" "$D/stage/$L/d2/items" 2>/dev/null || echo "$w0" >> "$D/stage/$L/d2/items"; printf 'vid: withdrawn. This deploy is abandoned; do not deploy it.\nby: RM\n' > "$Q/post"; sh "$HERE/github.sh" comment "$i" --body-file "$Q/post" > /dev/null 2>&1 || true; sh "$HERE/github.sh" close "$i" > /dev/null 2>&1 || true   # v0.26.10.27.3: its again item now
      rec "$k" known "$cm $*" "$BY" settled ;;
    grade:*:lost) v=${1:-}; [ $# -gt 0 ] && shift; x=$(printf %s "$k" | cut -d: -f2); case $v in again) sh "$HERE/grade.sh" again "$x" > /dev/null || die "ask $x was not lost"; rec "$k" again "$*" "$BY" 'asked again' ;;
        no) sh "$HERE/grade.sh" withdraw "$x" > /dev/null; rec "$k" no "$*" "$BY" withdrawn ;; *) die 'a lost grade ask: again or no' ;; esac ;;
    grade:*) v=${1:-}; [ $# -gt 0 ] && shift; x=$(printf %s "$k" | cut -d: -f2); j=$(printf %s "$k" | cut -d: -f3); w=$(sed -n "$((j + 1))p" "$D/grade/$x/read" | cut -f2- | tr '\t' ' ')
      case $v in   # v0.26.10.27.2 (R2): 7.4's answers but later, for a grade ask belongs to no stage
        row|fix) t=row; case $w in *'finding: rule'*) t='rule row, its places counted in covers:, armed in every later ticket' ;; *'finding: bug'*) t='row, a regression row once accepted' ;; esac
          rec "$k" "$v" "$*" "$BY" 'to the door: SP drafts its row'; echo "$k" >> "$Q/doors"; echo "door: /vid fix — a new $t, for grade ask #$x's line: $w (the owner: $*) · draft it with --for $k" ;;
        no) rec "$k" no "$*" "$BY" ruled ;;
        known) grep -qxF "$w" .vid/tw/known-findings 2>/dev/null || echo "$w" >> .vid/tw/known-findings; rec "$k" known "$*" "$BY" ruled ;;
        *) die 'a grade finding: row, fix, no, or known' ;; esac ;;
    stage:*) v=${1:-}; [ $# -gt 0 ] && shift; w=$(s_all | awk -F'\t' -v k="$k" '$1 == k { print $5; exit }'); x=$(printf %s "$k" | cut -d: -f2)
      case $v in
        row|fix) t=row; case $w in *'finding: rule '*) t='rule row, its places counted in covers:' ;; *'finding: bug '*) t='row, a regression row once accepted' ;; esac
          rec "$k" "$v" "$*" "$BY" 'to the door: SP drafts its row'; echo "$k" >> "$Q/doors"; echo "door: /vid fix — a new $t for stage $x's finding: $w (the owner: $*) · draft it with --for $k" ;;
        no) rec "$k" no "$*" "$BY" ruled ;;
        known) grep -qxF "$w" .vid/tw/known-findings 2>/dev/null || echo "$w" >> .vid/tw/known-findings; rec "$k" known "$*" "$BY" ruled ;;
        later) M=${1:-}; [ $# -gt 0 ] && shift; case $M in ''|*[!0-9]*) die 'later <M>: a stage number' ;; esac; [ "$M" -gt "$x" ] || die "later $M: stage $M is not after stage $x"
          sed -n '/^```vid-stages/,/^```$/p' STAGES.md 2>/dev/null | awk -F'|' -v m="$M" '{ k = $1; gsub(/[ \t]/, "", k); sub(/^STAGE-0*/, "", k); if (k == "") k = 0 } k == m && $1 ~ /STAGE-/ { f = 1 } END { exit !f }' || die "later $M: no stage $M in STAGES.md"
          printf '%s\t%s\t%s\tstage %s\n' "$k" "$M" "$w" "$x" >> "$Q/moves"; rec "$k" "later $M" "$*" "$BY" "moved to stage $M" ;;
        *) die 'a stage finding: row, fix, no, known, or later <M>' ;; esac ;;
    context:window) v=${1:-}; [ $# -gt 0 ] && shift; case $v in   # v0.26.10.26.7 (R13): yes writes the setting; the event either way
        yes) mkdir -p .claude; if [ ! -f .claude/settings.json ] || [ "$(tr -d ' \t\r\n' < .claude/settings.json)" = '{}' ] || [ ! -s .claude/settings.json ]; then printf '{\n  "autoCompactWindow": 300000\n}\n' | put .claude/settings.json
            else awk '!d && index($0, "{") { i = index($0, "{"); print substr($0, 1, i); print "  \"autoCompactWindow\": 300000,"; r = substr($0, i + 1); if (r ~ /[^ \t]/) print r; d = 1; next } { print }' .claude/settings.json > "$Q/cs" && put .claude/settings.json < "$Q/cs"; fi
          ev 'context-window requested=300000'; rec "$k" yes "$*" "$BY" 'set to 300000' ;;
        no) ev 'context-window requested=declined'; rec "$k" no "$*" "$BY" declined ;; *) die 'the compaction question: yes or no' ;; esac ;;
    hold:*) v=${1:-}; [ $# -gt 0 ] && shift; [ "$v" = continue ] || die 'the setup hold: continue'; holding || die 'the setup hold is off already'
      if grep -q '^run: *stopped owner asked to pause' "$RS"; then cmd_control continue "$*"; exit 0; fi   # a recorded pause first: continue ends it, the hold stays
      hold_off "$*"; rec "$k" continue "$*" "$BY" 'hold off' ;;   # v0.26.10.26.7 (R2)
    draft:*) x=${k#draft:}; X=$D/drafts/$x; v=${1:-}; [ $# -gt 0 ] && shift; case $v in
        yes) rc=0; sh "$HERE/land.sh" "$x" --words "${*:-yes}" > "$Q/land" 2>&1 || rc=$?; cat "$Q/land"
          case $rc in 0) : > "$X/state"; rec "$k" yes "$*" "$BY" landed ;; 3) echo 'waits for continue: say yes again after continuing' > "$Q/xs" || exit 1; put "$X/state" < "$Q/xs" || exit 1; ev "queue-waits what=draft n=$x" ;;
            4) echo 'stale: HEAD moved since it was drafted, and SP redrafts it' > "$Q/xs" || exit 1; put "$X/state" < "$Q/xs" || exit 1; ev "queue-stale what=draft n=$x" ;; *) echo "refused, nothing landed: $(grep -m 1 'refused' "$Q/land" | sed 's/^ViD land: refused — //')" > "$Q/xs" || exit 1; put "$X/state" < "$Q/xs" || exit 1; ev "queue-refused what=draft n=$x" ;; esac
          cmd_sync > /dev/null; [ "$rc" = 0 ] || exit "$rc" ;;
        no) : > "$X/declined"; rec "$k" no "$*" "$BY" declined ;; *) die 'a draft: yes or no' ;; esac ;;
    pduty:*) [ "$BY" = owner ] || die "a production duty's known is the owner's alone, never $BY's"; [ "${1:-}" = known ] && [ -n "${2:-}" ] || die 'a production duty: known "<words>"'; shift
      rec "$k" known "$*" "$BY" ruled ;;   # 0.26.11.1.1 (R3)
    close:*/cs:stand-in:*) [ "$BY" = owner ] || die "a stand-in row is the owner's alone, never $BY's"; v=${1:-}; [ $# -gt 0 ] && shift; s=$(printf %s "$k" | cut -d: -f2); r=$(printf %s "$k" | cut -d: -f4); CF=$(cdir "$s")   # 0.26.11.1.1 (R4)
      case $v in limit) [ -n "$*" ] || die 'limit "<words>": why it is paid against a stand-in'; n0=$(printf %s "$k" | cut -d: -f5)
          { grep -v "^row $r " "$HAND" || true; printf 'row %s paid | stand-in: CS #%s against a stand-in, a known limit: %s (the owner)\n' "$r" "$n0" "$(printf '%s' "$*" | tr '\n|' '  ')"; } > "$Q/h" || exit 1; put "$HAND" < "$Q/h" || exit 1; x0=${s#stage-}; ev "stage-paid stage=${x0%%/*} row=$r issue=$n0 by=limit" ;;
        again) echo "$r" >> "$CF/stand-in-again" ;; *) die 'a stand-in row: limit "<words>" or again' ;; esac
      grep -v "^stand-in $r " "$CF/items" > "$Q/ci" || true; put "$CF/items" < "$Q/ci" || exit 1; rec "$k" "$v" "$*" "$BY" ruled ;;
    close:*/d1:notdone:*) v=${1:-}; du=$(printf %s "$k" | cut -d: -f4); [ "$v" = known ] || { [ "$v" = again ] || die 'a duty not done: again, or known "<words>"'; echo 'allow refused' >> "$(cdir "$(printf %s "$k" | cut -d: -f2)")/again"; }   # 0.26.11.1.1 (R3)
      CF=$(cdir "$(printf %s "$k" | cut -d: -f2)"); if [ "$v" = known ]; then [ "$BY" = owner ] || die "a duty's known is the owner's alone, never $BY's"; shift; [ -n "$*" ] || die 'known "<words>"'
        printf '%s\t%s\t%s\t%s\n' "$du" "$(printf '%s' "$*" | tr '\t\n' '  ')" "$BY" "$(stamp)" >> "$D/duties-known"; ev "duty-known duty=$du by=$BY"; else shift; fi
      grep -v "^notdone $du " "$CF/items" > "$Q/ci" || true; put "$CF/items" < "$Q/ci" || exit 1; rec "$k" "$v" "$*" "$BY" ruled ;;
    close:*) v=$1; shift; s=$(printf %s "$k" | cut -d: -f2); ch=$(printf %s "$k" | cut -d: -f4)
      CF=$(cdir "$s"); case $v in again) case $k in close:*/w1:*|close:*/d2:*) echo "allow again" >> "$CF/again" ;; close:*/d1:*|close:*/rh:*) echo "allow $(printf %s "$k" | cut -d: -f3)" >> "$CF/again" ;; close:*:lost:*|close:*:twice:*) case $k in close:*:lost:*) ! grep -qxF "$ch" "$CF/same" 2>/dev/null || [ -n "$*" ] || die "chunk $ch read the same as the attempt before, at this commit: a bare again reads the same — answer again \"<what must change first>\", which DevAgent is told, or limit"   # 0.26.10.28.10 (R2)
            [ -z "$*" ] || printf '%s\t%s\n' "$ch" "$(printf '%s' "$*" | tr '\t\n' '  ')" >> "$CF/againwhy" ;; esac; echo "allow $ch" >> "$CF/again" ;;
          close:*:shrink:*) echo 'allow shrink' >> "$CF/again" ;;   # 0.26.10.29.2 (R7): the fix line, the rows red twice too; answered, its red items, held back, come again at the next decide
          *) die 'again is for a lost chunk or a row red again after its fix; a red one has its fix ticket, or a limit' ;; esac ;;
        close) case $k in close:*/w1:*) ;; *) die 'close without the walk answers a walk not done for want of a browser alone' ;; esac   # 0.26.10.28.6 (R1 (b))
          [ "$*" = 'without the walk' ] || die 'the answer is: close without the walk'
          [ "$BY" = owner ] || die "close without the walk is the owner's answer alone, never $BY's"
          for o in done withdrawn none limit; do [ ! -f "$CF/$o" ] || die "this walk has ended already ($o): nothing to close"; done   # one outcome alone, never a second
          ws=$(ls "$CF" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1); [ -n "$ws" ] && [ "$(cut -f1 "$CF/$ws/read" 2>/dev/null)" = not-done ] && [ "$(cut -f2 "$CF/$ws/read" 2>/dev/null)" = 'browser: none' ] \
            || die 'close without the walk answers a walk not done for want of a browser alone: answer again'
          printf 'walk not done: no browser on this machine\nthe owner, %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$Q/wl" || exit 1; put "$CF/limit" < "$Q/wl" || exit 1
          sh "$HERE/walk.sh" pending > /dev/null 2>&1 || true; ev "walk-limit stage=$(printf %s "$s" | sed 's/^stage-//; s/\/.*//') candidate=$(printf %s "$s" | cut -d/ -f2) by=owner" ;;   # the CS issue kept open for the walk closes
        limit) case $k in close:*/w1:*) die "a walk holds no row: answer again" ;; esac; case $ch in p1cx|s1|d1) die "the rest chunk, S1 and D1 hold no row: answer again" ;; esac; case $k in close:*:twice:*) rs=$ch ;; close:*:shrink:*) rs=$(sed -n "s/^shrink $ch \(.*\) · before: .*/\1/p" "$CF/items" | tail -n 1) ;; *) rs=$(sed -n "s/^[a-z]* $ch //p" "$CF/items" | tr ' ' '\n' | sed 's/^[^:]*://' | grep '^[A-Z]') ;; esac; for r in $rs; do sh "$HERE/decide.sh" rule "$r" limit --by "$BY" > /dev/null 2>&1 && continue
            ts=$(awk -F'\t' -v r="$r" 'index($1, r "-T") == 1 { print $1 }' "$D/state"); [ -n "$ts" ] || die "the ruling on $r was refused"; for x in $ts; do sh "$HERE/decide.sh" rule "$x" limit --by "$BY" > /dev/null || die "the ruling on $x was refused"; done; done ;; *) die 'a close: again or limit (or, for a walk not done for want of a browser, close without the walk)' ;; esac
      case $k in close:*:twice:*) grep -v "^twice $ch " "$CF/items" > "$Q/ci" || true ;; close:*:shrink:*) grep -v -e "^shrink $ch " -e '^red ' "$CF/items" > "$Q/ci" || true ;; *) grep -v " $ch\( \|$\)" "$CF/items" > "$Q/ci" || true ;; esac; put "$CF/items" < "$Q/ci" || exit 1; rec "$k" "$v" "$*" "$BY" ruled ;;
  esac; echo "answered $QT"; }
# --- v0.26.10.26.3 (stage 7.3; R1–R3): the table's lines, the cost of each ticket, the regression tripwire. ViD's records alone ---
# EP: an awk function, an ISO UTC time to seconds; HM: seconds as `<h> h <m> m`
EP='function ep(s,   y, m, d, a) { if (s !~ /^[0-9]{4}-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z?$/) return -1; y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0; if (m <= 2) { y--; m += 12 }
    a = int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + d - 2440588 - 1524 + 2 - int(y / 100) + int(int(y / 100) / 4); return a * 86400 + substr(s, 12, 2) * 3600 + substr(s, 15, 2) * 60 + substr(s, 18, 2) }
  function hm(x) { return int(x / 3600) " h " int((x % 3600) / 60) " m" }
  function kv(l, k,   n, a, i) { n = split(l, a, " "); for (i = 1; i <= n; i++) if (index(a[i], k "=") == 1) return substr(a[i], length(k) + 2); return "" }'
# rjoin: $Q/rst, `<row> TAB <state> TAB <stage> TAB <class> TAB <marks> TAB <fault-proven 1|0>` for each row of planner.sh rows: its handed
# `row` line where one stands, else its newest decision (.vid/decide/state); a journey with neither, its transitions' (failing or held if any
# is, accepted only when every one is). States in one word: accepted-by-ruling, known-limit, evidence-missing; `-` for none
rjoin() { mustread "$Q/plr0" planner rows; grep -v '^#' "$Q/plr0" > "$Q/plr"; cat "$HAND" > "$Q/hd" 2>/dev/null || : > "$Q/hd"; cat "$D/state" > "$Q/ds" 2>/dev/null || : > "$Q/ds"
  awk -F'\t' 'FILENAME == ARGV[1] { if ($0 ~ /^row /) { split($0, a, " "); w = a[3]; sub(/\|.*/, "", w); H[a[2]] = w; FP[a[2]] = (index($0, " fault-proven ") > 0) } next }
    FILENAME == ARGV[2] { s = $2; gsub(/ /, "-", s); S[$1] = s; next }
    $2 == "tr" { TR[$3] = TR[$3] " " $1; next } $2 == "row" { O[++n] = $1; G[$1] = $5; C[$1] = $6; M[$1] = $7 }
    END { for (i = 1; i <= n; i++) { r = O[i]; s = "-"; if (r in H) s = H[r]; else if (r in S) s = S[r]; else if (TR[r] != "") { m = split(TR[r], t, " "); f = 0; h = 0; ok = 0; d = 0
          for (k = 1; k <= m; k++) { x = (t[k] in S) ? S[t[k]] : "-"; if (x == "failing") f = 1; else if (x == "held") h = 1; else if (x ~ /^(accepted|accepted-by-ruling|owed|passing)$/) ok++; if (x != "-") d = 1 }
          s = f ? "failing" : h ? "held" : (m && ok == m) ? "accepted" : d ? "evidence-missing" : "-" }
        print r "\t" s "\t" G[r] "\t" C[r] "\t" M[r] "\t" (FP[r] + 0) } }' "$Q/hd" "$Q/ds" "$Q/plr" > "$Q/rst" 2>/dev/null || : > "$Q/rst"; }
# tix: $Q/tix, `<ticket> TAB <kind> TAB <step> TAB <published at> TAB <rows, space-separated> TAB <withdrawn 1|0> TAB <rows as published>`, by
# .vid/tw/log, its newest rows and its first
tix() { awk "$EP"' $1 == "published" || $1 == "amended" { t = $2; if (!(t in K)) O[++n] = t; if ($1 == "published" && !(t in P)) { P[t] = kv($0, "at"); R0[t] = kv($0, "rows"); gsub(/,/, " ", R0[t]) } K[t] = kv($0, "kind"); S[t] = kv($0, "step"); R[t] = kv($0, "rows"); gsub(/,/, " ", R[t]) }
    $1 == "withdrawn" { W[$2] = 1 } END { for (i = 1; i <= n; i++) { t = O[i]; print t "\t" K[t] "\t" S[t] "\t" P[t] "\t" R[t] "\t" (W[t] + 0) "\t" R0[t] } }' .vid/tw/log 2>/dev/null > "$Q/tix" || : > "$Q/tix"; }
# ctime <step>: the step's close, in seconds, while its handed `closed` line stands: the newest close-closed event, or for C3's line
# (stage 7.1) the passed stage-c3 event of the stage folder whose ask names that issue; nothing while it is open
ctime() { l=$(grep "^closed $1 " "$HAND" 2>/dev/null | tail -n 1); [ -n "$l" ] || return 0; i=$(printf '%s\n' "$l" | sed -n 's/.*stand-in: C3 #\([0-9][0-9]*\).*/\1/p')
  if [ -n "$i" ]; then for a in "$D"/stage/*/*/ask; do [ -f "$a" ] && awk -F'\t' -v i="$i" '$1 == "issue" && $2 == i { f = 1 } END { exit !f }' "$a" || continue; x=${a%/ask}; c=${x##*/}; x=${x%/*}; n=${x##*/}
      awk "$EP"' $1 == "stage-c3" && kv($0, "stage") == N && kv($0, "ask") == C && kv($0, "result") == "passed" { t = ep(kv($0, "at")) } END { if (t != "") print t }' N="$n" C="$c" .vid/metrics-events 2>/dev/null; return 0; done
  else awk "$EP"' $1 == "close-closed" && kv($0, "step") == S { t = ep(kv($0, "at")) } END { if (t != "") print t }' S="$1" .vid/metrics-events 2>/dev/null; fi; }
# cmd_cost [<step>]: one line a published ticket, under its step (R2), then ViD's rounds
cmd_cost() { tix; : > "$Q/ct"; for s in $(cut -f3 "$Q/tix" | sort -u); do c=$(ctime "$s"); [ -n "$c" ] || ! grep -q "^closed $s " "$HAND" 2>/dev/null || c=-1; [ -z "$c" ] || printf '%s\t%s\n' "$s" "$c" >> "$Q/ct"; done
  { for f in .vid/results/pr-*-*.txt; do [ -f "$f" ] && sed -n '1s/^ticket \([0-9][0-9]*\), pull request \([0-9][0-9]*\), .*/P \2 \1/p' "$f"; done; awk '{ print "P " $1 " " $2 }' "$D/accepted-at" 2>/dev/null
    for f in "$D"/pr-*-*.txt; do [ -f "$f" ] && [ "$(sed -n 2p "$f")" = 'ticket: accepted' ] || continue; b=${f##*/pr-}; b=${b%.txt}; echo "A ${b%%-*} ${b#*-}"; done; } > "$Q/cpa" 2>/dev/null
  cat "$D/accepted-at" > "$Q/aa" 2>/dev/null || : > "$Q/aa"; cat "$D/log" > "$Q/dl" 2>/dev/null || : > "$Q/dl"
  awk -F'\t' "$EP"' function base(r) { sub(/-T[0-9]+$/, "", r); return r } function ok(s) { return s ~ /^(accepted|accepted by ruling|owed)$/ }
    FILENAME == ARGV[1] { if ($0 ~ /^P /) { split($0, a, " "); PT[a[2]] = a[3] } else { split($0, a, " "); AH[a[2] " " a[3]] = 1 } next }
    FILENAME == ARGV[2] { split($0, a, " "); if (!(a[2] in AT)) { AT[a[2]] = ep(kv($0, "at")); ATS[a[2]] = kv($0, "at"); AHD[a[2]] = a[3] } next }
    FILENAME == ARGV[3] { CT[$1] = $2; next }
    FILENAME == ARGV[4] { if (!($2 in PT)) next; t = PT[$2]; L[t, ++nl[t]] = $0; next }
    { t = $1; if (ONE != "" && $3 != ONE) next; if (!($3 in SN)) { SN[$3] = 1; SO[++ns] = $3 } TS[$3] = TS[$3] " " t; K[t] = $2; PB[t] = ep($4); RW[t] = ($7 != "") ? $7 : $5 }
    END { for (j = 1; j <= ns; j++) { s = SO[j]; m = split(TS[s], ts, " "); la = -1; unk = 0
        for (k = 1; k <= m; k++) { t = ts[k]; ac[t] = 0; acc[t] = ""; split("", HS); nh = 0; first = ""; done = 0; split("", HD); split("", FB); split("", HB)
          for (i = 1; i <= nl[t]; i++) { split(L[t, i], x, "\t"); if (first == "") first = x[1] " " x[3]; if ((t in ATS) ? (x[1] > ATS[t]) : (done && !(x[2] " " x[3] == dp && x[1] == dw))) break; if (!((x[2] " " x[3]) in HS)) { HS[x[2] " " x[3]] = 1; nh++ }
            if (x[1] " " x[3] == first) FB[x[4]] = x[5]; if (x[5] == "held") HD[base(x[4])] = 1
            if (!done && ((t in AHD) ? (x[3] == AHD[t]) : ((x[2] " " x[3]) in AH))) { done = 1; dp = x[2] " " x[3]; dw = x[1] } }
          if (t in AT) { acc[t] = AT[t]; ac[t] = 1 } else if (done) ac[t] = 2
          nr = split(RW[t], rr, " "); na = 0; for (q = 1; q <= nr; q++) { r = rr[q]; if (r in FB) { if (ok(FB[r])) na++; continue } tn = 0; to = 0; for (z in FB) if (index(z, r "-T") == 1) { tn++; if (ok(FB[z])) to++ } if (tn && to == tn) na++ }
          h = 0; for (z in HD) h++
          PA[t] = (ac[t] == 1) ? hm(acc[t] - PB[t]) : (ac[t] == 2) ? "unknown" : "not yet"; HE[t] = nh; FA[t] = na " of " nr; HO[t] = h
          if (s in CT) { if (ac[t] == 1 && acc[t] <= CT[s] && acc[t] > la) la = acc[t]; if (ac[t] == 2) unk = 1 } }
        print s; for (k = 1; k <= m; k++) { t = ts[k]
          if (!(s in CT)) c = "open"; else if (ac[t] == 1 && CT[s] >= 0 && acc[t] > CT[s]) c = "after the close"; else if (ac[t] == 0) c = "not accepted"; else if (unk || la < 0 || CT[s] < 0) c = "unknown"; else c = hm(CT[s] - la)
          print "  " s " #" t " " K[t] " · published to accepted " PA[t] " · heads " HE[t] " · accepted at the first decision " FA[t] " · held " HO[t] " · accepted to closed " c } } }' \
    "$Q/cpa" "$Q/aa" "$Q/ct" "$Q/dl" ONE="${1:-}" "$Q/tix"
  echo "ViD · rounds $(cat "$D/accepted-log" 2>/dev/null | grep -c . || true)"; }
# cmd_regress: R3 — `<close> TAB <n>` for each close whose numbers give regressions introduced above zero, a step's (<step>/<ask>) or a
# stage's (stage-<N>/<ask>, 7.1's folders); with `carried`, only each step's or stage's newest numbered close, while that step is open
cmd_regress() { for x in "$D"/close/*/* "$D"/stage/*/*; do [ -s "$x/numbers" ] || continue; n=$(sed -n 's/^regressions introduced \([0-9][0-9]*\).*/\1/p' "$x/numbers"); k=${x##*/}; s=${x%/*}; s=${s##*/}
    case $x in "$D"/stage/*) s=stage-$s ;; esac; printf '%s\t%s\t%s\n' "$s" "$k" "${n:-0}"; done | sort -t"$TAB" -k1,1 -k2,2n > "$Q/rg"
  if [ "${1:-}" = carried ]; then awk -F'\t' '{ N[$1] = $3; K[$1] = $2 } END { for (s in N) if (N[s] > 0) print s "\t" K[s] "\t" N[s] }' "$Q/rg" | sort | while IFS=$TAB read -r s k n; do
      case $s in stage-*) ls "$D/stage/${s#stage-}"/*/passed > /dev/null 2>&1 && continue ;; *) grep -q "^closed $s " "$HAND" 2>/dev/null && continue ;; esac; printf '%s close %s: %s\n' "$s" "$k" "$n"; done
  else awk -F'\t' '$3 > 0 { print "regression " $1 "/" $2 " " $3 }' "$Q/rg"; fi; }
# st_lines: R1's lines of the status, after 7.1's
st_lines() { rjoin; tix; P0=$(plan_block "$RS"); BF=$(sed -n 's/^strategy:[[:space:]]*//p' "$RS" | head -n 1 | sed 's/[[:space:]]*$//')
  cur=1; nm=''; if [ -f STAGES.md ]; then cur=$(sh "$HERE/stages.sh" current 2>/dev/null || echo 1); nm=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' -v c="$cur" '{ k = $1; gsub(/[ \t]/, "", k); sub(/^STAGE-0*/, "", k); if (k == "") k = 0 } k == c { n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print n; exit }'); fi
  sc=$(ls -d "$D"/stage/*/*/passed 2>/dev/null | sed 's|/[^/]*/passed$||' | sort -u | grep -c . || true)
  echo "stage: $cur${nm:+ — $nm}$([ -f STAGES.md ] || echo ' — one stage, no STAGES.md') · stages closed $sc"
  # the plan's steps: id, name, kind; the open tickets (the round's read)
  printf '%s\n' "$P0" | awk -F'\t' 'FILENAME == ARGV[1] { I[++ni] = $1; next } function ex(w,   o, a, b, p, x, y, i, v) { if (!index(w, "..")) return w; a = substr(w, 1, index(w, "..") - 1); b = substr(w, index(w, "..") + 2)
        p = a; sub(/[0-9]+$/, "", p); x = substr(a, length(p) + 1) + 0; y = substr(b, length(p) + 1) + 0; o = ""; for (i = 1; i <= ni; i++) if (substr(I[i], 1, length(p)) == p && substr(I[i], length(p) + 1) ~ /^[0-9]+$/) { v = substr(I[i], length(p) + 1) + 0; if (v >= x && v <= y) o = o " " I[i] } return substr(o, 2) }
      { l = $0; sub(/^[ \t]*/, "", l) } l ~ /^step[ \t]/ { n = split(l, a, "|"); id = a[1]; sub(/^step[ \t]+/, "", id); gsub(/[ \t]+$/, "", id); nm = ""; kd = "-"; rw = ""
      for (i = 2; i <= n; i++) { f = a[i]; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^name:/) { nm = f; sub(/^name:[ \t]*/, "", nm) } else if (f ~ /^kind:/) { kd = f; sub(/^kind:[ \t]*/, "", kd) } else if (f ~ /^rows:/) { sub(/^rows:[ \t]*/, "", f); m = split(f, w, " "); for (k = 1; k <= m; k++) rw = rw (rw == "" ? "" : " ") ex(w[k]) } }
      print id "\t" nm "\t" kd "\t" rw }' "$Q/plr" - > "$Q/steps"
  awk -F'\t' -v T=",${PX}ticket," '$1 == "issue" && index("," $3 ",", T) { print $2 }' "$RD" 2>/dev/null > "$Q/open"
  awk -F'\t' 'FILENAME == ARGV[1] { S[$1] = $2; next } FILENAME == ARGV[2] { N[$1] = $2; next } FILENAME == ARGV[3] { T[$1] = $0; next }
    ($1 in T) { split(T[$1], x, "\t"); m = split(x[5], r, " "); a = 0; for (i = 1; i <= m; i++) if (S[r[i]] ~ /^(accepted|accepted-by-ruling|owed|passing|paid)$/) a++
      o = o (o == "" ? "" : " · ") "#" $1 " " x[3] (x[3] in N ? " " N[x[3]] : "") ": " a " of " m " rows accepted" } END { print "now: " (o == "" ? "no open ticket" : o) }' "$Q/rst" "$Q/steps" "$Q/tix" "$Q/open"
  # left, and the debt's owed rows: each row once, in the first bucket that holds it; a step is started by its ticket or its step-start
  { cat "$Q/tix"; grep '^step-start ' .vid/metrics-events 2>/dev/null || true; } > "$Q/tixs"
  awk -F'\t' -v c="$cur" 'FILENAME == ARGV[1] { if ($0 ~ /^closed /) { split($0, a, " "); CL["closed " a[2]] = 1 } next } FILENAME == ARGV[2] { if ($0 ~ /^step-start /) { for (i = split($0, r, " "); i > 0; i--) if (r[i] ~ /^step=/) PS[substr(r[i], 6)] = 1; next } if ($6 == 0) for (i = split($5, r, " "); i > 0; i--) IN[r[i]] = 1; PS[$3] = 1; next }
    FILENAME == ARGV[3] { if (!($1 in PS) && !(("closed " $1) in CL)) ns++; next }
    $4 ~ /^(record|limit)$/ { next }
    { s = $2; dw = ($5 ~ /(^| )(owed-staging|owed-production|owed-rehearsal|seam)( |$)/) && s !~ /^(paid|known-limit)$/; lt = ($4 == "later" || $3 == "later" || ($3 ~ /^[0-9]+$/ && $3 + 0 > c + 0))
      if (s == "failing") f++; else if (s == "held") h++; else if (dw) d++; else if (lt && s !~ /^(accepted|accepted-by-ruling|owed|passing|paid|known-limit)$/) l++
      else if (s ~ /^(accepted|accepted-by-ruling|owed|passing|paid|known-limit)$/) next; else if (s != "-" || ($1 in IN)) u++; else z++ }
    END { printf "left: steps not started %d · rows failing %d · held %d · not yet decided %d · in no ticket %d · apart: deploy-owed %d · later stages %d\n", ns, f, h, u, z, d, l }' "$Q/hd" "$Q/tixs" "$Q/steps" "$Q/rst"
  # tests: the environments declared, the newest close's red rows by chunk
  nc=$(awk "$EP"' $1 == "close-asked" { print kv($0, "step") "/" kv($0, "ask") }' .vid/metrics-events 2>/dev/null | while read -r x; do [ -f "$D/close/$x/result" ] && echo "$x"; done | tail -n 1)
  [ -n "$nc" ] || nc=$(for s in $(ls "$D/close" 2>/dev/null); do k=$(ls "$D/close/$s" | grep -E '^[0-9]+$' | sort -n | while read -r j; do [ -f "$D/close/$s/$j/result" ] && echo "$j"; done | tail -n 1); [ -z "$k" ] || echo "$s/$k"; done | tail -n 1)
  rc=''; [ -z "$nc" ] || rc=$(awk -F'|' '$2 == "red" { n = split($4, w, " "); o = ""; for (i = 1; i <= n; i++) { r = w[i]; sub(/^[^:]*:/, "", r); if (!((r, $1) in s)) { s[r, $1] = 1; o = o " " r } } printf "%s%s%s", (k++ ? "; " : ""), $1, o }' "$D/close/$nc/chunks" 2>/dev/null)
  [ -n "$rc" ] || [ -z "$nc" ] || [ -s "$D/close/$nc/chunks" ] || rc=$(awk -F'\t' '$2 == "red" { printf "%s%s", (n++ ? " " : "red: "), $1 }' "$D/close/$nc/result")
  st=$(sed -n 's/^stacks=//p' .vid/budget 2>/dev/null | tail -n 1); en=$(sed -n 's/^engines \([^|]*\)|.*/\1/p' "$HAND" 2>/dev/null | tail -n 1 | sed 's/ *$//')
  echo "tests: environments declared ${st:-none}${en:+ · engines $en} · the newest close: ${nc:-none}${nc:+ ${rc:-no red}}"
  # the test state: evidence read only from tickets published after the row's newest landing (.vid/tw/log's order)
  awk -v n=0 '$1 == "published" { P[$2] = ++n } $1 == "landed" { ++n; m = split(kv($0, "ids"), a, ","); for (j = 1; j <= m; j++) if (a[j] != "") print a[j] "\t" n } function kv(l, k,   q, b, i) { q = split(l, b, " "); for (i = 1; i <= q; i++) if (index(b[i], k "=") == 1) return substr(b[i], length(k) + 2); return "" }
    END { for (t in P) print "#" t "\t" P[t] }' .vid/tw/log 2>/dev/null > "$Q/ord" || : > "$Q/ord"
  # each evidence file in the order of its head's first decision (.vid/decide/log): a row's T3 is its newest
  cat "$D/log" > "$Q/dl" 2>/dev/null || : > "$Q/dl"; awk -F'\t' '!(($2 " " $3) in O) { O[$2 " " $3] = ++n; print $2 "-" $3 "\t" n }' "$Q/dl" > "$Q/eo"
  for f in .vid/results/pr-*-*.txt; do [ -f "$f" ] || continue; t=$(sed -n '1s/^ticket \([0-9][0-9]*\),.*/\1/p' "$f"); b=${f##*/pr-}; b=${b%.txt}; o=$(awk -F'\t' -v b="$b" '$1 == b { print $2 }' "$Q/eo"); [ -n "$t" ] && awk -F'\t' -v t="$t" -v o="${o:-0}" 'NF == 6 && $1 ~ /^[A-Z]+-/ { print t "\t" o "\t" $0 }' "$f"; done > "$Q/evd"
  awk -F'\t' 'FILENAME == ARGV[1] { if ($1 ~ /^#/) P[substr($1, 2)] = $2; else if ($2 > LD[$1]) LD[$1] = $2; next } FILENAME == ARGV[2] { $0 = $0; id = $3; b = id; sub(/-T[0-9]+$/, "", b); if ((b in LD) && !(($1 in P) && P[$1] > LD[b])) next; if ((id in LD) && !(($1 in P) && P[$1] > LD[id])) next   # a landed transition, by its own id
        if ($5 == "red") R2[id] = 1; if ($7 ~ /^proven/) FP[id] = 1; if (!(id in TO) || $2 + 0 >= TO[id]) { TO[id] = $2 + 0; T3[id] = ($6 == "passed") } next }
    FILENAME == ARGV[3] { if ($2 == "tr") TR[$3] = TR[$3] " " $1; next }
    function has(A, r,   m, x, k) { if (TR[r] == "") return (r in A) && A[r]; m = split(TR[r], x, " "); for (k = 1; k <= m; k++) if (!((x[k] in A) && A[x[k]])) return 0; return 1 }
    $4 ~ /^(record|limit)$/ { next } { n++; if (has(R2, $1)) a++; if (has(T3, $1)) p++; if (has(FP, $1) || ($6 == 1 && !($1 in LD))) q++ }
    END { printf "test state: of %d rows · red seen at T2 %d · T3 passed %d · fault proven %d\n", n, a, p, q }' "$Q/ord" "$Q/evd" "$Q/plr" "$Q/rst"
  # the debt: rows whose state is owed, by kind (an undecided deploy-owed row is left's); held rows with their Q lines, deferred rows (breadth first), the regressions carried
  ow=$(awk -F'\t' '$4 ~ /^(record|limit)$/ || $2 != "owed" { next } { for (k = split("staging production rehearsal", K, " "); k > 0; k--) if ($5 ~ ("(^| )owed-" K[k] "( |$)")) c[K[k]]++ } END { printf "staging %d · production %d · rehearsal %d", c["staging"], c["production"], c["rehearsal"] }' "$Q/rst")
  hl=$(awk -F'\t' 'FILENAME == ARGV[1] { if ($1 ~ /^held:/) { r = substr($1, 6); sub(/-T[0-9]+$/, "", r); Q[r] = Q[r] (Q[r] == "" ? "" : ",") $2 } next } $2 == "held" { o = o (n++ ? ", " : "") $1 ($1 in Q ? " " Q[$1] : " no Q line") } END { printf "%d%s", n, (n ? " (" o ")" : "") }' "$Q/ids" "$Q/rst")
  df=0; if [ "$BF" = breadth-first ]; then cat .vid/tw/log > "$Q/tw" 2>/dev/null || : > "$Q/tw"; df=$(awk -F'\t' "$EP"' FILENAME == ARGV[1] { K[$1] = $3; for (i = split($4, r, " "); i > 0; i--) if (r[i] !~ /\.\./) ST[r[i]] = $1; next } FILENAME == ARGV[2] { if ($0 ~ /^(published|amended) / && K[kv($0, "step")] != "hardening") for (i = split(kv($0, "rows"), r, ","); i > 0; i--) FT[r[i]] = 1; next }
      ($1 in ST) && K[ST[$1]] == "hardening" && ($1 in FT) && $2 !~ /^(accepted|accepted-by-ruling|known-limit)$/ { n++ } END { print n + 0 }' "$Q/steps" "$Q/tw" "$Q/rst"); fi
  rg=$(cmd_regress carried | paste -sd ',' - | sed 's/,/, /g')
  echo "debt: owed $ow · held $hl · deferred $df · regressions ${rg:-none}"
  # landings: rows reset over the run, from each landed draft's saved sets
  lr=0; lt=0; ln=0; for x in "$D"/drafts/*; do [ -f "$x/landed" ] || continue; ln=$((ln + 1)); lr=$((lr + $(awk -F'\t' '$1 == "reset" && $3 != "transition"' "$x/sets" 2>/dev/null | grep -c . || true))); lt=$((lt + $(awk -F'\t' '$1 == "reset" && $3 == "transition"' "$x/sets" 2>/dev/null | grep -c . || true))); done
  echo "landings: $ln landed · rows reset $lr · transitions reset $lt"
  # cost: the steps closed since the last update, their tickets' lines; the median published-to-accepted time
  cmd_cost > "$Q/cost"; cl=$(awk -F'\t' -v l="$L" '$2 >= 0 && $2 >= l { print $1 }' "$Q/ct" | paste -sd ' ' -)
  awk -F'\t' "$EP"' FILENAME == ARGV[2] { split($0, a, " "); if (!(a[2] in A)) A[a[2]] = ep(kv($0, "at")); next } FILENAME == ARGV[3] { if ($1 in A) { d[++n] = A[$1] - ep($4) } else u++; next }
    END { for (i = 2; i <= n; i++) { x = d[i]; k = i - 1; while (k > 0 && d[k] > x) { d[k + 1] = d[k]; k-- } d[k + 1] = x }
      printf "cost: steps closed since the last update %s · median published to accepted %s of %d tickets · %d with no accepted-at\n", (CL == "" ? "none" : CL), (n ? hm(d[int((n + 1) / 2)]) : "none"), n, u }' CL="$cl" "$Q/aa" "$Q/tix"
  for s in $cl; do grep "^  $s #" "$Q/cost"; done
  if [ "$BF" = breadth-first ]; then awk -F'\t' 'FILENAME == ARGV[1] { if ($3 == "hardening") { for (i = split($4, r, " "); i > 0; i--) HS[r[i]] = $1 } next }
      ($1 in HS) && $2 !~ /^(accepted|accepted-by-ruling|owed|paid|known-limit)$/ { n++; K[HS[$1]] = 1 } END { for (s in K) k++; printf "hardening: %d rows in %d steps not accepted\n", n, k }' "$Q/steps" "$Q/rst"
  else echo 'hardening: none, depth first'; fi
  echo 'estimate: none in ticket mode: DevAgent'"'"'s pace is its own (V2 §3.7)'; }
# orn <value> [<word>]: the value, or a word for nothing, "none" by default, so no field is a bare colon (0.26.10.28.5, R3)
orn() { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' "${2:-none}"; fi; }
# qfin: the final stage, STAGES.md's highest (stage 1 with none), as close.sh's finals reads it
qfin() { [ -f STAGES.md ] || { echo 1; return; }; sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); if (k ~ /^STAGE-/) { sub(/^STAGE-0*/, "", k); if (k == "") k = 0; m = k } } END { print m + 0 }'; }
cmd_status() { E=$(sed -n 's/^run-start //p' .vid/decide/queue/started 2>/dev/null); [ -n "$E" ] || { E=$(date +%s); echo "run-start $E" > "$Q/started"; }
  L=$(cat "$Q/updated" 2>/dev/null || echo 0); echo '== where things stand'
  echo "tickets: open $(awk -F'\t' -v T=",${PX}ticket," '$1 == "issue" && index("," $3 ",", T)' "$RD" 2>/dev/null | grep -c .) · merged $(cat "$D/merged-prs" 2>/dev/null | grep -c . || true) · items for the owner $(cat "$Q/items" 2>/dev/null | grep -c . || true) · steps waiting $(orn "$(c=$(rkey); awk -v c="$c" '$1 == "start" && $NF == c { print $2 }' "$D/refused" 2>/dev/null | sort -u | paste -sd ' ' -)")"
  echo "rows: $(orn "$(awk -F'\t' '{ c[$2]++ } END { for (s in c) printf "%s%s %d", (n++ ? " · " : ""), s, c[s] }' "$D/state" 2>/dev/null)")"
  echo "steps closed: $(orn "$(sed -n 's/^closed \([^ ]*\) .*/\1/p' "$HAND" 2>/dev/null | paste -sd ' ' -)") · closes out: $(orn "$(sh "$HERE/close.sh" out 2>/dev/null | cut -d' ' -f2 | paste -sd ' ' -)")"
  fo=0; fm=0; for t in $(awk '$1 == "published" && / kind=fix / { print $2 }' .vid/tw/log 2>/dev/null | sort -u); do if awk -F'\t' -v t="$t" '$2 == t { f = 1 } END { exit !f }' "$D/merges" 2>/dev/null; then fm=$((fm + 1)); elif ! grep -q "^withdrawn $t " .vid/tw/log; then fo=$((fo + 1)); fi; done
  echo "fixes: tickets open $fo · merged $fm$(for s in $(ls "$D/close" 2>/dev/null); do k=$(ls "$D/close/$s" | grep -E '^[0-9]+$' | sort -rn | while read -r j; do [ -s "$D/close/$s/$j/numbers" ] && { echo "$j"; break; }; done); [ -z "$k" ] || printf ' · %s close %s: %s' "$s" "$k" "$(cat "$D/close/$s/$k/numbers")"; done)"
  # R5 (v0.26.10.26.1): a stage with a candidate, or what keeps it from being due
  [ ! -d "$D/stage" ] || rjoin   # v0.26.10.26.2: the paid count reads the rows as they stand now
  for x in $(ls "$D/stage" 2>/dev/null); do c=$(snc "$x"); F=$D/stage/$x/$c; [ -n "$c" ] && [ -f "$F/named" ] || continue
    c3=out; [ ! -f "$F/passed" ] || c3=green; [ -f "$F/passed" ] || [ ! -f "$F/done" ] || c3=red; [ ! -f "$F/withdrawn" ] || c3='withdrawn by a re-cut'   # 0.26.10.29.2 (R2)
    G1=$F/s1; [ -f "$F/s1ask" ] || G1=$D/stage/$x/s1   # no S1 at this candidate: the stage's grades stand
    m=$(awk -F'\t' '$1 == "reqs" { print split($2, a, " ") }' "$F/s1ask" 2>/dev/null); [ -f "$F/s1ask" ] || m=$(grep -c . "$G1" 2>/dev/null); g=$(grep -c . "$G1" 2>/dev/null); p=$(awk -F'\t' '$2 == "pass"' "$G1" 2>/dev/null | grep -c .)
    # v0.26.10.26.2 (R7): D1, CS and the paid rows of stages up to this one
    d1=''; if [ -f "$F/d1/passed" ]; then d1=passed; elif [ -f "$F/d1/closed" ]; then grep -q '^failed ' "$F/d1/closed" && d1=failed || d1=withdrawn; elif [ -f "$F/d1/ask" ]; then d1=out; elif [ -f "$F/passed" ]; then d1=due; fi
    cs=''; if [ -f "$F/cs/passed" ]; then cs=green; elif [ -f "$F/cs/withdrawn" ]; then cs=withdrawn; elif [ -f "$F/cs/done" ]; then cs=red; elif [ -f "$F/cs/ask" ]; then cs=out; fi
    py=$(awk -F'\t' -v x="$x" '(($3 ~ /^[0-9]+$/ && $3 + 0 <= x + 0) || $1 ~ /^SEAM-/) && $5 ~ /(^| )(owed-staging|seam)( |$)/ { m++; if ($2 == "paid") p++ } END { print p + 0 " of " m + 0 }' "$Q/rst" 2>/dev/null)
    # v0.26.10.26.4 (R6): W1, and the stage's findings ruled
    w1=''; W=$F/w1; ws=$(ls "$W" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1); if [ -f "$W/done" ]; then w1=done; elif [ -f "$W/withdrawn" ]; then w1=withdrawn
      elif [ -f "$W/none" ]; then w1="none — $(head -n 1 "$W/none")"   # 0.26.10.28.6 (R1): no screens, no journey
      elif [ -f "$W/limit" ]; then w1="$(sed -n 1p "$W/limit") ($(sed -n 2p "$W/limit"))"   # R1 (b): the known limit, in its words, with who and when
      elif [ -n "$ws" ] && [ -f "$W/$ws/read" ]; then case $(cut -f1 "$W/$ws/read") in not-done) grep -qxF 'allow again' "$W/again" 2>/dev/null && w1=due || w1='not done' ;; refused) grep -q '^refused walk twice' "$W/items" 2>/dev/null && w1=refused || w1=due ;; *) w1=due ;; esac; elif [ -n "$ws" ] && [ -s "$W/$ws/pid" ]; then w1=out; elif [ -n "$ws" ]; then w1=due; elif [ -f "$F/cs/passed" ]; then w1=due; fi
    fr=$(s_all | awk -F'\t' -v x="$x" -v A="$Q/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, y, "\t"); D[y[2]] = 1 } } $2 == x { n++; if ($1 in D) r++ } END { print r + 0 " of " n + 0 }')
    echo "stage $x: candidate $c at $(printf %.12s "$(cat "$F/commit" 2>/dev/null)") · C3 $c3 · S1 ${g:-0} of ${m:-0} graded, ${p:-0} pass · findings $(cat "$F/findings" 2>/dev/null | grep -c . || true)${d1:+ · D1 $d1}${cs:+ · CS $cs} · paid ${py:-0 of 0}${w1:+ · W1 $w1} · findings $fr ruled$(stclose "$x")$(stprod "$F" "$x")$(addrs "$F" "$x" | awk '{ printf " · %s", $0 }')"; done
  np=$(sh "$HERE/close.sh" nextplan 2>/dev/null); [ -z "$np" ] || echo "stage $np: not yet planned"
  if holding; then n=$(hstage); if [ "$((n + 1))" -le "$(qfin)" ]; then echo "setup hold: the next stage waits until staging has passed once; the owner's continue builds on"
    else echo "setup hold: staging has not passed once yet; stage $n is the last stage, so nothing waits on it; the owner's continue clears it"; fi; fi   # v0.26.10.28.8 (R9)
  sh "$HERE/close.sh" why 2>/dev/null | sed 's/^/stage /'
  echo "open questions: $(orn "$(awk -F'\t' '{ k = $1; sub(/:.*/, "", k); c[k]++ } END { for (s in c) printf "%s%s %d", (n++ ? " · " : ""), s, c[s] }' "$Q/items" 2>/dev/null)")"
  # 0.26.10.29.5 (DP-1 R4): every answer not given by the owner, lib.sh's notowner, the set the stage facts and the completion report read
  # (the round's own stand-in rulings on held rows included); each with who gave it, the delegate's apart as before
  DA=$(notowner | awk -F'\t' 'BEGIN { OFS = "\t" } { if ($3 == "") $3 = "-"; if ($4 == "") $4 = "(no words)"; print }' | while IFS=$TAB read -r when k v w by; do e=$(epoch "$when"); [ "$e" -ge "$L" ] && echo "  $k — $w$(if [ "$by" = delegate ]; then echo ' · answered for you, under your delegation'; else echo " · by $by"; fi)"; done)   # v0.26.10.28.8 (F-004): the delegate's apart
  if [ -n "$DA" ]; then echo "delegated answers since the last update:"; printf '%s\n' "$DA"; else echo 'delegated answers since the last update: none'; fi
  # 0.26.10.29.5 (DP-1 R4): the merges whose decisions ViD did not record, from decisions.sh record's events (decisions-recorded pr=<p> n=<k>):
  # a body with no Decisions section (n=missing) and a record a hook refused (n=refused; a deploy report's by its id), each once, or none
  drec() { awk -v W="$1" '$1 == "decisions-recorded" { p = ""; n = ""; for (i = 2; i <= NF; i++) { if ($i ~ /^pr=/) p = "#" substr($i, 4); if ($i ~ /^deploy=/) p = "deploy " substr($i, 8); if ($i ~ /^n=/) n = substr($i, 3) } if (p != "" && n == W && !s[p]++) printf "%s%s", (c++ ? ", " : ""), p }' .vid/metrics-events 2>/dev/null; }
  echo "merged with no decisions stated: $(orn "$(drec missing)")"; echo "decisions refused: $(orn "$(drec refused)")"
  # 0.26.10.29.2 (R8): each plan change since the last update, its kind and its why, from the plan-change events and their decisions, as
  # develop's progress prints them; a change its decision records refused is not listed. The fields are read before the quoted why
  # alone (plan.sh writes no `"` inside it), so a why's own words never read as a field, and the why is joined as it stands
  PC=$(awk '$1 == "plan-change" { a = $NF; sub(/^at=/, "", a); p = index($0, " why=\""); h = p ? substr($0, 1, p - 1) : $0; y = p ? substr($0, p + 6) : ""; sub(/".*/, "", y)
      n = split(h, f, " "); w = ""; d = "-"; for (i = 2; i <= n; i++) { if (f[i] ~ /^what=/) w = substr(f[i], 6); if (f[i] ~ /^decision=/) d = substr(f[i], 10) }
      print a "\t" w "\t" d "\t" y }' .vid/metrics-events 2>/dev/null | while IFS=$TAB read -r a w d y; do e=$(epoch "$a"); [ "$e" -ge "$L" ] || continue
      ! grep -qx 'result=refused' ".vid/plans/decisions/$d.why" 2>/dev/null || continue; printf '%s%s\n' "${w:-a change}" "${y:+ — \"$y\"}"; done)
  echo "plan changes since the last update: $(printf '%s\n' "$PC" | grep -c . || true)${PC:+ · $(printf '%s\n' "$PC" | awk '{ printf "%s%s", (NR > 1 ? "; " : ""), $0 }')}"
  echo "flags: $(orn "$(awk '{ printf "%s%s %s", (n++ ? " · " : ""), $1, $2 }' "$D/flags" 2>/dev/null)" 'no flags')"; s=$(( $(date +%s) - E )); echo "elapsed: $((s / 3600)) h $(((s % 3600) / 60)) m"
  echo "grade asks: $(sh "$HERE/grade.sh" out 2>/dev/null | grep -c . || true) out · $(g_items | grep -v '^grade:[0-9]*:lost' | grep -c . || true) findings to rule"   # v0.26.10.27.2 (R4)
  # v0.26.10.27.4 (R7); 0.26.10.28.5 (R3): no count of unmet conditions before the final stage has a candidate
  fz=$(qfin); fc=$(snc "$fz"); if [ -z "$fc" ] || [ ! -f "$D/stage/$fz/$fc/named" ]; then echo "end: not yet, stage $(orn "$(sed -n 's/^stage:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$RS" | head -n 1)" 1) of $fz"
  else n=$(sh "$HERE/close.sh" endconds 2>/dev/null | grep -c . || true); if [ "${n:-0}" = 0 ]; then echo 'end: complete'; else echo "end: $n conditions unmet"; fi; fi
  if ohold; then echo "offer: the grade before the first go-live, ask #$(sed -n 's/^grade //p' "$Q/offer"), holds every production yes"; elif oopen && p_items | grep -q .; then echo 'offer: a grade of the whole product before the first go-live, waiting on the owner'; fi
  st_lines   # v0.26.10.26.3 (R1): after 7.1's lines
  echo "the findings page: one page of the held rows with their records; ask to open it in your browser"; [ -n "${VID_STATUS_KEEP:-}" ] || { date +%s > "$Q/up" || exit 1; put "$Q/updated" < "$Q/up" || exit 1; }; }
# v0.26.10.28.8 (R7): a candidate's addresses, as its passed deploy reports carry them, read where close.sh reads them: the test site
# (a passed D1's staging line), the rehearsal copy (a passed RH's copy line), the live copy (liveaddr). Each with its state: the test site
# is taken down once its staging run's issue closes (cs/issue-closed, or a withdrawn CS), the rehearsal copy once CR's does; one not
# reported yet is not known yet, never guessed. Only the address: no sign-in value. addrs <candidate folder> <stage>
# stays <candidate folder> (0.26.11.1.1, R1): its passed D1 says its staging stays up between deploys
stays() { [ -f "$1/d1/passed" ] && grep -q "^stays${TAB}up\$" "$1/d1/read" 2>/dev/null; }
aread() { [ -f "$1/passed" ] && sed -n "s/^$2$TAB//p" "$1/read" 2>/dev/null | head -n 1; }
addrs() { a=$(aread "$1/d1" staging); if [ -z "$a" ]; then echo 'test site: not known yet'; elif stays "$1"; then echo "test site: $a, up"; elif [ -f "$1/cs/issue-closed" ] || [ -f "$1/cs/withdrawn" ]; then echo "test site: $a, taken down after its run"; else echo "test site: $a, up"; fi
  a=$(aread "$1/rh" copy); [ -z "$a" ] || { if [ -f "$1/cr/passed" ] || [ -f "$1/cr/withdrawn" ]; then echo "rehearsal copy: $a, taken down after its run"; else echo "rehearsal copy: $a, up"; fi; }
  # the live copy: while production runs this candidate's commit (close.sh records it at a passed D2 and at a recovery, before CP reads
  # it), its own D2 read's address; else, the stage in production (a later stage's go-live included), production's newest address
  X0=$(cat "$1/commit" 2>/dev/null); if [ -n "$X0" ] && [ "$(pnow)" = "$X0" ]; then a=$(sed -n "s/^production$TAB//p" "$1/d2/read" 2>/dev/null | head -n 1); [ -n "$a" ] || a=$(liveaddr); echo "live copy: ${a:-not known yet}"; return 0; fi
  awk -v x="$2" '$1 == "production" && $2 >= x { f = 1 } END { exit !f }' "$HAND" 2>/dev/null && [ "$(pnow)" != none ] || return 0; a=$(liveaddr); echo "live copy: ${a:-not known yet}"; }
# pnow: what production runs now, as .vid/decide/production's newest line gives it: a commit, none (a recovery found it running nothing), or empty
pnow() { awk -F'\t' 'NF { c = $1 } END { print c }' "$D/production" 2>/dev/null; }
# liveaddr: once a stage is in production (the handed record's production line, as stprod reads it), production's address, read as
# close.sh's CP reads it when its own D2 names none: the newest D2 read's production line; nothing before a first go-live
liveaddr() { grep -q '^production [0-9]* | ' "$HAND" 2>/dev/null && [ "$(pnow)" != none ] || return 0; for f in $(ls -t "$D"/stage/*/*/d2*/read 2>/dev/null); do a=$(sed -n "s/^production$TAB//p" "$f" | head -n 1); [ -z "$a" ] || { echo "$a"; return 0; }; done; }
# v0.26.10.27.1 (R7): the stage line's production: RH, CR, the yes, D2, CP, and in production
stprod() { G0=$1; o=''; [ -f "$G0/rh/ask" ] || [ -f "$G0/d2/ask" ] || { grep -q "^production [0-9]* | " "$HAND" 2>/dev/null && awk -v x="$2" '$1 == "production" && $2 >= x { f = 1 } END { exit !f }' "$HAND" && printf ' · in production'; return 0; }
  if [ -f "$G0/rh/nobackup" ]; then o="$o · RH no backup"; elif [ -f "$G0/rh/passed" ]; then o="$o · RH passed"; elif [ -f "$G0/rh/closed" ]; then o="$o · RH failed"; elif [ -f "$G0/rh/ask" ]; then o="$o · RH out"; fi
  if [ -f "$G0/cr/passed" ]; then o="$o · CR green"; elif [ -f "$G0/cr/done" ]; then o="$o · CR red"; elif [ -f "$G0/cr/ask" ]; then o="$o · CR out"; fi
  if [ -f "$G0/yes" ]; then k0=$(cut -f1 "$G0/yes"); v0=$(awk -F'\t' -v k="$k0" '$2 == k { v = $3 } END { print v }' "$Q/answers"); o="$o · ${v0:-asked}"; fi
  if [ -f "$G0/d2/closed" ]; then o="$o · D2 $(cut -d' ' -f1 "$G0/d2/closed")"; elif [ -f "$G0/d2/passed" ]; then o="$o · D2 passed"; elif [ -f "$G0/d2/ask" ]; then o="$o · D2 out"; fi
  if [ -f "$G0/cp/passed" ]; then o="$o · CP green"; elif [ -f "$G0/cp/done" ]; then o="$o · CP red"; elif [ -f "$G0/cp/ask" ]; then o="$o · CP out"; fi
  awk -v x="$2" '$1 == "production" && $2 >= x { f = 1 } END { exit !f }' "$HAND" 2>/dev/null && o="$o · in production"; printf '%s' "$o"; }
# v0.26.10.26.5 (R6): the stage line's close: `closed at <c12>` (and `corrected since its close at <c12>`), or the unmet conditions by
# number; `held after <N>` while a hold is recorded
stclose() { sc=$(sed -n "s/^stage-closed $1 | stand-in: RM at \([0-9a-f]*\) candidate .*/\1/p" "$HAND" 2>/dev/null | tail -n 1); scc=$(sed -n "s/^stage-closed $1 | stand-in: RM at [0-9a-f]* candidate \([0-9]*\).*/\1/p" "$HAND" 2>/dev/null | tail -n 1)
  if [ -n "$sc" ]; then printf ' · closed at %s' "$sc"; ! sh "$HERE/close.sh" corrected "$1" > /dev/null 2>&1 || printf ' · corrected since its close at %s' "$sc"; fi
  if [ -z "$sc" ] || [ "$scc" != "$(snc "$1")" ]; then u=$(sh "$HERE/close.sh" conds "$1" 2>/dev/null | awk '{ print $1 }' | sort -un | paste -sd ',' - | sed 's/,/, /g'); [ -z "$u" ] || printf ' · the close waits on %s' "$u"; fi
  [ "$(sed -n 's/^held-after:[[:space:]]*//p' "$RS" | head -n 1)" != "$1" ] || printf ' · held after %s' "$1"; }
# v0.26.10.26.2 (R2): the setup hold holds while a candidate is named and no D1 has passed, until the owner's continue ends it
hold_off() { HB=${BY:-owner}; echo "setup-hold off | stand-in: $HB $*" >> "$HAND"; rec control:hold off "$*" "$HB" done; ev "setup-hold state=off by=$HB"; echo "setup hold: off"; }   # v0.26.10.28.8 (F-004): who said continue
holding() { grep -q '^candidate [0-9]' "$HAND" 2>/dev/null && ! grep -q '^staged ' "$HAND" && ! grep -q '^setup-hold off ' "$HAND"; }
# v0.26.10.26.5 (R1 conditions 5 and 6): blockers --stage <N> --tickets <file> --rows <file> --steps "<steps>": `5 <key>` for each finding of the
# stage, or of its tickets, without the owner's ruling (a row or fix ruled since this release counts once a draft made --for it landed or was
# declined; one before it, once no draft waits); `6 <key>` for each open item naming the stage: a question on its tickets, a close's or the
# walk's item of its steps or candidates, a draft of its rows waiting
dwait() { for x in $(ls "$D/drafts" 2>/dev/null | grep -E '^[0-9]+$'); do X=$D/drafts/$x; [ -f "$X/asked" ] && [ ! -f "$X/landed" ] && [ ! -f "$X/declined" ] && [ ! -f "$X/replaced" ] && echo "$x"; done; }
cmd_blockers() { N=''; TF=/dev/null; RF=/dev/null; ST=''; while [ $# -ge 2 ]; do case $1 in --stage) N=$2 ;; --tickets) TF=$2 ;; --rows) RF=$2 ;; --steps) ST=$2 ;; *) die "unknown $1" ;; esac; shift 2; done; [ -n "$N" ] || die 'usage — blockers --stage <N> …'
  awk -F'\t' '($1 == "open" || $1 == "merged") && $3 != "-" { print $2 "\t" $3 }' "$RD" 2>/dev/null >> "$Q/prs"; sort -u "$Q/prs" > "$Q/prs.t" || exit 1; put "$Q/prs" < "$Q/prs.t" || exit 1
  { s_all | awk -F'\t' -v n="$N" '$2 == n { print $1 }'; while IFS=$TAB read -r p t; do grep -qx "$t" "$TF" || continue; fnd "$p" | awk -v t="$t" '{ print "finding:" t ":" NR }'; done < "$Q/prs"; } | sort -u > "$Q/bk"
  W0=$(dwait | head -n 1)
  while read -r k; do a=$(awk -F'\t' -v k="$k" '$2 == k { v = $3 } END { print v }' "$Q/answers"); [ -n "$a" ] || { echo "5 $k"; continue; }
    case $a in row|fix) if grep -qxF "$k" "$Q/doors" 2>/dev/null; then ok=''; for f in $(grep -lxF "$k" "$D"/drafts/*/for 2>/dev/null); do X=${f%/for}; { [ -f "$X/landed" ] || [ -f "$X/declined" ]; } && ok=1; done; [ -n "$ok" ] || echo "5 $k"
        else [ -z "$W0" ] || echo "5 $k"; fi ;; esac; done < "$Q/bk"
  items > "$Q/ib"; while IFS=$TAB read -r k g w; do case $k in
      question:*) t=${k#question:}; t=${t%%:*}; { grep -qx "$t" "$TF" || awk -F'\t' -v t="$t" '($1 == "open" || $1 == "merged") && $2 == t { print $3 }' "$RD" 2>/dev/null | grep -qxF -f "$TF" || cat "$D/stage/$N"/[0-9]*/ask "$D/stage/$N"/[0-9]*/s1ask "$D/stage/$N"/[0-9]*/d1/ask "$D/stage/$N"/[0-9]*/cs/ask 2>/dev/null | awk -F'\t' -v t="$t" '$1 == "issue" && $2 == t { f = 1 } END { exit !f }'; } && echo "6 $k" ;;   # its tickets', or its candidates' asks
      close:stage-$N/*) echo "6 $k" ;;
      close:*) sc=${k#close:}; sc=${sc%%/*}; sc=${sc%%:*}; case " $ST " in *" $sc "*) echo "6 $k" ;; esac ;;
      draft:*) x=${k#draft:}; X=$D/drafts/$x; { awk '{ print $2 }' "$X/sets" 2>/dev/null | grep -qxF -f "$RF" || awk -v st=" $ST " "$RNG"' $1 == "step" && index(st, " " $2 " ") { n = split($0, w, /[ ,|]+/); for (i = 1; i <= n; i++) { q = split(rng(w[i]), e, " "); for (k = 1; k <= q; k++) print e[k] } }' "$X/plan" 2>/dev/null | grep -qxF -f "$(awk '$1 == "added" { print $2 }' "$X/sets" > "$Q/da"; echo "$Q/da")"; } && echo "6 $k" ;;   # its rows the stage's, or a row it adds placed in the stage's steps
    esac; done < "$Q/ib"; return 0; }
# R3: the hold after this stage: `held-after: <N>` in RUN-STATE, N the current stage; refused on the final stage and with one stage
cmd_hold() { [ -f STAGES.md ] || die 'no hold with one stage: the project has no STAGES.md'; cur=$(sh "$HERE/stages.sh" current 2>/dev/null || echo 1)
  last=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); if (k ~ /^STAGE-/) { sub(/^STAGE-0*/, "", k); if (k == "") k = 0; m = k } } END { print m }')
  [ "$cur" != "$last" ] || die "no hold on the final stage, $cur"; grep -q '^held-after:' "$RS" && die "a hold is recorded already: $(grep '^held-after:' "$RS")"
  rs_edit awk -v n="$cur" '{ print } /^run:/ && !d { print "held-after: " n; d = 1 }' || exit 1; rec control:hold "after $cur" "$*" owner done
  sh "$HERE/event.sh" "stage-hold n=$cur state=asked words=\"$(printf %s "$*" | tr '"' "'")\"" > /dev/null 2>&1 || true; echo "held after stage $cur"; }
# seed production|synthetic "<words>" (0.26.11.1.1, R6): the owner's alone, no --by; production refused before production exists
cmd_seed() { for a in "$@"; do [ "$a" != --by ] || die "the seed of staging is the owner's word alone: no --by"; done; v=${1:-}; [ $# -gt 0 ] && shift
  case $v in production|synthetic) ;; *) die 'control seed production|synthetic "<their words>"' ;; esac; [ -n "$*" ] || die 'control seed: the owner'"'"'s words'
  p=$(pnow); [ "$v" = synthetic ] || { [ -n "$p" ] && [ "$p" != none ]; } || die 'there is no production data yet'
  rec control:seed "$v" "$*" owner done; ev "staging-seed seed=$v by=owner"; echo "seed: $v"; }
cmd_control() { v=${1:-}; shift; case $v in pause) w='stopped owner asked to pause' ;; continue) w=active ;; hold) cmd_hold "$@"; return 0 ;; seed) cmd_seed "$@"; return 0 ;; *) die 'control pause|continue|hold|seed' ;; esac
  # v0.26.10.26.5 (R3): continue ends the hold once its stage has closed, whatever run: says, with the count of merges staging runs past the
  # held stage's newest closed candidate that no production deploy covers
  hn=$(sed -n 's/^held-after:[[:space:]]*//p' "$RS" | head -n 1); if [ "$v" = continue ] && [ -n "$hn" ] && grep -q "^stage-closed $hn " "$HAND" 2>/dev/null; then
    cc=$(sed -n "s/^stage-closed $hn | stand-in: RM at \([0-9a-f]*\) .*/\1/p" "$HAND" | tail -n 1); dc=''; for f in $(ls -t "$D"/stage/*/*/d1/passed 2>/dev/null); do dc=$(sed -n "s/^commit$TAB//p" "${f%/passed}/ask"); [ -n "$dc" ] && break; done
    n=0; [ -z "$cc" ] || [ -z "$dc" ] || n=$(git --git-dir=.vid/code rev-list --count --first-parent "$cc..$dc" 2>/dev/null || echo 0)
    unhold() { grep -v '^held-after:' | sed "s/^run:.*/run: active/"; }; rs_edit unhold || exit 1; rec control:continue "hold off $hn" "$*" "${BY:-owner}" done; sh "$HERE/event.sh" "stage-hold n=$hn state=off" > /dev/null 2>&1 || true
    echo "hold after stage $hn: off · staging runs $n merges past the held stage's closed candidate that no production deploy covers"; echo "run: active"; return 0; fi
  # a continue that ends no pause, while the hold holds, ends the hold; it never sets the run's state otherwise
  if [ "$v" = continue ] && ! grep -q '^run: *stopped' "$RS" && holding; then hold_off "$*"; k=hold:$(sed -n 's/^candidate \([0-9][0-9]*\) .*/\1/p' "$HAND" | sort -n | head -n 1); rec "$k" continue "$*" owner 'hold off'; return 0; fi
  rs_edit sed "s/^run:.*/run: $w/" || exit 1; rec "control:$v" "$v" "$*" "${BY:-owner}" done; ev "run state=$( [ "$v" = pause ] && echo stopped || echo active ) by=${BY:-owner}"; echo "run: $w"; }
cmd_defect() { s=$1; shift; F=.vid/VID-FINDINGS.md; [ -f "$F" ] || printf '# ViD findings\n\nViD'"'"'s own defects, as the round met them.\n' > "$F"; k="$s: $(printf %s "$*" | cut -c1-80)"
  if grep -qF "## $k" "$F"; then awk -v k="## $k" '$0 == k { print; getline; n = $3 + 1; print "- seen: " n; next } { print }' "$F" > "$Q/vf" || exit 1; put "$F" < "$Q/vf" || exit 1; else printf '\n## %s\n- seen: 1\n- first: %s\n- words: %s\n' "$k" "$(stamp)" "$*" >> "$F"; fi
  ev "vid-defect step=$s"; echo "defect $k"; }
cmd_lesson() { [ $# -ge 2 ] || die 'usage — lesson <rows,…> "<cause>"'; grep -qF "lesson $1 | $2 |" "$HAND" 2>/dev/null || echo "lesson $1 | $2 | stand-in: RM" >> "$HAND"; ev "lesson rows=$1"; echo "lesson $1"; }
# v0.26.10.27.4 (R2): keys, what waits, read only: `<key> TAB <Q n> TAB <words>` a line
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in
  sync) cmd_scan; cmd_sync; announce ;; keys) items > "$Q/ky" || exit 1; while IFS=$TAB read -r k g w; do printf '%s\t%s\t%s\n' "$k" "$(num "$k" | grep . || echo -)" "$w"; done < "$Q/ky" ;; cost) cmd_cost "$@" ;; answer) cmd_answer "$@" ;; status) cmd_status ;; addresses) case ${1:-} in ''|*[!0-9]*) die 'usage — addresses <stage>' ;; esac; c=$(snc "$1"); if [ -n "$c" ]; then addrs "$D/stage/$1/$c" "$1"; else echo 'test site: not known yet'; fi ;; control) cmd_control "$@" ;; blockers) cmd_blockers "$@" ;; defect) cmd_defect "$@" ;; lesson) cmd_lesson "$@" ;;
  recommend) k=$(qn "${1:-}"); case $k in held:*|stage:*) printf '%s\t%s\t%s\n' "$k" "${2:-}" "${3:-}" >> "$Q/recommend"; echo "recommended ${2:-} for $1" ;; *) die "${1:-} is no held row's or stage finding's line" ;; esac ;;
  ask) if [ "${1:-}" = draft ]; then X=$D/drafts/${2:-}; [ -f "$X/base" ] && [ -f "$X/words" ] || die "no draft ${2:-} with a count (sh checks/land.sh draft)"; : > "$X/asked"; ev "queue-draft n=$2"; cmd_sync > /dev/null; echo "asked $(num "draft:$2") draft $2"; exit 0; fi
    i=${1:-}; awk -F'\t' -v i="$i" '$1 == i { f = 1 } END { exit !f }' "$Q/questions" || die "no question $i"
    awk -F'\t' -v i="$i" -v OFS='\t' '$1 == i { $4 = "asked" } { print }' "$Q/questions" > "$Q/qq" || exit 1; put "$Q/questions" < "$Q/qq" || exit 1; cmd_sync > /dev/null; m=$(num "question:$i"); echo "asked $m"
    # v0.26.10.26.7 (R8, W-10): the dev side hears, once, that its question waits; never its text, which cmd_scan would read as the answer
    # once posted, recorded in $Q/waited, so a failed post is tried again at the next ask
    if ! grep -qxF "$i" "$Q/waited" 2>/dev/null; then printf 'RM: this question waits on the lead (%s); go on with what it does not block.\n' "$m" > "$Q/post"
      if sh "$HERE/github.sh" comment "${i%%:*}" --body-file "$Q/post" > /dev/null 2>&1; then echo "$i" >> "$Q/waited"; ev "queue-waiting n=${i%%:*} q=$m"; else echo "waiting-comment-failed ${i%%:*}"; fi; fi ;;
  *) echo 'usage: sh checks/queue.sh sync|recommend|ask|answer|control|status|addresses|cost|defect|lesson' >&2; exit 2 ;; esac
