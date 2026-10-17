# The scripted owner's answers (the work package, §7 case 15)

The evaluator writes these BEFORE the run and changes none of them during
it; a session that asks a product question not answered here is answered
"no ruling — decide technically and log it" and the question is counted.

## /vid init — the technical foundation

- The stack: **the evaluator's choice, written here before the run**:
  `STACK: ____________________` (language, web framework, queue library,
  scheduler, database, test runner, browser engines).
- Hosting: none yet; staging and production are chosen at the first
  deploy.
- A design pass: none — the owner's answer is "plain pages the builder
  writes; no design round for this package".
- Every derived inventory row: ratified as derived, at recognition speed.
- `.vid/budget`: the defaults.

## Mid-run answers

- (d), between slices 2 and 3, as the owner's append to PRD.md under
  `## Appends`:

  ```vid-prd
  REQ-013 AMENDED | functional | T1 | P1 | A listing absent from both feeds for five consecutive days is removed from the store. | fail-if: a listing missing from every feed for more than five days is still shown in a digest or a search | serves: the store stays current — stale listings read as a broken product | authority: authoritative | source: owner answer (work package seed d) | covers: DIM-feed-trust | arms: 1 strengthened
  ```

- OQ-1 (the send hour): "one fixed hour, 06:00, for everyone at launch".
