#!/bin/sh
# Purpose: ViD's project viewer (v0.9.7.4 spec, R1–R9, R11) — `/vid view` runs it. It makes self-contained HTML
# snapshots of a ViD project, one file each, that open by double-click and work offline: now, one for every
# milestone not yet made, and an index. It reads the project's documents in git and ViD's records and writes only
# into its own folder, outside the project.
#   sh viewer/view.sh [<project>] [--out <dir>] [--at <commit|UTC time>]
#     <project>: given, or the current directory; it must hold PRD.md. --out: else `~/ViD Viewer/<folder name>/`.
#     --at: one extra snapshot at a commit or a time, marked "requested" in the index (kept for later runs).
#   sh viewer/view.sh --check <snapshot file>
#     the data contract's check (viewer/DATA.md, `viewer-data 2`): every required field present and typed, every
#     id a part cites present in its part. Exit 0 when it holds; else one line per fault, exit 1.
# Milestones (3.3), found, never written: the PRD's Ratifications lines (each pause's commit); `stage name=init
# state=end`; the first `stage name=develop state=start`; `step-closed`; `slice-close`; `checkpoint`; the first
# `completion unmet=0 strict-gaps=0` or `run state=complete`; now (HEAD of the project's checkout, at the run's
# time). An event milestone's commit is the last commit on HEAD's first-parent history at or before its time.
# Milestones at the same commit and time share one snapshot.
# The view root (3.2): each snapshot is computed in a fresh, sealed temporary directory V — its own git repository
# borrowing the project's objects (objects/info/alternates), HEAD detached at C; the documents at C written from
# git; the events up to T (a line with no at= is kept), the receipts and the plans copied; a RUN-STATE written for
# T (`plan: required`, `run: active`, the plan block of the last plan-change at or before T); a copy of the
# plugin's checks/ (and the project's own results reader, checks/extractors/, at C). Only the plugin's evidence
# reader runs there: `sh checks/evidence.sh rows --at C --map <map> --until T`. Nothing in V links to the project.
# Incremental (3.5): a snapshot's data is cached by fingerprint in .cache/data/ — a past moment's by (C, T, the
# data version, the hash of view.sh and the plugin's checks/), now's by HEAD, the same code hash and the hash of
# every record file now's data reads; each entry carries the hash of its content and is recomputed when that
# fails. Documents are parsed once per git blob (.cache/blob/). Pages are reassembled from cached data, their
# neighbours and the page, and written only when they change; delegated marks are applied at assembly, from the
# full events file. Read only (R2): every git call runs with GIT_OPTIONAL_LOCKS=0, and nothing is written into
# the project. Counts, never percentages. Nothing pops up.
set -u
IFS='
'
umask 022
VIEWER=$(cd "$(dirname "$0")" && pwd -P); PLUG=$(cd "$VIEWER/.." && pwd -P)
GIT_OPTIONAL_LOCKS=0; export GIT_OPTIONAL_LOCKS
unset VID_EVIDENCE_HELD 2>/dev/null || true
unset $(git rev-parse --local-env-vars 2>/dev/null) 2>/dev/null || true
DATAV=2
PAGE="$VIEWER/page/ViD Viewer v3.dc.html"; RUNTIME="$VIEWER/page/support.js"
LIB="$VIEWER/vendor/react.production.min.js"; LIBDOM="$VIEWER/vendor/react-dom.production.min.js"
usage() { echo 'ViD view: usage — sh viewer/view.sh [<project>] [--out <dir>] [--at <commit|UTC time>] | --check <snapshot>' >&2; exit 2; }
die() { echo "ViD view: $*" >&2; exit 1; }
AWKAT='function lastat(  i) { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { if ($i ~ /^at=[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return substr($i, 4); return "" } return "" }
function kv(k,  i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
function qv(k,  p, s) { p = index($0, " " k "=\""); if (!p) return kv(k); s = substr($0, p + length(k) + 3); p = index(s, "\""); return p ? substr(s, 1, p - 1) : s }
function bkv(h,   i, s, j) { i = index($0, " brief="); if (!i) return ""; s = substr($0, i + 7); j = match(s, / [a-z][a-z-]*=/); if (j) s = substr(s, 1, j - 1); if (h != "" && index(s, h "/") == 1) s = substr(s, length(h) + 2); return s }'
# JSON: a string, escaped for a <script> element too (no </, <!-- or <script survives); backslashes doubled by
# concatenation, which every awk reads the same way
AWKJS='function js(s,   o, i) { o = ""; while ((i = index(s, "\\")) > 0) { o = o substr(s, 1, i) "\\"; s = substr(s, i + 1) } s = o s
  gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); gsub(/\r/, "", s); gsub(/\n/, "\\n", s); gsub(/[\001-\010\013\014\016-\037]/, "", s)
  gsub(/<\//, "<\\/", s); gsub(/<!--/, "\\u003c!--", s); gsub(/<[sS][cC][rR][iI][pP][tT]/, "\\u003cscript", s); return "\"" s "\"" }
function jn(s) { return (s == "" || s == "-") ? "null" : js(s) }
function ja(list, sep,   n, a, i, o, seen) { n = split(list, a, sep); o = ""; split("", seen); for (i = 1; i <= n; i++) if (a[i] != "" && !(a[i] in seen)) { seen[a[i]] = 1; o = o (o == "" ? "" : ",") js(a[i]) } return "[" o "]" }
function jb(x) { return x ? "true" : "false" }'
# v0.26.10.2 (R1–R7, R13–R16): the architecture part, from the snapshot's parsed documents, plan, paths and the main
# history (the body awk reads them into the arrays named in arch_read); \034 is a value not recorded (null)
AWKARCH='function anm(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
function anv(s) { return s == "\034" ? "null" : js(s) }
function asrc(p,   o, i) { sub(/^\.\//, "", p); o = ""; while ((i = index(p, "/src/")) > 0) { o = o substr(p, 1, i); p = substr(p, i + 5) } o = o p; sub(/\/src$/, "", o); return o }
# the import court s module_of: /src/ segments collapsed, the longest module path that is a prefix wins
function amod(p,   q, k, m, b) { q = asrc(p); b = ""; for (k = 1; k <= NMOD; k++) { m = MO[k]; if ((q == m || index(q, m "/") == 1) && length(m) > length(b)) b = m } return b }
function aadd(list, x) { return list (list == "" ? "" : "\036") x }
function aja(list,   n, a, i, o) { n = split(list, a, "\036"); o = ""; for (i = 1; i <= n; i++) o = o (i > 1 ? "," : "") js(a[i]); return "[" o "]" }
function arch_read(l,   f) { split(l, f, "\t")
  if (f[1] == "HAS") HAS[f[2]] = 1
  else if (f[1] == "MT") HASMT = 1
  else if (f[1] == "MC") MCOL[++NMC] = f[2]
  else if (f[1] == "MR") { if (!(f[2] in MI)) { MO[++NMOD] = f[2]; MI[f[2]] = NMOD } MRS[f[2]] = f[3]; MOW[f[2]] = f[4]; MSU[f[2]] = f[5]; MDE[f[2]] = f[6] }
  else if (f[1] == "SKT") HASSK = 1
  else if (f[1] == "SK") ASK[++NSK] = f[2] "\t" f[3] "\t" f[4]
  else if (f[1] == "T0T") HAST0 = 1
  else if (f[1] == "T0") AT0[++NT0] = f[2] "\t" f[3]
  else if (f[1] == "SV") ASV[++NSV] = l }
function amiss(part, why) { AMS = AMS (AMS == "" ? "" : ",") "{\"part\":" js(part) ",\"why\":" js(why) "}" }
# the facts the change log compares: AR <part> <key> <text>, then AF <part> <key> <field> <value> for each field
function afact(part, key, text, names, vals,   n, a, b, i) { print "AR\t" part "\t" key "\t" text > (S "/facts"); n = split(names, a, " "); split(vals, b, "\037")
  for (i = 1; i <= n; i++) print "AF\t" part "\t" key "\t" a[i] "\t" b[i] > (S "/facts") }
# a technical decision s enforced, added and stage (R13): dated only when C is on the main history and building has started by T
function atech(d,   q, ad, sg, l, f) { ad = "null"; sg = "null"
  if (!DADL) { DADL = 1; while ((getline l < hdec) > 0) { split(l, f, "\t"); DAD[f[1]] = f[2] "\t" f[3] } }
  if (ci != "" && ds != "" && (d in DAD)) { split(DAD[d], q, "\t"); ad = "{\"commit\":" js(substr(q[1], 1, 7)) ",\"time\":" js(q[2]) "}"; sg = (q[2] <= ds) ? "\"spec\"" : "\"build\"" }
  return ",\"enforced\":" jn(DEN[d]) ",\"added\":" ad ",\"stage\":" sg }
function arch_part(   l, f, i, j, k, m, n, w, a, x, y, q, d, it, ni, s, tok, pre, by, mt, o, lv, ch, MBU, OPEN, OTH, LV, MST, NK, PON, POS, POO, npo, LBL, MEN, MDC, MFL, SHN, SH, FPI, nfp, mo, d2) {
  while ((getline l < fpl) > 0) FPI[l] = ++nfp
  while ((getline l < harch) > 0) { split(l, f, "\t"); SHN[f[1]]++; SH[f[1], SHN[f[1]]] = l }
  # R1, R2: Dependents as the court reads them — split on commas and spaces, `all` anywhere opens it to every module
  for (i = 1; i <= NMOD; i++) { m = MO[i]; NK[anm(m)] = m; if (MDE[m] == "\034") continue; d2 = MDE[m]; gsub(/`/, "", d2); n = split(d2, a, /[ ,]+/)
    for (j = 1; j <= n; j++) { w = a[j]; if (w == "" || w == "none") continue; if (w == "all") { OPEN[m] = 1; continue }
      if (w in MI) { if (!((m, w) in MBU)) { MBU[m, w] = 1; MBL[m] = aadd(MBL[m], w) } } else if (!((m, "o:" w) in MBU)) { MBU[m, "o:" w] = 1; OTH[m] = aadd(OTH[m], w) } } }
  # R3: the shortest way down from the modules no other module may use; the open ones in their band
  for (i = 1; i <= NMOD; i++) { m = MO[i]; if (m in OPEN) continue; x = 0; for (k = 1; k <= NMOD; k++) if (MO[k] != m && ((m, MO[k]) in MBU)) x = 1; if (!x) LV[m] = 0 }
  for (lv = 0; ; lv++) { ch = 0; for (i = 1; i <= NMOD; i++) { m = MO[i]; if ((m in OPEN) || (m in LV)) continue
      for (k = 1; k <= NMOD; k++) { y = MO[k]; if (y != m && ((m, y) in MBU) && (y in LV) && LV[y] == lv) { LV[m] = lv + 1; ch = 1; break } } } if (!ch) break }
  # R4: the plan steps naming each module, joined as brief.sh archrows joins them; a name with no row is plan-only
  for (i = 1; i <= ns; i++) { s = SID[i]; n = split(SMOD[s], a, /[ ,\t]+/)
    for (j = 1; j <= n; j++) { w = a[j]; if (w == "" || w == "-") continue; k = anm(w); if (k == "") continue
      if (k in NK) { m = NK[k]; if (!((m, s) in MSTS)) { MSTS[m, s] = 1; MST[m] = aadd(MST[m], s) } }
      else { if (!(k in PON)) { PON[k] = w; POO[++npo] = k } if (!((k, s) in POSS)) { POSS[k, s] = 1; POS[k] = aadd(POS[k], s) } } } }
  # R13: what a label may name for a module — the rows, requirements and screen codes
  for (i = 1; i <= NMOD; i++) { m = MO[i]; n = split(MST[m], a, "\036")
    for (j = 1; j <= n; j++) { ni = split(SROWS[a[j]], it, " ")
      for (k = 1; k <= ni; k++) { x = it[k]; if (x == "") continue; LBL[m, x] = 1; q = split(PRQ[x], f, ","); for (y = 1; y <= q; y++) LBL[m, f[y]] = 1
        if (PSC[x] != "" && PSC[x] != "-") { w = PSC[x]; sub(/\/.*/, "", w); LBL[m, w] = 1 } } } }
  # R13: each technical decision at C, linked once, by the first way it links; scope: project is kept out
  for (i = 1; i <= nd; i++) { d = DID[i]; if (DSC[d] == "project") continue; split("", MEN)
    s = DW[d] " " DY[d]
    while (match(s, /[A-Za-z0-9_][A-Za-z0-9_.\/-]*/)) { tok = substr(s, RSTART, RLENGTH); pre = (RSTART > 1) ? substr(s, RSTART - 1, 1) : ""; s = substr(s, RSTART + RLENGTH)
      if (pre ~ /[.\/-]/) continue; sub(/[.\/-]+$/, "", tok); q = tok; gsub(/\./, "/", q); m = amod(q)
      if (m != "" && (q == m || index(q, m "/") == 1) && !(m in MEN)) MEN[m] = tok }
    ni = (DAP[d] == "") ? 0 : split(DAP[d], it, /[ ,]+/)
    for (j = 1; j <= NMOD; j++) { m = MO[j]; by = ""; mt = "null"
      for (k = 1; k <= ni && by == ""; k++) if (it[k] != "" && anm(it[k]) == anm(m)) by = "module-label"
      for (k = 1; k <= ni && by == ""; k++) if (it[k] != "" && ((m, it[k]) in LBL)) by = "label"
      if (by == "" && (m in MEN)) { by = "mentions"; mt = js(MEN[m]) }
      if (by != "") MDC[m] = MDC[m] (MDC[m] == "" ? "" : ",") "{\"id\":" js(d) ",\"by\":" js(by) ",\"match\":" mt "}" } }
  # R14: the paths at C the court gives to each module
  while ((getline l < (S "/files")) > 0) { m = amod(l); if (m != "") MFL[m] = aadd(MFL[m], l) }
  printf "%s", "\"architecture\":{\"modules\":["
  for (i = 1; i <= NMOD; i++) { m = MO[i]; o = ""
    for (k = 1; k <= NMOD; k++) { y = MO[k]; if (((y, m) in MBU) || ((y in OPEN) && y != m)) o = aadd(o, y) }
    # R16: the surface s history up to C, when C is on the main history
    if (ci == "") x = "null"; else { x = ""; for (k = 1; k <= SHN[m]; k++) { split(SH[m, k], f, "\t"); if (!(f[2] in FPI) || FPI[f[2]] < ci + 0) continue
        x = x (x == "" ? "" : ",") "{\"commit\":" js(substr(f[2], 1, 7)) ",\"time\":" js(f[3]) ",\"from\":" anv(f[4]) ",\"to\":" anv(f[5]) "}" } x = "[" x "]" }
    w = (m in OPEN) ? "open-to-all" : ((m in LV) ? "level" : "unplaced")
    printf "%s{\"id\":%s,\"responsibility\":%s,\"ownedData\":%s,\"surface\":%s,\"dependents\":%s,\"openToAll\":%s,\"mayBeUsedBy\":%s,\"otherNames\":%s,\"mayUse\":%s,\"steps\":%s,\"placement\":%s,\"level\":%s,\"decisions\":[%s],\"files\":%s,\"surfaceHistory\":%s}\n", (i > 1 ? "," : ""), js(m), anv(MRS[m]), anv(MOW[m]), anv(MSU[m]), anv(MDE[m]), jb(m in OPEN), aja(MBL[m]), aja(OTH[m]), aja(o), aja(MST[m]), js(w), ((m in LV) ? LV[m] : "null"), MDC[m], aja(MFL[m]), x
    afact("module", m, m, "responsibility ownedData surface dependents", MRS[m] "\037" MOW[m] "\037" MSU[m] "\037" MDE[m]) }
  printf "%s", "],\"planOnly\":["
  for (i = 1; i <= npo; i++) { k = POO[i]; printf "%s{\"name\":%s,\"steps\":%s}", (i > 1 ? "," : ""), js(PON[k]), aja(POS[k]) }
  printf "%s", "],\"services\":["
  for (i = 1; i <= NSV; i++) { split(ASV[i], f, "\t")
    printf "%s{\"id\":%s,\"service\":%s,\"purpose\":%s,\"chosen\":%s,\"credentials\":%s,\"probe\":%s,\"evidence\":%s,\"quirks\":%s,\"module\":%s}\n", (i > 1 ? "," : ""), js(f[2]), js(f[3]), js(f[4]), anv(f[5]), anv(f[6]), anv(f[7]), anv(f[8]), anv(f[9]), anv(f[10])
    afact("service", f[2], f[3], "service purpose chosen credentials probe evidence quirks module", f[3] "\037" f[4] "\037" f[5] "\037" f[6] "\037" f[7] "\037" f[8] "\037" f[9] "\037" f[10]) }
  printf "%s", "],\"stack\":["
  for (i = 1; i <= NSK; i++) { split(ASK[i], f, "\t"); printf "%s{\"layer\":%s,\"choice\":%s,\"ruledOut\":%s}\n", (i > 1 ? "," : ""), anv(f[1]), anv(f[2]), anv(f[3])
    afact("stack", f[1], f[1], "choice ruledOut", f[2] "\037" f[3]) }
  printf "%s", "],\"mustNeverBreak\":["
  for (i = 1; i <= NT0; i++) { split(AT0[i], f, "\t"); printf "%s{\"rule\":%s,\"meaning\":%s}\n", (i > 1 ? "," : ""), anv(f[1]), anv(f[2]) }
  # R7: missing is shown as missing
  if (!("arch" in HAS)) amiss("modules", "There is no ARCHITECTURE.md at this commit.")
  else if (!HASMT) amiss("modules", "ARCHITECTURE.md has no module table (a table with a Module column) at this commit.")
  for (i = 1; i <= NMC; i++) amiss("modules", "The module table has no " MCOL[i] " column.")
  if (!("seam" in HAS)) amiss("services", "There is no INVENTORY.md at this commit.")
  else if (!NSV) amiss("services", "INVENTORY.md has no seam rows at this commit.")
  if (!("base" in HAS)) { amiss("stack", "There is no BASELINE.md at this commit."); amiss("mustNeverBreak", "There is no BASELINE.md at this commit.") }
  else { if (!HASSK) amiss("stack", "BASELINE.md has no table under its Stack heading at this commit."); if (!HAST0) amiss("mustNeverBreak", "BASELINE.md has no table under its Tier-0 rows heading at this commit.") }
  printf "],\"missing\":[%s]},\n", AMS }'
utc_of() { TZ=UTC0 git -C "$P" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd "$1" 2>/dev/null; }
hashof() { git hash-object --stdin; }

# --- --check: the data contract (R7) -------------------------------------------------------------------------
# A small JSON reader: each value's path and type, every string's value; then the contract's required fields and
# the cross-part id joins (viewer/DATA.md).
check_page() {
  [ -f "$1" ] || die "no snapshot at $1"
  CW=$(mktemp -d) || exit 1
  awk '/^<script>window\.VID_DATA=/ { on = 1; sub(/^<script>window\.VID_DATA=/, "") } on && /;<\/script>$/ { sub(/;<\/script>$/, ""); print; exit } on { print }' "$1" > "$CW/j"
  [ -s "$CW/j" ] || { echo "ViD view check: $1 carries no window.VID_DATA"; rm -rf "$CW"; return 1; }
  # v0.9.8.1 (R23): a <script src> names only a canvas asset, canvases/<key>.js, present beside the snapshot
  _cd=$(dirname "$1")
  for _s in $(grep -oE '<script[^>]*[[:space:]]src="[^"]*"' "$1" | sed -E 's/.*src="([^"]*)"/\1/'); do
    case "$_s" in canvases/*.js) [ -f "$_cd/$_s" ] || { echo "ViD view check: $1 loads $_s, which is not beside it"; rm -rf "$CW"; return 1; } ;;
      *) echo "ViD view check: $1 loads $_s — a snapshot loads only its canvas assets, canvases/<key>.js"; rm -rf "$CW"; return 1 ;; esac
  done
  # read as a stream, a line at a time (no JSON string spans a line)
  LC_ALL=C awk -v F="$CW/j" '
    function err(m) { print "PARSE\t" m; exit 1 }
    function more(   l) { if ((getline l < F) <= 0) { eof = 1; return 0 } s = l "\n"; n = length(s); p = 1; return 1 }
    function ch() { while (p > n) if (eof || !more()) return ""; return substr(s, p, 1) }
    function ws(   c) { while (1) { c = ch(); if (c == "" || c !~ /[ \t\r\n]/) return; p++ } }
    function str(   o, c, q, r) { o = ""; p++; while (1) { if (ch() == "") err("an unterminated string"); r = substr(s, p)
        if (match(r, /["\\]/)) { o = o substr(r, 1, RSTART - 1); p += RSTART - 1 } else err("an unterminated string")
        c = substr(s, p, 1); if (c == "\"") { p++; return o }
        q = substr(s, p + 1, 1); if (q == "u") { o = o "?"; p += 6; continue } o = o ((q == "n" || q == "t") ? " " : q); p += 2 } }
    function val(path,   c, k, i, v) { ws(); c = ch()
      if (c == "{") { print "T\t" path "\tobject"; p++; ws(); if (ch() == "}") { p++; return }
        while (1) { ws(); if (ch() != "\"") err("a key expected at " path); k = str(); ws(); if (ch() != ":") err("a colon expected at " path "." k); p++
          val(path "." k); ws(); c = ch(); p++; if (c == "}") return; if (c != ",") err("a comma expected in " path) } }
      if (c == "[") { print "T\t" path "\tarray"; p++; ws(); i = 0; if (ch() == "]") { p++; return }
        while (1) { val(path "[" i "]"); i++; ws(); c = ch(); p++; if (c == "]") return; if (c != ",") err("a comma expected in " path) } }
      if (c == "\"") { v = str(); print "T\t" path "\tstring"; print "V\t" path "\t" v; return }
      if (substr(s, p, 4) == "true") { print "T\t" path "\tboolean"; p += 4; return }
      if (substr(s, p, 5) == "false") { print "T\t" path "\tboolean"; p += 5; return }
      if (substr(s, p, 4) == "null") { print "T\t" path "\tnull"; p += 4; return }
      if (c ~ /[-0-9]/) { v = ""; while (ch() ~ /[-+0-9.eE]/ && ch() != "") { v = v substr(s, p, 1); p++ } print "T\t" path "\tnumber"; print "V\t" path "\t" v; return }
      err("an unexpected character at " path) }
    BEGIN { n = 0; p = 1; val(""); ws(); if (ch() != "") err("text after the object") }' > "$CW/t" || { grep '^PARSE' "$CW/t" | sed 's/^PARSE	/ViD view check: not JSON — /'; rm -rf "$CW"; return 1; }
  awk -F'\t' '
    BEGIN {
      # required fields: <path pattern> <type[|type]>; [] stands for every element
      n = split(".viewer-data number|.meta object|.meta.project string|.meta.moment object|.meta.moment.commit string|.meta.moment.time string|.meta.milestones array|.meta.madeAt string|.meta.vid string|.meta.records number,null|.meta.evidenceRule string|.meta.replayed boolean|.meta.requested boolean|.meta.mode string|.meta.fingerprint string|.meta.previous object,null|.meta.next object,null|.meta.snapshots array|.meta.snapshots[].label string|.meta.snapshots[].moment object|.meta.snapshots[].milestones array|.meta.snapshots[].file string|.meta.snapshots[].replayed boolean|.meta.snapshots[].requested boolean|.meta.nowOnly boolean|.meta.notRecorded array|.goals array|.goals[].id string|.goals[].name string|.goals[].text string|.capabilities array|.capabilities[].id string|.capabilities[].goal string,null|.capabilities[].name string|.users array|.users[].name string|.journeys array|.journeys[].promise string|.journeys[].text string|.requirements array|.requirements[].id string|.requirements[].type string|.requirements[].tier string|.requirements[].plain string|.requirements[].statement string|.requirements[].failsIf string,null|.requirements[].capability string,null|.requirements[].phase string|.nonGoals array|.nonGoals[].id string|.nonGoals[].plain string|.screens array|.screens[].screen string|.screens[].state string|.screens[].requirements array|.screens[].canvas string,null|.promises array|.promises[].id string|.promises[].kind string|.promises[].text string|.promises[].requirements array|.promises[].capabilities array|.promises[].screenState string,null|.promises[].test string|.promises[].step string,null|.promises[].state string|.promises[].stateDetail string|.promises[].resultFile string,null|.promises[].resultCommit string,null|.promises[].built boolean|.promises[].judgments array|.promises[].judgments[].at string|.promises[].judgments[].result string|.promises[].judgments[].class string|.promises[].judgments[].prose string,null|.steps array|.steps[].id string|.steps[].name string|.steps[].kind string|.steps[].buildsOn array|.steps[].promises array|.steps[].started string,null|.steps[].closed string,null|.decisions object|.decisions.answers array|.decisions.answers[].id string|.decisions.answers[].tier string|.decisions.answers[].date string|.decisions.answers[].q string|.decisions.answers[].a string|.decisions.answers[].settles array|.decisions.answers[].delegated boolean|.decisions.answers[].amended boolean|.decisions.technical array|.decisions.technical[].id string|.decisions.technical[].what string|.decisions.technical[].why string|.decisions.technical[].enforced string,null|.decisions.technical[].added object,null|.decisions.technical[].added.commit string|.decisions.technical[].added.time string|.decisions.technical[].stage string,null|.architecture object|.architecture.modules array|.architecture.modules[].id string|.architecture.modules[].responsibility string,null|.architecture.modules[].ownedData string,null|.architecture.modules[].surface string,null|.architecture.modules[].dependents string,null|.architecture.modules[].openToAll boolean|.architecture.modules[].mayBeUsedBy array|.architecture.modules[].otherNames array|.architecture.modules[].mayUse array|.architecture.modules[].steps array|.architecture.modules[].files array|.architecture.modules[].placement string|.architecture.modules[].level number,null|.architecture.modules[].decisions array|.architecture.modules[].decisions[].id string|.architecture.modules[].decisions[].by string|.architecture.modules[].decisions[].match string,null|.architecture.modules[].surfaceHistory array,null|.architecture.modules[].surfaceHistory[].commit string|.architecture.modules[].surfaceHistory[].time string|.architecture.modules[].surfaceHistory[].from string,null|.architecture.modules[].surfaceHistory[].to string,null|.architecture.planOnly array|.architecture.planOnly[].name string|.architecture.planOnly[].steps array|.architecture.services array|.architecture.services[].id string|.architecture.services[].service string|.architecture.services[].purpose string|.architecture.services[].chosen string,null|.architecture.services[].credentials string,null|.architecture.services[].probe string,null|.architecture.services[].evidence string,null|.architecture.services[].quirks string,null|.architecture.services[].module string,null|.architecture.stack array|.architecture.stack[].layer string,null|.architecture.stack[].choice string,null|.architecture.stack[].ruledOut string,null|.architecture.mustNeverBreak array|.architecture.mustNeverBreak[].rule string,null|.architecture.mustNeverBreak[].meaning string,null|.architecture.missing array|.architecture.missing[].part string|.architecture.missing[].why string|.needsYou object|.needsYou.questions array|.needsYou.held array|.needsYou.delegated array|.needsYou.answered array|.activity object|.activity.agentsOpen array|.activity.recentCommits array|.activity.planChanges array|.counts object|.counts.promises number|.counts.built number|.counts.tested number|.counts.reviewed number|.counts.reviewedKept number|.counts.reviewedBroken number|.counts.byState object|.counts.steps object|.changes array|.changes[].kind string|.changes[].ids array|.changes[].capabilities array|.changes[].window string", R, "|")
      for (i = 1; i <= n; i++) { split(R[i], a, " "); RP[i] = a[1]; RT[i] = a[2] } nr = n }
    $1 == "T" { k = $2; gsub(/\[[0-9]+\]/, "[]", k); TY[k] = TY[k] "," $3; HAS[k] = 1; if (k ~ /\[\]$/) { el[k]++; ELEM[$2] = k } FLD[$2] = 1; PT[$2] = $3; if ($3 == "object") OBJ[k] = 1; next }
    $1 == "V" { VAL[$2] = $3; next }
    END {
      for (i = 1; i <= nr; i++) { pth = RP[i]; m = split(RT[i], ok, ","); p0 = pth
        # an element field is required only when its array has elements
        par = pth; if (index(par, "[]")) { sub(/\[\][^[]*$/, "[]", par); if (!(par in el)) continue }
        # v0.26.10.2: a field of an object that may be null is required only where the object is there
        up = pth; sub(/\.[^.[]*$/, "", up); if (up != pth && up != "" && (up in HAS) && !(up in OBJ)) continue
        if (!(pth in HAS)) { print "ViD view check: " pth " is missing"; bad++; continue }
        nt = split(substr(TY[pth], 2), got, ","); for (j = 1; j <= nt; j++) { f = 0; for (q = 1; q <= m; q++) if (got[j] == ok[q]) f = 1; if (!f) { print "ViD view check: " pth " is " got[j] ", not " RT[i]; bad++; break } } }
      # every element of an array carries the fields required of its elements
      for (e in ELEM) { k = ELEM[e]; for (i = 1; i <= nr; i++) { if (index(RP[i], k ".") != 1) continue; rest = substr(RP[i], length(k) + 1); if (index(rest, "[]")) continue
          up = rest; sub(/\.[^.]*$/, "", up); if (up != "" && PT[e up] != "object") continue
          if (!((e rest) in FLD)) { print "ViD view check: " e rest " is missing"; bad++ } } }
      # the joins: ids a part cites exist in their part
      for (pth in VAL) {
        if (pth ~ /^\.requirements\[[0-9]+\]\.id$/) REQ[VAL[pth]] = 1
        else if (pth ~ /^\.capabilities\[[0-9]+\]\.id$/) CAP[VAL[pth]] = 1
        else if (pth ~ /^\.goals\[[0-9]+\]\.id$/) GO[VAL[pth]] = 1
        else if (pth ~ /^\.promises\[[0-9]+\]\.id$/) PRO[VAL[pth]] = 1
        else if (pth ~ /^\.steps\[[0-9]+\]\.id$/) STP[VAL[pth]] = 1
        else if (pth ~ /^\.decisions\.answers\[[0-9]+\]\.id$/) ANS[VAL[pth]] = 1
        else if (pth ~ /^\.decisions\.technical\[[0-9]+\]\.id$/) TEC[VAL[pth]] = 1
        else if (pth ~ /^\.architecture\.modules\[[0-9]+\]\.id$/) MOD[VAL[pth]] = 1 }
      for (pth in VAL) { v = VAL[pth]; w = ""
        if (pth ~ /^\.promises\[[0-9]+\]\.requirements\[[0-9]+\]$/ && !(v in REQ)) w = "requirement"
        else if (pth ~ /^\.promises\[[0-9]+\]\.capabilities\[[0-9]+\]$/ && !(v in CAP)) w = "capability"
        else if (pth ~ /^\.promises\[[0-9]+\]\.step$/ && !(v in STP)) w = "step"
        else if (pth ~ /^\.requirements\[[0-9]+\]\.capability$/ && !(v in CAP)) w = "capability"
        else if (pth ~ /^\.capabilities\[[0-9]+\]\.goal$/ && !(v in GO)) w = "goal"
        else if (pth ~ /^\.steps\[[0-9]+\]\.promises\[[0-9]+\]$/ && !(v in PRO)) w = "promise"
        else if (pth ~ /^\.steps\[[0-9]+\]\.buildsOn\[[0-9]+\]$/ && !(v in STP)) w = "step"
        else if (pth ~ /^\.journeys\[[0-9]+\]\.promise$/ && !(v in PRO)) w = "promise"
        else if (pth ~ /^\.screens\[[0-9]+\]\.requirements\[[0-9]+\]$/ && !(v in REQ)) w = "requirement"
        else if (pth ~ /^\.needsYou\.held\[[0-9]+\]$/ && !(v in PRO)) w = "promise"
        else if (pth ~ /^\.needsYou\.delegated\[[0-9]+\]$/ && !(v in ANS)) w = "answer"
        else if (pth ~ /^\.needsYou\.answered\[[0-9]+\]$/ && !(v in ANS)) w = "answer"
        else if (pth ~ /^\.architecture\.modules\[[0-9]+\]\.(mayUse|mayBeUsedBy)\[[0-9]+\]$/ && !(v in MOD)) w = "module"
        else if (pth ~ /^\.architecture\.(modules|planOnly)\[[0-9]+\]\.steps\[[0-9]+\]$/ && !(v in STP)) w = "step"
        else if (pth ~ /^\.architecture\.modules\[[0-9]+\]\.decisions\[[0-9]+\]\.id$/ && !(v in TEC)) w = "technical decision"
        if (w != "") { print "ViD view check: " pth " cites " v ", which is no " w " of this snapshot"; bad++ } }
      exit bad ? 1 : 0 }' "$CW/t"
  _rc=$?; rm -rf "$CW"; return $_rc
}

# --- arguments ---------------------------------------------------------------------------------------------
PROJ=''; OUT=''; AT=''; CHECK=''
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || usage; OUT=$2; shift 2 ;;
    --at) [ $# -ge 2 ] || usage; AT=$2; shift 2 ;;
    --check) [ $# -ge 2 ] || usage; CHECK=$2; shift 2 ;;
    -*) usage ;;
    *) [ -z "$PROJ" ] || usage; PROJ=$1; shift ;;
  esac
done
if [ -n "$CHECK" ]; then check_page "$CHECK"; exit $?; fi
P=$(cd "${PROJ:-.}" 2>/dev/null && pwd -P) || die "no project at ${PROJ:-.}"
[ -f "$P/PRD.md" ] || die "$P holds no PRD.md — a ViD project's folder is named, or the current one."
HEAD=$(git -C "$P" rev-parse -q --verify 'HEAD^{commit}' 2>/dev/null) || die "$P is no git repository with a commit."
CD=$(git -C "$P" rev-parse --git-common-dir); case "$CD" in /*) ;; *) CD="$P/$CD" ;; esac; CD=$(cd "$CD" && pwd -P)
NAME=$(basename "$P")
TITLE=$(git -C "$P" show HEAD:PRD.md 2>/dev/null | sed -n '1s/^# //p' | sed 's/[[:space:]]*—[[:space:]]*PRD[[:space:]]*$//'); TITLE=${TITLE:-$NAME}
[ -n "$OUT" ] || OUT="$HOME/ViD Viewer/$NAME"
case "$OUT" in /*) ;; *) OUT="$(pwd -P)/$OUT" ;; esac
# the folder as it will resolve: its nearest existing ancestor, physically, then the rest
_o=$OUT; _rest=''; while [ ! -d "$_o" ]; do _rest="/${_o##*/}$_rest"; _o=$(dirname "$_o"); done
_or="$(cd "$_o" && pwd -P)$_rest"
case "$_or/" in "$P/"*|"$CD/"*) die "--out $OUT is inside the project; the viewer writes nothing there." ;; esac
for f in "$PAGE" "$RUNTIME" "$LIB" "$LIBDOM"; do [ -f "$f" ] || die "the plugin's viewer is incomplete: $f is missing."; done
mkdir -p "$OUT/.cache/data" "$OUT/.cache/blob" "$OUT/.cache/pages" || die "cannot write $OUT"
OUT=$(cd "$OUT" && pwd -P)
W=$(mktemp -d) || exit 1
trap 'rm -rf "$W"' EXIT
trap 'rm -rf "$W"; exit 130' INT TERM
EVF="$P/.vid/metrics-events"; [ -f "$EVF" ] || EVF=/dev/null
STARTED=$(date +%s)
VIDV=$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUG/.claude-plugin/plugin.json" 2>/dev/null | head -n 1); VIDV=${VIDV:-unknown}
RECV=$(git -C "$P" show HEAD:checks/records-version 2>/dev/null | sed -n 's/^records:[[:space:]]*//p' | head -n 1)
case "$RECV" in ''|*[!0-9]*) RECV='' ;; esac
CODEH=$( { cat "$VIEWER/view.sh"; find "$PLUG/checks" -type f ! -path '*/selftest/*' | LC_ALL=C sort | while IFS= read -r f; do printf '%s\n' "$f" | sed "s#^$PLUG/##"; cat "$f"; done; } | hashof)
NOWT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# --- milestones (R5) ---------------------------------------------------------------------------------------
# ms: `<T>\t<kind>\t<label>` — the PRD's ratifications at HEAD, then the events'
git -C "$P" show HEAD:PRD.md 2>/dev/null | awk '/^## Ratifications/ { on = 1; next } on && /^## / { exit }
  on && /^- / { n = split($0, f, / — /); if (n >= 3) { sha = f[n]; gsub(/[ \t`]/, "", sha); sc = f[2]; for (i = 3; i < n; i++) sc = sc " — " f[i]; print sha "\t" sc } }' > "$W/rats"
: > "$W/ms"
while IFS='	' read -r _sha _sc; do
  _c=$(git -C "$P" rev-parse -q --verify "$_sha^{commit}" 2>/dev/null) || continue
  printf '%s\tprd-ratified\tPRD ratified (%s)\t%s\n' "$(utc_of "$_c")" "$_sc" "$_c" >> "$W/ms"
done < "$W/rats"
awk "$AWKAT"' { t = lastat(); if (t == "") next }
  $1 == "stage" && kv("name") == "init" && kv("state") == "end" && !ie { ie = 1; print t "\tsetup-done\tSetup done" }
  $1 == "stage" && kv("name") == "develop" && kv("state") == "start" && !ds { ds = 1; print t "\tbuilding-started\tBuilding started" }
  $1 == "step-closed" && kv("step") != "" { print t "\tstep-closed\t" kv("step") }
  $1 == "slice-close" { print t "\tslice-closed\tSlice " kv("slice") " closed" }
  $1 == "checkpoint" && kv("n") != "" { print t "\tcheckpoint\tCheckpoint " kv("n") }
  (($1 == "completion" && kv("unmet") == "0" && kv("strict-gaps") == "0") || ($1 == "run" && kv("state") == "complete")) && !re { re = 1; print t "\trun-ended\tRun ended" }' "$EVF" >> "$W/ms"
# the requested moments, kept across runs
[ -f "$OUT/.cache/requested" ] || : > "$OUT/.cache/requested"
if [ -n "$AT" ]; then
  if _c=$(git -C "$P" rev-parse -q --verify "$AT^{commit}" 2>/dev/null); then _t=$(utc_of "$_c")
  else case "$AT" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) _t=$AT ;; *) die "--at $AT is neither a commit nor a UTC time (YYYY-MM-DDTHH:MM:SSZ)." ;; esac; _c=''; fi
  grep -qx "$_t	$_c" "$OUT/.cache/requested" || printf '%s\t%s\n' "$_t" "$_c" >> "$OUT/.cache/requested"
