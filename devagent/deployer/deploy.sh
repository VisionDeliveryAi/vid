#!/bin/sh
# Purpose: DevAgent's deployer, DP (v0.26.10.26.2 R8, v0.26.10.27.1 R8, 0.26.11.1.1 R1). Two modes. HOSTED, when the dev setup record has a host: line: staging and
# production on the project's chosen host, through the record's host lines (setup.md), which the deployer role writes as it sets the host up; the rehearsal still
# a sealed local copy. LOCAL, with no host: line, for a test alone: three local copies. Each report is pushed alone on vid-results/deploy-<issue>-<k>, the next free
# k, in ViD results format 1 (docs/RESULTS-FORMAT.md, V2 §6.4). It reads the record and nothing of ViD's.
# HOSTED (0.26.11.1.1 R1): before any deploy, rollback or restore, the record's host-login: runs (exit 0 while the host's tool is logged in); its failure refuses,
# exit 1, naming the log-in as the owner's step, nothing run or pushed. A hosted staging or production takes no local port and none of the machine's test
# environments; its commands see BASE_URL its address (staging-address:, production-address:), PORT and DATA_DIR empty. deploy: deploys the instance's checkout to
# TARGET on the host; ready is the address giving any web answer (curl) within ready-seconds:. Staging: checkout, seed (with --seed production: production's dump
# taken now by backup: with TARGET=production, loaded by restore: with TARGET=staging, R6), migrate, deploy, seed (the record's seed:, on the synthetic seed), ready;
# it stays up between deploys (stop --ask says so and takes nothing down; staging.txt adds stays: up). Production: backup (by backup:, TARGET=production; on the
# first, nothing to back up), checkout, migrate, deploy, ready; no production-seed:; report.txt adds production: <production-address>, and on the first deploy
# logs: <the record's production-logs:>. A hosted production exists once this script's own record says so, production/hosted, written by its first passed deploy.
# Rollback deploys the earlier commit; with none before it, refused, exit 1, nothing taken down: DP asks the owner. stop --target production refuses a hosted one.
# STAGING, D1 (the default target), local: at the named commit, in a clean checkout, the product brought up locally by the dev setup record's start: (setup.md, beside
# run.sh) on a free local port, with the synthetic seed:
#   report.txt   by: DP, commit:, outcome: passed or outcome: failed <step>, and for a failed one product change: yes|no; 0.26.10.29.5 (DP-1 R2), every
#                report of every target: a decision: <what> | why: <why> line for each of the record's decision: lines, or decisions: none
#   deploy.xml   JUnit, one testcase a deploy step: checkout, start, seed (when the record has seed:), ready (the port answers)
#   staging.txt  a passed one's: staging: http://127.0.0.1:<port>; a signin: <role> <address> line for each of the record's signin: <role> /<path> lines;
#                the record's differs: <what> — <on staging> — <on production> lines, or differs: none; 0.26.11.1.1 (R4, R6): the record's seam: <row> real
#                and seam: <row> stand-in — <why> lines, and seed: synthetic|production; 0.26.11.1.2 (R9), after the signin: lines, the record's first
#                mail: <address> — <how to read it> and clock: <address> — <how to move it>, an address starting / put on the staging's, as signin:'s are;
#                0.26.11.1.3 (R3), after the seam: lines, each of the record's real: #<this okay's issue>-<n> lines, the answers to the okay's real checks,
#                a later line of a key in place of an earlier one; a line for another okay is not copied
#   duties.txt   0.26.11.1.1 (R3), a passed D1's or D2's: one <duty>: done|not needed|not done — <words> line a duty of its target, from the record's
#                duty: <duty> — <answer> — <words> lines; a hosted deploy is refused while a duty of its target has none, a plant needing none. With no host:,
#                each is <duty>: not needed — a local copy, for a test. Staging's: log-in environments outside-services sending-domain deploy-notes captures;
#                production's: service-switch-on backups point-in-time-recovery storage-versioning dns https monitoring. A failed deploy carries none
# The staging stays up until `stop` or the next staging deploy replaces it. Each local instance holds one of the machine's test environments (v0.26.10.28.2, R1).
# PRODUCTION, D2 (--target production), local: a second local instance with its own data store, DATA_DIR=<work>/production/data, on its own local port (from
# DP_PRODUCTION_PORT, 47300, kept from deploy to deploy while free), up between deploys. Steps: backup (the record's backup: on the live production, DUMP a new file
# under <work>/production/backups; with no production yet it passes, `nothing to back up`), checkout, then the live instance replaced: migrate (the record's migrate:,
# when it has one), start, seed (the record's production-seed:, SEED=sample, labelled sample data standing for customers', on the first deploy alone), ready.
# report.txt adds production: <address>, and on the first deploy logs: <work>/production/production.log, where every production instance writes. A failed step
# with --product-change is pushed; without, its report is kept and nothing pushed (exit 4), and the same command with --product-change pushes that report,
# deploying nothing again. While production is down after a failed step, or not running, it takes no deploy: recover it first.
# REHEARSAL, RH (--target rehearsal), a local copy in both modes, its own DATA_DIR. Steps: checkout; restore (a dump of production's store taken now, by the
# record's backup:, then the record's restore: into the copy's store); migrate; kept (0.26.11.1.1 R5: the record's kept:, seeing DUMP, the dump restored, and
# DATA_DIR, the migrated copy, prints kept: <table> — <n> rows lines, or kept: none — <why>, which report.txt holds; its non-zero exit, a row lost or changed, is
# outcome: failed kept; with no kept: line a rehearsal is refused); boot (the record's sealed-start:, which starts it on an internal network with one published
# port, and then sealed: yes; with none, start: and sealed: no), the port answering, from DP_REHEARSAL_PORT (47500). report.txt adds sealed:, copy: <address>
# and a signin: line a role; change.txt, every outcome: migrates: (the record's change-migrates:, yes or no, no when absent), a drops:, rewrites: and services:
# line for each change-drops:, change-rewrites: and change-services: line of the record, drops: none and services: none when it has none. With no production
# yet: outcome: no backup yet, nothing deployed. One rehearsal up at a time: `stop --ask` destroys it, its store and its dump.
# RECOVERY, DP's, for a production okay's newest deploy: rollback runs production at the commit it ran before that deploy, its store as it stands (locally, with
# none before it, production is taken down and its store removed: recovered none); restore puts back that deploy's backup and runs that commit. Every restore,
# in both modes, is refused, exit 5, until --lose-writes, which DP passes only after the owner's answer on the okay naming the recovery point (the backup's
# time) and the writes at risk (every write since) (0.26.11.1.1 R1, E1).
# start:, seed:, production-seed:, backup:, restore:, migrate:, deploy:, kept:, sealed-start: and stop: run under sh -c, in the instance's checkout (a backup of
# the live production in its own), and see PORT, BASE_URL (http://127.0.0.1:<port>, or the hosted address), RUN_ID (the instance's id), TARGET (staging,
# production or rehearsal), STAGING (1 on staging), SEED (synthetic or production on staging, sample on a local production), DATA_DIR (the store of a local
# production or the rehearsal), DUMP (the dump to write or read) and an empty NO_PRODUCT. Each process group an instance starts is recorded with its members'
# starts, and stopped by its id when it goes, after the record's stop: (a local copy's alone).
#   deploy.sh deploy --setup <record> --ask deploy-<issue> --commit <full id> [--target staging|production|rehearsal] [--seed synthetic|production] [--product-change no|yes]
#                    a failed step is pushed only with --product-change, DP's judgement whether its fix needs a commit to the code repository: without one,
#                    nothing is pushed, the log is named, exit 4, and DP judges and runs the same command with it; --seed production, a hosted staging's alone
#   deploy.sh deploy … --fail-step <step> --product-change no|yes
#                    the labelled plant, for a test alone: a failed step reported, nothing deployed, the live instance untouched (production's backup taken first)
#   deploy.sh stop [--setup <record>] --ask deploy-<issue>   stops the live local staging, or destroys the live rehearsal, when it is that okay's
#   deploy.sh stop [--setup <record>] --target production    takes DevAgent's local production down, its store kept: the end of a test alone
#   deploy.sh stop [--setup <record>] --target staging|production --report deploy-<issue> --commit <full id>   (FB-2 A4) a take-down okay's:
#                    what of that target is live goes, its store kept: a local staging or the local live copy by its recorded groups; a
#                    hosted staging by the record's host-down: (TARGET=staging, BASE_URL its address), then its address giving no web answer
#                    within ready-seconds:; with no host-down:, nothing stopped. A hosted production is refused, as above. The report pushed
#                    alone on vid-results/deploy-<issue>-<k>: report.txt, by: DP, commit:, decisions: none, outcome: down or outcome: failed
#                    down — <why>, and down: <target> <address>; a report whose push failed is kept, and the same command pushes it, nothing
#                    repeated. After the live copy's, production takes no deploy until it is recovered
#   deploy.sh rollback|restore [--setup <record>] --ask deploy-<issue> [--lose-writes]   prints recovered <the commit production runs now, or none> — <what it did>
#   deploy.sh live [--setup <record>]         live <id> <address>, or live none; and rehearsal <id> <address> while one is up
#   deploy.sh production [--setup <record>]   production <commit> <address>, production down — …, production stopped — …, or production none
# The record defaults to $DM_WORK/dev-setup.txt, or the current folder's. Optional keys: seed:, signin:, mail:, clock:, differs:, seam:, real:, duty:, migrate:, sealed-start:, decision:,
# change-migrates:, change-drops:, change-rewrites:, change-services:, ready-seconds: (120), startup-seconds: (3600), and the hosted ones: host:, staging-address:,
# production-address:, host-login:, deploy:, host-down: (FB-2 A4), production-logs:. A production or a rehearsal needs backup: and restore:, a rehearsal kept:; a local first
# production deploy production-seed:, a hosted one production-logs:. The first staging port tried is DP_PORT (47100). Exit: 0 pushed, stopped, recovered or
# listed; 1 refused, not run or not pushed; 4 a failed step not pushed; 5 a restore without --lose-writes.
# serves: dev side (0.26.10.28.4, M9)
set -eu
die() { echo "deploy.sh: $*" >&2; exit 1; }
CMD=${1:-}; [ $# -eq 0 ] || shift
case $CMD in deploy|stop|live|production|rollback|restore) ;; *) die 'usage: deploy.sh deploy|stop|live|production|rollback|restore …, see its head' ;; esac
HERE=$(cd "$(dirname "$0")" && pwd -P); RUN=$(dirname "$HERE")/test-manager/run.sh
SETUP=''; ASK=''; COMMIT=''; SEED=synthetic; PC=''; FS=''; TG=''; LW=''; REP=''
while [ $# -gt 0 ]; do [ "$1" != --lose-writes ] || { LW=1; shift; continue; }; [ $# -ge 2 ] || die "$1 needs a value"
  case $1 in --setup) SETUP=$2 ;; --ask) ASK=$2 ;; --commit) COMMIT=$2 ;; --seed) SEED=$2 ;; --product-change) PC=$2 ;; --fail-step) FS=$2 ;; --target) TG=$2 ;; --report) REP=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
