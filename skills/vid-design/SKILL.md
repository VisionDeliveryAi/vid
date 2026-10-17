---
name: vid-design
description: Turn an owner-approved design into the ratified visual half of a ViD project's spec. Derives a complete screen/state brief (with its machine manifest) from the PRD; once the brief is written and the session has proven it can see its own drawings, it asks the owner who makes the design — the owner in their own tool from the brief (recommended), or ViD here — and, when it cannot see them, says so and hands over the brief; the verb imports the returned canvases-plus-tokens pack verbatim, reconciles it against the manifest through the fail-closed design-join court, dual-writes the embodied product decisions, and makes the design enforceable — protected path, marker citations, token court, fidelity grading. It drafts design only when the owner chooses that, behind the render-and-see gate. Use when the owner says "vid design", has a design to import or ratify, or asked for a design pass during vid-init.
---

# /vid design

The owner authors; this verb ratifies. It exists to take a design the
owner approves and give it the same standing PRD.md has — the second half
of the spec, enforced by the courts, graded for fidelity. It is not a
designer. Owner-facing and conversational like the init interview, unlike
develop.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In a ViD project — after
init, or inside it (`.vid/` exists) — record
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=design state=start session=$CLAUDE_CODE_SESSION_ID records=1"`
when this verb starts and `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=design state=end session=$CLAUDE_CODE_SESSION_ID"`
when it hands back. This verb can run inside init before the project's
checks/ exists, so it calls the plugin's copy of the helper; every event it
names is written the same way, `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" '<event>'`, which appends
it to `.vid/metrics-events` with its time.

Preconditions: PRD.md exists (it takes the whole spec to know every
screen — otherwise /vid init). The product has a visual surface (an API,
CLI, or library does not — say so plainly and stop). Visual identity is
per project; nothing here is shared across products.

## Capability ledger — what may be promised, and when

Every promise this verb makes to the owner comes from this ledger.
Anything not on it is unverified: verify in-session before promising, or
do not promise. ViD's law — claims stop at evidence — binds this skill's
own statements first.

Field-verified, twice (two independent authoring runs, 2026-08):

- **The handoff is text: HTML canvases (`.dc.html`) plus `tokens.css` —
  zero images in either field pack.** Everything downstream — the join,
  the citation court, the coverage join — is deterministic text
  processing: grep, not judgment, no image reading in any counting path.
- Both packs carried section comments and `{{ placeholders }}` unprompted;
  the marker contract below rides that existing shape.
- The earlier "screenshots are the guaranteed handoff" doctrine is
  RETIRED. Screenshots may still arrive as supplementary reference and may
  be stored, but they satisfy no contract: a pack without canvases cannot
  pass the join, and nothing counts pixels.

Verified against the tool schema:

- DesignSync is a file courier. Its complete method set: `list_projects`
  `get_project` `list_files` `get_file` `create_project` `finalize_plan`
  `write_files` `delete_files` `register_assets` `unregister_assets`
  `report_validate`. There is no generate, prompt, or compose method.
  Nothing this verb touches makes Claude Design draw anything.
- `create_project` creates design-SYSTEM projects only; the type is
  immutable. The generative composer on claude.ai/design makes REGULAR
  projects — a different container, invisible to `list_projects`. A
  composer project's ID can therefore only come from the owner.

Environment-dependent — verify in-session, before promising, never after:

- rendering live HTML to visible pixels (browser pane policies differ;
  one field environment blocked claude.ai, localhost, AND file://
  screenshots — 2026-08-12)
- a connected claude-in-chrome browser (same field session: zero)

Untested — label as untested to the owner if attempted:

- `list_files`/`get_file` against a composer (regular) project.

Standing rules, no exceptions: never present a URL a tool did not
return — never construct one from a project ID. Never hand unverified
renders to the owner as a review artifact. Degraded capability is stated
to the owner once, plainly, before work is planned around it.

## 1. The brief — always the opening move

Read the law: CLAUDE.md → PRD.md (base + Appends, later wins) →
BASELINE.md → ARCHITECTURE.md → DECISIONS.md → INVENTORY.md if it exists
(its shell, reachability, and error-surface rows are surfaces the brief
must carry) → design/ if it exists (later rounds iterate, never restart).
The PRD is typed rows: read the EFFECTIVE set — base plus appends, an
`AMENDED` row superseding every earlier row with its id, for items and
answers alike — and derive the complete screen and state inventory from
typed demand; the one prose section the derivation reads is the journeys
section, for ordering and off-screen phases:

