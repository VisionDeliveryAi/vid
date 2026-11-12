#!/bin/sh
# Purpose: DevAgent's deployer, DP (v0.26.10.26.2 R8, v0.26.10.27.1 R8), for the test only: three local targets, never a real cloud deploy. Each report is pushed
# alone on vid-results/deploy-<issue>-<k>, the next free k, in ViD results format 1 (docs/RESULTS-FORMAT.md, V2 §6.4). It reads the record and nothing of ViD's.
# STAGING, D1 (the default target), answering ViD's staging okay: at the named commit, in a clean checkout, the product brought up locally by the dev setup record's
# start: (setup.md, beside run.sh) on a free local port, with the synthetic seed:
#   report.txt   by: DP, commit:, outcome: passed or outcome: failed <step>, and for a failed one product change: yes|no
#   deploy.xml   JUnit, one testcase a deploy step: checkout, start, seed (when the record has seed:), ready (the port answers)
#   staging.txt  a passed one's: staging: http://127.0.0.1:<port>; a signin: <role> <address> line for each of the record's signin: <role> /<path> lines;
#                the record's differs: <what> — <on staging> — <on production> lines, or differs: none
# The staging stays up until `stop` or the next staging deploy replaces it. Each instance holds one of the machine's test environments (v0.26.10.28.2, R1).
# PRODUCTION, D2 (--target production): a second local instance with its own data store, DATA_DIR=<work>/production/data, on its own local port (from
# DP_PRODUCTION_PORT, 47300, kept from deploy to deploy while free), up between deploys. Steps: backup (the record's backup: on the live production, DUMP a new file
# under <work>/production/backups; with no production yet it passes, `nothing to back up`), checkout, then the live instance replaced: migrate (the record's migrate:,
# when it has one), start, seed (the record's production-seed:, SEED=sample, labelled sample data standing for customers', on the first deploy alone), ready.
# report.txt adds production: <address>, and on the first deploy logs: <work>/production/production.log, where every production instance writes. A failed step
# with --product-change is pushed; without, its report is kept and nothing pushed (exit 4), and the same command with --product-change pushes that report,
# deploying nothing again. While production is down after a failed step, or not running, it takes no deploy: recover it first.
# REHEARSAL, RH (--target rehearsal): a third local instance, its own DATA_DIR. Steps: checkout; restore (a dump of production's store taken now, by the record's
# backup:, then the record's restore: into the copy's store); migrate; boot (the record's sealed-start:, which starts it on an internal network with one published
# port, and then sealed: yes; with none, start: and sealed: no), the port answering, from DP_REHEARSAL_PORT (47500). report.txt adds sealed:, copy: <address> and
# a signin: line a role; change.txt, every outcome: migrates: (the record's change-migrates:, yes or no, no when absent), a drops:, rewrites: and services: line for
# each change-drops:, change-rewrites: and change-services: line of the record, drops: none and services: none when it has none. With no production yet: outcome:
# no backup yet, nothing deployed. One rehearsal up at a time: `stop --ask` destroys it, its store and its dump.
# RECOVERY, DP's, for a production okay's newest deploy: rollback runs production at the commit it ran before that deploy, its store as it stands (with none before
# it, production is taken down and its store removed: recovered none); restore puts back that deploy's backup and runs that commit; refused, exit 5, while production
# has been written since its last start (a fresh dump differs from the one taken then, or none could be taken), until --lose-writes, after the owner's answer.
# start:, seed:, production-seed:, backup:, restore:, migrate:, sealed-start: and stop: run under sh -c, in the instance's checkout (a backup of the live production
# in its own), and see PORT, BASE_URL (http://127.0.0.1:<port>), RUN_ID (the instance's id), TARGET (staging, production or rehearsal), STAGING (1 on staging),
# SEED (synthetic on staging, sample on production), DATA_DIR (the instance's data store, production's and the rehearsal's), DUMP (the dump to write or read)
# and an empty NO_PRODUCT. Each process group an instance starts is recorded with its members' starts, and stopped by its id when it goes, after the record's stop:.
#   deploy.sh deploy --setup <record> --ask deploy-<issue> --commit <full id> [--target staging|production|rehearsal] [--seed synthetic] [--product-change no|yes]
#                    a failed step is pushed only with --product-change, DP's judgement whether its fix needs a commit to the code repository: without one,
#                    nothing is pushed, the log is named, exit 4, and DP judges and runs the same command with it
#   deploy.sh deploy … --fail-step <step> --product-change no|yes
#                    the labelled plant, for a test alone: a failed step reported, nothing deployed, the live instance untouched (production's backup taken first)
#   deploy.sh stop [--setup <record>] --ask deploy-<issue>   stops the live staging, or destroys the live rehearsal, when it is that okay's
#   deploy.sh stop [--setup <record>] --target production    takes DevAgent's production down, its store kept: the end of a test alone
#   deploy.sh rollback|restore [--setup <record>] --ask deploy-<issue> [--lose-writes]   prints recovered <the commit production runs now, or none> — <what it did>
#   deploy.sh live [--setup <record>]         live <id> <address>, or live none; and rehearsal <id> <address> while one is up
#   deploy.sh production [--setup <record>]   production <commit> <address>, production down — …, production stopped — …, or production none
# The record defaults to $DM_WORK/dev-setup.txt, or the current folder's. Optional keys: seed:, signin:, differs:, migrate:, sealed-start:, change-migrates:,
# change-drops:, change-rewrites:, change-services:, ready-seconds: (120), startup-seconds: (3600). A production or a rehearsal needs backup: and restore:; the first
# production deploy production-seed:. The first staging port tried is DP_PORT (47100). Exit: 0 pushed, stopped, recovered or listed; 1 refused, not run or not
# pushed; 4 a failed step not pushed; 5 a restore that would lose writes.
# serves: dev side (0.26.10.28.4, M9)
set -eu
die() { echo "deploy.sh: $*" >&2; exit 1; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in deploy|stop|live|production|rollback|restore) ;; *) die 'usage: deploy.sh deploy|stop|live|production|rollback|restore …, see its head' ;; esac
HERE=$(cd "$(dirname "$0")" && pwd -P); RUN=$(dirname "$HERE")/test-manager/run.sh
SETUP=''; ASK=''; COMMIT=''; SEED=synthetic; PC=''; FS=''; TG=''; LW=''
while [ $# -gt 0 ]; do [ "$1" != --lose-writes ] || { LW=1; shift; continue; }; [ $# -ge 2 ] || die "$1 needs a value"
  case $1 in --setup) SETUP=$2 ;; --ask) ASK=$2 ;; --commit) COMMIT=$2 ;; --seed) SEED=$2 ;; --product-change) PC=$2 ;; --fail-step) FS=$2 ;; --target) TG=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
