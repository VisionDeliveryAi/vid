# Purpose: selftest fixture — the sort of the owner's list (FB-5 A1). Sourced after planner-toy.sh, tickets.sh and manual.sh (Env:
# CHECKS, T, fail()).
# so_toy <dir>: the manual toy there, entered, with a run record, the queue the owner's, $T/home as HOME; QS the queue, SO the sort's
#   file, B the backlog, TB a tab
# so_qs <verb> …: queue.sh, its output in $T/out, its exit in RC; so_ok the same, and a failure of the case when it is not 0
# so_l <kind> <a> <b> <c> <d>: one line of a call, tab-separated; so_raise: the lines on stdin raised
# so_id <words>: the open backlog item whose words hold them
# so_todo <ids> <title>: a whole todo block; so_now: `queue.sh sorted` into $T/now
so_toy() { HOME=$T/home; export HOME; mkdir -p "$HOME"; mn_project "$1"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
  printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
  QS=$CHECKS/queue.sh; B=.vid/decide/queue/backlog; SO=.vid/decide/queue/sorted; TB=$(printf '\t'); }
so_qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }
so_ok() { so_qs "$@"; [ "$RC" = 0 ] || fail "queue.sh $* exited $RC"; }
so_l() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
so_raise() { cat > "$T/L"; so_ok raise "$T/L"; }
so_id() { awk -F'\t' -v w="$1" '$3 != "done" && index($5, w) { print $1; exit }' "$B"; }
so_todo() { printf 'line todo %s\ntitle %s\ndo Say which\nwhat The team waits for this.\nask Which one?\nchoice The first\nchoice The second\nchoose 1 it is the smaller change\nthen The team is told.\n\n' "$1" "$2"; }
so_now() { sh "$QS" sorted > "$T/now" 2> "$T/out" || fail 'queue.sh sorted failed'; }
