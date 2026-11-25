#!/bin/sh
# Purpose: selftest case — which commit's spec a folder holds (FB-4 B1: lib.sh's folderis and foldersay), on a scratch repository of five
# commits and a kept `.vid/round/folder` written by hand. A folder holding a commit's files is that commit; two files alone, a range,
# newest first; a commit of a side branch merged back is found; a file changed by hand, or two commits' files, is `none`; an export's
# blanked copy is the commit the log's export line names, and the commits with the same files as it; an applied commit HEAD does not
# reach is found too; a README, a design/ folder, a stamp and a PRD.md deeper down are never compared; no PRD.md at the top is `absent`; a
# kept read of another folder, none kept, layout separate and GitHub auto say nothing. The words: a folder that holds the applied
# version's files is never said to differ, a take-over commit's among them; one that differs names its commit and --applied. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "folder-is: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t'); mkdir "$T/p"; cd "$T/p"; git init -q; printf '.vid/\n' > .gitignore
put_() { for f in "$@"; do printf '%s of %s\n' "$f" "$M" > "$f"; done; git add -A; g commit -qm "$M"; git rev-parse HEAD; }
M=first; C0=$(put_ PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md INVENTORY.md STAGES.md README.md)
M=second; C1=$(put_ PRD.md INVENTORY.md); M=third; C2=$(put_ DECISIONS.md)
b=$(git symbolic-ref --short HEAD); git checkout -qb side "$C1"; M=side; CS=$(put_ BASELINE.md); git checkout -q "$b"; g merge -q --no-ff -s ours -m 'the side branch merged' side
M=fourth; C3=$(put_ PRD.md)
mkdir -p .vid/round .vid/plan .vid/tw; printf 'layout: one\nspec-path: upstream/vid/\n' > .vid/tw/settings
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-19T09:00:00Z\n' > .vid/plan/setup
head_() { printf 'main\t%s\towner/code\t%s\n' 0123456789abcdef0123456789abcdef01234567 "${1:-upstream/vid}" > .vid/round/folder; }
add_() { _c=$1; shift; for f in "$@"; do printf '%s\t%s\n' "$(git rev-parse "$_c:$f")" "$f" >> .vid/round/folder; done; }
ids() { printf '%s\t%s\n' "$(printf '%s\n' "$2" | git hash-object --stdin)" "$1" >> .vid/round/folder; }
is_() { sh -c '. "$1/lib.sh"; folderis' x "$CHECKS" > "$T/out" 2>&1 || fail "folderis failed ($2)"; [ "$(cat "$T/out")" = "$1" ] || fail "$2: not \"$1\""; }
say_() { sh -c '. "$1/lib.sh"; foldersay' x "$CHECKS" > "$T/out" 2>&1 || fail "foldersay failed ($1)"; }
S='PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md GRADING-CHECKLIST.md'
head_; add_ "$C1" $S INVENTORY.md STAGES.md; is_ "is $C1" 'the files of the second commit'
head_; add_ "$C1" PRD.md ARCHITECTURE.md; sh -c '. "$1/lib.sh"; folderis' x "$CHECKS" > "$T/out" 2>&1 || fail 'folderis failed'
grep -q "^is .*$C2" "$T/out" && grep -q " $C1$" "$T/out" && ! grep -q "$C0\|$C3" "$T/out" || fail 'two files alone are not the range of the commits that hold them, newest first'
head_; add_ "$CS" $S; is_ "is $CS" 'a commit of a side branch merged back'
head_; add_ "$C1" $S; add_ "$C0" INVENTORY.md; is_ none "two commits' files"
head_; ids PRD.md 'a line of the team'; add_ "$C1" ARCHITECTURE.md; is_ none 'a file changed by hand'
# the team's own files beside
head_; add_ "$C1" $S INVENTORY.md; ids README.md 'the team'; ids design/screen.html 'a screen'; ids STAMP 'vid 1234567'; ids old/PRD.md 'an old one'; is_ "is $C1" "the team's own files beside"
# an export's blanked copy
git init -q --bare .vid/spec.git; B=$(printf 'a blanked PRD.md\n' | git --git-dir=.vid/spec.git hash-object -w --stdin); A=$(git show "$C1:ARCHITECTURE.md" | git --git-dir=.vid/spec.git hash-object -w --stdin)
X=$(printf '100644 blob %s\tARCHITECTURE.md\n100644 blob %s\tPRD.md\n' "$A" "$B" | git --git-dir=.vid/spec.git mktree | xargs -I{} git --git-dir=.vid/spec.git -c user.email=v@s -c user.name=v commit-tree {} -m x)
printf 'export %s from=%s state=local at=2026-11-20T09:00:00Z\n' "$X" "$C1" > .vid/tw/log
head_; printf '%s\tPRD.md\n' "$B" >> .vid/round/folder; add_ "$C1" ARCHITECTURE.md; sh -c '. "$1/lib.sh"; folderis' x "$CHECKS" > "$T/out" 2>&1 || fail 'folderis failed'
grep -q "^is .*$C2" "$T/out" && grep -q " $C1$" "$T/out" && ! grep -q "$C0\|$C3" "$T/out" || fail "an export's blanked copy is not its from= commit and the commits with the same files"
# an applied commit HEAD does not reach
git checkout -q "$C0"; M=apart; CA=$(put_ PRD.md); git checkout -q "$b"; head_; add_ "$CA" $S; is_ none 'a commit HEAD does not reach'
printf '%s\n' "$CA" > .vid/tw/applied; is_ "is $CA" 'the applied commit, HEAD not reaching it'
# no spec there, and none to read
head_; is_ absent 'a folder not there'; add_ "$C1" ARCHITECTURE.md; ids old/PRD.md x; is_ absent 'a folder with no PRD.md at its top'
head_ specs/other; add_ "$C1" $S; is_ '' 'a kept read of another folder'
head_; add_ "$C1" $S; sed 's/one/separate/' .vid/tw/settings > "$T/s"; cp .vid/tw/settings "$T/s1"; cp "$T/s" .vid/tw/settings; is_ '' 'layout separate'; cp "$T/s1" .vid/tw/settings
sed 's/manual/auto/' .vid/plan/setup > "$T/s"; cp .vid/plan/setup "$T/s1"; cp "$T/s" .vid/plan/setup; is_ '' 'GitHub auto'; cp "$T/s1" .vid/plan/setup
mv .vid/round/folder "$T/kept"; is_ '' 'no kept read'; mv "$T/kept" .vid/round/folder
# the words
c12() { printf %.12s "$1"; }
printf '%s\n' "$C1" > .vid/tw/applied; head_; add_ "$C1" $S; say_ holds; grep -q "^holds${TB}upstream/vid " "$T/out" || fail 'a folder holding the applied version is not said to hold it'
printf '%s\n' "$C2" > .vid/tw/applied; head_; add_ "$C1" PRD.md ARCHITECTURE.md; say_ 'the same files'; grep -q "^holds$TB" "$T/out" || fail "a folder holding the applied version's files is said to differ"
head_; add_ "$C0" $S; say_ differs; grep -q "^differs${TB}upstream/vid .*$(c12 "$C0").*$(c12 "$C2").*--applied $(c12 "$C0")" "$T/out" || fail 'a folder that differs does not name its commit, the applied one and --applied'
head_; add_ "$C1" PRD.md ARCHITECTURE.md; printf '%s\n' "$C0" > .vid/tw/applied; say_ 'a range'; grep -q "^differs$TB.*$(c12 "$C1")" "$T/out" && grep -q 'same files' "$T/out" || fail 'a range is not named as one, its oldest too'
# a take-over commit is the commit it was made on
git checkout -q "$C1"; M=taken; CT=$(put_ INVENTORY.md); git checkout -q "$b"; git update-ref refs/vid/applied/1 "$CT"; printf '%s\n' "$CT" > .vid/tw/applied
head_; add_ "$C1" $S INVENTORY.md; say_ 'a take-over commit'; grep -q "^holds$TB" "$T/out" || fail "the folder a take-over commit was made on is said to differ from it"
head_; ids PRD.md x; say_ none; grep -q "^none${TB}upstream/vid .*more than one commit, or changed there" "$T/out" || fail 'the words of a folder of no one commit'
head_; say_ absent; grep -q "^absent${TB}upstream/vid .*sh checks/planner.sh setup spec-path" "$T/out" || fail 'the words of a folder not there do not name the one command'
echo 'folder-is: ok'
