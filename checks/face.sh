#!/bin/sh
# Purpose: ViD's face (0.26.10.29, step 1a): the sitting and the standing,
# two work-in-progress files a panel reads; never records — PRD.md and its
# answer ledger stay the only truth (RECORDS.md, "ViD's face").
#   .vid/face/sitting.json — what ViD presents at one of the sittings its
#     table holds (the four PRD sittings: interview, pause-1, pause-2,
#     pause-3; 0.26.10.29.6: and the eleven of stops 6 to 9), in the skill's order: sections of seven kinds (text,
#     questions, list, objections, decided, figures, alone), each item with
#     ViD's id, the acts a person may take and the answer it starts at.
#   .vid/face/standing.json — the nine stops of defining a project, which
#     is current, which are done, whose turn it is, and the wait's parts;
#     computed from disk.
# Usage:
#   sh checks/face.sh write <sitting> [<lines file>|-]   the session's lines
#       for what no script prints; prd.sh --pause (and scorecard.sh where a
#       sitting shows the scorecard) beside this script supply the rest.
#       Whole or not at all: a line it cannot read is refused by number,
#       nothing written.
#   sh checks/face.sh end <sitting>     the sitting ended (a pause at its
#       commit, the interview when its answers are taken); usability (P11):
#       its line of what was agreed is kept in .vid/face/agreed
#   sh checks/face.sh draft <sitting> [<lines file>|-]   usability (P13):
#       what ViD has drafted so far, the same lines as write for any of the
#       sitting's own sections (those not given are left out), written whole
#       in a third state, drafting: no buttons, never the person's turn
#   sh checks/face.sh wait parts "<name>" "<name>" …   usability (P6): the
#       parts of the wait now starting, in order, two to eight, each at most
#       60 characters
#   sh checks/face.sh wait at <n> ["<what ViD is doing, in plain words>"]
#       part n is running; the parts before it are done
#   sh checks/face.sh wait done         clears the parts (write and end do too)
#   sh checks/face.sh waiting           usability (P9): the sitting that waits, for
#       the book: `<name><TAB><stop><TAB><title>`, then `<item id><TAB><its words>`
#       a line; nothing when none waits. A read: it writes and removes nothing
#   write and end also run `pages.sh for <the sitting's stop>` where pages.sh
#       is beside this script, and the standing carries the pages' index
#   sh checks/face.sh standing          recompute the standing, print it
# The lines (one a line, ` | ` before free text; blank lines are skipped):
#   section <id>             the sitting's sections the session writes
#   empty <id> | <why>       a section of those with nothing in it
#   item <id> | <words>      an item, its id ViD's own (Q1, F-03, DIM-…)
#   detail | <words>         a line under the item above
#   recommend | <words>      ViD's recommendation (a question: one choice)
#   recommend | none         ViD has no recommendation for the item above
#   choice | <words>         a question's choice, or (0.26.10.29.6, S1) an
#                            alone item's, where its section has Choose
#   value | <words>          (S1) the figure shown for an item of a figures
#                            section the session writes
#   look | <why>             (S10) ViD points to the item above, the why one
#                            of: An open finding · Shapes a rule that must
#                            never break · No recommendation; the pointed
#                            items first in their section, else refused
#   section duplicates, then `item <a>~<b>` (no words) and one
#   `recommend | Merge|Keep apart|none` under it: (S2) ViD's recommendation
#                            for a pair prd.sh --pause prints; nothing else
#                            of a script's section is the session's
#   alone                    the item above is asked on its own (below)
# 0.26.10.29.6 (S2): a recommendation or none is required, the write refused
#   naming the item, on each finding of pause 1, each rewording of pause 3,
#   each near-duplicate pair (every pair prd.sh --pause prints must be named
#   in `section duplicates`), and the items of the design's gaps and lines and
#   of the test list's "Look here first"; an item asked on its own (`alone`,
#   or of an alone section) may come with none. The qualities are not held to
#   it: all but the two the skill asks about start at Needs it.
#   about | <section>/<item> a finding's item: the item it is about, drawn
#                            beside it (usability, P10)
#   says <item id> | <words> the words of a withdrawn check's clause
#   judged <quality> | <words>  a judged scorecard line, as presented
#   plain-changed <id> … | none  pause 3: the items whose plain sentences
#                            are shown (changed since pause 2)
# For the session that writes the lines (usability, P1 to P3, P7):
#   - every item starts at ViD's recommendation. A recommendation in a list or a findings section starts with the button's own words ("Cut", "Fix it: within one day", "Answer: 30 days"), then the end, a colon, a full stop, a comma, a semicolon or a dash; after a colon, the words of a button that takes them. Where a section has a standing act (the features, the qualities, the plain sentences) an item ViD gives nothing starts there.
#   - for each of the two qualities the skill wants ruled in or out, write `recommend | Needs it`, `recommend | Doesn't need it`, or `recommend | none`.
#   - write `alone` under an item whose answer would remove or weaken a failure clause, change a setting, or give a permission (a finding at the third pause that proposes a looser bound is one): it starts unanswered and holds back the send until the person answers it.
# 0.26.10.29.6 (S1, S7): where the map, as the standing shows it (the sitting
# on disk counted), stands past a sitting's stop, write and draft write
# nothing, say so in one line and exit 0; end of a sitting not on disk, or at a
# stop the map has left (a later stop done), says so, changes nothing, exits 0.
# Session words holding one of ViD's own words or an id: one notice line, the
# sitting still written.
# Only where .vid/ exists (as for events): elsewhere it writes nothing and
# says so. PRD.md is read in the repository's top level (else here).
# serves: both (0.26.10.29)
set -eu
LC_ALL=C; export LC_ALL   # bytes, so no multi-byte letter is cut or trimmed
D=$(cd "$(dirname "$0")" && pwd -P)
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
F=$TOP/.vid/face
PRD=$TOP/PRD.md
FORMAT=2   # usability (P1): items carry the answer they start at
say() { echo "ViD face: $*" >&2; }
die() { say "refused — $*"; exit 1; }
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
sittings() { table | awk -F'\t' '$1 == "sitting" { s = s (s ? ", " : "") $2 } END { print s }'; }
usage() { echo "ViD face: usage — sh checks/face.sh write <$(sittings | sed 's/, /|/g')> [<lines file>|-] | draft <sitting> [<lines file>|-] | end <sitting> | wait parts <name>… | wait at <n> [<words>] | wait done | waiting | standing" >&2; exit 2; }

