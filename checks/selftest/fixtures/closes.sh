# Purpose: selftest fixture — a stage's closes on the writer's toy (FB-7 A1 to A4, D3), sourced by the cases of them after tw-toy.sh and
# results-reports.sh. `cl_toy` makes the toy with stage 1's four tickets merged (#2 the skeleton's, S01: ROW-003, ROW-004 owed-production; #3
# S02: ROW-001, SEAM-002; #4 S03: ROW-006, SEAM-001, ROW-007 owed-staging; #5 S04: ROW-002, DIF-001 owed-staging), each row accepted or owed,
# two engines, and (but with CL_NOASK) asks stage 1's full run: $K its candidate's folder, $X its commit, $N the ask. `cl_c3` sends a whole green full run and a
# grade, and decides it; `cl_d1` okays and passes the deploy (its address, its duties, SEAM rows real); `cl_cs` asks the staging run ($N), its rows
# in $CSR. Helpers: cs <close.sh args>, its output in $T/out and its code in $RC; ok, no <pattern>; rq <chunk-k> <commit> <engine> <row=state>…;
# allof <state> [<row=state>…] the states of a chunk's rows, $1 but those named, rows from $ROWS; fetch; tk <n> <kind> <step> <rows,> <marks>;
# nt <kind> <step> <rows,> <marks>, the next ticket, its number in $TN; mg <pr> <n>, merged at a new main commit; land <row>…, the records a
# landing's reset of each row leaves; unland, them dropped again; qn <words> the Q line holding them; ds <d1 report>. The case defines fail. Env: CHECKS, T.
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
allof() { s0=$1; shift; for r0 in $ROWS; do v0=$s0; for y0 in "$@"; do [ "${y0%%=*}" != "$r0" ] || v0=${y0#*=}; done; printf '%s=%s\n' "$r0" "$v0"; done; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "${5:-}" | tr ' ' '\n' | sed -n "s/^$r=//p" | tr '+' ' ' | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
nt() { TN=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); tk "$TN" "$1" "$2" "$3" "${4:-}"; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; sh "$GS" results-fetch > /dev/null 2>&1; }
state() { { grep -v "^row $1 " .vid/tw/handed || true; } > "$T/h0"; cat "$T/h0" > .vid/tw/handed; [ -z "${2:-}" ] || tw_hand "row $1 $2"; }
land() { cp .vid/tw/handed "$T/hb"; for r in "$@"; do echo "$r 0123456789ab $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .vid/decide/landed; state "$r"; done; }
unland() { : > .vid/decide/landed; cat "$T/hb" > .vid/tw/handed; }
limit() { printf '%s\tknown limit\tfailing\t%s\tx\tx\n' "$1" "${2:-22}" >> .vid/decide/state; state "$1" known-limit; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
cl_toy() { tw_toy "$T/toy"; mkdir -p "$T/r"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
  printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
  gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
  tk 2 skeleton S01 ROW-003,ROW-004 'ROW-004=owed-production'; mg 20 2; tk 3 step S02 ROW-001,SEAM-002 'SEAM-002=seam'; mg 21 3
  tk 4 step S03 ROW-006,SEAM-001,ROW-007 'SEAM-001=seam ROW-007=owed-staging'; mg 22 4; tk 5 step S04 ROW-002,DIF-001 'DIF-001=owed-staging'; mg 23 5
  for r in ROW-003 ROW-001 ROW-006 ROW-002; do tw_hand "row $r accepted"; done; for r in ROW-004 SEAM-001 SEAM-002 DIF-001 ROW-007; do tw_hand "row $r owed"; done
  tw_closed S01; sh "$GS" tw-sync > /dev/null 2>&1; : > .vid/decide/landed; [ -n "${CL_NOASK:-}" ] || cl_ask; }
# cl_ask: stage 1's full run asked, as owed
cl_ask() { X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; ok '^candidate 1 '; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); CN=$(sed -n 's/^candidate 1 //p' "$T/out"); K=.vid/decide/stage/1/$CN; ROWS=$(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/ask); C3N=$N; }
cl_s1() { G=$(sed -n 's/^issue\t//p' $K/s1ask); { echo 'by: GR'; echo "commit: $X"; for q in $(sed -n 's/^reqs\t//p' $K/s1ask); do echo "$q pass — read"; done; } > "$T/g"; rm -rf "$T/r/grade-$G-1"; mkdir -p "$T/r/grade-$G-1"; cp "$T/g" "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"; }
# cl_c3 [<row=state>…]: the full run's reports, every row passed but those named, the rest chunk, and the grade; then decided
cl_c3() { N=$C3N; [ ! -f "$K/s1ask" ] || cl_s1; rq p1c1-1 "$X" alpha $(allof pass "$@"); rq p2c1-1 "$X" beta $(allof pass "$@"); rq p1cx-1 "$X" alpha test_other=pass; fetch; cs decide --stage 1; [ "$RC" = 0 ] || fail "decide failed ($RC)"; }
cl_d1() { cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); Q=deploy-$O-1; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"
  rr_put "$Q" staging.txt "$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none\nstays: up\nseed: synthetic\nseam: SEAM-001 real\nseam: SEAM-002 real')"
  rr_put "$Q" duties.txt "$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)"; send "$Q"; fetch; cs decide --stage 1; ok '^d1 1 passed$'; }
cl_cs() { cs owed; ok '^cs 1$'; cs ask --cs 1; ok '^asked [0-9]* cs stage-1$'; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); CSN=$N; CSR=$(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cs/ask); ROWS=$CSR; }
# csr <k> <state> [<row=state>…]: the staging run's two reports of attempt k, $ROWS all of one state but those named
csr() { k0=$1; shift; N=$CSN; rq p1c1-$k0 "$X" alpha $(allof "$@"); rq p2c1-$k0 "$X" beta $(allof "$@"); fetch; cs decide --stage 1; [ "$RC" = 0 ] || fail "decide failed ($RC)"; }
# failclose <n>: `gh issue close <n>` fails once, each other call the fake's. pubfix <rows> <step> <marks>: the ticket of the handed fix line of those rows, $TN, its line's key
failclose() { [ -d "$T/bin0" ] || { mkdir -p "$T/bin0"; printf '#!/bin/sh\nif [ "$1 $2" = "issue close" ] && [ -f %s ] && [ "$3" = "$(cat %s)" ]; then rm -f %s; echo "gh: the close failed" >&2; exit 1; fi\nexec %s "$@"\n' "'$T/failclose'" "'$T/failclose'" "'$T/failclose'" "'$(command -v gh)'" > "$T/bin0/gh"; chmod +x "$T/bin0/gh"; PATH=$T/bin0:$PATH; export PATH; }; echo "$1" > "$T/failclose"; }
pubfix() { FL=$(sed -n "s/^\(fix $1 .*\) | stand-in: RM$/\1/p" .vid/tw/handed); KF=$(printf '%s' "$FL" | cksum | cut -d' ' -f1); nt fix "$2" "$(echo $1 | tr ' ' ,)" "${3:-}"; sed "s/^\(published $TN .*\) at=/\1 fix=$KF at=/" .vid/tw/log > "$T/l"; cat "$T/l" > .vid/tw/log; }
