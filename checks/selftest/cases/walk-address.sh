#!/bin/sh
# Purpose: selftest case — the walk looks before it starts (FB-7 C2), walk.sh start and read on the writer's toy, stage 1's walk due. No
# answer at the staging's address (the real tool at a closed port of this machine, and a fake one): no walker starts, the start's read is
# `not-done <address> does not answer`, a question whose answer is again alone, asked of the address once; again gives a new brief. Any
# HTTP answer starts the walker (200, a redirect, a refusal, a server's own error, whatever the tool's exit); an address that is no http one,
# and a machine with no tool to ask by, are not looked at; a carriage return at the address's end is none of it. A start that has its read
# is not started again: a new brief is. A walker that returns no walk.txt is refused with its own last words: its
# result's, its error's, its log's, and `no walk.txt` alone when it said nothing. close.sh walk says the walker did not start. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "walk-address: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; WS=$CHECKS/walk.sh; QS=$CHECKS/queue.sh; mkdir -p .vid/round .vid/decide design/screens "$T/wk"; VID_WALK_TMP=$T/wk; export VID_WALK_TMP
wk() { RC=0; sh "$WS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
echo '<html>the saved search canvas</html>' > 'design/screens/S01 Subscribe.dc.html'
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p "$K/cs" "$K/d1"
printf 'issue\t9\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$K/ask"; echo "$X" > "$K/commit"; : > "$K/named"; : > "$K/passed"; printf 'issue\t50\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$K/cs/ask"; : > "$K/cs/passed"
at() { printf 'd1\tpassed\t1\nstaging\t%s\n' "$1" > "$K/d1/read"; }
# the walker: it says it ran, and what WSAY and WERR hold, and ends with no walk.txt
printf '%s\n' '#!/bin/sh' ': > "$RAN"; [ -z "${WSAY:-}" ] || printf "%s\n" "$WSAY"; [ -z "${WERR:-}" ] || printf "%s\n" "$WERR" >&2; exit 0' > "$T/walker"; chmod +x "$T/walker"; VID_WALKER=$T/walker; RAN=$T/ran; export VID_WALKER RAN
# a fake tool to ask by, as the real one answers for a code: with -f (or --fail) a refusal is no answer; -w prints the code; CX its exit
cat > "$T/fcurl" <<'W'
#!/bin/sh
echo "$@" >> "$CLOG"; f=''; w=''; for a in "$@"; do case $a in --fail*) f=1 ;; --*) ;; -*f*) f=1 ;; *http_code*) w=1 ;; esac; done
[ "$CODE" != 000 ] || { [ -z "$w" ] || printf 000; exit 7; }
[ -z "$w" ] || printf %s "$CODE"; { [ -z "$f" ] || [ "$CODE" -lt 400 ]; } || exit 22; exit "${CX:-0}"
W
chmod +x "$T/fcurl"; CLOG=$T/clog; export CLOG
fake() { cp "$T/fcurl" "$T/bin/curl"; CODE=$1; CX=${2:-0}; export CODE CX; : > "$CLOG"; }; real() { rm -f "$T/bin/curl"; }
start() { rm -f "$RAN"; wk brief --stage 1; [ "$RC" = 0 ] || fail 'no brief'; wk start --stage 1; }
afresh() { rm -rf "$K/w1"; }
refused() { [ "$RC" = 1 ] || fail "a start with no answer exited $RC"; ok "^w1 not-done $1 does not answer\$"; [ "$(cat "$K/w1/$2/read")" = "not-done	$1 does not answer" ] || fail "the start's read: $(cat "$K/w1/$2/read" 2>/dev/null)"; [ ! -f "$RAN" ] && [ ! -f "$K/w1/$2/pid" ] || fail 'a walker started at an address that does not answer'; }
started() { [ "$RC" = 0 ] || fail "$1: the start exited $RC"; ok '^started [0-9]*$'; [ ! -f "$K/w1/1/read" ] || fail "$1: the start has a read: $(cat "$K/w1/1/read")"; n=0; until sh "$WS" ended 1; do n=$((n + 1)); [ "$n" -lt 20 ] || fail "$1: the walker never ended"; sleep 1; done; [ -f "$RAN" ] || fail "$1: the walker did not run"; }
# the real tool, a closed port of this machine
if command -v curl > /dev/null 2>&1; then at http://127.0.0.1:9/; start; refused http://127.0.0.1:9/ 1; afresh; fi
# no answer: asked once, the question, again
at http://127.0.0.1:5001; fake 000; start; refused http://127.0.0.1:5001 1; [ "$(grep -c . "$CLOG")" = 1 ] || fail "the address was asked $(grep -c . "$CLOG") times"; grep -qF 'http://127.0.0.1:5001' "$CLOG" || fail 'another address was asked'
ok '^walk-item 1 not done — http://127.0.0.1:5001 does not answer #1$'; wk owed; ! grep -q '^walk 1' "$T/out" || fail 'the walk is due with no answer of the owner'; wk pending; ! grep -q '^walk-read' "$T/out" || fail 'a start with a read is read again'
QN=$(qn 'the walk W1 of stage-1: not done — http:..127.0.0.1:5001 does not answer'); [ -n "$QN" ] || fail "no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"; ! grep -q "^- $QN · .*close without the walk" .vid/RUN-STATE.md || fail 'an address that does not answer offers close without the walk'
RC=0; sh "$QS" answer "$QN" close without the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && [ ! -f "$K/w1/limit" ] || fail 'close without the walk was taken for an address that does not answer'
sh "$QS" answer "$QN" again 'it is up' > "$T/out" 2>&1 || fail 'again was refused'; wk owed; ok '^walk 1$'; start; refused http://127.0.0.1:5001 2
afresh; RC=0; sh "$CHECKS/close.sh" walk 1 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail "close.sh walk exited $RC"; ok '^refused stage 1: the walker did not start: w1 not-done http://127.0.0.1:5001 does not answer$'; afresh
# any HTTP answer starts it
for c in 200 302 401 503; do fake $c; start; started "an answer $c"; afresh; done
fake 200 28; start; started 'an answer whose body does not end'; afresh
# not looked at
fake 000; at 'app://jobdigest'; start; started 'an address that is no http one'; [ ! -s "$CLOG" ] || fail 'an address that is no http one was asked'; afresh
at http://127.0.0.1:5001; real; mkdir -p "$T/nb"; ln -s /usr/bin/* /bin/* /usr/sbin/* "$T/nb/" 2>/dev/null || true; rm -f "$T/nb/curl"; cp "$T/bin/gh" "$T/nb/gh.x"; rm -f "$T/nb/gh"; mv "$T/nb/gh.x" "$T/nb/gh"
P0=$PATH; PATH=$T/nb; if ! command -v curl > /dev/null 2>&1; then start; started 'no tool to ask by'; afresh; fi; PATH=$P0
# no walk.txt: the walker's own last words
fake 200; noreturn() { start; started "$1"; wk read --stage 1; ok "^w1 refused $2\$"; [ "$(cat "$K/w1/1/read")" = "refused	$2" ] || fail "$1: its read: $(cat "$K/w1/1/read")"; afresh; }
WSAY='{"type":"system","subtype":"init","tools":["Bash"]}
{"type":"result","subtype":"success","is_error":true,"result":"OAuth session expired · Please run \"login\"\nthen try again","session_id":"x"}'; export WSAY; noreturn 'a result' 'no walk.txt: OAuth session expired · Please run "login" then try again'
WSAY=''; WERR='first
Error: the model is not available'; export WSAY WERR; noreturn 'an error' 'no walk.txt: Error: the model is not available'
WERR=''; WSAY='starting
Not signed in'; export WSAY WERR; noreturn 'a plain log' 'no walk.txt: Not signed in'
WSAY=''; export WSAY; noreturn 'nothing said' 'no walk.txt'
# a start that has its read is not started again; a carriage return is none of the address (each told)
BAD=''; bad() { echo "walk-address: $*" >&2; cat "$T/out" >&2; BAD=1; }; CR=$(printf '\r')
at http://127.0.0.1:5001; fake 000; start; refused http://127.0.0.1:5001 1; fake 200; rm -f "$RAN"; wk start --stage 1; sleep 1
[ "$RC" != 0 ] && grep -q 'the walk 1 of stage 1 is read already: answer again, then a new brief' "$T/out" && [ ! -f "$RAN" ] && [ ! -f "$K/w1/1/pid" ] || bad 'a start that has its read was started again'
n=0; while [ -f "$K/w1/1/pid" ] && [ "$n" -lt 5 ]; do sleep 1; n=$((n + 1)); done; afresh
at "http://127.0.0.1:5001$CR"; fake 200; start; ! grep -q "$CR" "$CLOG" || bad 'the address was asked with its carriage return'; n=0; until sh "$WS" ended 1 || [ "$n" -ge 10 ]; do n=$((n + 1)); sleep 1; done; [ -f "$RAN" ] || bad 'no walker started at an address with a carriage return'; afresh
fake 000; start; [ -f "$K/w1/1/read" ] && ! grep -q "$CR" "$K/w1/1/read" || bad 'the read holds a carriage return'
[ -z "$BAD" ]
