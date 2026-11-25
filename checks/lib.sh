#!/bin/sh
# Purpose: the ticket side's shared helpers (0.26.10.28.4, 9.3 R3, R4, M3, M4), each once: put, the settings reader, the plan-block reader, the
# row-range expander, date to seconds, the timestamp, the answers not given by the owner (0.26.10.29.5, DP-1 R4), the event writer and the lock. Each of the 13 ticket scripts, and decisions.sh, loads it from
# beside itself, `. "$HERE/lib.sh"`, after setting HERE; loaded, it defines these, sets one trap (mustread's, below) and runs nothing else. plan.sh
# and develop's own scripts keep their own.
# serves: tickets
# mvr <from> <to> (0.26.11.1.4, R6): the rename tried up to 5 times, 1 s apart, since a synced folder may refuse one for a moment; if every try fails,
# non-zero, with the source and the target as they were. No copy fallback: a record copied over would be seen half written
mvr() { _mn=1; until mv -f "$1" "$2"; do [ "$_mn" -lt 5 ] || return 1; _mn=$((_mn + 1)); sleep 1; done; }
# put <file>: stdin into a dot file beside it, then renamed in through mvr, so a record is replaced whole and never emptied first (0.26.10.28.1, F3)
put() { _p=$(dirname "$1")/.put.$$.$(basename "$1"); cat > "$_p" && mvr "$_p" "$1"; }
# skey <key>: .vid/tw/settings' value of `<key>:`, its trailing space trimmed; twkey, the same
skey() { sed -n "s/^$1:[[:space:]]*//p" .vid/tw/settings 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//'; }
twkey() { skey "$1"; }
# ghmode (GitHub manual, GM-1 S1): the GitHub mode, the owner's newest `setup-answered key=github-mode` line of .vid/plan/setup:
# auto, team (FB-1 C1: retired, an old project's answer, which connect.sh start refuses) or manual; none with no answer (a `github-mode:` line written by hand is no answer). manual: in GitHub manual, or in
# a call /vid mode marks as its own switch to or re-take of GitHub manual (VID_CALLER=mode), which reads under manual's rules
# before the mode is recorded; never in /vid mode's switch to GitHub auto (GM-4 F13, VID_CALLER=mode-auto), which reads under
# auto's rules before the mode is recorded. Every script asks these, never the setup or the caller mark itself (GM-4 F10)
ghmode() { _gm=$(sed -n 's/^setup-answered key=github-mode value="\([a-z]*\)".*/\1/p' .vid/plan/setup 2>/dev/null | tail -n 1); case $_gm in auto|team|manual) echo "$_gm" ;; *) echo none ;; esac; }
# FB-3 A1.6: ownask <n>, an ask number of ViD's own, ten digits beginning with 0 (a stage's grade 0900<N><c>, an owner's grade ask 091<k>, in
# GitHub manual): no issue on GitHub has it, by text or by value
ownask() { case ${1:-} in 0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) return 0 ;; esac; return 1; }
manual() { case ${VID_CALLER:-} in mode) return 0 ;; mode-auto) return 1 ;; esac; [ "$(ghmode)" = manual ]; }
# onrec (FB-3 C3): the tickets on ViD's record, one number a line: each .vid/tw/log publishes and does not withdraw, whatever its
# labels on GitHub. A ticket is one of these or an issue labelled <prefix>ticket, in every reader, both modes
onrec() { awk '$1 == "published" && $2 ~ /^[0-9]+$/ { P[$2] = 1 } $1 == "withdrawn" { delete P[$2] } END { for (n in P) print n }' .vid/tw/log 2>/dev/null | sort -n; }
# applied (GM-4 F8): the commit the team has, one line, the one reader of it: in GitHub manual the first line of .vid/tw/applied
# (GM M3: every change reaches the team only through the apply), nothing when none is recorded; in every other mode HEAD, where every
# commit of ViD's is exported as it is made, so no record is kept there. A reader that must know there is no recorded version in
# GitHub manual checks manual and an empty applied
applied() { if manual; then sed -n '1s/[[:space:]]*$//p' .vid/tw/applied 2>/dev/null; else git rev-parse -q --verify HEAD 2>/dev/null; fi; }
# FB-4 B1: which commit's spec the code repository's folder holds, in GitHub manual with layout: one, from the read github.sh spec-folder
# keeps, .vid/round/folder (its first line `main TAB <main's commit> TAB <repo> TAB <path>`, then `<blob id> TAB <path from the folder>`),
# names and ids alone. folderpath: the setup's spec-path:, docs/specs while missing. folderis [<commit>]: one line, `is <commit> …`,
# `none` or `absent` (no PRD.md at the folder's top, or no folder); nothing in another mode or layout, with no read kept or one of
# another folder. Of the seven spec files at the folder's top, those it holds: every commit HEAD reaches, newest first, and <commit> (the
# applied one when not given), at which each has that blob; a commit an export line of .vid/tw/log names by from=, whose copy in
# .vid/spec.git has those blobs (the export's blanked words), counts, and each commit with the same files as it. Whatever else the folder holds is never compared
folderpath() { _fd=$(skey spec-path); _fd=${_fd:-docs/specs}; printf '%s\n' "${_fd%/}"; }
folderis() { manual && [ "$(skey layout)" = one ] && [ -s .vid/round/folder ] && [ "$(sed -n 1p .vid/round/folder | cut -f4)" = "$(folderpath)" ] || return 0
  _fi=$(awk -F'\t' 'NR > 1 && $2 ~ /^(PRD|DECISIONS|BASELINE|ARCHITECTURE|GRADING-CHECKLIST|INVENTORY|STAGES)\.md$/ { print $2 "=" $1 }' .vid/round/folder | paste -sd ' ' -)
  case " $_fi" in *' PRD.md='*) ;; *) echo absent; return 0 ;; esac
  _fq='function ask(n,   i, a, f) { n = split(W, a, " "); for (i = 1; i <= n; i++) { f = a[i]; sub(/=.*/, "", f); print $1 ":" f, f, $1 ($2 == "" ? "" : " " $2) } }'
  { { git rev-list --topo-order HEAD; [ -z "${1-$(applied)}" ] || git rev-parse -q --verify "${1-$(applied)}^{commit}"; } 2>/dev/null | awk -v W="$_fi" "$_fq"' { ask() }' | git cat-file --batch-check='%(objectname) %(rest)' | sed 's/^/C /'
    [ ! -d .vid/spec.git ] || awk '$1 == "export" { for (i = 3; i <= NF; i++) if ($i ~ /^from=/ && !U[$2, $i]++) print $2, substr($i, 6) }' .vid/tw/log 2>/dev/null | awk -v W="$_fi" "$_fq"' { ask() }' |
      git --git-dir=.vid/spec.git cat-file --batch-check='%(objectname) %(rest)' 2>/dev/null | sed 's/^/X /'
  } | awk -v W="$_fi" 'BEGIN { n = split(W, a, " "); for (i = 1; i <= n; i++) { F[i] = a[i]; sub(/=.*/, "", F[i]); B[F[i]] = a[i]; sub(/.*=/, "", B[F[i]]); S = S " " B[F[i]] } OK[S] = 1 }
    $1 == "C" && NF == 4 { if (!($4 in K)) { K[$4] = 1; O[++k] = $4 } I[$4, $3] = $2 }
    $1 == "X" && NF == 5 && B[$3] == $2 && ++N[$4, $5] == n { E[$5] = 1 }
    function sig(c,   i, s) { s = ""; for (i = 1; i <= n; i++) s = s " " I[c, F[i]]; return s }
    END { for (c in E) if (c in K) OK[sig(c)] = 1; r = ""; for (i = 1; i <= k; i++) if (sig(O[i]) in OK) r = r " " O[i]; print (r == "" ? "none" : "is" r) }'; }
