#!/bin/sh
# Purpose: ViD deploy's gate record (v0.9.6.2 spec 3.5, R5) — vid-deploy
# calls it at each gate, at each owner confirmation and at a rollback; it
# writes one event through checks/event.sh (so at the run's home). A
# platform command run outside it is not recorded, so a missing record
# means "not recorded", not "not done". A call that does not parse is
# turned back (usage, exit 2), writing nothing.
# 0.26.11.1.2 (R2): `3 start` refuses — exit 1, one line
# `deploy-gate: refused — <the first missing fact>`, nothing written —
# unless all five facts hold, read from .vid/metrics-events, DEPLOYMENT.md
# and the inventory where the deploy runs (as checks/stages.sh reads them),
# every commit resolved, so a full commit, a short one or a tag naming the
# same commit is the same commit:
#   1. the newest gate-2 pass names <c> (staging's exact commit; HEAD is
#      not compared: gate 1 pays its rows in a law commit after it);
#   2. a `deploy-check target=production sha=<c> … result=ready` event;
#   3. after the first such event, gate 1 for <c>: a start for <c> whose end
#      is a pass, with no fail for <c> after it; or a first-deploy skip,
#      while no gate-3 start is recorded and the deploy log holds no row;
#   4. after that gate-1 record and after any earlier gate-3 start, the
#      owner's cutover yes for <c> (`confirm answer --what "cutover <c>: …"
#      --result yes`), with no no to a cutover question for <c> after it;
#      no other confirmation is read;
#   5. `sh checks/stages.sh debt --target production` succeeds and prints
#      no row owed to gate 1 or 2.
# The owner's yes never stands in for a missing record. Every other call
# (gates 1 and 2, end, skipped, confirm, rollback) only records: a rollback
# is never refused.
#   <gate> start --candidate <commit> --env <name>
#        → deploy-gate gate=<gate> state=start candidate=<commit> env=<name>
#   <gate> end --result pass|fail [--rollback-target <ref>]
#        → deploy-gate gate=<gate> state=end result=<r> [rollback-target=<ref>]
#   1 skipped --reason first-deploy
#        → deploy-gate gate=1 state=skipped reason=first-deploy
#   confirm ask --what "<line>"
#        → deploy-confirm state=ask what="<line>"
#   confirm answer --what "<line>" --result yes|no
#        → deploy-confirm state=answer what="<line>" result=<yes|no>
#   rollback --gate <gate> --why "<line>"
#        → deploy-rollback gate=<gate> why="<line>"
# <gate> is 1, 2 or 3. Usage: sh checks/deploy-gate.sh <one of the above>
set -eu
usage() { echo 'ViD deploy-gate: usage — sh checks/deploy-gate.sh <1|2|3> start --candidate <commit> --env <name> | <1|2|3> end --result pass|fail [--rollback-target <ref>] | 1 skipped --reason first-deploy | confirm ask --what "<line>" | confirm answer --what "<line>" --result yes|no | rollback --gate <1|2|3> --why "<line>"' >&2; exit 2; }
D=$(dirname "$0")   # checks/event.sh beside this script
A=${1:-}; [ $# -ge 1 ] || usage; shift
B=''; if [ "$A" != rollback ]; then B=${1:-}; [ $# -ge 1 ] || usage; shift; fi
CAND=''; ENVN=''; RES=''; RBT=''; REASON=''; WHAT=''; GATE=''; WHY=''
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || usage
  case "$1" in
    --candidate) CAND=$2 ;; --env) ENVN=$2 ;; --result) RES=$2 ;; --rollback-target) RBT=$2 ;;
    --reason) REASON=$2 ;; --what) WHAT=$2 ;; --gate) GATE=$2 ;; --why) WHY=$2 ;;
    *) usage ;;
  esac
  shift 2