case $TG in ''|staging|rehearsal|production) ;; *) die "--target is staging, rehearsal or production, not '$TG'" ;; esac
[ -z "$TG" ] || [ "$CMD" = deploy ] || [ "$CMD:$TG" = stop:production ] || die '--target goes with deploy, or with stop as --target production'
[ -z "$LW" ] || [ "$CMD" = restore ] || die "--lose-writes is a restore's alone"
TG=${TG:-staging}
[ -n "$SETUP" ] || SETUP=${DM_WORK:-$PWD}/dev-setup.txt; [ -f "$SETUP" ] || die "no dev setup record at '$SETUP': run the setup first"
W=$(cd "$(dirname "$SETUP")" && pwd -P); SETUP=$W/$(basename "$SETUP"); SF=$W/staging; PF=$W/production; HF=$W/rehearsal
d=$W; while :; do [ ! -e "$d/.vid" ] || die "the work folder is in $d, a folder of ViD's records"; [ "$d" != / ] || break; d=$(dirname "$d"); done
key() { sed -n "s/^$1: *//p" "$SETUP" | head -n 1; }
now() { date +%s; }
case $CMD:$TG in live:*|production:*|stop:production) [ -z "$ASK" ] || die "$CMD $([ "$CMD" != stop ] || echo '--target production ')takes no --ask" ;;
  *) printf '%s\n' "$ASK" | grep -Eqx 'deploy-[0-9]+' || die "the ask is deploy-<issue>, not '$ASK'" ;; esac
SUL=$(key startup-seconds | grep . || echo 3600)
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
# fport <first>: the first free local port from it, of 200
fport() { p=$1; e=$(($1 + 200)); while [ "$p" -lt "$e" ] && up "$p"; do p=$((p + 1)); done; [ "$p" -lt "$e" ] || return 1; echo "$p"; }
# names <instance folder>: what the record's commands see
names() { RUN_ID=$(cat "$1/id"); PORT=$(cat "$1/port"); BASE_URL=http://127.0.0.1:$PORT; TARGET=$(cat "$1/target" 2>/dev/null || echo staging); STAGING=''; SEED=''; DATA_DIR=''; DUMP=''; NO_PRODUCT=''
  case $TARGET in staging) STAGING=1; SEED=synthetic ;; production) SEED=sample; DATA_DIR=$PF/data ;; rehearsal) DATA_DIR=$1/data ;; esac
  export RUN_ID PORT BASE_URL TARGET STAGING SEED DATA_DIR DUMP NO_PRODUCT; }
