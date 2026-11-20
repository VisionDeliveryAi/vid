# Purpose: selftest fixture — GitHub manual's amendments, withdrawals and the team's ticket changes (GM-2 T5, T6, T7). Sourced after
# fixtures/form.sh (Env: CHECKS, T).
# am_move <row> <from> <to>: the row moved in RUN-STATE's block from step <from> to the front of step <to>'s rows (the toy's needs
#   lines are each `| -`, so none changes)
# am_change <n> <why>: plan.sh change rows "<why>", trigger owner-answer, evidence ticket:<n>, as a move records it; $T/chg the output
# am_amend <n> <words> [<cause>]: the preparation (the export, the sync), writer.sh write amend <n> [--cause <cause>], then github.sh
#   tw-post --amend <n> --words <words>; AM_F the file, $T/post the output; returns 1 on the first refusal
# am_comment <n> <first words>: the newest comment of issue n opening with those words, printed; nothing when none
# am_read: next.sh read, then next.sh changes into $T/ch; returns 1 when either fails
# am_take_over <n>: issue n's records made those of a ticket /vid mode took over from its comments: its published line in the switch's
#   form (`taken-over=comments writing=<h>`, no form= or words=), no `sent` line, no form or kept-body record; its writing kept
am_move() { pt_rs "s/^\(step $2 .*rows:.*\) $1 /\1 /"; pt_rs "s/^\(step $3 .*rows:\) /\1 $1 /"; }
am_change() { sh "$CHECKS/plan.sh" change rows "$2" --trigger owner-answer --evidence "ticket:$1" --expect 'the ticket changes its tests' > "$T/chg" 2>&1; }
am_amend() { _n=$1; _w=$2; shift 2; AM_F=''
  sh "$CHECKS/github.sh" spec-export > "$T/post" 2>&1 && sh "$CHECKS/github.sh" tw-sync >> "$T/post" 2>&1 || return 1
  if [ $# -gt 0 ]; then AM_F=$(sh "$CHECKS/writer.sh" write amend "$_n" --cause "$1" 2>> "$T/post") || return 1; else AM_F=$(sh "$CHECKS/writer.sh" write amend "$_n" 2>> "$T/post") || return 1; fi
  sh "$CHECKS/github.sh" tw-post --amend "$_n" --words "$_w" "$AM_F" > "$T/post" 2>&1; }
am_comment() { _c=''; for _k in $(ls "$FAKEGH/issues/$1/comments" 2>/dev/null | sort -n); do head -n 1 "$FAKEGH/issues/$1/comments/$_k" | grep -q "^$2" && _c=$_k; done
  [ -z "$_c" ] || cat "$FAKEGH/issues/$1/comments/$_c"; }
am_read() { sh "$CHECKS/next.sh" read > "$T/rd" 2>&1 && sh "$CHECKS/next.sh" changes > "$T/ch" 2>&1; }
am_take_over() { _h=$(git hash-object ".vid/tw/out/issue-$1.md" | cut -c1-12)
  awk -v n="$1" -v h="$_h" '$1 == "sent" && $3 == "ticket=" n { next } $1 == "published" && $2 == n { sub(/ form=.*$/, ""); sub(/ at=[^ ]*$/, ""); $0 = $0 " taken-over=comments writing=" h " at=2026-11-18T09:00:00Z" } { print }' .vid/tw/log > "$T/lg" && cat "$T/lg" > .vid/tw/log
  rm -f ".vid/tw/form/issue-$1" ".vid/tw/body/issue-$1"; }
