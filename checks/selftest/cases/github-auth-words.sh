#!/bin/sh
# Purpose: selftest case — the GitHub check names what failed (low-1, R4). ViD's own `refused —` line, the one the round quotes, read
# alone: with no gh on PATH, tw-sync and round-read say gh is not found and never "log in"; with a gh whose auth status prints gh's
# real failure lines (a bad token, its login advice) and exits 1, the line is the neutral one, with no "log in"; with the fake gh's
# "not logged into any", it says "log in" as before. gh's own words stay printed above it, indented. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "github-auth-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/tickets.sh"
P0=$PATH; gh_fake; mkdir -p "$T/v/.vid/tw"; cd "$T/v"; : > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
ref() { RC=0; PATH=$1 sh "$CHECKS/github.sh" "$2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail "$2 exited $RC"; L=$(grep '^ViD github: refused — ' "$T/out" || true); [ -n "$L" ] || fail "$2 gave no refused line"; }
# no gh on PATH: every command of the PATH but gh, linked into one folder
mkdir "$T/nogh"; IFS=:; for d in $P0; do [ -d "$d" ] || continue; for f in "$d"/*; do b=${f##*/}; [ "$b" != gh ] && [ -x "$f" ] && [ ! -e "$T/nogh/$b" ] && ln -s "$f" "$T/nogh/$b" 2>/dev/null || true; done; done; unset IFS
for s in tw-sync round-read; do ref "$T/nogh" "$s"; case $L in *'log in'*) fail "$s, no gh: the refusal says log in" ;; esac
  case $L in *'gh is not found on'*PATH*) ;; *) fail "$s, no gh: the refusal does not say gh is not found" ;; esac; done
# gh's real failure lines, as it prints them for a bad token and for a network failure alike
mkdir "$T/realgh"; cat > "$T/realgh/gh" <<'G'
#!/bin/sh
printf 'github.com\n  X Failed to log in to github.com account someone (keyring)\n  - Active account: true\n  - The token in keyring is invalid.\n  - To re-authenticate, run: gh auth login -h github.com\n  - To forget about this account, run: gh auth logout -h github.com -u someone\n' >&2
exit 1
G
chmod +x "$T/realgh/gh"
ref "$T/realgh:$P0" tw-sync; case $L in *'log in'*) fail 'the real failure lines: the refusal says log in' ;; esac
case $L in *'gh auth status failed (its words above)'*) ;; *) fail 'the real failure lines: not the neutral refusal' ;; esac
grep -qx '      X Failed to log in to github.com account someone (keyring)' "$T/out" || fail "gh's own words are not printed above, indented"
# not logged into any: the message as before
: > "$T/gh/auth-fail"; ref "$PATH" tw-sync; case $L in *'log in'*) ;; *) fail 'not logged into any: the refusal lacks log in' ;; esac
grep -q '^    You are not logged into any GitHub hosts' "$T/out" || fail "gh's own words are not printed above, indented"
echo 'github-auth-words: ok'