- **`ux_flow` items** give the flow surface directly — each is a screen
  sequence with its states; its `fail-if:` names the branch the drawing
  must show failing gracefully.
- **The `## Actors and journeys` section** gives the ordered walk per
  actor. An `(off_screen)` phase is where the product is absent: the
  brief says so at that step and draws nothing for it — never invent a
  surface for a phase the PRD marked off-screen.
- **`data_entity` items** name what screens display, and what the empty,
  loading, error, and stale states of that entity mean on a screen (a
  state the stack cannot show — a server-rendered surface has no loading
  state — is declared absent, not drawn).
- **`functional` items** supply the remaining screens and, through their
  `fail-if:` clauses, the unhappy branches; confirmation states follow
  from any item whose Fail-if names a silent success — an action that
  happened with nothing on screen saying so.
- **`constraint` and `nfr` items** carry the binding visual constraints
  (theming/white-label, accessibility targets, density, platform).
- **`non_goal` rows** are what the brief must NOT draw — a fenced screen
  in a pack is an "extra" at the join.
- A **`pending`** item's surface is drawn as its carrier states it and
  marked in the brief as awaiting `OQ-n`; a drawing never resolves an
  open decision.

Every screen; empty, loading, error, confirmation, and the unhappy
branches. Write it as DESIGN-BRIEF.md at the repo root, its first line
after the title `grammar: 0.9.2` (the courts read the line: from 0.9.1 on
a manifest row without `pins:` and a manifest without C00's rows refuse
the join; under 0.9.2 a styled canvas element without an identifier is a
join delta, rule 5 below; an earlier brief is reported, never
convicted): the owner's authoring checklist, the spec translated into
"what must exist visually". It promises nothing about tooling.

**The brief return contract** — the shape decides REQ traceability
(field-measured: inline REQs survived the authoring round trip 80/~100;
REQs pooled per screen survived 16/108). Six rules, stated in the brief
itself so the authoring tool sees them:

1. **REQ IDs sit inline with the element they govern** — never pooled per
   screen.
2. **Every screen × state carries a one-line marker in the returned
   artifact**, riding the section-comment shape the tool already emits:

       <!-- @screen P03 state=expired reqs=REQ-016,REQ-038 -->

   Dynamic content as `{{ placeholders }}`; canvas chrome — annotations,
   token swatches, headings — outside the marked blocks.
3. **The pack returns an index**: marker → REQ IDs → states drawn. Under
   the join court its absence fails the import instead of being a dead
   request — a pack without markers fails immediately, with the row list
   naming exactly what is missing.