# foldersay [<commit>]: what folderis says, in words, `<holds|differs|is|none|absent> TAB <words>`, the folder first: holds, the commit (the
# applied one when not given) is of them, or is a take-over commit (kept under refs/vid/applied/) made on one of them; differs, it is not; is, no commit to compare with
foldersay() { _fc=${1-$(applied)}; _fr=$(folderis "$_fc"); _fp=$(folderpath); [ -z "$_fc" ] || _fc=$(git rev-parse -q --verify "$_fc^{commit}" 2>/dev/null) || _fc=''
  case $_fr in '') return 0 ;;
    none) printf "none\t%s on main holds no one commit's spec: its files are of more than one commit, or changed there\n" "$_fp"; return 0 ;;
    absent) printf 'absent\t%s is not on main, or holds no PRD.md there: if the team reads the spec in another folder, sh checks/planner.sh setup spec-path <folder> --words "<their words>" names it\n' "$_fp"; return 0 ;; esac
  _fr=${_fr#is }; _fn=$(printf %.12s "$_fr"); _fw="the spec of $_fn"; [ "${_fr##* }" = "$_fr" ] || _fw="the spec of $_fn (the newest of $(echo "$_fr" | wc -w | tr -d ' ') commits with the same files, the oldest $(printf %.12s "${_fr##* }"))"
  _ft=''; if [ -n "$_fc" ] && git for-each-ref --format='%(objectname)' refs/vid/applied/ 2>/dev/null | grep -qx "$_fc"; then _ft=$(git rev-parse -q --verify "$_fc^1" 2>/dev/null) || _ft=''; fi
  case " $_fr " in *" ${_fc:--} "*|*" ${_ft:--} "*) printf 'holds\t%s on main holds the spec of the applied version, %.12s\n' "$_fp" "$_fc"; return 0 ;; esac
  if [ -n "$_fc" ]; then printf 'differs\t%s on main holds %s, not of the applied version %.12s: if the published tickets were written from that one, /vid mode manual --applied %s is the answer\n' "$_fp" "$_fw" "$_fc" "$_fn"
  else printf 'is\t%s on main holds %s: if the published tickets were written from it, --applied %s names it\n' "$_fp" "$_fw" "$_fn"; fi; }
