#!/bin/sh
# Purpose: selftest case — a record write retries a refused rename (0.26.11.1.4, R6). lib.sh's mvr tries the rename up to 5 times, 1 s
# apart, and put renames through it. A stub mv that refuses its first 2 calls on a .put.* file: put returns 0, the record holds the new
# content whole, and no .put.* file is left. A stub mv that refuses every call: put returns non-zero, the record is as it was, and mvr
# tried 5 times. Between the refusals a reader of the record sees its old content whole. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "put-retry: $*" >&2; exit 1; }
HERE=$CHECKS; . "$CHECKS/lib.sh"
RMV=$(command -v mv); mkdir "$T/stub" "$T/a"
# the stub: on a .put.* file it counts its calls in $T/n and refuses while the count is at most FAILS (all: every call)
cat > "$T/stub/mv" <<EOF
#!/bin/sh
for a; do case "\$a" in */.put.*|.put.*) n=\$(( \$(cat "$T/n" 2>/dev/null || echo 0) + 1 )); echo "\$n" > "$T/n"
  cp "$T/a/r" "$T/seen.\$n" 2>/dev/null || true
  if [ "\$FAILS" = all ] || [ "\$n" -le "\$FAILS" ]; then echo "mv: refused (\$n)" >&2; exit 1; fi; break ;; esac; done
exec "$RMV" "\$@"
EOF
chmod +x "$T/stub/mv"; OP=$PATH
# refused twice: the third try goes in
printf 'old\n' > "$T/a/r"; rm -f "$T/n"; RC=0
( PATH="$T/stub:$OP"; FAILS=2; export FAILS; printf 'new\n' | put "$T/a/r" ) 2> "$T/err" || RC=$?
[ "$RC" = 0 ] || fail "put returned $RC on a rename refused twice: $(cat "$T/err")"
[ "$(cat "$T/a/r")" = new ] || fail "the record is not the new content whole: $(cat "$T/a/r")"
[ "$(cat "$T/n")" = 3 ] || fail "the rename was tried $(cat "$T/n") times, not 3"
for i in 1 2 3; do [ "$(cat "$T/seen.$i")" = old ] || fail "between the refusals the record read other than whole: $(cat "$T/seen.$i")"; done
[ -z "$(ls -A "$T/a" | grep '^\.put\.' || true)" ] || fail "a .put file is left beside the record: $(ls -A "$T/a")"
# refused every time: non-zero, the record as it was, 5 tries
printf 'old\n' > "$T/a/r"; rm -f "$T/n" "$T/seen".*; RC=0
( PATH="$T/stub:$OP"; FAILS=all; export FAILS; printf 'new\n' | put "$T/a/r" ) 2> "$T/err" || RC=$?
[ "$RC" != 0 ] || fail 'put returned 0 on a rename refused every time'
[ "$(cat "$T/a/r")" = old ] || fail "the record changed on a rename refused every time: $(cat "$T/a/r")"
[ "$(cat "$T/n")" = 5 ] || fail "the rename was tried $(cat "$T/n") times, not 5"
# mvr alone, on a file outside put: the source and the target as they were
printf 's\n' > "$T/a/.put.x"; printf 't\n' > "$T/a/t"; rm -f "$T/n"; RC=0
( PATH="$T/stub:$OP"; FAILS=all; export FAILS; mvr "$T/a/.put.x" "$T/a/t" ) 2> "$T/err" || RC=$?
[ "$RC" != 0 ] && [ "$(cat "$T/a/.put.x")" = s ] && [ "$(cat "$T/a/t")" = t ] || fail "mvr refused every time did not leave the source and the target as they were ($RC)"
exit 0
