# Purpose: selftest fixture — a Codex builder's job, without Codex (v0.9.7.1 spec 3.9, R9). Sourced by a case after
# it has made $T (Env: CHECKS, T); it sources the brief-write fixture. jb_repo <dir>: the brief-write toy with
# bw_builder, checks/ gaining job.sh, test.sh, plan.sh, event.sh, evidence.sh and lawfiles, a RUN-STATE (run:
# active, no plan: key — the test gate stays off, the home is found), builders set to Codex by the owner, and a
# checked builder brief for S1 (try 1-builder-1) in $B. The fake Codex ($T/fake-codex.sh, through VID_CODEX) reads
# its arguments as codex exec gets them (-C <worktree>, -o <final>, the bootstrap last) and acts by $FAKE_CODEX:
#   ok     — two turn.completed events (input 1000, then 3000), a commit in the worktree on vid/<try>, the return
#            file at the path the bootstrap names (written .tmp, then renamed), the final message; exit 0
#            (v0.9.8.1: with $FAKE_BOOT set it saves the bootstrap there; with $FAKE_BARE set the return's brief line
#            is the bare file name, as a Codex return once wrote it)
#   limit  — one turn event, an uncommitted edit, then Codex's usage-limit error with "try again at 3:05 PM"; exit 1
#   sleep  — touches $FAKE_ENTER, then a child sleeping 120 s in its group; waits for it
#   output — v0.9.7.3: a command whose output, an agent message and a non-fatal error item name a rate and a usage
#            limit, then turn.completed; exit 0 (output-fail: the same, then exit 2 with a plain stderr line)
. "$CHECKS/selftest/fixtures/brief-write.sh"
jb_repo() {
  bw_plugin; bw_repo "$1"; bw_builder
  printf '{ "name": "vid", "version": "9.9.9" }\n' > /dev/null
  mkdir -p "$CLAUDE_PLUGIN_ROOT/.claude-plugin" "$CLAUDE_PLUGIN_ROOT/skills/vid-build"; printf '{ "name": "vid", "version": "9.9.9" }\n' > "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json"; printf '# toy vid-build\n' > "$CLAUDE_PLUGIN_ROOT/skills/vid-build/SKILL.md"
  cp "$CHECKS/job.sh" "$CHECKS/test.sh" "$CHECKS/plan.sh" "$CHECKS/event.sh" "$CHECKS/evidence.sh" "$CHECKS/lawfiles" checks/
  mkdir -p lib; printf 'base\n' > lib/a.txt
  g add -A && g commit -qm 'job toy'
  printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
  sh checks/job.sh tool codex --by owner > /dev/null
  bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || { cat "$T/wout" >&2; return 1; }
  B=$(bw_out)
  cat > "$T/fake-codex.sh" <<'FAKE'
#!/bin/sh
WT=''; FIN=''
while [ $# -gt 1 ]; do case "$1" in -C) WT=$2; shift 2 ;; -o) FIN=$2; shift 2 ;; *) shift ;; esac; done
BOOT=$1
[ -n "${FAKE_BOOT:-}" ] && printf '%s\n' "$BOOT" > "$FAKE_BOOT"
RET=$(printf '%s\n' "$BOOT" | sed -n 's/^Your hand-back: write your return file at \([^ ]*\) — .*/\1/p')
cd "$WT" || exit 9
TRY=$(basename "$WT" .wt)
case "${FAKE_CODEX:-ok}" in
  ok)
    echo '{"type":"thread.started","thread_id":"t"}'
    echo '{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":0,"output_tokens":5}}'
    git -c user.email=f@x -c user.name=f checkout -q -b "vid/$TRY" && printf 'built\n' >> lib/a.txt && git -c user.email=f@x -c user.name=f commit -qam built
    echo '{"type":"turn.completed","usage":{"input_tokens":3000,"cached_input_tokens":2000,"output_tokens":5}}'
    _bl=$(sed -n 's/^brief=//p' "$(dirname "$WT")/$TRY"); [ -n "${FAKE_BARE:-}" ] && _bl=${_bl##*/}
    { printf 'brief: %s\nbranch: vid/%s\ncommit: %s\n' "$_bl" "$TRY" "$(git rev-parse HEAD)"
      printf 'ROW-101 | not | none | not built in the toy\nROW-102 | not | none | not built in the toy\n'; } > "$RET.tmp" && mv "$RET.tmp" "$RET"
    printf 'return: %s\n' "$RET" > "$FIN"; exit 0 ;;
  limit)
    echo '{"type":"turn.completed","usage":{"input_tokens":500,"output_tokens":5}}'
    printf 'half done\n' >> lib/a.txt
    echo '{"type":"error","message":"You'"'"'ve hit your usage limit. Upgrade or try again at 3:05 PM."}'
    exit 1 ;;
  sleep)
    : > "${FAKE_ENTER:-/dev/null}"; printf 'half\n' >> lib/a.txt; sleep 120 & wait ;;
  output|output-fail)
    echo '{"type":"thread.started","thread_id":"t"}'
    echo '{"type":"item.completed","item":{"id":"i1","type":"command_execution","command":"grep -n rate tests/test_x.py","aggregated_output":"12:def _literal_rate_limited_registration(): # rate_limit, usage limit, try again at 3:05 PM\n","exit_code":0,"status":"completed"}}'
    echo '{"type":"item.completed","item":{"id":"i2","type":"agent_message","text":"The test covers the rate limit; usage limit messages are tested too."}}'
    echo '{"type":"item.completed","item":{"id":"i3","type":"error","message":"rate_limit noted in a tool"}}'
    echo '{"type":"turn.completed","usage":{"input_tokens":700,"output_tokens":5}}'
    [ "${FAKE_CODEX}" = output-fail ] && { echo 'the run ended' >&2; exit 2; }
    exit 0 ;;
esac
FAKE
  VID_CODEX=$(printf 'sh\n%s' "$T/fake-codex.sh"); export VID_CODEX
}
jb_wait() { _i=0; while [ ! -e "$1" ] && [ "$_i" -lt "${2:-50}" ]; do sleep 0.2; _i=$((_i + 1)); done; [ -e "$1" ]; }
