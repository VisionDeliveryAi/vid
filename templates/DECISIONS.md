# {{PROJECT_NAME}} — DECISIONS

Append-only, except labels and replaced-by marks. One line per decision.
Trigger (law in CLAUDE.md): the choice picked between plausible
alternatives, constrains future code, or would surprise a competent
newcomer. Entries without an `| enforced:` ref, or without a label, are
rejected at commit.

Format:

    - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention"> | applies-to: <ids and codes> [| origin: proposal] [| model: <id>]
    - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention"> | scope: project [| origin: proposal] [| model: <id>]

`why:` gives the reason in ViD's own words and cites the answer it rests
on (`A-NNN`), never the owner's words, which stay in the commit's `Owner:`
trailer (vid-create-prd, "The owner's words, and the questions raised").

The label says where a brief quotes the decision. `applies-to:` items,
comma separated: ROW, RULE or REQ ids of INVENTORY.md; screen codes (the
part before `/` of an INVENTORY marker); DIF ids, when rows carry a
`divergence:` field; module ids of ARCHITECTURE.md's module table (its
Module column, a dotted label read as a path). A decision that bears on
one module, or a few, names them beside its row, requirement or screen
items, never instead of them: a module item reaches only the briefs of
builders whose step names the module, and graders, test authors and
fixers join by rows. `scope: project` only when it bears on many areas.

A line a later decision replaces, whole or in part, is marked, and only
marked: `| replaced-by: D-NNN[, D-MMM]` in its rule part, right before
` | why:`, ids in the order added. Where the lines differ, the named lines
win; the old line's words stay as written, and wherever it is quoted the
lines it names follow it. A commit may change a line's label, or add its
`replaced-by:` mark, or add a D-id to the mark it has, keeping the ids
already there, and nothing else; that is the one edit this file allows.

`origin: proposal` marks defaults the model chose when the owner skipped a
hint or delegated the choice. `model:` is optional (§9 model-change
durability): record it when the deciding model differs from the project's
usual one, so a later model can see what it inherits.

`origin: dev-side` marks a decision the dev side made in ticket mode,
recorded by ViD in the dev side's words from a merged pull request's
Decisions section (`enforced: ticket <n>`) or a deploy report's
`decision:` lines (`enforced: deploy <id>`, `scope: project`).

## Log

- **D-001** {{FIRST_DECISION}} | why: {{WHY}} | enforced: {{REF}} | {{LABEL}}