# bounded <seconds> <folder> <command> [<where>]: the command in the folder's checkout, or where, its own process group, recorded; stopped by its group past the
# seconds. RC its exit, 124 when stopped
bounded() { set -m; ( cd "${4:-$2/checkout}" && exec nohup sh -c "$3" ) >> "$2/log" 2>&1 < /dev/null & P=$!; set +m; echo "$P" >> "$2/groups"; n=0
  while kill -0 "$P" 2>/dev/null && [ "$n" -lt "$1" ]; do sleep 1; n=$((n + 1)); done
  if kill -0 "$P" 2>/dev/null; then kill -s TERM -- "-$P" 2>/dev/null || true; sleep 1; kill -s KILL -- "-$P" 2>/dev/null || true; fi
  RC=0; wait "$P" 2>/dev/null || RC=$?; [ "$n" -lt "$1" ] || RC=124; }
# members <folder>: every process now in a recorded group, with its start, so a later stop knows the group is still its own
members() { for g in $(cat "$1/groups"); do ps -A -o pid= -o pgid= | awk -v g="$g" '$2 == g { print $1 }'; done | while read -r p; do
    sh "$RUN" stamp "$p" > "$1/m.$p" 2>/dev/null && [ -s "$1/m.$p" ] || rm -f "$1/m.$p"; done; }
# down <folder>: the record's stop:, then each recorded group a recorded member of which is still itself, by its id; what will not go is named
down() { [ -d "$1/checkout" ] || return 0; names "$1"; bounded "$SUL" "$1" "$(key stop)" || true; G=''
  for m in "$1"/m.*; do [ -f "$m" ] || continue; p=${m##*/m.}; sh "$RUN" is "$p" "$m" || continue; g=$(ps -o pgid= -p "$p" 2>/dev/null | tr -d ' '); case " $G " in *" $g "*) ;; *) G="$G $g" ;; esac; done
  for g in $G; do grep -qx "$g" "$1/groups" || continue; kill -s TERM -- "-$g" 2>/dev/null || true; done; [ -z "$G" ] || sleep 1
  for g in $G; do grep -qx "$g" "$1/groups" && kill -s KILL -- "-$g" 2>/dev/null || true; done
  for m in "$1"/m.*; do [ -f "$m" ] || continue; p=${m##*/m.}; ! sh "$RUN" is "$p" "$m" || echo "deploy.sh: process $p of $(cat "$1/id") not gone" >&2; rm -f "$m"; done
  : > "$1/groups"; rm -rf "$1/checkout"; sh "$RUN" slot free "$SLN.$(cat "$1/target" 2>/dev/null || echo staging)" "$1" || true; }
# slot: this instance's test environment of the machine's (v0.26.10.28.2, R1, run.sh slot): its target's in this work folder, so a replacement keeps the slot
# its predecessor holds and production, up between deploys, holds it for good; while max-environments: are up and none is its own, it waits; down frees it.
# slot <predecessor's folder>: the instance it replaces, counted with it until it is down
SLN=dp-$(printf %s "$W" | cksum | cut -d' ' -f1)
slot() { echo $$ > "$D/dp.pid"; sh "$RUN" stamp $$ > "$D/dp.lstart"; f=''; while :; do rc=0; sh "$RUN" slot take "$SETUP" "$SLN.$TG" instance "$D" "${1:-}" || rc=$?; [ "$rc" != 0 ] || return 0
    [ "$rc" = 1 ] || die "the machine's test environments could not be counted: run.sh slot take, exit $rc"
    [ -n "$f" ] || { echo "waiting for a test environment: max-environments: are up on this machine" >> "$D/log"; echo "deploy.sh: waiting for a test environment: max-environments: are up on this machine" >&2; f=1; }; sleep 5; done; }
# destroy <rehearsal folder>: down, and its store and dump gone
destroy() { down "$1"; rm -rf "$1/data" "$1/dump"; }
lock() { mkdir -p "$W"; L=$W/.deploy-lock; if ! mkdir "$L" 2>/dev/null; then p=$(cat "$L/pid" 2>/dev/null || true); [ -n "$p" ] && kill -0 "$p" 2>/dev/null && die "another deploy runs in $W, pid $p"; rm -rf "$L"; mkdir "$L" || die 'the lock could not be taken'; fi
  echo $$ > "$L/pid"; trap 'rm -rf "$W/.deploy-lock"' EXIT; }
state() { LIVE=$(cat "$SF/live" 2>/dev/null || true); PL=$(cat "$PF/live" 2>/dev/null || true); HL=$(cat "$HF/live" 2>/dev/null || true); }
# pstate: production live, down (a failed deploy or recovery took it down), stopped (its store kept, nothing running) or none
pstate() { if [ -f "$PF/down" ]; then echo down; elif [ -n "$PL" ]; then echo live; elif [ -d "$PF/data" ]; then echo stopped; else echo none; fi; }
state
if [ "$CMD" = live ]; then if [ -n "$LIVE" ]; then P=$(cat "$SF/$LIVE/port"); up "$P" && echo "live $LIVE http://127.0.0.1:$P" || echo "live $LIVE http://127.0.0.1:$P — not answering"; else echo 'live none'; fi
  [ -z "$HL" ] || { P=$(cat "$HF/$HL/port"); up "$P" && echo "rehearsal $HL http://127.0.0.1:$P" || echo "rehearsal $HL http://127.0.0.1:$P — not answering"; }; exit 0; fi
if [ "$CMD" = production ]; then case $(pstate) in
    live) P=$(cat "$PF/$PL/port"); echo "production $(cat "$PF/$PL/commit") http://127.0.0.1:$P$(up "$P" || echo ' — not answering')" ;;
    down) echo "production down — $(cat "$PF/down") failed and took it down: roll it back or restore it" ;;
    stopped) echo 'production stopped — its store kept, nothing running' ;; none) echo 'production none' ;; esac; exit 0; fi
