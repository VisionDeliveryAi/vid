#!/bin/sh
# Purpose: selftest case — a folder restored in four steps (v0.26.10.28.1, R6): land.sh's roll-back and github.sh state-restore, on the
# writer's toy and the fake gh. A stub cp, mv or rm early on the path fails one step at a time for .vid/decide: the copy beside it (1),
# the rename aside (2), the rename in (3), the removal of the old one (4). After each, .vid/decide holds its content before the restore or
# after it, whole. Killed between the two renames, .vid/decide is absent, .vid/.old.<pid>.decide holds its content whole, and the
# script's next start renames it back. The roll-back is reached by a stub git that refuses the landing's own commit in the project
# (the dry run's, in its scratch copy, goes through). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "put-restore: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
RMV=$(command -v mv); RCP=$(command -v cp); RRM=$(command -v rm); RG=$(command -v git); mkdir -p "$T/stub" "$T/tmp"
# the stubs: STOP names the step that fails; k kills the script (its parent) at the rename in
cat > "$T/stub/cp" <<EOF
#!/bin/sh
if [ "\${STOP:-}" = 1 ]; then for a; do :; done; case "\$a" in *.put.*.decide) exit 1 ;; esac; fi
exec "$RCP" "\$@"
EOF
cat > "$T/stub/mv" <<EOF
#!/bin/sh
case "\${STOP:-}" in
  2) case "\${2:-}" in *.old.*.decide) exit 1 ;; esac ;;
  3) case "\${1:-}" in *.put.*.decide) exit 1 ;; esac ;;
  k) case "\${1:-}" in *.put.*.decide) kill -9 "\$PPID"; exit 1 ;; esac ;;
