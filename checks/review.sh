#!/bin/sh
# Purpose: ViD's own review (FB-3 A1.4, A1.6): of a ticket, at a commit of main, in GitHub manual alone; of a stage (S1) and of the owner's
# `/vid grade` ask, each asked in GitHub manual as ViD's own, and made in either mode, a switch to GitHub auto since included. It prepares a fresh agent's brief, shows it the changes it may read, and checks and keeps what it wrote. It
# starts no agent and decides nothing. Run at the top of ViD's repository.
# What it reads, the whole list: ViD's own repository at the applied commit, the published tickets and ViD's records; the names, results
# and messages of the test cases in the results reports at the commit (.vid/code, the reports' own folders); and the changes of the
# tickets' merged pull requests, from GitHub's list of a pull request's files (github.sh pr-files).
# What it never writes: any of the team's code. `show` prints a change and writes nothing, no file and no object of .vid/code; it prints
# only for a pull request on the review's own list. What it prints stands in the reader's own conversation.
#   prepare step-<n> <commit>   a ticket's review at a commit of main, once a ticket. prepare stage-<N>: the newest candidate's own
#       grade. prepare <an ask's ten digits>: that ask's. Writes .vid/round/review/<id>/ (not saved): brief.md from
#       skills/vid-accept-step/passes/review.md, ticket.md, spec/ (ViD's own repository's spec), prs (the list). The id: step-<n>-<c12>, or
#       the ask's number. Prints `brief <id> <path>`. A ticket no pull request of which is found: `review #<n>: no pull request of this
#       ticket was found`, and .vid/decide/review/none-step-<n> holds the commit, for the decision. A requirement none of whose tickets has
#       one is the script's own line; with no other to ask, the grade is recorded at once, `recorded <id>`. A ticket whose review is
#       recorded and not sorted: the second reviewer's brief again, `to-sort <k> <brief>`
#   show <id> [list <part>]     the list: each pull request with its ticket, its files and their counts, at most 20,000 characters a part
#   show <id> <pr> <path> [<part>]   that file's change, the same
#   record <id> <file>          the reviewer's lines, checked: a ticket's each row (each transition of a journey) once, one of kept, breached
#       product, breached test, unclear, with a reason; an ask's as results.sh reads one. `by: GR` and `commit:` are put here. Prints
#       `recorded <id>`, or `to-sort <k> <the second reviewer's brief>`: the lines that read breached or unclear, a known limit's aside
#   sorted <id> <file>          the second reviewer's lines, one for one, in their order. `by: SR` and `commit:` are put here. `recorded <id>`
#   due                         what waits, a line each: `review #<n> <c12>`, `review stage-<N> <c12>`, `review grade-<ask> <c12>`,
#       `to-sort <id> <k>`
# Records: .vid/decide/review/<report id>/ (saved): grade.txt and prs, or sorted.txt; github.sh own-refs makes each the report
# vid-results/<report id> of .vid/code: grade-step-<n>-<c12>-1, sort-step-<n>-<c12>-1, grade-<ask>-1.
# Usage: sh checks/review.sh prepare|show|record|sorted|due …
# serves: tickets
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
D=.vid/decide; RV=$D/review; RW=.vid/round/review; RD=.vid/round/read; LOG=.vid/tw/log; TAB=$(printf '\t'); MAX=20000
die() { echo "ViD review: $*" >&2; exit 1; }
usage() { echo 'usage: sh checks/review.sh prepare step-<n> <commit>|stage-<N>|<ask> | show <id> [list <part>] | show <id> <pr> <path> [<part>] | record <id> <file> | sorted <id> <file> | due' >&2; exit 2; }
[ -f .vid/RUN-STATE.md ] || { echo 'ViD review: run it at the top of ViD'"'"'s repository' >&2; exit 2; }
gh_() { sh "$HERE/github.sh" "$@"; }
G() { git --git-dir=.vid/code "$@"; }
tmp() { mkdir -p "$RW"; X=$(mktemp -d "$PWD/$RW/tmp.XXXXXX"); trap 'rm -rf "$X"' EXIT; }
# idok <id>: n and KIND: ticket (step-<n>-<c12>) or ask (ten digits); RID, its report's id
idok() { ID=$1; case $1 in step-[0-9]*-*) n=${1#step-}; n=${n%%-*}; KIND=ticket ;; *) KIND=ask; n=$1; ownask "$1" || die "no review $1: step-<n>-<c12>, or an ask's ten digits" ;; esac; case $1 in *[!a-z0-9-]*) die "no review $1" ;; esac; RID=grade-$ID-1; }
# ask_ <number>: an ask's record. AF its file, AB its body, AW stage|grade, AN the stage; 1 when there is none, or it is read or withdrawn
ak() { sed -n "s/^$1$TAB//p" "$AF" | head -n 1; }
ask_() { AF=''; case $1 in
    0900*) for f in "$D"/stage/*/*/s1ask; do [ -f "$f" ] && grep -qx "issue$TAB$1" "$f" && AF=$f; done; [ -n "$AF" ] || return 1; _k=${AF%/s1ask}; AB=$_k/s1body; AW=stage; AN=${_k%/*}; AN=${AN##*/}; [ ! -f "$_k/s1withdrawn" ] && [ ! -f "$_k/s1done" ] ;;
    *) [ -f "$D/grade/$1/ask" ] || return 1; AF=$D/grade/$1/ask; AB=$D/grade/$1/body; AW=grade; AN=''; [ ! -f "$D/grade/$1/withdrawn" ] && [ ! -f "$D/grade/$1/done" ] ;; esac; }
