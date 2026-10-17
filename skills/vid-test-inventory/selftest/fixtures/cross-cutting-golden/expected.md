# D-5 — cross-cutting: one row per named surface
exists ROW derived-from~REQ-005 subject=ingest
exists ROW derived-from~REQ-005 subject=digest-selection
exists ROW derived-from~REQ-005 subject=console
count ROW derived-from~REQ-005 >= 3
# a derives: golden-set item cites its golden fixture under tests/invariants/
exists ROW derived-from~REQ-003 row~golden
exists ROW derived-from~REQ-003 row~tests/invariants/
# a guard/never row (no digest after unsubscribe) has its control sibling
exists ROW derived-from~REQ-002 obligation~^control.of.ROW-