done
tok() { case "$1" in ''|*[[:space:]\"]*) usage ;; esac; }   # one word
line() { case "$1" in ''|*'
'*) usage ;; esac; }                                        # one line
q() { printf '%s' "$1" | tr '"' "'"; }                        # quoted in the event
refuse() { echo "deploy-gate: refused — $*"; exit 1; }
full() { git rev-parse -q --verify "$1^{commit}" 2>/dev/null; }   # a commit, a short one or a tag, resolved
kvawk='function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
# gate3 <candidate>: the five facts (R2), in order; the first one missing refuses
gate3() {
  EV=.vid/metrics-events; [ -f "$EV" ] || EV=/dev/null
  CC=$(full "$1") || refuse "the candidate $1 is no commit here"
  C12=$(printf '%s' "$CC" | cut -c1-12)
  # 1. the newest gate-2 pass, as checks/stages.sh reads it
  G2=$(awk "$kvawk"'
    $1 == "deploy-gate" && kv("gate") == "2" { if (kv("state") == "start") c = kv("candidate"); else if (kv("state") == "end") { if (kv("result") == "pass" && c != "") p = c; c = "" } } END { print p }' "$EV")
  [ -n "$G2" ] || refuse "no gate-2 pass is recorded: deploy $C12 to staging first"
  GC=$(full "$G2") || refuse "the newest gate-2 pass names $G2, which is no commit here"
  [ "$GC" = "$CC" ] || refuse "the newest gate-2 pass is on $(printf '%s' "$GC" | cut -c1-12), not on the candidate $C12: deploy it to staging first"
  # 2. the production check's ready record for it; gate 1 follows the first one
  DC=0
  for _l in $(awk '$1 == "deploy-check" && / target=production / && / result=ready( |$)/ { for (i = 2; i <= NF; i++) if (index($i, "sha=") == 1) print NR ":" substr($i, 5) }' "$EV"); do
    if [ "$(full "${_l#*:}" || true)" = "$CC" ]; then DC=${_l%%:*}; break; fi
  done
  [ "$DC" -gt 0 ] || refuse "no ready production check names $C12 (sh checks/metrics.sh deploy-check --target production --record)"
  # the deploy log's newest production row, as checks/stages.sh reads it
  PRODC=$( [ -f DEPLOYMENT.md ] && awk '/^## /{ on = ($0 ~ /^## Deploy log/) ; next } on && /^\|/ { if ($0 ~ /^\|[ \t:|-]*$/) next; n = split($0, f, "|"); c = f[4]; gsub(/^[ \t`]+|[ \t`]+$/, "", c); if (c == "Commit" || c == "" || c ~ /^\{\{/) next; last = c } END { if (last != "") print last }' DEPLOYMENT.md || true)
  # 3 and 4: the gate records and the cutover answers, in order, one a line: <line> g3|g1|cut …
  R=$(awk "$kvawk"'
    $1 == "deploy-gate" { g = kv("gate"); s = kv("state"); if (g == "3" && s == "start") print NR " g3 start"
      else if (g == "1") { if (s == "start") print NR " g1 start " kv("candidate"); else if (s == "end") print NR " g1 end " kv("result"); else if (s == "skipped") print NR " g1 skip" } }
    $1 == "deploy-confirm" && match($0, / what="[^"]*"/) { q = substr($0, RSTART, RLENGTH); x = substr($0, 1, RSTART - 1) substr($0, RSTART + RLENGTH)
      # state and result read with the quoted question removed, so its words are never taken for them
      s = ""; r = ""; n = split(x, F, " "); for (i = 2; i <= n; i++) { if (index(F[i], "state=") == 1) s = substr(F[i], 7); else if (index(F[i], "result=") == 1) r = substr(F[i], 8) }
      if (s == "answer" && (r == "yes" || r == "no") && match(q, /^ what="cutover [^ :"]+:/)) print NR " cut " substr(q, 16, RLENGTH - 16) " " r }' "$EV")
  G3ANY=no; case "$R" in *' g3 start'*) G3ANY=yes ;; esac
  G1=0; G1W=''; L3=0; CUR=''
  while IFS=' ' read -r _n _k _a _b; do
    case "$_k" in
      g3) L3=$_n ;;
      g1) [ "$_n" -gt "$DC" ] || continue
        case "$_a" in
          start) CUR=$(full "$_b" || true) ;;
          end) if [ "$CUR" = "$CC" ]; then if [ "$_b" = pass ]; then G1=$_n; G1W=pass; else G1=0; G1W=fail; fi; fi ;;   # CUR kept: a later end belongs to the last start
          skip) if [ "$G3ANY" = yes ]; then G1W=skip3; elif [ -n "$PRODC" ]; then G1W=skiplog; else G1=$_n; G1W=skip; fi ;;
        esac ;;
    esac
  done <<EOR
