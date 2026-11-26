#!/bin/sh
# Purpose: selftest fixture — the share's toy (0.26.10.28.7, R6), made-up names alone: sh_toy <dir> makes a project home there
# with github.sh and lib.sh in its checks/, and beside them a stand-in share.sh whose scan exits 1, naming the file and the
# kind, when a file of the folder holds the word PLANTED-VALUE, and 0 otherwise (the real one is half A's); a bundle folder
# .vid/shares/2026-11-local-toy/ in FORMAT.md's layout; git config naming a person, and that person in the environment's
# GIT_AUTHOR_* and GIT_COMMITTER_*; the share's fake gh first on PATH, its state $SHAREGH: the login quill-tester, the
# accounts bramble-reader (User) and quill-labs (Organization), quill-labs owned by the login. It enters the home.
# sh_repo <owner/name> <private> [org]: a repository already there. sh_calls: the calls logged since the mark sh_mark took.
sh_toy() {
  mkdir -p "$1/home/checks" "$1/bin" "$1/gh/users" "$1/gh/orgs/quill-labs" "$1/gh/repos"
  cp "$CHECKS/github.sh" "$CHECKS/lib.sh" "$1/home/checks/"
  printf '#!/bin/sh\n# stand-in scanner\n[ "$1" = scan ] && [ -d "$2" ] || exit 2\nf=$(grep -rl PLANTED-VALUE "$2" | head -n 1)\n[ -z "$f" ] || { echo "scan: ${f#$2/}: kind planted" >&2; exit 1; }\nexit 0\n' > "$1/home/checks/share.sh"
  cp "$CHECKS/selftest/fixtures/share-gh" "$1/bin/gh"; chmod +x "$1/bin/gh"
  SHAREGH=$1/gh; export SHAREGH; PATH="$1/bin:$PATH"; export PATH
  echo quill-tester > "$SHAREGH/login"; echo User > "$SHAREGH/users/bramble-reader"; echo User > "$SHAREGH/users/ferngrove"
  echo Organization > "$SHAREGH/users/quill-labs"; echo 'active admin' > "$SHAREGH/orgs/quill-labs/quill-tester"; : > "$SHAREGH/log"
  cd "$1/home" && git init -q && git config user.name 'Jane Q Ferrow' && git config user.email 'jane.ferrow@example.org'
  GIT_AUTHOR_NAME='Jane Env'; GIT_AUTHOR_EMAIL='jane.env@example.org'; GIT_COMMITTER_NAME='Jane Env'; GIT_COMMITTER_EMAIL='jane.env@example.org'
  export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  B=.vid/shares/2026-11-local-toy; mkdir -p "$B/records" "$B/findings" "$B/conversations"
  printf '# Run\n\n- project: toy\n' > "$B/RUN.md"; printf '# Findings\n\nNo findings file.\n' > "$B/FINDINGS.md"
  printf '{"format": 1}\n' > "$B/MANIFEST.json"; printf '# Manifest\n' > "$B/MANIFEST.md"; printf 'round 1\n' > "$B/records/round.log"
  printf '# Index\n' > "$B/conversations/INDEX.md"
}
sh_repo() { _d=$SHAREGH/repos/$(printf '%s' "$1" | tr '/' '%'); mkdir -p "$_d/collab" "$_d/invitations"; git init -q --bare "$_d/remote.git"
  git -C "$_d/remote.git" symbolic-ref HEAD refs/heads/main; echo "$2" > "$_d/private"; echo "${3:-false}" > "$_d/org"; }
sh_dir() { printf '%s/repos/%s' "$SHAREGH" "$(printf '%s' "$1" | tr '/' '%')"; }
sh_mark() { _m=$(wc -l < "$SHAREGH/log" | tr -d ' '); }
sh_calls() { sed -n "$((_m + 1)),\$p" "$SHAREGH/log"; }
