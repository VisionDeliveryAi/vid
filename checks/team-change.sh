#!/bin/sh
# Purpose: GitHub manual's answer to a change the team made to a ticket's tests (GM-2 T7; GM M9): the yes and the no the move
# `/vid next team-change #<n> <id> yes|no "<words>"` calls. Run at the top of ViD's repository, in GitHub manual alone.
#   sh checks/team-change.sh <n> <id> yes|no "<the owner's words>"
# The change must be one `next.sh changes` lists now (added or dropped, on ticket n, with its evidence hash): one an answer covers
# with that evidence, or none at all, is refused. GM-3 U5: a team-added id found only in the pending spec (`pending-only`) takes a
# no as any change does; its yes is refused, pointing to the apply move, since the analysis takes it into its ticket's step by
# default and the apply's yes takes it in (GM M9). Words are needed, kept on one line (a tab or newline a space, a `"` a `'`).
# yes: the plan's block changed and checked before anything is recorded (GM-4 F5: the preparation a publish makes, the export, the
# sync, the read and the handovers, is github.sh tw-hand's, made for each ticket it changes): added, the test into ticket n's step, out of the step that held it, its no-step line off .vid/tw/to-place (an
# other-stage line kept: it still stands in a step of another stage); dropped, the test out of
# the step. The test leaves its `needs` line (a line left with no row goes) and, moved in, joins the line of its new step's rows
# that names all the step's builds-on, made when there is none. A step left with no test goes from the block, and from every
# other step's builds-on:, fakes: and needs lines (its ticket is then withdrawn). planner.sh check runs on the changed block
# first: a flag other than a `place` flag of the test or a `size` flag refuses, naming it, nothing recorded; a size flag is shown
# as a warning. A `place` flag puts the test on .vid/tw/to-place, `other-stage` (a test of another stage than its step's) or
# `no-step`, with the words. Then plan.sh change rows, trigger owner-answer, evidence ticket:<n>, the words its why (refused: the
# block and the to-place list restored, nothing recorded). The answer is recorded at once; then each ticket the change reaches
# (ticket n, and the open tickets of the step the test left), in the order writer.sh due gives, is withdrawn or amended through K1's
# one path (GM-4 F5: github.sh tw-hand withdraw|amend <m> --words --cause, with the lock, the saved records and the save), on the same
# words, its cause the change taken in.
# no: one comment on ticket n (github.sh tw-team-no), saying the test stays as the ticket had it; then the answer recorded.
# The record, .vid/next/team-answers (GM-2 §5): `<n>\t<added|dropped>\t<id>\t<evidence hash>\t<yes|no>\t<at>\t<words>`, appended;
# next.sh changes reads it and offers the change again only once its evidence changes.
# Exit 0 done; 1 refused (named), or a ticket left owed after the plan change was recorded (said so); 2 usage.
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
die() { echo "ViD team-change: $*" >&2; exit 2; }
ref() { echo "ViD team-change: refused — $*" >&2; exit 1; }
[ $# -eq 4 ] || die 'usage — sh checks/team-change.sh <n> <id> yes|no "<the owner'"'"'s words>"'
N=$1; ID=$2; AN=$3; WD=$4
case $N in ''|*[!0-9]*) die "'$N' is no ticket number" ;; esac
case $AN in yes|no) ;; *) die "the answer is yes or no, not '$AN'" ;; esac
manual || ref 'a team change is answered in GitHub manual alone'
# words of whitespace alone (a carriage return among them) are no words, as tw-post reads them; checked first
[ -n "$(printf '%s' "$WD" | tr -d '[:space:]')" ] || ref "no words: a team change is answered only on the owner's words"
WQ=$(printf '%s' "$WD" | tr '\t\n\r' '   ' | tr '"' "'" | sed 's/^ *//; s/ *$//')
L=$(awk -v n="$N" '$1 == "withdrawn" && $2 == n { w = 1 } ($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { if (!w) print l }' .vid/tw/log 2>/dev/null)
[ -n "$L" ] || ref "#$N is no published ticket open in ViD's records"
TS=$(printf '%s\n' "$L" | tr ' ' '\n' | sed -n 's/^step=//p' | head -n 1)
# the change, as next.sh changes lists it now
sh "$HERE/next.sh" changes > "$T/ch" 2> "$T/che" || { sed 's/^/    /' "$T/che" >&2; ref 'next.sh changes failed'; }
C=$(awk -F'\t' -v n="$N" -v id="$ID" '($1 == "added" || $1 == "dropped") && $2 == n && $3 == id { print; exit }' "$T/ch")
[ -n "$C" ] || ref "next.sh changes lists no change of $ID on #$N: answered with its evidence unchanged, or no change"
KD=$(printf '%s' "$C" | cut -f1); ST=$(printf '%s' "$C" | cut -f4); EV=$(printf '%s' "$C" | cut -f5)
record() { mkdir -p .vid/next; printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$N" "$KD" "$ID" "$EV" "$AN" "$(now)" "$WQ" >> .vid/next/team-answers; }
if [ "$AN" = no ]; then
  sh "$HERE/github.sh" tw-team-no "$N" "$ID" "$KD" > "$T/no" 2>&1 || { sed 's/^/    /' "$T/no" >&2; ref "the comment on #$N could not be posted — nothing recorded"; }
  record; echo "ViD team-change: no — $KD $ID on #$N: the test stays as the ticket had it; one comment posted, the answer recorded"; exit 0; fi
# GM-3 U5: the yes to a pending-only addition is the apply's
[ "$ST" != pending-only ] || ref "$ID is in the pending spec alone, not the applied one: the analysis (/vid next planning-analysis) takes it into #$N's step, and your words to /vid next implement-replan take it in"

# yes: the block changed (GM-4 F5: each post's preparation is tw-hand's)
plan_block > "$T/blk"; [ -s "$T/blk" ] || ref 'RUN-STATE holds no plan block'
awk -v id="$ID" -v kd="$KD" -v ts="$TS" -v GONE="$T/gone" -v SRC="$T/src" "$RNG"'
  function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function ex(v,   m, a, j, o) { gsub(/[\t,]/, " ", v); m = split(v, a, " "); o = ""; for (j = 1; j <= m; j++) if (a[j] != "") o = o " " rng(a[j]); return substr(o, 2) }
  function has(l, x,   m, a, j) { m = split(l, a, " "); for (j = 1; j <= m; j++) if (a[j] == x) return 1; return 0 }
  function less(l, x,   m, a, j, o) { m = split(l, a, " "); o = ""; for (j = 1; j <= m; j++) if (a[j] != x) o = o (o == "" ? "" : " ") a[j]; return o }
  function lessall(l,   s) { for (s in G) l = less(l, s); return l }
  function same(a, b,   x, m, k, y, j) { m = split(a, x, " "); k = split(b, y, " "); if (m != k) return 0; for (j = 1; j <= m; j++) if (!has(b, x[j])) return 0; return 1 }
  function allin(a, b,   x, m, j) { m = split(a, x, " "); for (j = 1; j <= m; j++) if (!has(b, x[j])) return 0; return 1 }
  function sid(l,   x) { x = l; sub(/^[ \t]*step[ \t]+/, "", x); sub(/[ \t]*\|.*/, "", x); return tr(x) }
  function fld(l, k,   m, a, j, x) { m = split(l, a, "|"); for (j = 2; j <= m; j++) { x = tr(a[j]); if (index(x, k ":") == 1) return tr(substr(x, length(k) + 2)) } return "" }
  function setf(l, k, v,   m, a, j, x, o) { m = split(l, a, "|"); o = tr(a[1]); for (j = 2; j <= m; j++) { x = tr(a[j]); if (index(x, k ":") == 1) x = k ": " v; o = o " | " x } return o }
  { B[++n] = $0 }
  END {
    for (i = 1; i <= n; i++) if (B[i] ~ /^[ \t]*step[ \t]/) { s = sid(B[i]); R[s] = ex(fld(B[i], "rows")); SI[i] = s }
    for (s in R) { r = R[s]
      if (kd == "added") { if (s != ts && has(r, id)) { r = less(r, id); print s > SRC } if (s == ts && !has(r, id)) r = r (r == "" ? "" : " ") id }
      else if (s == ts) r = less(r, id)
      if (r != R[s]) CH[s] = 1; R[s] = r; if (r == "") { G[s] = 1; print s > GONE } }
    bo = ""; for (i = 1; i <= n; i++) if ((i in SI) && SI[i] == ts) { bo = fld(B[i], "builds-on"); bo = (bo == "-" ? "" : lessall(ex(bo))) }
    # the needs lines: the test leaves its line; moved in, it joins the line of its step naming all its builds-on, made when none
    tgt = 0; last = 0
    for (i = 1; i <= n; i++) if (B[i] ~ /^[ \t]*needs[ \t]/) { last = i; v = B[i]; sub(/^[ \t]*needs[ \t]+/, "", v); p = index(v, "|")
        NR_[i] = less(ex(substr(v, 1, p - 1)), id); w = tr(substr(v, p + 1)); NW[i] = (w == "-" ? "" : lessall(ex(w)))
        if (kd == "added" && !tgt && NR_[i] != "" && same(NW[i], bo) && allin(NR_[i], R[ts])) tgt = i }
    for (i = 1; i <= n; i++) {
      if (i in SI) { s = SI[i]; if (s in G) continue; l = B[i]
        if (s in CH) l = setf(l, "rows", R[s])
        b = fld(l, "builds-on"); if (b != "" && b != "-") { b2 = lessall(ex(b)); if (b2 != ex(b)) l = setf(l, "builds-on", b2 == "" ? "-" : b2) }
        f = fld(l, "fakes"); if (f != "" && f != "-") { f2 = lessall(ex(f)); if (f2 != ex(f)) l = setf(l, "fakes", f2 == "" ? "-" : f2) }
        print l; continue }
      if (i in NR_) { r = NR_[i]; if (i == tgt) r = r " " id; if (r != "") print "needs " r " | " (NW[i] == "" ? "-" : NW[i])
        if (i == last && kd == "added" && !tgt) print "needs " id " | " (bo == "" ? "-" : bo); continue }
      print B[i] } }' "$T/blk" > "$T/nblk"
touch "$T/gone" "$T/src"
# the planner's check on the changed block, before anything is recorded
RC=0; sh "$HERE/planner.sh" check --block "$T/nblk" > "$T/pk" 2>&1 || RC=$?
[ "$RC" -le 1 ] || { sed 's/^/    /' "$T/pk" >&2; ref 'planner.sh check could not read the changed plan — nothing recorded'; }
: > "$T/tp"; : > "$T/bad"; : > "$T/warn"
if [ "$RC" = 1 ]; then while IFS= read -r f; do case $f in
    "place $ID — in no step"*) printf '%s\tno-step\n' "$ID" >> "$T/tp" ;;
    "place $ID — in step "*) printf '%s\tother-stage\n' "$ID" >> "$T/tp" ;;
    'size '*) echo "$f" >> "$T/warn" ;;
    *) echo "$f" >> "$T/bad" ;; esac; done < "$T/pk"; fi