# engnone (FB-3 E2): no engines line on the handed record; ENGASK, the line that says so, with its command (both modes)
engnone() { [ -z "$(sed -n 's/^engines \(.*\) | stand-in.*/\1/p' .vid/tw/handed 2>/dev/null | tail -n 1)" ]; }
ENGASK='engines not named — /vid:vid-accept-step engines "<primary> <other>…" "<words>"'
# plan_block [<RUN-STATE>]: the vid-plan block's lines under "## The plan", strict fence, trailing space trimmed: plan.sh's `block`, whose hash is the plan's
plan_block() { [ -f "${1:-.vid/RUN-STATE.md}" ] || return 0; awk '/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b { print }' "${1:-.vid/RUN-STATE.md}" | sed 's/[[:space:]]*$//'; }
# specfiles (FB-7 D2): the spec's files, the one list: the ticket writer's gate, and a refused recording of decisions, which waits for them
specfiles() { printf '%s\n' PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md DECISIONS.md BASELINE.md CLAUDE.md design
  sed -n 's/.*|[[:space:]]*golden:[[:space:]]*\([^ |]*\).*/\1/p' INVENTORY.md 2>/dev/null | sort -u; }
# rkey: the round's refusal key: the plan block, the handed record and the newest tw-sync's main (0.26.10.28.2, R4), so a refusal is tried again once one
# changes; round.sh's refusals and queue.sh's count of the steps waiting read the one key
rkey() { { plan_block; cat .vid/tw/handed 2>/dev/null; sed -n 's/^sync main=\([^ ]*\) .*/\1/p' .vid/tw/log 2>/dev/null | tail -n 1; } | cksum | tr -d ' '; }
# stkey (low-1, R3): the stage key, for a start refused for its stage, which waits for its stage and never for main: the plan block, the handed
# record's candidate, staged and setup-hold lines without their labels (FB-8 E1), the six files of planner.sh's hash and RUN-STATE's stage: and
# held-after: lines, all the stage admission reads
stkey() { { plan_block; grep -E '^(candidate|staged|setup-hold)[[:space:]]' .vid/tw/handed 2>/dev/null | sed 's/[[:space:]]*|[[:space:]]*stand-in.*$//'; for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md; do printf '== %s\n' "$f"; cat "$f" 2>/dev/null; done
  grep -E '^(stage|held-after):' .vid/RUN-STATE.md 2>/dev/null; } | cksum | tr -d ' '; }
