#!/bin/sh
# Pushes one report folder as its own branch, vid-results/<id>, holding that folder and nothing else.
# It never touches your working branch: the branch is made in a new, empty folder each time.
#
#   sh push-report.sh <code repository's address> <report folder>
#
#   <report folder>  a folder named by the report's id, such as red-7-1: results.txt and its cases files for a test
#                    report, grade.txt for a grade, sorted.txt for a sort
set -eu
[ $# -eq 2 ] || { echo "usage: sh push-report.sh <code repository's address> <report folder>" >&2; exit 2; }
remote=$1 src=$(cd "$2" && pwd); id=$(basename "$src")
[ -f "$src/results.txt" ] || [ -f "$src/grade.txt" ] || [ -f "$src/sorted.txt" ] || { echo "$src holds no results.txt, grade.txt or sorted.txt" >&2; exit 2; }
tmp=$(mktemp -d "${TMPDIR:-/tmp}/jobdigest-report.XXXXXX"); trap 'rm -rf "$tmp"' EXIT
cp -R "$src" "$tmp/$id"
cd "$tmp"
git init -q
git add "$id"
git -c user.name="${GIT_AUTHOR_NAME:-$(git config user.name || echo dev)}" -c user.email="${GIT_AUTHOR_EMAIL:-$(git config user.email || echo dev@example.invalid)}" commit -qm "$id"
git push -q "$remote" "HEAD:refs/heads/vid-results/$id"
echo "pushed vid-results/$id"