fi
while IFS='	' read -r _t _c; do [ -n "$_t" ] && printf '%s\trequested\tRequested\t%s\n' "$_t" "$_c" >> "$W/ms"; done < "$OUT/.cache/requested"
# each milestone's commit: its own (a ratification, a requested commit), else HEAD's first-parent at or before T
: > "$W/msc"
while IFS='	' read -r _t _k _l _c; do
  [ -n "$_c" ] || _c=$(git -C "$P" rev-list --first-parent -1 --before="$_t" HEAD 2>/dev/null)
  [ -n "$_c" ] || continue
  [ "$_t" \> "$NOWT" ] && continue
  printf '%s\t%s\t%s\t%s\n' "$_t" "$_c" "$_k" "$_l" >> "$W/msc"
done < "$W/ms"
# snaps: one per distinct (T, C), oldest first — `<T>\t<C>\t<kinds>\t<label>\t<file>\t<requested>`; now last
LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2 "$W/msc" | awk -F'\t' '
  function flush(   lab, i, nst) { if (key == "") return; lab = ""; nst = split(ST, sa, " ")
    for (i = 1; i <= nk; i++) { if (K[i] == "step-closed") { if (done_s) continue; done_s = 1; l = (nst > 1 ? "Steps " : "") ST_L " closed" } else l = L[i]
      lab = lab (lab == "" ? "" : " · ") l }
    f = t; gsub(/[-:]/, "", f); print t "\t" c "\t" KS "\t" lab "\t" f "-" K[1] ".html\t" (req ? 1 : 0) }
  { k = $1 SUBSEP $2; if (k != key) { flush(); key = k; t = $1; c = $2; nk = 0; KS = ""; ST = ""; ST_L = ""; done_s = 0; req = 0; split("", HK) }
    if ($3 == "requested") req = 1
    if ($3 == "step-closed") { if (!(("s" $4) in HK)) { HK["s" $4] = 1; ST = ST " " $4; ST_L = ST_L (ST_L == "" ? "" : ", ") $4 } if (("k" $3) in HK) next }
    if ((("k" $3 "\001" $4) in HK)) next; HK["k" $3 "\001" $4] = 1; HK["k" $3] = 1
    K[++nk] = $3; L[nk] = $4; KS = KS (KS == "" ? "" : ",") $3 }
  END { flush() }' > "$W/snaps"