4. **One components canvas** (v0.9.1 3.7a, R12-iv): *"the pack contains
   one components canvas, `C00 Components.dc.html`, holding the shared
   elements — the shell (header, nav, footer, both auth states, both
   widths), the card, the top bar, overlays, badges, headings — each as
   a section under the ordinary marker with the component as its state:
   `<!-- @screen C00 state=card-default reqs=REQ-046 -->`. A screen
   canvas draws its own content only; where it shows a shared element
   it draws C00's section as-is and does not restyle it; a variant is
   drawn on C00, named as its own state."* No new marker vocabulary:
   C00's rows in the manifest are ordinary rows (`C00 | card-default |
   REQ-046`), the citation a rule block uses is the existing
   `(C00/card-default — REQ-046)`, and the join, citation and coverage
   courts read all of it unchanged. The "may not restyle" rule is
   enforced where it can be measured: the rendered-vs-cited census class
   and the fidelity graders (§5) compare a screen's shared element to
   C00's section, never to another screen. (v0.9.8.1 R20: in a new pack
   the components canvas is written as small group files, rule 6.)
5. **Element identifiers** (v0.9.2 3.4, R20): every canvas element
   carrying an inline style carries a stable identifier attribute,
   `data-element="<role>"`, unique within its section and named for the
   element's role (`featured-grid`, `search-form`, `primary-action`); the
   section root needs none — its marker maps it. The brief states that
   the identifiers are what the ledger measures: the surface instrument
   (a ledger test file per screen for new projects, v0.9.8.1 R18, the
   surface test-author pass's product) maps each identified canvas element to the app element
   carrying the same identifier inside the marker's section and compares
   EVERY property the canvas declares on it — layout, spacing, type,
   colour, radius — in one evaluate, through the measure module the
   rendered census and the graders share (seed/extractors/README.md).
   An element drawn without an identifier is invisible to the instrument
   and visible only to the fidelity grader, which is why
   `sh checks/design-join.sh` reports it as the delta `no identifier`
   under a 0.9.2 brief (a pre-0.9.2 pack is reported, never convicted).
6. **One canvas per screen** (v0.9.8.1 R20; new packs only): *"each
   screen is its own canvas, named by its marker — `P03 <name>.dc.html` —
   holding all its states; the shared components are small group files,
   `C00-<group>.dc.html` (forms, navigation, cards …); and the pack
   carries `design/screens/index.json`: `{"layout": "per-screen",
   "files": [every file of the pack], "components": {"P03": [the
   component files that screen uses]}}`."* The join court runs its
   per-screen checks only under that declared layout — each manifest
   screen other than C00 has its own file (a screen whose rows are all
   owed, descoped, fenced or later needs none), and every file the index
   lists exists — so an existing pack, in one canvas, is judged as
   before. Writers and graders are briefed only their screen's file and
   the component files the index lists for it (`checks/brief.sh`).

**The manifest** — emitted with the brief, spent at import, persisted as
the inventory's surface rows. A ```vid-design-manifest block in
DESIGN-BRIEF.md, one row per required surface × state, each carrying
`pins:` — the two or three measurable properties the row's ledger test
will read, **as constraints, never as illustrative literals** (v0.9.1
3.7b); the brief tells the designer these are what will be measured:

    P03 | expired | REQ-016,REQ-038 | pins: expired notice present; noindex set; a search link resolves
    P02 | populated | REQ-044,REQ-046 | pins: card count = page size; sort control present; salary shown when the record carries one
    C00 | card-default | REQ-046 | pins: logo or fallback; publication age; New within seven days

test-inventory's surface-row derivation writes each row's obligation
from its pins; the consistency pass (§3) reads the pins column.

## 1b. Who makes the design — asked once, after the gate (v0.9.5 3.14, R13)

After the brief and its manifest are written — the brief is derived either
way, since the manifest join needs it — run the render-and-see gate
**first** (Gated alternates, below): render a candidate file in-session and
look at the pixels.

- **The gate passes.** Ask the owner once:

  > **Who makes the design?** (a) You design it in your own tool from this
  > brief. Recommended: it has worked in practice. (b) ViD drafts it here.
  > Quicker to start, but you may reject it on taste.

- **The gate fails.** Ask nothing. Say once, plainly, that ViD cannot see
  its own drawings here, and take (a).

(a) runs §2 as written; (b) runs the session-drafted flow (Gated
alternates) under the same return contract. Record the answer as a
DECISIONS.md entry in the existing form, with no `origin: proposal`:
`- **D-NNN** design made <from the brief in the owner's tool | here in the session> | why: the owner's answer at the design question | enforced: convention`.

## 2. The owner authors — the recommended path

The owner designs from the brief in Claude Design or any tool they
prefer, with that tool's own options and revisions. This verb waits.
What comes back: **HTML canvases plus tokens.css** — the field-verified
handoff. Ask what the owner can produce; screenshots alone cannot pass
the join and are stored only as supplementary reference. A DesignSync
pull of the owner's composer project remains untested (see ledger) —
owner-supplied ID only, framed as an experiment.

### Gated alternates

**Session-drafted design (explicit owner opt-in only).** The session
draws tokens/components/screens in code. Hard gate, proven before
offering: render a candidate file in-session and SEE the pixels. Cannot →
say so once and route to the default flow. If drafts are displayed
through a DesignSync gallery: every file self-contained (inline CSS —
relative stylesheet links render as unstyled raw HTML in the isolated
cards; field-verified 2026-08-12), first line
`<!-- @dsCard group="…" -->`, push changed files only via
`finalize_plan` → `write_files`. Owner rejection on taste is a normal
outcome of this mode, not a malfunction. A session-drafted pack obeys the
same return contract — markers, index, manifest join — as any other.

