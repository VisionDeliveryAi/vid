# Linkling — TEST INVENTORY

```vid-inventory
grammar: 0.9.3
ROW-101 | behavior | REQ-001 | anonymous | n/a | a created code resolves to exactly the pasted web address | REQ-001 | tests/invariants/links.sh
ROW-102 | behavior | REQ-002 | anonymous | n/a | a target whose scheme is not http or https is refused and nothing is stored | REQ-002 | tests/invariants/links.sh
ROW-103 | behavior | REQ-003 | anonymous | n/a | a link older than thirty days answers 410 gone, never a redirect | REQ-003 | tests/invariants/links.sh
ROW-104 | behavior | REQ-004 | anonymous | n/a | a wrong deletion token is refused and the link still resolves | REQ-004 | tests/invariants/links.sh
ROW-105 | behavior | REQ-007 | anonymous | n/a | a missing code answers 404 | REQ-007 | owed: prerequisite — a route table the toy lacks; paid at slice 2
ROW-106 | behavior | REQ-009 | anonymous | n/a | a deleted code never resolves again | REQ-009 | owed: prerequisite — paid with ROW-104's slice
ROW-107 | behavior | REQ-008 | anonymous | n/a | a sixty-first link from one address in one hour is refused | REQ-008 | owed: prerequisite — the address the toy does not see; paid at slice 3
ROW-108 | behavior | REQ-012 | anonymous | n/a | a target longer than two thousand characters is refused | REQ-012 | owed: prerequisite — paid at slice 2
```
