#!/bin/sh
# Purpose: the decision-label join (0.26.10.29.3, R7, F32), once — the commit hook (checks/hooks/pre-commit, 4c) and the
# labelling pass (checks/decisions.sh propose and apply) both load it, so the pass selects every labelled line the hook
# would refuse and never writes a label the hook would refuse. The hook loads checks/labels.sh from the project's root,
# decisions.sh the copy beside itself; loaded, it defines and runs nothing else.
#   label_items <inventory file> <architecture file>   the items a brief can join a label on, one a line, sorted: an
#       INVENTORY row's ROW id, the REQ ids of its derived-from, the screen codes of its marker (the part before `/`), the
#       DIF ids its divergence: fields name, the rule rows' RULE ids; and the module ids of the first table of the
#       architecture file with a Module column (a dotted label read as a path). A file that is absent gives nothing.
#   label_bad <items file>   decision lines on standard input; prints each one the hook refuses — four spaces and the
#       line, then each reason on its own line, six spaces in: no label, more than one, `scope:` other than project,
#       `applies-to:` naming nothing or an item no brief joins on (a DIF id while no row carries a divergence: field).
# serves: both
label_items() {
  { [ -f "$1" ] && sed -n '/^```vid-inventory/,/^```$/p' "$1" | sed '1d;$d' | awk -F'|' '
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { id = tr($1)
      if (id ~ /^ROW-[0-9]+$/) { print id
        n = split(tr($7), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] ~ /^REQ-[0-9]+$/) print a[k]
        n = split(tr($5), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && index(a[k], "/") > 1) print substr(a[k], 1, index(a[k], "/") - 1)
        for (i = 8; i <= NF; i++) { f = tr($i); if (f ~ /^divergence:/) { sub(/^divergence:[ \t]*/, "", f); n = split(f, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] ~ /^DIF-[0-9]+$/) print a[k] } } }
      else if (id == "rule" && tr($2) ~ /^RULE-[0-9]+$/) print tr($2) }' | sort -u; } 2> /dev/null || true
  { [ -f "$2" ] && awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^[ \t]*\|/ { if (done) next; if (!intab) { intab = 1; if (!col) { n = split($0, c, "|"); for (k = 2; k < n; k++) if (tr(c[k]) == "Module") col = k } next }
        if (!col || $0 ~ /^[ \t]*\|[ \t:|-]*$/) next; split($0, c, "|"); m = c[col]; gsub(/`/, "", m); m = tr(m)
        if (m == "" || index(m, "{{") == 1 || m == "Module") next; if (m !~ /\// && m ~ /\./) gsub(/\./, "/", m); print m; next }
      { if (intab && col) done = 1; intab = 0 }' "$2"; } 2> /dev/null || true
}
label_bad() {
  grep -v '^$' | awk -F'|' -v jf="$1" '
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN { while ((getline l < jf) > 0) { J[l] = 1; if (l ~ /^DIF-/) dif = 1 } }
    { line = $0; a2 = ""; sc = ""; na = 0; ns = 0
      for (i = 2; i <= NF; i++) { f = tr($i)
        if (f ~ /^applies-to:/) { na++; sub(/^applies-to:[ \t]*/, "", f); a2 = f }
        else if (f ~ /^scope:/) { ns++; sub(/^scope:[ \t]*/, "", f); sc = f } }
      if (na + ns == 0) { print "    " line "\n      no label: add `| applies-to: <ids and codes>` or `| scope: project`"; next }
      if (na + ns > 1) { print "    " line "\n      more than one label: a decision carries one"; next }
      if (ns) { if (sc != "project") print "    " line "\n      scope: takes only `project`"; next }
      n = split(a2, it, /[ ,]+/); bad = ""; k2 = 0
      for (k = 1; k <= n; k++) { x = it[k]; if (x == "") continue; k2++
        if (x in J) continue
        if (x ~ /^DIF-[0-9]+$/ && !dif) bad = bad "\n      " x ": no INVENTORY row carries a divergence: field, so nothing could join a DIF label"
        else if (x ~ /^(ROW|REQ|RULE|DIF)-[0-9]+$/) bad = bad "\n      " x ": not an id a brief joins on (INVENTORY row ids, their derived-from REQ ids, rule-row ids, divergence: DIF ids)"
        else bad = bad "\n      " x ": not a screen code any INVENTORY row marks, nor a ROW, RULE, REQ or DIF id, nor a module id of ARCHITECTURE.md" }
      if (!k2) bad = "\n      applies-to: names nothing"
      if (bad != "") print "    " line bad }'
}