**Driving the composer through claude-in-chrome.** Legitimate only after
verifying in-session that a browser is connected and the origin loads.
Never assumed, never promised in the skill's name.

## 3. The import gate — the join court, then the delta sitting

Snapshot the returned pack into design/screens/ (verbatim — see §4), then
run the court, not judgment:

    sh checks/design-join.sh

It compares the manifest against the pack's markers and prints the four
delta classes; it exits nonzero while any row is unresolved, and
**ratification cannot close over an unresolved delta**. Sit with the
owner over the delta table — every resolution is an owner act, recorded
in the manifest row:

| Delta | Resolutions (owner, per row) |
|---|---|
| Missing surface | draw it · descope (PRD append) · `owed: <reason>` |
| Missing state | same three |
| Extra (no REQ behind it) | adopt → new REQ + Fail-if + tier · drop · fence — never ratified silently |
| Untraceable (marker, no REQs) | owner names it · session proposes, owner confirms |

The resolved table IS the inventory's surface-row input. Because the gate
forced every gap on day one, the decision to rebuild or approximate can
never be made silently mid-develop.

**Consistency pass (after `design-join.sh` exits clean).** A fresh
context receives each canvas section with its marker, the effective
rows its marker serves (from the manifest's marker→REQ join), the
`## Actors and journeys` section, and the rulings ledger. It reports
DISAGREEMENTS only, defined narrowly: **(a)** a canvas contradicting an
effective row or ruling — it draws what a row forbids, draws a product
rule differently from the row (a count, an ordering, a state's
meaning, who may act), or omits a state or control a row demands;
**(b)** the pack contradicting itself — one element drawn two ways on
two canvases. **A canvas supplying a detail the PRD does not state is
not a disagreement**: it routes to the "decisions embodied" read-back
and lands as a DECISIONS entry, no ruling, unless the read-back finds
it embodies a product rule (then a proposed item, as today). One line
per disagreement: `marker · item id · canvas says · row says`. The
finiteness mandate holds; a clean pack returns a clean verdict.

Spawn `passes/consistency.md` with exactly that — a separate agent, no
session context; the brief's header is the mechanism. It runs at every
import: init's design chain (vid-init §3) and every standalone round. A
standalone round hands it the DELTA canvases plus every existing canvas
section that shares a component or a state with the delta, and C00
always, listed as `context:` — a changed P03 can contradict an
unchanged P07 or C00 on a detail the PRD never states, and the rows
cannot reconstruct that visual baseline; a context marker is never a
finding's target on its own. Record `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" 'tokens slice=0 phase=review n=T'`.

**The sitting.** Present the lines as returned — one per disagreement,
never a count — and the owner rules each: `design wins` · `PRD wins` ·
`both change` · `not a disagreement`. The `not a disagreement` count is
the measure of over-flagging; record it with the round. **A class-(c)
line — a canvas asserting a configuration value the PRD makes an input
(v0.9.2 3.13, R22) — is ruled with the same four values and no other;
the class adds a consequence, never a ruling:** `design wins` — the PRD
is amended in the brief's PRD half, either as a data item plus a
provisioning row (the value is seeded, and a ledger row proves it) or as
an item "the <actor> enters <value> at <step>" whose inventory row is
born `owed: paid by /vid deploy gate 2 — <the entry, observed on
staging>` (the entry is a deploy-time fact); `PRD wins` — the canvas is
amended to the placeholder in the design half and re-imported; `both
change` — the PRD gains the entry item and the canvas is annotated as an
example value; `not a disagreement` — the "decisions embodied"
read-back, as today. The surface instrument measures against the
harness's ratified configuration either way (vid-test-inventory §4.1's
DIF row carries the provisioning obligation). Then write
`DESIGN-AMENDMENT-BRIEF.md` at the repo root (the same home as
DESIGN-BRIEF.md; overwritten per round, history in git), two halves
under one machine block:

    # <project> — design amendment brief (<date> round)

    ```vid-design-amendments
    D-01 | P03/default | REQ-006 | canvas says: an Edit target control beside Remove | row says: one Remove control; NG-001 forbids editing a target | ruling: PRD wins | status: ruled
    ```

    ## (a) Design changes
    - D-01 — P03: remove the Edit target control; the deletion page carries one Remove control only.

    ## (b) PRD amendments
    (the AMENDED rows and their A-rows, as they will land in commit B)