printf '%s\t%s\tnow\tNow\tnow.html\t0\n' "$NOWT" "$HEAD" >> "$W/snaps"
NSNAP=$(grep -c . "$W/snaps")

# --- fingerprints and the cache (R6) -------------------------------------------------------------------------
# now's records: every file now's data reads
RECH=$( { cat "$EVF"; cat "$P/.vid/RUN-STATE.md" 2>/dev/null; ls -1 "$P/.vid/ledger-results" 2>/dev/null; ls -1 "$P/.vid/plans" 2>/dev/null
  find "$P/.vid/verdicts" -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do printf '%s\n' "${f##*/}"; cat "$f"; done
  find "$P/.vid/briefs" -name '*.return.md' -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do printf '%s\n' "${f#$P/}"; cat "$f"; done
  find "$P/.vid/jobs" -maxdepth 1 -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do printf '%s\n' "${f##*/}"; cat "$f"; done; } | hashof)
awk -F'\t' -v d="$DATAV" -v code="$CODEH" -v rech="$RECH" '{ if ($3 == "now") print "now\t" d "\t" $2 "\t" code "\t" rech; else print "past\t" d "\t" $2 "\t" $1 "\t" code }' "$W/snaps" | while IFS= read -r l; do printf '%s' "$l" | hashof; done > "$W/fps"
paste "$W/snaps" "$W/fps" > "$W/snapfp"
# a damaged or malformed entry is deleted and recomputed, and the run says so
valid() { _b="$OUT/.cache/data/$1"; [ -f "$_b.sum" ] && [ -f "$_b.json" ] && [ -f "$_b.facts" ] && [ -f "$_b.meta" ] && [ -f "$_b.canvases" ] || return 1
  [ "$(cat "$_b.json" "$_b.facts" "$_b.meta" "$_b.canvases" | hashof)" = "$(cat "$_b.sum")" ]; }