# RNG: the awk function rng(<id or range>), its ids space-separated: <P>-<a>..<P>-<b> written out at a's width, as the plan reads it; prepended to an awk program
RNG='function rng(y,   a, b, p, lo, hi, w, k, r) { if (y !~ /\.\./) return y; a = y; sub(/\.\..*/, "", a); b = y; sub(/.*\.\./, "", b); p = a; sub(/-[0-9]+$/, "", p)
  lo = a; sub(/^.*-/, "", lo); hi = b; sub(/^.*-/, "", hi); w = length(lo); r = ""; for (k = lo + 0; k <= hi + 0; k++) r = r (r == "" ? "" : " ") sprintf("%s-%0" w "d", p, k); return r }'
# PROF (0.26.11.1.2, R7): the word check, awk functions prepended to a program, the one list: profw(<word>), a word of the list; prof(<line>),
# its first such word, lower case, or ""; profx(<line>), the line with each such word (a run of letters, digits and _) written "(a word)", every other
# character as it was. The writer refuses or blanks by it; the spec export (github.sh exptree) blanks by it and refuses nothing
PROF='function profw(w) { return tolower(w) ~ /^(f+u+c+k[a-z0-9_]*|shit[a-z0-9_]*|bullshit[a-z0-9_]*|damn[a-z0-9_]*|goddam[a-z0-9_]*|crap[a-z0-9_]*|bitch[a-z0-9_]*|bastard[a-z0-9_]*|asshole[a-z0-9_]*|arsehole[a-z0-9_]*|piss[a-z0-9_]*|cunt[a-z0-9_]*|dick(head)?s?|wtf|motherf[a-z0-9_]*|bloody|bollocks)$/ }
  function prof(l,   n, w, i) { n = split(tolower(l), w, /[^a-z0-9_]+/); for (i = 1; i <= n; i++) if (profw(w[i])) return w[i]; return "" }
  function profx(l,   r, w) { r = ""; while (match(l, /[A-Za-z0-9_]+/)) { w = substr(l, RSTART, RLENGTH); r = r substr(l, 1, RSTART - 1) (profw(w) ? "(a word)" : w); l = substr(l, RSTART + RLENGTH) } return r l }'
# BLKL (FB-5 B1.1): the awk function blkl(<an issue's labels, comma-joined>, <the labels' prefix>), those of them that say a question stops it: the
# prefix's `blocked`, and any label that ends `:blocked`, comma-joined, "" with none; prepended to an awk program, the one reading of it in both
# modes. blkl <labels> <prefix>, the same from the shell
BLKL='function blkl(s, px,   a, i, n, r) { n = split(s, a, ","); r = ""; for (i = 1; i <= n; i++) if (a[i] == px "blocked" || a[i] ~ /:blocked$/) r = r (r == "" ? "" : ",") a[i]; return r }'
blkl() { printf '%s\n' "$1" | awk -v px="$2" "$BLKL"'{ print blkl($0, px) }'; }
# ASKF (FB-5 B1.3): the awk function askd(<the first lines of an issue's or a pull request's comments, as the read holds them>): AK its newest `vid:
# decide <7 to 40 characters of a commit>`, a CR at the line's end dropped (@tsv writes it as two characters), AKD 1 when a `vid: decision
# <it…>` follows; 0 with no ask. The one reading of an ask
ASKF='function askd(h,   c, n, i, y, k) { n = split(h, c, "\001"); AK = ""; AKD = 0; k = 0
    for (i = 1; i <= n; i++) { y = c[i]; if (y !~ /^vid: decide [0-9a-f]/) continue; sub(/(\\r|\r|[ \t])*$/, "", y); sub(/^vid: decide /, "", y); if (y ~ /^[0-9a-f]+$/ && length(y) >= 7 && length(y) <= 40) { AK = y; k = i } }
    if (AK == "") return 0; for (i = k + 1; i <= n; i++) if (index(c[i], "vid: decision " AK) == 1) AKD = 1; return 1 }'