# The sittings: id, the stop it is, its title, the send button's words, the
# closing line the person's message ends with (from the panel's design),
# whether its end closes its stop (usability, P8: the four PRD sittings
# do; a stop of several sittings is done by its own marks), and its short
# phrase for when it waits (usability, P12). Then its
# sections in the skill's order (CP = skills/vid-create-prd/SKILL.md): id,
# kind, who writes it (session, or the prd.sh --pause section it is read
# from), its title, its acts (id=label, a trailing + where the act takes
# words), and its standing act (usability, P1: the act every item starts at
# when ViD gave it no recommendation of its own; - for none).
# 0.26.10.29.6 (S1): the eleven sittings of stops 6 to 9 follow, none closing
# its stop, every section the session's (docs/specs/USABILITY-3-PAUSES.md, S1's
# table). A section may carry an eighth column, its rules joined by `;`:
#   rec            every item carries `recommend | …` or `recommend | none` (S2;
#                  an item asked on its own, and a draft, are not held to it)
#   choices=A|B    every item's choices, fixed: the session gives none of its own
#   nchoices=<n>   every item has exactly n choices
#   detail=<words> a fixed line under every item (S1, the access item: O7)
#   one            one item at a writing (stages-own)
#   nolook         no `look` line (S10: the test list's sitting)
# An act's label ending `!` (S2): an item ViD recommends it for is asked on its
# own, since that answer removes a requirement or a test.
# 0.26.10.29.6 (S4): pauses 2 and 3 carry `changed`, filled here from git.
table() {
  cat <<'EOF'
sitting	interview	2	The interview	Send answers to ViD	-	yes	Your questions are ready
section	questions	questions	session	Questions	choose=Choose,own=In my own words+,pick=You pick,skip=Skip	-
section	challenge	list	session	What the first version could ship without	cut=Cut,keep=Keep	-
sitting	pause-1	3	Agree the summary	Send to ViD	With these rulings, I approve the summary.	yes	Your summary is ready
section	thesis	text	session	The summary	-	-
section	contract	list	session	The qualities it must have	in=Needs it,out=Doesn't need it	in
section	features	list	features	The features	ok=Fine,change=Change+	ok
section	findings	objections	session	The critic's findings	fix=Fix it,overrule=Leave it+	-	rec
section	decisions	decided	decisions	Decided for you	change=Change+	-
section	withdrawn	alone	withdrawn	A check ViD's draft would remove	choose=Choose,own=In my own words+	-
sitting	pause-2	4	Answer the gaps	Send to ViD	With these rulings, I approve the plain sentences.	yes	The gaps are ready for you
section	gaps	questions	session	Gaps to answer	choose=Choose,own=In my own words+,pick=You pick,skip=Skip	-
section	never	questions	questions	What must never break	choose=Choose,own=In my own words+	-
section	size	figures	size	The size	-	-
section	decisions	decided	decisions	Decided for you	change=Change+	-
section	changed	decided	changed	Changed since you agreed it	change=Change+	-
section	sensitive	list	sensitive	Sensitive, resting on a ViD decision	ok=Fine,change=Change+	ok
section	duplicates	list	duplicates	Possibly one rule written twice	merge=Merge,apart=Keep apart	-	rec
section	plain	list	plain	Each rule in plain words	ok=Agree,change=Change+	ok
section	scorecard	figures	scorecard	The scorecard	-	-
section	withdrawn	alone	withdrawn	A check ViD's draft would remove	choose=Choose,own=In my own words+	-
sitting	pause-3	5	The final wording	Approve the final wording	I approve the final wording.	yes	The final wording is ready
section	decisions	decided	decisions	Decided for you	change=Change+	-
section	changed	decided	changed	Changed since you agreed it	change=Change+	-
section	rewordings	list	session	Rewordings	accept=Accept,decline=Decline	-	rec
section	findings	objections	session	Findings left	answer=Answer+,accept=Accept	-
section	duplicates	list	duplicates	Possibly one rule written twice	merge=Merge,apart=Keep apart	-	rec
section	plain	list	plain-changed	Each changed rule in plain words	ok=Agree,change=Change+	ok
section	scorecard	figures	scorecard	The scorecard	-	-
section	withdrawn	alone	withdrawn	A check ViD's draft would remove	choose=Choose,own=In my own words+	-
sitting	technical	6	Technical hints, and where it runs	Send to ViD	-	no	Your technical questions are ready
section	hints	questions	session	Your hints on design and technology	own=In my own words+,pick=You pick,skip=Skip	-
section	where	questions	session	Where it runs	choose=Choose,own=In my own words+	-
section	access	alone	session	Asked on its own	own=In my own words+	-	detail=Name the way only. Never type a password, a key or a token here.
sitting	design-who	7	Who makes the design	Send to ViD	-	no	A question on the design is ready
section	who	questions	session	Who makes the design	choose=Choose	-	nchoices=2
sitting	design-gaps	7	The design's gaps	Send to ViD	With these rulings, the design's gaps are settled.	no	The design's gaps are ready for you
section	brief-only	list	session	In the brief, not in the design	draw=Draw it,out=Leave it out!,owe=Owe it+	-	rec
section	design-only	list	session	In the design, not in the brief	adopt=Adopt it,drop=Drop it,fence=Fence it off	-	rec
section	unknown	list	session	ViD cannot tell what this is	right=ViD's guess is right,name=Name it+	-	rec
sitting	design-lines	7	Where the design and the PRD disagree	Send to ViD	I have ruled every line.	no	The design's disagreements are ready
section	lines	objections	session	Where the design and the PRD disagree	design=Design wins,prd=PRD wins,both=Both change,not=Not a disagreement	-	rec
sitting	design-approval	7	Approve the design	Approve the design	I approve the design.	no	The design is ready for your approval
section	decides	text	session	What the design decides	-	-
section	findings	objections	session	Findings on the changes	fix=Fix it,leave=Leave it+	-
section	alone	alone	session	Asked on their own	choose=Choose,own=In my own words+	-
sitting	tests	8	Approve the test list	Approve the test list	I approve the test list. I have not read it line by line.	no	The test list is ready for your approval
section	counted	figures	session	The test list, counted	-	-	nolook
section	look	list	session	Look here first	keep=Keep it,remove=Remove it+!,change=Change it+	-	rec;nolook
section	kinds	list	session	Kinds of failure ViD proposes to test for	keep=Keep it,drop=Drop it	keep	nolook
section	alone	alone	session	Asked on their own	choose=Choose,own=In my own words+	-	nolook
sitting	tests-review	8	The changes to the test list	Send to ViD	With these rulings, I approve the changes to the test list.	no	The changes to the test list are ready
section	findings	objections	session	Findings on the changes	fix=Fix it,leave=Leave it+	-
section	alone	alone	session	Asked on their own	choose=Choose,own=In my own words+	-
sitting	consolidation	8	What consolidation changed	Send to ViD	I approve these changes.	no	The PRD's changes are ready
section	changes	list	session	What consolidation changed in the PRD	ok=Fine,change=Change+	ok
section	alone	alone	session	Asked on their own	choose=Choose,own=In my own words+	-
sitting	settings	9	Two settings on this machine	Send to ViD	-	no	Two settings are ready for you
section	settings	alone	session	Two settings on this machine	choose=Choose	-	choices=Yes|No
sitting	stages	9	The stage cut	Send to ViD	With these answers, I approve the stage cut.	no	The stage cut is ready
section	cuts	figures	session	The cuts, counted	-	-
section	which	questions	session	Which cut	choose=Choose	-
section	stages	text	session	The stages of the recommended cut	-	-
section	open	questions	session	Product choices left open	choose=Choose,own=In my own words+	-
section	findings	objections	session	Findings on the changes the cut needs	fix=Fix it,leave=Leave it+	-
sitting	stages-own	9	Asked on its own	Send to ViD	-	no	A question asked on its own is ready
section	alone	alone	session	Asked on its own	choose=Choose	-	choices=Yes|No;one
EOF
}

STOPS='Describe the product|The interview|Agree the summary|Answer the gaps|The final wording|Technical hints, and where it runs|The design|The test list|The releases'

# A JSON string from one line of text.
JS='function js(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); gsub(/\r/, "", s); gsub(/[\001-\037]/, "", s); return "\"" s "\"" }'

stop_of() { table | awk -F'\t' -v s="$1" '$1 == "sitting" && $2 == s { print $3 }'; }
closes_of() { table | awk -F'\t' -v s="$1" '$1 == "sitting" && $2 == s { print $7 }'; }
# the sources of a sitting's sections, one a line
sources_of() { table | awk -F'\t' -v s="$1" '$1 == "sitting" { on = ($2 == s); next } on { print $4 }'; }

# --- the standing --------------------------------------------------------
# the standing, written whole by rename; usability (P4): leftovers of cut-off runs go first
standing() {
  find "$F" -maxdepth 1 -name '.standing.*' -mmin +1 -exec rm -f {} + 2>/dev/null || true
  find "$F" -maxdepth 1 -name 'run.*' -mtime +7 -exec rm -f {} + 2>/dev/null || true
  standing_json > "$F/.standing.$$"
  mv -f "$F/.standing.$$" "$F/standing.json"
}

