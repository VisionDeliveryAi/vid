#!/bin/sh
# Purpose: selftest fixture — a stand-in host for DevAgent's deployer's hosted mode (0.26.11.1.1, R1, R5, R6). Run, never sourced:
# `sh devagent-host.sh <call>`, from a dev setup record's host lines. Each call is logged to $FH/calls, one line:
# `<call> <TARGET> <RUN_ID> <the checkout's commit> port=<PORT or none> data=<DATA_DIR or none> base=<BASE_URL> seed=<SEED>`.
#   login    exits 0, unless $FH/logged-out exists (exit 1, the tool not logged in)
#   deploy   serves TARGET's address on 127.0.0.1 (FH_STAGING_PORT or FH_PRODUCTION_PORT) with a plain web answer, in a process group of
#            its own, replacing what it served there before; with $FH/no-serve it serves nothing
#   migrate  `migrated <RUN_ID>` added to the store; seed: `seeded <SEED>` added
#   backup   the store copied to DUMP; restore: DUMP copied into the store
#   kept     each `record:` line of DUMP still in DATA_DIR's store: `kept: records — <n> rows`, exit 0; one gone, exit 1
#   down     every server it serves stopped
# The store is DATA_DIR/data.txt when DATA_DIR is set (a local copy), else the host's own, $FH/<TARGET>.data. $FH/fail-<call> makes that
# call exit 3. Env: FH, FH_STAGING_PORT, FH_PRODUCTION_PORT, and the names deploy.sh gives a record's commands.
set -u
c=${1:-}; t=${TARGET:-none}
echo "$c $t ${RUN_ID:-none} $(git rev-parse HEAD 2>/dev/null || echo none) port=${PORT:-none} data=${DATA_DIR:-none} base=${BASE_URL:-} seed=${SEED:-}" >> "$FH/calls"
[ ! -f "$FH/fail-$c" ] || { echo "devagent-host: $c failed, as asked"; exit 3; }
if [ -n "${DATA_DIR:-}" ]; then st=$DATA_DIR/data.txt; else st=$FH/$t.data; fi
serve() { while :; do printf 'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok' | nc -l 127.0.0.1 "$1" > /dev/null 2>&1 || sleep 1; done; }
case $c in
  login) [ ! -f "$FH/logged-out" ] || { echo 'devagent-host: not logged in'; exit 1; } ;;
  deploy) [ ! -f "$FH/$t.pid" ] || { kill -s TERM -- "-$(cat "$FH/$t.pid")" 2>/dev/null || true; rm -f "$FH/$t.pid"; sleep 1; }
    [ ! -f "$FH/no-serve" ] || exit 0
    case $t in staging) p=$FH_STAGING_PORT ;; production) p=$FH_PRODUCTION_PORT ;; *) echo "devagent-host: no target '$t'"; exit 2 ;; esac
    set -m; serve "$p" < /dev/null > /dev/null 2>&1 & echo $! > "$FH/$t.pid"; set +m ;;
  migrate) echo "migrated ${RUN_ID:-}" >> "$st" ;;
  seed) echo "seeded ${SEED:-}" >> "$st" ;;
  backup) touch "$st"; cp "$st" "$DUMP" ;;
  restore) cp "$DUMP" "$st" ;;
  kept) n=0; while IFS= read -r l; do case $l in record:*) grep -qxF -- "$l" "$st" || { echo "devagent-host: lost: $l"; exit 1; }; n=$((n + 1)) ;; esac; done < "$DUMP"
    echo "kept: records — $n rows" ;;
  down) for f in "$FH"/*.pid; do [ -f "$f" ] || continue; kill -s TERM -- "-$(cat "$f")" 2>/dev/null || true; rm -f "$f"; done ;;
  *) echo "devagent-host: no call '$c'"; exit 2 ;;
esac
exit 0