case $TG in ''|staging|rehearsal|production) ;; *) die "--target is staging, rehearsal or production, not '$TG'" ;; esac
[ -z "$REP" ] || { [ "$CMD" = stop ] && [ -z "$ASK" ] && { [ "$TG" = staging ] || [ "$TG" = production ]; } && printf '%s\n' "$REP" | grep -Eqx 'deploy-[0-9]+'; } || die 'a take-down is stop --target staging|production --report deploy-<issue> --commit <the commit>'   # FB-2 A4
[ -z "$TG" ] || [ "$CMD" = deploy ] || [ "$CMD:$TG" = stop:production ] || [ -n "$REP" ] || die '--target goes with deploy, or with stop as --target production'
[ -z "$LW" ] || [ "$CMD" = restore ] || die "--lose-writes is a restore's alone"
TG=${TG:-staging}
[ -n "$SETUP" ] || SETUP=${DM_WORK:-$PWD}/dev-setup.txt; [ -f "$SETUP" ] || die "no dev setup record at '$SETUP': run the setup first"
W=$(cd "$(dirname "$SETUP")" && pwd -P); SETUP=$W/$(basename "$SETUP"); SF=$W/staging; PF=$W/production; HF=$W/rehearsal
d=$W; while :; do [ ! -e "$d/.vid" ] || die "the work folder is in $d, a folder of ViD's records"; [ "$d" != / ] || break; d=$(dirname "$d"); done
key() { sed -n "s/^$1: *//p" "$SETUP" | head -n 1; }
now() { date +%s; }
case $CMD:$TG${REP:+:r} in live:*|production:*|stop:production|stop:*:r) [ -z "$ASK" ] || die "$CMD $([ "$CMD" != stop ] || echo '--target production ')takes no --ask" ;;
  *) printf '%s\n' "$ASK" | grep -Eqx 'deploy-[0-9]+' || die "the ask is deploy-<issue>, not '$ASK'" ;; esac
