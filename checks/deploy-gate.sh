#!/bin/sh
# Purpose: ViD deploy's gate record (v0.9.6.2 spec 3.5, R5) — vid-deploy
# calls it at each gate, at each owner confirmation and at a rollback; it
# writes one event through checks/event.sh (so at the run's home) and NEVER
# refuses: a gate 3 start with no recorded gate 2 pass is written like any
# other, and the analysis reports the missing record; deploy's own rules
# are unchanged. A platform command run outside it is not recorded, so a
# missing record means "not recorded", not "not done". Only a call that
# does not parse is turned back (usage, exit 2), writing nothing.
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
case "$A" in
  1|2|3)
    case "$B" in
      start) tok "$CAND"; tok "$ENVN"; sh "$D/event.sh" "deploy-gate gate=$A state=start candidate=$CAND env=$ENVN" ;;
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
