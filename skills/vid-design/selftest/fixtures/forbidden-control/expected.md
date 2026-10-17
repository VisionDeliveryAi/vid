# forbidden-control (v0.9.1 3.3): the deletion page draws an "Edit target"
# control beside Remove. REQ-006 gives the page one Remove control and
# NG-001 rules out editing a link's target; the seed says "no editing".
# Exactly one disagreement line, naming P03/default and the item (REQ-006
# or NG-001 — one control, one line, however many ids it cites). The
# rest of the canvas is what the rows demand plus PRD-silent details
# (a page title, the count's label, a confirm step's wording) — none of
# them a disagreement.
count line = 1
exists line marker~P03/default target~REQ-006|NG-001
absent line marker!~P03/default