# the standing computed from disk and printed, writing nothing (usability, P9: `waiting` reads it so)
standing_json() {
  ev=$TOP/.vid/metrics-events
  marks=''
  # 1: the PRD holds the person's own first words (its Seed, or SEED.md)
  if [ -f "$TOP/SEED.md" ] || { [ -f "$PRD" ] && awk '/^## Seed/ { on = 1; next } on && /^## / { exit } on && /<!--/ { c = 1 } on && !c && /[^[:space:]]/ && !/^Seed: / { found = 1 } on && /-->/ { c = 0 } END { exit !found }' "$PRD"; }; then marks="$marks 1"; fi
  # 3, 4, 5: the pause's event after the latest create-prd start, or its
  # Ratifications line (the line may trail the event by one pause)
  for n in 1 2 3; do
    e=no
    if [ -f "$ev" ] && awk -v n="$n" '/^stage name=create-prd .*state=start( |$)/ { p = 0 } $0 ~ ("^stage name=create-prd .*state=pause-" n "( |$)") { p = 1 } END { exit !p }' "$ev"; then e=yes; fi
    case $n in 1) sc='thesis+contract' ;; 2) sc='gap answers' ;; 3) sc='final' ;; esac
    if [ "$e" = no ] && [ -f "$PRD" ] && awk -v sc="$sc" '/^## Ratifications/ { on = 1; next } on && /^## / { exit } on && index($0, " — " sc " — ") && $0 ~ /^- [0-9]/ && $0 !~ /\{\{/ { f = 1 } END { exit !f }' "$PRD"; then e=yes; fi
    [ "$e" = yes ] && marks="$marks $((n + 2))"
  done
  # 2: the interview's sitting ended (its answers taken)
  if [ -f "$F/sitting.json" ] && grep -q '"sitting":"interview"' "$F/sitting.json" && grep -q '"state":"ended"' "$F/sitting.json"; then marks="$marks 2"; fi
  # 6: init's technical foundation written (BASELINE.md and ARCHITECTURE.md)
  if [ -f "$TOP/BASELINE.md" ] && [ -f "$TOP/ARCHITECTURE.md" ]; then marks="$marks 6"; fi
  # 7: 0.26.10.29.6 (S1): the design ratified — after the latest start of the design verb, only at its end; with no
  # design event, the design imported (design/), as before; a product with no face leaves no mark
  if [ -f "$ev" ] && grep -qE '^stage name=design .*state=start( |$)' "$ev"; then
    awk '/^stage name=design .*state=start( |$)/ { d = 0 } /^stage name=design .*state=end( |$)/ { d = 1 } END { exit !d }' "$ev" && marks="$marks 7"
  elif [ -d "$TOP/design" ]; then marks="$marks 7"; fi
  # 8: the test list ratified (test-inventory's end event)
  if [ -f "$ev" ] && grep -q '^stage name=test-inventory .*state=end' "$ev"; then marks="$marks 8"; fi
  # 9: the releases cut (stage-cut), or init handed back
  if [ -f "$ev" ] && grep -qE '^stage-cut |^stage name=init .*state=end' "$ev"; then marks="$marks 9"; fi
  # a sitting written for a stop is itself a mark: the stops before it are done
  sit=''; sst=''; ses=''; sstate=''; scl=''
  if [ -f "$F/sitting.json" ]; then
    sit=$(sed -n 's/.*"sitting":"\([a-z0-9-]*\)".*/\1/p' "$F/sitting.json" | head -1)
    sstate=$(sed -n 's/.*"state":"\([a-z]*\)".*/\1/p' "$F/sitting.json" | head -1)
    ses=$(sed -n 's/.*"session":"\([^"]*\)".*/\1/p' "$F/sitting.json" | head -1)
    [ -n "$sit" ] && { sst=$(stop_of "$sit"); scl=$(closes_of "$sit"); }
  fi
  # usability (P8): a stop has sittings when the table holds one for it
  sitstops=$(table | awk -F'\t' '$1 == "sitting" { printf " %s", $3 }')
  # usability (P6): the wait's parts, as the session named them
  wf=''; [ -f "$F/wait" ] && wf=$F/wait
  # usability (P11): each stop's latest line of what was agreed
  af=''; [ -f "$F/agreed" ] && af=$F/agreed
  # usability (P9): what there is to read, from the pages script's index
  pf=''; [ -f "$TOP/.vid/pages/index" ] && pf=$TOP/.vid/pages/index
  VID_PF="$pf" VID_AF="$af" VID_WF="$wf" awk -v marks="$marks" -v sst="${sst:-0}" -v scl="$scl" -v sit="$sit" -v sstate="$sstate" -v ses="$ses" -v stops="$STOPS" -v sitstops="$sitstops" -v fmt="$FORMAT" -v at="$(now)" "$JS"'
  BEGIN {
    # usability (P9): the paths by the environment, so a backslash in the path of the checkout is kept as written
    pf = ENVIRON["VID_PF"]; af = ENVIRON["VID_AF"]; wf = ENVIRON["VID_WF"]
    n = split(stops, name, "|"); m = split(marks, mk, " ")
    for (i = 1; i <= m; i++) done[mk[i]] = 1
    k = split(sitstops, ss, " "); for (i = 1; i <= k; i++) hassit[ss[i]] = 1
    # where no mark is left, a stop is done when a later one is
    for (i = 1; i < sst; i++) done[i] = 1
    for (i = n; i >= 1; i--) if (done[i]) { for (j = 1; j < i; j++) done[j] = 1; break }
    if (sstate == "ended" && sst > 0 && scl == "yes") done[sst] = 1
    cur = n + 1; for (i = 1; i <= n; i++) if (!done[i]) { cur = i; break }
    turn = (sstate == "waiting" && sst == cur) ? "person" : "vid"
    np = 0; wat = 0; wnow = ""
    if (wf != "") while ((getline l < wf) > 0) { t = index(l, "\t"); kk = substr(l, 1, t - 1); v = substr(l, t + 1); if (kk == "part") pn[++np] = v; else if (kk == "at") wat = v + 0; else if (kk == "now") wnow = v }
    w = "{\"parts\":["
    for (i = 1; i <= np; i++) w = w (i > 1 ? "," : "") "{\"name\":" js(pn[i]) ",\"state\":" js(i < wat ? "done" : i == wat ? "now" : "to come") "}"
    w = w "],\"now\":" js(wnow) "}"
    if (af != "") while ((getline l < af) > 0) { t = index(l, "\t"); if (t) agl[substr(l, 1, t - 1) + 0] = substr(l, t + 1) }
    pg = "["; npg = 0
    if (pf != "") while ((getline l < pf) > 0) {
      if (split(l, pfd, "\t") != 5) continue
      # a page whose file is gone is left out
      if ((getline probe < pfd[3]) < 0) continue
      close(pfd[3])
      st = "["; if (pfd[5] != "-") { ns2 = split(pfd[5], sn, ","); for (q = 1; q <= ns2; q++) if (sn[q] ~ /^[0-9]+$/) st = st (st == "[" ? "" : ",") (sn[q] + 0) }
      pg = pg (npg++ ? "," : "") "{\"id\":" js(pfd[1]) ",\"title\":" js(pfd[2]) ",\"file\":" js(pfd[3]) ",\"link\":" js(pfd[4] == "-" ? "" : pfd[4]) ",\"stops\":" st "]}"
    }
    pg = pg "]"
    s = "{\"format\":" fmt ",\"written\":" js(at) ",\"current\":" cur ",\"turn\":" js(turn) ",\"sitting\":" js(turn == "person" ? sit : "") ",\"session\":" js(turn == "person" ? ses : "") ",\"next\":" js(cur < n ? name[cur + 1] : "") ",\"wait\":" w ",\"pages\":" pg ",\"stops\":["
    for (i = 1; i <= n; i++) s = s (i > 1 ? "," : "") "{\"n\":" i ",\"name\":" js(name[i]) ",\"state\":" js(done[i] ? "done" : i == cur ? "here" : "todo") ",\"sitting\":" (hassit[i] ? "true" : "false") ",\"agreed\":" js(!done[i] ? "" : (i in agl) ? agl[i] : "Done") "}"
    print s "]}"
    printf "standing: stop %d of %d (%s), turn %s\n", cur, n, (cur <= n ? name[cur] : "all done"), turn > "/dev/stderr"
  }'
}

# --- the wait's parts (usability, P6) --------------------------------------
# characters, not bytes: a byte that continues a letter is not counted
chars() { printf '%s' "$1" | tr -d '\200-\277' | wc -c | tr -d ' '; }
wait_parts() {
  [ $# -ge 1 ] || usage
  case $1 in
    parts)
      shift
      [ $# -ge 2 ] && [ $# -le 8 ] || die "a wait has two to eight parts, not $#"
      W=$F/.wait.$$
      : > "$W"
      for p; do
        p=$(printf '%s' "$p" | tr '\t\n\r' '   ' | sed 's/^ *//; s/ *$//')
        [ -n "$p" ] || { rm -f "$W"; die 'a part has no name'; }
        [ "$(chars "$p")" -le 60 ] || { rm -f "$W"; die "the part '$p' is longer than 60 characters"; }
        printf 'part\t%s\n' "$p" >> "$W"
      done
      printf 'at\t0\n' >> "$W"
      mv -f "$W" "$F/wait" ;;
    at)
      [ $# -ge 2 ] && [ $# -le 3 ] || usage
      [ -f "$F/wait" ] || die 'no parts are named: sh checks/face.sh wait parts "<name>" … first'
      np=$(grep -c '^part	' "$F/wait" || true)
      case $2 in ''|*[!0-9]*) die "'$2' is not a part's number (1 to $np)" ;; esac
      [ "$2" -ge 1 ] && [ "$2" -le "$np" ] || die "there is no part $2 (1 to $np)"
      words=$(printf '%s' "${3:-}" | tr '\t\n\r' '   ')
      W=$F/.wait.$$
      { grep '^part	' "$F/wait"; printf 'at\t%s\n' "$2"; [ -z "$words" ] || printf 'now\t%s\n' "$words"; } > "$W"
      mv -f "$W" "$F/wait" ;;
    done) [ $# -eq 1 ] || usage; rm -f "$F/wait" ;;
    *) usage ;;
  esac
  standing
}

