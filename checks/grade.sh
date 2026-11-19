#!/bin/sh
# Purpose: the owner's grade asks in ticket mode (v0.26.10.27.2, R1). `/vid grade` in ticket mode is an ask for one grade, S1's form
# (v0.26.10.26.1 R3) with the owner's scope: GR, DevAgent's, grades; ViD reads the report's form alone, and every finding goes to the
# owner (queue.sh, R2). It reads no code and runs nothing. Run at the top of ViD's repository.
#   ask [--reqs "<REQ ids>"] [--focus "<words>"] [--vs <commit>] [--robustify "<area>; <area>; …"] [--commit <c>] (v0.26.10.27.4: a commit given, R4's)
#        posts one ask on an issue labelled grade: `grade: ask-<n>`, `commit:` the newest candidate's commit (main's newest merge with no
#        candidate), the requirements asked (by default those of stages up to the newest candidate's stage, stage 1's with none, every
#        live one with no STAGES.md; or those named; invariants left out), the rest listed as deferred; the focus areas first; a `vs:`
#        commit; or 3 to 5 robustify areas, which ask no requirement lines. Prints `asked <n> grade ask-<n>`
#   step  each ask out: its report read (results.sh grade --ask <n>); a refused one posted back once; late, `vid: again s1` once, then
#        lost, a `grade:<n>:lost` item for the owner (queue.sh). Prints `grade-ask <n> read <k> …`, `vs <n> <REQ> <word> — <reason>` for a
#        requirement that passed at the ask's commit, `grade-ask-refused <n> <k>`, `grade-again <n>`, `grade-lost <n>`
#   out   the asks out, one number a line: neither read, withdrawn nor lost (round.sh holds `nothing-left` back for them)
#   lost  the asks lost, waiting on the owner: their issues stay open, and hold back no `nothing-left`
#   again <n> | withdraw <n>   the owner's answer to a lost ask: asked again, or closed `vid: withdrawn`
# Records: .vid/decide/grade/<n>/: ask (issue, commit, asked, reqs, deferred, vs, robustify, focus; tab), body, read (results.sh's),
# grades (REQ, word, reason, vs word, vs reason; tab), findings, done, refused, again, allow, lost, withdrawn.
# serves: tickets (0.26.10.28.4, M9)
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
[ -f .vid/RUN-STATE.md ] || { echo "ViD grade: run it at the top of ViD's repository" >&2; exit 2; }
D=.vid/decide; G=$D/grade; HAND=.vid/tw/handed; RD=.vid/round/read; TAB=$(printf '\t'); mkdir -p "$G" .vid/round
die() { echo "ViD grade: $*" >&2; exit 1; }
gh_() { sh "$HERE/github.sh" "$@"; }
akey() { sed -n "s/^$2$TAB//p" "$G/$1/ask" | head -n 1; }
# cand: `<stage> <commit>` of the newest candidate (the highest stage with a named one, its newest), or nothing; stage 0's, the walking
# skeleton's, never released, counts as none
cand() { for x in $(ls "$D/stage" 2>/dev/null | grep -E '^[1-9][0-9]*$' | sort -n); do c=''; for k in $(ls "$D/stage/$x" | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/stage/$x/$k/named" ] && [ -s "$D/stage/$x/$k/commit" ] && c=$k; done
    [ -z "$c" ] || echo "$x $(head -n 1 "$D/stage/$x/$c/commit")"; done | tail -n 1; }
# mainc: main's newest merge: main at the newest sync (TW's, .vid/tw/log), else the merges record's last
mainc() { m=$(sed -n 's/^sync main=\([0-9a-f]*\) .*/\1/p' .vid/tw/log 2>/dev/null | tail -n 1); [ -n "$m" ] || m=$(awk -F'\t' '$4 != "" && $4 != "-" { m = $4 } END { print m }' "$D/merges" 2>/dev/null); echo "$m"; }
# live: the effective requirements; with `pilot`, those not `phase: later`
live() { sh "$HERE/prd.sh" --effective 2>/dev/null | awk -F'|' -v P="${1:-}" '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^phase:[ \t]*later$/) l = 1 } } k ~ /^REQ-[0-9]/ && !(P == "pilot" && l) { print k }' | sort -u; }

cmd_ask() { RQ=''; FO=''; VS=''; RB=''; AC=''; while [ $# -ge 2 ]; do case $1 in --reqs) RQ=$2 ;; --focus) FO=$2 ;; --vs) VS=$2 ;; --robustify) RB=$2 ;; --commit) AC=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
  [ $# -eq 0 ] || die "unknown $1"
  set -- $(cand); N=${1:-}; C=${2:-}; [ -z "$AC" ] || C=$AC; [ -n "$C" ] || C=$(mainc); [ -n "$C" ] || die 'no candidate and no merge on main: nothing to grade yet'   # v0.26.10.27.4: --commit, the offered grade's item's candidate
  T=$(mktemp -d "$PWD/$G/tmp.XXXXXX"); trap 'rm -rf "$T"' EXIT; live > "$T/live"
  if [ -n "$RB" ]; then n=$(printf '%s\n' "$RB" | tr ';' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -c .); [ "$n" -ge 3 ] && [ "$n" -le 5 ] || die "robustify takes 3 to 5 areas, ; between them: $n given"
    [ -z "$RQ$VS" ] || die 'a robustify ask asks no requirement and no second commit'; : > "$T/ask"
  elif [ -n "$RQ" ]; then printf '%s\n' "$RQ" | tr ' ,' '\n\n' | grep . | sort -u > "$T/ask"; bad=$(grep -v '^REQ-[0-9]' "$T/ask" | paste -sd ' ' -); [ -z "$bad" ] || die "not requirements: $bad (invariants are left out)"
    bad=$(comm -23 "$T/ask" "$T/live" | paste -sd ' ' -); [ -z "$bad" ] || die "no live requirement: $bad"
  elif [ -f STAGES.md ]; then mustread "$T/sc" stages scope --upto "${N:-1}" --reqs; grep '^REQ-[0-9]' "$T/sc" | sort -u | comm -12 - "$T/live" > "$T/ask"
  else live pilot > "$T/ask"; fi
  [ -n "$RB" ] || [ -s "$T/ask" ] || die 'no requirement to ask'
  VS0=$VS; [ -z "$VS" ] || [ -d .vid/code ] || die "vs $VS: no copy of the code repository to find it in (sh checks/github.sh results-fetch)"; [ -z "$VS" ] || VS=$(git --git-dir=.vid/code rev-parse -q --verify "$VS^{commit}" 2>/dev/null) || die "vs ${VS0:-?}: the code repository's copy has no such commit (sh checks/github.sh results-fetch)"   # a full id, as the runs need
  comm -23 "$T/live" "$T/ask" > "$T/def"; AQ=$(paste -sd ' ' "$T/ask"); DF=$(paste -sd ' ' "$T/def"); RB1=$(printf '%s\n' "$RB" | tr ';' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep . | paste -sd ';' - | sed 's/;/; /g')
  { printf 'grade: ask-#\ncommit: %s\nrequirements: %s\n' "$C" "${AQ:-none}"; [ -z "$VS" ] || printf 'vs: %s\n' "$VS"; [ -z "$RB1" ] || printf 'robustify: %s\n' "$RB1"; echo
    [ -z "$FO" ] || printf 'Focus areas, graded first and deepest: %s\n\n' "$FO"
    [ -z "$DF" ] || [ -n "$RB1" ] || printf 'Deferred, not asked: %s\n\n' "$DF"
    if [ -n "$RB1" ]; then printf 'Grade each area named above as built, in a fresh context. Give each protection the area lacks as a `finding: rule — <the invariant, in plain words>` line, no command; then any other finding, `finding: bug|rule <severity> — <line>`. The report holds finding lines alone: no requirement line, and no line for an area as built.'
    else printf 'Grade each requirement, in a fresh context, against the grading checklist and its rows'"'"' fail-ifs: pass, partial, facade (looks built, isn'"'"'t) or absent, each with its reason. One line per requirement, `REQ-<n> <word> — <reason>`'
      [ -z "$VS" ] || printf ', graded at the commit above and again at the vs: commit, on the same line: `REQ-<n> <word> — <reason> — vs: <word> — <reason>`'
      printf '. Then each finding, tagged bug or rule, with its severity, high, medium or low, after its tag: `finding: bug|rule <severity> — <line>`.'; fi
    printf ' Report it as vid-results/grade-<this issue>-<k>, its grade.txt by: GR, its commit the one above, then comment `vid: reported s1-<k>` here. Comment `vid: started` when it starts; send it again only after a comment `vid: again s1`, or a refusal.\n'; } > "$T/body"
  i=$(gh_ grade-ask --stage ask --commit "$C" --title "Grade ask: $(if [ -n "$RB1" ]; then echo "robustify $RB1"; elif [ -n "$RQ" ]; then echo "$AQ"; else echo "stages up to ${N:-1}"; fi)$([ -z "$VS" ] || echo ", vs $VS")" --body-file "$T/body") || die 'the grade ask could not be posted'
  [ -n "$i" ] || die 'the grade ask has no number'; mkdir -p "$G/$i"; sed "s/^grade: ask-#$/grade: ask-$i/" "$T/body" > "$G/$i/body"
  printf 'issue\t%s\ncommit\t%s\nasked\t%s\nreqs\t%s\ndeferred\t%s\nvs\t%s\nrobustify\t%s\nfocus\t%s\n' "$i" "$C" "$(stamp)" "$AQ" "$DF" "$VS" "$RB1" "$FO" > "$G/$i/ask"
  ev "grade-ask issue=$i commit=$C reqs=$(wc -w < "$T/ask" | tr -d ' ')${VS:+ vs=$VS}${RB1:+ robustify=yes}"; echo "asked $i grade ask-$i"; }

outs() { for n in $(ls "$G" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do X=$G/$n; [ -f "$X/ask" ] && [ ! -f "$X/done" ] && [ ! -f "$X/withdrawn" ] && echo "$n"; done; }
cmd_step() { for n in $(outs); do X=$G/$n; touch "$X/again"; sh "$HERE/results.sh" grade --ask "$n" > /dev/null 2> .vid/round/ge || die "ask $n could not be read: $(tail -n 1 .vid/round/ge)"
    set -- $(head -n 1 "$X/read" | tr '\t' ' ')
    case $2 in
      read) awk -F'\t' '$1 == "grade" { print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }' "$X/read" > .vid/round/gg || exit 1; put "$X/grades" < .vid/round/gg || exit 1; sed -n "s/^finding$TAB//p" "$X/read" > .vid/round/gf || exit 1; put "$X/findings" < .vid/round/gf || exit 1; rm -f "$X/lost"; : > "$X/done"
        gh_ close "$n" > /dev/null 2>&1 || true; ev "grade-read issue=$n graded=$(grep -c . "$X/grades") findings=$(grep -c . "$X/findings")"
        echo "grade-ask $n read $3: $(grep -c . "$X/grades") graded, $(awk -F'\t' '$2 != "pass"' "$X/grades" | grep -c .) not pass, $(grep -c . "$X/findings") findings"
        awk -F'\t' -v n="$n" '$2 == "pass" && $4 != "" { print "vs " n " " $1 " " $4 " — " $5 }' "$X/grades"; continue ;;
      refused) grep -qx "refused $3" "$X/refused" 2>/dev/null || { printf 'vid: refused s1-%s\nby: RM\n\n%s\n' "$3" "$(cut -f4- "$X/read" | head -n 1)" > .vid/round/gr
          gh_ comment "$n" --body-file .vid/round/gr > /dev/null 2>&1 && echo "refused $3" >> "$X/refused"; echo "grade-ask-refused $n $3"; } ;;
    esac
    [ ! -f "$X/lost" ] || continue
    W=$(skey close-wait-minutes); W=$((${W:-180} * 60)); u=$(awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { print $5 }' "$RD" 2>/dev/null); [ -n "$u" ] || u=$(akey "$n" asked); q=$(( $(date +%s) - $(epoch "$u") ))
    if [ -f "$X/allow" ] || { [ "$q" -ge "$W" ] && ! grep -q . "$X/again"; }; then printf 'vid: again s1\nby: RM\n' > .vid/round/gr; gh_ comment "$n" --body-file .vid/round/gr > /dev/null 2>&1 || die "the grade ask #$n could not be commented"
      rm -f "$X/allow"; echo "again $(stamp)" >> "$X/again"; echo "grade-again $n"
    elif [ "$q" -ge "$W" ]; then : > "$X/lost"; ev "grade-lost issue=$n"; echo "grade-lost $n"; fi; done; }
cmd_answer() { n=${2:-}; X=$G/$n; [ -f "$X/ask" ] || die "no grade ask $n"; case $1 in
    again) [ -f "$X/lost" ] || die "ask $n is not lost"; rm -f "$X/lost"; : > "$X/allow"; echo "again $n" ;;
    withdraw) printf 'vid: withdrawn. The owner withdrew this grade ask; a later report for it is not read.\n' > .vid/round/gr; gh_ comment "$n" --body-file .vid/round/gr > /dev/null 2>&1 || true
      gh_ close "$n" > /dev/null 2>&1 || true; rm -f "$X/lost"; : > "$X/withdrawn"; ev "grade-withdrawn issue=$n"; echo "withdrawn $n" ;; esac; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in
  ask) cmd_ask "$@" ;; step) cmd_step ;; out) outs | while read -r n; do [ -f "$G/$n/lost" ] || echo "$n"; done ;; lost) outs | while read -r n; do [ ! -f "$G/$n/lost" ] || echo "$n"; done ;; again|withdraw) cmd_answer "$CMD" "$@" ;;
  *) echo 'usage: sh checks/grade.sh ask [--reqs "<ids>"] [--focus "<words>"] [--vs <commit>] [--robustify "<a>; <b>; <c>"] | step | out | again <n> | withdraw <n>' >&2; exit 2 ;; esac
