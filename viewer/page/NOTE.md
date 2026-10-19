# VID Viewer — design note

## Navigation
- **One tree, one address per thing.** Product › capability › requirement › promise. Every node is a plain `#<id>` anchor (`#FEAT-10`, `#REQ-049`, `#ROW-037`, `#S08`, `#A-131`, `#D-101`), so any link or search result lands in the same place.
- **Keeping your place.** The breadcrumb remembers the route you took: a promise that serves three capabilities shows the capability and requirement you came from, and lists the others ("Serves 3 capabilities — counted under each of them").
- **Same summary at every level.** Tests (passing of total), Reviews (kept, broken, not reviewed) and Open gaps (by state), plus one bar of counts. Product, capability, requirement and step all use it, rolled up from promises.
- **Tests and reviews apart.** On a promise, the test result (result file, commit, failed checks) and the review history (each judgment in order, who was at fault, the prose) are two panels. Tests are marked with filled dots; reviews with outlined squares.
- **Delivery** is a second way in: built, tested and reviewed as three separate counts, needs-you, agents now, steps over time and recent changes. Every item opens its node in the tree.
- **Search** from anywhere: `/` or ⌘/Ctrl-K. It accepts ids loosely (`row-37`, `s8`) or words; Enter goes to the first match.
- **Time.** The header always shows the moment, Live or Replayed, and the previous and next snapshots. A replayed snapshot also gets a banner.

## How the change log handles scale
1,762 changes are never shown as one list:
1. **Narrow first:** a range between two moments, capability, kind (each kind chip shows its count), and free text.
2. **Group with counts:** by kind, then by what changed. Promise states group by transition (e.g. Never run → Passing · 512); reviews group into Broken and Kept.
3. **Show a few:** 8 items per group, with "Show 25 more · N not shown".
4. **Commits** start as a count. The list opens one click later.

## States (Tweaks)
- `mode`: snapshot or index (index opens on Snapshots).
- `replayed`: shows the replayed banner.
- `dataset: empty`: the first-snapshot, nothing-recorded state.
- `theme`: auto, light or dark.

Search with no results and filters with no results both have their own empty messages.

## Sample caveats
- Canvases are null in the sample. The S01–S06 states point at the one example canvas (`S Platform staff`), so those open at their marker. Other states are marked as having no embedded design.
- The sample doesn't include review prose, so each judgment says the notes aren't in this snapshot.
- Delivery: dataset is split into `viewer-data.js` and `canvases.js` for editing; bundle to one offline file for distribution.

## Architecture
A fifth top-level section, between Product and Delivery. It reads `architecture` and the `architecture` change kind only. Tabs: System, Outside services, Stack. Anchors: `#architecture`, `#architecture/services`, `#architecture/stack`, each module at its path (`#apps/jobs`, `#core`, `#services/search`), each service at its id (`#SEAM-004`, which opens the Services tab and scrolls to it).

### The system picture
- One row per `level` (level 0 at the top), then the band "Open to every module" at the bottom. Rows come straight from `placement`/`level`; the caption says the arrangement is computed from the module table, not drawn by anyone.
- Each module is a box: its path, a thin bar of its criteria's test results (the same colours as the summary bar), and "may use N · N steps".
- No lines at rest. Pointing at a box (or focusing it with the keyboard) draws its lines; clicking it opens its module page. Blue lines go to modules it may use; purple lines come from modules that may use it. Unrelated boxes fade. Lines are measured from the laid-out boxes, so they follow wrapping and window size.
- The open-to-every-module band never gets lines: any module may use it, so one line each would only add clutter. The strip under the picture says how many of the picked module's links went to the band.
- The strip under the picture shows the picked module's path, place, responsibility and counts, with "Open apps/jobs →".
- Outside services sit in a dashed rail at the right edge, each with its probe and credentials state. The data doesn't record which module talks to which service, so they have no lines, and the rail says so.
- Shown apart, below: **Unplaced** modules (dashed, warning colour). Plan names with no module row (e.g. `data`) are no longer shown on the System tab; a step page still lists them as "data (no row)".

