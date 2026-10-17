# two-round (v0.9.1 3.3, class b): round 1 drew P02 (receipt) and P03
# (deletion page), both with the footer address support@shortlink.example;
# round 2's DELTA redraws P03 with help@shortlink.example. The PRD says
# only "a support address that reaches a person" (REQ-013) — the detail
# is PRD-silent, so no row is contradicted, but the pack now contradicts
# itself: one element (the support footer) drawn two ways on two
# canvases. Exactly one line, the delta marker first, the unchanged
# marker second, `canvas says … · canvas says …`. P02 is context and is
# never a finding's target on its own.
count line = 1
exists line marker~P03/default target~P02/default canvas~help@ row~support@
absent line marker!~P03/default