for f in $(ls -1 "$OUT/.cache/data" 2>/dev/null); do
  k=${f%%.*}; case "$k" in *[!0-9a-f]*|'') rm -f "$OUT/.cache/data/$f"; echo "ViD view: a cache entry with a malformed key ($f) deleted"; continue ;; esac
  [ ${#k} -eq 40 ] || { rm -f "$OUT/.cache/data/$f"; echo "ViD view: a cache entry with a malformed key ($f) deleted"; }
done
: > "$W/todo"
while IFS='	' read -r _t _c _k _l _f _r _fp; do
  if valid "$_fp"; then continue; fi
  if ls "$OUT/.cache/data/$_fp".* >/dev/null 2>&1; then rm -f "$OUT/.cache/data/$_fp".*; echo "ViD view: the cached data of $_f failed its hash — deleted, recomputed"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_t" "$_c" "$_k" "$_l" "$_f" "$_r" "$_fp" >> "$W/todo"
done < "$W/snapfp"
NTODO=$(grep -c . "$W/todo" || true)
if [ "$NTODO" -gt 0 ]; then
  PACE=$(cat "$OUT/.cache/pace" 2>/dev/null | head -n 1); case "$PACE" in ''|*[!0-9]*) PACE='' ;; esac
  if [ -n "$PACE" ]; then echo "ViD view: $NTODO snapshot(s) to compute for $NAME — estimate about $((NTODO * PACE)) s, from the previous run's $PACE s per snapshot (an estimate)"
  else echo "ViD view: $NTODO snapshot(s) to compute for $NAME — no estimate yet (no previous run)"; fi
fi

# --- parsing documents, once per blob ------------------------------------------------------------------------
# blob <C> <path> → the blob's hash, or nothing
blob() { git -C "$P" rev-parse -q --verify "$1:$2" 2>/dev/null; }
# parse <kind> <blob> → .cache/blob/<blob>.<kind> (TSV), written once
parse() {
  _o="$OUT/.cache/blob/$2.$1"; [ -f "$_o" ] && return 0
  git -C "$P" cat-file blob "$2" > "$W/doc" 2>/dev/null || return 1
  case "$1" in
    prd) awk -F'|' '
      function tr(s) { gsub(/\t/, " ", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function lab(s, l) { s = tr(s); return index(s, l) == 1 ? tr(substr(s, length(l) + 1)) : "\001" }
      NR == 1 && /^# / { t = $0; sub(/^# /, "", t); sub(/[ \t]+—[ \t]+PRD[ \t]*$/, "", t); print "TITLE\t" tr(t) }
      /^grammar:/ { g = $0; sub(/^grammar:[ \t]*/, "", g); leg = 0 }
      /^```vid-prd-features$/ { b = "F"; next } /^```vid-prd$/ { b = "I"; next } /^```vid-prd-answers$/ { b = "A"; next } /^```/ { b = ""; next }
      /^## / { sec = $0; sub2 = "" } /^### / { sub2 = $0 }
      b == "" && sub2 ~ /^### MVP focus/ && /^- G[0-9]+:/ { l = $0; sub(/^- /, "", l); id = l; sub(/:.*/, "", id); r = l; sub(/^[^:]*:[ \t]*/, "", r); nm = r; tx = ""
        p = index(r, " — "); if (p) { nm = substr(r, 1, p - 1); tx = substr(r, p + 5) } print "G\t" id "\t" tr(nm) "\t" tr(tx); next }
      b == "" && sub2 ~ /^### Primary users/ && /^- \*\*[^*]+\*\*/ { u = $0; sub(/^- \*\*/, "", u); sub(/\*\*.*/, "", u); print "U\t" tr(u); nu++; next }
      b == "" && sec ~ /^## Actors and journeys/ && /^### / { a = $0; sub(/^### /, "", a); AC[++na] = tr(a); next }
      b == "" && sec ~ /^## Ratifications/ && /^- / { n = split($0, f, / — /); if (n >= 3) { s = f[n]; gsub(/[ \t`]/, "", s); d = f[1]; sub(/^- /, "", d); print "RAT\t" tr(d) "\t" tr(f[2]) "\t" s } next }
      b != "" && (/^[ \t]*#/ || /^[ \t]*$/) { next }
      b == "F" { id = tr($1); sub(/[ \t]+AMENDED$/, "", id); if (id !~ /^FEAT-/) next; if (!(id in FEA)) FO[++nf] = id; FEA[id] = "F\t" id "\t" tr($2) "\t" tr($3); next }
      b == "I" { id = tr($1); am = (id ~ /AMENDED$/); sub(/[ \t]+AMENDED$/, "", id); if (id == "") next
        ty = tr($2); ti = tr($3); np = (g == "" ? 5 : 4); st = tr($np); fi_ = ""; ph = "pilot"; fe = ""; pl = ""
        for (i = np + 1; i <= NF; i++) { v = lab($i, "fail-if:"); if (v != "\001") fi_ = v; v = lab($i, "phase:"); if (v != "\001") ph = v; v = lab($i, "feature:"); if (v != "\001") fe = v; v = lab($i, "plain:"); if (v != "\001") pl = v }
        if (!(id in IS)) IO[++ni] = id
        if (ty == "non_goal") IS[id] = "N\t" id "\t" (pl != "" ? pl : st)
        else IS[id] = "R\t" id "\t" ty "\t" ti "\t" (pl != "" ? pl : st) "\t" st "\t" fi_ "\t" fe "\t" ph
        next }
      b == "A" { id = tr($1); am = (id ~ /AMENDED$/); sub(/[ \t]+AMENDED$/, "", id); if (id !~ /^A-/) next
        q = ""; an = ""; se = ""; for (i = 4; i <= NF; i++) { v = lab($i, "Q:"); if (v != "\001") q = v; v = lab($i, "A:"); if (v != "\001") an = v; v = lab($i, "settles:"); if (v != "\001") se = v }
        gsub(/[ \t]*,[ \t]*/, ",", se)
        if (!(id in AS)) AO[++nan] = id; else AM[id] = 1
        AS[id] = "A\t" id "\t" tr($2) "\t" tr($3) "\t" q "\t" an "\t" se; next }
      END { for (i = 1; i <= nf; i++) print FEA[FO[i]]; for (i = 1; i <= ni; i++) print IS[IO[i]]
        for (i = 1; i <= nan; i++) print AS[AO[i]] "\t" ((AO[i] in AM) ? 1 : 0)
        if (!nu) for (i = 1; i <= na; i++) print "U\t" AC[i] }' "$W/doc" > "$_o.tmp" ;;
    inv) sed -n '/^```vid-inventory/,/^```$/p' "$W/doc" | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ {
        for (i = 1; i <= NF; i++) { gsub(/\t/, " ", $i); gsub(/^[ \t]+|[ \t]+$/, "", $i) }
        print "P\t" $1 "\t" $2 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 }' > "$_o.tmp" ;;
    dec) awk '/^- \*\*D-[0-9]+\*\*/ { l = $0; gsub(/\t/, " ", l); id = l; sub(/^- \*\*/, "", id); sub(/\*\*.*/, "", id); r = l; sub(/^- \*\*[^*]*\*\*[ \t]*/, "", r)
        n = split(r, f, / \| /); what = f[1]; why = ""; ap = ""; sc = ""
        for (i = 2; i <= n; i++) { if (f[i] ~ /^why:/) { why = f[i]; sub(/^why:[ \t]*/, "", why) } else if (f[i] ~ /^applies-to:/) { ap = f[i]; sub(/^applies-to:[ \t]*/, "", ap) } else if (f[i] ~ /^scope:/) { sc = f[i]; sub(/^scope:[ \t]*/, "", sc) } }
        if (!(id in S)) O[++no] = id; S[id] = "D\t" id "\t" what "\t" why "\t" ap "\t" sc }
        END { for (i = 1; i <= no; i++) print S[O[i]] }' "$W/doc" > "$_o.tmp" ;;
    # v0.26.10.2 (R13): the decisions again, with enforced: — a kind of its own, so an older cache can't supply them
    dec2) awk '/^- \*\*D-[0-9]+\*\*/ { l = $0; gsub(/\t/, " ", l); id = l; sub(/^- \*\*/, "", id); sub(/\*\*.*/, "", id); r = l; sub(/^- \*\*[^*]*\*\*[ \t]*/, "", r)
        n = split(r, f, / \| /); what = f[1]; why = ""; ap = ""; sc = ""; en = ""
        for (i = 2; i <= n; i++) { if (f[i] ~ /^why:/) { why = f[i]; sub(/^why:[ \t]*/, "", why) } else if (f[i] ~ /^applies-to:/) { ap = f[i]; sub(/^applies-to:[ \t]*/, "", ap) } else if (f[i] ~ /^scope:/) { sc = f[i]; sub(/^scope:[ \t]*/, "", sc) } else if (f[i] ~ /^enforced:/) { en = f[i]; sub(/^enforced:[ \t]*/, "", en) } }
        if (!(id in S)) O[++no] = id; S[id] = "D\t" id "\t" what "\t" why "\t" ap "\t" sc "\t" en }
        END { for (i = 1; i <= no; i++) print S[O[i]] }' "$W/doc" > "$_o.tmp" ;;
    # v0.26.10.2 (R1): the first table whose header row has a cell `Module`, to the table's end, columns by header name;
    #   a row whose Module cell is empty or starts {{ is skipped, as in imports.sh. MT: the table is there; MC <column>:
    #   a column it lacks; MR <id> <responsibility> <owned> <surface> <dependents>, each as written, \034 for a missing
    #   column. The id: the Module cell, backticks removed, a dotted label read as a path (imports.sh:43-46)
    arch) awk -F'|' 'function tr(s) { gsub(/\t/, " ", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function cell(k) { return k ? tr(c[k]) : "\034" }
      /^[ \t]*\|/ { if (done) next; if (!intab) { intab = 1; if (!on) { n = split($0, c, "|"); for (k = 2; k < n; k++) H[tr(c[k])] = k
            if ("Module" in H) { on = 1; print "MT"; split("Module|Responsibility|Owned tables/data|Public surface|Dependents", N, "|")
              for (k = 1; k <= 5; k++) { COL[k] = (N[k] in H) ? H[N[k]] : 0; if (!COL[k]) print "MC\t" N[k] } } else split("", H) } next }
          if (!on) next; if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) next
          split($0, c, "|"); m = cell(COL[1]); gsub(/`/, "", m); m = tr(m); if (m == "" || m == "\034" || index(m, "{{") == 1 || m == "Module") next
          if (m !~ /\// && m ~ /\./) gsub(/\./, "/", m)
          print "MR\t" m "\t" cell(COL[2]) "\t" cell(COL[3]) "\t" cell(COL[4]) "\t" cell(COL[5]); next }
      { if (intab && on) done = 1; intab = 0 }' "$W/doc" > "$_o.tmp" ;;
    # v0.26.10.2 (R6, R15): the first table under `## Stack` (SK <layer> <choice> <ruled out>, the third column when its
    #   header starts FORBIDDEN, else \034) and under `## Tier-0 rows` (T0 <rule> <meaning>); SKT and T0T: the table is there
    base) awk -F'|' 'function tr(s) { gsub(/\t/, " ", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^## / { sec = ""; if ($0 ~ /^## Stack[ \t]*$/) sec = "SK"; else if ($0 ~ /^## Tier-0 rows[ \t]*$/) sec = "T0"; intab = 0; next }
      /^[ \t]*\|/ { if (sec == "" || (sec in DONE)) next
          if (!intab) { intab = 1; print sec "T"; n = split($0, c, "|"); rc = (n > 4 && toupper(tr(c[4])) ~ /^FORBIDDEN/) ? 4 : 0; next }
          if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) next; n = split($0, c, "|")
          if (sec == "SK") print "SK\t" tr(c[2]) "\t" (n > 3 ? tr(c[3]) : "\034") "\t" (rc ? tr(c[rc]) : "\034"); else print "T0\t" tr(c[2]) "\t" (n > 3 ? tr(c[3]) : "\034"); next }
      { if (intab) DONE[sec] = 1; intab = 0 }' "$W/doc" > "$_o.tmp" ;;
    # v0.26.10.2 (R5, R15, R17d): the seam rows of the vid-inventory block — SV <id> <service> <purpose> <chosen>
    #   <credentials> <probe> <evidence> <quirks> <module>, the labelled fields by label, \034 where absent
    seam) sed -n '/^```vid-inventory/,/^```$/p' "$W/doc" | awk -F'|' 'function tr(s) { gsub(/\t/, " ", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      tr($1) == "seam" { split("chosen credentials probe evidence quirks module", L, " "); split("", V)
        for (i = 5; i <= NF; i++) { x = tr($i); for (k = 1; k <= 6; k++) if (index(x, L[k] ":") == 1) V[k] = tr(substr(x, length(L[k]) + 2)) }
        o = "SV\t" tr($2) "\t" tr($3) "\t" tr($4); for (k = 1; k <= 6; k++) o = o "\t" ((k in V) ? V[k] : "\034"); print o }' > "$_o.tmp" ;;
    man) sed -n '/^```vid-design-manifest$/,/^```$/p' "$W/doc" | grep -v '^```' | grep -v '^[[:space:]]*#' | awk -F'|' 'NF >= 3 { for (i = 1; i <= 3; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i); gsub(/[ \t]/, "", $3); print "S\t" $1 "\t" $2 "\t" $3 }' > "$_o.tmp" ;;
    cvm) grep -o '@screen [A-Za-z0-9_-]* state=[A-Za-z0-9_-]*' "$W/doc" | awk '{ s = $3; sub(/^state=/, "", s); print "M\t" $2 "\t" s }' | awk '!x[$0]++' > "$_o.tmp" ;;
  esac
  mv "$_o.tmp" "$_o"
}
# canvas <name> <pack> <blob> <C>: the canvas packaged for offline use, as a JSON string, cached by its inputs —
# each relative script or stylesheet it names that the pack holds at C goes inline, with the vendored runtime
# library before the first script and the runtime's self-read switched off (spec 3.10, kind 1)
canvas() {
  _cvb=$3; _pk=$2; _cc=$4
  git -C "$P" cat-file blob "$_cvb" > "$W/cv" 2>/dev/null || return 1
  grep -oE '<(script|link)[^>]*(src|href)="[^"#:]+"' "$W/cv" | sed -E 's/.*(src|href)="(\.\/)?([^"]*)".*/\3/' | awk '!x[$0]++' > "$W/cvrefs"
  : > "$W/cvinc"
  while IFS= read -r _r; do _rb=$(blob "$_cc" "$_pk/$_r") && printf '%s\t%s\n' "$_r" "$_rb" >> "$W/cvinc"; done < "$W/cvrefs"
  _key=$( { printf '%s\n' "$_cvb"; cat "$W/cvinc"; cat "$LIB" "$LIBDOM" | hashof; } | hashof)
  printf '%s\n' "$_key"
  [ -f "$OUT/.cache/blob/$_key.canvas" ] && return 0
  mkdir -p "$W/inc"; rm -f "$W/inc/"*
  while IFS='	' read -r _r _rb; do git -C "$P" cat-file blob "$_rb" > "$W/inc/$(printf '%s' "$_r" | tr '/' '_')"; done < "$W/cvinc"
  LC_ALL=C awk -v incd="$W/inc" -v incl="$W/cvinc" -v lib="$LIB" -v libdom="$LIBDOM" "$AWKJS"'
    function slurp(f,   l, o) { o = ""; while ((getline l < f) > 0) o = o l "\n"; close(f); return o }
    BEGIN { while ((getline l < incl) > 0) { split(l, a, "\t"); n = a[1]; f = n; gsub(/\//, "_", f); INC[n] = incd "/" f } printf "%s", "\"" }
    { line = $0
      while (match(line, /<script[^>]*src="[^"]*"[^>]*><\/script>|<link[^>]*rel="stylesheet"[^>]*href="[^"]*"[^>]*>|<link[^>]*href="[^"]*"[^>]*rel="stylesheet"[^>]*>/)) {
        tag = substr(line, RSTART, RLENGTH); pre = substr(line, 1, RSTART - 1); line = substr(line, RSTART + RLENGTH)
        r = tag; if (tag ~ /^<script/) sub(/.*src="/, "", r); else sub(/.*href="/, "", r); sub(/".*/, "", r); sub(/^\.\//, "", r)
        out = pre
        if (r in INC) { body = slurp(INC[r])
          if (tag ~ /^<script/) { if (!libin) { libin = 1; out = out "<script>window.__resources={};</script><script>" slurp(lib) "</script><script>" slurp(libdom) "</script>" } out = out "<script>" body "</script>" }
          else out = out "<style>" body "</style>" }
        else out = out tag
        e = js(out); printf "%s", substr(e, 2, length(e) - 2) }
      e = js(line "\n"); printf "%s", substr(e, 2, length(e) - 2) }
    END { printf "%s", "\"" }' "$W/cv" > "$OUT/.cache/blob/$_key.canvas.tmp" && mv "$OUT/.cache/blob/$_key.canvas.tmp" "$OUT/.cache/blob/$_key.canvas"
}

# --- v0.26.10.2 (R13, R16): the main history, read once per run, cached by HEAD ------------------------------
# fpl: HEAD's first-parent history, newest first. .dec: each decision id, with the first commit on it whose
# DECISIONS.md holds the id, and that commit's time. .arch: each change to a module's Public surface cell on it,
# oldest first — <module> <commit> <time> <from (\034: the row first appears)> <to>.
git -C "$P" rev-list --first-parent HEAD > "$W/fpl" 2>/dev/null || : > "$W/fpl"
HK=$(printf '%s\n%s\n' "$HEAD" "$CODEH" | hashof); HDEC="$OUT/.cache/hist/$HK.dec"; HARCH="$OUT/.cache/hist/$HK.arch"
if [ "$NTODO" -gt 0 ] && { [ ! -f "$HDEC" ] || [ ! -f "$HARCH" ]; }; then
  mkdir -p "$OUT/.cache/hist"
  TZ=UTC0 git -C "$P" log --first-parent --diff-merges=first-parent --reverse -p --unified=0 --no-color --no-ext-diff --no-renames --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%x01%H %cd' HEAD -- DECISIONS.md 2>/dev/null |
    awk '/^\001/ { c = substr($1, 2); t = $2; next } /^\+- \*\*D-[0-9]+\*\*/ { id = $0; sub(/^\+- \*\*/, "", id); sub(/\*\*.*/, "", id); if (!(id in S)) { S[id] = 1; print id "\t" c "\t" t } }' > "$HDEC.tmp" && mv "$HDEC.tmp" "$HDEC"
  TZ=UTC0 git -C "$P" log --first-parent --diff-merges=first-parent --reverse --no-renames --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%H %cd' HEAD -- ARCHITECTURE.md 2>/dev/null > "$W/archlog" || : > "$W/archlog"
  while IFS=' ' read -r _h _d; do
    if _b=$(blob "$_h" ARCHITECTURE.md) && parse arch "$_b"; then awk -F'\t' -v h="$_h" -v d="$_d" '$1 == "MR" { print h "\t" d "\t" $2 "\t" $5; n++ } END { if (!n) print h "\t" d "\t\035" }' "$OUT/.cache/blob/$_b.arch"
    else printf '%s\t%s\t\035\n' "$_h" "$_d"; fi
  done < "$W/archlog" | awk -F'\t' 'function flush(   m) { if (c == "") return; for (m in CUR) if (!(m in OLD) || OLD[m] != CUR[m]) print m "\t" c "\t" t "\t" ((m in OLD) ? OLD[m] : "\034") "\t" CUR[m]
      split("", OLD); for (m in CUR) OLD[m] = CUR[m]; split("", CUR) }
    $1 != c { flush(); c = $1; t = $2 } $3 != "\035" && !(($3) in CUR) { CUR[$3] = $4 } END { flush() }' > "$HARCH.tmp" && mv "$HARCH.tmp" "$HARCH"
fi

# --- one snapshot's data (R3, R4, R7) ------------------------------------------------------------------------
# snapdata <T> <C> <kind> <fp>: computed in a sealed view root, cached as .cache/data/<fp>.{json,facts,meta,canvases,sum}
snapdata() {
  _T=$1; _C=$2; _K=$3; _fp=$4; S="$W/s.$_fp"; V="$W/v.$_fp"; mkdir -p "$S" "$V"
  _t0=$(date +%s)
  _C=$(git -C "$P" rev-parse "$_C^{commit}")
  # the view root: its own repository on the project's objects, HEAD detached at C, no checkout
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git init -q "$V" || return 1
  printf '%s\n' "$CD/objects" > "$V/.git/objects/info/alternates"
  printf '%s\n' "$_C" > "$V/.git/HEAD"
  for f in PRD.md INVENTORY.md DESIGN-BRIEF.md DECISIONS.md docker-compose.test.yml; do
    git -C "$P" show "$_C:$f" > "$V/$f" 2>/dev/null || rm -f "$V/$f"; done
  git -C "$P" rev-parse -q --verify "$_C:design" >/dev/null 2>&1 && git -C "$P" archive "$_C" design 2>/dev/null | tar -x -C "$V" 2>/dev/null
  # the records up to T, copied
  mkdir -p "$V/.vid"
  awk "$AWKAT"' { t = lastat() } t == "" || t <= T' T="$_T" "$EVF" > "$V/.vid/metrics-events"
  # a develop run that has started by T reads as active at T (a paused run reads like an active one)
  if grep -q '^stage .*name=develop.*state=start' "$V/.vid/metrics-events"; then printf 'stage name=develop state=start session=vid-view at=%s\n' "$_T" >> "$V/.vid/metrics-events"; fi
  [ -d "$P/.vid/ledger-results" ] && cp -R "$P/.vid/ledger-results" "$V/.vid/"
  [ -d "$P/.vid/plans" ] && cp -R "$P/.vid/plans" "$V/.vid/"
  _ph=$(awk "$AWKAT"' $1 == "plan-change" && kv("hash") != "" { h = kv("hash") } END { print h }' "$V/.vid/metrics-events")
  : > "$S/plan"; [ -n "$_ph" ] && [ -f "$P/.vid/plans/$_ph.plan" ] && cp "$P/.vid/plans/$_ph.plan" "$S/plan"
  { printf 'run: active\nsession: vid-view\nplan: required\n\n## The plan\n\n```vid-plan\n'; cat "$S/plan"; printf '```\n'; } > "$V/.vid/RUN-STATE.md"
  mkdir -p "$V/checks"; (cd "$PLUG/checks" && find . -type f ! -path './selftest/*' | while IFS= read -r f; do mkdir -p "$V/checks/$(dirname "$f")"; cp "$f" "$V/checks/$f"; done)
  # the project's own results reader, at C (a receipt without its .cases sidecar is read through it)
  git -C "$P" rev-parse -q --verify "$_C:checks/extractors" >/dev/null 2>&1 && git -C "$P" archive "$_C" checks/extractors 2>/dev/null | tar -x -C "$V" 2>/dev/null
  # the documents, parsed once per blob
  # v0.26.10.2 (R1, R5, R6, R8, R13): the decisions by dec2; ARCHITECTURE.md, BASELINE.md and the seam rows by their own
  #   kinds; HAS <kind>: the document is there at C
  for d in prd:PRD.md inv:INVENTORY.md dec2:DECISIONS.md man:DESIGN-BRIEF.md arch:ARCHITECTURE.md base:BASELINE.md seam:INVENTORY.md; do _kd=${d%%:*}; _b=$(blob "$_C" "${d#*:}") && parse "$_kd" "$_b" && printf 'HAS\t%s\n' "$_kd" && cat "$OUT/.cache/blob/$_b.$_kd"; done > "$S/docs"
  # v0.26.10.2 (R14): the paths at C, no file read; (R13, R16) C's place on the main history, building's start by T
  git -C "$P" -c core.quotePath=false ls-tree -r --name-only "$_C" > "$S/files" 2>/dev/null || : > "$S/files"
  _ci=$(grep -nx "$_C" "$W/fpl" | head -n 1 | cut -d: -f1)
  _ds=$(awk "$AWKAT"' $1 == "stage" && kv("name") == "develop" && kv("state") == "start" { t = lastat(); if (t != "") { print t; exit } }' "$V/.vid/metrics-events")
  # the plan at T, parsed by the plugin's plan.sh
  if [ -s "$S/plan" ]; then (cd "$V" && sh checks/plan.sh parse "$S/plan") > "$S/parsed" 2>/dev/null || : > "$S/parsed"; else : > "$S/parsed"; fi
  # the map: every INVENTORY row at C, its step from the plan at T, no paths
  awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "row") SR[$2] = $3; next } $1 == "P" { print $2 "\t" (($2 in SR) ? SR[$2] : "-") "\t" }' "$S/parsed" "$S/docs" > "$S/map"
  # the reader, the only command run in V
  if [ "$_K" = now ]; then _u=''; else _u=$_T; fi
  if [ -s "$S/map" ]; then
    if [ -n "$_u" ]; then set -- --until "$_u"; else set --; fi
    ( cd "$V" && sh checks/evidence.sh rows --at "$_C" --map "$S/map" "$@" ) > "$S/states" 2> "$S/reader.err" || { echo "ViD view: the evidence reader failed at $_C ($_T): $(head -n 3 "$S/reader.err")" >&2; return 1; }
  else : > "$S/states"; fi
  # the canvases at C: the pack (design/screens, else design), each .html file holding @screen markers
  _pk=design; git -C "$P" rev-parse -q --verify "$_C:design/screens" >/dev/null 2>&1 && _pk=design/screens
  : > "$S/cvlist"
  git -C "$P" ls-tree "$_C" "$_pk/" 2>/dev/null | awk -F'\t' '$1 ~ / blob / && $2 ~ /\.html$/ { split($1, a, " "); print a[3] "\t" $2 }' > "$S/cvfiles" || : > "$S/cvfiles"
  while IFS='	' read -r _b _path; do
    parse cvm "$_b" || continue; [ -s "$OUT/.cache/blob/$_b.cvm" ] || continue
    _nm=${_path##*/}; _nm=${_nm%.html}; _nm=${_nm%.dc}
    _key=$(canvas "$_nm" "$_pk" "$_b" "$_C") || continue
    awk -F'\t' -v n="$_nm" '{ print "CV\t" n "\t" $2 "\t" $3 }' "$OUT/.cache/blob/$_b.cvm" >> "$S/docs"
    printf '%s\t%s\n' "$_nm" "$_key" >> "$S/cvlist"
  done < "$S/cvfiles"
  # the records the data reads, up to T: verdicts, hand-backs (timed by build-cost), step times, questions
  E="$V/.vid/metrics-events"
  awk "$AWKAT"' $1 == "verdict" && kv("row") != "" && kv("result") != "" { r = kv("row"); b = kv("brief"); k = r SUBSEP b
      res = (kv("result") == "KEPT") ? "kept" : "broken"; c = kv("class"); if (c == "") c = "-"
      if (!(k in R)) { O[++n] = k; R[k] = res; A[k] = lastat(); C[k] = c; ROW[k] = r; BR[k] = b } else { if (res == "broken") R[k] = "broken"; if (c != "-" && C[k] == "-") C[k] = c } }
    END { for (i = 1; i <= n; i++) { k = O[i]; print "J\t" ROW[k] "\t" A[k] "\t" R[k] "\t" C[k] "\t" BR[k] } }' "$E" > "$S/judg"
  # v0.9.8.1 (R7, F-1): brief= read whole, up to the next field, relative to the project (an older record's absolute
  #   path, spaces and all, its prefix removed); a hand-back the records name and the project lacks is said, never 0
  awk -v h="$P" "$AWKAT"' $1 == "build-cost" && bkv(h) != "" { print bkv(h) }' "$E" | awk '!x[$0]++' | while IFS= read -r _br; do
    case "$_br" in /*) _rf="${_br%.md}.return.md" ;; *) _rf="$P/${_br%.md}.return.md" ;; esac
    if [ -f "$_rf" ]; then awk -F'|' '$1 ~ /^[ \t]*ROW-/ { r = $1; gsub(/[ \t]/, "", r); s = $2; gsub(/[ \t]/, "", s); if (s == "pass") print "B\t" r }' "$_rf"
    else echo "ViD view: note — the hand-back $_rf, named by a build-cost record, is not in the project; its rows are not counted as built" >&2; fi
  done | awk '!x[$0]++' > "$S/built"
  awk "$AWKAT"' { t = lastat() } $1 == "step-start" && kv("step") != "" && !(kv("step") in SS) { SS[kv("step")] = t; print "SS\t" kv("step") "\t" t }
    $1 == "step-closed" && kv("step") != "" { print "SC\t" kv("step") "\t" t }' "$E" > "$S/steptimes"
  if [ "$_K" = now ]; then
    awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+/ { l = $0; sub(/^- /, "", l); gsub(/\t/, " ", l); print "Q\t" l }' "$P/.vid/RUN-STATE.md" 2>/dev/null > "$S/qs" || : > "$S/qs"
  else
    awk "$AWKAT"' $1 == "question" && kv("n") != "" { n = kv("n"); if (kv("state") == "asked") { if (!(n in A)) O[++no] = n; A[n] = substr(lastat(), 1, 10); G[n] = kv("gates"); delete D[n] } else if (kv("state") == "answered") D[n] = 1 }
      END { for (i = 1; i <= no; i++) { n = O[i]; if (n in D) continue; g = G[n]; gsub(/,/, ", ", g); print "Q\tQ" n " · asked " A[n] " · gates " (g == "" ? "-" : g) " · wording not recorded (a past snapshot; the run state keeps only open questions)" } }' "$E" > "$S/qs"
  fi
  # now only: the reviewers' prose, agents open, recent commits, plan changes
  : > "$S/now"
  if [ "$_K" = now ]; then
    for f in $(find "$P/.vid/verdicts" -name 'ROW-*.md' -type f 2>/dev/null | LC_ALL=C sort); do
      awk -v row="$(basename "$f" .md)" 'function flush() { if (h != "") { gsub(/\t/, " ", body); gsub(/\n/, "\002", body); print "X\t" row "\t" h "\t" body } }
        /^## / { flush(); h = $0; sub(/^## /, "", h); body = ""; next } h != "" { body = body (body == "" ? "" : "\n") $0 } END { flush() }' "$f" >> "$S/now"
    done
    awk -v h="$P" "$AWKAT"' { t = lastat() }
      $1 == "agent-start" && kv("agent") != "" { a = kv("agent"); if (!(a in OP)) OO[++no] = a; OP[a] = 1; TY[a] = kv("type"); AT[a] = t }
      $1 == "agent-stop" && kv("agent") != "" { delete OP[kv("agent")] }
      $1 == "job-start" && kv("try") != "" { j = kv("try"); if (!(j in JO)) JL[++nj] = j; JO[j] = 1; JT[j] = t; JS[j] = kv("step") }
      ($1 == "job-exit" || $1 == "job-stop") && kv("try") != "" { delete JO[kv("try")] }
      $1 == "job-recovery-required" && kv("try") != "" { JO[kv("try")] = 1 }
      $1 == "brief-written" && kv("path") != "" { b = kv("path"); if (index(b, h "/") == 1) b = substr(b, length(h) + 2); BW[++nb] = b; BR[b] = kv("role"); BT[b] = t }
      $1 == "build-cost" && bkv(h) != "" { DONE[bkv(h)] = 1 }
      END { for (i = 1; i <= no; i++) { a = OO[i]; if (!(a in OP)) continue; ty = TY[a]; ro = ty; sub(/^vid:/, "", ro); hb = ""
          for (k = nb; k >= 1; k--) { b = BW[k]; if (BR[b] == ro && !(b in DONE) && !(b in USED) && BT[b] <= AT[a]) { hb = b; USED[b] = 1; break } }
          print "AG\t" ro " " substr(a, 1, 8) " (since " AT[a] ")\t" (hb == "" ? "" : "its hand-back for " hb) }
        for (i = 1; i <= nj; i++) { j = JL[i]; if (j in JO) print "AG\tCodex builder " j (JS[j] != "" ? " · " JS[j] : "") " (since " JT[j] ")\tits hand-back: the job record .vid/jobs/" j } }' "$EVF" >> "$S/now"
    TZ=UTC0 git -C "$P" log --first-parent -n 12 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='RC%x09%h%x09%cd%x09%s' "$_C" >> "$S/now" 2>/dev/null
    awk "$AWKAT"' $1 == "plan-change" { L[++n] = "PC\t" kv("what") "\t" lastat() "\t" qv("why") } END { for (i = (n > 10 ? n - 9 : 1); i <= n; i++) print L[i] }' "$EVF" >> "$S/now"
  fi
  # the data body (viewer-data 2, less meta and changes) and the facts the change log compares
  LC_ALL=C awk -F'\t' -v S="$S" -v K="$_K" -v ci="$_ci" -v ds="$_ds" -v fpl="$W/fpl" -v hdec="$HDEC" -v harch="$HARCH" "$AWKJS""$AWKARCH"'
    function caps_of(list,   n, a, i, o, s, c) { n = split(list, a, /[ ,]+/); o = ""; split("", s)
      for (i = 1; i <= n; i++) { c = ""; if (a[i] in RCAP) c = RCAP[a[i]]; else if (a[i] in PCAPS) c = PCAPS[a[i]]
        if (c != "") { m = split(c, cc, ","); for (q = 1; q <= m; q++) if (cc[q] != "" && !(cc[q] in s)) { s[cc[q]] = 1; o = o (o == "" ? "" : ",") cc[q] } } } return o }
    function arr(name, n, A,   i) { printf "%s", "\"" name "\":["; for (i = 1; i <= n; i++) printf "%s%s\n", A[i], (i < n ? "," : ""); printf "%s", "],\n" }
    BEGIN {
      while ((getline l < (S "/docs")) > 0) { n = split(l, f, "\t")
        if (f[1] == "G") G[++ng] = "{\"id\":" js(f[2]) ",\"name\":" js(f[3]) ",\"text\":" js(f[4]) "}"
        else if (f[1] == "F") { FG[f[2]] = f[3]; F[++nf] = "{\"id\":" js(f[2]) ",\"goal\":" jn(f[3]) ",\"name\":" js(f[4]) "}" }
        else if (f[1] == "U") U[++nu] = "{\"name\":" js(f[2]) "}"
        else if (f[1] == "R") { RID[f[2]] = 1; RCAP[f[2]] = f[8]
          R[++nr] = "{\"id\":" js(f[2]) ",\"type\":" js(f[3]) ",\"tier\":" js(f[4]) ",\"plain\":" js(f[5]) ",\"statement\":" js(f[6]) ",\"failsIf\":" jn(f[7]) ",\"capability\":" jn(f[8]) ",\"phase\":" js(f[9] == "" ? "pilot" : f[9]) "}" }
        else if (f[1] == "N") NG[++nn] = "{\"id\":" js(f[2]) ",\"plain\":" js(f[3]) "}"
        else if (f[1] == "A") { AID[++na] = f[2]; ATI[f[2]] = f[3]; ADA[f[2]] = f[4]; AQ[f[2]] = f[5]; AA[f[2]] = f[6]; ASE[f[2]] = f[7]; AAM[f[2]] = f[8] }
        else if (f[1] == "D") { DID[++nd] = f[2]; DW[f[2]] = f[3]; DY[f[2]] = f[4]; DAP[f[2]] = f[5]; DSC[f[2]] = f[6]; DEN[f[2]] = f[7] }
        else if (f[1] == "S") { SM[++nsm] = f[2] "\t" f[3] "\t" f[4] }
        else if (f[1] == "CV") CVN[f[3], f[4]] = f[2]
        else if (f[1] == "P") { PID[++np] = f[2]; PK[f[2]] = f[3]; PA[f[2]] = f[4]; PSC[f[2]] = f[5]; PT[f[2]] = f[6]; PD[f[2]] = f[7]; PTS[f[2]] = f[8] }
        else arch_read(l) }
      while ((getline l < (S "/parsed")) > 0) { split(l, f, "\t"); if (f[1] == "step") { SID[++ns] = f[2]; SNM[f[2]] = f[3]; SMOD[f[2]] = f[4]; SBO[f[2]] = f[5]; SKD[f[2]] = (f[7] == "hardening" ? "hardening" : "feature") } else if (f[1] == "row") { RSTEP[f[2]] = f[3]; SROWS[f[3]] = SROWS[f[3]] " " f[2] } }
      while ((getline l < (S "/states")) > 0) { split(l, f, "\t"); ST[f[1]] = f[2]; SD[f[1]] = f[3] }
      while ((getline l < (S "/built")) > 0) { split(l, f, "\t"); BU[f[2]] = 1 }
      while ((getline l < (S "/judg")) > 0) { split(l, f, "\t"); JN[f[2]]++; JJ[f[2], JN[f[2]]] = f[3] "\t" f[4] "\t" f[5] "\t" f[6] }
      while ((getline l < (S "/steptimes")) > 0) { split(l, f, "\t"); if (f[1] == "SS") SST[f[2]] = f[3]; else SCT[f[2]] = f[3] }
      while ((getline l < (S "/qs")) > 0) { sub(/^Q\t/, "", l); Q[++nq] = js(l) }
      while ((getline l < (S "/now")) > 0) { split(l, f, "\t")
        if (f[1] == "X") { h = f[3]; split(h, hp, / · /); sl = hp[1]; sub(/^slice /, "", sl); key = f[2] SUBSEP sl SUBSEP hp[2]; b = f[4]; gsub(/\002/, "\n", b); PROSE[key] = b }
        else if (f[1] == "AG") AG[++nag] = "{\"name\":" js(f[2]) ",\"handBack\":" js(f[3]) "}"
        else if (f[1] == "RC") RC[++nrc] = "{\"commit\":" js(f[2]) ",\"time\":" js(f[3]) ",\"subject\":" js(f[4]) "}"
        else if (f[1] == "PC") PCH[++npc] = "{\"what\":" js(f[2]) ",\"why\":" js(f[4]) ",\"at\":" jn(f[3]) "}" }
    }
    END {
      # promises: requirements (the derived items this snapshot holds), capabilities through them
      for (i = 1; i <= np; i++) { id = PID[i]; m = split(PD[id], dd, /[ ,]+/); rq = ""; cp = ""; split("", sc)
        for (k = 1; k <= m; k++) if (dd[k] in RID) { rq = rq (rq == "" ? "" : ",") dd[k]; c = RCAP[dd[k]]; if (c != "" && !(c in sc)) { sc[c] = 1; cp = cp (cp == "" ? "" : ",") c } }
        PRQ[id] = rq; PCAPS[id] = cp }
      printf "%s", "\"goals\":["; for (i = 1; i <= ng; i++) printf "%s%s\n", G[i], (i < ng ? "," : ""); printf "%s", "],\n"
      arr("capabilities", nf, F); arr("users", nu, U)
      nj2 = 0; for (i = 1; i <= np; i++) if (PK[PID[i]] == "journey") JRN[++nj2] = "{\"promise\":" js(PID[i]) ",\"text\":" js(PT[PID[i]]) "}"
      arr("journeys", nj2, JRN); arr("requirements", nr, R); arr("nonGoals", nn, NG)
      for (i = 1; i <= nsm; i++) { split(SM[i], f, "\t"); cv = ((f[1], f[2]) in CVN) ? CVN[f[1], f[2]] : ""; m = split(f[3], rr, ","); o = ""
          for (k = 1; k <= m; k++) if (rr[k] in RID) o = o (o == "" ? "" : ",") rr[k]
          SCR[i] = "{\"screen\":" js(f[1]) ",\"state\":" js(f[2]) ",\"requirements\":" ja(o, ",") ",\"canvas\":" jn(cv) "}" }
      arr("screens", nsm, SCR)
      # each promise; the result file and commit from the reader detail, in each form it prints
      nb = 0; nt = 0; nrv = 0; nk = 0; nbk = 0
      for (i = 1; i <= np; i++) { id = PID[i]; s = (id in ST) ? ST[id] : "never"; dt = (id in SD) ? SD[id] : "not read"; rf = ""; rc = ""
        if (s == "pass") { if (dt ~ /^passed at /) { rc = dt; sub(/^passed at /, "", rc); sub(/ \(.*$/, "", rc); rf = dt; sub(/^[^(]*\(/, "", rf); sub(/\)$/, "", rf) } else rf = dt }
        else if (dt ~ /\(last current run: [^)]*\)$/) { rf = dt; sub(/.*\(last current run: /, "", rf); sub(/\)$/, "", rf) }
        else if (dt ~ /\(last run [^)]*\)/) { rf = dt; sub(/.*\(last run /, "", rf); sub(/\).*$/, "", rf) }
        if (rf != "" && rc == "" && match(rf, /^[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+\./)) rc = substr(rf, 1, RLENGTH - 1)
        by[s]++; if (s == "pass") nt++; if (id in BU) nb++
        js_ = ""; last = ""
        for (k = 1; k <= JN[id]; k++) { split(JJ[id, k], jf, "\t"); bk = jf[4]; sl = bk; sub(/^\.vid\/briefs\//, "", sl); nm = sl; sub(/\/.*/, "", sl); sub(/^.*\//, "", nm); sub(/\.md$/, "", nm)
          pr = (K == "now" && ((id, sl, nm) in PROSE)) ? PROSE[id, sl, nm] : ""
          js_ = js_ (js_ == "" ? "" : ",") "{\"at\":" js(jf[1]) ",\"result\":" js(jf[2]) ",\"class\":" js(jf[3]) ",\"prose\":" jn(pr) "}"; last = jf[2] }
        if (JN[id] > 0) { nrv++; if (last == "kept") nk++; else nbk++ }
        st_ = RSTEP[id]; sco = PSC[id]; if (sco == "-" || sco == "") sco = ""
        PR[i] = "{\"id\":" js(id) ",\"kind\":" js(PK[id]) ",\"text\":" js(PT[id]) ",\"requirements\":" ja(PRQ[id], ",") ",\"capabilities\":" ja(PCAPS[id], ",") ",\"screenState\":" jn(sco) ",\"test\":" js(PTS[id]) ",\"step\":" jn(st_) ",\"state\":" js(s) ",\"stateDetail\":" js(dt) ",\"resultFile\":" jn(rf) ",\"resultCommit\":" jn(rc) ",\"built\":" jb(id in BU) ",\"judgments\":[" js_ "]}"
        if (s == "held") HELD = HELD (HELD == "" ? "" : ",") id
        print "P\t" id "\t" s "\t" PCAPS[id] > (S "/facts") }
      arr("promises", np, PR)
      cl = 0; un = 0; ns0 = 0
      for (i = 1; i <= ns; i++) { s = SID[i]; m = split(SROWS[s], rr, " "); o = ""; for (k = 1; k <= m; k++) if (rr[k] != "") o = o (o == "" ? "" : ",") rr[k]
        bo = SBO[s]; if (bo == "-") bo = ""
        if (s in SCT) cl++; else if (s in SST) un++; else ns0++
        STP[i] = "{\"id\":" js(s) ",\"name\":" js(SNM[s]) ",\"kind\":" js(SKD[s]) ",\"buildsOn\":" ja(bo, " ") ",\"promises\":" ja(o, ",") ",\"started\":" jn(SST[s]) ",\"closed\":" jn(SCT[s]) ",\"done\":null}" }
      arr("steps", ns, STP)
      printf "%s", "\"decisions\":{\"answers\":["
      for (i = 1; i <= na; i++) { a = AID[i]; printf "%s{\"id\":%s,\"amended\":%s,\"tier\":%s,\"date\":%s,\"q\":%s,\"a\":%s,\"settles\":%s,\"delegated\":false}\n", (i > 1 ? "," : ""), js(a), jb(AAM[a] == 1), js(ATI[a]), js(ADA[a]), js(AQ[a]), js(AA[a]), ja(ASE[a], ",")
        print "A\t" a "\t" ATI[a] "|" ADA[a] "|" AQ[a] "|" AA[a] "|" ASE[a] "\t" ADA[a] "\t" caps_of(ASE[a]) "\t" AA[a] > (S "/facts") }
      printf "%s", "],\"technical\":["
      for (i = 1; i <= nd; i++) { d = DID[i]; printf "%s{\"id\":%s,\"what\":%s,\"why\":%s,\"appliesTo\":%s,\"scope\":%s%s}\n", (i > 1 ? "," : ""), js(d), js(DW[d]), js(DY[d]), jn(DAP[d]), jn(DSC[d]), atech(d)
        print "D\t" d "\t" DW[d] "|" DY[d] "|" DAP[d] "|" DSC[d] "\t-\t" caps_of(DAP[d]) "\t" DW[d] > (S "/facts") }
      printf "%s", "]},\n"
      # v0.9.8.1 (R22): every answer the effective ledger holds, newest first — the page shows each from decisions.answers
      ANSW = ""; for (i = na; i >= 1; i--) ANSW = ANSW (ANSW == "" ? "" : ",") AID[i]
      printf "%s", "\"needsYou\":{\"questions\":["; for (i = 1; i <= nq; i++) printf "%s%s", (i > 1 ? "," : ""), Q[i]; printf "%s", "],\"held\":" ja(HELD, ",") ",\"answered\":" ja(ANSW, ",") ",\n"
      printf "%s\n", "\"delegated\":[\"@VID-DELEGATED@\"]},"
      printf "%s", "\"activity\":{\"agentsOpen\":["; for (i = 1; i <= nag; i++) printf "%s%s", (i > 1 ? "," : ""), AG[i]
      printf "%s", "],\"recentCommits\":["; for (i = 1; i <= nrc; i++) printf "%s%s", (i > 1 ? "," : ""), RC[i]
      printf "%s", "],\"planChanges\":["; for (i = 1; i <= npc; i++) printf "%s%s", (i > 1 ? "," : ""), PCH[i]; printf "%s", "]},\n"
      arch_part()
      o = ""; for (k in by) o = o (o == "" ? "" : ",") js(k) ":" by[k]
      printf "\"counts\":{\"promises\":%d,\"built\":%d,\"tested\":%d,\"reviewed\":%d,\"reviewedKept\":%d,\"reviewedBroken\":%d,\"byState\":{%s},\"steps\":{\"closed\":%d,\"underway\":%d,\"notStarted\":%d}},\n", np, nb, nt, nrv, nk, nbk, o, cl, un, ns0
    }' /dev/null > "$S/body" || return 1
  [ -f "$S/facts" ] || : > "$S/facts"
  _secs=$(( $(date +%s) - _t0 ))
  printf 'T=%s\nC=%s\nkind=%s\nmadeAt=%s\nseconds=%s\n' "$_T" "$_C" "$_K" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$_secs" > "$S/meta"
  _b="$OUT/.cache/data/$_fp"
  cp "$S/body" "$_b.json.tmp" && cp "$S/facts" "$_b.facts.tmp" && cp "$S/meta" "$_b.meta.tmp" && cp "$S/cvlist" "$_b.canvases.tmp" || return 1
  for x in json facts meta canvases; do mv "$_b.$x.tmp" "$_b.$x"; done
  cat "$_b.json" "$_b.facts" "$_b.meta" "$_b.canvases" | hashof > "$_b.sum"
  rm -rf "$V" "$S"
  printf '%s\n' "$_secs"
}

