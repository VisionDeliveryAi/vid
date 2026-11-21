#!/bin/sh
# Purpose: selftest case — one door, its text once (GM-4 F9, A10). The door's text stands in vid-fix's ticket-mode branch alone: the
# draft asked through the queue (`queue.sh ask draft <n>`), landed by the owner's yes through vid-answer, a stale draft drafted again
# with `--replaces <n>`, and GitHub manual's one difference (no plan block; the change waits as pending until the apply, GM M3),
# named by its ruling. vid-add, vid-stage and vid-incorporate each name that branch where they draft, keep only what is their own
# (what they write, their `--why` mark), and hold no copy: no ask of their own, no landing, no stale draft, no "in place of the
# queue's ask". The run skill names the door where a change to rows comes through it, and holds none of the door's lines: the
# draft, the ask and the landing are vid-fix's, as are the lines a landing prints. Reads skills/: skipped in a project's layout.
# Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-fix" ] && [ -d "$S/vid-run" ] || { echo 'door-once: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "door-once: $*" >&2; exit 1; }
F=$S/vid-fix/SKILL.md; R=$S/vid-run/SKILL.md
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
one() { tr '\n' ' ' < "$1" | tr -s ' '; }
# the door's text, in vid-fix's ticket-mode branch
awk '/^\*\*Ticket mode \(v0\.26\.10\.25\.5, R1\)/ { on = 1 } on && /^\*\*Stage events/ { exit } on' "$F" | tr '\n' ' ' | tr -s ' ' > "$T/door"
[ -s "$T/door" ] || fail 'vid-fix has no ticket-mode branch'
for p in 'sh checks/queue.sh ask draft <n>' 'vid-answer' '--replaces <n>' 'GM M3' 'devagent-start.sh" mode' 'no plan block' 'landed <n> at <commit>'; do
  grep -qF -- "$p" "$T/door" || fail "the door in vid-fix's ticket-mode branch lacks: $p"; done
# each verb that drafts names the door, and holds no copy of it
for k in vid-add vid-stage vid-incorporate; do G=$S/$k/SKILL.md; [ -f "$G" ] || fail "there is no $k skill"
  one "$G" | grep -qF "the vid-fix skill's ticket-mode branch" || fail "$k does not name the door, the vid-fix skill's ticket-mode branch"
  for p in 'queue.sh ask draft' "in place of the queue's ask" 'sh checks/land.sh <n> --words' 'drafted again, `--replaces <n>`' 'lands it in `/vid run`' 'lands it in /vid:vid-run' 'lands it in /vid run'; do
    ! one "$G" | grep -qF -- "$p" || fail "$k still holds the door's text: $p"; done; done
# the door's lines in vid-fix alone among the drafting verbs and the run skill
for p in 'sh checks/queue.sh ask draft <n>' "\`queue.sh answer Q<n> yes \"<their words>\"\` runs \`sh checks/land.sh <n>\`" 'a dry run on a scratch copy first' '`next` exports it and writes the new tickets'; do
  ! one "$R" | grep -qF -- "$p" || fail "the run skill still holds the door's text: $p"; done
grep '^\*\*A change to rows during the run\*\*' "$R" | grep -qF "the vid-fix skill's ticket-mode branch" || fail 'the run skill does not send a change to rows through the vid-fix door'
for r in '| `door: /vid fix — …` |' '| `landed <n> at <commit>: …`'; do [ "$(grep -cF -- "$r" "$R")" = 1 ] || fail "the run skill has no one row $r"
  grep -F -- "$r" "$R" | grep -q 'vid-fix' || fail "the run skill's row $r does not name vid-fix"; done
echo 'door-once: ok'