# --- changed since you agreed it (0.26.10.29.6, S4) -------------------------
# every line of the PRD's thesis and mechanisms that differs between the commit of the last line under
# ## Ratifications and the file as it stands, by git diff: `N<the line now>` then `W<the line as it was>` a line that
# differs (either may be empty: a new line, a line gone); or one `?<why>` line where nothing can be compared. A
# line's id is its first field (`MECH-02 | …`, `- G1: …`) where it holds a digit
prd_region() { awk '/^## (Thesis|Mechanisms)[[:space:]]*$/ { on = 1; next } /^## / { on = 0 } on && /[^[:space:]]/ && !/^```/' "$1"; }
changed_since() {
  c=$(awk '/^## Ratifications/ { on = 1; next } on && /^## / { exit } on && /^- / && !/\{\{/ { l = $0 } END { print l }' "$PRD" | grep -oE '[0-9a-f]{7,40}' | tail -1 || true)
  [ -n "$c" ] || { echo '?no ratification is recorded yet'; return 0; }
  C=$(mktemp -d)
  if ! (cd "$TOP" && git show "$c:PRD.md") > "$C/full" 2>/dev/null; then echo "?the last ratification's commit $c is not in this repository"; rm -rf "$C"; return 0; fi
  prd_region "$C/full" > "$C/was"; prd_region "$PRD" > "$C/now"
  # told apart by their own id, never paired by position: an id on both sides is a line changed (its agreed wording
  # below it), on the old side only a line gone, on the new side only a line new; a line with no id is gone or new
  (cd "$C" && git diff --no-index -U0 was now 2>/dev/null) | awk '
    function idof(l,   x) { x = l; sub(/^- /, "", x); if (match(x, /^[A-Z][A-Za-z0-9]*(-[A-Za-z0-9-]+)?( \||:)/)) { x = substr(x, 1, RLENGTH); sub(/( \||:)$/, "", x); if (x ~ /[0-9]/) return x } return "" }
    /^@@/ { on = 1; next }
    !on { next }
    /^-/ { r[++nr] = substr($0, 2); i = idof(r[nr]); if (i != "") rid[i] = nr; next }
    /^\+/ { a[++na] = substr($0, 2); next }
    END {
      for (k = 1; k <= na; k++) { i = idof(a[k]); if (i != "" && (i in rid)) { used[rid[i]] = 1; if (r[rid[i]] == a[k]) continue; print "N" a[k]; print "W" r[rid[i]] } else { print "N" a[k]; print "W" } }
      for (k = 1; k <= nr; k++) if (!(k in used)) { print "N"; print "W" r[k] }
    }'
  rm -rf "$C"
}