NMADE=0; SECS=0
while IFS='	' read -r _t _c _k _l _f _r _fp; do
  _kk=past; [ "$_k" = now ] && _kk=now
  _s=$(snapdata "$_t" "$_c" "$_kk" "$_fp") || die "the snapshot $_f could not be computed."
  NMADE=$((NMADE + 1)); SECS=$((SECS + ${_s:-0}))
  echo "ViD view: computed $_f (${_s} s)"
done < "$W/todo"
[ "$NMADE" -gt 0 ] && echo $(( (SECS + NMADE - 1) / NMADE )) > "$OUT/.cache/pace"
# every snapshot's moment is its cached data's (now's time is when its data was made, so an unchanged now is unchanged)
while IFS='	' read -r _t _c _k _l _f _r _fp; do
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(sed -n 's/^T=//p' "$OUT/.cache/data/$_fp.meta")" "$_c" "$_k" "$_l" "$_f" "$_r" "$_fp"
done < "$W/snapfp" > "$W/snapfp.x" && mv "$W/snapfp.x" "$W/snapfp"

# --- the change log (R8): between consecutive snapshots' data -----------------------------------------------
: > "$W/changes"
_pfp=''; _pt=''; _pc=''
while IFS='	' read -r _t _c _k _l _f _r _fp; do
  _ct=$(sed -n 's/^T=//p' "$OUT/.cache/data/$_fp.meta"); _cc=$(sed -n 's/^C=//p' "$OUT/.cache/data/$_fp.meta")
  if [ -n "$_pfp" ]; then
    TZ=UTC0 git -C "$P" log --first-parent --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%h%x09%cd%x09%s' "$_pc..$_cc" 2>/dev/null > "$W/commits" || : > "$W/commits"
    LC_ALL=C awk -F'\t' -v win="$_f" -v t0="$_pt" -v t1="$_ct" -v prev="$OUT/.cache/data/$_pfp.facts" -v cur="$OUT/.cache/data/$_fp.facts" -v cm="$W/commits" "$AWKAT""$AWKJS"'
      function out(kind, ids, at, extra, caps) { print "{\"kind\":" js(kind) ",\"ids\":" ja(ids, ",") ",\"at\":" jn(at) extra ",\"capabilities\":" ja(caps, ",") ",\"window\":" js(win) "}" }
      function capsof(list,   n, a, i, o, c, m, cc, q, s) { n = split(list, a, /[ ,]+/); o = ""; split("", s)
        for (i = 1; i <= n; i++) { c = (a[i] in PC) ? PC[a[i]] : ((a[i] in XC) ? XC[a[i]] : ""); m = split(c, cc, ","); for (q = 1; q <= m; q++) if (cc[q] != "" && !(cc[q] in s)) { s[cc[q]] = 1; o = o (o == "" ? "" : ",") cc[q] } } return o }
      # v0.26.10.2 (R9): an architecture row (AR) added, removed, or with a field (AF) that differs
      function anl(s) { return s == "\034" ? "null" : js(s) }
      function aout(w, part, key, text, extra) { print "{\"kind\":\"architecture\",\"ids\":[" js(key) "],\"at\":null,\"what\":" js(w) ",\"part\":" js(part) ",\"text\":" js(text) extra ",\"capabilities\":[],\"window\":" js(win) "}" }
      BEGIN { while ((getline l < prev) > 0) { split(l, f, "\t"); if (f[1] == "P") OS[f[2]] = f[3]; else if (f[1] == "AR") { OAR[f[2], f[3]] = 1; OARO[++noa] = f[2] "\t" f[3]; OAT[f[2], f[3]] = f[4] } else if (f[1] == "AF") OAF[f[2], f[3], f[4]] = f[5]; else OH[f[1], f[2]] = f[3] }
        while ((getline l < cur) > 0) { split(l, f, "\t"); if (f[1] == "P") { NS[f[2]] = f[3]; PC[f[2]] = f[4]; PO[++np] = f[2] }
          else if (f[1] == "AR") { NAR[f[2], f[3]] = 1; NARO[++nna] = f[2] "\t" f[3]; NAT[f[2], f[3]] = f[4] } else if (f[1] == "AF") { NAF[f[2], f[3], f[4]] = f[5]; NAFN[f[2], f[3]] = NAFN[f[2], f[3]] " " f[4] }
          else { NH[f[1], f[2]] = f[3]; XO[++nx] = f[1] "\t" f[2]; XA[f[1], f[2]] = f[4]; XC[f[2]] = f[5]; XT[f[1], f[2]] = f[6] } }
        for (i = 1; i <= np; i++) { id = PO[i]; fr = (id in OS) ? OS[id] : "new"; if (fr != NS[id]) out("promise state", id, "", ",\"from\":" js(fr) ",\"to\":" js(NS[id]), PC[id]) }
        for (id in OS) if (!(id in NS)) out("promise state", id, "", ",\"from\":" js(OS[id]) ",\"to\":\"removed\"", "")
        for (i = 1; i <= nx; i++) { split(XO[i], f, "\t"); k = f[1] SUBSEP f[2]; if ((k in OH) && OH[k] == NH[k]) continue
          out("decision", f[2], (f[1] == "A" ? XA[k] : ""), ",\"text\":" js(XT[k]), XC[f[2]]) }
        for (i = 1; i <= nna; i++) { split(NARO[i], f, "\t"); k = f[1] SUBSEP f[2]; if (!(k in OAR)) { aout("added", f[1], f[2], NAT[k], ""); continue }
          fl = ""; n = split(NAFN[k], fn, " "); for (j = 1; j <= n; j++) { if (fn[j] == "") continue; a = OAF[f[1], f[2], fn[j]]; b = NAF[f[1], f[2], fn[j]]
            if (a != b) fl = fl (fl == "" ? "" : ",") "{\"name\":" js(fn[j]) ",\"from\":" anl(a) ",\"to\":" anl(b) "}" }
          if (fl != "") aout("changed", f[1], f[2], NAT[k], ",\"fields\":[" fl "]") }
        for (i = 1; i <= noa; i++) { split(OARO[i], f, "\t"); k = f[1] SUBSEP f[2]; if (!(k in NAR)) aout("removed", f[1], f[2], OAT[k], "") }
        while ((getline l < cm) > 0) { split(l, f, "\t"); out("commit", f[1], f[2], ",\"text\":" js(f[3]), "") }
        FS = " " }
      { t = lastat(); if (t == "" || t <= t0 || t > t1) next }
      $1 == "verdict" && kv("row") != "" && kv("result") != "" { r = kv("row"); b = kv("brief"); k = r SUBSEP b; res = (kv("result") == "KEPT") ? "kept" : "broken"; c = kv("class"); if (c == "") c = "-"
        if (!(k in VR)) { VO[++nv] = k; VR[k] = res; VT[k] = t; VC[k] = c; VW[k] = r } else if (res == "broken") VR[k] = "broken"; next }
      $1 == "plan-change" { w = qv("why"); ids = ""; s = w; while (match(s, /(S[0-9][0-9]+|ROW-[0-9]+|REQ-[0-9]+|INV-[0-9]+)/)) { ids = ids (ids == "" ? "" : ",") substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) }
        out("plan", ids, t, ",\"what\":" js(kv("what")) ",\"why\":" js(w), capsof(ids)); next }
      $1 == "step-start" && kv("step") != "" && !(kv("step") in SEEN) { SEEN[kv("step")] = 1; out("step", kv("step"), t, ",\"what\":\"started\"", ""); next }
      $1 == "step-closed" && kv("step") != "" { out("step", kv("step"), t, ",\"what\":\"closed\"", ""); next }
      $1 == "question" && kv("n") != "" { g = kv("gates"); gsub(/,/, ", ", g); out("question", "Q" kv("n"), t, ",\"what\":" js(kv("state")) ",\"text\":" js("Q" kv("n") " " kv("state") (g != "" ? " · gates " g : "")), ""); next }
      END { for (i = 1; i <= nv; i++) { k = VO[i]; out("review", VW[k], VT[k], ",\"result\":" js(VR[k]) ",\"class\":" js(VC[k]), PC[VW[k]]) } }' "$EVF" > "$W/ch.$_fp"
  else : > "$W/ch.$_fp"; fi
  cat "$W/ch.$_fp" >> "$W/changes"
  _pfp=$_fp; _pt=$_ct; _pc=$_cc
