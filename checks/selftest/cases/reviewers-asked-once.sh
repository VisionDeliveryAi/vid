#!/bin/sh
# Purpose: selftest case — the second-reviewer question is asked once per machine (0.26.10.29.3 phase 2, R5). With a
# fake `codex` on the PATH, `sh checks/lib/wsl.sh reviewers ask` prints the one question and nothing else; `reviewers
# record yes` writes `codex: yes` to .vid/reviewers at the main checkout and `reviewers` then prints `yes`; a second
# `ask` prints nothing; in a builder worktree `ask` prints nothing, `reviewers` prints the main checkout's `yes`, and
# nothing is written there. With no `codex` on the PATH, `ask` prints nothing and records nothing, and `reviewers`
# prints `no` whatever is recorded. `record` takes yes or no only. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "reviewers-asked-once: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'cd /; git -C "$T/p" worktree prune 2>/dev/null; rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"
WANT='A second model, Codex, is installed on this machine. May ViD use it as a second reviewer beside its own?'
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/codex" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/bin" "$T/p"; printf '#!/bin/sh\nexit 0\n' > "$T/bin/codex"; chmod +x "$T/bin/codex"
FPATH="$T/bin:$NPATH"
cd "$T/p"; git init -q; g commit -q --allow-empty -m base
Q=$(PATH=$NPATH sh "$LIB" reviewers ask) || fail 'reviewers ask exited non-zero (the script is missing or broken)'
[ -z "$Q" ] || fail "with no codex on the PATH, ask printed '$Q'"
[ ! -e .vid/reviewers ] || fail 'with no codex, ask recorded an answer'
Q=$(PATH=$FPATH sh "$LIB" reviewers ask); [ "$Q" = "$WANT" ] || fail "with codex present, ask printed '$Q', not the one question"
PATH=$FPATH sh "$LIB" reviewers record yes > /dev/null || fail 'record yes exited non-zero'
[ -f .vid/reviewers ] && [ "$(cat .vid/reviewers)" = 'codex: yes' ] || fail ".vid/reviewers does not hold 'codex: yes' after record yes"
A=$(PATH=$FPATH sh "$LIB" reviewers); [ "$A" = yes ] || fail "after record yes, reviewers printed '$A'"
A=$(PATH=$NPATH sh "$LIB" reviewers); [ "$A" = no ] || fail "with codex gone, reviewers printed '$A', not no"
Q=$(PATH=$FPATH sh "$LIB" reviewers ask); [ -z "$Q" ] || fail "a second ask printed '$Q'"
g worktree add -q "$T/wt" 2>/dev/null; cd "$T/wt"
Q=$(PATH=$FPATH sh "$LIB" reviewers ask); [ -z "$Q" ] || fail "in a builder worktree, ask printed '$Q'"
A=$(PATH=$FPATH sh "$LIB" reviewers); [ "$A" = yes ] || fail "in a builder worktree, reviewers printed '$A', not the main checkout's yes"
[ ! -e "$T/wt/.vid/reviewers" ] || fail 'the worktree got its own .vid/reviewers'
if PATH=$FPATH sh "$LIB" reviewers record maybe > /dev/null 2>&1; then fail "record took 'maybe'"; fi
[ ! -e "$T/p/.vid/windows" ] || fail 'the reviewers answer wrote .vid/windows'
echo 'reviewers-asked-once: ok'