esac
exec "$RMV" "\$@"
EOF
cat > "$T/stub/rm" <<EOF
#!/bin/sh
if [ "\${STOP:-}" = 4 ]; then for a; do case "\$a" in *.old.*.decide) exit 1 ;; esac; done; fi
exec "$RRM" "\$@"
EOF
cat > "$T/stub/git" <<EOF
#!/bin/sh
if [ -n "\${NOCOMMIT:-}" ]; then for a; do [ "\$a" = commit ] && [ "\$(pwd -P)" = "\$NOCOMMIT" ] && exit 1; done; fi
exec "$RG" "\$@"
EOF
chmod +x "$T/stub/cp" "$T/stub/mv" "$T/stub/rm" "$T/stub/git"
sum() { [ -d "$1" ] || { echo absent; return 0; }; (cd "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$f" "$(cksum < "$f")"; done); }
is() { sum .vid/decide > "$T/now"; cmp -s "$T/now" "$T/$1"; }
old1() { w=$1; set -- .vid/.old.*.decide; [ $# = 1 ] && [ -d "$1" ] || fail "killed between the renames, not one .vid/.old.<pid>.decide: $*"; sum "$1" > "$T/now"; cmp -s "$T/now" "$T/$w"; }
tw_toy "$T/toy"; P0=$(pwd -P); tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
tw_start S02 || fail "S02 was refused: $(cat "$T/start")"; tw_post step S02 || fail "S02's ticket: $(cat "$T/werr")"
LS=$CHECKS/land.sh; GS=$CHECKS/github.sh
# land.sh's roll-back: a zero-row module-table draft, its landing's own commit refused, so back() restores .vid/decide
printf 'none\n' > "$T/rv"; sed 's/^| web | the pages |/| web | the pages and the operator pages |/' ARCHITECTURE.md > "$T/a"; ! cmp -s "$T/a" ARCHITECTURE.md || fail 'no module-table edit'; cp "$T/a" ARCHITECTURE.md
sh "$LS" draft --review "$T/rv" --why 'the module table' > "$T/out" 2>&1 || fail 'the draft failed'; N=$(sed -n 's/^draft \([0-9][0-9]*\)$/\1/p' "$T/out"); [ -n "$N" ] || fail 'no draft number'
sh "$CHECKS/queue.sh" control continue 'go on' > /dev/null 2>&1 || true
for f in counts limits halted record state rulings landed; do touch ".vid/decide/$f"; done; sum .vid/decide > "$T/before"
ld() { git reset -q -- ARCHITECTURE.md 2>/dev/null || true; git checkout -q -- ARCHITECTURE.md 2>/dev/null || true; rm -rf .vid/.old.* .vid/.put.*
  RC=0; PATH="$T/stub:$PATH" STOP=$1 NOCOMMIT=$P0 TMPDIR="$T/tmp" sh "$LS" "$N" --words 'Yes, the module table' > "$T/out" 2>&1 || RC=$?; }
# a step that fails leaves the live folder whole: rolled back, or the restore refused with its backup kept and said so
for s in 1 2 3 4; do ld "$s"; [ "$RC" = 2 ] && { grep -q 'rolled back' "$T/out" || { kb=$(sed -n 's/.*their backup is kept in \([^ ]*\) (bk-\*).*/\1/p' "$T/out"); [ -n "$kb" ] && [ -d "$kb/bk-decide" ] && rm -rf "$kb"; }; } || fail "the landing stopped at its roll-back's step $s was neither rolled back nor kept its backup ($RC)"
  is before || fail "the roll-back stopped at step $s: .vid/decide is not whole"; done
ld k; [ "$RC" != 0 ] || fail 'a roll-back killed between its renames went on'; [ ! -e .vid/decide ] || fail 'killed between the renames, .vid/decide is there'
old1 before || fail "the roll-back's old folder is not whole"
sh "$LS" > "$T/out" 2>&1 || true; is before || fail "land.sh's next start did not rename the old folder back"; [ -z "$(ls -d .vid/.old.* 2>/dev/null)" ] || fail 'the old folder is still beside it'
git reset -q -- ARCHITECTURE.md 2>/dev/null || true; git checkout -q -- ARCHITECTURE.md 2>/dev/null || true
# github.sh state-restore: saved, then changed, then restored with each step failed
sh "$GS" state-save > "$T/out" 2>&1 || fail 'state-save failed'; sum .vid/decide > "$T/saved"
mkdir -p .vid/decide/rows; printf 'b\n' > .vid/decide/counts; printf 'two\n' > .vid/decide/rows/ROW-002.txt; sum .vid/decide > "$T/live"; cp -R .vid/decide "$T/live-copy"
cmp -s "$T/saved" "$T/live" && fail 'the change made no difference to see'
gr() { rm -rf .vid/decide .vid/.old.* .vid/.put.*; cp -R "$T/live-copy" .vid/decide; rm -f .vid/state-at
  RC=0; PATH="$T/stub:$PATH" STOP=$1 TMPDIR="$T/tmp" sh "$GS" state-restore > "$T/out" 2>&1 || RC=$?; }
for s in 1 2 3; do gr "$s"; [ "$RC" != 0 ] || fail "a restore stopped at step $s went on"; is live || fail "a restore stopped at step $s: .vid/decide is not its content before, whole"
  [ -z "$(ls -d .vid/.old.* 2>/dev/null)" ] || fail "a restore stopped at step $s left an old folder"; done
gr 4; [ "$RC" != 0 ] || fail 'a restore stopped at step 4 went on'; is saved || fail 'a restore stopped at step 4: .vid/decide is not the saved content, whole'
gr k; [ "$RC" != 0 ] || fail 'a restore killed between its renames went on'; [ ! -e .vid/decide ] || fail 'killed between the renames, .vid/decide is there'
old1 live || fail "the restore's old folder is not whole"
sh "$GS" > "$T/out" 2>&1 || true; is live || fail "github.sh's next start did not rename the old folder back"; [ -z "$(ls -d .vid/.old.* 2>/dev/null)" ] || fail 'the old folder is still beside it'
exit 0