if [ "$CMD" = stop ]; then lock; state
  if [ "$TG" = production ]; then [ -n "$PL" ] || die 'no live production'; down "$PF/$PL"; rm -f "$PF/live"; echo "stopped production $PL; its store kept"; exit 0; fi
  if [ -n "$LIVE" ] && [ "${LIVE%-*}" = "$ASK" ]; then down "$SF/$LIVE"; rm -f "$SF/live"; echo "stopped $LIVE"; exit 0; fi
  if [ -n "$HL" ] && [ "${HL%-*}" = "$ASK" ]; then destroy "$HF/$HL"; rm -f "$HF/live"; echo "destroyed the rehearsal $HL"; exit 0; fi
  die "no live staging of $ASK, nor rehearsal$([ -z "$LIVE" ] || echo ": the live staging is $LIVE")$([ -z "$HL" ] || echo "; the live rehearsal is $HL")"; fi
case_() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-}" >> "$D/cases"; }   # <step> <seconds> <failure message, or nothing> [<its output, or skipped: why>]
xml() { tail -n 20 "$D/log" 2>/dev/null | LC_ALL=C tr -d '\000-\010\013\014\016-\037' > "$D/tail" || true
  LC_ALL=C awk -F'\t' -v tl="$D/tail" 'function e(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); gsub(/"/, "\\&quot;", s); return s }
    { s[++n] = $1; t[n] = $2; m[n] = $3; o[n] = $4; if ($3 != "") f++ }
    END { while ((getline l < tl) > 0) x = x e(l) "\n"; print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"; printf "<testsuite name=\"deploy\" tests=\"%d\" failures=\"%d\">\n", n, f
      for (i = 1; i <= n; i++) if (m[i] != "") printf "  <testcase name=\"%s\" time=\"%s\"><failure message=\"%s\">%s</failure></testcase>\n", s[i], t[i], e(m[i]), x
        else if (o[i] ~ /^skipped: /) printf "  <testcase name=\"%s\" time=\"%s\"><skipped message=\"%s\"/></testcase>\n", s[i], t[i], e(substr(o[i], 10))
        else if (o[i] != "") printf "  <testcase name=\"%s\" time=\"%s\"><system-out>%s</system-out></testcase>\n", s[i], t[i], e(o[i])
        else printf "  <testcase name=\"%s\" time=\"%s\"/>\n", s[i], t[i]
      print "</testsuite>" }' "$D/cases" > "$D/report/$ID/deploy.xml"; rm -f "$D/tail"; }
push() { R=$D/report; git -C "$R" init -q; git -C "$R" add "$ID"; git -C "$R" -c user.name='DevAgent DP' -c user.email=dev@devagent.invalid commit -qm "$ID" -m "Role: DP" > /dev/null 2>&1
  n=0; until git -C "$R" push -q "$REPO" "HEAD:refs/heads/vid-results/$ID" > /dev/null 2>&1; do n=$((n + 1)); [ "$n" -lt 3 ] || return 1; sleep 3; done; }
# change.txt, the rehearsal's, every outcome: the record's word alone, as differs: is
chg() { { echo "migrates: $(key change-migrates | grep . || echo no)"; for k in drops rewrites services; do v=$(sed -n "s/^change-$k: *//p" "$SETUP" | grep . || true)
      if [ -n "$v" ] && [ "$v" != none ]; then printf '%s\n' "$v" | sed "s/^/$k: /"; elif [ "$k" != rewrites ]; then echo "$k: none"; fi; done; } > "$D/report/$ID/change.txt"; }
report() { { echo 'by: DP'; echo "commit: $COMMIT"; if [ -z "${1:-}" ]; then echo 'outcome: passed'; else echo "outcome: failed $1"; [ -z "$PC" ] || echo "product change: $PC"; fi; } > "$D/report/$ID/report.txt"
  [ "$TG" != rehearsal ] || chg; xml; }
pushed() { push || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; }
# failed <step>: the instance that was coming up goes; pushed with a judgement, else nothing pushed and exit 4 (production's report kept for it)
failed() { if [ "$TG" = rehearsal ]; then destroy "$D"; else down "$D"; fi
  if [ -z "$PC" ]; then if [ "$TG" = production ]; then report "$1"; echo "$ID" > "$PF/unpushed"; W4="production $([ -f "$PF/down" ] && echo 'is down' || echo 'runs as it did'); "; fi
    echo "deploy.sh: failed $1, nothing pushed: ${W4:-}its log is $D/log; judge whether the fix needs a commit to the code repository and run the same command with --product-change yes|no" >&2; exit 4; fi
  report "$1"; pushed; }
plant_() { echo "the labelled plant: a failed $1, product change: $PC" >> "$D/log"; rm -rf "$D/checkout"; report "$1"; pushed; }
# run_ <step> <command> [<where>]: the command bounded in the instance, its case; a failure is the step's
run_() { t=$(now); bounded "$SUL" "$D" "$2" "${3:-}"; members "$D"; [ "$RC" = 0 ] || { case_ "$1" $(($(now) - t)) "$([ "$RC" = 124 ] && echo "$1 past its limit" || echo "exit $RC")"; failed "$1"; }; case_ "$1" $(($(now) - t)) ''; }
ready_() { t=$(now); L=$(key ready-seconds | grep . || echo 120); n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done
  up "$PORT" || { case_ "$1" $(($(now) - t)) "port $PORT did not answer within ${L}s"; failed "$1"; }; case_ "$1" $(($(now) - t)) ''; }
checkout_() { t=$(now); git -C "$D/checkout" -c advice.detachedHead=false checkout -q "$COMMIT" >> "$D/log" 2>&1 || { case_ checkout $(($(now) - t)) 'the checkout failed'; failed checkout; }; case_ checkout $(($(now) - t)) ''; }
# mkd <folder>: a new instance's folder; every production instance writes to the one production log
mkd() { rm -rf "$1"; mkdir -p "$1/report/$ID"; echo "$ID" > "$1/id"; echo "$TG" > "$1/target"; : > "$1/groups"; : > "$1/cases"; echo 0 > "$1/port"
  if [ "$TG" = production ]; then : >> "$PF/production.log"; ln -s ../production.log "$1/log"; else : > "$1/log"; fi; }
# pport: production's port, the one it had while free
pport() { p=$(cat "$PF/port" 2>/dev/null || true); { [ -n "$p" ] && ! up "$p"; } || p=$(fport "${DP_PRODUCTION_PORT:-47300}") || die "no free local port from ${DP_PRODUCTION_PORT:-47300}"; echo "$p" > "$D/port"; echo "$p" > "$PF/port"; }
# after <folder>: a dump of production's store just after this instance started, to tell later whether it was written since
after() { DUMP=$1/after.dump; export DUMP; rm -rf "$DUMP"; bounded "$SUL" "$1" "$(key backup)"; [ "$RC" = 0 ] && [ -e "$DUMP" ] || { rm -rf "$DUMP"; echo "the dump after the start failed: a restore will ask first" >> "$1/log"; }; }
REPO=$(key repo); [ -n "$REPO" ] || die 'the record has no repo: line'
if [ "$CMD" = rollback ] || [ "$CMD" = restore ]; then TG=production; lock; state; [ ! -f "$PF/unpushed" ] || die "the failed deploy $(cat "$PF/unpushed") is not pushed yet: push its report first, with --product-change"
  A=$(ls -d "$PF/$ASK"-[0-9]* 2>/dev/null | sed 's|.*-||' | sort -n | tail -n 1); [ -n "$A" ] || die "no production deploy of $ASK here"
  DA=$PF/$ASK-$A; PREV=$(cat "$DA/prev" 2>/dev/null || true); BK=$(cat "$DA/backup" 2>/dev/null || echo none); [ -n "$PREV" ] || die "$ASK-$A recorded no previous commit"
  [ -n "$(key start)" ] && [ -n "$(key backup)" ] && [ -n "$(key restore)" ] || die 'the record has no start:, backup: or restore: line'
  if [ "$CMD" = restore ]; then [ "$BK" != none ] || die "$ASK-$A took no backup, no production being there before it: nothing to restore; roll back instead"; [ -e "$BK" ] || die "the backup $BK is gone"
    if [ -n "$PL" ] && [ -z "$LW" ]; then lose=1; if [ -e "$PF/$PL/after.dump" ]; then names "$PF/$PL"; DUMP=$PF/$PL/now.dump; export DUMP; rm -rf "$DUMP"; bounded "$SUL" "$PF/$PL" "$(key backup)"
        [ "$RC" != 0 ] || ! cmp -s "$DUMP" "$PF/$PL/after.dump" || lose=''; rm -rf "$DUMP"; fi
      [ -z "$lose" ] || { echo "deploy.sh: a restore of $BK would lose the writes made on production since $PL started$([ -e "$PF/$PL/after.dump" ] || echo ', which could not be measured'): ask on the okay first, with the recovery point and the writes at risk; with the owner's yes, restore --lose-writes" >&2; exit 5; }; fi; fi
  if [ "$PREV" = none ]; then [ "$CMD" = rollback ] || die 'nothing ran before it to restore to'; [ -z "$PL" ] || down "$PF/$PL"; rm -f "$PF/live" "$PF/down" "$PF/seeded"; rm -rf "$PF/data"
    echo "recovered none — DevAgent's production taken down and its store removed: no production exists"; exit 0; fi
  j=1; while [ -e "$PF/$ASK-r$j" ]; do j=$((j + 1)); done; ID=$ASK-r$j; D=$PF/$ID; COMMIT=$PREV; mkd "$D"
  { git clone -q "$REPO" "$D/checkout" && git -C "$D/checkout" -c advice.detachedHead=false checkout -q "$PREV"; } >> "$D/log" 2>&1 || { rm -rf "$D"; die "$PREV could not be checked out from $REPO; production untouched"; }
  slot "${PL:+$PF/$PL}"; [ -z "$PL" ] || { down "$PF/$PL"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; echo "$ID" > "$PF/down"; mkdir -p "$PF/data"; pport; names "$D"
  rec() { bounded "$SUL" "$D" "$2"; members "$D"; [ "$RC" = 0 ] || { down "$D"; die "the $CMD failed at $1, exit $RC: production is down; its log is $PF/production.log"; }; }
  [ "$CMD" != restore ] || { DUMP=$BK; export DUMP; rec restore "$(key restore)"; }; rec start "$(key start)"
  L=$(key ready-seconds | grep . || echo 120); n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done; up "$PORT" || { down "$D"; die "the $CMD's port $PORT did not answer within ${L}s: production is down"; }
  echo "$PREV" > "$D/commit"; after "$D"; echo "$ID" > "$PF/live"; rm -f "$PF/down"
  if [ "$CMD" = restore ]; then echo "recovered $PREV — production's store restored from $BK, the backup $ASK-$A took, and run at $PREV, $BASE_URL"
  else echo "recovered $PREV — production rolled back to $PREV, the commit it ran before $ASK-$A, its store as it stood, $BASE_URL"; fi; exit 0; fi
# deploy
case $COMMIT in *[!0-9a-f]*|'') die 'the commit must be a full id' ;; esac; [ "${#COMMIT}" -eq 40 ] || die 'the commit must be a full id'
[ "$SEED" = synthetic ] || die "DevAgent deploys on the synthetic seed alone, not '$SEED': an owner-only step, DP's question on the okay"
case $PC in ''|yes|no) ;; *) die "--product-change is yes or no, not '$PC'" ;; esac
[ -z "$FS" ] || { printf '%s\n' "$FS" | grep -Eqx '[a-z][a-z0-9-]*' || die "a step is one word, not '$FS'"; [ -n "$PC" ] || die 'a plant needs --product-change yes|no'; }
[ -n "$FS" ] || [ -n "$(key start)" ] || { [ "$TG" = rehearsal ] && [ -n "$(key sealed-start)" ]; } || die 'the record has no start: line'
SI=$(sed -n 's/^signin: *//p' "$SETUP"); printf '%s\n' "$SI" | awk 'NF && !($0 ~ /^[A-Za-z][A-Za-z0-9_-]* \/[^ ]*$/) { print; exit 1 }' > /dev/null || die "a signin: line is not <role> /<path>: $(printf '%s\n' "$SI" | awk 'NF && !($0 ~ /^[A-Za-z][A-Za-z0-9_-]* \/[^ ]*$/)' | head -n 1)"
DF=$(sed -n 's/^differs: *//p' "$SETUP"); printf '%s\n' "$DF" | awk 'NF && $0 != "none" && split($0, x, " — ") != 3 { exit 1 }' || die 'a differs: line is not <what> — <on staging> — <on production>'
[ "$(printf '%s\n' "$DF" | grep -c .)" -le 1 ] || ! printf '%s\n' "$DF" | grep -qx none || die 'differs: none stands alone'
case $TG in production|rehearsal) [ -n "$(key backup)" ] && [ -n "$(key restore)" ] || die "the record has no backup: or restore: line: a $TG needs both, the product's own way to dump its data store and to load a dump" ;; esac
if [ "$TG" = rehearsal ]; then case $(key change-migrates) in ''|yes|no) ;; *) die "change-migrates: is yes or no, not '$(key change-migrates)'" ;; esac
  for k in drops rewrites services; do v=$(sed -n "s/^change-$k: *//p" "$SETUP"); [ "$(printf '%s\n' "$v" | grep -c .)" -le 1 ] || ! printf '%s\n' "$v" | grep -qx none || die "change-$k: none stands alone"; done; fi