# askall_ <read> (GM-4 E1, FB-5 B1.4, GitHub manual): the newest ask of each place a ticket is asked at, `<n> TAB <its commit, as it is asked> TAB <- or
# the pull request> TAB <1 answered, or 0> TAB <- or its head>`: the issue of a published ticket not withdrawn, and each pull request whose
# ticket line is such a ticket, an open one, or a merged one this read is the first to show (in neither unit-merges nor merged-prs) or that
# stands in pr-asks; an ask that begins its head is that head, full; and an ask of pr-asks at the head unit-merges has of its pull request, no
# decision posted there, though the read's list of merged ones shows it no more. tasks_ <read>: those owed an answer, a pull request's at its head
# alone, `<n> TAB <commit> TAB <- or the pull request>`
askall_() { [ -f "$1" ] || return 0; awk -F'\t' "$ASKF"'BEGIN { OFS = "\t"; while ((getline l < ".vid/tw/log") > 0) { split(l, x, " "); if (x[1] == "published") P[x[2]] = 1; else if (x[1] == "withdrawn") delete P[x[2]] }
      while ((getline l < ".vid/decide/merged-prs") > 0) M[l] = 1; while ((getline l < ".vid/decide/unit-merges") > 0) { split(l, x, "\t"); M[x[1]] = 1 } while ((getline l < ".vid/decide/pr-asks") > 0) { split(l, x, "\t"); delete M[x[1]] } }
    $1 == "issue" && ($2 in P) { if (askd($4)) print $2, AK, "-", AKD, "-"; next }
    ($1 == "open" || ($1 == "merged" && !($2 in M))) && ($3 in P) { if (askd($1 == "open" ? $10 : $6)) print $3, (index($4, AK) == 1 ? $4 : AK), $2, AKD, $4 }
    $1 == "open" || $1 == "merged" { SN[$2] = 1 }
    END { close(".vid/decide/unit-merges"); while ((getline l < ".vid/decide/unit-merges") > 0) { split(l, x, "\t"); UH[x[1]] = x[3] } close(".vid/decide/pr-asks"); while ((getline l < ".vid/decide/pr-asks") > 0) { split(l, x, "\t"); if ((x[1] in SN) || !(x[2] in P) || UH[x[1]] != x[3]) continue
        f = ".vid/decide/posted-step-" x[2] "-" substr(x[3], 1, 12); if ((getline y < f) >= 0) { close(f); continue } print x[2], x[3], x[1], 0, x[3] } }' "$1"; }
