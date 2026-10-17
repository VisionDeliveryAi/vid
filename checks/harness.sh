#!/bin/sh
# Purpose: ViD court — one product image (v0.9.2 3.6, R21), presence-gated,
# fail-closed. Rule source: docker-compose.test.yml's `x-vid-harness` key
# (product: <service>; forbidden: <in-process server tokens>) — the harness
# contract init generates; a compose file without the key is pre-0.9.2 and is
# reported, never convicted. Judgments: (1) exactly ONE service carries a
# `build:` — the product — and it is the named one; a second build (the same
# context with another target, or any other) is a second image; (2) no other
# service names the product's image (any tag) — the tests service reaches
# the product over the network at its name, never by running its image;
# (3) no file under tests/ carries a forbidden token — a server bound
# in-process inside the tests container is not the image the owner previews;
# (4) the README's preview command brings up the product service from THIS
# compose file (`docker-compose.test.yml … up … <product>`), and no second
# compose file exists at the root — what the owner previews is what the
# ledger certified, or it is nothing.
# v0.9.3 (3.3, R4 — the ungated set): rule 2 admits the deployed shape. A
# service named under x-vid-harness `processes:` may name the product image
# when its `image:` reference is BYTE-IDENTICAL to the product service's
# (0.9.2 compared repositories with the tag stripped — a worker on an older
# tag would certify code outside the export), carries no `build:`, and sits
# in the `deployed` profile. A `processes:` entry with no service, a process
# service outside the profile, and a process service on any other reference
# are rejections; every other service — the tests service first — still may
# not name the product's image at any tag.
# v0.9.7.0.10 (3.4, R8): judgment (1) counts the product and its
# `processes:` only — exactly one of them builds, the product. A service
# that is neither (the tests, a fake) may carry its own `build:`, so its
# dependencies can be installed into its image once instead of at every
# start; it still may not name the product's image (2).
# v0.9.7.0.10 (3.6, R12): when x-vid-harness carries `rules: 1` (the three
# rules, init and the template), judgment (5) holds rule 2's declarations,
# naming the service: every service the product's depends_on names carries
# a healthcheck and is waited for with `condition: service_healthy` — a
# one-shot service waited for with `condition: service_completed_successfully`
# is ready by its completion and needs none; the product carries a
# healthcheck; and the tests service waits for the product with `condition:
# service_healthy`. A start-only wait (the list form, or `service_started`)
# is a start, not readiness; an entry's condition is read in the block form
# and the one-line form (`<name>: {condition: …}`). Without the line nothing new is checked (Codex
# 7 on revision 2). Rules 1 and 3 name no court.
# v0.9.7.0.10 (3.6, R13): `rules` — the upgrade step's check, at develop's
# start. It prints `harness-upgrade harness=<cksum of the harness file>
# state=<the latest harness-upgrade state for that hash at the run's home,
# or none>` and exits 1 when the harness declares no `rules:` line and that
# hash has no `applied` or `declined` event; 0 when the line is there, the
# hash is done, or there is no harness. It writes nothing; the run manager
# records the states (`sh checks/event.sh 'harness-upgrade state=<due|
# dispatched|asked|applied|declined> harness=<hash>'`). A declined hash
# stays declined only while the file is unchanged: an edit is a new hash.
# v0.9.7.0.11 (3.2, R2): harness rule 4 — `case-limit: <seconds>` under
# x-vid-harness; checks/test.sh exports it as VID_CASE_LIMIT and the tests
# service references it, its runner stopping one case at the limit. `rules:
# 2` is rules 1–4: the court keeps judgment (5) and adds (6) `case-limit:`
# a positive integer and (7) the tests service's definition naming
# VID_CASE_LIMIT. The runner's enforcement is proved by running it, not
# here. The upgrade states are keyed by harness hash AND target rules
# version (`target=<n>` on the event; one without targets 1): `rules` is due
# when the harness's `rules:` is below the current target (2) and the pair
# (hash, 2) has no `applied` or `declined` event — it prints
# `harness-upgrade harness=<hash> target=2 state=<…>` — except that a
# target-1 step already under way for the hash (dispatched or asked) keeps
# its scope and is printed first, `target=1`; one only `due` is superseded
# by target 2 (nothing was done for it); a target-1 decline does not
# suppress target 2.
# Usage: sh checks/harness.sh [rules]
set -eu
IFS='
'
CF=docker-compose.test.yml
TARGET=2   # v0.9.7.0.11 (3.2, R2): the rules version the plugin brings — rules 1–4
if [ "${1:-}" = rules ]; then
  [ -f "$CF" ] || { echo "harness-upgrade: no $CF — nothing to upgrade"; exit 0; }
  HR=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="rules:"{print $2; exit}' "$CF")
  case "$HR" in ''|*[!0-9]*) HRN=0 ;; *) HRN=$HR ;; esac
  if [ "$HRN" -ge "$TARGET" ]; then echo "harness-upgrade: $CF declares rules: $HR — nothing due"; exit 0; fi
  HH=$(cksum < "$CF" | cut -d' ' -f1)
  # the run's home, as checks/event.sh resolves it: plan.sh home-of beside this script, else this worktree
  HM=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
  _pl="$(dirname "$0")/plan.sh"
  if [ -f "$_pl" ]; then _ph=$(sh "$_pl" home-of 2>/dev/null) && [ -n "$_ph" ] && [ -d "$_ph" ] && HM=$_ph; fi
  # the latest state of (this hash, target t); an event with no target= targets 1
  st_of() { awk -v h="harness=$HH" -v t="$1" '$1 == "harness-upgrade" { hit = 0; s = ""; tg = 1; for (i = 2; i <= NF; i++) { if ($i == h) hit = 1; if (index($i, "state=") == 1) s = substr($i, 7); if (index($i, "target=") == 1) tg = substr($i, 8) + 0 } if (hit && tg == t) last = s } END { print last }' "$HM/.vid/metrics-events" 2>/dev/null || true; }
  S1=$(st_of 1)
  case "$S1" in dispatched|asked) [ "$HRN" -lt 1 ] && { echo "harness-upgrade harness=$HH target=1 state=$S1"; exit 1; } ;; esac
  ST=$(st_of "$TARGET")
  echo "harness-upgrade harness=$HH target=$TARGET state=${ST:-none}"
  case "$ST" in applied|declined) exit 0 ;; esac
  exit 1
