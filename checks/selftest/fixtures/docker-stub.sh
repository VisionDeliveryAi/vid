# Purpose: selftest fixture — a docker command stub for the test-environment
# cases (v0.9.6 spec 3.9, 3.10; §7 cases 16–19). Sourced after gated-run.sh
# (Env: T). $T/docker.sh answers: `info` with $DOCKER_TOTAL_MB as bytes;
# `compose version --short` with 2.29.1; `stats --no-stream` with, for
# every run folder under $DSTUB_HOME/.vid/runs/ whose holder names a
# project, `<project>-product-1` at $ENV_PRODUCT and `<project>-tests-1` at
# $ENV_TESTS, then the containers of $T/others (`id<TAB>name<TAB>working
# dir<TAB>memory`); `stats … <id>` with that container's memory; `ps`
# with the others' ids and working directories; `ps -a` with $T/psa
# (`name<TAB>working dir<TAB>status<TAB>age`). Every call is logged to
# $T/docker.log. VID_DOCKER points at it. release_sampled and release_overlap
# (below) end a held run on the state awaited.
cat > "$T/docker.sh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$(dirname "$STUB_LOG")/docker.log"
SD=$(dirname "$STUB_LOG")
case "$1" in
  info) echo $(( ${DOCKER_TOTAL_MB:-16384} * 1048576 )) ;;
  compose) echo 2.29.1 ;;
  stats)
    for a in "$@"; do last=$a; done
    case "$*" in
      *'{{.Name}}'*)
        for h in "$DSTUB_HOME"/.vid/runs/*/holder; do
          [ -f "$h" ] || continue
          pj=$(sed -n 's/^project=//p' "$h"); [ -n "$pj" ] || continue
          printf '%s-product-1\t%s / 8GiB\n%s-tests-1\t%s / 8GiB\n' "$pj" "${ENV_PRODUCT:-300MiB}" "$pj" "${ENV_TESTS:-212MiB}"
        done
        [ -f "$SD/others" ] && awk -F'\t' '{ print $2 "\t" $4 " / 8GiB" }' "$SD/others" ;;
      *) [ -f "$SD/others" ] && awk -F'\t' -v i="$last" '$1 == i { print $4 " / 8GiB" }' "$SD/others" ;;
    esac ;;
  ps)
    case " $* " in
      *' -a '*) [ -f "$SD/psa" ] && cat "$SD/psa" ;;
      *) [ -f "$SD/others" ] && awk -F'\t' '{ print $1 "\t" $3 }' "$SD/others" ;;
    esac ;;
esac
exit 0
STUB
chmod +x "$T/docker.sh"
export VID_DOCKER="$T/docker.sh"
# v0.9.7.3 (R7): a held run is released on what was awaited, never after a sleep's guess (each wait bounded at 120 s,
# only so a hung run cannot hang the suite). release_sampled <hold>: in the background, once a stubbed `up` started
# after the hold was made holds and two `docker stats` samples were taken after it; release_overlap <hold> <n>: once n stubbed `up`s hold at once.
release_sampled() { ( _sd=$(dirname "$STUB_LOG"); _i=0
    until [ -n "$(find "$_sd" -maxdepth 1 -name 'up.*' -newer "$1" 2>/dev/null)" ] || [ "$_i" -ge 1200 ]; do sleep 0.1; _i=$((_i + 1)); done
    _n0=$(grep -c '{{.Name}}' "$_sd/docker.log" 2>/dev/null || true); _n0=${_n0:-0}; _i=0
    until [ "$(grep -c '{{.Name}}' "$_sd/docker.log" 2>/dev/null || echo 0)" -ge $((_n0 + 2)) ] || [ "$_i" -ge 1200 ]; do sleep 0.1; _i=$((_i + 1)); done
    rm -f "$1" ) & }
release_overlap() { ( _sd=$(dirname "$STUB_LOG"); _i=0
    until [ "$(ls "$_sd"/up.* 2>/dev/null | grep -c .)" -ge "$2" ] || [ "$_i" -ge 1200 ]; do sleep 0.1; _i=$((_i + 1)); done
    rm -f "$1" ) & }