### The module picture
- On a module's page: "May be used by" on the left, the module in the middle, "May use" on the right. Modules open to every module are one dashed group on either side, never one line each. An open module itself reads "Every module: it is open to all". A module nothing may use reads "No module may use it".
- The lists come from `mayBeUsedBy` and `mayUse` as recorded. The words are always "may use" and "may be used by".
- Below the picture: owned data, public surface, other names (as written, or "None"), and placement. Backticked text is shown as code; a null field reads "not recorded".
- Then the same summary bar as everywhere else, over the criteria of the module's build steps, each counted once. The note under it says a criterion is counted under every module its step names, and how many of these also count under another module.
- Then the build steps that name it, and the criteria list with its filter chips, as on a step. Every step and criterion opens its existing page.

### Inside a module (brief 2)
The module page is the picture, then five tabs. Each tab has its own address: `#apps/jobs` (Overview), `#apps/jobs/decisions`, `/health`, `/left`, `/files`. The picture and tabs stay at the top of every tab.
- **Overview.** *What it is*: responsibility, the data it owns, and the rule "Only this module writes this data. Other modules go through its way in." *Its way in*: the surface as written. The entry point it leads with is shown first as code, then the rest of the cell as written, with "Other modules enter through the entry point." No claim is made about what VID checks. Below, side by side: every change to the way in, newest first, each with date, commit, and Before (struck through) / After. A first entry reads "Nothing: the row first appeared here". Next to it, *Decisions labelled for this module*. A missing `surfaceHistory` reads "Interface history: not recorded". *What a change affects*: the modules that may be used by it, with "VID's fixes re-check this module together with them". *Outside services it talks to*: each service that names the module, with purpose, contract test, probe and credentials. If no service names it, a line says the records don't link services to modules.
- **Decisions linked to this module.** Listed in date order. Each row shows what was decided and why, how it is held, when (At spec / During the build, date, commit) and why it is listed ("Mentions" followed by the words its text uses (`match`) as code, "Labelled for this module", or "Labelled for its promises"). Some mentions aren't about the module (e.g. `core._domainkey`, a DNS name, on core), which is why the words are shown. A missing stage or date reads "Stage: not recorded" / "Date: not recorded". Convention rows get a warning pill ("Convention · nothing checks it") and a tinted row, and the intro counts them. Filter chips: All, Convention only, Labelled, At spec, During the build. Chips with no matches are hidden. Below the list, *Project-wide decisions* is one group, collapsed by default. It shows decisions whose `scope` is `project`; the sample has none, so it says so.
- **Health.** The usual summary bar. Then *Must-never-break rules its criteria prove* ("8 of 23"): each rule's meaning, a bar and the count of the module's criteria that serve it. Then the criteria list, with problems first (failing, stale, never run, broken on review) and then the rest by state. The tab count is the number of problems.
- **Left to build.** Steps not closed, and criteria that are not built or are built but owed a test. Each criterion shows its step. The list shows 30 at a time.
- **Files.** File paths grouped by folder (no code). Next to them, the test files its criteria use, also grouped, each with how many criteria it checks.

Null fields read "not recorded". Every empty part says so in one line.

**Module states (Tweak `archSample`).**
- 22 decisions: `apps/jobs`. 1 decision: `services/search`. A convention row is in `apps/jobs`.
- A mention not about the module: core D-099 (`core._domainkey`), in the sample.
- *edge states* also adds:
  - two decisions on `apps/jobs`: D-300 labelled for this module (so it appears under "Decisions about it") and D-301 labelled for its promises;
  - two example changes to its way in (`e1a2b3c`, `f4d5e6a`), so the way in has changed twice;
  - services that name modules: SEAM-001 → apps/ingestion, SEAM-002 → apps/mail, SEAM-006 → services/search;
  - three project-wide decisions (D-001–D-003);
  - D-283 on apps/jobs with no stage or date ("not recorded").
- The System tab now lists every module under **Module pages**, each linking to its page. Clicking a box in the picture opens its page.
- No must-never-break rules: `apps/apply` and `apps/seo` (in the sample).
- *past snapshot*: the module page is cut to 2 Oct 2026, before the build started. The kicker and a banner say "Replayed · As it stood at …". Decisions and way-in changes added after that time are left out, and the banner gives the count. (In a real replayed snapshot the data already ends at that moment.)
- Dark mode uses the theme variables.

