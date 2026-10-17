# harness-config (v0.9.2 3.13, R22): the harness provisions sender_name and
# brand_colour directly by fixture; REQ-021 (A-007) makes both operator-
# entered at setup, and no row provisions them. Expected: one difference
# row per value (or one naming both) with the gate-2 paying step — the
# product, provisioned by its own path, serves the ratified value — and
# the surface rows of P01 still derived, none deferred for provisioning.
# The phase-deploy expectations hold too (REQ-007's two rows, REQ-020 nothing).
exists difference row~sender.name|sender_name row~paying-step:.staging
exists difference row~paying-step:.staging
count difference row~paying-step:.staging >= 1
exists ROW kind=surface subject~P01|/ derived-from~REQ-021
count ROW kind=surface >= 2
absent ROW kind=surface test~prerequisite|provision
exists ROW derived-from~REQ-007 test~^owed:.paid.by./vid.deploy.gate.2
exists ROW derived-from~REQ-007 test!~deploy
absent ROW derived-from~REQ-020
