#!/bin/sh
# Purpose: the end of a ticket-mode run, computed (v0.26.10.27.4, stage 8.3, R2, R3). Completion is read from ViD's records alone, never
# asserted: close.sh endconds gives each unmet condition (1 the final stage's newest candidate closed, none due; 2 every row decided;
# 3 every live requirement's newest grade current, no grade ask out; 4 no ticket open; 5 no question open; 6 every finding ruled).
#   complete           writes the completion report, .vid/decide/completion.md, met or unmet; only a met one also writes `run: complete`
#                      in RUN-STATE and the event `run state=complete`. Prints `complete`, or `unmet <n>` then each unmet condition
#   complete --check   the same computation, writing nothing (the watcher's, R5): exit 0 when complete, 1 with the first unmet line
# The report, in develop's order, each line naming its evidence by id or "unverified": the rows headline (rows by state, never tests);
# completion; what shipped by requirement, with its newest grade and that grade's candidate; the deploy-owed rows ("N rows at deploy")
# and the later items ("M later"); the rule rows' newest covers: counts; the metrics roll-up (each ticket's cost line, the flags,
# regressions); the findings for the owner's ruling; the decisions ViD made on the owner's behalf (0.26.10.29.5, DP-1 R4: every answer
# not given by the owner, the queue's and the held-row rulings, with who gave it, and the DECISIONS.md lines with origin: proposal); every open question. It is no
# production okay. Run at the top of ViD's repository.
# Usage: sh checks/end.sh complete [--check]
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
[ -f .vid/RUN-STATE.md ] || { echo "ViD end: run it at the top of ViD's repository" >&2; exit 2; }
[ "${1:-}" = complete ] || { echo 'usage: sh checks/end.sh complete [--check]' >&2; exit 2; }
CHK=no; [ "${2:-}" = --check ] && CHK=yes
D=.vid/decide; HAND=.vid/tw/handed; RS=.vid/RUN-STATE.md; TAB=$(printf '\t'); mkdir -p .vid/round
T=$(mktemp -d "$PWD/.vid/round/end.XXXXXX"); trap 'rm -rf "$T"' EXIT
[ "$CHK" = yes ] || sh "$HERE/queue.sh" sync > /dev/null 2>&1 || true   # RUN-STATE's open questions as the records stand
RC=0; sh "$HERE/close.sh" endconds > "$T/u" 2> /dev/null || RC=$?
if [ "$CHK" = yes ]; then if [ "$RC" = 0 ]; then echo complete; exit 0; fi; head -n 1 "$T/u"; exit 1; fi
# the report's parts
sh "$HERE/planner.sh" rows 2>/dev/null | grep -v '^#' > "$T/plr" || : > "$T/plr"
hst() { sed -n "s/^row $1 \([^ |]*\).*/\1/p" "$HAND" 2>/dev/null | tail -n 1; }
# each row's state: the handed record's, else a later item's (`later`) or a plan limit (`known-limit, by the plan`) by its class
awk -F'\t' '$2 == "row" { print $1 "\t" $5 "\t" $6 "\t" $7 }' "$T/plr" | while IFS=$TAB read -r r g cl mk; do w=$(hst "$r")
  if [ -z "$w" ]; then case "$g $cl" in *later*) w=later ;; *limit*) w='known-limit, by the plan' ;; *record*) w=record ;; *) w=not-yet-decided ;; esac; fi; printf '%s\t%s\t%s\t%s\t%s\n' "$r" "$w" "$g" "$cl" "$mk"; done > "$T/rs"