tasks_() { askall_ "$1" | awk -F'\t' '$4 == 0 && ($3 == "-" || $2 == $5) { print $1 "\t" $2 "\t" $3 }'; }
# FB-6 A1: gclosed <n>, the call's read holds ticket n as closed on GitHub; CLOSEDL, the last line of a `not yet` posted on such a ticket
gclosed() { awk -F'\t' -v n="$1" '$1 == "ticket" && $2 == n && $3 == "CLOSED" { f = 1 } END { exit !f }' .vid/round/read 2>/dev/null; }
# gclosedl: those tickets, for the readers that count open tickets (FB-6 A1.2: an `issue` line does not make one open)
gclosedl() { awk -F'\t' '$1 == "ticket" && $3 == "CLOSED" { printf " %s", $2 } END { print " " }' .vid/round/read 2>/dev/null || echo ' '; }
CLOSEDL='this ticket is closed on GitHub and not accepted: ask again here'
# FB-6 A2.1: hitf, the awk functions a test's name is matched to an id by, one text for every reader: norm(s), `-`, `_` and `.` one character; hit(<a
# normed name>, <id>), the id in it with neither a letter nor a digit right before or after. In GitHub manual the id's first dash may be left out (ROW012)
hitf() { printf '%s\n' 'function norm(s) { gsub(/[-_.]/, "-", s); return s }
  function hit1(n, id,   o, p, a, b, s) { o = 1
    while ((p = index(substr(n, o), id)) > 0) { a = o + p - 1; b = (a > 1) ? substr(n, a - 1, 1) : ""; s = substr(n, a + length(id), 1); if (b !~ /[A-Za-z0-9]/ && s !~ /[A-Za-z0-9]/) return 1; o = a + 1 } return 0 }'
  if manual; then printf '%s\n' '  function hit(n, id,   x) { x = id = norm(id); return (hit1(n, id) || (sub(/-/, "", x) && hit1(n, x))) ? 1 : 0 }'
  else printf '%s\n' '  function hit(n, id) { return hit1(n, norm(id)) }'; fi; }
# epoch <UTC ISO time>: its seconds, BSD's date or GNU's, else 0
epoch() { date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0; }
# stamp, now: the UTC time, ISO
stamp() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
now() { stamp; }
# prog on|now|stop|parts|done [<words>…] (FB-3 D2): the progress of a long call, beside the chat (checks/face.sh wait …); it prints
# nothing and never fails the call
prog() { sh "$HERE/face.sh" wait "$@" > /dev/null 2>&1 || :; }
# pneed <what it needs> (FB-3 D2): a call's running part stopped, where the call named its parts; with none named, nothing is written
pneed() { ! grep -q "^part$(printf '\t')" .vid/face/wait 2> /dev/null || prog stop "$1"; }
# notowner (0.26.10.29.5, DP-1 R4): the answers not given by the owner, `<when>\t<key>\t<value>\t<words>\t<by>` a line, from two records
# with no overlap: the queue's answers (.vid/decide/queue/answers) whose by is not owner, its held rows apart (their rulings are the
# record) and control:hold apart (the hold's second record of one continue); and each held-row ruling (.vid/decide/rulings) whose who
# is not owner, decide (a later head's undo) or SP (a landing's reset), keyed held:<row>, its words the ruling's word and words. A line
# with no who is the owner's, the default. The stage facts (close.sh), the completion report (end.sh) and the status (queue.sh) read
# this one set
notowner() { { sed 's/^/A	/' .vid/decide/queue/answers 2>/dev/null; sed 's/^/R	/' .vid/decide/rulings 2>/dev/null; } | awk -F'\t' 'BEGIN { OFS = "\t" }
    $1 == "A" && $6 != "" && $6 != "owner" && $3 !~ /^held:/ && $3 != "control:hold" { print $2, $3, $4, $5, $6 }
    $1 == "R" && $6 != "" && $6 !~ /^(owner|decide|SP)$/ { print $2, "held:" $3, $4, ($5 == "" ? $4 : $4 ": " $5), $6 }'; }
# lread <file> planner|stages <args…> (0.26.11.1.2, R6): `sh "$HERE/<planner|stages>.sh" <args…>`, the plan's rows or the stage scope,
# into <file> whole. A failed read is never an empty list: it prints `ViD <script>: refused — the plan's rows cannot be read (checks/planner.sh
# rows): <its first error line>` (the stage scope's alike) and returns 1. mustread: the same, then the script stops, exit 1, from inside a $(…)
# or a pipe too: its USR1 reaches the script's own shell, whose trap exits 1 (a subshell's exit alone would leave the script going on)
lread() { _lf=$1; _lx=$2; shift 2; if sh "$HERE/$_lx.sh" "$@" > "$_lf" 2> "$_lf.err"; then rm -f "$_lf.err"; return 0; fi
  case $_lx in planner) _lw="the plan's rows" ;; *) _lw='the stage scope' ;; esac; _le=$(grep -v '^[[:space:]]*$' "$_lf.err" 2>/dev/null | head -n 1)
  _la=$(printf ' %s' "$@"); echo "ViD $(basename "$0" .sh): refused — $_lw cannot be read (checks/$_lx.sh$_la): ${_le:-it failed with no message}" >&2; rm -f "$_lf" "$_lf.err"; return 1; }