SUL=$(key startup-seconds | grep . || echo 3600)
# 0.26.11.1.1 (R1): hosted mode, by the record's host: line; SA and PA the hosted addresses
HO=$(key host); SA=$(key staging-address); PA=$(key production-address)
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
# answers <address>: any web answer, whatever its status
answers() { c=$(curl -s -o /dev/null -m 3 -w '%{http_code}' "$1" 2>/dev/null) || true; case $c in ''|000) return 1 ;; esac; }
# fport <first>: the first free local port from it, of 200
fport() { p=$1; e=$(($1 + 200)); while [ "$p" -lt "$e" ] && up "$p"; do p=$((p + 1)); done; [ "$p" -lt "$e" ] || return 1; echo "$p"; }
# names <instance folder>: what the record's commands see; a hosted instance (its addr file) its address, no port, no data folder
names() { RUN_ID=$(cat "$1/id"); TARGET=$(cat "$1/target" 2>/dev/null || echo staging); STAGING=''; SEED=''; DATA_DIR=''; DUMP=''; NO_PRODUCT=''
  if [ -f "$1/addr" ]; then PORT=''; BASE_URL=$(cat "$1/addr"); [ "$TARGET" != staging ] || { STAGING=1; SEED=$(cat "$1/seed" 2>/dev/null || echo synthetic); }
  else PORT=$(cat "$1/port"); BASE_URL=http://127.0.0.1:$PORT
    case $TARGET in staging) STAGING=1; SEED=synthetic ;; production) SEED=sample; DATA_DIR=$PF/data ;; rehearsal) DATA_DIR=$1/data ;; esac; fi
  export RUN_ID PORT BASE_URL TARGET STAGING SEED DATA_DIR DUMP NO_PRODUCT; }
# hprod <instance folder>: that instance's names, against the hosted production: what backup: sees to dump it
hprod() { names "$1"; TARGET=production; BASE_URL=$PA; PORT=''; DATA_DIR=''; STAGING=''; SEED=''; export TARGET BASE_URL PORT DATA_DIR STAGING SEED; }
# bounded <seconds> <folder> <command> [<where>]: the command in the folder's checkout, or where, its own process group, recorded; stopped by its group past the
# seconds. RC its exit, 124 when stopped
bounded() { set -m; ( cd "${4:-$2/checkout}" && exec nohup sh -c "$3" ) >> "$2/log" 2>&1 < /dev/null & P=$!; set +m; echo "$P" >> "$2/groups"; n=0
  while kill -0 "$P" 2>/dev/null && [ "$n" -lt "$1" ]; do sleep 1; n=$((n + 1)); done
  if kill -0 "$P" 2>/dev/null; then kill -s TERM -- "-$P" 2>/dev/null || true; sleep 1; kill -s KILL -- "-$P" 2>/dev/null || true; fi
  RC=0; wait "$P" 2>/dev/null || RC=$?; [ "$n" -lt "$1" ] || RC=124; }
# members <folder>: every process now in a recorded group, with its start, so a later stop knows the group is still its own
members() { for g in $(cat "$1/groups"); do ps -A -o pid= -o pgid= | awk -v g="$g" '$2 == g { print $1 }'; done | while read -r p; do
    sh "$RUN" stamp "$p" > "$1/m.$p" 2>/dev/null && [ -s "$1/m.$p" ] || rm -f "$1/m.$p"; done; }
# down <folder>: the record's stop: (a local copy's alone), then each recorded group a recorded member of which is still itself, by its id; what will not go is named
down() { [ -d "$1/checkout" ] || return 0; names "$1"; [ -f "$1/addr" ] || bounded "$SUL" "$1" "$(key stop)" || true; G=''
  for m in "$1"/m.*; do [ -f "$m" ] || continue; p=${m##*/m.}; sh "$RUN" is "$p" "$m" || continue; g=$(ps -o pgid= -p "$p" 2>/dev/null | tr -d ' '); case " $G " in *" $g "*) ;; *) G="$G $g" ;; esac; done
  for g in $G; do grep -qx "$g" "$1/groups" || continue; kill -s TERM -- "-$g" 2>/dev/null || true; done; [ -z "$G" ] || sleep 1
  for g in $G; do grep -qx "$g" "$1/groups" && kill -s KILL -- "-$g" 2>/dev/null || true; done
  for m in "$1"/m.*; do [ -f "$m" ] || continue; p=${m##*/m.}; ! sh "$RUN" is "$p" "$m" || echo "deploy.sh: process $p of $(cat "$1/id") not gone" >&2; rm -f "$m"; done
  : > "$1/groups"; rm -rf "$1/checkout"; [ -f "$1/addr" ] || sh "$RUN" slot free "$SLN.$(cat "$1/target" 2>/dev/null || echo staging)" "$1" || true; }
# slot: this instance's test environment of the machine's (v0.26.10.28.2, R1, run.sh slot): its target's in this work folder, so a replacement keeps the slot
# its predecessor holds and production, up between deploys, holds it for good; while max-environments: are up and none is its own, it waits; down frees it.
# A hosted staging or production takes none (0.26.11.1.1 R1).
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
# pstate: production live, down (a failed deploy or recovery took it down), stopped (a local one's store kept, nothing running) or none; a hosted production
# is none until production/hosted says a hosted deploy passed (0.26.11.1.1 R1)
pstate() { if [ -f "$PF/down" ]; then echo down; elif [ -n "$PL" ]; then echo live; elif [ -n "$HO" ]; then if [ -f "$PF/hosted" ]; then echo live; else echo none; fi
  elif [ -d "$PF/data" ]; then echo stopped; else echo none; fi; }
# addr <instance folder>: where it answers, and whether it does
addr() { if [ -f "$1/addr" ]; then a=$(cat "$1/addr"); answers "$a" && echo "$a" || echo "$a — not answering"; else P=$(cat "$1/port"); up "$P" && echo "http://127.0.0.1:$P" || echo "http://127.0.0.1:$P — not answering"; fi; }
state
if [ "$CMD" = live ]; then if [ -n "$LIVE" ]; then echo "live $LIVE $(addr "$SF/$LIVE")"; else echo 'live none'; fi
  [ -z "$HL" ] || echo "rehearsal $HL $(addr "$HF/$HL")"; exit 0; fi
if [ "$CMD" = production ]; then case $(pstate) in
    live) if [ -n "$PL" ]; then echo "production $(cat "$PF/$PL/commit") $(addr "$PF/$PL")"; else echo "production ? $PA"; fi ;;
    down) echo "production down — $(cat "$PF/down") failed and took it down: roll it back or restore it" ;;
    stopped) echo 'production stopped — its store kept, nothing running' ;; none) echo 'production none' ;; esac; exit 0; fi