fi
[ -f "$CF" ] || exit 0
if ! grep -qE '^x-vid-harness:' "$CF"; then
  echo "note: $CF carries no x-vid-harness key (pre-0.9.2 harness, reported — v0.9.2 3.6 R21)"
  exit 0
fi
PRODUCT=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="product:"{print $2; exit}' "$CF")
PROCS=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="processes:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); gsub(/[][,]/," ",v); print v; exit }' "$CF" | tr ' ' '\n' | grep -v '^$' || true)
FORBID=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="forbidden:"{ $1=""; sub(/#.*/,""); print; exit}' "$CF")
RULES=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="rules:"{print $2; exit}' "$CF")
[ -n "$PRODUCT" ] || { echo "ViD harness: $CF x-vid-harness names no product: service — failing closed." >&2; exit 1; }
FAIL=0
# services: name → build (yes/no), image
SVC=$(awk '
  /^services:/ { ins=1; next }
  ins && /^[^ ]/ { ins=0 }
  ins && /^  [A-Za-z0-9_.-]+:/ { name=$1; sub(/:$/,"",name); svc[name]=1; order[++n]=name; inprof=0; next }
  ins && name != "" && /^    build:/ { build[name]=1; inprof=0; next }
  ins && name != "" && /^    image:/ { img=$2; image[name]=img; inprof=0; next }
  ins && name != "" && /^    profiles:/ { v=$0; sub(/^[^:]*:/,"",v); if (v ~ /deployed/) prof[name]=1; inprof=1; next }
  ins && name != "" && inprof && /^      - / { if ($0 ~ /deployed/) prof[name]=1; next }
  ins && name != "" && /^    [a-z]/ { inprof=0 }
  END { for (i=1;i<=n;i++) { s=order[i]; printf "%s\t%s\t%s\t%s\n", s, (s in build ? "build" : "-"), (s in image ? image[s] : "-"), (s in prof ? "deployed" : "-") } }' "$CF")
isproc() { printf '%s\n' "$PROCS" | grep -qxF "$1"; }
# v0.9.7.0.10 (R8): the builds among the product and its processes — the product's image, built once
PB=$(printf '%s\n' "$SVC" | awk -F'\t' '$2=="build" { print $1 }' | while IFS= read -r s; do { [ "$s" = "$PRODUCT" ] || isproc "$s"; } && echo "$s"; done || true)
NB=$(printf '%s\n' "$PB" | grep -c . || true)
if [ "$NB" -ne 1 ]; then
  echo "ViD harness: rejected — $NB services among the product and its processes carry a build: in $CF; one product image means ONE product build (the product service, $PRODUCT); a second build of it is a second image (R21; a service that is neither may build its own image, v0.9.7.0.10):" >&2
  printf '%s\n' "$PB" | grep . | sed 's/^/    /' >&2
  FAIL=1
fi
if ! printf '%s\n' "$SVC" | awk -F'\t' -v p="$PRODUCT" '$1==p && $2=="build"' | grep -q .; then
  echo "ViD harness: rejected — the product service '$PRODUCT' (x-vid-harness) carries no build: in $CF; the certifiable run builds the product from the export." >&2
  FAIL=1
fi
PIMG=$(printf '%s\n' "$SVC" | awk -F'\t' -v p="$PRODUCT" '$1==p { print $3 }')
if [ -n "$PIMG" ] && [ "$PIMG" != '-' ]; then
  PREPO=${PIMG%%:*}
  for line in $(printf '%s\n' "$SVC" | awk -F'\t' -v p="$PRODUCT" '$1!=p && $3!="-"'); do
    s=${line%%	*}; img=$(printf '%s\n' "$line" | cut -f3); repo=${img%%:*}; prof=$(printf '%s\n' "$line" | cut -f4)
    if isproc "$s"; then
      [ "$img" = "$PIMG" ] || { echo "ViD harness: rejected — process service '$s' runs '$img', not the product's image reference '$PIMG' byte for byte: a deployed-shape receipt certifies the export's image or nothing (v0.9.3 3.3)." >&2; FAIL=1; }
      continue
    fi
    if [ "$repo" = "$PREPO" ]; then
      echo "ViD harness: rejected — service '$s' names the product's image ($img; the product is $PIMG): the tests reach the product over the network at '$PRODUCT', never by running its image (R21); only a declared process may run it (v0.9.3 3.3)." >&2
      FAIL=1
    fi
  done
fi
for pr in $PROCS; do
  line=$(printf '%s\n' "$SVC" | awk -F'\t' -v s="$pr" '$1==s' | head -n 1)
  if [ -z "$line" ]; then echo "ViD harness: rejected — x-vid-harness processes: names '$pr' and no service '$pr' exists in $CF (v0.9.3 3.3)." >&2; FAIL=1; continue; fi
  [ "$(printf '%s\n' "$line" | cut -f4)" = deployed ] || { echo "ViD harness: rejected — process service '$pr' is outside the deployed profile; the inline pass must not start the product's processes (v0.9.3 3.3)." >&2; FAIL=1; }
  if [ "$(printf '%s\n' "$line" | cut -f2)" = build ]; then echo "ViD harness: rejected — process service '$pr' carries a build:; it runs the product's one image (v0.9.3 3.3)." >&2; FAIL=1; fi
  if [ "$(printf '%s\n' "$line" | cut -f3)" = '-' ]; then echo "ViD harness: rejected — process service '$pr' names no image; it runs the product's image reference byte for byte (v0.9.3 3.3)." >&2; FAIL=1; fi
done
# v0.9.7.0.10 (R12): rule 2's readiness declarations, once the harness declares the rules
case "$RULES" in 1|2) RULESC=yes ;; *) RULESC=no ;; esac
if [ "$RULESC" = yes ]; then
  # hc|nohc <service> — a healthcheck, or one disabled; dep <service> <needed> <condition> — each depends_on entry
  RD=$(awk '
    /^services:/ { ins=1; next }
    ins && /^[^ ]/ { flush(); ins=0 }
    !ins { next }
    function flush() { if (dn != "") print "dep\t" name "\t" dn "\t" (cond != "" ? cond : "service_started"); dn=""; cond="" }
    /^  [A-Za-z0-9_.-]+:/ { flush(); name=$1; sub(/:$/,"",name); blk=""; next }
    name == "" { next }
    /^    [a-z_]+:/ { flush(); blk=$1; sub(/:$/,"",blk)
      if (blk == "healthcheck") print "hc\t" name
      if (blk == "depends_on") { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); gsub(/[][,]/," ",v); k=split(v, a, " "); for (i=1;i<=k;i++) print "dep\t" name "\t" a[i] "\tservice_started" }
      next }
    blk == "healthcheck" && /^      disable:[ \t]*true/ { print "nohc\t" name; next }
    blk == "depends_on" && /^      - / { v=$2; sub(/#.*/,"",v); print "dep\t" name "\t" v "\tservice_started"; next }
    blk == "depends_on" && /^      [A-Za-z0-9_.-]+:/ { flush(); dn=$1; sub(/:$/,"",dn)
      if (match($0, /condition:[ \t]*[a-z_]+/)) { cond=substr($0, RSTART, RLENGTH); sub(/condition:[ \t]*/, "", cond) }   # the one-line form, `<name>: {condition: …}`
      next }
    blk == "depends_on" && dn != "" && /^        condition:/ { cond=$2; next }
    END { flush() }' "$CF")
  has_ready() { printf '%s\n' "$RD" | awk -F'\t' -v s="$1" '$1=="hc" && $2==s { y=1 } $1=="nohc" && $2==s { y=0 } END { exit !y }'; }
  has_ready "$PRODUCT" || { echo "ViD harness: rejected — rules: $RULES — the product service '$PRODUCT' declares no healthcheck; the tests wait for the product to be ready, not only started (rule 2, v0.9.7.0.10 R12)." >&2; FAIL=1; }
  for line in $(printf '%s\n' "$RD" | awk -F'\t' -v p="$PRODUCT" '$1=="dep" && $2==p { print $3 "\t" $4 }'); do
    d=${line%%	*}; c=${line#*	}
    [ "$c" = service_completed_successfully ] && continue
    has_ready "$d" || { echo "ViD harness: rejected — rules: $RULES — service '$d', which the product depends on, declares no healthcheck; the product starts once it is ready (rule 2, v0.9.7.0.10 R12)." >&2; FAIL=1; }
    [ "$c" = service_healthy ] || { echo "ViD harness: rejected — rules: $RULES — the product waits for service '$d' only to start ($c), not to be ready; depends_on '$d' with condition: service_healthy (rule 2, v0.9.7.0.10 R12)." >&2; FAIL=1; }
  done
  TC=$(printf '%s\n' "$RD" | awk -F'\t' -v p="$PRODUCT" '$1=="dep" && $2=="tests" && $3==p { print $4; exit }')
  TW='not at all'; [ -n "$TC" ] && TW="only to start ($TC)"
  [ "$TC" = service_healthy ] || { echo "ViD harness: rejected — rules: $RULES — the tests service waits for the product '$PRODUCT' $TW, not to be ready; depends_on '$PRODUCT' with condition: service_healthy (rule 2, v0.9.7.0.10 R12)." >&2; FAIL=1; }
fi
# v0.9.7.0.11 (3.2, R2): rule 4, with `rules: 2` — the per-case limit declared, and handed to the tests' runner
if [ "$RULES" = 2 ]; then
  CL=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="case-limit:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' "$CF")
  case "$CL" in ''|*[!0-9]*|0) echo "ViD harness: rejected — rules: 2 — x-vid-harness carries no case-limit: of whole seconds above 0 ('${CL:-none}'); rule 4: no one case runs longer than the limit (v0.9.7.0.11 R2)." >&2; FAIL=1 ;; esac
  awk '/^services:/ { ins=1; next } ins && /^[^ ]/ { ins=0 } ins && /^  [A-Za-z0-9_.-]+:/ { t = ($1 == "tests:"); next } ins && t && /VID_CASE_LIMIT/ { f=1 } END { exit !f }' "$CF" \
    || { echo "ViD harness: rejected — rules: 2 — the tests service does not reference VID_CASE_LIMIT; its runner stops one case at the limit checks/test.sh hands it (rule 4, v0.9.7.0.11 R2)." >&2; FAIL=1; }
fi
if [ -d tests ] && [ -n "$(printf '%s' "$FORBID" | tr -d ' ')" ]; then
  for t in $(printf '%s\n' "$FORBID" | tr ' ' '\n' | grep -v '^$'); do
    HITS=$(grep -rnF -- "$t" tests 2>/dev/null | grep -v '\.md:' || true)
    if [ -n "$HITS" ]; then
      echo "ViD harness: rejected — tests carry the in-process server token '$t' (x-vid-harness forbidden:); a product bound inside the tests process is not the image the owner previews (R21):" >&2
      printf '%s\n' "$HITS" | head -n 3 | sed 's/^/    /' >&2
      FAIL=1
    fi
  done
fi
OTHERCF=$(ls docker-compose*.yml docker-compose*.yaml compose*.yml compose*.yaml 2>/dev/null | grep -vx "$CF" || true)
if [ -n "$OTHERCF" ]; then
  echo "ViD harness: rejected — a second compose file exists beside $CF; the preview runs the harness's product service from the one file (R21):" >&2
  printf '%s\n' "$OTHERCF" | sed 's/^/    /' >&2
  FAIL=1
fi
if [ -f README.md ]; then
  if ! grep -E "$CF.*[[:space:]]up[[:space:]].*[[:space:]]$PRODUCT([[:space:]]|\`|$)" README.md | grep -qv -- '-f [^ ]*\.yml.*-f ' ; then
    echo "ViD harness: rejected — README.md carries no preview command bringing up the product service from $CF (… -f $CF up … $PRODUCT); what the owner previews is what the ledger certified, or it is nothing (R21)." >&2
    FAIL=1
  fi
  OTHERREF=$(grep -oE -- '-f[[:space:]]+[A-Za-z0-9_./-]*compose[A-Za-z0-9_.-]*\.ya?ml' README.md | awk '{print $2}' | grep -vx "$CF" | sort -u || true)
  if [ -n "$OTHERREF" ]; then
    echo "ViD harness: rejected — README.md names a compose file other than $CF:" >&2
    printf '%s\n' "$OTHERREF" | sed 's/^/    /' >&2
    FAIL=1
  fi
fi
exit $FAIL
