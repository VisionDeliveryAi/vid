#!/bin/sh
# Purpose: selftest case — the Windows forms (v0.26.10.25.2.1, F-007, F-003, F-016, F-005), faked on this machine. A stand-in
# for Windows git gives its paths as W:/… and reads an alternates line in no other form: spec-export still pushes, its
# alternates line in git's own form. With devagent/ beside checks/: run.sh's stamp holds under WSL's drifting ps start, under
# Git Bash's ps with no -o and its /proc start that moves with its boot time, and on this machine's own ps; a pid whose start
# is another's is no agent of dm.sh list; and run.sh grade, its results branches unreadable, says why and pushes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); T0=$T; trap 'rm -rf "$T0"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "windows-forms: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
RG=$(command -v git); mkdir -p "$T/win"
cat > "$T/win/git" <<G
#!/bin/sh
# a stand-in for Windows git: its own paths are W:/…, and an alternates line in any other form names no objects to it
case "\$*" in *'rev-parse --path-format=absolute'*) o=\$("$RG" "\$@") || exit \$?; printf 'W:%s\n' "\$o"; exit 0 ;; esac
A=\$PWD/.vid/spec.git/objects/info/alternates
[ -f "\$A" ] || exec "$RG" "\$@"
cp "\$A" "\$A.win"; sed -e 's|^W:||' -e t -e 's|^/.*|/no/such/objects|' "\$A.win" > "\$A"; rc=0; "$RG" "\$@" || rc=\$?; cp "\$A.win" "\$A"; rm -f "\$A.win"; exit \$rc
G
chmod +x "$T/win/git"
# F-007: the export, through Windows git
tw_toy "$T/toy"; GS=$CHECKS/github.sh
PATH=$T/win:$PATH sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'the export failed through Windows git'
grep -q '^W:/' .vid/spec.git/objects/info/alternates || fail "the alternates line is not in git's own form: $(cat .vid/spec.git/objects/info/alternates)"
grep -q 'state=pushed' .vid/tw/log || fail 'nothing was pushed'
# Windows git before 2.31: no --path-format, so Git Bash's cygpath gives the form
sed -i.b 's|^case "\$\*" in .*rev-parse --path-format=absolute.*esac$|case "$*" in *--path-format*) echo "$*" \| sed "s/.*--path-format=absolute //"; "'"$RG"'" rev-parse --git-common-dir; exit 0 ;; esac|' "$T/win/git"; rm -f "$T/win/git.b"
printf '#!/bin/sh\nprintf "W:%%s\\n" "$2"\n' > "$T/win/cygpath"; chmod +x "$T/win/cygpath"
PATH=$T/win:$PATH sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed through an older Windows git'; grep -q '^W:/' .vid/spec.git/objects/info/alternates || fail "an older git left the shell's form: $(cat .vid/spec.git/objects/info/alternates)"
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RS=$CHECKS/../devagent/test-manager/run.sh; DM=$CHECKS/../devagent/dev-manager/dm.sh
# F-003, F-016: a live process, this shell, under each platform's forms; P its fake /proc
P=$T/proc; mkdir -p "$P/$$" "$T/bin"; VID_PROC=$P; export VID_PROC
st() { printf '%s (sh) S 1 1 1 0 -1 0 0 0 0 0 0 0 0 0 20 0 1 0 %s 1000 10\n' "$$" "$1" > "$P/$$/stat"; printf 'cpu 1 1 1 1\nbtime %s\n' "$2" > "$P/stat"; }; mkdir -p "$P/sys/kernel/random"; echo boot-a > "$P/sys/kernel/random/boot_id"
os() { printf '#!/bin/sh\necho %s\n' "$1" > "$T/bin/uname"; chmod +x "$T/bin/uname"; }
stamp() { PATH=$T/bin:$PATH sh "$RS" stamp "$$"; }; is() { PATH=$T/bin:$PATH sh "$RS" is "$$" "$T/rec"; }
# WSL: ps's start drifts at each read, /proc's ticks stand
os Linux; printf '#!/bin/sh\nn=$(cat "%s/n" 2>/dev/null || echo 0); n=$((n + 1)); echo $n > "%s/n"; echo "Mon Nov  9 10:00:0$n 2026"\n' "$T" "$T" > "$T/bin/ps"; chmod +x "$T/bin/ps"
st 4242 1700000000; stamp > "$T/rec"; [ "$(cat "$T/rec")" = boot-a:4242 ] || fail "WSL's stamp is not the boot and /proc's ticks: $(cat "$T/rec")"; is || fail 'WSL: a live run read as gone'
st 99999 1700000000; ! is || fail 'WSL: a pid with another start read as the same process'
st 4242 1700000000; echo boot-b > "$P/sys/kernel/random/boot_id"; ! is || fail 'WSL: after a reboot, the same ticks read as the same process'
# Git Bash: ps has no -o; /proc's start moves with the boot time, as F-016 saw it, and the two read together stand
os MINGW64_NT-10.0; printf '#!/bin/sh\necho "ps: unknown option -- o" >&2; exit 1\n' > "$T/bin/ps"; chmod +x "$T/bin/ps"
st 899213122 1700000000; stamp > "$T/rec"; is || fail 'Git Bash: a live run read as gone'
st 899222883 1699999902; is || fail 'Git Bash: the moved start read as another process'
st 899213422 1700000000; ! is || fail 'Git Bash: a start 3 s later read as the same process'
st 899313122 1700000000; ! is || fail 'Git Bash: a start 1000 s later read as the same process'
# this machine: no /proc, its own ps
rm -f "$T/bin/uname" "$T/bin/ps"; VID_PROC=$T/none; export VID_PROC; stamp > "$T/rec"; [ -s "$T/rec" ] && is || fail "this machine's own start does not hold"
# dm.sh list: an agent whose pid lives under another start is none
W=$T/w; mkdir -p "$W/agents/test-author-1"; A=$W/agents/test-author-1; echo $$ > "$A/pid"; cp "$T/rec" "$A/lstart"; echo 1 > "$A/ticket"; echo "$T" > "$A/clone"; echo TA > "$A/role"; date +%s > "$A/start"; : > "$A/log"
DM_WORK=$W sh "$DM" list > "$T/out" 2>&1; grep -q '^alive test-author-1 ' "$T/out" || fail 'a live agent is not listed'
echo 'Mon Jan  1 00:00:00 2001' > "$A/lstart"; DM_WORK=$W sh "$DM" list > "$T/out" 2>&1; grep -q '^ended test-author-1 ' "$T/out" || fail 'a pid with another start is listed as the agent'
# F-005: run.sh grade with its results branches unreadable says why, and pushes nothing
B=$T/bin; T=$T/sp; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/devagent-project.sh"; sp_project; cd "$T"; S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12)
printf '#!/bin/sh\ncase "$1" in ls-remote) echo "fatal: Unable to read current working directory: No such file or directory" >&2; exit 128 ;; esac\nexec "%s" "$@"\n' "$RG" > "$B/git"; chmod +x "$B/git"
printf 'by: GR\ncommit: %s\nROW-001 kept — seen\n' "$SP_C" > g.txt; RC=0; PATH=$B:$PATH sh "$RS" grade --setup "$S" --ask "grade-pr-1-$H" --file g.txt > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'could not be read: fatal: Unable to read current working directory' "$T/out" || fail 'the unreadable results branches were not named'
! git -C "$T/origin.git" rev-parse -q --verify "refs/heads/vid-results/grade-pr-1-$H-1" > /dev/null || fail 'a grade was pushed with its attempts unread'
# and a fault run and a head run, each with a result that says why
printf 'ROW-001\tnone.patch\tnone\tROW-001\n' > work/f0.txt; RC=0; PATH=$B:$PATH sh "$RS" run --setup "$S" --commit "$SP_C" --ask "pr-1-$H" --faults work/f0.txt > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'not run: the results branches .* could not be read: fatal: Unable' "$T/out" && ! grep -q 'no head report' "$T/out" || fail 'a fault run gave a false cause'
RC=0; PATH=$B:$PATH sh "$RS" run --setup "$S" --commit "$SP_C" --ask "pr-1-$H" --select ROW-001 --engines alpha > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'not pushed: the results branches .* could not be read: fatal: Unable' "$T/out" || fail 'a head run ended with no result saying why'
exit 0