lock; state
o=$(git ls-remote --heads "$REPO" "vid-results/$ASK-*" 2>&1) || die "the results branches of $REPO could not be read: $(printf '%s' "$o" | tr '\n' ' ')"
K=$(printf '%s\n' "$o" | sed -n "s|.*refs/heads/vid-results/$ASK-\([0-9][0-9]*\)\$|\1|p" | sort -n | tail -n 1); ID=$ASK-$((${K:-0} + 1))
case $TG in staging) D=$SF/$ID; [ "$LIVE" != "$ID" ] || die "$ID is live and not pushed: stop it first" ;; production) D=$PF/$ID ;; rehearsal) D=$HF/$ID; [ "$HL" != "$ID" ] || die "$ID is live and not pushed: stop it first" ;; esac
if [ "$TG" = production ] && [ -f "$PF/unpushed" ]; then U=$(cat "$PF/unpushed")
  [ "$U" = "$ID" ] || die "the failed production deploy $U waits for its judgement: the same command as it, with --product-change yes|no, pushes its report"
  [ -n "$PC" ] && [ -z "$FS" ] || die "$ID failed and is not pushed: the same command with --product-change yes|no, and no plant, pushes its report"
  [ "$(sed -n 's/^commit: //p' "$D/report/$ID/report.txt")" = "$COMMIT" ] || die "the kept report of $ID is of another commit"
  echo "product change: $PC" >> "$D/report/$ID/report.txt"; push || die "not pushed: vid-results/$ID"; rm -f "$PF/unpushed"; echo "pushed vid-results/$ID"; exit 0; fi