done < "$W/snapfp"

# --- pages (R9): each snapshot's file assembled from its data, its neighbours and the page ------------------
awk "$AWKAT"' $1 == "delegated" && kv("answer") != "" { print kv("answer") }' "$EVF" | LC_ALL=C sort -u > "$W/delegated"
PAGEH=$(cat "$PAGE" "$RUNTIME" "$LIB" "$LIBDOM" "$VIEWER/view.sh" | hashof)
# meta.snapshots: every snapshot, oldest first
awk -F'\t' "$AWKJS"' { ms = ""; n = split($3, k, ","); for (i = 1; i <= n; i++) ms = ms (i > 1 ? "," : "") js(k[i]); c = substr($2, 1, 7)
    printf "%s{\"label\":%s,\"moment\":{\"commit\":%s,\"time\":%s},\"milestones\":[%s],\"file\":%s,\"replayed\":%s,\"requested\":%s}", (NR > 1 ? "," : ""), js($4), js(c), js($1), ms, js($5), ($3 == "now" ? "false" : "true"), ($6 == 1 ? "true" : "false") }' "$W/snapfp" > "$W/snapsjson"
assemble() { # <i> <file> <mode>
  _i=$1; _file=$2; _mode=$3
  _row=$(sed -n "${_i}p" "$W/snapfp"); _t=$(printf '%s' "$_row" | cut -f1); _c=$(printf '%s' "$_row" | cut -f2); _k=$(printf '%s' "$_row" | cut -f3); _l=$(printf '%s' "$_row" | cut -f4); _f=$(printf '%s' "$_row" | cut -f5); _r=$(printf '%s' "$_row" | cut -f6); _fp=$(printf '%s' "$_row" | cut -f7)
  _b="$OUT/.cache/data/$_fp"
  _mt=$(sed -n 's/^T=//p' "$_b.meta"); _mc=$(sed -n 's/^C=//p' "$_b.meta"); _made=$(sed -n 's/^madeAt=//p' "$_b.meta")
  nb() { [ "$1" -ge 1 ] && [ "$1" -le "$NSNAP" ] || { printf 'null'; return; }; sed -n "${1}p" "$W/snapfp" | awk -F'\t' "$AWKJS"' { printf "{\"label\":%s,\"time\":%s,\"commit\":%s,\"file\":%s}", js($4), js($1), js(substr($2, 1, 7)), js($5) }'; }
  _prev=$(nb $((_i - 1))); if [ "$_mode" = index ]; then _next=null; else _next=$(nb $((_i + 1))); fi
  _repl=false; [ "$_k" = now ] || _repl=true; [ "$_mode" = index ] && _repl=false
  _req=false; [ "$_r" = 1 ] && _req=true
  _nowonly=false; [ "$_k" = now ] || _nowonly=true
  _nr='[]'; if [ -z "$RECV" ]; then _nr='["delegated","built"]'; else _nr=$( { [ "$RECV" -lt 19 ] && echo delegated; [ "$RECV" -lt 10 ] && echo built; } | awk "$AWKJS"' { o = o (o == "" ? "" : ",") js($0) } END { print "[" o "]" }'); fi
  _ms=$(printf '%s' "$_k" | awk -F, "$AWKJS"' { for (i = 1; i <= NF; i++) o = o (i > 1 ? "," : "") js($i); print o }')
  _rule="gated evidence, line-level staleness (the plugin's own reader, ViD $VIDV)"
  { printf '{"viewer-data":%s,\n"meta":' "$DATAV"
    printf '%s' "$TITLE" | awk -v t="$_mt" -v c="$(printf '%s' "$_mc" | cut -c1-7)" -v made="$_made" -v vid="$VIDV" -v rec="${RECV:-null}" -v rule="$_rule" -v repl="$_repl" -v req="$_req" -v mode="$_mode" -v fp="$_fp" -v prev="$_prev" -v next_="$_next" -v ms="$_ms" -v nowonly="$_nowonly" -v nr="$_nr" -v lab="$_l" "$AWKJS"' { name = $0 }
      END { printf "{\"project\":%s,\"label\":%s,\"moment\":{\"commit\":%s,\"time\":%s},\"milestones\":[%s],\"madeAt\":%s,\"vid\":%s,\"records\":%s,\"evidenceRule\":%s,\"replayed\":%s,\"requested\":%s,\"mode\":%s,\"fingerprint\":%s,\"previous\":%s,\"next\":%s,\"nowOnly\":%s,\"notRecorded\":%s,\"snapshots\":[", js(name), js(lab), js(c), js(t), ms, js(made), js(vid), rec, js(rule), repl, req, js(mode), js(fp), prev, next_, nowonly, nr }'
    cat "$W/snapsjson"; printf ']},\n'
    # the delegated marks: an answer live at this commit is delegated when any delegated event names it
    awk -v df="$W/delegated" 'BEGIN { while ((getline l < df) > 0) D[l] = 1 }
      /^,?\{"id":"A-[0-9]+","amended":/ { id = $0; sub(/^,?\{"id":"/, "", id); sub(/".*/, "", id); if (id in D) { sub(/"delegated":false\}$/, "\"delegated\":true}"); L = L (L == "" ? "" : ",") "\"" id "\"" } }
      { lines[++n] = $0 } END { for (i = 1; i <= n; i++) { if (lines[i] == "\"delegated\":[\"@VID-DELEGATED@\"]},") lines[i] = "\"delegated\":[" L "]},"; print lines[i] } }' "$_b.json"
    printf '"changes":['
    if [ "$_mode" = index ]; then awk '{ printf "%s%s\n", (NR > 1 ? "," : ""), $0 }' "$W/changes"; else awk '{ printf "%s%s\n", (NR > 1 ? "," : ""), $0 }' "$W/ch.$_fp"; fi
    printf ']}\n'; } > "$W/data.json"
  # the canvases this snapshot's screens name, each once — v0.9.8.1 (R23): each canvas is written once, as the local
  # script asset canvases/<its cache key>.js beside the snapshots, which a snapshot loads by <script src> (file://
  # loads it, offline, and a copied folder keeps it); a changed canvas is a new key, so an older snapshot keeps its own
  mkdir -p "$OUT/canvases"; : > "$W/cvsrc"
  { printf 'window.VID_CANVASES={'; _n=0
    while IFS='	' read -r _nm _key; do
      grep -q "\"canvas\":\"$(printf '%s' "$_nm" | sed 's/[][\.*^$/]/\\&/g')\"" "$W/data.json" || continue
      _af="$OUT/canvases/$_key.js"
      [ -f "$_af" ] || { { printf 'window.VID_CANVAS_FILES=window.VID_CANVAS_FILES||{};window.VID_CANVAS_FILES["%s"]=' "$_key"; cat "$OUT/.cache/blob/$_key.canvas"; printf ';\n'; } > "$_af.tmp" && mv "$_af.tmp" "$_af"; }
      printf '<script src="canvases/%s.js"></script>\n' "$_key" >> "$W/cvsrc"
      [ "$_n" -gt 0 ] && printf ','; _n=$((_n + 1))
      printf '%s' "$_nm" | awk "$AWKJS"' { printf "%s:", js($0) }'; printf 'window.VID_CANVAS_FILES["%s"]' "$_key"
    done < "$_b.canvases"; printf '};'; } > "$W/canvases.js"
  _key=$( { printf '%s\n' "$PAGEH"; cat "$W/data.json" "$W/canvases.js"; } | hashof)
  if [ -f "$OUT/$_file" ] && [ "$(cat "$OUT/.cache/pages/$_file.key" 2>/dev/null)" = "$_key" ]; then return 0; fi
  # the design's page, its three script lines replaced by the inline runtime, data and canvases (kind 1)
  awk -v lib="$LIB" -v libdom="$LIBDOM" -v rt="$RUNTIME" -v data="$W/data.json" -v cvs="$W/canvases.js" -v cvsrc="$W/cvsrc" '
    function cat_(f,   l) { while ((getline l < f) > 0) print l; close(f) }
    function catd(f,   l, o, first) { first = 1; while ((getline l < f) > 0) { if (!first) printf "\n"; printf "%s", l; first = 0 } close(f) }
    $0 == "<script src=\"./support.js\"></script>" && !done_ { done_ = 1
      print "<script>window.__resources={};</script>"; printf "<script>"; cat_(lib); print "</script>"; printf "<script>"; cat_(libdom); print "</script>"
      printf "<script>window.VID_DATA="; catd(data); print ";</script>"
      cat_(cvsrc); printf "<script>"; catd(cvs); print "</script>"
      printf "<script>"; cat_(rt); print "</script>"; next }
    { gsub(/<script src="\.\/viewer-data\.js"><\/script><script src="\.\/canvases\.js"><\/script>/, ""); print }' "$PAGE" > "$OUT/.$_file.tmp" && mv "$OUT/.$_file.tmp" "$OUT/$_file"
  printf '%s\n' "$_key" > "$OUT/.cache/pages/$_file.key"
  NWROTE=$((NWROTE + 1))
}
NWROTE=0
i=1; while [ "$i" -le "$NSNAP" ]; do assemble "$i" "$(sed -n "${i}p" "$W/snapfp" | cut -f5)" snapshot; i=$((i + 1)); done
assemble "$NSNAP" index.html index
_el=$(( $(date +%s) - STARTED ))
if [ "$NMADE" -eq 0 ] && [ "$NWROTE" -eq 0 ]; then echo "ViD view: nothing new — $NSNAP snapshot(s) in $OUT, unchanged ($_el s)"; exit 0; fi
echo "ViD view: made $NMADE snapshot(s)' data and wrote $NWROTE page(s) of $NSNAP snapshot(s) and the index, in $_el s — $OUT/index.html"
exit 0
