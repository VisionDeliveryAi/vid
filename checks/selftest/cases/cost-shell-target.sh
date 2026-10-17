#!/bin/sh
# Purpose: selftest case — the first-change value counts only a shell write
# to a module (v0.9.7.0.9 spec 3.7, R10). The brief-write fixture (step S1,
# modules app/). Each builder transcript opens with shell calls that name
# app/ but write elsewhere — the recorded shape `git add … app/ … > <a
# scratch file>`, a redirection to /dev/null and to a descriptor, `cp
# app/x /tmp/x`, `tee` and `sed -i` on a scratch file, `mv` and `rm`
# outside app/ — then one true write. Convicts unless the build-cost's
# before-change is that write's context, marked ` shell`, for each of `cat
# > app/x <<…`, `sed -i … app/x`, `mv app/x /tmp/x`, `rm app/x`, `tee
# app/x`, `cp /tmp/x app/x` and `>> app/x`, `sh -c '… > app/x'`, a
# here-document script writing app/x, and a quoted `cp` target under app/;
# and `unknown` when no call writes a module — the elsewhere calls include
# the shapes rehearsal R-4 met: `grep -c '<pattern>'` beside app/ (no
# script), a `>` inside a quoted pattern (no redirection), and a
# here-document script on a scratch file beside `cp app/x <scratch>`.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "cost-shell-target: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep '^build-cost' .vid/metrics-events >&2; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
C=$(pwd -P)
# js <text>: the text as a JSON string body (backslash, quote, newline)
js() { printf '%s' "$1" | awk 'BEGIN { ORS = "" } { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); if (NR > 1) print "\\n"; print }'; }
call() { # <message id> <context> <command>: one assistant Bash call and its result
  printf '{"parentUuid":"p","isSidechain":true,"message":{"model":"m","id":"%s","type":"message","role":"assistant","content":[{"type":"tool_use","id":"tu_%s","name":"Bash","input":{"command":"%s"}}],"usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":%s,"output_tokens":9}},"type":"assistant","uuid":"u","cwd":"%s"}\n' "$1" "$1" "$(js "$3")" "$2" "$C"
  printf '{"parentUuid":"p","isSidechain":true,"type":"user","message":{"role":"user","content":[{"tool_use_id":"tu_%s","type":"tool_result","content":"ok","is_error":false}]},"uuid":"u","cwd":"%s"}\n' "$1" "$C"
}
elsewhere() { # the calls that name app/ and write elsewhere, contexts 1001…
  call m1 1001 "git add app/links.sh tests/invariants/links.sh && git diff --cached --stat app/ > $T/scratch.txt"
  call m2 1002 'grep -rn link app/ > /dev/null 2>&1; ls app/ 2>&1 >&2'
  call m3 1003 "cp app/links.sh $T/copy.sh"
  call m4 1004 "cat app/links.sh | tee $T/log.txt"
  call m5 1005 "sed -i.bak 's/a/b/' $T/scratch.txt app.txt"
  call m6 1006 "mv $T/scratch.txt $T/scratch2.txt; rm -f $T/scratch2.txt app.log"
  call m7 1007 'sed -n 1,5p app/links.sh >> notes/app-reading.txt'
  # (rehearsal R-4) a pattern after grep -c is no script; a quoted > is no redirection; a scratch here-document script
  call m8 1008 "git add app/ && time sh checks/census.sh > $T/census1.txt 2>&1; grep -c '^FAIL' $T/census1.txt; grep -oE '<a [^>]*>[^<]*</a>' app/links.sh"
  call m10 1010 "cd $T && sh - <<'EOF'
printf '%s\n' 'a > b' > scratch.txt
EOF
cp app/links.sh $T/b.html"
}
n=1
cost() { # <agent> <true write or ''> <expected before-change>
  bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'the writer refused a brief'
  b=$(bw_out)
  _p="$T/projects/s$n.jsonl"; mkdir -p "${_p%.jsonl}/subagents"; : > "$_p"
  { elsewhere; [ -n "$2" ] && call m9 3000 "$2"; } > "${_p%.jsonl}/subagents/agent-$1.jsonl"
  printf 'agent-start session=S1 agent=%s type=general-purpose transcript="%s" at=2026-10-02T11:00:00Z\n' "$1" "$_p" >> .vid/metrics-events
  printf 'brief: %s\nagent: %s\nbranch: b\ncommit: '"$(git rev-parse HEAD)"'\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$b" "$1" "$GREEN" > "$b.return.md"
  sh checks/brief.sh return "$b.return.md" > "$T/out" 2>&1 || fail "the hand-back for $1 was refused"
  grep "^build-cost .* brief=$b " .vid/metrics-events | grep -q " before-change=$3 tool=" || fail "$1 ('$2'): before-change is not '$3': $(grep "^build-cost .* brief=$b " .vid/metrics-events)"
  n=$((n + 1)); }
cost w0 '' unknown
cost w1 "cat > app/new.sh <<'EOF'
printf hello
EOF" '3000 shell'
cost w2 "sed -i 's/a/b/' app/links.sh" '3000 shell'
cost w3 "mv app/links.sh $T/gone.sh" '3000 shell'
cost w4 'rm -f ./app/links.sh' '3000 shell'
cost w5 "printf x | tee $T/log.txt app/links.sh" '3000 shell'
cost w6 "cp $T/copy.sh $C/app/links.sh" '3000 shell'
cost w7 'printf x >> app/links.sh' '3000 shell'
cost w8 "sh -c 'printf x > app/links.sh'" '3000 shell'
cost w9 "sh - <<'EOF'
printf x > app/links.sh
EOF" '3000 shell'
cost w10 'cp "$T/copy.sh" "app/a b.sh"' '3000 shell'
exit 0