# --- writing a sitting ---------------------------------------------------
# DRAFT=1 (usability, P13): only the session's sections given, state drafting, the wait kept
DRAFT=0
write_sitting() {
  S=$1; IN=${2:--}
  STOP=$(stop_of "$S"); [ -n "$STOP" ] || die "'$S' is not a sitting ($(sittings))"
  # 0.26.10.29.6 (S1): a stop the map has passed gets no sitting — nothing written, the one on disk left as it is. The
  # map as the standing shows it, the sitting on disk counted; a re-write at the map's own stop is taken
  pcur=$(standing_json 2>/dev/null | sed -n 's/.*"current":\([0-9]*\).*/\1/p' | head -1)
  if [ -n "$pcur" ] && [ "$STOP" -lt "$pcur" ]; then
    say "$S is for stop $STOP, which the map has passed: no sitting is written and the one on disk stays; ask in the chat"
    exit 0
  fi
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  if [ "$IN" = - ]; then cat > "$W/lines"; else [ -f "$IN" ] || die "no lines file '$IN'"; cp "$IN" "$W/lines"; fi
  : > "$W/pause"; : > "$W/score"
  # usability (P8): PRD.md and its pause material only where a section is filled by a script
  if [ "$DRAFT" = 0 ] && sources_of "$S" | grep -qvx session; then
    [ -f "$PRD" ] || die "$S needs PRD.md in $TOP"
    # the material prints whether or not gaps remain; the exit is not ours
    (cd "$TOP" && sh "$D/prd.sh" PRD.md --pause > "$W/pause" 2>/dev/null) || true
    grep -q '^pause material ' "$W/pause" || die "prd.sh --pause printed no pause material for $PRD"
    if sources_of "$S" | grep -qx scorecard; then
      # the scorecard as the skill presents it: against the previous pause's PRD where it is saved
      prev=''; [ -f "$TOP/.vid/scorecard-previous.md" ] && prev=.vid/scorecard-previous.md
      (cd "$TOP" && sh "$D/scorecard.sh" PRD.md ${prev:+--previous "$prev"} > "$W/score" 2>/dev/null) || die 'scorecard.sh failed on PRD.md'
    fi
  fi
  : > "$W/changed"
  if [ "$DRAFT" = 0 ] && sources_of "$S" | grep -qx changed; then changed_since > "$W/changed"; fi
  table > "$W/table"
  sess=${CLAUDE_CODE_SESSION_ID:-}
  [ -n "$sess" ] || die 'no CLAUDE_CODE_SESSION_ID: a sitting carries the session that wrote it'
  awk -F'\t' -v draft="$DRAFT" -v S="$S" -v STOP="$STOP" -v sess="$sess" -v fmt="$FORMAT" -v at="$(now)" -v W="$W" "$JS"'
  function bad(m) { printf "ViD face: refused — line %d: %s (no sitting written)\n", FNR, m > "/dev/stderr"; err = 1; exit 1 }
  function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
  function rest(s,   i) { i = index(s, " | "); return i ? trim(substr(s, i + 3)) : "" }
  function okid(s) { return s ~ /^[A-Za-z0-9][A-Za-z0-9_.~-]*$/ }
  # 0.26.10.29.6 (S7): the first of ViD'"'"'s own words (whole words, a plural too) or an id in the forms of its ids, a text holds, or ""
  function plainck(t,   lw, u, n, i, vw) {
    if (match(t, /(^|[^A-Za-z0-9_-])((REQ|INV|RULE|DIF|EXC|SUP|ROW|HOS|FEAT|OQ|STAGE|MECH|DIM|GAP|DEPLOY)-[A-Za-z0-9]+|(A|D|F)-[0-9]+)/)) { u = substr(t, RSTART, RLENGTH); sub(/^[^A-Za-z]/, "", u); return u }
    u = " " t " "; gsub(/[^A-Za-z0-9]/, " ", u); if (index(u, " T0 ")) return "T0"
    lw = " " tolower(t) " "; gsub(/[^a-z0-9]/, " ", lw)
    n = split("court courts frame frames genus genera recognition compaction arm arms tier tiers lens lenses ledger ledgers", vw, " ")
    for (i = 1; i <= n; i++) if (index(lw, " " vw[i] " ")) return vw[i]
    return ""
  }
  function additem(sec, id, text) {
    if ((sec, id) in seen) { dup = 1; return }
    seen[sec, id] = 1; k = ++ni[sec]; iid[sec, k] = id; itx[sec, k] = text; nd[sec, k] = 0; nc[sec, k] = 0; irec[sec, k] = ""; ival[sec, k] = ""; norec[sec, k] = 0; alone[sec, k] = (skind[sec] == "alone"); iabout[sec, k] = ""; ilook[sec, k] = ""
    # 0.26.10.29.6 (S1): a section of fixed choices gives them to every item
    if (sfch[sec] != "") { nf2 = split(sfch[sec], fc2, "|"); for (j2 = 1; j2 <= nf2; j2++) ch[sec, k, ++nc[sec, k]] = fc2[j2] }
  }
  # the act a list'"'"'s or a finding'"'"'s recommendation names (usability, P1): its number, the words after it in mw
  function matchact(s, k,   r, lr, j, lab, ll, after, best, bl) {
    r = irec[s, k]; lr = tolower(r); best = 0; bl = 0; mw = ""
    for (j = 1; j <= nac[s]; j++) {
      lab = aclab[s, j]; ll = length(lab)
      if (r == "" || substr(lr, 1, ll) != tolower(lab)) continue
      after = substr(r, ll + 1)
      # usability (P1): after the label, the end, or a colon, a full stop, a comma, a semicolon or a dash, hyphen, en or em (spaces before
      # it allowed); a space then a word is no match
      if ((after ~ /^[[:space:]]*$/ || after ~ /^[[:space:]]*(:|\.|,|;|-|–|—)/) && ll > bl) { best = j; bl = ll; mw = after }
    }
    return best
  }
  # usability (P1): the answer an item starts at, and who set it
  function preset(s, k,   r, best, w) {
    pby = ""
    if (alone[s, k] || norec[s, k]) return ""
    r = irec[s, k]
    if (skind[s] == "questions") { if (r != "") { pby = "vid"; return "choose:" r } return "" }
    if (skind[s] != "list" && skind[s] != "objections") return ""
    best = matchact(s, k); w = mw
    if (best) {
      pby = "vid"
      # usability (P1): the words of a button follow a colon; any other mark after the label carries none
      if (w ~ /^[[:space:]]*:/) { sub(/^[[:space:]]*:[[:space:]]*/, "", w); w = trim(w) } else w = ""
      return (acwd[s, best] && w != "") ? acid[s, best] ":" w : acid[s, best]
    }
    if (sstand[s] != "-" && sstand[s] != "") { pby = "standing"; return sstand[s] }
    return ""
  }
  FILENAME == W "/table" {
    if ($1 == "sitting") { cur = $2; if (cur == S) { stitle0 = $4; ssend = $5; sclose = ($6 == "-") ? "" : $6; sready = $8 } next }
    if (cur != S) next
    ns++; sid[ns] = $2; skind[$2] = $3; ssrc[$2] = $4; stitle[$2] = $5; sacts[$2] = $6; sstand[$2] = $7; pos[$2] = ns
    nac[$2] = ($6 == "-") ? 0 : split($6, ac, ",")
    for (j = 1; j <= nac[$2]; j++) { p = index(ac[j], "="); acid[$2, j] = substr(ac[j], 1, p - 1); lab = substr(ac[j], p + 1); acbang[$2, j] = (lab ~ /!$/); sub(/!$/, "", lab); acwd[$2, j] = (lab ~ /\+$/); sub(/\+$/, "", lab); aclab[$2, j] = lab; if (acid[$2, j] == "choose") haschoose[$2] = 1 }
    # 0.26.10.29.6 (S1, S2, S10): the section'"'"'s own rules, the eighth column
    nfx = split($8, tfx, ";")
    for (j = 1; j <= nfx; j++) { p = index(tfx[j], "="); fk = p ? substr(tfx[j], 1, p - 1) : tfx[j]; fv = p ? substr(tfx[j], p + 1) : ""
      if (fk == "rec") srec[$2] = 1; else if (fk == "one") sone[$2] = 1; else if (fk == "nolook") snolook[$2] = 1
      else if (fk == "choices") sfch[$2] = fv; else if (fk == "nchoices") snch[$2] = fv + 0; else if (fk == "detail") sfdet[$2] = fv }
    next
  }
  # 0.26.10.29.6 (S4): the lines changed since the last ratification
  FILENAME == W "/changed" {
    if ($0 ~ /^\?/) { chwhy = substr($0, 2); next }
    if ($0 ~ /^N/) { chn[++nch] = substr($0, 2); next }
    if ($0 ~ /^W/) { chw[nch] = substr($0, 2) }
    next
  }
  FILENAME == W "/pause" {
    if ($0 ~ /^size: /) { psec = ""; line = substr($0, 7); nsz = split(line, kv, " "); for (i = 1; i <= nsz; i++) { sep = index(kv[i], "="); abt = 0; if (!sep) { sep = index(kv[i], "≈"); abt = sep > 0 } if (!sep) { szv[last] = szv[last] " " kv[i]; continue } last = substr(kv[i], 1, sep - 1); szk[++nk] = last; szv[last] = (abt ? "about " : "") substr(kv[i], sep + (abt ? length("≈") : 1)) } next }
    if ($0 ~ /^questions \(must-never-break/) { psec = "questions"; pcount["questions"] = $0; next }
    if ($0 ~ /^new ViD decisions /) { psec = "decisions"; next }
    if ($0 ~ /^sensitive /) { psec = "sensitive"; next }
    if ($0 ~ /^near-duplicates /) { psec = "duplicates"; next }
    if ($0 ~ /^features: /) { psec = "features"; next }
    if ($0 ~ /^plain sentences /) { psec = "plain"; next }
    # usability (P7): each failure clause ViD'"'"'s draft would remove (0.26.10.29.3 prints them last)
    if ($0 ~ /^owner questions/) { psec = "withdrawn"; next }
    if ($0 !~ /^  /) { psec = ""; next }
    if (psec == "") next
    pl[psec, ++pn[psec]] = substr($0, 3)
    next
  }
  FILENAME == W "/score" {
    if ($0 ~ /^flags: /) { scq[++nsc] = "flags"; scv["flags"] = substr($0, 8); scdone = 1; next }
    if ($0 ~ /^candidates/) { scdone = 1 }
    if (scdone || $0 !~ / \| (counted|judged) +\| /) next
    q = trim(substr($0, 1, index($0, "|") - 1)); v = $0; sub(/^[^|]*\|[^|]*\| /, "", v)
    scq[++nsc] = q; scv[q] = trim(v); next
  }
  {
    raw = $0; sub(/\r$/, "", raw); line = trim(raw)
    if (line == "") next
    split(line, w, " "); kw = w[1]; arg = w[2]
    # 0.26.10.29.6 (S7): words the person reads, holding one of ViD'"'"'s own words or an id: flagged, never refused
    if (kw ~ /^(item|detail|recommend|choice|value|says|empty|judged)$/) { pw = plainck(rest(line)); if (pw != "") notice = notice (notice == "" ? "" : ", ") "line " FNR " (" pw ")" }
    if (kw == "section") {
      if (!(arg in skind)) bad("section \"" arg "\" is not one this sitting has (" S ")")
      if (arg in given) bad("section \"" arg "\" given twice")
      # 0.26.10.29.6 (S2): of a script'"'"'s section the session gives only a near-duplicate pair'"'"'s recommendation
      if (ssrc[arg] == "duplicates") { given[arg] = 1; csec = ""; citem = 0; rsec = arg; rpair = ""; next }
      if (ssrc[arg] != "session") bad("section \"" arg "\" is printed by a script; the session does not write it")
      given[arg] = 1; csec = arg; citem = 0; rsec = ""; next
    }
    if (rsec != "") {
      if (kw == "item") {
        if (line != "item " arg) bad("item " arg " in section \"" rsec "\": a pair takes no words of the session, only its recommendation under it")
        if (arg in prec) bad("pair " arg " given twice"); rpair = arg; prec[arg] = ""; precat[arg] = FNR; pord[++npord] = arg; next }
      # 0.26.10.29.6 (S10): where to look, by the same rules as elsewhere; the pairs stand in the order the session names them
      if (kw == "look" && rpair != "") {
        t = rest(line)
        if (t != "An open finding" && t != "Shapes a rule that must never break" && t != "No recommendation") bad("look gives \"" t "\": the why is one of An open finding, Shapes a rule that must never break, No recommendation")
        if (rpair in plook) bad("pair " rpair " has one look line")
        for (j = 1; j < npord; j++) if (!(pord[j] in plook)) bad("pair " rpair " points where to look but follows " pord[j] ", which does not: the pointed items come first")
        plook[rpair] = t; next }
      if (kw == "recommend" && rpair != "") {
        if (prec[rpair] != "") bad("pair " rpair " has one recommendation")
        t = rest(line); if (t != "Merge" && t != "Keep apart" && t != "none") bad("pair " rpair ": the recommendation is Merge, Keep apart or none, not \"" t "\"")
        prec[rpair] = t; next }
      if (kw != "section" && kw != "empty") bad("\"" kw "\" in section \"" rsec "\": the session gives a pair only `item <a>~<b>`, one `recommend | Merge`, `Keep apart` or `none`, and at most one `look | <why>`")
      rsec = ""
    }
    if (kw == "empty") {
      if (!(arg in skind) || ssrc[arg] != "session") bad("\"" arg "\" is not a section the session writes at " S)
      if (arg in given) bad("section \"" arg "\" given twice")
      given[arg] = 1; isempty[arg] = 1; why[arg] = rest(line); csec = ""; citem = 0; next
    }
    if (kw == "item") {
      if (csec == "") bad("an item outside a section")
      if (!okid(arg)) bad("item id \"" arg "\" is not an id")
      t = rest(line); if (t == "") bad("item " arg " has no words")
      if (sone[csec] && ni[csec] >= 1) bad("section \"" csec "\" takes one item at a writing; write the sitting again for the next")
      dup = 0; additem(csec, arg, t); if (dup) bad("item id \"" arg "\" given twice")
      citem = ni[csec]; next
    }
    if (kw == "detail" || kw == "recommend" || kw == "choice" || kw == "value") {
      if (!citem) bad(kw " with no item above it")
      t = rest(line); if (t == "") bad(kw " with no words")
      if (kw == "detail") det[csec, citem, ++nd[csec, citem]] = t
      if (kw == "recommend") { if (skind[csec] == "text" || skind[csec] == "figures") bad("a recommendation in a " skind[csec] " section")
        if (t == "none") { norec[csec, citem] = 1; irec[csec, citem] = "" } else { irec[csec, citem] = t; norec[csec, citem] = 0 }
        # 0.26.10.29.6 (S1): a question offers what it can be answered with: its fixed choices, or choices at all
        if (t != "" && t != "none" && (skind[csec] == "questions" || skind[csec] == "alone")) {
          if (!haschoose[csec]) bad("a recommendation in section \"" csec "\", which offers no choices (recommend | none, or nothing)")
          if (sfch[csec] != "" && index("|" sfch[csec] "|", "|" t "|") == 0) bad("the recommendation \"" t "\" is not one of section \"" csec "\"'"'"'s choices (" sfch[csec] ")") } }
      if (kw == "choice") { if (skind[csec] != "questions" && skind[csec] != "alone") bad("a choice outside a questions or an alone section")
        if (!haschoose[csec]) bad("a choice in section \"" csec "\", which offers no choices")
        if (sfch[csec] != "") bad("section \"" csec "\"'"'"'s choices are fixed (" sfch[csec] "); it takes none of the session'"'"'s")
        ch[csec, citem, ++nc[csec, citem]] = t }
      # 0.26.10.29.6 (S1): the figure shown for an item of a figures section the session writes
      if (kw == "value") { if (skind[csec] != "figures") bad("a value outside a figures section"); ival[csec, citem] = t }
      next
    }
    # 0.26.10.29.6 (S10): where to look, by one of three counted rules; the pointed items first in their section
    if (kw == "look") {
      if (!citem) bad("look with no item above it")
      if (snolook[csec]) bad("look in section \"" csec "\": this sitting does not use it (its own section holds what needs the person)")
      if (skind[csec] != "questions" && skind[csec] != "list" && skind[csec] != "objections" && skind[csec] != "alone") bad("look on an item of a " skind[csec] " section, which takes no answer")
      t = rest(line)
      if (t != "An open finding" && t != "Shapes a rule that must never break" && t != "No recommendation") bad("look gives \"" t "\": the why is one of An open finding, Shapes a rule that must never break, No recommendation")
      for (j = 1; j < citem; j++) if (ilook[csec, j] == "") bad("item " iid[csec, citem] " points where to look but follows " iid[csec, j] ", which does not: the pointed items come first")
      ilook[csec, citem] = t; next
    }
    if (kw == "alone") {
      if (!citem) bad("alone with no item above it")
      if (skind[csec] != "questions" && skind[csec] != "list" && skind[csec] != "objections" && skind[csec] != "alone") bad("alone on an item of a " skind[csec] " section, which takes no answer")
      alone[csec, citem] = 1; next
    }
    if (kw == "about") {
      if (!citem) bad("about with no finding above it")
      if (skind[csec] != "objections") bad("about belongs under a finding, not an item of a " skind[csec] " section")
      t = rest(line); if (t !~ /^[A-Za-z0-9][A-Za-z0-9_.~-]*\/[A-Za-z0-9][A-Za-z0-9_.~-]*$/) bad("about names \"" t "\", not <section id>/<item id>")
      iabout[csec, citem] = t; next
    }
    if (kw == "says") {
      if (!okid(arg)) bad("says names \"" arg "\", which is not an id")
      t = rest(line); if (t == "") bad("says " arg " with no words")
      says[arg] = t; saysat[arg] = FNR; next
    }
    if (kw == "judged") {
      if (!("scorecard" in skind)) bad("judged lines belong to pauses 2 and 3")
      jq[arg] = rest(line); next
    }
    if (kw == "plain-changed") {
      if (!("plain" in skind) || ssrc["plain"] != "plain-changed") bad("plain-changed belongs to pause 3")
      havepc = 1; x = line; sub(/^plain-changed[[:space:]]*/, "", x); sub(/[[:space:]]*\|[[:space:]]*none$/, "", x)
      if (x == "none" || x == "") next
      m = split(x, ids, /[ ,]+/); for (i = 1; i <= m; i++) if (ids[i] != "") pc[ids[i]] = 1
      next
    }
    bad("\"" kw "\" is not a line this script reads")
  }
  END {
    if (err) exit 1
    for (i = 1; i <= ns; i++) { s = sid[i]; if (!draft && ssrc[s] == "session" && !(s in given)) { FNR = 0; printf "ViD face: refused — section \"%s\" (%s) is neither given nor declared empty (no sitting written)\n", s, stitle[s] > "/dev/stderr"; exit 1 } }
    for (i = 1; i <= ns; i++) { s = sid[i]; if (ssrc[s] == "session" && (s in given) && !(s in isempty) && ni[s] == 0) { printf "ViD face: refused — section \"%s\" has no item; declare it empty instead (no sitting written)\n", s > "/dev/stderr"; exit 1 } }
    if (!draft && ("plain" in skind) && ssrc["plain"] == "plain-changed" && !havepc) { printf "ViD face: refused — pause 3 names the items whose plain sentences it shows: plain-changed <ids> or plain-changed none (no sitting written)\n" > "/dev/stderr"; exit 1 }
    szname["demand"] = "Requirements"; szname["pilot"] = "In the first version"; szname["grader-batches"] = "Grading batches"; szname["features"] = "Features"; szname["largest"] = "The largest features"
    # the plain sentence of each item, for near-duplicate pairs; the plain sentence alone, for a withdrawn clause
    for (k = 1; k <= pn["plain"]; k++) { split(pl["plain", k], f, " \\| "); pid = trim(f[1]); ps = f[2]; sub(/^plain: /, "", ps); rl = f[3]; sub(/^rule: /, "", rl); plainof[pid] = (ps == "(none)" || ps == "") ? rl : ps; if (ps != "(none)" && ps != "") plainonly[pid] = ps }
    # the script sections, from prd.sh --pause and scorecard.sh
    for (i = 1; i <= ns; i++) {
      s = sid[i]; src = ssrc[s]
      if (src == "session" || draft) continue
      if (src == "size") {
        for (k = 1; k <= pn["features"]; k++) { split(pl["features", k], f, " \\| "); fname[trim(f[1])] = trim(f[3]) }
        for (k = 1; k <= nk; k++) { q = szk[k]; v = szv[q]; if (q == "largest") for (fx in fname) gsub(fx, fname[fx], v); additem(s, q, (q in szname) ? szname[q] : q); ival[s, ni[s]] = v }
      }
      if (src == "scorecard") { for (k = 1; k <= nsc; k++) { q = scq[k]; additem(s, q, q); ival[s, ni[s]] = (q in jq) ? jq[q] : scv[q] } }
      if (src == "questions") for (k = 1; k <= pn["questions"]; k++) {
        x = pl["questions", k]; p = index(x, " — "); hd = substr(x, 1, p - 1); x = substr(x, p + length(" — "))
        split(hd, h, " "); n3 = split(x, f, " \\| ")
        additem(s, h[1], trim(f[1])); c = ni[s]
        for (j = 2; j <= n3; j++) { if (f[j] ~ /^recommended: /) { r = f[j]; sub(/^recommended: /, "", r); irec[s, c] = trim(r); ch[s, c, ++nc[s, c]] = trim(r) } else det[s, c, ++nd[s, c]] = trim(f[j]) }
        det[s, c, ++nd[s, c]] = "asks " h[2]
      }
      if (src == "decisions") for (k = 1; k <= pn["decisions"]; k++) {
        n3 = split(pl["decisions", k], f, " \\| "); id = trim(f[1]); sub(/ \(revised\)$/, "", id); a = f[n3]; sub(/^A: /, "", a)
        additem(s, id, trim(a)); c = ni[s]; det[s, c, ++nd[s, c]] = trim(f[3]); if (pl["decisions", k] ~ /^[^|]*\(revised\)/) det[s, c, ++nd[s, c]] = "revised since it was shown"
      }
      if (src == "sensitive") for (k = 1; k <= pn["sensitive"]; k++) {
        split(pl["sensitive", k], f, " \\| "); id = trim(f[1]); t = (id in plainof) ? plainof[id] : id
        additem(s, id, t); c = ni[s]; det[s, c, ++nd[s, c]] = trim(f[4]); det[s, c, ++nd[s, c]] = trim(f[2]) " · " trim(f[3])
      }
      # 0.26.10.29.6 (S2, S10): the pairs the session named first, in its order, with its recommendation and look; then any
      # it did not name, in the order prd.sh prints them (refused below for want of a recommendation)
      if (src == "duplicates") {
        for (k = 1; k <= pn["duplicates"]; k++) { split(pl["duplicates", k], f, " \\| "); pr = trim(f[1]); split(pr, ab, / ~ /); pk[ab[1] "~" ab[2]] = k }
        npo = 0; for (j = 1; j <= npord; j++) if (pord[j] in pk) po[++npo] = pk[pord[j]]
        for (k = 1; k <= pn["duplicates"]; k++) { split(pl["duplicates", k], f, " \\| "); pr = trim(f[1]); split(pr, ab, / ~ /); if (!((ab[1] "~" ab[2]) in prec)) po[++npo] = k }
        for (q = 1; q <= npo; q++) {
          k = po[q]
          split(pl["duplicates", k], f, " \\| "); pr = trim(f[1]); split(pr, ab, / ~ /)
          additem(s, ab[1] "~" ab[2], ((ab[1] in plainof) ? plainof[ab[1]] : ab[1]) " — and — " ((ab[2] in plainof) ? plainof[ab[2]] : ab[2])); c = ni[s]
          det[s, c, ++nd[s, c]] = ab[1] " and " ab[2] ": " trim(f[2])
          x = iid[s, c]; if (x in prec) { pused[x] = 1; if (prec[x] == "none") norec[s, c] = 1; else irec[s, c] = prec[x]; if (x in plook) ilook[s, c] = plook[x] }
        }
      }
      if (src == "duplicates") for (x in prec) {
        if (prec[x] == "") { printf "ViD face: refused — line %d: pair %s has no recommendation under it (Merge, Keep apart or none) (no sitting written)\n", precat[x], x > "/dev/stderr"; exit 1 }
        if (!(x in pused)) { printf "ViD face: refused — line %d: pair %s is not one prd.sh --pause prints (no sitting written)\n", precat[x], x > "/dev/stderr"; exit 1 }
      }
      if (src == "features") for (k = 1; k <= pn["features"]; k++) {
        split(pl["features", k], f, " \\| "); additem(s, trim(f[1]), trim(f[3])); c = ni[s]; pd = trim(f[4]); sub(/^pilot demand /, "", pd); t0 = trim(f[5]); sub(/^T0 /, "", t0)
        det[s, c, ++nd[s, c]] = pd " in the first version · " t0 " must never break"
      }
      if (src == "plain" || src == "plain-changed") for (k = 1; k <= pn["plain"]; k++) {
        split(pl["plain", k], f, " \\| "); id = trim(f[1]); if (src == "plain-changed" && !(id in pc)) continue
        ps = f[2]; sub(/^plain: /, "", ps); rl = f[3]; sub(/^rule: /, "", rl)
        if (ps == "(none)" || ps == "") { additem(s, id, rl); c = ni[s]; det[s, c, ++nd[s, c]] = "No plain sentence yet: this is the rule as written" } else { additem(s, id, ps); c = ni[s]; det[s, c, ++nd[s, c]] = "The rule: " rl }
      }
      # usability (P7): one item a withdrawn clause, <requirement>~<clause>; the words a says line gives first
      if (src == "withdrawn") for (k = 1; k <= pn["withdrawn"]; k++) {
        x = trim(pl["withdrawn", k]); split(x, f, " ")
        if (f[1] == "arm" && f[3] == "of" && f[2] ~ /^[0-9]+$/ && okid(f[4])) { id = f[4] "~" f[2]; t = (f[4] in plainonly) ? plainonly[f[4]] : f[4] } else { id = "withdrawn-" k; t = x }
        additem(s, id, t); c = ni[s]
        if (id in says) { det[s, c, ++nd[s, c]] = says[id]; used[id] = 1 }
        det[s, c, ++nd[s, c]] = x
        ch[s, c, ++nc[s, c]] = "Keep the check"; ch[s, c, ++nc[s, c]] = "Remove it"
      }
      if (src == "plain-changed") for (x in pc) if (!((s, x) in seen)) { printf "ViD face: refused — plain-changed names %s, which prd.sh --pause does not print (no sitting written)\n", x > "/dev/stderr"; exit 1 }
      # 0.26.10.29.6 (S4): one item a line changed since the last ratification, the line now, the line as it was below it
      if (src == "changed") for (k = 1; k <= nch; k++) {
        nw = chn[k]; wa = chw[k]; id = nw; if (id == "") id = wa; sub(/[[:space:]]*\|.*$/, "", id)
        if (!okid(id) || id !~ /-[0-9]/) id = "line-" k
        dup = 0; additem(s, id, (nw != "") ? nw : "This line is gone"); if (dup) { dup = 0; additem(s, "line-" k, (nw != "") ? nw : "This line is gone") }
        c = ni[s]; det[s, c, ++nd[s, c]] = (wa != "") ? "As you agreed it: " wa : "Not there when you agreed it"
      }
      if (ni[s] == 0) { isempty[s] = 1; why[s] = (src == "changed") ? (chwhy != "" ? chwhy : "nothing in the summary or the mechanisms differs since you agreed it") : "none at this pause" }
    }
    for (x in says) if (!(x in used)) { printf "ViD face: refused — line %d: says names %s, which is no check this sitting shows ViD'"'"'s draft would remove (no sitting written)\n", saysat[x], x > "/dev/stderr"; exit 1 }
    # a recommendation is one of the choices of its question: one given alone becomes one
    for (i = 1; i <= ns; i++) { s = sid[i]; if (skind[s] != "questions" && skind[s] != "alone") continue
      for (k = 1; k <= ni[s]; k++) { if (irec[s, k] == "") continue; hit = 0; for (j = 1; j <= nc[s, k]; j++) if (ch[s, k, j] == irec[s, k]) hit = 1; if (!hit) ch[s, k, ++nc[s, k]] = irec[s, k] } }
    # 0.26.10.29.6 (S1, S2): a section'"'"'s own rules, and an answer that removes asked on its own
    for (i = 1; i <= ns; i++) { s = sid[i]
      for (k = 1; k <= ni[s]; k++) {
        if (!draft && srec[s] && !alone[s, k] && irec[s, k] == "" && !norec[s, k]) { printf "ViD face: refused — item %s of section \"%s\" has neither a recommendation nor recommend | none (no sitting written)\n", iid[s, k], s > "/dev/stderr"; exit 1 }
        if (snch[s] && nc[s, k] != snch[s]) { printf "ViD face: refused — item %s of section \"%s\" has %d choices, not %d (no sitting written)\n", iid[s, k], s, nc[s, k], snch[s] > "/dev/stderr"; exit 1 }
        if ((skind[s] == "list" || skind[s] == "objections") && !norec[s, k] && irec[s, k] != "") { j = matchact(s, k); if (j && acbang[s, j]) alone[s, k] = 1 }
        if (sfdet[s] != "") det[s, k, ++nd[s, k]] = sfdet[s]
      } }
    o = "{\"format\":" fmt ",\"sitting\":" js(S) ",\"stop\":" STOP ",\"session\":" js(sess) ",\"written\":" js(at) ",\"state\":\"" (draft ? "drafting" : "waiting") "\",\"ended\":\"\",\"title\":" js(stitle0) ",\"send\":" js(ssend) ",\"closing\":" js(sclose) ",\"ready\":" js(sready) ",\"sections\":["
    no = 0
    for (i = 1; i <= ns; i++) {
      s = sid[i]; if (draft && !(s in given)) continue
      o = o (no++ ? "," : "") "{\"id\":" js(s) ",\"kind\":" js(skind[s]) ",\"title\":" js(stitle[s]) ",\"source\":" js(ssrc[s] == "session" ? "session" : "vid") ",\"empty\":" ((s in isempty) ? "true" : "false") ",\"why\":" js((s in isempty) ? why[s] : "") ",\"acts\":["
      for (j = 1; j <= nac[s]; j++) o = o (j > 1 ? "," : "") "{\"id\":" js(acid[s, j]) ",\"label\":" js(aclab[s, j]) ",\"words\":" (acwd[s, j] ? "true" : "false") "}"
      o = o "],\"items\":["
      for (k = 1; k <= ni[s]; k++) {
        pv = preset(s, k)
        o = o (k > 1 ? "," : "") "{\"id\":" js(iid[s, k]) ",\"text\":" js(itx[s, k]) ",\"detail\":["
        for (j = 1; j <= nd[s, k]; j++) o = o (j > 1 ? "," : "") js(det[s, k, j])
        o = o "],\"recommend\":" js(irec[s, k]) ",\"choices\":["
        for (j = 1; j <= nc[s, k]; j++) o = o (j > 1 ? "," : "") js(ch[s, k, j])
        o = o "],\"value\":" js(ival[s, k]) ",\"preset\":" js(pv) ",\"presetBy\":" js(pby) ",\"alone\":" (alone[s, k] ? "true" : "false") ",\"norecommend\":" (norec[s, k] ? "true" : "false") ",\"about\":" js(iabout[s, k]) ",\"look\":" js(ilook[s, k]) "}"
      }
      o = o "]}"
    }
    print o "]}"
    if (notice != "") print notice > (W "/notice")
  }' "$W/table" "$W/pause" "$W/score" "$W/changed" "$W/lines" > "$W/sitting.json" || exit 1
  mkdir -p "$F"
  mv -f "$W/sitting.json" "$F/.sitting.$$"
  mv -f "$F/.sitting.$$" "$F/sitting.json"
  echo "ViD face: $S $([ "$DRAFT" = 1 ] && echo drafted || echo written) ($(grep -o '"id":"[^"]*","text"' "$F/sitting.json" | wc -l | tr -d ' ') items)" >&2
  # 0.26.10.29.6 (S7): one line, which lines hold an id or one of ViD's own words; the sitting stands
  [ ! -s "$W/notice" ] || say "plain words — $(cat "$W/notice") hold an id or one of ViD's own words: rewrite them in plain words before you ask (the sitting is written)"
  [ "$DRAFT" = 1 ] || rm -f "$F/wait"   # usability (P6): a sitting written ends the wait; a draft does not
  standing
  [ "$DRAFT" = 1 ] || pages_for "$STOP"
}

# usability (P9): with the sitting in place and the standing recomputed, the pages due at its stop, where pages.sh is
# beside this script; its lines go to the session unchanged, and the standing is recomputed once more so a page it made
# is in it. A failure of that script changes nothing of the sitting.
pages_for() {
  [ -f "$D/pages.sh" ] || return 0
  # recomputed whatever its exit: a page it made before failing is in the standing too
  if (cd "$TOP" && sh "$D/pages.sh" for "$1"); then :; else say "the pages script failed (exit $?): the sitting stands, a page it did not make is missing"; fi
  standing
  return 0
}

# usability (P9): the sitting that waits (P4's rule: at the current stop or a later one), for the book: its name, stop
# and title, then one line an item, its id and its words; nothing when none waits
waiting() {
  [ -f "$F/sitting.json" ] && grep -q '"state":"waiting"' "$F/sitting.json" || return 0
  # a read: the current stop computed afresh and printed, nothing under .vid/ written or removed
  cur=$(standing_json 2>/dev/null | sed -n 's/.*"current":\([0-9]*\).*/\1/p' | head -1)
  sit=$(sed -n 's/.*"sitting":"\([a-z0-9-]*\)".*/\1/p' "$F/sitting.json" | head -1)
  sst=$(stop_of "$sit")
  [ -n "$sst" ] && [ -n "$cur" ] && [ "$cur" -le "$sst" ] || return 0
  printf '%s\t%s\t%s\n' "$sit" "$sst" "$(sed -n 's/.*"title":"\([^"]*\)","send".*/\1/p' "$F/sitting.json" | head -1)"
  grep -oE '"id":"[^"]*","text":"([^"\\]|\\.)*"' "$F/sitting.json" | awk '{
    id = $0; sub(/^"id":"/, "", id); sub(/",".*$/, "", id)
    t = $0; sub(/^"id":"[^"]*","text":"/, "", t); sub(/"$/, "", t)
    o = ""; while ((i = index(t, "\\")) > 0) { c = substr(t, i + 1, 1); o = o substr(t, 1, i - 1) (c == "t" ? " " : c); t = substr(t, i + 2) }
    print id "\t" o t }'
}

end_sitting() {
  S=$1; [ -n "$(stop_of "$S")" ] || die "'$S' is not a sitting ($(sittings))"
  # 0.26.10.29.6 (S1): a sitting not written (its stop passed, or another on disk) has nothing to end: said, nothing changed
  if [ ! -f "$F/sitting.json" ] || ! grep -q "\"sitting\":\"$S\"" "$F/sitting.json"; then
    say "$S was not written (no sitting, or another one, is on disk): nothing to end, nothing changed"
    exit 0
  fi
  # 0.26.10.29.6 (S1): at a stop the map has left (a later stop done) an end changes nothing: the sitting, the agreed
  # lines and the marks stay. A pause's own ratification marks only its own stop, so its end still ends it
  if standing_json 2>/dev/null | awk -v st="$(stop_of "$S")" '{ while (match($0, /"n":[0-9]+,"name":"[^"]*","state":"done"/)) { x = substr($0, RSTART + 4, RLENGTH); sub(/,.*/, "", x); if (x + 0 > st + 0) f = 1; $0 = substr($0, RSTART + RLENGTH) } } END { exit !f }'; then
    say "$S is for stop $(stop_of "$S"), which the map has passed: nothing ended, nothing changed"
    exit 0
  fi
  if grep -q '"state":"waiting"' "$F/sitting.json"; then
    sed "s/\"state\":\"waiting\",\"ended\":\"\"/\"state\":\"ended\",\"ended\":\"$(now)\"/" "$F/sitting.json" > "$F/.sitting.$$"
    mv -f "$F/.sitting.$$" "$F/sitting.json"
    echo "ViD face: $S ended" >&2
    # usability (P11): what was agreed, from the sitting itself: its title, its items, the day it ended
    n=$(grep -o '"id":"[^"]*","text"' "$F/sitting.json" | wc -l | tr -d ' ')
    t=$(sed -n 's/.*"title":"\([^"]*\)","send".*/\1/p' "$F/sitting.json" | head -1)
    printf '%s\t%s: %s %s, agreed %s\n' "$(stop_of "$S")" "$t" "$n" "$([ "$n" = 1 ] && echo item || echo items)" "$(LC_ALL=C date -u '+%d %b' | sed 's/^0//')" >> "$F/agreed"
  fi
  rm -f "$F/wait"   # usability (P6): a sitting ended ends the wait
  standing
  pages_for "$(stop_of "$S")"   # usability (P9): no page keeps saying the sitting waits
}

[ $# -ge 1 ] || usage
if [ ! -d "$TOP/.vid" ]; then say "no .vid/ in $TOP: not a ViD project, so no sitting is written (the chat goes on as before)"; exit 0; fi
[ "$1" = waiting ] || mkdir -p "$F"   # usability (P9): waiting is a read
case $1 in
  write) [ $# -ge 2 ] && [ $# -le 3 ] || usage; write_sitting "$2" "${3:--}" ;;
  draft) [ $# -ge 2 ] && [ $# -le 3 ] || usage; DRAFT=1; write_sitting "$2" "${3:--}" ;;
  end) [ $# -eq 2 ] || usage; end_sitting "$2" ;;
  wait) shift; wait_parts "$@" ;;
  waiting) [ $# -eq 1 ] || usage; waiting ;;
  standing) [ $# -eq 1 ] || usage; standing; cat "$F/standing.json" ;;
  *) usage ;;
esac
