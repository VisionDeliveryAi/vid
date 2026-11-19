#!/bin/sh
# Purpose: selftest case — one token boundary in share.sh (0.26.11.1.2, R1). Every token kind (github, anthropic,
# openai, stripe, aws, slack, google, npm, jwt) and a bare user name are planted in a record right after each boundary form:
# the text's start, a space, \b \f \n \r \t, “, \xe2\x80\x9c, a colour code (\u001b[1;31m, a raw escape byte and
# [0m, \x1b[31m), %22, and a raw curly quote (a control: its last byte is no word character, so it was always a boundary).
# Convicts unless each becomes [REDACTED:<kind>] with its prefix kept, none of those values is left in the bundle, a token
# or a name inside a word (a letter or a digit right before it) stays as it is, and share.sh holds one boundary function,
# used by the tokens and the names alike, with no fixed count of last characters (no lastc). The values are built from
# pieces at run time, never written whole here. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-token-boundary: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
S=$CHECKS/share.sh
U=Users; HN=river
export HOME="$T/h/$U/$HN"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
printf '[user]\n\temail = b@example.test\n\tname = Bo\n' > "$T/gitconfig"; export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes"; cp "$S" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
rep() { awk -v c="$1" -v n="$2" 'BEGIN { for (i = 0; i < n; i++) printf "%s", c }'; }
# tok <filler>: one value of each kind, `<kind> <value>` a line, made of the filler
tok() { f=$1
  printf 'github-token gh%s_%s\n' p "$(rep "$f" 24)"
  printf 'anthropic-key sk-%s-%s\n' ant "$(rep "$f" 24)"
  printf 'openai-key sk-%s-%s\n' proj "$(rep "$f" 34)"
  printf 'stripe-key sk_%s_%s\n' live "$(rep "$f" 16)"
  printf 'aws-key AK%s%s\n' IA "$(rep "$f" 16)"
  printf 'slack-token xo%s-%s\n' xb "$(rep "$f" 12)"
  printf 'google-key AI%s%s\n' za "$(rep "$f" 35)"
  printf 'npm-token np%s_%s\n' m "$(rep "$f" 36)"
  printf 'jwt ey%s%s.ey%s%s.%s\n' J "$(rep "$f" 10)" J "$(rep "$f" 10)" "$(rep "$f" 8)"
}
ESC=$(printf '\033'); CQ=$(printf '\342\200\234')
# the boundary forms, one a line: a tag, then the prefix
cat > "$T/pre" <<EOF
sp
bs \\b
ff \\f
nl \\n
cr \\r
ht \\t
u4 \\u201c
x2 \\xe2\\x80\\x9c
cu \\u001b[1;31m
ce ${ESC}[0m
cx \\x1b[31m
pc %22
cq ${CQ}
EOF
: > "$T/rec"; : > "$T/want"
tok Q > "$T/tq"; tok K > "$T/tk"
while IFS=' ' read -r k v; do
  printf '%s\n' "$v" >> "$T/rec"; printf '%s\n' "[REDACTED:$k]" >> "$T/want"   # at the text's start
  while IFS= read -r l; do tg=${l%% *}; p=${l#* }; [ "$tg" = sp ] && p=' '
    printf 'L %s%s end\n' "$p" "$v" >> "$T/rec"; printf 'L %s[REDACTED:%s] end\n' "$p" "$k" >> "$T/want"
  done < "$T/pre"
done < "$T/tq"
# inside a word: a letter or a digit right before; kept as it is
while IFS=' ' read -r k v; do printf 'W z%s end\nW 7%s end\n' "$v" "$v" >> "$T/rec"; printf 'W z%s end\nW 7%s end\n' "$v" "$v" >> "$T/want"; done < "$T/tk"
# the bare name after each boundary form (the 0.26.10.28.9 forms and the new ones), and inside a word
while IFS= read -r l; do tg=${l%% *}; p=${l#* }; [ "$tg" = sp ] && p=' '
  printf 'N %s%s end\n' "$p" "$HN" >> "$T/rec"; printf 'N %s[REDACTED:user-name] end\n' "$p" >> "$T/want"
done < "$T/pre"
printf 'N z%s end\n' "$HN" >> "$T/rec"; printf 'N z%s end\n' "$HN" >> "$T/want"
cp "$T/rec" .vid/notes/text.txt
sh checks/share.sh build --run 2026-11-b --leave-out conversations > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
G=.vid/shares/2026-11-b/records/.vid/notes/text.txt; [ -f "$G" ] || fail 'no record in the bundle'
if ! cmp -s "$T/want" "$G"; then
  diff "$T/want" "$G" | sed -n '1,30p' | cat -v >&2; fail 'a token or a name after a boundary is left, or one inside a word was redacted'
fi
while IFS=' ' read -r k v; do N=$(grep -rcF -- "$v" .vid/shares | awk -F: '{ s += $NF } END { print s + 0 }'); [ "$N" = 0 ] || fail "$k: a planted value is left on $N lines"; done < "$T/tq"
# one rule: one bnd, no lastc, the names' rw calls it, the tokens' tok calls it
[ "$(grep -c '^function bnd(' "$S")" = 1 ] || fail 'share.sh does not hold exactly one bnd'
! grep -q 'lastc' "$S" || fail 'share.sh still keeps a fixed count of last characters (lastc)'
body() { awk -v f="$1" '$0 ~ "^function " f "[(]" { on = 1; print; next } on && /^function / { exit } on' "$S"; }
body rw | grep -q 'bnd(' || fail "the names' rw does not use bnd"
body tok | grep -q 'bnd(' || fail "the tokens' tok does not use bnd"
N=$(grep -c '"%"' "$S" || true); [ "$N" = 1 ] || fail "share.sh holds the %XX boundary on $N lines, not one"
echo 'share-token-boundary: ok'
