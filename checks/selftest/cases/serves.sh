#!/bin/sh
# Purpose: selftest case — what each script serves, said in its header (0.26.10.28.4, 9.3 R7, M9). Every script of checks/ (its hooks and the self-test
# runner among them) but develop's own six has exactly one `serves:` line in its head comment, its word develop, tickets, both or dev side; the 12
# ticket scripts and lib.sh say tickets, and github.sh both (0.26.10.28.7: the share works in every mode). Develop's own (metrics, brief, evidence, test, stages, deploy-gate) have none. Where devagent/ is here, its
# scripts say dev side. Env: CHECKS.
set -eu
fail() { echo "serves: $*" >&2; exit 1; }
head_() { awk 'NR == 1 { next } /^#/ { print; next } { exit }' "$1"; }
for f in "$CHECKS"/*.sh "$CHECKS"/hooks/commit-msg "$CHECKS"/hooks/pre-commit "$CHECKS"/hooks/post-commit "$CHECKS"/selftest/run.sh; do b=${f#"$CHECKS"/}
  n=$(grep -c '^# serves:' "$f" || true); h=$(head_ "$f" | grep -c '^# serves:' || true)
  case $b in metrics.sh|brief.sh|evidence.sh|test.sh|stages.sh|deploy-gate.sh) [ "$n" = 0 ] || fail "$b is develop's own and says what it serves"; continue ;; esac
  [ "$n" = 1 ] && [ "$h" = 1 ] || fail "$b has $n serves: lines ($h in its head)"
  w=$(sed -n 's/^# serves: \([a-z][a-z ]*[a-z]\)\( (.*)\)\{0,1\}$/\1/p' "$f"); case $w in develop|tickets|both|'dev side') ;; *) fail "$b serves '$w', not develop, tickets, both or dev side" ;; esac
  case $b in close.sh|decide.sh|end.sh|grade.sh|land.sh|planner.sh|queue.sh|refresh.sh|results.sh|round.sh|walk.sh|writer.sh|lib.sh) [ "$w" = tickets ] || fail "$b is a ticket script and serves $w" ;;
    github.sh) [ "$w" = both ] || fail "github.sh serves $w, not both (the share works in every mode, 0.26.10.28.7)" ;; esac; done
[ -d "$CHECKS/../devagent" ] || { echo 'serves: ok'; exit 0; }
for f in "$CHECKS"/../devagent/*/*.sh; do [ "$(head_ "$f" | grep -c '^# serves: dev side' || true)" = 1 ] && [ "$(grep -c '^# serves:' "$f")" = 1 ] || fail "devagent's $(basename "$f") does not say dev side once"; done
echo 'serves: ok'