if [ "$CMD" = stop ] && [ -z "$REP" ]; then lock; state
  if [ "$TG" = production ]; then [ -z "$HO" ] || die "a hosted production is not taken down by deploy.sh: it is the host's; ask the owner on the okay"
    [ -n "$PL" ] || die 'no live production'; down "$PF/$PL"; rm -f "$PF/live"; echo "stopped production $PL; its store kept"; exit 0; fi
  if [ -n "$LIVE" ] && [ "${LIVE%-*}" = "$ASK" ] && [ -f "$SF/$LIVE/addr" ]; then echo "the hosted staging $LIVE stays up between deploys, as develop's does: nothing taken down"; exit 0; fi
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
# 0.26.10.29.5 (DP-1 R2): every report states its decisions: the record's decision: lines, each one of this deploy's choices in DP's
# words (`decision: <what> | why: <why>`), or decisions: none; ViD refuses a report with neither
decs() { _v=$(sed -n 's/^decision: *//p' "$SETUP" | grep . || true); if [ -n "$_v" ]; then printf '%s\n' "$_v" | sed 's/^/decision: /'; else echo 'decisions: none'; fi; }
# report [<failed step>]; a rehearsal's kept: lines, once its kept step ran, after the outcome (0.26.11.1.1 R5)
report() { { echo 'by: DP'; echo "commit: $COMMIT"; decs; if [ -z "${1:-}" ]; then echo 'outcome: passed'; else echo "outcome: failed $1"; [ -z "$PC" ] || echo "product change: $PC"; fi
    [ "$TG" != rehearsal ] || [ ! -s "$D/kept" ] || cat "$D/kept"; } > "$D/report/$ID/report.txt"
  [ "$TG" != rehearsal ] || chg; xml; }
# 0.26.11.1.1 (R3): the duties of a D1 and a D2, and duties.txt, a passed one's alone
DUS='log-in environments outside-services sending-domain deploy-notes captures'; DUP='service-switch-on backups point-in-time-recovery storage-versioning dns https monitoring'
dof() { case $1 in staging) echo "$DUS" ;; production) echo "$DUP" ;; esac; }
duties() { for u in $(dof "$TG"); do if [ -n "$HO" ]; then echo "$u: $(sed -n "s/^duty: *$u — //p" "$SETUP")"; else echo "$u: not needed — a local copy, for a test"; fi; done > "$D/report/$ID/duties.txt"; }
pushed() { push || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; }
# failed <step>: the instance that was coming up goes; pushed with a judgement, else nothing pushed and exit 4 (production's report kept for it)
failed() { if [ "$TG" = rehearsal ]; then destroy "$D"; else down "$D"; fi
  if [ -z "$PC" ]; then if [ "$TG" = production ]; then report "$1"; echo "$ID" > "$PF/unpushed"; W4="production $(if [ -f "$PF/down" ]; then echo 'is down'; elif [ -n "${FIRST:-}" ]; then echo 'never ran before it'; else echo 'runs as it did'; fi); "; fi
    echo "deploy.sh: failed $1, nothing pushed: ${W4:-}its log is $D/log; judge whether the fix needs a commit to the code repository and run the same command with --product-change yes|no" >&2; exit 4; fi
  report "$1"; pushed; }
plant_() { echo "the labelled plant: a failed $1, product change: $PC" >> "$D/log"; rm -rf "$D/checkout"; report "$1"; pushed; }
# run_ <step> <command> [<where>]: the command bounded in the instance, its case; a failure is the step's
run_() { t=$(now); bounded "$SUL" "$D" "$2" "${3:-}"; members "$D"; [ "$RC" = 0 ] || { case_ "$1" $(($(now) - t)) "$([ "$RC" = 124 ] && echo "$1 past its limit" || echo "exit $RC")"; failed "$1"; }; case_ "$1" $(($(now) - t)) ''; }
# ready_ <step>: the port answering, or for a hosted instance its address giving any web answer, within ready-seconds:
ready_() { t=$(now); L=$(key ready-seconds | grep . || echo 120)
  if [ -n "$PORT" ]; then n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done
    up "$PORT" || { case_ "$1" $(($(now) - t)) "port $PORT did not answer within ${L}s"; failed "$1"; }
  else while ! answers "$BASE_URL" && [ $(($(now) - t)) -lt "$L" ]; do sleep 1; done
    answers "$BASE_URL" || { case_ "$1" $(($(now) - t)) "$BASE_URL gave no web answer within ${L}s"; failed "$1"; }; fi; case_ "$1" $(($(now) - t)) ''; }
checkout_() { t=$(now); git -C "$D/checkout" -c advice.detachedHead=false checkout -q "$COMMIT" >> "$D/log" 2>&1 || { case_ checkout $(($(now) - t)) 'the checkout failed'; failed checkout; }; case_ checkout $(($(now) - t)) ''; }
# mkd <folder>: a new instance's folder; every local production instance writes to the one production log; a hosted one names its address
mkd() { rm -rf "$1"; mkdir -p "$1/report/$ID"; echo "$ID" > "$1/id"; echo "$TG" > "$1/target"; : > "$1/groups"; : > "$1/cases"; echo 0 > "$1/port"
  if [ -n "$HO" ] && [ "$TG" != rehearsal ]; then if [ "$TG" = staging ]; then echo "$SA" > "$1/addr"; echo "$SEED" > "$1/seed"; else echo "$PA" > "$1/addr"; fi; fi
  if [ "$TG" = production ]; then : >> "$PF/production.log"; ln -s ../production.log "$1/log"; else : > "$1/log"; fi; }
# pport: production's port, the one it had while free
pport() { p=$(cat "$PF/port" 2>/dev/null || true); { [ -n "$p" ] && ! up "$p"; } || p=$(fport "${DP_PRODUCTION_PORT:-47300}") || die "no free local port from ${DP_PRODUCTION_PORT:-47300}"; echo "$p" > "$D/port"; echo "$p" > "$PF/port"; }
# login: the record's host-login:, before any step of a hosted deploy, rollback or restore (0.26.11.1.1 R1)
login() { [ -n "$HO" ] || return 0; mkdir -p "$W/host"; : > "$W/host/groups"; bounded 300 "$W/host" "$(key host-login)" "$W"
  [ "$RC" = 0 ] || die "the host's tool is not logged in: host-login: exited $RC (its output: $W/host/log). The log-in is the owner's step: ask them on the okay to log in to $HO, then run this again; nothing was run on the host or pushed"; }
REPO=$(key repo); [ -n "$REPO" ] || die 'the record has no repo: line'
if [ -n "$HO" ]; then command -v curl > /dev/null 2>&1 || die 'a hosted deploy needs curl, to see the address answer'
  [ -n "$(key host-login)" ] || die "the record has host: $HO and no host-login: line, the command that exits 0 while the host's tool is logged in"; fi
hk() { for k in "$@"; do [ -n "$(key "$k")" ] || die "the record has host: $HO and no $k: line"; done; }
# FB-2 A4: a take-down okay's, stop --target staging|production --report deploy-<issue> --commit <c> (the head says what it does)
if [ -n "$REP" ]; then case $COMMIT in *[!0-9a-f]*|'') die 'the commit must be a full id' ;; esac; [ "${#COMMIT}" -eq 40 ] || die 'the commit must be a full id'
  [ "$TG" = staging ] || [ -z "$HO" ] || die "a hosted production is not taken down by deploy.sh: it is the host's; ask the owner on the okay"
  lock; state; login; ASK=$REP; o=$(git ls-remote --heads "$REPO" "vid-results/$ASK-*" 2>&1) || die "the results branches of $REPO could not be read: $(printf '%s' "$o" | tr '\n' ' ')"
  K=$(printf '%s\n' "$o" | sed -n "s|.*refs/heads/vid-results/$ASK-\([0-9][0-9]*\)\$|\1|p" | sort -n | tail -n 1); ID=$ASK-$((${K:-0} + 1)); D=$W/down/$ID
  # FB-2 A4: a report of this attempt kept here, its push failed: pushed again, as it is, and nothing repeated
  [ ! -f "$D/report/$ID/report.txt" ] || { push || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; }
  rm -rf "$D"; mkdir -p "$D/report/$ID"; : > "$D/log"; : > "$D/groups"; WHY=''; A=''
  if [ "$TG" = production ]; then if [ -n "$PL" ]; then A=http://127.0.0.1:$(cat "$PF/$PL/port"); down "$PF/$PL"; rm -f "$PF/live"; ! up "${A##*:}" || WHY="$A still answers"; else WHY='no live copy runs here'; fi
  elif [ -n "$HO" ]; then A=$SA; if [ -z "$(key host-down)" ]; then WHY='the record names no host-down:'
    else RUN_ID=$ID; TARGET=staging; BASE_URL=$SA; PORT=''; DATA_DIR=''; STAGING=1; export RUN_ID TARGET BASE_URL PORT DATA_DIR STAGING; bounded "$SUL" "$D" "$(key host-down)" "$W"
      if [ "$RC" != 0 ]; then WHY="host-down: exited $RC (its log: $D/log)"
      else L=$(key ready-seconds | grep . || echo 120); t=$(now); while answers "$SA" && [ $(($(now) - t)) -lt "$L" ]; do sleep 1; done
        if answers "$SA"; then WHY="$SA still answers after host-down:"; else [ -z "$LIVE" ] || { rm -rf "$SF/$LIVE/checkout"; rm -f "$SF/live"; }; fi; fi; fi
  elif [ -n "$LIVE" ]; then A=http://127.0.0.1:$(cat "$SF/$LIVE/port"); down "$SF/$LIVE"; rm -f "$SF/live"; ! up "${A##*:}" || WHY="$A still answers"
  else WHY='no staging runs here'; fi
  { echo 'by: DP'; echo "commit: $COMMIT"; echo 'decisions: none'; if [ -z "$WHY" ]; then echo 'outcome: down'; else echo "outcome: failed down — $WHY"; fi; [ -z "$A" ] || echo "down: $TG $A"; } > "$D/report/$ID/report.txt"
  push || die "not pushed: vid-results/$ID"; echo "pushed vid-results/$ID"; exit 0; fi