F=$(awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); if (k ~ /^STAGE-/) { sub(/^STAGE-0*/, "", k); if (k == "") k = 0; m = k } } END { print m + 0 }' STAGES.md 2>/dev/null); [ "${F:-0}" -ge 1 ] || F=1
{
  printf '# The completion report\n\nComputed by checks/end.sh at %s, from the records alone; never written by the model. It is no production okay: production stays the owner'"'"'s.\n\n' "$(stamp)"
  printf '## 1. The rows\n\n'; awk -F'\t' '{ c[$2]++ } END { for (s in c) printf "- %s: %d\n", s, c[s] }' "$T/rs" | sort; printf '\nEvidence: the handed record (.vid/tw/handed), each row'"'"'s newest line.\n\n'
  printf '## 2. Completion\n\n'; if [ "$RC" = 0 ]; then echo 'Complete: every condition holds.'; else awk '{ n = $1; $1 = ""; print "- condition " n ":" $0 }' "$T/u"; fi; printf '\nEvidence: close.sh endconds.\n\n'
  printf '## 3. What shipped, by requirement\n\n'
  for f in $(ls "$D"/stage/*/s1 2>/dev/null); do x=${f%/s1}; x=${x##*/}; awk -F'\t' -v x="$x" '{ print $1 "\t" x "\t" $3 "\t" $2 }' "$f"; done | sort -t"$TAB" -k1,1 -k2,2n -k3,3n | awk -F'\t' '{ L[$1] = $0 } END { for (q in L) print L[q] }' | sort > "$T/g"
  if [ -s "$T/g" ]; then while IFS=$TAB read -r q x c w; do i=$(sed -n "s/^issue$TAB//p" "$D/stage/$x/$c/s1ask" 2>/dev/null); printf -- '- %s: %s, graded at stage %s'"'"'s candidate %s (grade ask #%s)\n' "$q" "$w" "$x" "$c" "${i:-unverified}"; done < "$T/g"; else echo '- none graded (unverified)'; fi
  # 8.1b's line, `production <N> | stand-in: D2 #<i> at <commit12>`: stages up to N in production; the final stage once N reaches it
  PL=$(awk -v f="$F" '$1 == "production" && $2 ~ /^[0-9]+$/ && $2 + 0 >= f + 0 { l = $0 } END { print l }' "$HAND" 2>/dev/null)
  if [ -n "$PL" ]; then printf '\nStage %s is in production (%s, the handed record). Stage 0 is never released.\n' "$F" "$(printf %s "$PL" | sed 's/^production [0-9]* | stand-in: //; s/[[:space:]]*$//')"; fi
  awk -F'\t' '$5 ~ /(^| )(owed-staging|owed-rehearsal|owed-production|seam)( |$)/ && $2 !~ /^(paid|known-limit|later|record)/ { n++; o = ($5 ~ /owed-production/) ? "production" : ($5 ~ /owed-rehearsal/) ? "the rehearsal" : "staging"; L = L "- " $1 ": owed to " o " (its plan marks; " (($2 == "owed") ? "the handed record: owed" : "the handed record: " $2) ")\n" }
    END { printf "\n## 4. The deploy-owed rows and the later items\n\n%d rows at deploy\n\n%s", n, L }' "$T/rs"
  # 0.26.10.28.6 (R1 (b)): each walk the owner closed without, a known limit, in its words with who answered and when
  for f in $(ls "$D"/stage/*/*/w1/limit 2>/dev/null); do y=${f#"$D"/stage/}; printf -- '- stage %s, candidate %s: %s (%s)\n' "${y%%/*}" "$(printf %s "$y" | cut -d/ -f2)" "$(sed -n 1p "$f")" "$(sed -n 2p "$f")"; done > "$T/wl"
  [ ! -s "$T/wl" ] || { printf '\nThe walks not done, known limits:\n\n'; cat "$T/wl"; }
  sh "$HERE/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); if (k !~ /^REQ-[0-9]/) next; for (i = 3; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^phase:[ \t]*later$/ && !s[k]++) { n++; L = L "- " k " (PRD.md, phase: later)\n" } } } END { printf "\n%d later\n\n%s", n, L }'   # the later items, by requirement
  printf '\n## 5. The rule rows\n\n'; k=0; for r in $(awk -F'\t' '$1 ~ /^RULE-/ { print $1 }' "$T/rs"); do k=$((k + 1)); l=''; e=''   # the newest read report's covers count, on the row's line
    for f in $(ls -t .vid/results/*.txt 2>/dev/null); do l=$(grep "^$r$TAB" "$f" 2>/dev/null | grep -o 'covers [0-9][0-9]*' | head -n 1); [ -z "$l" ] || { e=$f; break; }; done
    if [ -n "$l" ]; then printf -- '- %s: %s places (%s)\n' "$r" "${l#covers }" "$e"; else printf -- '- %s: no covers: count (unverified)\n' "$r"; fi; done; [ "$k" -gt 0 ] || echo '- none'
  printf '\n## 6. The metrics roll-up\n\n'; sh "$HERE/queue.sh" cost 2>/dev/null | sed 's/^/- /' || true; printf '\nFlags, raised and cleared (.vid/metrics-events):\n\n'; grep -E '^flag(-cleared)? word=' .vid/metrics-events 2>/dev/null | sed 's/^/- /' | grep . || echo '- none'
  printf '\nRegressions (each close'"'"'s numbers):\n\n'; for x in "$D"/close/*/* "$D"/stage/*/*; do [ -s "$x/numbers" ] || continue; printf -- '- %s: %s\n' "${x#$D/}" "$(head -n 1 "$x/numbers")"; done | grep . || echo '- none'
  sh "$HERE/queue.sh" keys > "$T/k" 2>/dev/null || : > "$T/k"
  printf '\n## 7. The findings for the owner'"'"'s ruling\n\n'; awk -F'\t' '$1 ~ /^(finding|findings|stage|grade):/ { print "- " $2 ": " $3 " (" $1 ")" }' "$T/k" | grep . || echo '- none'
  # 0.26.10.29.5 (DP-1 R4): develop's "on your behalf": every answer not given by the owner (lib.sh's notowner, the stage facts' set), each
  # with who gave it, then the DECISIONS.md lines with origin: proposal alone, never every decision
  printf '\n## 8. The decisions ViD made on the owner'"'"'s behalf\n\n'
  { notowner | sort | awk -F'\t' '{ s = ($2 ~ /^held:/) ? "the held-row rulings" : "the queue'"'"'s answers"; print "- " $1 " " $2 ": " ($4 == "" ? $3 : $4) " (" s ", by " $5 ")" }'
    grep -E '^- \*\*D-[0-9]+\*\* .*\|[[:space:]]*origin:[[:space:]]*proposal[[:space:]]*(\||$)' DECISIONS.md 2>/dev/null | grep -o '^- \*\*D-[0-9][0-9]*\*\* [^|]*' | sed 's/^- \*\*\(D-[0-9]*\)\*\* /- \1: /; s/[[:space:]]*$/ (DECISIONS.md, origin: proposal)/'; } > "$T/s8"
  if [ -s "$T/s8" ]; then cat "$T/s8"; else echo '- none'; fi
  printf '\n## 9. The open questions\n\n'; awk -F'\t' '$1 !~ /^(production|production-lost|finding|findings|stage|grade):/ { print "- " $2 ": " $3 " (" $1 ")" }' "$T/k"
  awk -v I="$D/queue/ids" 'BEGIN { while ((getline l < I) > 0) { split(l, y, "\t"); O[y[2]] = 1 } } /^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+ / && !($2 in O) { print "- " $2 ": " substr($0, 1, 120) " (RUN-STATE)" }' "$RS" | tee "$T/rq"   # the session's own
 grep -n '^VID-QUESTION: ' PRD.md 2>/dev/null | sed 's/^\([0-9]*\):/- PRD.md:\1 /' | cut -c1-160
  [ -s "$T/k" ] || [ -s "$T/rq" ] || grep -q '^VID-QUESTION: ' PRD.md 2>/dev/null || echo '- none'
} > "$T/report" || exit 1
put "$D/completion.md" < "$T/report" || exit 1
if [ "$RC" = 0 ]; then rs_edit sed 's/^run:.*/run: complete/' || exit 1; ev 'run state=complete'; echo complete
else echo "unmet $(grep -c . "$T/u")"; cat "$T/u"; exit 1; fi