$R
EOR
  if [ "$G1" -eq 0 ]; then
    case "$G1W" in
      fail) refuse "gate 1's last record for $C12 is a fail: rehearse again" ;;
      skip3) refuse "gate 1 was skipped as a first deploy, but a gate-3 start is recorded: gate 1 applies" ;;
      skiplog) refuse "gate 1 was skipped as a first deploy, but the deploy log holds a production row ($PRODC): gate 1 applies" ;;
      *) refuse "gate 1 has not passed on $C12 since its production check (deploy-gate.sh 1 start, then 1 end)" ;;
    esac
  fi
  M=$G1; if [ "$L3" -gt "$M" ]; then M=$L3; fi
  Y=0
  while IFS=' ' read -r _n _k _a _b; do
    [ "$_k" = cut ] && [ "$_n" -gt "$M" ] || continue
    [ "$(full "$_a" || true)" = "$CC" ] || continue
    if [ "$_b" = yes ]; then Y=$_n; else Y=0; fi
  done <<EOR
$R
EOR
  [ "$Y" -gt 0 ] || refuse "no cutover yes from the owner for $C12 after gate 1 and the last gate-3 start (confirm answer --what \"cutover $C12: …\" --result yes)"
  # 5. no row owed to gate 1 or 2 unpaid
  _o=$(sh "$D/stages.sh" debt --target production 2>&1) || refuse "the deploy debt cannot be read (checks/stages.sh debt): $(printf '%s\n' "$_o" | sed -n 1p)"
  _ow=$(printf '%s\n' "$_o" | grep -E '^owed: [^ ]+ gate [12]$' | sed -n 1p || true)
  [ -z "$_ow" ] || refuse "${_ow#owed: } is unpaid: gate 3 cannot open with a row owed to gate 1 or 2"
}
case "$A" in
  1|2|3)
    case "$B" in
      start) tok "$CAND"; tok "$ENVN"; [ "$A" != 3 ] || gate3 "$CAND"; sh "$D/event.sh" "deploy-gate gate=$A state=start candidate=$CAND env=$ENVN" ;;
      end)
        case "$RES" in pass|fail) ;; *) usage ;; esac
        if [ -n "$RBT" ]; then tok "$RBT"; sh "$D/event.sh" "deploy-gate gate=$A state=end result=$RES rollback-target=$RBT"
        else sh "$D/event.sh" "deploy-gate gate=$A state=end result=$RES"; fi ;;
      skipped) [ "$A" = 1 ] && [ "$REASON" = first-deploy ] || usage; sh "$D/event.sh" "deploy-gate gate=1 state=skipped reason=first-deploy" ;;
      *) usage ;;
    esac ;;
  confirm)
    line "$WHAT"; W=$(q "$WHAT")
    case "$B" in
      ask) sh "$D/event.sh" "deploy-confirm state=ask what=\"$W\"" ;;
      answer) case "$RES" in yes|no) ;; *) usage ;; esac; sh "$D/event.sh" "deploy-confirm state=answer what=\"$W\" result=$RES" ;;
      *) usage ;;
    esac ;;
  rollback)
    case "$GATE" in 1|2|3) ;; *) usage ;; esac
    line "$WHY"; sh "$D/event.sh" "deploy-rollback gate=$GATE why=\"$(q "$WHY")\"" ;;
  *) usage ;;
esac