if [ "$CMD" = rollback ] || [ "$CMD" = restore ]; then TG=production; lock; state; login; [ ! -f "$PF/unpushed" ] || die "the failed deploy $(cat "$PF/unpushed") is not pushed yet: push its report first, with --product-change"
  A=$(ls -d "$PF/$ASK"-[0-9]* 2>/dev/null | sed 's|.*-||' | sort -n | tail -n 1); [ -n "$A" ] || die "no production deploy of $ASK here"
  DA=$PF/$ASK-$A; PREV=$(cat "$DA/prev" 2>/dev/null || true); BK=$(cat "$DA/backup" 2>/dev/null || echo none); [ -n "$PREV" ] || die "$ASK-$A recorded no previous commit"
  if [ -n "$HO" ]; then hk deploy production-address; [ "$CMD" = rollback ] || hk restore
  else [ -n "$(key start)" ] && [ -n "$(key backup)" ] && [ -n "$(key restore)" ] || die 'the record has no start:, backup: or restore: line'; fi
  # 0.26.11.1.1 (R1, E1): every restore asks the owner first, the recovery point and the writes at risk named; the dump comparison is cut
  if [ "$CMD" = restore ]; then [ "$BK" != none ] || die "$ASK-$A took no backup, no production being there before it: nothing to restore; roll back instead"; [ -e "$BK" ] || die "the backup $BK is gone"
    [ -n "$LW" ] || { echo "deploy.sh: a restore of $BK, the backup $ASK-$A took at $(date -u -r "$BK" '+%Y-%m-%dT%H:%M:%SZ'), the recovery point, would lose the writes made on production since then, the writes at risk: ask on the okay first, naming both; with the owner's yes, restore --lose-writes" >&2; exit 5; }; fi
  if [ "$PREV" = none ]; then [ "$CMD" = rollback ] || die 'nothing ran before it to restore to'
    [ -z "$HO" ] || die "$ASK-$A was the first hosted production deploy: no earlier commit to roll back to, and the host's production is not taken down by deploy.sh; nothing done: ask the owner on the okay what to do with it"
    [ -z "$PL" ] || down "$PF/$PL"; rm -f "$PF/live" "$PF/down" "$PF/seeded"; rm -rf "$PF/data"
    echo "recovered none — DevAgent's production taken down and its store removed: no production exists"; exit 0; fi
  j=1; while [ -e "$PF/$ASK-r$j" ]; do j=$((j + 1)); done; ID=$ASK-r$j; D=$PF/$ID; COMMIT=$PREV; mkd "$D"
  { git clone -q "$REPO" "$D/checkout" && git -C "$D/checkout" -c advice.detachedHead=false checkout -q "$PREV"; } >> "$D/log" 2>&1 || { rm -rf "$D"; die "$PREV could not be checked out from $REPO; production untouched"; }
  rec() { bounded "$SUL" "$D" "$2"; members "$D"; [ "$RC" = 0 ] || { down "$D"; die "the $CMD failed at $1, exit $RC: production is down; its log is $PF/production.log"; }; }
  if [ -n "$HO" ]; then [ -z "$PL" ] || { rm -rf "$PF/$PL/checkout"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; echo "$ID" > "$PF/down"; names "$D"
    [ "$CMD" != restore ] || { DUMP=$BK; export DUMP; rec restore "$(key restore)"; }; rec deploy "$(key deploy)"
    L=$(key ready-seconds | grep . || echo 120); t=$(now); while ! answers "$BASE_URL" && [ $(($(now) - t)) -lt "$L" ]; do sleep 1; done
    answers "$BASE_URL" || { down "$D"; die "the $CMD's $BASE_URL gave no web answer within ${L}s: production is down"; }
  else slot "${PL:+$PF/$PL}"; [ -z "$PL" ] || { down "$PF/$PL"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; echo "$ID" > "$PF/down"; mkdir -p "$PF/data"; pport; names "$D"
    [ "$CMD" != restore ] || { DUMP=$BK; export DUMP; rec restore "$(key restore)"; }; rec start "$(key start)"
    L=$(key ready-seconds | grep . || echo 120); n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done; up "$PORT" || { down "$D"; die "the $CMD's port $PORT did not answer within ${L}s: production is down"; }; fi
  echo "$PREV" > "$D/commit"; echo "$ID" > "$PF/live"; rm -f "$PF/down"
  if [ "$CMD" = restore ]; then echo "recovered $PREV — production's store restored from $BK, the backup $ASK-$A took, and run at $PREV, $BASE_URL"
  else echo "recovered $PREV — production rolled back to $PREV, the commit it ran before $ASK-$A, its store as it stood, $BASE_URL"; fi; exit 0; fi
# deploy
case $COMMIT in *[!0-9a-f]*|'') die 'the commit must be a full id' ;; esac; [ "${#COMMIT}" -eq 40 ] || die 'the commit must be a full id'
# 0.26.11.1.1 (R6): --seed production, a hosted staging's alone
case $SEED in synthetic) ;; production) [ -n "$HO" ] || die "--seed production is a hosted staging's alone: with no host: line in the record, staging is a local copy, which holds no production data; DevAgent deploys it on the synthetic seed"
    [ "$TG" = staging ] || die '--seed production goes with a staging deploy' ;;
  *) die "--seed is synthetic, or production on a hosted staging, not '$SEED': another seed is an owner-only step, DP's question on the okay" ;; esac