Screenshots:
- arch-module-01: the System tab with the Module pages list.
- 02: apps/jobs, the title and tabs, with the picture on Overview.
- 03: Its way in (entry point, history, labelled decisions).
- 04: the Decisions tab on apps/jobs (22). 05: on services/search.
- 06 to 08: Health (summary, rules, criteria).
- 09: Left to build. 10: Files.
- 11: the way in changed twice, and a labelled decision (edge states).
- 12: core decisions, including a mention not about the module (`core._domainkey`).
- 13: a decision with no stage or date.
- 14: the open Project-wide group.
- 15: a service that names the module.
- 16: no rules (apps/apply).
- 17 and 18: past snapshot.
- 19: dark mode.

**Usability pass (module page).**
- The tabs now sit right under the title, so they show without scrolling. The "Who may use it" picture is shown only on Overview.
- Filter chips that would match every decision are hidden. If none is left, the chip row is hidden too.
- The System tab's description now says that clicking a module opens its page.

### Moving between them and the rest of the page
- System picture → module page → step (`#S08`) or criterion (`#ROW-…`) → back up through the product tree as before.
- A step page now has a "Modules it names" field linking back (plan names with no row are shown as "data (no row)").
- A service's "Chosen by" links to its decision page (`#D-010`).
- Search finds modules by path and services by name or id (results group as "Modules" and "Outside services").
- Change log: a new "Architecture" kind chip. A changed row shows each field with Before and After; the removed part is struck through and the added part is highlighted. The module id links to its page.

### States
- **Not recorded (old project):** no `architecture` in the data, or Tweak `archSample: not recorded`. The section stays in the navigation and shows one dashed "Not recorded" panel. `dataset: empty` gives the same.
- **`missing` entries:** a notice above the tabs lists each part with its reason, and the affected tab shows "Not recorded" with the reason instead of an empty picture or table.
- **Unplaced module, service with no decision link:** the sample has neither, so Tweak `archSample: edge states` adds one unplaced example module (`apps/billing`, with null owned data and surface, and two other names), removes SEAM-007's decision ("No decision recorded"), and adds a `missing` entry for the stack. A decision id that isn't in the snapshot reads "D-xxx (not in this snapshot)".
- **Plan name with no row:** in the sample (`data`).
- **Past snapshot:** the existing Replayed banner, plus "Replayed · As it stood at …" on the section and on module pages.
- **Dark mode:** all colours come from the existing theme variables.

### Changes to existing lines
Most of the v2 file is untouched; the section adds new lines. Changed in place:
- The search result row: `overflow-wrap:anywhere` added to the id span, so long module paths wrap inside the id column.
- The `data-props` on the script tag: the `archSample` tweak added.
Everything else is new lines inserted between existing ones (one-line hooks in `build`, `onHash`, `chItem`, `renderVals`, the mount/update handlers, and `KINDS.push`).

For brief 2, the old module-page block (facts grid and step list) is replaced by the tabs above. Its picture moved above the tabs, unchanged. The nav order is now Product, Architecture, Delivery, Change log, Snapshots. The returned v2 copy is identical to this project's v2. `viewer-data.js` is the brief-2 file, used as supplied. `support.js` is unchanged.

Screenshots: arch-01 system with a module picked, arch-02 module picture, arch-03 services, arch-04 stack, arch-05 not recorded, arch-06 unplaced and plan-name states, arch-07 dark mode, replayed, arch-08 change log Architecture rows.


## Files returned (brief 2 + correction)
- `VID Viewer v3.dc.html`: the whole page.
- `viewer-data.js`: the correction's file, used as supplied.
- `NOTE.md`: this note.
- `screenshots/arch-module-01` to `19`.
- `support.js` is unchanged, so it is not included.

Changes outside the module page, made on review:
- Architecture moved in the top navigation to between Product and Delivery.
- Clicking a box in the system picture opens its module page. It used to keep its lines drawn instead.
- The "Named in the plan, with no module row" box is removed from the System tab.
- A Module pages list is added below the system picture.

