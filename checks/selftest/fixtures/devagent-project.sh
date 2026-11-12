#!/bin/sh
# Purpose: selftest fixture — a tiny code repository for DevAgent's run script (v0.26.10.24.1 R4). Sourced by the
# devagent-run case. `sp_project` makes $T/origin.git, a local bare repository, and pushes to it one commit ($SP_C) of a
# runner and four cases: ROW-001 passes, ROW-002 reaches for the product, ROW-003 hangs, ROW-004 passes after it. It
# writes the dev setup record $T/work/dev-setup.txt: engines alpha and beta, a case limit of 3 seconds, the product a
# background process. v0.26.10.24.4: product.txt, ROW-005 reads it, and ROW-006 stays green whatever it says. The runner honours SELECTION as a pattern over case names, CASE_LIMIT and RESULTS, and four
# selections of its own: noreport writes no results report; noreport-once writes none the first time; stray leaves a
# process behind; quiet and dies go silent, dies after marking a service dead. Reads only files under checks/. Env: T.
SP_T=$T; export SP_T
sp_git() { git -c user.email=sp@selftest -c user.name=sp "$@"; }
sp_project() {
  git init -q --bare "$T/origin.git"; git -C "$T/origin.git" symbolic-ref HEAD refs/heads/main
  git init -q "$T/dev"; git -C "$T/dev" symbolic-ref HEAD refs/heads/main; mkdir -p "$T/dev/tests/cases" "$T/work"
  cat > "$T/dev/tests/runner.sh" <<'R'
#!/bin/sh
echo "runner: $ENGINE, selection ${SELECTION:-all}"
case ${SELECTION:-} in
  noreport) echo 'nothing collected'; exit 4 ;;
  noreport-once) if [ ! -f "$SP_T/tried" ]; then : > "$SP_T/tried"; echo 'nothing collected'; exit 4; fi; SELECTION=ROW-001 ;;
  stray) sleep 300 & echo $! > "$SP_T/stray"; SELECTION=ROW-001 ;;
  quiet) exec sleep 30 ;;
  dies) echo dead > "$SP_T/dead"; exec sleep 30 ;;
esac
exec 3>&1; { echo '<testsuite name="toy">'
  for c in tests/cases/*.sh; do n=$(basename "$c" .sh)
    echo "$n" | grep -Eq "${SELECTION:-.}" || continue
    sh "$c" > "$SP_T/case.out" 2>&1 & p=$!; s=0
    while kill -0 "$p" 2>/dev/null && [ "$s" -lt "$CASE_LIMIT" ]; do sleep 1; s=$((s + 1)); done
    if kill -0 "$p" 2>/dev/null; then kill -9 "$p"; wait "$p" 2>/dev/null
      echo "<testcase name=\"$n\" time=\"$s\"><failure message=\"stopped at the case limit\"/></testcase>"; continue; fi
    rc=0; wait "$p" || rc=$?; grep '^covers: ' "$SP_T/case.out" >&3 || true
    if [ "$rc" = 0 ]; then echo "<testcase name=\"$n\" time=\"$s\"/>"
    else echo "<testcase name=\"$n\" time=\"$s\"><failure message=\"$(head -n 1 "$SP_T/case.out")\"/></testcase>"; fi
  done
  echo '</testsuite>'; } > "$RESULTS.tmp"
mv "$RESULTS.tmp" "$RESULTS"
R
  printf '[ -z "${SP_COVER:-}" ] || echo "covers: ROW-001 3"\nexit 0\n' > "$T/dev/tests/cases/ROW-001-home.sh"; echo 'exit 0' > "$T/dev/tests/cases/ROW-004-after.sh"
  echo 'exec sleep 30' > "$T/dev/tests/cases/ROW-003-hangs.sh"
  echo good > "$T/dev/product.txt"; echo 'exit 0' > "$T/dev/tests/cases/ROW-006-weak.sh"
  printf 'grep -q good product.txt || { echo "ROW-005: promised good, saw $(cat product.txt)"; exit 1; }\n' > "$T/dev/tests/cases/ROW-005-value.sh"
  cat > "$T/dev/tests/cases/ROW-002-product.sh" <<'R'
[ -f "$SP_T/product.pid" ] && kill -0 "$(cat "$SP_T/product.pid")" && exit 0
echo 'setup: no product to reach'; exit 1
R
  ( cd "$T/dev" && git add -A && sp_git commit -qm 'the toy' && git remote add origin "$T/origin.git" && git push -q origin main )
  SP_C=$(git -C "$T/dev" rev-parse HEAD)
  cat > "$T/work/dev-setup.txt" <<R
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
start: [ -n "\$NO_PRODUCT" ] || { sleep 300 > /dev/null 2>&1 & echo \$! > "\$SP_T/product.pid"; }
stop: [ ! -f "\$SP_T/product.pid" ] || { kill "\$(cat "\$SP_T/product.pid")"; mv "\$SP_T/product.pid" "\$SP_T/product.was"; }
run: sh tests/runner.sh
R
}