case $PC in ''|yes|no) ;; *) die "--product-change is yes or no, not '$PC'" ;; esac
[ -z "$FS" ] || { printf '%s\n' "$FS" | grep -Eqx '[a-z][a-z0-9-]*' || die "a step is one word, not '$FS'"; [ -n "$PC" ] || die 'a plant needs --product-change yes|no'; }
if [ -n "$HO" ] && [ "$TG" != rehearsal ]; then [ -n "$FS" ] || hk deploy; [ "$TG" = staging ] && hk staging-address || hk production-address
  case "$SA $PA" in *[[:space:]]*[[:space:]]*) die 'a hosted address is one word, http:// or https://' ;; esac
else [ -n "$FS" ] || [ -n "$(key start)" ] || { [ "$TG" = rehearsal ] && [ -n "$(key sealed-start)" ]; } || die 'the record has no start: line'; fi
[ "$TG" != rehearsal ] || [ -z "$HO" ] || hk production-address
# 0.26.11.1.1 (R3): with host:, a deploy names each duty of its target in a duty: line; a plant needs none. Without host:, none is read
if [ -n "$HO" ]; then o=$(sed -n 's/^duty: *//p' "$SETUP" | awk -F ' — ' -v ok=" $DUS $DUP " 'NF < 3 || index(ok, " " $1 " ") == 0 || ($2 != "done" && $2 != "not needed" && $2 != "not done") || $3 == "" { print; exit }')
  [ -z "$o" ] || die "a duty: line is not duty: <duty> — done|not needed|not done — <words>, of the thirteen duties: duty: $o"
  [ -n "$FS" ] || for u in $(dof "$TG"); do n=$(grep -c "^duty: *$u — " "$SETUP" || true)
    [ "$n" != 0 ] || die "the record has no duty: line for $u, a duty of every hosted $TG deploy: write duty: $u — done|not needed|not done — <what and where, or why> as the set-up stands, then deploy"
    [ "$n" = 1 ] || die "the duty $u has $n duty: lines: one alone"; done; fi
# 0.26.11.1.1 (R4): seam: <row> real, or seam: <row> stand-in — <why>, one a row
SM=$(sed -n 's/^seam: *//p' "$SETUP"); o=$(printf '%s\n' "$SM" | awk 'NF && !($0 ~ /^[A-Za-z0-9_-]+ real$/ || $0 ~ /^[A-Za-z0-9_-]+ stand-in — ./) { print; exit }')
[ -z "$o" ] || die "a seam: line is not seam: <row> real or seam: <row> stand-in — <why>: seam: $o"
[ -z "$(printf '%s\n' "$SM" | awk 'NF { print $1 }' | sort | uniq -d)" ] || die "a row has two seam: lines: $(printf '%s\n' "$SM" | awk 'NF { print $1 }' | sort | uniq -d | head -n 1)"
SI=$(sed -n 's/^signin: *//p' "$SETUP"); printf '%s\n' "$SI" | awk 'NF && !($0 ~ /^[A-Za-z][A-Za-z0-9_-]* \/[^ ]*$/) { print; exit 1 }' > /dev/null || die "a signin: line is not <role> /<path>: $(printf '%s\n' "$SI" | awk 'NF && !($0 ~ /^[A-Za-z][A-Za-z0-9_-]* \/[^ ]*$/)' | head -n 1)"
DF=$(sed -n 's/^differs: *//p' "$SETUP"); printf '%s\n' "$DF" | awk 'NF && $0 != "none" && split($0, x, " — ") != 3 { exit 1 }' || die 'a differs: line is not <what> — <on staging> — <on production>'
[ "$(printf '%s\n' "$DF" | grep -c .)" -le 1 ] || ! printf '%s\n' "$DF" | grep -qx none || die 'differs: none stands alone'
case $TG in production|rehearsal) [ -n "$(key backup)" ] && [ -n "$(key restore)" ] || die "the record has no backup: or restore: line: a $TG needs both, the product's own way to dump its data store and to load a dump" ;; esac
[ "$SEED" != production ] || { [ -n "$(key backup)" ] && [ -n "$(key restore)" ]; } || die "the record has no backup: or restore: line: production data on staging needs both"
if [ "$TG" = rehearsal ]; then case $(key change-migrates) in ''|yes|no) ;; *) die "change-migrates: is yes or no, not '$(key change-migrates)'" ;; esac
  for k in drops rewrites services; do v=$(sed -n "s/^change-$k: *//p" "$SETUP"); [ "$(printf '%s\n' "$v" | grep -c .)" -le 1 ] || ! printf '%s\n' "$v" | grep -qx none || die "change-$k: none stands alone"; done
  # 0.26.11.1.1 (R5): the rehearsal checks the permanent records survive, by the record's kept:
  [ -n "$FS" ] || [ -n "$(key kept)" ] || die "the record has no kept: line: a rehearsal runs it after the migration, seeing DUMP and DATA_DIR, to print kept: <table> — <n> rows for each table the product only ever adds to, or kept: none — <why>, and to exit non-zero on a row lost or changed"; fi