One row per line the pass returned, in the pass's words: `D-NN`, the
delta marker, the item id or the context marker, the two sides,
`ruling:` (`-` until ruled), `status:` — `open` (unruled) · `ruled`
(ruled, its consequence pending) · `landed` (the design change
re-imported and the pass re-run empty; the PRD amendment in commit B; a
`not a disagreement` line lands at its ruling). **(a) design changes**
— every `PRD wins` and `both change` line as an instruction to the
designer, per canvas and marker, in the designer's terms, handed back
before ratification; the pack is re-imported and the pass re-run
(expected empty) when the changes land. **(b) PRD amendments** — every
`design wins` and `both change` line as an AMENDED row plus its A-row
(`source: design <date> <marker>`), carrying the `arms:` accounting of
the wording lens (§4), landing in ratification's commit B with the
rest of the dual-write. **Ratification (§4) cannot close** while a line
is unruled or a design change has not been re-imported — the same
standing as an unresolved join delta: `sh checks/design-join.sh`
refuses a brief with an `open` line or a `PRD wins` / `both change`
line short of `landed`.

Alongside the join, read back **decisions embodied** — every product
decision the design carries (a warning step, an ordering, empty-state
content, a visibility rule) in plain language for the dual-write below.

## 4. Ratification — one owner act, two commits (law, then spec)

Approval is the ratification moment — same standing as the interview
answers that became the PRD. From then on: PRD.md is what the product
DOES; design/ is what it IS. Both law, both re-read every session, both
changed only through the owner. The act lands as two adjacent commits,
because the law-change rule (§4.1) forbids mixing law with anything else:
**commit A (law)** — everything below except the dual-write: design/
snapshot, tokens, inventory rows, materialised tests, placement/BASELINE
bookkeeping, checks refresh — all law-eligible paths, one standalone law
commit. **Commit B (spec, immediately after)** — the PRD appends and
DECISIONS entries of the dual-write.

- **The amendment brief is closed.** `DESIGN-AMENDMENT-BRIEF.md` (§3)
  carries no `open` line and no `PRD wins` or `both change` line short of
  `landed` — the court refuses commit A otherwise; a design change is
  re-imported and its pass re-run empty before this act.
- **Dual-write.** Each read-back decision, and each `design wins` or
  `both change` row of the §3 brief → PRD.md `## Appends`, in the
  PRD's row grammar: a dated append heading naming the sitting, a
  ```vid-prd block with a new `REQ-NNN` row (a demand type, tier,
  `fail-if:`, `serves:`, `phase:` — v0.9.1 3.6) or a full `REQ-NNN AMENDED` restatement carrying `arms:` — one entry
  per arm of the row it supersedes, `retained · strengthened · moved
  <id> · withdrawn <A-NNN>` (v0.9.1 3.5b; checks/prd.sh join 14 joins it
  under `grammar: 0.9.1`); `authority: authoritative` (the owner approved
  the design), `source:` naming the design sitting and the marker
  (`design 2026-09-09 P03/expired`); under a PRD headed `grammar: 0.9.4`
  or later each new row carries `feature:`, and a new feature is an
  appended ```vid-prd-features row; under a PRD headed `grammar: 0.9.5` or later every new or AMENDED demand item and invariant also carries `plain:` — one sentence of at most 30 words saying the rule in the owner's words, no ids, every number in it taken from its own statement or fail-if (v0.9.5 3.13). checks/prd.sh judges the effective
  set at commit B — an amendment that drops its Fail-if fails the commit.
  Surprising technical choices → DECISIONS.md. This keeps the spec's two
  halves agreeing by construction. Before commit B, spawn
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
  in `mode: delta` on the prepared append — the §3 brief's amendment
  rows and the decisions-embodied rows — against the effective set
  (v0.9.1 3.2, R14-ii) — a design-wins amendment can contradict an item
  outside the marked screens (the consistency pass sees only
  marker-linked rows), and only the affected-set review sees that; its findings are ruled in this ratification sitting, the run
  recording `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" 'tokens slice=0 phase=review n=T'`.
