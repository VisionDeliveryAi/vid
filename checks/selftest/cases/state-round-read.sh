#!/bin/sh
# Purpose: selftest case — the one read in the saved records, in GitHub manual alone (GM-4 F3, I2; GM-2 T12; GM-4 §1). On the toy,
# with .vid/round/ holding the call's read, the read before it and the round's other files. In GitHub auto neither is saved: a
# save after a new round read, nothing else changed, says the records are as saved, and a restore into an empty folder brings no
# .vid/round/read or .vid/round/read.prev back. In GitHub manual, state-save then state-restore <repo> into an empty folder gives
# .vid/round/read and .vid/round/read.prev back byte for byte and nothing else of .vid/round/. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "state-round-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
tw_toy "$T/toy"; GS=$CHECKS/github.sh; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$GS" state-restore > "$T/out" 2>&1 || fail 'a first session was refused'
# rd <tag>: the read, the read before it and the round's other files, each holding the tag
rd() { mkdir -p .vid/round/wait; printf 'ticket%s7%sOPEN%s-%s%s\nbody%s7%sthe body, %s\n' "$TB" "$TB" "$TB" "$TB" "$1" "$TB" "$TB" "$1" > .vid/round/read
  printf 'ticket%s7%sOPEN%s-%sbefore %s\n' "$TB" "$TB" "$TB" "$TB" "$1" > .vid/round/read.prev; printf 'tick %s\n' "$1" > .vid/round/last; printf 'w %s\n' "$1" > .vid/round/wait/a; }
# back <dir>: the restore into the empty folder <dir> holds the two files as saved, and nothing else of .vid/round/
back() { cp .vid/round/read "$T/r"; cp .vid/round/read.prev "$T/rp"; mkdir "$1"; cd "$1"
  sh "$GS" state-restore owner/code-spec > "$T/out" 2>&1 || fail "state-restore into $2 failed"
  cmp -s "$T/r" .vid/round/read || fail "$2: .vid/round/read did not come back as saved"
  cmp -s "$T/rp" .vid/round/read.prev || fail "$2: .vid/round/read.prev did not come back as saved"
  ( cd .vid/round && find . -type f -o -type d ) | sort > "$T/got"; printf '.\n./read\n./read.prev\n' > "$T/want"
  cmp -s "$T/want" "$T/got" || { cp "$T/got" "$T/out"; fail "$2: the restore brought back more of .vid/round/ than the read and the read before it"; }; }
# GitHub auto: neither saved; a new round read alone is nothing to save
rd auto; sh "$GS" state-save > "$T/out" 2>&1 || fail 'state-save failed in GitHub auto'
rd 'auto, a newer round read'; sh "$GS" state-save > "$T/out" 2>&1 || fail 'a second state-save failed in GitHub auto'
grep -q 'as saved' "$T/out" || fail 'GitHub auto: a save after a new round read alone pushed the records'
mkdir "$T/a2"; cd "$T/a2"; sh "$GS" state-restore owner/code-spec > "$T/out" 2>&1 || fail 'state-restore into GitHub auto failed'
[ ! -e .vid/round/read ] && [ ! -e .vid/round/read.prev ] || fail 'GitHub auto: the restore brought the round read back, so it was saved'
# GitHub manual: the owner's answer, a read, saved and restored
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-04T09:00:00Z\n' >> .vid/plan/setup
rd manual; sh "$GS" state-save > "$T/out" 2>&1 || fail 'state-save failed in GitHub manual'
back "$T/m2" 'GitHub manual'
grep -q 'manual' .vid/round/read || fail 'GitHub manual: the restore brought back another read'
exit 0