lock; state
if [ "$SEED" = production ]; then [ -f "$PF/hosted" ] || die 'there is no production data yet: no hosted production deploy has passed'; [ -n "$PL" ] || die 'there is no production to take data from: production is down; recover it first'; fi
login
o=$(git ls-remote --heads "$REPO" "vid-results/$ASK-*" 2>&1) || die "the results branches of $REPO could not be read: $(printf '%s' "$o" | tr '\n' ' ')"
K=$(printf '%s\n' "$o" | sed -n "s|.*refs/heads/vid-results/$ASK-\([0-9][0-9]*\)\$|\1|p" | sort -n | tail -n 1); ID=$ASK-$((${K:-0} + 1))
case $TG in staging) D=$SF/$ID; [ "$LIVE" != "$ID" ] || die "$ID is live and not pushed: stop it first" ;; production) D=$PF/$ID ;; rehearsal) D=$HF/$ID; [ "$HL" != "$ID" ] || die "$ID is live and not pushed: stop it first" ;; esac
if [ "$TG" = production ] && [ -f "$PF/unpushed" ]; then U=$(cat "$PF/unpushed")
  [ "$U" = "$ID" ] || die "the failed production deploy $U waits for its judgement: the same command as it, with --product-change yes|no, pushes its report"
  [ -n "$PC" ] && [ -z "$FS" ] || die "$ID failed and is not pushed: the same command with --product-change yes|no, and no plant, pushes its report"
  [ "$(sed -n 's/^commit: //p' "$D/report/$ID/report.txt")" = "$COMMIT" ] || die "the kept report of $ID is of another commit"
  echo "product change: $PC" >> "$D/report/$ID/report.txt"; push || die "not pushed: vid-results/$ID"; rm -f "$PF/unpushed"; echo "pushed vid-results/$ID"; exit 0; fi
FIRST=''; if [ "$TG" = production ]; then case $(pstate) in down) die "production is down since $(cat "$PF/down") failed: recover it first, deploy.sh rollback or restore" ;; stopped) die 'the DevAgent production is stopped: nothing to back up from' ;; esac
  if [ -n "$HO" ]; then [ -f "$PF/hosted" ] || FIRST=1; [ -z "$FIRST" ] || [ -n "$FS" ] || hk production-logs
  else [ -d "$PF/data" ] || FIRST=1; [ -z "$FIRST" ] || [ -n "$FS" ] || [ -n "$(key production-seed)" ] || die 'the record has no production-seed: line: the DevAgent production is seeded once, on its first deploy, with labelled sample data'; fi; mkdir -p "$PF"; fi
