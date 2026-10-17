#!/bin/sh
# Purpose: selftest case — the law-commit self-test is isolated from git's
# hook environment (v0.9.4 fix). pre-commit runs checks/selftest/run.sh on
# every law commit, and git exports repository variables to the hooks it
# runs: in a linked worktree an absolute GIT_DIR and GIT_INDEX_FILE, under
# `git -c … commit` GIT_CONFIG_PARAMETERS. A fake repository with a linked
# worktree stands in for the project; a copy of run.sh runs one case of the
# shipped shape (git init, add and commit in its own scratch directory) with
# GIT_DIR and GIT_INDEX_FILE planted at the fake worktree and
# GIT_CONFIG_PARAMETERS naming a hook directory inside the fake. Convicts
# unless the fake's shared config (core.bare with it), refs, worktree index
# and worktree HEAD come back byte-identical, the planted hook never runs,
# and the scratch case runs green. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q fake
( cd fake && printf 'x\n' > f && git add f && git -c user.email=vid@selftest -c user.name=vid commit -qm root && git worktree add -q ../wt -b wt )
W="$T/fake/.git/worktrees/wt"
mkdir -p fake/planted-hooks
printf '#!/bin/sh\n: > "%s/planted-hook-ran"\n' "$T" > fake/planted-hooks/pre-commit
chmod +x fake/planted-hooks/pre-commit
state() { cksum < fake/.git/config; git -C fake config --get core.bare; git -C fake for-each-ref; cksum < "$W/index"; cat "$W/HEAD"; }
BEFORE=$(state)
mkdir -p checks/selftest/cases
cp "$CHECKS/selftest/run.sh" checks/selftest/
cat > checks/selftest/cases/scratch-git.sh <<'EOF'
#!/bin/sh
# Purpose: a case of the shipped shape — git init, add and commit in its own scratch directory
set -eu
S=$(mktemp -d); trap 'rm -rf "$S"' EXIT
cd "$S"; git init -q; printf 'y\n' > g; git add g
git -c user.email=vid@selftest -c user.name=vid commit -qm scratch
EOF
ST=0
GIT_DIR="$W" GIT_INDEX_FILE="$W/index" GIT_CONFIG_PARAMETERS="'core.hooksPath'='$T/fake/planted-hooks'" \
  sh checks/selftest/run.sh >out.txt 2>&1 || ST=$?
[ "$(state)" = "$BEFORE" ] || { echo 'hook-env: the fake repository changed under the planted variables' >&2; exit 1; }
[ ! -e planted-hook-ran ] || { echo 'hook-env: GIT_CONFIG_PARAMETERS reached a case' >&2; exit 1; }
[ "$ST" -eq 0 ] || { echo 'hook-env: the scratch case failed' >&2; cat out.txt >&2; exit 1; }
grep -q '^selftest: 1/1 courts convict$' out.txt || exit 1
exit 0
