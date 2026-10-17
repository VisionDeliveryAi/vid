# {{PROJECT_NAME}} — DECISIONS

Append-only, except labels. One line per decision. Trigger (law in
CLAUDE.md): the choice picked between plausible alternatives, constrains
future code, or would surprise a competent newcomer. Entries without an
`| enforced:` ref, or without a label, are rejected at commit.

Format:

    - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention"> | applies-to: <ids and codes> [| origin: proposal] [| model: <id>]
    - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention"> | scope: project [| origin: proposal] [| model: <id>]

The label says where a brief quotes the decision. `applies-to:` items,
comma separated: ROW, RULE or REQ ids of INVENTORY.md; screen codes (the
part before `/` of an INVENTORY marker); DIF ids, when rows carry a
`divergence:` field. `scope: project` only when it bears on many areas. A
commit may change a line's label and nothing else; that is the one edit
this file allows.

`origin: proposal` marks defaults the model chose when the owner skipped a
hint or delegated the choice. `model:` is optional (§9 model-change
durability): record it when the deciding model differs from the project's
usual one, so a later model can see what it inherits.

## Log

- **D-001** {{FIRST_DECISION}} | why: {{WHY}} | enforced: {{REF}} | {{LABEL}}
