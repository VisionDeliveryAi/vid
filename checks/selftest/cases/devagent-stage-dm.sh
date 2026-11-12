#!/bin/sh
# Purpose: selftest case — DevAgent's dev manager's side of a stage's candidate (v0.26.10.26.1 R7), on the fake gh. next gives an issue labelled grade a line, as it
# gives a run issue: work while it has no vid: reported s1-<k>, wait once it has, work again after a vid: again s1 or a comment begun vid: refused newer than its
# newest report, wait while the record's lost s1 <k> came after the k-th again, blocked by its label, nothing once closed; a full run's rest chunk p1cx is a chunk like
# any. start takes the stage-grader role, on its own file, as GR, with no Edit tool, on --model the note's model or, with none, dm.sh's default (v0.26.10.28.3 R4).
# The stage grader's file and the dev manager's say what they must; the row
# grader's file is as at 00109a8, and on this line of versions the second reviewer's as at the base, aa6e610. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-stage-dm: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_fake; W=$T/work; mkdir -p "$W/tickets" "$W/c1"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
is() { sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
C=$(printf '%040d' 7)
printf 'grade: stage-1\ncommit: %s\nrequirements: REQ-1 REQ-2\n\nGrade each requirement.\n' "$C" > "$T/b"
GN=$(gh issue create -R owner/code --title 'Stage grade: stage 1' --body-file "$T/b" --label grade); GN=${GN##*/}
cm() { printf '%s\n' "$2" > "$T/b"; g issue comment "$1" -R owner/code --body-file "$T/b"; }
is "work $GN"
cm "$GN" 'vid: started
by: DM'; is "work $GN"
cm "$GN" 'vid: reported s1-1
by: DM'; is "wait $GN"
cm "$GN" 'vid: refused — no line for REQ-2'; is "work $GN"
cm "$GN" 'vid: reported s1-2'; is "wait $GN"
cm "$GN" 'vid: refusedx'; is "wait $GN"
cm "$GN" 'vid: again s1'; is "work $GN"
echo 'lost s1 1' > "$W/tickets/$GN.txt"; is "wait $GN"
cm "$GN" 'vid: again s1'; is "work $GN"
g issue edit "$GN" -R owner/code --add-label blocked; is "blocked $GN"
g issue close "$GN" -R owner/code; is none
# C3, a run issue with the rest chunk: a chunk like any
printf 'close: stage-1\ncommit: %s\nengines: alpha beta\n\n- chunk p1c1, alpha: ROW-001\n- chunk p2c1, beta: ROW-001\n- chunk p1cx, alpha: every other test case of the suite, but the cases of the deploy-owed rows ROW-009\n' "$C" > "$T/b"
RN=$(gh issue create -R owner/code --title 'Close run: stage 1' --body-file "$T/b" --label run); RN=${RN##*/}
for c in p1c1 p2c1; do cm "$RN" "vid: reported $c-1"; done; is "work $RN"
cm "$RN" 'vid: reported p1cx-1'; is "wait $RN"
cm "$RN" 'vid: again p1cx'; is "work $RN"
g issue close "$RN" -R owner/code; is none
# start: the stage-grader role, on its own file, as GR, read-only but its grade file
cat > "$T/bin/claude" <<'X'
#!/bin/sh
printf '%s\n' "$*" >> "$FC_LOG"
printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_M"
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"grades/stage-1/grade-1.txt"}\n'
X
chmod +x "$T/bin/claude"; FC_LOG=$T/fc; FC_M=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_LOG FC_M; : > "$FC_LOG"; [ -n "$FC_M" ] || fail "dm.sh has no default model"
printf 'ticket: %s\nthe job\n' "$GN" > "$W/job"; A=$(DM_AGENT_CLAUDE="$T/bin/claude" sh "$DM" start stage-grader "$W/job" "$W/c1") || fail 'the stage grader did not start'
sh "$DM" wait "$A" > "$T/out" 2>&1 || fail 'wait on the stage grader'
grep -qF "$RT/devagent/agents/stage-grader.md" "$FC_LOG" && grep -q -- "--model $FC_M " "$FC_LOG" && grep -q -- '--allowedTools Bash Read Write Grep Glob$' "$FC_LOG" || fail "the stage grader's start: $(cat "$FC_LOG")"
[ "$(cat "$W/agents/$A/role")" = GR ] || fail "the stage grader's label: $(cat "$W/agents/$A/role")"
# the files
F=$RT/devagent/agents/stage-grader.md
for l in 'skills/vid-grade/GRADING.md' 'You run nothing' '**pass:**' '**partial:**' '**facade:**' '**absent:**' 'none other and none twice' 'the grade is void' 'The six probes' 'it is a rule, not a bug' 'finding: bug|rule' 'by: GR' "not the blind copy's" '**Completeness:**' 'deploy-owed row' 'cites file:line'; do
  grep -qF -- "$l" "$F" || fail "the stage grader's file lacks: $l"; done
for l in '## A stage grade' '`<prefix>grade`' 'grade-<n>' 'vid: reported s1-<k>' 'lost s1 <k>' 'vid: again s1' '`vid: refused`' 'stage-grader' '--leave-out' 'req-<n>-p1cx' '**Who does each:**' 'close: stage-<N>'; do
  grep -qF -- "$l" "$RT/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
! git -C "$RT" cat-file -e 00109a8 2> /dev/null || [ "$(git -C "$RT" rev-parse 00109a8:standin/agents/grader.md 2>/dev/null)" = "$(git -C "$RT" hash-object devagent/agents/grader.md)" ] || fail "the row grader's file changed since 00109a8"
case $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$RT/.claude-plugin/plugin.json") in
  0.26.10.25.5.1|0.26.10.26.*) ! git -C "$RT" cat-file -e aa6e610 2> /dev/null || [ "$(git -C "$RT" rev-parse aa6e610:standin/agents/second-reviewer.md 2>/dev/null)" = "$(git -C "$RT" hash-object devagent/agents/second-reviewer.md)" ] || fail "the second reviewer's file changed in this release" ;;
esac
exit 0
