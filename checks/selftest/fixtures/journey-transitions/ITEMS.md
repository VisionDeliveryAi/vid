# Boardlet — the effective items the batch derives from (fixture: journey-transitions)

REQ-020 | functional | tier 1 | A signed-in member applies to a role from its detail page with one control; the page then shows "Application sent". fail-if: applying records nothing, or records more than one application, or the page shows no confirmation.
REQ-021 | functional | tier 1 | A member withdraws an application from the role's page; the role is then open to apply again. fail-if: withdrawing leaves the application recorded, or a role never applied to can be "withdrawn".
REQ-022 | functional | tier 2 | "My applications" lists the member's current applications. fail-if: a withdrawn application is listed, or another member's is.
REQ-023 | constraint | tier 1 | One application per member per role. fail-if: a second application to the same role is accepted.