mustread() { lread "$@" || { kill -s USR1 $$ 2>/dev/null; exit 1; }; }
trap 'exit 1' USR1
# ev <event line>: through the event.sh beside this file, at the run's home; a failure of event.sh is reported, never written past (9.3 R1, M1)
ev() { sh "$HERE/event.sh" "$1" > /dev/null || echo "ViD: the event was not recorded, event.sh failed: $1" >&2; }
# The lock (9.3 R4, M4): a folder naming its holder in one file, h, written whole and renamed in: `<pid> <start>`, its start as DevAgent's run.sh
# stamp writes one (/proc where it is: boot id and ticks, Git Bash seconds; else ps), so a reader never takes one holder's pid with another's start. A
# holder that is gone, or whose pid another process now has, is no holder: its lock is taken over by one waiter at a time (<folder>.steal), which reads
# h again before it removes anything. A live holder's lock is never taken: lock_take waits for it
# Stated limit (K-1): a clearer killed inside its guard leaves one moment with no release; portable shell has no atomic compare-and-remove to close it
pstamp() { if [ -r "/proc/$1/stat" ]; then _t=$(sed 's/^.*) //' "/proc/$1/stat" | cut -d' ' -f20); case $(uname -s) in MINGW*|MSYS*|CYGWIN*) _b=$(sed -n 's/^btime //p' /proc/stat 2>/dev/null); echo $((${_b:-0} + _t / $(getconf CLK_TCK))) ;; *) echo "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null):$_t" ;; esac; else LC_ALL=C TZ=UTC0 ps -o lstart= -p "$1" 2>/dev/null; fi; }   # one locale and one time zone for every reader
# palive <pid> <start>: it lives and is the process that start names (under Git Bash, within the second the two round to)
palive() { kill -0 "$1" 2>/dev/null || return 1; _s=$(pstamp "$1"); [ -n "$_s" ] || return 1; [ "$_s" = "$2" ] && return 0
  case $(uname -s) in MINGW*|MSYS*|CYGWIN*) case $2$_s in *[!0-9-]*) return 1 ;; esac; [ $((_s - $2)) -ge -1 ] && [ $((_s - $2)) -le 1 ] ;; *) return 1 ;; esac; }
