# configured-value (v0.9.2 3.13, R22 — class c): the deletion page's footer
# draws the support address as the literal support@shortlink.example.
# REQ-025 (A-006) makes that address operator-entered at deployment, so
# the canvas asserts a configuration value the PRD makes an input.
# Exactly one line, naming P03/default and REQ-025 (or A-016), with the
# literal in the canvas field; the rest of the canvas is what the rows
# demand plus PRD-silent details — none of them a disagreement.
count line = 1
exists line marker~P03/default target~REQ-025|A-016 canvas~support@shortlink.example
absent line marker!~P03/default