FIRST=''; if [ "$TG" = production ]; then case $(pstate) in down) die "production is down since $(cat "$PF/down") failed: recover it first, deploy.sh rollback or restore" ;; stopped) die 'the DevAgent production is stopped: nothing to back up from' ;; esac
  [ -d "$PF/data" ] || FIRST=1; [ -z "$FIRST" ] || [ -n "$FS" ] || [ -n "$(key production-seed)" ] || die 'the record has no production-seed: line: the DevAgent production is seeded once, on its first deploy, with labelled sample data'; mkdir -p "$PF"; fi
mkd "$D"
git clone -q "$REPO" "$D/checkout" >> "$D/log" 2>&1 || { rm -rf "$D"; die "$REPO could not be cloned"; }
git -C "$D/checkout" cat-file -e "$COMMIT^{commit}" 2>/dev/null || { rm -rf "$D"; die "$COMMIT is not on origin; nothing pushed"; }
if [ "$TG" = production ]; then
  if [ -n "$PL" ]; then cat "$PF/$PL/commit" > "$D/prev"; else echo none > "$D/prev"; fi; echo none > "$D/backup"
  [ "$FS" != backup ] || { case_ backup 0 'a labelled plant (--fail-step backup): nothing was backed up or deployed'; plant_ backup; }
  t=$(now); if [ -n "$PL" ]; then mkdir -p "$PF/backups"; names "$PF/$PL"; DUMP=$PF/backups/$ID.dump; export DUMP; rm -rf "$DUMP"; bounded "$SUL" "$D" "$(key backup)" "$PF/$PL/checkout"; members "$D"
    [ "$RC" = 0 ] && [ -e "$DUMP" ] || { case_ backup $(($(now) - t)) "$([ "$RC" = 0 ] && echo "the backup wrote no dump at $DUMP" || echo "exit $RC")"; failed backup; }
    echo "$DUMP" > "$D/backup"; case_ backup $(($(now) - t)) '' "backed up to $DUMP"
  else case_ backup 0 '' 'nothing to back up'; fi
  [ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was deployed, production untouched"; plant_ "$FS"; }
  checkout_
  slot "${PL:+$PF/$PL}"; [ -z "$PL" ] || { down "$PF/$PL"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; mkdir -p "$PF/data"; echo "$ID" > "$PF/down"; pport; names "$D"
  if [ -n "$(key migrate)" ]; then run_ migrate "$(key migrate)"; else case_ migrate 0 '' 'the record has no migrate:'; fi
  run_ start "$(key start)"
  [ -z "$FIRST" ] || { run_ seed "$(key production-seed)"; : > "$PF/seeded"; }
  ready_ ready
  echo "$COMMIT" > "$D/commit"; after "$D"; names "$D"; report; { echo "production: $BASE_URL"; [ -z "$FIRST" ] || echo "logs: $PF/production.log"; } >> "$D/report/$ID/report.txt"
  echo "$ID" > "$PF/live"; rm -f "$PF/down"; push || die "not pushed: vid-results/$ID; production runs it"; echo "pushed vid-results/$ID"; exit 0; fi
if [ "$TG" = rehearsal ]; then
  [ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was restored or deployed, the live rehearsal untouched"; plant_ "$FS"; }
  if [ "$(pstate)" = none ]; then case_ restore 0 '' 'skipped: no backup yet: no production exists; nothing restored or deployed'
    { echo 'by: DP'; echo "commit: $COMMIT"; echo 'outcome: no backup yet'; } > "$D/report/$ID/report.txt"; chg; xml; rm -rf "$D/checkout"; pushed; fi
  slot "${HL:+$HF/$HL}"; [ -z "$HL" ] || { destroy "$HF/$HL"; rm -f "$HF/live"; echo "replaced $HL" >> "$D/log"; }
  checkout_
  p=$(fport "${DP_REHEARSAL_PORT:-47500}") || die "no free local port from ${DP_REHEARSAL_PORT:-47500}"; echo "$p" > "$D/port"; mkdir -p "$D/data"
  # restore: production's store dumped now, by the live production's own checkout when it runs, then loaded into the copy's
  t=$(now); if [ -n "$PL" ]; then names "$PF/$PL"; DUMP=$D/dump; export DUMP; bounded "$SUL" "$D" "$(key backup)" "$PF/$PL/checkout"
  else names "$D"; DATA_DIR=$PF/data; DUMP=$D/dump; export DATA_DIR DUMP; bounded "$SUL" "$D" "$(key backup)"; fi; members "$D"
  [ "$RC" = 0 ] && [ -e "$D/dump" ] || { case_ restore $(($(now) - t)) "the dump of production failed: $([ "$RC" = 0 ] && echo "no dump at $D/dump" || echo "exit $RC")"; failed restore; }
  DT=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); names "$D"; DUMP=$D/dump; export DUMP; bounded "$SUL" "$D" "$(key restore)"; members "$D"
  [ "$RC" = 0 ] || { case_ restore $(($(now) - t)) "the restore: exit $RC"; failed restore; }; case_ restore $(($(now) - t)) '' "restored from a dump of production taken at $DT"
  names "$D"; if [ -n "$(key migrate)" ]; then run_ migrate "$(key migrate)"; else case_ migrate 0 '' 'the record has no migrate:'; fi
  SE=no; B=$(key start); [ -z "$(key sealed-start)" ] || { SE=yes; B=$(key sealed-start); }
  t=$(now); bounded "$SUL" "$D" "$B"; members "$D"; [ "$RC" = 0 ] || { case_ boot $(($(now) - t)) "$([ "$RC" = 124 ] && echo 'start-up past its limit' || echo "exit $RC")"; failed boot; }
  L=$(key ready-seconds | grep . || echo 120); n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done
  up "$PORT" || { case_ boot $(($(now) - t)) "port $PORT did not answer within ${L}s"; failed boot; }
  case_ boot $(($(now) - t)) '' "$([ "$SE" = yes ] && echo 'started by sealed-start:, an internal network and one published port' || echo 'started by start:: not sealed')"
  report; { echo "sealed: $SE"; echo "copy: $BASE_URL"; printf '%s\n' "$SI" | awk -v b="$BASE_URL" 'NF { print "signin: " $1 " " b $2 }'; } >> "$D/report/$ID/report.txt"
  push || { destroy "$D"; die "not pushed: vid-results/$ID; the copy destroyed"; }; echo "$ID" > "$HF/live"; echo "pushed vid-results/$ID"; exit 0; fi
# staging
[ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was deployed"; plant_ "$FS"; }
# a real deploy: the live staging goes first, so staging holds one candidate
slot "${LIVE:+$SF/$LIVE}"; [ -z "$LIVE" ] || { down "$SF/$LIVE"; rm -f "$SF/live"; echo "replaced $LIVE" >> "$D/log"; }
checkout_
p=$(fport "${DP_PORT:-47100}") || die "no free local port from ${DP_PORT:-47100}"; echo "$p" > "$D/port"; names "$D"
run_ start "$(key start)"
[ -z "$(key seed)" ] || run_ seed "$(key seed)"
ready_ ready
{ echo "staging: $BASE_URL"; printf '%s\n' "$SI" | awk -v b="$BASE_URL" 'NF { print "signin: " $1 " " b $2 }'; if [ -n "$DF" ]; then printf '%s\n' "$DF" | sed 's/^/differs: /'; else echo 'differs: none'; fi; } > "$D/report/$ID/staging.txt"
report; push || { down "$D"; die "not pushed: vid-results/$ID; the staging taken down"; }; echo "$ID" > "$SF/live"; echo "pushed vid-results/$ID"; exit 0
