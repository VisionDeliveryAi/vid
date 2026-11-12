#!/bin/sh
# Purpose: selftest case — the record contract covers every writer (v0.9.5
# spec 3.10, R10; §7 case 16). Every event type written must be listed in
# RECORDS.md's Events table, taken from three sources: the code (checks/*.sh,
# checks/hooks/*, the plugin's hooks/*.sh — a single- or double-quoted
# `printf '<type> …'` appended to the events file, traps included); every
# `event.sh '<type> …'` call under skills/; develop's catalogue (the
# "Record the dataset as you go" paragraph's `<type> <field>=…` spans). In
# the plugin repository the real tree must show no drift. Then, on a
# scratch copy, each of three plants must be caught alone: a new
# single-quoted writer, a new double-quoted writer in a trap, a new
# event.sh call in a skill. Where RECORDS.md is absent (a project: init
# copies checks/ alone), the scratch copy is the project's checks/ with a
# contract listing the types its code writes — it still proves the
# detector convicts each plant. v0.9.6.2 (3.9, R8; §6 case 21): the code
# source also takes an `event.sh "<type> …"` call in a script or hook (the
# refusal and deploy-gate writers), and in the plugin repository each event
# type records 4 adds — session, agent-start, agent-stop, refused,
# deploy-gate, deploy-confirm, deploy-rollback — must be found written AND
# listed. v0.9.6.2.2: a project's stub contract also lists the types its
# scripts write through event.sh, as the detector reads them. v0.9.7.0.3
# (3.4, R7): the two records-7 events, analyst-due (checks/test.sh) and
# analyst-done (the test manager's skill), must be found written AND
# listed in the plugin repository. v0.9.7.2 (3.12, R16): so must the five
# records-17 events — strategy, step-done, step-rows-passing, deferred,
# deferred-resolved. v0.9.7.3 (3.10, R10): so must the two records-18
# events, decision-labels and court-refused. v0.9.7.4 (3.11, R12): so must
# the records-19 event, delegated. v0.9.8 (R14; amendment 3): so must two records-20 events —
# test-proven, authority-kept. v0.26.10.6 (R17): so must the records-26 event, usage. v0.26.10.7 (R18): so must the
# records-27 events, deploy-check and stage-hold. v0.26.10.8 (R14): so must the records-28 event, staging-auth.
# v0.26.10.9 (R28): the code source also takes a script's own `ev "<type> …"` helper call (ticket.sh, github.sh), and
# the records-29 events — ticket, milestone, publish-approved, skeleton — must be found written AND listed (copy-check's
# only writer, ticket.sh, removed in 0.26.10.28.1: its row is marked not written).
# v0.26.10.12 (H1): the project branch's stub read only two of the three forms, so in every init'd project the case
# aborted before any plant; both now read one extraction, and the project branch runs in the plugin repository too.
# v0.26.10.27.4 (R8, records 33): the extraction is made whole and the contract is checked both ways, names and
# fields. A type is `[a-z][a-z0-9-]*` on both sides. A writer's literal is its whole quoted argument, up to its own
# closing quote, each `$(…)` inside it one unit; its fields are the literal's `<key>=` tokens, less a direct printf's
# final `at=` (the time; event.sh appends its own, so any other `at=` is a field). A `# fields: <key>= …` comment on a
# writer's line names keys it builds at run time; its bare words name the types of a writer whose type is built at
# run time; on a line with no writer (event.sh's `run=` on a stage start) it names keys a helper adds to those types.
# A row's fields are the keys of its fields cell's code spans. Three checks besides the unlisted type: a listed type
# no writer writes, a field written but not listed, a field listed but never written — the first and third unless
# marked `*(not written from <version>)*` (on the row's writer or when cell; right after the key's code span). The
# project branch's stub contract writes each type's fields cell from the written keys. Ten plants, each caught alone
# on both scratch copies: the three above, a new field in a writer, a field listed that no writer writes, a type
# listed that no writer writes, a type with a digit, a field after a `$(…)`, a key removed from a `# fields:` comment,
# and the payload `at=` removed from landed's writer.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ROOT=$(cd "$CHECKS/.." && pwd)
# writers.awk: one line per writer found, "<where><TAB><type><TAB><key> <key> …".
#   -v mode=code: a script or hook, line by line — a `printf '<type> …'` on a line appending to the events file, an
#     `event.sh '<type> …'` call, an `ev '<type> …'` helper call; the literal must hold a `=`.
#   -v mode=skill -v F=<file>: a skill file joined into one line; `event.sh '<type> …'` calls only.
#   -v mode=span: develop's catalogue, one `<type> <field>=…` span a line.
cat > "$T/writers.awk" <<'AWK'
function lit(s, i, q,    o, c, d, iq) {   # the literal opened by the quote q at i; END_ its closing quote, 0 if none
  o = ""
  for (i = i + 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (q == SQ) { if (c == SQ) { END_ = i; return o } o = o c; continue }
    if (c == "\\") { o = o substr(s, i, 2); i++; continue }
    if (c == "\"") { END_ = i; return o }
    if (c == "$" && substr(s, i + 1, 1) == "(") {   # $(…) as one unit: nested parentheses and quotes inside it
      d = 0; iq = ""
      for (i = i + 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (iq == SQ) { if (c == SQ) iq = ""; continue }
        if (iq == "\"") { if (c == "\\") { i++; continue } if (c == "\"") iq = ""; continue }
        if (c == SQ || c == "\"") { iq = c; continue }
        if (c == "\\") { i++; continue }
        if (c == "(") d++
        else if (c == ")") { d--; if (d == 0) break }
      }
      o = o "@"; continue
    }
    o = o c
  }
  END_ = 0; return o
}
function keys(s,    r, k, out, seen) {   # the <key>= tokens, each once, in order
  out = ""; split("", seen); r = " " s
  while (match(r, /[ \t\[{+][a-z][a-z0-9-]*=/)) {
    k = substr(r, RSTART + 1, RLENGTH - 2); r = substr(r, RSTART + RLENGTH)
    if (!(k in seen)) { seen[k] = 1; out = out (out == "" ? "" : " ") k }
  }
  return out
}
function words(s,    n, a, i, out) {   # a comment's bare words: the types it names
  out = ""; n = split(s, a, /[ \t]+/)
  for (i = 1; i <= n; i++) if (a[i] ~ /^[a-z][a-z0-9-]*$/) out = out (out == "" ? "" : " ") a[i]
  return out
}
function emit(where, form, l,    t, ks, n, a, i, o, ts) {
  if (match(l, /^[a-z][a-z0-9-]* /)) { t = substr(l, 1, RLENGTH - 1); ts = t }
  else if (match(l, /^[a-z][a-z0-9-]*\$[^ ]* /) && FXT != "") ts = FXT   # a type built at run time, named by the comment
  else return
  l = substr(l, RLENGTH)
  if (mode == "code" && index(l, "=") == 0) return
  ks = keys(l)
  if (form == "printf") { n = split(ks, a, " "); if (n > 0 && a[n] == "at") { o = ""; for (i = 1; i < n; i++) o = o (o == "" ? "" : " ") a[i]; ks = o } }
  if (FXK != "") ks = ks (ks == "" ? "" : " ") FXK
  n = split(ts, a, " "); for (i = 1; i <= n; i++) print where "\t" a[i] "\t" ks
  FOUND = 1
}
function scan(s, where, evline,    rest, p, q, l, best, bf) {
  FXK = ""; FXT = ""; FOUND = 0
  if ((p = index(s, "# fields:")) > 0) { FXK = keys(substr(s, p + 9)); FXT = words(substr(s, p + 9)) }
  rest = s
  while (1) {
    best = 0; bf = ""
    if (mode == "code" && evline && match(rest, /printf[ \t]+['"]/)) { best = RSTART + RLENGTH - 1; bf = "printf" }
    if (match(rest, /event\.sh"?[ \t]+['"]/) && (best == 0 || RSTART + RLENGTH - 1 < best)) { best = RSTART + RLENGTH - 1; bf = "event" }
    if (mode == "code" && match(rest, /(^|[;&|( \t])ev[ \t]+['"]/) && (best == 0 || RSTART + RLENGTH - 1 < best)) { best = RSTART + RLENGTH - 1; bf = "ev" }
    if (best == 0) break
    q = substr(rest, best, 1); l = lit(rest, best, q)
    if (END_ == 0) break
    emit(where, bf, l)
    rest = substr(rest, END_ + 1)
  }
  if (!FOUND && mode == "code" && FXK != "" && FXT != "") {   # a helper's comment: keys it adds to those types
    n = split(FXT, a, " "); for (i = 1; i <= n; i++) print where "\t" a[i] "\t" FXK
  }
}
BEGIN { SQ = sprintf("%c", 39) }
mode == "span" { emit("develop's catalogue", "span", $0); next }
mode == "skill" { scan($0, F, 0); next }
{ scan($0, FILENAME ":" FNR, ($0 ~ />>/ && $0 ~ /metrics-events|"\$EV"|\$EVENTS|\$\{EV\}/)) }
AWK
# listed.awk: RECORDS.md's Events table, one line per row, "<type><TAB><1|0 marked><TAB><keys><TAB><marked keys>".
# Cells split on `|` outside code spans, an escaped `\|` kept; the fields cell is the second.
cat > "$T/listed.awk" <<'AWK'
function keys(s,    r, k, out) {
  out = ""; r = " " s
  while (match(r, /[ \t\[{+(][a-z][a-z0-9-]*=/)) { k = substr(r, RSTART + 1, RLENGTH - 2); r = substr(r, RSTART + RLENGTH); out = out " " k }
  return out
}
/^## Events/ { on = 1; next }
on && /^## / { exit }
on && /^\| `[a-z][a-z0-9-]*` \|/ {
  n = 0; cell = ""; sp = 0; s = $0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\" && substr(s, i + 1, 1) == "|") { cell = cell "|"; i++; continue }
    if (c == "`") sp = !sp
    if (c == "|" && !sp) { C[++n] = cell; cell = ""; continue }
    cell = cell c
  }
  C[++n] = cell
  t = C[2]; gsub(/[ `]/, "", t)
  rm = (C[4] " " C[5]) ~ /\*\(not written from [^)]*\)\*/ ? 1 : 0
  ks = ""; mk = ""; m = split(C[3], P, "`")
  for (i = 2; i <= m; i += 2) {
    if (i + 1 <= m && P[i + 1] ~ /^[ \t]*\*\(not written from [^)]*\)\*/) mk = mk keys(P[i]); else ks = ks keys(P[i])
  }
  print t "\t" rm "\t" ks "\t" mk
  for (i = 1; i <= n; i++) delete C[i]
}
AWK
# drift.awk: the listed lines, then the writer lines; prints each drift, sorted by the caller
cat > "$T/drift.awk" <<'AWK'
FNR == NR { L[$1] = 1; RM[$1] = $2; n = split($3, a, " "); for (i = 1; i <= n; i++) LK[$1 SUBSEP a[i]] = 1
  n = split($4, a, " "); for (i = 1; i <= n; i++) MK[$1 SUBSEP a[i]] = 1; next }
{ W[$2] = 1; w = $1; if (match(w, /(checks|hooks)\/[^\/]*(\/[^\/]*)?:[0-9]+$/)) w = substr(w, RSTART)
  n = split($3, a, " "); for (i = 1; i <= n; i++) { k = $2 SUBSEP a[i]; WK[k] = 1; if (!(k in AT)) AT[k] = w } }
END {
  for (t in W) if (!(t in L)) print "unlisted: " t
  for (t in L) if (!(t in W) && !RM[t]) print "unwritten type: " t
  for (k in WK) { split(k, p, SUBSEP); if ((p[1] in L) && !(k in LK) && !(k in MK)) print "unlisted field: " p[1] " " p[2] "= (" AT[k] ")" }
  for (k in LK) { split(k, p, SUBSEP); if ((p[1] in W) && !(k in WK) && !(k in MK)) print "unwritten field: " p[1] " " p[2] "=" }
}
AWK
# code_writers <file>...: the writers in scripts and hooks. v0.26.10.12 (H1): the detector and a project's stub
# contract both read through this one function, so they cannot read different forms again.
code_writers() { for f in "$@"; do [ -f "$f" ] || continue; awk -v mode=code -f "$T/writers.awk" "$f"; done; }
# drift <root>: prints each drift of RECORDS.md against the writers; exit 1 if any
drift() {
  _r=$1
  code_writers "$_r"/checks/*.sh "$_r"/checks/hooks/* "$_r"/hooks/*.sh "$_r"/checks/selftest/run.sh > "$T/w"   # v0.9.8.1: run.sh writes selftest-retried
  if [ -d "$_r/skills" ]; then
    find "$_r/skills" -type f -name '*.md' | while IFS= read -r f; do
      tr '\n' ' ' < "$f" | awk -v mode=skill -v F="${f#"$_r"/}" -f "$T/writers.awk"
    done >> "$T/w"
    D="$_r/skills/vid-develop/SKILL.md"
    if [ -f "$D" ]; then
      awk '/Record the dataset as you go/ { on = 1 } on && /^[[:space:]]*$/ { exit } on' "$D" | tr '\n' ' ' \
        | { grep -oE '`[a-z][a-z0-9-]* [^`]*=[^`]*`' || true; } | sed 's/^`//; s/`$//' | awk -v mode=span -f "$T/writers.awk" >> "$T/w"
    fi
  fi
  [ -f "$_r/RECORDS.md" ] || { echo 'no RECORDS.md'; return 1; }
  awk -f "$T/listed.awk" "$_r/RECORDS.md" > "$T/l"
  cut -f1 "$T/l" | sort -u > "$T/listed"
  [ -s "$T/listed" ] || { echo 'RECORDS.md lists no event type'; return 1; }
  cut -f2 "$T/w" | sort -u | grep -v '^$' > "$T/written" || true
  [ -s "$T/written" ] || { echo 'no writer found — the extraction is broken'; return 1; }
  _m=$(awk -F'\t' -f "$T/drift.awk" "$T/l" "$T/w" | sort)
  [ -z "$_m" ] || { printf '%s\n' "$_m"; return 1; }
  return 0
}
# copy <scratch>: the checks/ under test, its scripts and hooks, and the self-test runner (it writes selftest-retried)
copy() { mkdir -p "$1/checks/hooks" "$1/checks/selftest"; cp "$CHECKS"/*.sh "$1/checks/"; cp "$CHECKS"/hooks/* "$1/checks/hooks/"; [ ! -f "$CHECKS/selftest/run.sh" ] || cp "$CHECKS/selftest/run.sh" "$1/checks/selftest/"; }
# plants <scratch> <branch>: the copy shows no drift, then each of the ten plants is caught alone, by its own drift
plants() {
  _s=$1 _b=$2
  OUT=$(drift "$_s") || { printf 'records-drift: the %s scratch copy drifts before any plant:\n%s\n' "$_b" "$OUT" >&2; exit 1; }
  mkdir -p "$_s/skills/vid-plant" "$_s/orig"
  cp "$_s/RECORDS.md" "$_s/checks/brief.sh" "$_s/checks/land.sh" "$_s/orig/"
  for p in single double skill field listed row digit after comment payload; do
    rm -f "$_s/checks/plant.sh" "$_s/skills/vid-plant/SKILL.md"
    cp "$_s/orig/RECORDS.md" "$_s/"; cp "$_s/orig/brief.sh" "$_s/orig/land.sh" "$_s/checks/"
    case "$p" in
      single) W='unlisted: xplant'
        printf '#!/bin/sh\n# Purpose: plant\nprintf '"'"'xplant n=%%s\\n'"'"' 1 >> .vid/metrics-events\n' > "$_s/checks/plant.sh" ;;
      double) W='unlisted: yplant'
        printf '#!/bin/sh\n# Purpose: plant\ntrap '"'"'printf "yplant seconds=%%s\\n" 1 >> .vid/metrics-events'"'"' EXIT\n' > "$_s/checks/plant.sh" ;;
      skill) W='unlisted: zplant'
        printf 'Then record\n`sh checks/event.sh '"'"'zplant slice=N n=K'"'"'` and continue.\n' > "$_s/skills/vid-plant/SKILL.md" ;;
      field) W='unlisted field: completion xplantfield='   # a new field in a writer of a listed type
        printf '#!/bin/sh\n# Purpose: plant\nprintf '"'"'completion unmet=%%s strict-gaps=%%s xplantfield=%%s at=%%s\\n'"'"' 0 0 1 now >> .vid/metrics-events\n' > "$_s/checks/plant.sh" ;;
      listed) W='unwritten field: completion xplantlisted='   # the contract lists a field no writer writes
        sed 's/^| `completion` | /| `completion` | `xplantlisted=<n>` /' "$_s/orig/RECORDS.md" > "$_s/RECORDS.md" ;;
      row) W='unwritten type: xplant-row'   # the contract lists a type no writer writes
        awk '{ print } /^\| `completion` \|/ { print "| `xplant-row` | `n=<n>` | nobody | never |" }' "$_s/orig/RECORDS.md" > "$_s/RECORDS.md" ;;
      digit) W='unlisted: xplant9'   # a type with a digit
        printf '#!/bin/sh\n# Purpose: plant\nprintf '"'"'xplant9 n=%%s at=%%s\\n'"'"' 1 now >> .vid/metrics-events\n' > "$_s/checks/plant.sh" ;;
      after) W='unlisted field: completion xplantafter='   # a field after a $(…) holding quotes
        printf '#!/bin/sh\n# Purpose: plant\nsh checks/event.sh "completion unmet=$(printf "%%s" 0) strict-gaps=0 xplantafter=1"\n' > "$_s/checks/plant.sh" ;;
      comment) W='unwritten field: manager-cost input='   # a key removed from a # fields: comment
        sed 's/# fields: calls= input=/# fields: calls=/' "$_s/orig/brief.sh" > "$_s/checks/brief.sh" ;;
      payload) W='unwritten field: landed at='   # landed's payload at=<the landing> removed from its writer
        sed '/ev "landed /s/ at=\$L//' "$_s/orig/land.sh" > "$_s/checks/land.sh" ;;
    esac
    if OUT=$(drift "$_s"); then echo "records-drift: the $p plant was not caught in the $_b scratch copy" >&2; exit 1; fi
    printf '%s\n' "$OUT" | grep -qF "$W" || { printf 'records-drift: the %s plant failed for another reason in the %s scratch copy:\n%s\n' "$p" "$_b" "$OUT" >&2; exit 1; }
    [ "$(printf '%s\n' "$OUT" | grep -c .)" -eq 1 ] || { printf 'records-drift: the %s plant was not caught alone in the %s scratch copy:\n%s\n' "$p" "$_b" "$OUT" >&2; exit 1; }
  done
}
if [ -f "$ROOT/RECORDS.md" ]; then
  OUT=$(drift "$ROOT") || { printf 'records-drift: the shipped tree drifts from RECORDS.md:\n%s\n' "$OUT" >&2; exit 1; }
  for t in session agent-start agent-stop refused deploy-gate deploy-confirm deploy-rollback; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-4 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-4 event $t" >&2; exit 1; }
  done
  for t in analyst-due analyst-done; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-7 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-7 event $t" >&2; exit 1; }
  done
  for t in strategy step-done step-rows-passing deferred deferred-resolved; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-17 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-17 event $t" >&2; exit 1; }
  done
  for t in delegated; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-19 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-19 event $t" >&2; exit 1; }
  done
  for t in test-proven authority-kept; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-20 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-20 event $t" >&2; exit 1; }
  done
  for t in selftest-retried agent-brief; do   # v0.9.8.1 (R24)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-21 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-21 event $t" >&2; exit 1; }
  done
  for t in usage; do   # v0.26.10.6 (R17)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-26 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-26 event $t" >&2; exit 1; }
  done
  for t in deploy-check stage-hold; do   # v0.26.10.7 (R18)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-27 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-27 event $t" >&2; exit 1; }
  done
  for t in ticket milestone publish-approved skeleton; do   # v0.26.10.9 (R28); copy-check went with ticket.sh (0.26.10.28.1), its row marked not written
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-29 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-29 event $t" >&2; exit 1; }
  done
  for t in staging-auth; do   # v0.26.10.8 (R14)
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-28 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-28 event $t" >&2; exit 1; }
  done
  for t in decision-labels court-refused; do
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the records-18 event $t was found" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md does not list the records-18 event $t" >&2; exit 1; }
  done
  for t in stage-c3 stage-s1 stage-d1; do   # v0.26.10.27.4 (R8): types with a digit, found on both sides
    grep -qxF "$t" "$T/written" || { echo "records-drift: no writer of the event $t was found — the type pattern drops digits" >&2; exit 1; }
    grep -qxF "$t" "$T/listed" || { echo "records-drift: RECORDS.md's $t was not read — the type pattern drops digits" >&2; exit 1; }
  done
  S="$T/plugin"; copy "$S"
  cp "$ROOT/RECORDS.md" "$S/"
  [ -d "$ROOT/skills" ] && cp -R "$ROOT/skills" "$S/"
  [ -d "$ROOT/hooks" ] && cp -R "$ROOT/hooks" "$S/"
  plants "$S" plugin
fi
# v0.26.10.12 (H1): the project branch runs everywhere, the plugin repository included, so ViD's own suite takes the
# path every init'd project takes: checks/ alone, with a contract listing exactly what its code writes. v0.26.10.27.4
# (R8): each type's fields cell holds the keys its writers write, by the same extraction.
S="$T/project"; copy "$S"
mkdir -p "$S/skills"; printf '# stub\n' > "$S/skills/stub.md"
{ printf '## Events\n\n| type | fields |\n|---|---|\n'
  code_writers "$S"/checks/*.sh "$S"/checks/hooks/* "$S"/checks/selftest/run.sh | awk -F'\t' '{ T[$2] = 1; n = split($3, a, " "); for (i = 1; i <= n; i++) if (!(($2 SUBSEP a[i]) in S)) { S[$2 SUBSEP a[i]] = 1; K[$2] = K[$2] " " a[i] "=x" } }
    END { for (t in T) { k = K[t]; sub(/^ /, "", k); print "| `" t "` | " (k == "" ? "x" : "`" k "`") " |" } }' | sort
} > "$S/RECORDS.md"
plants "$S" project
exit 0
