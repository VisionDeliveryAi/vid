#!/bin/sh
# Runs the tests of one commit, from a clean copy of it, in a fresh test environment, and writes the XML test report.
#
#   sh run-tests.sh <code repository folder> <commit> <report folder> [-k "<pytest selection>"] [--fault <patch>]
#
#   <report folder>   gets cases-chromium.xml (created if missing; an existing report there is replaced)
#   -k                runs only the tests whose names match, as pytest's -k does: -k "ROW_006 or ROW_003"
#   --fault <patch>   applies the patch to the clean copy first (a deliberate break), then runs
#
# Exit 0 when every test passed, 1 when some failed, 2 when the run itself could not be made.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
usage() { echo "usage: sh run-tests.sh <code repository folder> <commit> <report folder> [-k \"<selection>\"] [--fault <patch>]" >&2; exit 2; }
[ $# -ge 3 ] || usage
repo=$1 commit=$2 out=$3; shift 3
selection='' fault=''
while [ $# -gt 0 ]; do
  case $1 in
    -k) [ $# -ge 2 ] || usage; selection=$2; shift 2 ;;
    --fault) [ $# -ge 2 ] || usage; fault=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); shift 2 ;;
    *) usage ;;
  esac
done
engine=chromium
full=$(git -C "$repo" rev-parse --verify "$commit^{commit}") || { echo "no such commit: $commit" >&2; exit 2; }
mkdir -p "$out"; out=$(cd "$out" && pwd)

# the images, fetched and built once; the only step that fetches anything.
# The fakes run on the base image by name, so it must be on the machine under that name, not only in the build cache.
docker image inspect python:3.12-slim-bookworm > /dev/null 2>&1 || docker pull -q python:3.12-slim-bookworm > /dev/null
docker image inspect jobdigest-lab-product > /dev/null 2>&1 || docker build -q -t jobdigest-lab-product -f "$here/product.Dockerfile" "$here"
docker image inspect jobdigest-lab-tests > /dev/null 2>&1 || docker build -q -t jobdigest-lab-tests -f "$here/tests.Dockerfile" "$here"

# a clean copy of the commit: what is committed, nothing else
work=$(mktemp -d "${TMPDIR:-/tmp}/jobdigest-run.XXXXXX")
project="jobdigest-$(basename "$work" | tr -cd 'a-zA-Z0-9' | tr 'A-Z' 'a-z')"
cleanup() { docker compose -p "$project" -f "$here/compose.yml" --profile product --profile tests down -v --remove-orphans -t 5 > /dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT INT TERM
mkdir "$work/checkout"
git -C "$repo" archive "$full" | tar -x -C "$work/checkout"
if [ -n "$fault" ]; then
  (cd "$work/checkout" && patch -p1 --quiet < "$fault") || { echo "the fault $fault does not apply to $full" >&2; exit 2; }
  echo "fault planted: $(basename "$fault")"
fi
chmod -R a+rX "$work"

export CHECKOUT="$work/checkout" OUT="$out" ENGINE="$engine" SELECTION="$selection"
compose() { docker compose -p "$project" -f "$here/compose.yml" "$@"; }
if [ -f "$work/checkout/Procfile" ]; then
  export PRODUCT_URL=http://product:8000
  if ! compose --profile product up -d --wait mail feed product > "$work/up.log" 2>&1; then
    echo "setup: the product did not start; its log:" >&2; compose --profile product logs --no-color product >&2 || true; exit 2
  fi
else
  export PRODUCT_URL=''   # no product yet: every test that needs it fails with a message that begins setup:
  compose up -d --wait mail feed > "$work/up.log" 2>&1 || { echo "setup: the fakes did not start" >&2; cat "$work/up.log" >&2; exit 2; }
fi
rm -f "$out/cases-$engine.xml"
set +e
compose --profile tests run --rm --no-deps tests
status=$?
set -e
[ -f "$out/cases-$engine.xml" ] || { echo "setup: no report was written" >&2; exit 2; }
echo "commit: $full"
echo "report: $out/cases-$engine.xml"
[ $status -eq 0 ] && exit 0 || exit 1
