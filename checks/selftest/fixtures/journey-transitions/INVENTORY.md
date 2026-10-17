# Boardlet — Test Inventory (fixture: journey-transitions, v0.9.2 3.5)

The batch a test-author pass receives: one journey row with four `transitions:` and four behavior rows of the same domain (applications). The rows cite the files the pass will produce.

```vid-inventory
grammar: 0.9.2
ROW-010 | journey | member applies to a role and withdraws | member | n/a | A signed-in member finds a role, applies, withdraws, and sees no application listed. transitions: 1. member at P02/default · the role card's View link · press · P03/default · the role's detail page shows the role title; 2. member at P03/default · the Apply control · press · P03/applied · the notice "Application sent" is shown and the Apply control is gone; 3. member at P03/applied · the Withdraw control · press · P03/default · the notice is gone and the Apply control is back; 4. member at P03/default · the My applications nav link · press · P04/default · the list shows no application | REQ-020,REQ-021,REQ-022 | tests/invariants/journeys.sh | origin: derived
ROW-011 | behavior | REQ-020 | member | n/a | applying to a role records exactly one application for that member and role, answered as created | REQ-020 | tests/invariants/applications.sh | origin: derived
ROW-012 | behavior | REQ-023 | member | n/a | a second application to the same role is refused as a conflict and the count stays one | REQ-023 | tests/invariants/applications.sh | origin: derived
ROW-013 | behavior | REQ-021 | member | n/a | withdrawing removes the application; withdrawing a role never applied to is refused as not found | REQ-021 | tests/invariants/applications.sh | origin: derived
ROW-014 | behavior | REQ-022 | member | n/a | the applications list answers the member's current applications and nothing else | REQ-022 | tests/invariants/applications.sh | origin: derived
```