- **Snapshot verbatim** into `design/screens/` — markers preserved
  exactly; nothing tidied, renamed, or improved in transit. The ONLY
  permitted transformation: extracting `design/tokens.css` VERBATIM from
  the pack's values, disclosed with a provenance header (the successful
  field build's header is the template):

      /* <project> — ratified design tokens.
       * Extracted VERBATIM from the owner's design files in
       * design/screens/ (the one permitted transformation, disclosed at
       * ratification). Values are the design's own; nothing invented,
       * nothing dropped. App source references these variables only —
       * checks/conformance.sh rejects any new raw hex outside design/. */

- **Inventory.** Persist the resolved join table as INVENTORY.md surface
  rows — inside init, the vid-test-inventory skill's init-mode sitting
  (init's ratification 3) consumes the table; standalone, run that skill
  in **append mode** with the resolved surfaces as the delta (it derives
  the surface rows per auth state, presents the row-set diff, and
  materialises what is newly expressible as failing ledger tests, stamped
  at the parent sha).
- **Bookkeeping**, same commit: `design/` into CLAUDE.md's
  ```vid-placement block; the design's extensions (`.css` `.html` as
  applicable) into BASELINE's allowed list.
- **Court compatibility.** design/ is spec, not source: exempt from
  `Purpose:` headers and from the raw-hex court. If this project's checks
  predate v0.6 — grep: `checks/design-join.sh` must exist — refresh
  `./checks/` from `${CLAUDE_PLUGIN_ROOT}/checks/` in this same commit,
  and for an existing codebase set `Import court: report-only` in
  ARCHITECTURE.md (the §5.4 retrofit default) so the refresh is not a
  wall. Housekeeping, technical channel; do not surface it.
- During a develop run under a 0.9.6 plan (`sh checks/plan.sh gate`
  prints `on`), run no ledger here. The design courts judge commit A at
  the hook, and the surface rows the amendment touches are named, each
  with a reason, in the next slice close's rows file
  (`.vid/close/<slice>.rows`), so that close runs them. The checkpoints
  and the final full run cover the rest. Otherwise (no develop run), `sh
  checks/test.sh` run (red inventory rows are expected pre-develop;
  nothing previously green may turn red). Then commit A with the template
  message and `VID_ROLE=fix` — design/ is protected, and this write is
  owner-sanctioned by the approval itself — followed immediately by
  commit B (the PRD appends + DECISIONS dual-write).

## 5. Afterlife — how the ratified design stays true

- Develop TRANSCRIBES, never reinterprets: every CSS rule
  property-for-property from a cited canvas section, hex→token the only
  substitution, no invented visual values; citations at sub-screen marker
  granularity (`Design: design/screens/<file> (P03/expired …)`,
  `/* Result cards (P02/populated — REQ-030) */`). checks/design-cite.sh
  enforces rule-block citations at every commit; checks/coverage.sh joins
  every marker — never a filename — to a citation; an uncited marker is a
  gap that blocks "done".
- App source never introduces raw colors: colors enter through design/
  and are referenced as tokens; checks/conformance.sh rejects new raw hex
  outside design/.
- The grading engine grades fidelity: built-vs-designed divergence is a
  finding; a screen existing only in design/ is ABSENT. A shared element
  is compared to C00's section, never to another screen (v0.9.1 3.7a):
  its CSS lives in one rule block citing C00, so a second block citing a
  screen marker for the same element is the tell graders are told to
  look for; a screen that restyles a shared element is caught by the
  comparison, never assumed away by a reference. The citation
  names the target, so a spot-check ("compare `.jt-header` to P01's
  header section") is a 30-second grader task. `/vid grade --visual`
  adds the stochastic screenshot review — findings, never a gate.
- design/ changes only through another /vid design round or an
  owner-sanctioned /vid fix correction — and modifying or deleting
  anything under design/ is a law change (standalone commit,
  hook-enforced; additions stay free). A visual correction lands as the
  design law commit first, immediately followed by the code commit citing
  the same markers — adjacent, so the two never diverge beyond one commit.
- A PRD/design contradiction discovered later is a product question —
  asked immediately, never resolved silently in either direction.

The design binds the builder and never absolves it: a designed screen is
spec, not evidence. Only the ledger and the graders are evidence.