# FB-5 C2: pubwords <read>, what stands on each of the read's publish pull requests, `<n> TAB <words>`, GitHub's state alone deciding: a
# standing request for changes first, then an approval, then a comment since the last push or answer, else an approval waited for; then
# what others said since, newest first
pubwords() { awk -F'\t' 'function j(s, x) { return s == "" ? x : s "; " x }
  $1 != "publish" { next } !($2 in K) { K[$2] = 1; O[++k] = $2 } $3 == "unread" { U[$2] = 1 }
  $3 == "state" && $5 == "CHANGES_REQUESTED" && $7 == "after" { A[$2] = j(A[$2], $4 " asks for changes") }
  $3 == "state" && $5 == "CHANGES_REQUESTED" && $7 != "after" { B[$2] = j(B[$2], "changed since " $4 " asked; waits for them to look again") }
  $3 == "state" && $5 == "APPROVED" { P[$2] = j(P[$2], $4 " approved") }
  $3 == "said" { if (!(($2, $4) in G)) { G[$2, $4] = 1; C[$2] = j(C[$2], $4 " commented") } S[$2] = S[$2] " · " $4 ", " $5 ": " ($6 == "" ? "(no words of its own)" : $6) }
  END { for (i = 1; i <= k; i++) { n = O[i]; w = A[n]; if (B[n] != "") w = j(w, B[n]); if (w == "") w = P[n]; if (w == "") w = C[n]; if (w == "") w = "waits for an approval"
    print n "\t" ((n in U) ? "its reviews could not be read" : w S[n]) } }' "$1" 2>/dev/null; }
lage() { [ -n "$(find "$1" -prune -mmin +1 2>/dev/null)" ]; }
# lheld <folder>: a live holder holds it, or one is still naming itself (a lock younger than a minute with no h yet)
lheld() { [ -d "$1" ] || return 1; _hl=$(cat "$1/h" 2>/dev/null || true); if [ -n "${_hl#* }" ] && [ "${_hl#* }" != "$_hl" ]; then palive "${_hl%% *}" "${_hl#* }"; else ! lage "$1"; fi; }   # a start not read is no start: held a minute
# lclear <folder>: under its guard, <folder>.steal, which names its clearer as a lock names its holder and is removed only once that clearer is gone
# (never for its age alone), renamed first so no fresh guard goes; a lock gone or renamed meanwhile is no dead one
lclear() { if mkdir "$1.steal" 2>/dev/null; then echo "$$ $(pstamp $$)" > "$1.steal/h" 2>/dev/null; _h0=$(cat "$1/h" 2>/dev/null || true)
    if [ -d "$1" ] && ! lheld "$1" && [ "$(cat "$1/h" 2>/dev/null || true)" = "$_h0" ]; then rm -rf "$1"; fi; rm -rf "$1.steal"
  elif ! lheld "$1.steal" && mv "$1.steal" "$1.steal.$$" 2>/dev/null; then rm -rf "$1.steal.$$"; fi; }
# lock_take <folder> [<seconds>]: 0 once held; 1 when a live holder keeps it past the seconds (60)
lock_take() { _l=$1; _w=${2:-60}; _n=0; while :; do
    if mkdir "$_l" 2>/dev/null; then { echo "$$ $(pstamp $$)" > "$_l/.h.$$" && mv -f "$_l/.h.$$" "$_l/h"; } 2>/dev/null && [ "$(cut -d' ' -f1 "$_l/h" 2>/dev/null)" = "$$" ] && return 0; continue; fi
    [ ! -d "$_l" ] || lheld "$_l" || { lclear "$_l"; [ -d "$_l" ] || continue; }; [ "$_n" -lt "$_w" ] || return 1; sleep 1; _n=$((_n + 1)); done; }   # a lock not cleared waits, counted
# lock_free <folder>: its holder's alone
lock_free() { [ "$(cut -d' ' -f1 "$1/h" 2>/dev/null)" != "$$" ] || rm -rf "$1"; }
# rs_edit <command> [<arg>…] (9.3 R2, M2): the run record's one writer on the ticket side. Under its lock (.vid/run-state.lock), the command reads the
# current .vid/RUN-STATE.md on stdin and prints it as it should be; written through put when it succeeded, printed something and changed. Each writer
# reads the record inside the lock, so two at once each get their change in and neither is lost
rs_edit() { _rl=.vid/run-state.lock; lock_take "$_rl" 60 || { echo "ViD: the run record's lock is held by a live process ($(cut -d' ' -f1 "$_rl/h" 2>/dev/null)); RUN-STATE.md not written" >&2; return 1; }
  _rt=.vid/.rs.$$; _rr=1; if "$@" < .vid/RUN-STATE.md > "$_rt" && [ -s "$_rt" ]; then _rr=0; cmp -s "$_rt" .vid/RUN-STATE.md || put .vid/RUN-STATE.md < "$_rt" || _rr=1; fi
  rm -f "$_rt"; lock_free "$_rl"; return $_rr; }
