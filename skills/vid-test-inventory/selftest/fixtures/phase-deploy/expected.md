# phase-deploy (v0.9.1 3.6): REQ-007 is a pilot Tier-0 item with one arm the
# harness observes (the product's own record is deleted only after the
# provider confirms) and one arm only the real mail provider can show (the
# address erased from the provider's suppression and contact stores) — the
# seam carries credentials: not-yet. REQ-020 is `later`. Expected: REQ-007
# derives its ordinary ledger row(s) AND one row born owed: paid by /vid
# deploy gate 2 naming what the rung observes; REQ-020 derives nothing —
# no behavior row, no trigger row, no surface row.
exists ROW derived-from~REQ-007 test~^owed:.paid.by./vid.deploy.gate.2
exists ROW derived-from~REQ-007 test!~deploy
absent ROW derived-from~REQ-020
absent ROW subject=REQ-020
absent ROW obligation~send.hour