live_() { awk '$1 == "published" { p[$2] = 1 } $1 == "withdrawn" { delete p[$2] } END { for (n in p) print n }' "$LOG" 2>/dev/null | sort -n; }
# plist <commit> [<vs commit>]: $X/pl, the merged pull requests of the tickets in $X/t, `<p> TAB <ticket> TAB <merge> TAB c|vs|both`, by which
# of the two commits hold the merge: a unit's record (decide.sh umap), this call's read (a ticket line, a sub-issue's too), the merges
# recorded in GitHub auto, GitHub's closing references, and the list a ticket's own review kept; FB-5 B1.4: at the commit its ask names, the step's
# own pull request (pr-asks), merged or not
plist() { _r=$RD; [ -f "$_r" ] || _r=/dev/null; awk -F'\t' -v T="$X/t" 'BEGIN { while ((getline l < T) > 0) t[l] = 1 } $1 == "sub" && ($2 in t) { print $4 "\t" $2 }' "$_r" > "$X/sub"
  { cat "$X/t"; cut -f1 "$X/sub"; } | sort -un > "$X/num"; gh_ closing-prs $(cat "$X/num") > "$X/cl" 2> "$X/e" || die "$(tail -n 1 "$X/e")"
  # FB-5 B1.4: and, at the commit its ask names, a step's own pull request (pr-asks)
  { awk -F'\t' -v c="$1" '$3 == c { print $1 "\t" $2 "\t" $3 }' "$D/pr-asks" 2>/dev/null; sh "$HERE/decide.sh" umap 2>/dev/null | awk -F'\t' '{ print $1 "\t" $2 "\t" $4 }'; awk -F'\t' '$1 ~ /^[0-9]+$/ { print $1 "\t" $2 "\t" $4 }' "$D/merges" 2>/dev/null
    awk -F'\t' '$1 == "merged" { print $2 "\t" $3 "\t" $5 }' "$_r"; awk -F'\t' '{ print $2 "\t" $1 "\t" $3 }' "$X/cl"
    while read -r t; do cat "$RV/grade-step-$t-"*/prs 2>/dev/null | cut -f1-3; done < "$X/t"; } |
  awk -F'\t' -v T="$X/t" -v S="$X/sub" 'BEGIN { while ((getline l < T) > 0) t[l] = l; while ((getline l < S) > 0) { split(l, x, "\t"); t[x[1]] = x[2] } } ($2 in t) && $3 ~ /^[0-9a-f]+$/ && !s[$1]++ { print $1 "\t" t[$2] "\t" $3 }' | sort -n > "$X/pa"
  : > "$X/pl"; while IFS=$TAB read -r p t m; do a=''; ! G merge-base --is-ancestor "$m" "$1" 2>/dev/null || a=c; [ -z "${2:-}" ] || ! G merge-base --is-ancestor "$m" "$2" 2>/dev/null || { [ -n "$a" ] && a=both || a=vs; }; [ -z "$a" ] || printf '%s\t%s\t%s\t%s\n' "$p" "$t" "$m" "$a" >> "$X/pl"; done < "$X/pa"; }
