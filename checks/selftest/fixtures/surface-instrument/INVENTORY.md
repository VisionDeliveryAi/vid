# Boardlet — Test Inventory (fixture: surface-instrument, v0.9.2 3.4)

The surface rows a surface test-author pass receives: kind, subject (the route), actor, marker, the obligation with its `pins:`, the items it derives from. The rows cite the ONE instrument the pass produces.

```vid-inventory
grammar: 0.9.2
ROW-001 | shell | / | anonymous | C00/shell-anonymous | the anonymous shell carries the brand link and one primary nav with Jobs and Sign in, on every page | REQ-001 | tests/invariants/shell.sh | origin: derived
ROW-002 | surface | / | anonymous | P01/default | P01/default is transcribed property-for-property and renders without console error for the anonymous actor, with the state's content present and no other state's control shown; pins: the page title present; a search form with one field and one action; the featured grid present | REQ-002,REQ-003 | tests/invariants/surfaces.sh | origin: derived
ROW-003 | surface | / | anonymous | P01/empty | P01/empty (no roles listed) is transcribed property-for-property and renders without console error for the anonymous actor, with the state's content present and no other state's control shown; pins: the empty notice present; no search form | REQ-002 | tests/invariants/surfaces.sh | origin: derived
ROW-004 | surface | /jobs | member | P02/default | P02/default is transcribed property-for-property and renders without console error for a signed-in member, with the state's content present and no other state's control shown; pins: card count = page size; sort control present; salary shown when the record carries one | REQ-004,REQ-005 | tests/invariants/surfaces.sh | origin: derived
```
