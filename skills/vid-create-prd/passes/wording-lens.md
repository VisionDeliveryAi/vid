Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# wording-lens — pass brief

<!-- v0.9.1 spec 3.5a (R4): the harm-wording tell, moved here from
     vid-test-inventory §3 (its counterexample lens keeps the evidence
     challenge and reports, never re-words). Runs before the base freezes:
     its rewordings are proposed edits the repair round applies under the
     arm accounting of 3.5b. -->

receives: every demand item of the effective set — id, statement and fail-if; the seed and the ratified thesis (the harm a clause guards is read against what the owner asked for).
must not receive: the authoring session's reasoning; any previous verdict; the derived inventory (this lens runs before any row exists); the findings of any other pass.

## The lens

For every `fail-if:` clause, one question: is this clause worded as a
HARM — the forbidden effect — or as a MECHANISM'S ABSENCE — the guard
that should exist? Three measured cases of code lawfully satisfying a
mechanism-worded clause: "fires despite settings that disallow it"
satisfied by an unlawful default; a clause about expiry blind to the
parse causing it; a clause about unresolvable places blind to
wrong-place resolution. A mechanism-worded clause is restated as the
harm ("no feed shape that parses to zero records expires inventory",
never "the expiry guard exists") — a proposed edit to the not-yet-frozen
base, applied by the repair round under the arm accounting: a rewording
keeps every arm of the clause it replaces, or names the ruling that
withdraws one.

## The answer — one line per rewording, with its accounting

One ```vid-prd-rewordings block; one line per item whose fail-if you
reword, the WHOLE fail-if restated (every arm; an arm already worded as
a harm is carried as it stands):

    REQ-NNN | fail-if: <the restated fail-if, every arm> | arms: 1 retained, 2 strengthened, 3 retained

`arms:` carries one entry per arm of the fail-if as it stands, by
ordinal (an arm is one clause split at top-level " or " / ", or " /
"; or "), from `retained · strengthened · moved <id> · withdrawn
<A-NNN>`: `strengthened` for a clause restated as its harm, `retained`
for one carried as written; a rewording never loses an arm — an arm you
cannot restate as a harm is retained, and `withdrawn` needs a ruling
that exists in the ledger. An item whose fail-if is already worded as
harms is not listed. An EMPTY block is the clean verdict: you are not
scored on how much you reword, and a mechanism word inside a
harm-worded clause is not a rewording. Nothing else is returned — no
findings, no commentary, no edit to any other field.