# spec_ <folder>: the spec at the applied commit, ViD's own repository's
spec_() { _a=$(applied); [ -n "$_a" ] || die 'the applied commit is not recorded (.vid/tw/applied)'; git -c core.quotePath=false ls-tree -r --name-only "$_a" -- PRD.md INVENTORY.md DECISIONS.md BASELINE.md ARCHITECTURE.md STAGES.md GRADING-CHECKLIST.md design 2>/dev/null | while IFS= read -r f; do mkdir -p "$(dirname "$1/$f")"; git show "$_a:./$f" > "$1/$f"; done; }
# rows_ <ticket>: the ids its review grades: each row of its writing, each transition of a journey, a retired one aside
rows_() { awk -F'|' -v L="$LOG" -v n="$1" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN { while ((getline l < L) > 0) { k = split(l, w, " "); if ((w[1] == "published" || w[1] == "amended") && w[2] == n) { rt = ""; for (i = 3; i <= k; i++) if (w[i] ~ /^retired=/) rt = "," substr(w[i], 9) "," } } }
    /^## / { s = substr($0, 4); next }
    s == "Rows" && /^> / { a = tr(substr($1, 3)); id = (a ~ /^[A-Z]+-[0-9]/) ? a : tr($2); o[++m] = id; t = 0; p = index($0, "transitions:"); if (p) { r = " " substr($0, p + 12); while ((q = index(r, " " (t + 1) ". ")) > 0) { r = substr(r, q + 1); t++ } } N[id] = t; next }
    s == "Rows" && match($0, /^- [^ ]+ marks: retired;/) { split($0, w, " "); R[w[2]] = 1 }
    END { for (i = 1; i <= m; i++) { id = o[i]; if ((id in R) || index(rt, "," id ",")) continue; if (N[id]) for (j = 1; j <= N[id]; j++) print id "-T" j; else print id } }' ".vid/tw/out/issue-$1.md"; }
# sect <heading>…: those sections of the pass, whole
pass_() { _pr=${CLAUDE_PLUGIN_ROOT:-}; [ -n "$_pr" ] && [ -f "$_pr/skills/vid-accept-step/passes/review.md" ] || _pr=$(cd "$HERE/.." && pwd); PASS=$_pr/skills/vid-accept-step/passes/review.md; [ -f "$PASS" ] || die "the reviewer's pass is not found (set CLAUDE_PLUGIN_ROOT): no $PASS"; }
sect() { for _s in "$@"; do awk -v s="## $_s" '/^## / { p = ($0 == s) } p' "$PASS"; done; }
cases_() { sh "$HERE/results.sh" cases "$1" 2>/dev/null; }

cmd_prepare() { pass_
  case ${1:-} in
    step-*) [ $# -eq 2 ] || usage; n=${1#step-}; case $n in ''|*[!0-9]*) usage ;; esac; manual || die 'ViD reviews a ticket by itself in GitHub manual alone'; live_ | grep -qx "$n" || die "#$n: no published ticket that is not withdrawn"
      C=$(G rev-parse -q --verify "$2^{commit}" 2>/dev/null) || die "$2 is not in .vid/code (sh checks/github.sh results-fetch)"; KIND=ticket; ID=step-$n-$(printf %.12s "$C")
      # its review recorded: only the sort it still lacks is prepared again, from the record (a restored folder has no .vid/round/review)
      o=$(ls -d "$RV/grade-step-$n-"* 2>/dev/null | head -n 1); if [ -n "$o" ]; then RID=grade-$ID-1; k=0; [ "${o##*/}" = "$RID" ] && [ ! -d "$RV/sort-$ID-1" ] && { open_; k=$(grep -c . "$RW/$ID/to-sort.txt"); }
        [ "$k" != 0 ] || die "#$n is reviewed already: ${o##*/}"; cp ".vid/tw/out/issue-$n.md" "$RW/$ID/ticket.md"; cp "$RV/$RID/prs" "$RW/$ID/prs"; rm -rf "$RW/$ID/spec"; mkdir "$RW/$ID/spec"; spec_ "$RW/$ID/spec"; sortbrief; echo "to-sort $k $RW/$ID/sort-brief.md"; return 0; fi
      ! grep -qE '^- (kind: reached|follows: )' ".vid/tw/out/issue-$n.md" || die "#$n has no review: a reached ticket, or one that follows another"; tmp; echo "$n" > "$X/t"; VS='' ;;
    stage-*|[0-9]*) [ $# -eq 1 ] || usage; n=$1; case $1 in stage-*) n=''; for f in $(ls -d "$D/stage/${1#stage-}"/*/s1ask 2>/dev/null); do AF=$f; i=$(ak issue); ! ownask "$i" || ! ask_ "$i" || n=$i; done; [ -n "$n" ] || die "${1}: no grade of ViD's own is out" ;; esac
      idok "$n"; ask_ "$n" || die "$n: no grade ask of ViD's own that is out"; [ ! -d "$RV/$RID" ] || die "$n is recorded already: $RID"; C=$(ak commit); VS=$(ak vs); RQ=$(ak reqs); tmp ;;
    *) usage ;; esac
  [ -d .vid/code ] || die 'no .vid/code (sh checks/github.sh results-fetch)'; F=$X/d; mkdir -p "$F"; mkdir "$F/spec"; spec_ "$F/spec"
  if [ "$KIND" = ask ]; then   # the requirements, their rows ($X/rr) and the tickets holding those
    sed -n '/^```vid-inventory/,/^```$/p' "$F/spec/INVENTORY.md" | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      { a = tr($1); if (a ~ /^[A-Z]+-[0-9]/) { id = a; x = $7 } else { id = tr($2); if (id !~ /^[A-Z]+-[0-9]/) next; x = $0 } gsub(/[^A-Za-z0-9-]/, " ", x); n = split(x, t, " "); for (i = 1; i <= n; i++) if (t[i] ~ /^REQ-[0-9]+$/ && !s[id, t[i]]++) print t[i] "\t" id }' > "$X/rr"
    awk '($1 == "published" || $1 == "amended") { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) R[$2] = substr($i, 6) } $1 == "withdrawn" { delete R[$2] } END { for (t in R) { n = split(R[t], a, ","); for (i = 1; i <= n; i++) if (a[i] != "" && a[i] != "-") print a[i] "\t" t } }' "$LOG" 2>/dev/null > "$X/rt"
    awk -F'\t' 'FILENAME == ARGV[1] { T[$1] = T[$1] " " $2; next } ($2 in T) { n = split(T[$2], t, " "); for (i = 1; i <= n; i++) if (!s[$1, t[i]]++) print $1 "\t" t[i] }' "$X/rt" "$X/rr" > "$X/qt"
    printf '%s\n' $RQ | grep . > "$X/rq"; if [ -n "$(ak robustify)" ]; then live_ > "$X/t"; else awk -F'\t' 'FILENAME == ARGV[1] { Q[$1] = 1; next } ($1 in Q) { print $2 }' "$X/rq" "$X/qt" | sort -un > "$X/t"; fi; fi
  if [ -s "$X/t" ]; then plist "$C" "$VS"; else : > "$X/pl"; fi; cp "$X/pl" "$F/prs"
  if [ "$KIND" = ticket ]; then
    if [ ! -s "$X/pl" ]; then mkdir -p "$RV"; echo "$C" > "$X/no"; put "$RV/none-step-$n" < "$X/no" || exit 1; echo "review #$n: no pull request of this ticket was found"; return 0; fi
    rm -f "$RV/none-step-$n"; rm -rf "$RW/step-$n-"*; cp ".vid/tw/out/issue-$n.md" "$F/ticket.md"; rows_ "$n" > "$F/rows"; [ -s "$F/rows" ] || die "#$n holds no row to grade"
    sh "$HERE/results.sh" read --ticket "$n" --at "$C" > "$X/ev" 2> "$X/e" || die "#$n's results could not be read: $(tail -n 1 "$X/e")"
    # the cases at the commit that name a row of the ticket, from the reports that read counted
    sed -n 's/^report \(.* read\).*/\1/p' "$X/ev" | tr ' ' '\n' | sed 's/:$//' | awk '!s[$0]++' | grep -E '^[!#-~]+$' | grep -vE '^(red|grade|sort)-' | while read -r i; do G rev-parse -q --verify "refs/heads/vid-results/$i" > /dev/null 2>&1 || continue
      G ls-tree --name-only "refs/heads/vid-results/$i:$i" 2>/dev/null | grep '\.xml$' | while IFS= read -r f; do cases_ "refs/heads/vid-results/$i:$i/$f" | awk -F'\t' -v h="$i $f" '$1 == "c" { print h "\t" $2 "\t" $3 "\t" $4 }'; done; done > "$X/cs"
    awk -F'\t' 'function nm(s) { gsub(/[-_.]/, "-", s); return s } FILENAME == ARGV[1] { id = nm($1); sub(/-T[0-9]+$/, "", id); if (!s[id]++) B[++n] = id; next }
      { x = "-" nm($2) "-"; for (i = 1; i <= n; i++) if (match(x, "[^A-Za-z0-9]" B[i] "[^A-Za-z0-9]")) { print "- " $1 ": " $2 ": " $3 ($4 == "" ? "" : " — " $4); next } }' "$F/rows" "$X/cs" > "$X/cx"
    { printf '# ViD'"'"'s review of ticket #%s: your brief\n\n' "$n"; head_; sect 'Every form' 'The ticket form'
      printf '## The ticket\n\nIts whole writing: `%s/ticket.md`. The commit of main decided: %s.\n\nThe rows you grade, a line each:\n\n' "$RW/$ID" "$C"; sed 's/^/- /' "$F/rows"; printf '\n'; awk '/^## / { s = ($0 == "## Rows") } s && /^> /' "$F/ticket.md"
      printf '\n## The cases at the commit, by the rows'"'"' ids in their names\n\n'; if [ -s "$X/cx" ]; then cat "$X/cx"; else echo 'none'; fi; spec__; } > "$F/brief.md"
  else
    if [ -n "$(ak robustify)" ]; then : > "$F/unread"; [ -s "$X/pl" ] || die "$n: no pull request of any ticket was found: nothing to read"; else awk -F'\t' 'FILENAME == ARGV[1] { P[$2] = 1; next } FILENAME == ARGV[2] { if ($2 in P) R[$1] = 1; next } !($1 in R)' "$X/pl" "$X/qt" "$X/rq" > "$F/unread"; fi
    grep -vxFf "$F/unread" "$X/rq" > "$F/reqs" || :; rm -rf "${RW:?}/$ID"
    { if [ "$AW" = stage ]; then printf '# ViD'"'"'s grade of stage %s: your brief\n\n' "$AN"; else printf '# ViD'"'"'s grade, the owner'"'"'s ask %s: your brief\n\n' "$n"; fi; head_; sect 'Every form' 'The stage form'
      printf '## The ask, as it was made\n\n'; sed 's/^/> /' "$AB" 2>/dev/null; printf '\n## The requirements you grade\n\n'; [ -s "$F/reqs" ] || echo 'none: finding lines alone'
      sh "$HERE/prd.sh" --effective "$F/spec/PRD.md" > "$X/prd" 2>/dev/null || :; cat "$F/reqs" | while read -r r; do grep -E "^$r[ |]" "$X/prd" | head -n 1 | sed 's/^/> /' | grep . || echo "> $r |"
        awk -F'\t' -v r="$r" 'FILENAME == ARGV[1] { if ($1 == r) T[$2] = 1; next } ($2 in T) { o = o " #" $1 ($4 == "vs" ? " (at vs: alone)" : $4 == "both" ? " (at both)" : "") } END { print "  pull requests:" (o == "" ? " none" : o) }' "$X/qt" "$X/pl"
        awk -F'\t' -v r="$r" '$1 == r { print $2 }' "$X/rr" > "$X/ri"; sed -n '/^```vid-inventory/,/^```$/p' "$F/spec/INVENTORY.md" | awk -F'|' -v I="$X/ri" 'BEGIN { while ((getline l < I) > 0) W[l] = 1 } { a = $1; b = $2; gsub(/[ \t]/, "", a); gsub(/[ \t]/, "", b) } (a in W) || (b in W) { print "  > " $0 }'; done
      [ ! -s "$F/unread" ] || printf '\nNot yours, no pull request of their tickets could be found (ViD writes their lines): %s\n' "$(paste -sd ' ' "$F/unread")"; spec__; } > "$F/brief.md"; fi
  mv "$F" "$RW/$ID" || exit 1
  if [ "$KIND" = ask ] && [ ! -s "$RW/$ID/reqs" ] && [ -s "$RW/$ID/unread" ]; then : > "$RW/$ID/grade.txt"; cmd_record "$ID" "$RW/$ID/grade.txt"; return 0; fi
  echo "brief $ID $RW/$ID/brief.md"; }
