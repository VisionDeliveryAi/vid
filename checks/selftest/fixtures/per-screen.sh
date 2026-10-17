# Purpose: selftest fixture — a design pack for the per-screen layout cases (v0.9.8.1 R20). Sourced in a scratch
# directory. ps_pack makes DESIGN-BRIEF.md (grammar 0.9.2; manifest P01 default, P02 default and empty, P03 owed,
# C00 field) and design/screens/: `P01 Home.dc.html`, `P02 Jobs.dc.html`, `C00-forms.dc.html`, each holding its
# markers; ps_index <files…> writes design/screens/index.json declaring the layout, listing those files, P01 and P02
# using C00-forms.dc.html. join: the court on it, its output in $T/out, its exit in JR.
ps_pack() {
  printf '# brief\ngrammar: 0.9.2\n\n```vid-design-manifest\nP01 | default | REQ-001 | pins: the list\nP02 | default | REQ-002 | pins: the rows\nP02 | empty | REQ-002 | pins: the empty note\nP03 | default | REQ-003 | pins: the map | owed: drawn next round\nC00 | field | REQ-001 | pins: the field\n```\n' > DESIGN-BRIEF.md
  mkdir -p design/screens
  printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<div>the list</div>\n' > "design/screens/P01 Home.dc.html"
  printf '<!-- @screen P02 state=default reqs=REQ-002 -->\n<div>rows</div>\n<!-- @screen P02 state=empty reqs=REQ-002 -->\n<div>none</div>\n' > "design/screens/P02 Jobs.dc.html"
  printf '<!-- @screen C00 state=field reqs=REQ-001 -->\n<div>a field</div>\n' > design/screens/C00-forms.dc.html
}
ps_index() { { printf '{\n  "layout": "per-screen",\n  "files": ['; _s=''; for _f in "$@"; do printf '%s"%s"' "$_s" "$_f"; _s=', '; done
  printf '],\n  "components": {"P01": ["C00-forms.dc.html"], "P02": ["C00-forms.dc.html"]}\n}\n'; } > design/screens/index.json; }
join() { JR=0; sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens > "$T/out" 2>&1 || JR=$?; }
