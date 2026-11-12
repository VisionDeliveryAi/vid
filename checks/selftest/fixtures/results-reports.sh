#!/bin/sh
# Purpose: selftest fixture — made-up reports for the results reader (v0.26.10.24.5), on the plain toy words alone. Sourced by
# the results-* cases. `rr_project` makes $T/p, enters it, and writes .vid/code, a local bare code repository with commits $RR_RED
# (the tests-first commit), $RR_H (a head) and $RR_H2 (a later head), and four published tickets in .vid/tw/out: #1 a skeleton
# (ROW-009), #2 an earlier step (ROW-008), #3 a step (ROW-001; the journey ROW-002 of 2 transitions, its first faulted; HOS-001, a
# faulted protection row; RULE-001; DIF-001 owed; SEAM-001; regression row ROW-009), #5 a reached ticket (ROW-001, DIF-001). Helpers:
# `rr_cases <case>…` prints a cases file, each case `name=pass`, `name=skip`, `name=fail:<message>` or `name=err:<message>`; `rr_put
# <id> <file> <text>` writes a report's file in $T/r/<id>; `rr_send <id>` pushes that folder alone as vid-results/<id>; `rr_good` sends red-3-1,
# pr-4-<head12>-1, grade-pr-4-<head12>-1 and sort-pr-4-<head12>-1 in good form, each row as its own case. Env: T.
rr_git() { git -c user.email=rr@selftest -c user.name=rr "$@"; }
rr_project() {
  mkdir -p "$T/p/.vid/tw/out" "$T/r"; cd "$T/p"; git init -q --bare .vid/code; git --git-dir=.vid/code symbolic-ref HEAD refs/heads/main
  git init -q "$T/w"; git -C "$T/w" symbolic-ref HEAD refs/heads/main
  for n in base tests head head2; do echo "$n" > "$T/w/$n.txt"; git -C "$T/w" add -A; rr_git -C "$T/w" commit -qm "$n"; eval "RR_$n=\$(git -C \"\$T/w\" rev-parse HEAD)"; done
  RR_RED=$RR_tests; RR_H=$RR_head; RR_H2=$RR_head2; RR_H12=$(printf %s "$RR_H" | cut -c1-12); git -C "$T/w" push -q "$T/p/.vid/code" main
  rr_ticket 1 skeleton '> ROW-009 | behavior | a | b | n/a | The page shows. | REQ-001 | origin: REQ-001
- ROW-009 marks: none' '' ''
  rr_ticket 2 step '> ROW-008 | behavior | a | b | n/a | The list shows. | REQ-001 | origin: REQ-001
- ROW-008 marks: none' '' ''
  rr_ticket 3 step '> ROW-001 | behavior | a | b | n/a | Each search saves. | REQ-001 | origin: REQ-001
- ROW-001 marks: none
> ROW-002 | journey | j | b | n/a | The visitor saves. transitions: 1. a at b · c · d · e · 2. f at g · h · i · j | REQ-001 | origin: REQ-001
- ROW-002 marks: journey; run with the product'"'"'s processes
> hostility | HOS-001 | Send it twice; expect one | protects: INV-001 | disable: remove the merge
- HOS-001 marks: protection
> rule | RULE-001 | Every save is logged | sites: every save | 1 | origin: plan REQ-001
- RULE-001 marks: rule
> difference | DIF-001 | clock | a fake | the real one | same code | paying-step: staging
- DIF-001 marks: owed-staging
> seam | SEAM-001 | the feed | a read | chosen: D-001 | credentials: not-yet | probe: none | evidence: owed | quirks: none
- SEAM-001 marks: seam' '- ROW-009' '- ROW-002-T1 (of the journey ROW-002): make this transition'"'"'s fail-if true, and nothing else
- HOS-001: make this row'"'"'s fail-if true, and nothing else'
  rr_ticket 5 reached '> ROW-001 | behavior | a | b | n/a | Each search saves. | REQ-001 | origin: REQ-001
- ROW-001 marks: none
> difference | DIF-001 | clock | a fake | the real one | same code | paying-step: staging
- DIF-001 marks: owed-staging' '- ROW-001' ''
}
rr_ticket() { { printf '# A ticket\n\n## Header\n\n- number: %s\n- kind: %s\n- rows: x\n\n## Rows\n\n%s\n\n' "$1" "$2" "$3"
  [ "$2" = skeleton ] || printf '## Engines\n\n- primary: alpha\n\n## Regression rows\n\n%s\n\n## Faulted rows\n\n%s\n\n## Rows a ruling reached\n\nnone\n\n' "${4:-none}" "${5:-none}"; printf '## Roles\n\nnone\n'; } > ".vid/tw/out/issue-$1.md"; }
rr_cases() { echo '<?xml version="1.0"?><testsuite name="toy">'; for c; do n=${c%%=*}; v=${c#*=}; case $v in pass) printf '<testcase name="%s" time="1"/>\n' "$n" ;;
      skip) printf '<testcase name="%s"><skipped message="not now"/></testcase>\n' "$n" ;; fail:*) printf '<testcase name="%s"><failure message="%s">trace</failure></testcase>\n' "$n" "${v#fail:}" ;;
      err:*) printf '<testcase name="%s"><error message="%s"/></testcase>\n' "$n" "${v#err:}" ;; esac; done; echo '</testsuite>'; }
rr_put() { mkdir -p "$(dirname "$T/r/$1/$2")"; printf '%s\n' "$3" > "$T/r/$1/$2"; }
rr_send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; [ -z "${RR_EXTRA:-}" ] || echo x > "$T/x/$RR_EXTRA"; git -C "$T/x" init -q; git -C "$T/x" add -A; rr_git -C "$T/x" commit -qm "$1"; git -C "$T/x" push -q -f "$T/p/.vid/code" "HEAD:refs/heads/vid-results/$1"; }
RR_ALL='ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass HOS-001=pass RULE-001=pass ROW-009=pass'
rr_good() { rr_put red-3-1 results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 ROW-002 HOS-001 RULE-001' "$RR_RED")"
  rr_put red-3-1 cases-alpha.xml "$(rr_cases ROW-001=fail:no\ row ROW-002-T1=fail:no\ page ROW-002-T2=fail:no\ page HOS-001=fail:no\ list RULE-001=fail:no\ log)"; rr_send red-3-1
  A=pr-4-$RR_H12-1; rr_put "$A" results.txt "$(printf 'by: TM\ncommit: %s\nenvironments: 2\ncovers: RULE-001 3\nstand-in: clock — a fake — the real one' "$RR_H")"; rr_put "$A" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_send "$A"
  G=grade-pr-4-$RR_H12-1; rr_put "$G" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — seen\nROW-002-T1 kept — seen\nROW-002-T2 kept — seen\nHOS-001 kept — seen\nRULE-001 kept — seen\nDIF-001 kept — seen\nSEAM-001 unclear — which feed?\nfinding: bug — a stray route' "$RR_H")"; rr_send "$G"
  G=sort-pr-4-$RR_H12-1; rr_put "$G" sorted.txt "$(printf 'by: SR\ncommit: %s\nSEAM-001 note it — a note — SEAM-001 unclear — which feed?\nROW-001 drop it — a drop — ROW-001 breached test — not in use' "$RR_H")"; rr_send "$G"; }