[ ! -s "$T/bad" ] || { sed 's/^/    /' "$T/bad" >&2; ref "planner.sh check flags the changed plan ($(head -n 1 "$T/bad")) — nothing recorded"; }
[ ! -s "$T/warn" ] || sed 's/^/ViD team-change: warning, not a refusal in GitHub manual — /' "$T/warn"
# recorded: the block and the to-place list, then the plan change; refused, both restored
cp .vid/RUN-STATE.md "$T/rs0"; TP0=''; if [ -f .vid/tw/to-place ]; then cp .vid/tw/to-place "$T/tp0"; TP0=1; else : > "$T/tp0"; fi
restore() { cat "$T/rs0" > .vid/RUN-STATE.md; if [ -n "$TP0" ]; then cat "$T/tp0" > .vid/tw/to-place; else rm -f .vid/tw/to-place; fi; }
awk -v NB="$T/nblk" 'BEGIN { while ((getline l < NB) > 0) K[++k] = l } /^## The plan/ { s = 1 } s && !d && /^```vid-plan[ \t]*$/ { print; for (i = 1; i <= k; i++) print K[i]; b = 1; d = 1; next } b && /^```[ \t]*$/ { b = 0 } !b { print }' "$T/rs0" > "$T/rs1"
put .vid/RUN-STATE.md < "$T/rs1" || { restore; ref 'RUN-STATE.md could not be written — nothing recorded'; }
# an added yes takes the test's no-step line off the to-place list, and keeps an other-stage one
{ awk -F'\t' -v id="$ID" -v kd="$KD" '$1 != id || (kd == "added" && $2 == "other-stage")' "$T/tp0"; awk -F'\t' -v t="$(now)" -v w="$WQ" -v OFS='\t' '{ print $1, $2, t, w }' "$T/tp"; } > "$T/tp1"
mkdir -p .vid/tw; if [ -s "$T/tp1" ] || [ -n "$TP0" ]; then put .vid/tw/to-place < "$T/tp1" || { restore; ref '.vid/tw/to-place could not be written — nothing recorded'; }; fi
if [ "$KD" = added ]; then EX="$ID moves into step $TS, as the team added it to #$N"; else EX="$ID leaves step $TS for the to-place list, as the team took it out of #$N"; fi
sh "$HERE/plan.sh" change rows "$WQ" --trigger owner-answer --evidence "ticket:$N" --expect "$EX" > "$T/pc" 2>&1 || { sed 's/^/    /' "$T/pc" >&2; restore; ref 'the plan change was refused — nothing recorded'; }
record
echo "ViD team-change: yes — $KD $ID on #$N: the plan change recorded$([ ! -s "$T/tp" ] || echo ", $ID on the to-place list ($(cut -f2 "$T/tp"))"), the answer recorded"
# the tickets the change reaches: ticket n and the open tickets of the step the test left; each as writer.sh due owes it
{ echo "$N"; for s in $(cat "$T/src"); do awk -v s="step=$s" '$1 == "withdrawn" { W[$2] = 1 } ($1 == "published" || $1 == "amended") { for (i = 3; i <= NF; i++) if ($i == s) P[$2] = 1 } END { for (t in P) if (!(t in W)) print t }' .vid/tw/log; done; } | sort -u > "$T/reach"
owed() { echo "ViD team-change: the plan change and the answer are recorded; $1 — it stays owed, a move at the next call" >&2; exit 1; }
sh "$HERE/writer.sh" due > "$T/due" 2>&1 || { sed 's/^/    /' "$T/due" >&2; owed 'writer.sh due failed, so no ticket was changed'; }
if [ "$KD" = added ]; then CN="the team's addition of $ID to this ticket, taken in"; else CN="the team's removal of $ID from this ticket, taken in"; fi
while read -r k m _r; do grep -qx "$m" "$T/reach" || continue; if [ "$m" = "$N" ]; then c=$CN; else c="$ID moves to step $TS, ticket #$N, where the team added it"; fi
  case $k in
    withdraw) sh "$HERE/github.sh" tw-hand withdraw "$m" --words "$WQ" --cause "$c" > "$T/o" 2>&1 || { sed 's/^/    /' "$T/o" >&2; owed "the withdrawal of #$m failed"; } ;;
    amend) sh "$HERE/github.sh" tw-hand amend "$m" --words "$WQ" --cause "$c" > "$T/o" 2>&1 || { sed 's/^/    /' "$T/o" >&2; owed "the amendment of #$m failed"; } ;;
    *) continue ;; esac
  sed 's/^/    /' "$T/o"; done < "$T/due"
exit 0
