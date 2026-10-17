#!/bin/sh
# Purpose: selftest case — certificates under concurrent runs (v0.9.7.3 spec 3.6, R6). Two worktrees run the suite at
# once with the same key: one certificate, reading `pass <key>`, and no private file left; with different keys (a
# skills/ file differs): two certificates. A key input changed during the run (a skills/ file edited while the suite
# runs) publishes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/cert.sh"
fail() { echo "selftest-cert-concurrent: $*" >&2; cat "$T/out" "$T/out.b" >&2 2>/dev/null; exit 1; }
ct_repo "$T/main"; C=$(ct_cert)
git worktree add -q "$T/b" -b b 2>/dev/null; mkdir -p "$T/b/.ran" "$T/b/.fail"
printf 'sleep 2\n' > "$T/hook-in.sh"
both() { ct_row "$1"; ( cd "$T/b" && ct_row "$1" )
  ( sh checks/hooks/pre-commit > "$T/out" 2>&1; echo $? > "$T/st.a" ) & A=$!
  ( cd "$T/b" && sh checks/hooks/pre-commit > "$T/out.b" 2>&1; echo $? > "$T/st.b" ) & B=$!
  wait "$A" "$B"; [ "$(cat "$T/st.a")" = 0 ] && [ "$(cat "$T/st.b")" = 0 ] || fail 'a concurrent law commit was refused'
  g commit -qm "a $1" --no-verify; ( cd "$T/b" && g commit -qm "b $1" --no-verify ); }
both 2
[ "$(ls -A "$C" | grep -c .)" = 1 ] || fail 'same key: not exactly one entry (a private file left?)'
K=$(ls "$C"); [ "$(cat "$C/$K")" = "pass $K" ] || fail 'same key: the certificate is not whole'
rm -rf "$C"; printf '# another skill text\n' > "$T/b/skills/one.md"
both 3
[ "$(ls -A "$C" | grep -c .)" = 2 ] || fail 'different keys: not two certificates'
for k in $(ls "$C"); do [ "$(cat "$C/$k")" = "pass $k" ] || fail "different keys: $k is not whole"; done
# a key input changed during the run
rm -rf "$C"; printf 'printf "# edited during the run\\n" >> "%s/main/skills/one.md"\n' "$T" > "$T/hook-in.sh"
ct_row 4; ct_law 'an input changed mid-run'
[ -z "$(ls "$C" 2>/dev/null)" ] || fail 'a run whose key input changed published a certificate'
exit 0