head_() { printf 'The repository: `%s`. Your lines go in `%s`, and nowhere else.\n\n- `sh checks/review.sh show %s` lists the pull requests and their changed files; a long list, `sh checks/review.sh show %s list <part>`\n- `sh checks/review.sh show %s <pull request> <path>` shows that file'"'"'s change; a long one, a part number after it\n\n' "$PWD" "$RW/$ID/${1:-grade.txt}" "$ID" "$ID" "$ID"; }
spec__() { printf '\n## The spec\n\nViD'"'"'s own copy, as the team has it: `%s/spec/`. Read the items the rows and requirements above cite by id, GRADING-CHECKLIST.md whole where it is there, and search the rest when a row needs it.\n' "$RW/$ID"; }

# parts <part> <head>: stdin in parts of whole lines, each at most MAX characters, its heading, number and line ends counted (40 for the
# number's words); part's, under the head and its number. Exit 3: no such part
parts() { awk -v P="$1" -v H="$2" -v M="$MAX" 'BEGIN { M -= length(H) + 40 } function add(l) { if (z != "" && length(z) + length(l) + 1 > M) { A[++k] = z; z = "" } z = z l "\n" }
  { l = $0; while (length(l) > M - 1) { c = M - 1; while (c > 1 && substr(l, c + 1, 1) ~ /[\200-\277]/) c--; add(substr(l, 1, c)); l = substr(l, c + 1) } add(l) } END { if (z != "" || !k) A[++k] = z; if (P < 1 || P > k) exit 3; printf "%s, part %d of %d\n%s", H, P, k, A[P] }'; }
cmd_show() { [ $# -ge 1 ] || usage; idok "$1"; P=$RW/$ID/prs; [ -f "$P" ] || die "no review $ID is prepared here (sh checks/review.sh prepare)"; pt=1
  if [ $# -eq 1 ] || [ "$2" = list ]; then [ $# -le 3 ] || usage; pt=${3:-1}; case $pt in ''|*[!0-9]*) usage ;; esac; o=''; while IFS=$TAB read -r p t m a; do
      l=$(gh_ pr-files "$p") || exit 1; s=$(printf '%s\n' "$l" | awk -F'\t' -v p="$p" -v t="$t" -v a="$a" 'NF >= 6 { n++; x += $3; y += $4; L = L "  " $2 " " $1 ($5 == "-" ? "" : " (from " $5 ")") " +" $3 " -" $4 ($6 == "none" ? " — not shown by GitHub" : "") "\n" }
        END { printf "pull request #%s (ticket #%s) — %d files, +%d -%d%s\n%s", p, t, n, x, y, (a == "vs" ? ", at vs: alone" : a == "both" ? ", at the commit and at vs:" : ""), L; if (n >= 3000) print "  GitHub lists 3000 files of a pull request at most: the rest are not shown" }'); o="$o$s
"; done < "$P"
    printf '%s' "$o" | parts "$pt" "review $ID, $(grep -c . "$P") pull requests" || die "no part $pt"; return 0; fi
  [ $# -eq 3 ] || [ $# -eq 4 ] || usage; pt=${4:-1}; case $2$pt in *[!0-9]*) usage ;; esac
  grep -q "^$2$TAB" "$P" || die "pull request #$2 is not on review $ID's list"
  o=$(gh_ pr-files "$2" "$3") || exit 1; [ -n "$o" ] || die "#$2's change has no file $3"
  printf '%s\n' "$o" | awk -F'\t' 'NR == 1 { if ($5 == "none") { print "not shown by GitHub: it gives no change for this file (" $1 ($4 == "-" ? "" : " from " $4) ", +" $2 " -" $3 ")"; exit } next } { print }' | parts "$pt" "pull request #$2, $3 ($(printf '%s\n' "$o" | awk -F'\t' '{ print $1 ", +" $2 " -" $3; exit }'))" || die "no part $pt"; }

# keep <report id> <file name> <by> <commit> <lines>: the record, made whole, and its report
keep() { mkdir -p "$RV/$1"; { printf 'by: %s\ncommit: %s\n' "$3" "$4"; cat "$5"; } > "$X/k" || exit 1; put "$RV/$1/$2" < "$X/k" || exit 1; gh_ own-refs > "$X/e" 2>&1 || { unkeep "$1"; die "$(tail -n 1 "$X/e")"; }; }
unkeep() { rm -rf "${RV:?}/$1"; gh_ own-refs > /dev/null 2>&1 || :; }
commit_() { if [ "$KIND" = ticket ]; then G rev-parse -q --verify "${ID##*-}^{commit}" 2>/dev/null || die "${ID##*-} is not in .vid/code (sh checks/github.sh results-fetch)"; else ak commit; fi; }
lines_() { tr -d '\r' < "$1" | sed '/^by: /d; /^commit: /d; /^[[:space:]]*$/d'; }
cmd_record() { [ $# -eq 2 ] || usage; idok "$1"; W=$RW/$ID; [ -f "$W/brief.md" ] && [ -f "$W/prs" ] || die "no review $ID is prepared here (sh checks/review.sh prepare)"; [ -f "$2" ] || die "no file $2"; [ ! -d "$RV/$RID" ] || die "$ID is recorded already: $RID"
  if [ "$KIND" = ticket ]; then o=$(ls -d "$RV/grade-step-$n-"* 2>/dev/null | head -n 1); [ -z "$o" ] || die "#$n is reviewed already: ${o##*/}"; else ask_ "$ID" || die "$ID: the ask is read already, or withdrawn"; fi
  [ -n "${X:-}" ] || tmp; lines_ "$2" > "$X/l"; C=$(commit_) || exit 1
  if [ "$KIND" = ticket ]; then b=$(awk -v R="$W/rows" 'BEGIN { while ((getline l < R) > 0) { A[l] = 1; O[++n] = l } } function no(w) { print w; bad = 1; exit }
      /^finding: (bug|rule)( (high|medium|low))? — ./ { next } /^finding:/ { no("a finding not tagged bug or rule, its severity high, medium or low after it, then a dash: " substr($0, 1, 80)) }
      !($1 in A) { no("a line for no row asked: " substr($0, 1, 80)) } ($1 in S) { no($1 " is there twice") }
      !/^[^ ]+ (kept|breached product|breached test|unclear) — [^ ]/ { no($1 " has none of the four words with a reason after a dash (kept, breached product, breached test, unclear): " substr($0, 1, 80)) } { S[$1] = 1 }
      END { if (bad) exit; for (i = 1; i <= n; i++) if (!(O[i] in S)) { print O[i] " has no line"; exit } }' "$X/l"); [ -z "$b" ] || die "$ID not recorded: $b"
    # the second reviewer's brief is made before anything is saved: what it needs missing, nothing is recorded (FB-3 proof)
    open_ "$X/l"; k=$(grep -c . "$W/to-sort.txt"); [ "$k" = 0 ] || sortbrief
    keep "$RID" grade.txt GR "$C" "$X/l"; cp "$W/prs" "$RV/$RID/prs"; if [ "$k" = 0 ]; then echo "recorded $ID"; else echo "to-sort $k $W/sort-brief.md"; fi; return 0; fi
  b=$(awk -v U="$W/unread" 'BEGIN { while ((getline l < U) > 0) A[l] = 1 } ($1 in A) { print $1; exit }' "$X/l"); [ -z "$b" ] || die "$ID not recorded: $b is not asked of the reviewer (no pull request of its tickets was found)"
  while read -r r; do u='absent — unread: no pull request of its tickets could be found'; [ -z "$(ak vs)" ] && echo "$r $u" || echo "$r $u — vs: $u"; done < "$W/unread" >> "$X/l"
  keep "$RID" grade.txt GR "$C" "$X/l"; cp "$W/prs" "$RV/$RID/prs"
  # its form is S1's, read where every grade is: refused there, nothing is kept
  if [ "$AW" = stage ]; then set -- --stage "$AN"; else set -- --ask "$ID"; fi; sh "$HERE/results.sh" grade "$@" > "$X/g" 2> "$X/e" || { unkeep "$RID"; die "$ID not recorded: $(tail -n 1 "$X/e")"; }
  [ "$(head -n 1 "$X/g" | cut -f2)" = read ] || { unkeep "$RID"; die "$ID not recorded: $(head -n 1 "$X/g" | cut -f4-)"; }
  echo "recorded $ID"; }
# open_ [<file>]: to-sort.txt, the lines of the ticket's record (or of the file, not recorded yet) that read breached or unclear, but a row's whose newest ruling is a known limit
open_() { mkdir -p "$RW/$ID"; awk -F'\t' 'FILENAME == ARGV[1] { U[$2] = $3; next } { split($0, w, " ") } $0 ~ /^[^ ]+ (breached|unclear)/ && U[w[1]] != "limit"' "$([ -f "$D/rulings" ] && echo "$D/rulings" || echo /dev/null)" "${1:-$RV/$RID/grade.txt}" > "$RW/$ID/to-sort.txt"; }
sortbrief() { pass_; { printf '# ViD'"'"'s review of ticket #%s: the second reviewer'"'"'s brief\n\n' "$n"; head_ sorted.txt; sect 'Every form' 'The second reviewer'; printf '## The lines to sort\n\n'; cat "$RW/$ID/to-sort.txt"; printf '\n## The ticket\n\nIts whole writing: `%s/ticket.md`.\n' "$RW/$ID"; spec__; } > "$RW/$ID/sort-brief.md"; }
cmd_sorted() { [ $# -eq 2 ] || usage; idok "$1"; [ "$KIND" = ticket ] && [ -f "$RV/$RID/grade.txt" ] || die "$ID: no ticket's review is recorded under it"; [ -f "$2" ] || die "no file $2"; S=sort-$ID-1; [ ! -d "$RV/$S" ] || die "$ID is sorted already: $S"
  tmp; open_; lines_ "$2" > "$X/l"; C=$(commit_) || exit 1
  b=$(awk -v T="$RW/$ID/to-sort.txt" 'BEGIN { while ((getline l < T) > 0) L[++n] = l; D = " — " } bad { next }
    NR > n { print "a line more than the " n " to sort: " substr($0, 1, 80); bad = 1; next }
    { g = L[NR]; r = g; sub(/ .*/, "", r); if ($1 != r) { print "line " NR " is not " r "\047s, the line in its place"; bad = 1; next }
      if (!match($0, /^[^ ]+ (test it|note it|drop it|prove it real) — /)) { print r " has none of the four words (test it, note it, prove it real, drop it)"; bad = 1; next }
      x = substr($0, RLENGTH + 1); e = D g; p = length(x) - length(e); if (p < 1 || substr(x, p + 1) != e) { print r " does not end in its reason, a dash and the grade line word for word"; bad = 1 } }
    END { if (!bad && NR < n) print (n - NR) " of the " n " lines are not there" }' "$X/l"); [ -z "$b" ] || die "$ID not sorted: $b"
  keep "$S" sorted.txt SR "$C" "$X/l"; echo "recorded $ID"; }
cmd_due() { for f in $(ls -d "$D"/stage/*/*/s1ask 2>/dev/null); do AF=$f; i=$(ak issue); ownask "$i" && ask_ "$i" && [ ! -d "$RV/grade-$i-1" ] && echo "review stage-$AN $(ak commit | cut -c1-12)"; done
  for i in $(ls "$D/grade" 2>/dev/null | grep -E '^[0-9]+$'); do ownask "$i" && ask_ "$i" && [ ! -d "$RV/grade-$i-1" ] && echo "review grade-$i $(ak commit | cut -c1-12)"; done
  manual || return 0   # a ticket's review is GitHub manual's alone; an own ask on record is made in either mode
  # a ticket's: prepared and not recorded, no pull request found, or its newest decision lacking the review
  { ls -d "$RW"/step-*/brief.md 2>/dev/null | sed 's|/brief.md$||; s|.*/step-||; s|-| |'; for f in $(ls "$RV"/none-step-* 2>/dev/null); do echo "${f##*none-step-} $(cut -c1-12 "$f")"; done
    for f in $(ls "$D"/last-step-* 2>/dev/null); do t=${f##*last-step-}; c=$(head -n 1 "$f" | cut -c1-12); ! grep -q '^review missing' "$D/step-$t-$c.txt" 2>/dev/null || echo "$t $c"; done; } | awk '!s[$1]++' | while read -r t c; do ls -d "$RV/grade-step-$t-"* > /dev/null 2>&1 || ! live_ | grep -qx "$t" || echo "review #$t $c"; done
  for d in $(ls -d "$RV"/grade-step-*-1 2>/dev/null); do ID=${d##*/grade-}; ID=${ID%-1}; RID=grade-$ID-1; [ ! -d "$RV/sort-$ID-1" ] || continue
    k=$(awk -F'\t' 'FILENAME == ARGV[1] { U[$2] = $3; next } { split($0, w, " ") } $0 ~ /^[^ ]+ (breached|unclear)/ && U[w[1]] != "limit" { k++ } END { print k + 0 }' "$([ -f "$D/rulings" ] && echo "$D/rulings" || echo /dev/null)" "$d/grade.txt"); [ "$k" = 0 ] || echo "to-sort $ID $k"; done; return 0; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in prepare) cmd_prepare "$@" ;; show) cmd_show "$@" ;; record) cmd_record "$@" ;; sorted) cmd_sorted "$@" ;; due) [ $# -eq 0 ] || usage; cmd_due ;; *) usage ;; esac