mkd "$D"
git clone -q "$REPO" "$D/checkout" >> "$D/log" 2>&1 || { rm -rf "$D"; die "$REPO could not be cloned"; }
git -C "$D/checkout" cat-file -e "$COMMIT^{commit}" 2>/dev/null || { rm -rf "$D"; die "$COMMIT is not on origin; nothing pushed"; }
if [ "$TG" = production ]; then
  if [ -n "$PL" ]; then cat "$PF/$PL/commit" > "$D/prev"; else echo none > "$D/prev"; fi; echo none > "$D/backup"
  [ "$FS" != backup ] || { case_ backup 0 'a labelled plant (--fail-step backup): nothing was backed up or deployed'; plant_ backup; }
  t=$(now); if [ -n "$PL" ]; then mkdir -p "$PF/backups"; if [ -n "$HO" ]; then hprod "$D"; else names "$PF/$PL"; fi; DUMP=$PF/backups/$ID.dump; export DUMP; rm -rf "$DUMP"
    wh=$PF/$PL/checkout; [ -d "$wh" ] || wh=$W; bounded "$SUL" "$D" "$(key backup)" "$wh"; members "$D"
    [ "$RC" = 0 ] && [ -e "$DUMP" ] || { case_ backup $(($(now) - t)) "$([ "$RC" = 0 ] && echo "the backup wrote no dump at $DUMP" || echo "exit $RC")"; failed backup; }
    echo "$DUMP" > "$D/backup"; case_ backup $(($(now) - t)) '' "backed up to $DUMP"
  else case_ backup 0 '' 'nothing to back up'; fi
  [ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was deployed, production untouched"; plant_ "$FS"; }
  checkout_
  # a hosted first deploy marks nothing down: no production ran before it, so a failed one leaves none, and the next attempt runs as the first
  if [ -n "$HO" ]; then [ -z "$PL" ] || { rm -rf "$PF/$PL/checkout"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; [ -n "$FIRST" ] || echo "$ID" > "$PF/down"; names "$D"
  else slot "${PL:+$PF/$PL}"; [ -z "$PL" ] || { down "$PF/$PL"; rm -f "$PF/live"; echo "replaced $PL" >> "$D/log"; }; mkdir -p "$PF/data"; echo "$ID" > "$PF/down"; pport; names "$D"; fi
  if [ -n "$(key migrate)" ]; then run_ migrate "$(key migrate)"; else case_ migrate 0 '' 'the record has no migrate:'; fi
  if [ -n "$HO" ]; then run_ deploy "$(key deploy)"
  else run_ start "$(key start)"; [ -z "$FIRST" ] || { run_ seed "$(key production-seed)"; : > "$PF/seeded"; }; fi
  ready_ ready
  echo "$COMMIT" > "$D/commit"; names "$D"; report; duties
  { echo "production: $BASE_URL"; [ -z "$FIRST" ] || if [ -n "$HO" ]; then echo "logs: $(key production-logs)"; else echo "logs: $PF/production.log"; fi; } >> "$D/report/$ID/report.txt"
  echo "$ID" > "$PF/live"; rm -f "$PF/down"; [ -z "$HO" ] || echo "$ID" >> "$PF/hosted"; push || die "not pushed: vid-results/$ID; production runs it"; echo "pushed vid-results/$ID"; exit 0; fi
if [ "$TG" = rehearsal ]; then
  [ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was restored or deployed, the live rehearsal untouched"; plant_ "$FS"; }
  if [ "$(pstate)" = none ]; then case_ restore 0 '' 'skipped: no backup yet: no production exists; nothing restored or deployed'
    { echo 'by: DP'; echo "commit: $COMMIT"; decs; echo 'outcome: no backup yet'; } > "$D/report/$ID/report.txt"; chg; xml; rm -rf "$D/checkout"; pushed; fi
  slot "${HL:+$HF/$HL}"; [ -z "$HL" ] || { destroy "$HF/$HL"; rm -f "$HF/live"; echo "replaced $HL" >> "$D/log"; }
  checkout_
  p=$(fport "${DP_REHEARSAL_PORT:-47500}") || die "no free local port from ${DP_REHEARSAL_PORT:-47500}"; echo "$p" > "$D/port"; mkdir -p "$D/data"
  # restore: production's store dumped now, by the live production's own checkout when it runs (a hosted production's by backup: against its address), then loaded
  # into the copy's
  t=$(now); wh=$PF/$PL/checkout; if [ -n "$HO" ]; then hprod "$D"; DUMP=$D/dump; export DUMP; [ -n "$PL" ] && [ -d "$wh" ] || wh=$D/checkout; bounded "$SUL" "$D" "$(key backup)" "$wh"
  elif [ -n "$PL" ]; then names "$PF/$PL"; DUMP=$D/dump; export DUMP; bounded "$SUL" "$D" "$(key backup)" "$wh"
  else names "$D"; DATA_DIR=$PF/data; DUMP=$D/dump; export DATA_DIR DUMP; bounded "$SUL" "$D" "$(key backup)"; fi; members "$D"
  [ "$RC" = 0 ] && [ -e "$D/dump" ] || { case_ restore $(($(now) - t)) "the dump of production failed: $([ "$RC" = 0 ] && echo "no dump at $D/dump" || echo "exit $RC")"; failed restore; }
  DT=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); names "$D"; DUMP=$D/dump; export DUMP; bounded "$SUL" "$D" "$(key restore)"; members "$D"
  [ "$RC" = 0 ] || { case_ restore $(($(now) - t)) "the restore: exit $RC"; failed restore; }; case_ restore $(($(now) - t)) '' "restored from a dump of production taken at $DT"
  names "$D"; if [ -n "$(key migrate)" ]; then run_ migrate "$(key migrate)"; else case_ migrate 0 '' 'the record has no migrate:'; fi
  # 0.26.11.1.1 (R5): kept, after the migration and before the boot: the record's kept: on the dump and the migrated copy; its kept: lines go in report.txt
  t=$(now); names "$D"; DUMP=$D/dump; KC=$(key kept); KO=$D/kept.out; export DUMP KC KO; bounded "$SUL" "$D" 'sh -c "$KC" > "$KO"'; members "$D"; grep '^kept: ' "$KO" > "$D/kept" 2>/dev/null || true
  [ "$RC" = 0 ] || { case_ kept $(($(now) - t)) "$([ "$RC" = 124 ] && echo 'kept: past its limit' || echo "exit $RC: a permanent record lost or changed")"; failed kept; }
  [ -s "$D/kept" ] || { case_ kept $(($(now) - t)) 'kept: printed no kept: line'; failed kept; }; case_ kept $(($(now) - t)) '' "$(paste -sd ';' "$D/kept")"
  names "$D"; SE=no; B=$(key start); [ -z "$(key sealed-start)" ] || { SE=yes; B=$(key sealed-start); }
  t=$(now); bounded "$SUL" "$D" "$B"; members "$D"; [ "$RC" = 0 ] || { case_ boot $(($(now) - t)) "$([ "$RC" = 124 ] && echo 'start-up past its limit' || echo "exit $RC")"; failed boot; }
  L=$(key ready-seconds | grep . || echo 120); n=0; while ! up "$PORT" && [ "$n" -lt "$L" ]; do sleep 1; n=$((n + 1)); done
  up "$PORT" || { case_ boot $(($(now) - t)) "port $PORT did not answer within ${L}s"; failed boot; }
  case_ boot $(($(now) - t)) '' "$([ "$SE" = yes ] && echo 'started by sealed-start:, an internal network and one published port' || echo 'started by start:: not sealed')"
  report; { echo "sealed: $SE"; echo "copy: $BASE_URL"; printf '%s\n' "$SI" | awk -v b="$BASE_URL" 'NF { print "signin: " $1 " " b $2 }'; } >> "$D/report/$ID/report.txt"
  push || { destroy "$D"; die "not pushed: vid-results/$ID; the copy destroyed"; }; echo "$ID" > "$HF/live"; echo "pushed vid-results/$ID"; exit 0; fi
# staging
[ -z "$FS" ] || { case_ "$FS" 0 "a labelled plant (--fail-step $FS): nothing was deployed"; plant_ "$FS"; }
if [ -n "$HO" ]; then
  # hosted (0.26.11.1.1 R1, R6): the host's staging replaced by this one; production data, when asked, loaded before the migration
  [ -z "$LIVE" ] || { rm -rf "$SF/$LIVE/checkout"; rm -f "$SF/live"; echo "replaced $LIVE" >> "$D/log"; }
  checkout_
  if [ "$SEED" = production ]; then t=$(now); hprod "$D"; DUMP=$D/seed.dump; export DUMP; rm -rf "$DUMP"; wh=$PF/$PL/checkout; [ -d "$wh" ] || wh=''; bounded "$SUL" "$D" "$(key backup)" "$wh"; members "$D"
    [ "$RC" = 0 ] && [ -e "$DUMP" ] || { case_ seed $(($(now) - t)) "production's dump failed: $([ "$RC" = 0 ] && echo "no dump at $DUMP" || echo "exit $RC")"; failed seed; }
    DT=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); names "$D"; DUMP=$D/seed.dump; export DUMP; bounded "$SUL" "$D" "$(key restore)"; members "$D"
    [ "$RC" = 0 ] || { case_ seed $(($(now) - t)) "the restore into staging: exit $RC"; failed seed; }; case_ seed $(($(now) - t)) '' "production's data, dumped at $DT, loaded into staging"; fi
  names "$D"; if [ -n "$(key migrate)" ]; then run_ migrate "$(key migrate)"; else case_ migrate 0 '' 'the record has no migrate:'; fi
  run_ deploy "$(key deploy)"
  [ "$SEED" = production ] || [ -z "$(key seed)" ] || run_ seed "$(key seed)"
  ready_ ready
else
  # a real deploy: the live staging goes first, so staging holds one candidate
  slot "${LIVE:+$SF/$LIVE}"; [ -z "$LIVE" ] || { down "$SF/$LIVE"; rm -f "$SF/live"; echo "replaced $LIVE" >> "$D/log"; }
  checkout_
  p=$(fport "${DP_PORT:-47100}") || die "no free local port from ${DP_PORT:-47100}"; echo "$p" > "$D/port"; names "$D"
  run_ start "$(key start)"
  [ -z "$(key seed)" ] || run_ seed "$(key seed)"
  ready_ ready
fi
{ echo "staging: $BASE_URL"; printf '%s\n' "$SI" | awk -v b="$BASE_URL" 'NF { print "signin: " $1 " " b $2 }'
  for k in mail clock; do sed -n "s/^$k: *//p" "$SETUP" | head -n 1 | awk -v b="$BASE_URL" -v k="$k" 'NF { if ($0 ~ /^\//) $0 = b $0; print k ": " $0 }'; done; if [ -n "$DF" ]; then printf '%s\n' "$DF" | sed 's/^/differs: /'; else echo 'differs: none'; fi
  printf '%s\n' "$SM" | sed -n 's/^./seam: &/p'
  sed -n "/^real: *#${ASK#deploy-}-[0-9][0-9]* /p" "$SETUP" | awk '{ k = $2; if (!(k in L)) o[++n] = k; L[k] = $0 } END { for (i = 1; i <= n; i++) print L[o[i]] }'   # 0.26.11.1.3 (R3): this okay's alone, of a key the newest
  echo "seed: $SEED"; [ -z "$HO" ] || echo 'stays: up'; } > "$D/report/$ID/staging.txt"
report; duties
if [ -n "$HO" ]; then push || die "not pushed: vid-results/$ID; the host's staging runs it"; else push || { down "$D"; die "not pushed: vid-results/$ID; the staging taken down"; }; fi
echo "$ID" > "$SF/live"; echo "pushed vid-results/$ID"; exit 0
