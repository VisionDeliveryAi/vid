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



## Execution
A new top-level section after Delivery (`#execution`). It reads `execution` only. **Shown in the latest snapshot only**: in a past snapshot (`execution` is null) the section is one line, "Execution is shown in the latest snapshot only", with a link to the latest. Everything in it carries **"as observed at <execution.observedAt>"**: a band at the top says so, with "The records say what was started and what ended. They don't prove a process is alive now." and the watcher's last check.

**Parts.** Four cards (agents by state, needs attention now, test queue, rework), then five tabs, each with its own address:
- **Needs attention** (`#execution`, default). Current items first, newest first; past items below in one collapsed group, dated, with a count per kind. Each item: its kind as a badge, "Recorded <time>" (or "Time recorded: not recorded"), "as observed at <time>", the text as written (long text folds at 240 characters), links to the agent, question (`#delivery/needs`), test request or row it names, and **Copy a prompt**. **Quiet** (dashed outline, "Quiet · no activity seen") and **Stuck** (filled warning, "Stuck · past its time limit") are different badges, and the line above the list defines both. A death the records describe only in words has no agent to open; it shows as written, and says no prompt form fits.
- **Roster** (`#execution/roster`). Every agent and Codex job, grouped by session: the run manager's sessions first (tagged), then the others, then "No session recorded" (Codex jobs). Each row: role and try (or "No role recorded" and its agent type), tool, id, "brief linked" / "brief not recorded", step, state (working rows add "as observed at <time>"), start, running time (runs added; "N runs" when resumed), tokens, Copy a prompt. Filters: search by id or try, session, role, step (selects); tool and state (chips). Sort: start, running time, tokens. 20 rows per session, then "Show 50 more". The state counts in the first card also set the state filter.
- **Agent page** (`#execution/agent/<id>`, from any row, lane or link). State, running time (elapsed), step and slice, model and effort, session. **Runs**: each run's start, end (or "open, as observed at"), how it ended, elapsed, and a bar of the runs (open runs striped). **Its brief**: only when a record names both (`linked`): path, size (from the usage entry's `briefBytes`), the rows it names (each opens its criterion), its text when carried, else "The brief's text is not carried in this snapshot. Its path is above." Unlinked: "Brief not recorded" and its agent type; the link is never guessed. **Its hand-back**: file, then "Acceptance recorded", "Refused on <date>", or "No acceptance recorded, as observed at <time>" with "Not necessarily refused: the check may not have run yet, or it refused it. Older records don't say which, or when."; line count and "not" count; report beside it or not; one line per row (row, pass/not, receipt, reason, each "not recorded" when null). **Test runs it asked for** (passes naming its try). **Its usage**: four kinds or the older total with its words, the estimate or its reason, largest call, context at first change (with "possibly earlier, through a shell command"), survived. No usage entry reads "tokens not recorded".
- **Timeline** (`#execution/timeline`). Starts on the last 24 hours. Presets 6 hours / 24 hours / 3 days / Whole run, ← → to move by half a window, + − to zoom. Bands on top: stages, slices, steps (packed into rows; open bands have a dashed end; extra overlapping rows are counted, not drawn). Pointing at a band shades its span behind every lane; a step band opens the step. One lane per agent with a recorded start, coloured by state, each run drawn; an open run is striped to the observed line. Agents with no recorded start are counted ("…in the roster but not drawn"). Test passes: waiting dotted, running solid by outcome. Each close batch is its own group: "<ticket> · N parts side by side · the batch took <elapsed>", one sub-lane per part. "Times are elapsed time, never compute time" is said once. 40 agent lanes and 30 test lanes at a time.
- **Test queue** (`#execution/queue`). Environments as slots (taken: request, since, elapsed, working copy; or free) with "every one taken" when so. Running: request, kind, who asked (role and try), rows, since and elapsed (marked "open in the records past its cap" when the elapsed time passes the cap), time limits. Waiting: the same plus **why it is waiting, as recorded**, and Copy a prompt.
- **Rework** (`#execution/rework`). Attempts per step (briefs, came back, closed); attempts per row (briefs, times broken, latest review), filtered to "Broken more than once" first, those rows tinted; hand-backs with no acceptance recorded (or "Refused on <date>"). Every briefs count opens the tries behind it, each linking to its agent where a record names one (dashed when none does).

**Copy a prompt, as built.** A button on every attention item, roster row, agent page and waiting request. It opens a dialog showing the exact message, then Copy → "Copied". Filled only with ids, times and state words; every form ends "Check the current state before you act on this." <T> is `observedAt` as "20 Oct 2026, 07:10 UTC".
- agent: "As of <T>, the ViD viewer showed <role> <try> (agent <id>) as <state> for <duration>. Please tell me what it is doing or what happened." With no role or try: "…showed agent <id> as…". State words: working, returned, ended without a hand-back, died, needing recovery.
- question, hand-back, test request, notice (also used for quiet), session stopped, run stopped/waiting, stuck, Codex job, environment: the brief's forms, verbatim. An environment with no slot recorded reads "test environment (slot not recorded)".
- refused hand-back: the agent form with the state word "refused". Agent lost: the agent form when the record names the agent; otherwise no button (the item says why).

## Economics
After Execution (`#economics`). Shown in every snapshot, up to its moment. A note at the top explains the two kinds of token record. Four cards: four-kind sum (with its estimate), older-total sum, **the run manager shown apart** (records, calls, its mixed total), test passes. Then the prices line: "API-equivalent, not your bill", the prices' date ("date not recorded" here), and that this sample's prices are placeholders. Five tabs:
- **Where the tokens went** (default). Group by role, agent, step, slice, stage, or model and effort. Columns: agents, four kinds (or "not recorded in kinds"), older total (header: "input and cache together; output not recorded"), estimate. A group holding both kinds shows both sums side by side, tagged "two sums: kinds and older totals". Never added together; no dollar figure on an older total ("older record, no estimate"); unpriced kinds say "model not priced".
- **Inside the calls.** Cache read and fresh input as two counts side by side (plus cache write and output), over the agents recorded in kinds; never a share. Context size per agent: largest call, context at first change ("possibly earlier, through a shell command"), brief bytes, tokens. Largest first.
- **Test time.** By outcome (all ten outcome words), and by request kind, role or step: passes, outcomes, running, waiting, start-up, clean-up, repeated attempts. Times are added only for passes outside close batches; batch parts count as passes, and each close batch shows its own elapsed time with its parts listed, never added. Proof runs: "none recorded" here; the rule is stated.
- **Rework cost.** One card per kind: builder or fixer that died or ended with no hand-back; hand-back refused (where recorded); rows all broken on review later; set aside for a fresh one; any other recorded reason as written; test run stopped at a limit, cancelled or void (test time). Each shows its count, its sums (two kinds apart) and "Tokens not recorded: N attempts", and opens its items. **Not yet known** (no acceptance recorded) is a dashed card apart.
- **Cost per outcome.** Steps closed: closed date, briefs, tokens behind it (two sums, plus "tokens not recorded"), test time; each opens its tries. Rows kept: each brief behind it, "shared with N other rows; tokens not divided". Shared work apart: the run manager's records and total, and test passes owned by no try, step or row.

## How a reader moves
Execution card or chip → roster filtered by state → agent page → its step (`#S…`), rows (`#ROW-…`), test runs, Economics. Attention item → agent / question in Delivery / request in the queue. Timeline lane → agent; step band → step. Rework count → tries → agent. Economics agent rows and rework items → agent page (latest snapshot). Step and row ids everywhere open their existing pages.

## States (Tweak `execSample`)
- *as recorded*: the sample. In it: working (incl. two open since 9 Oct), returned, ended without a hand-back; linked and "brief not recorded"; a hand-back with no acceptance recorded and with "not" lines; resumed agents (3-fixer-175, 6 runs); current and past attention items; an open question; quiet notices and stuck operations; requests waiting with their reason; every environment taken; rows broken 3 to 6 times; builders mixing four-kind and older totals; a Codex job with an estimate and Claude agents with "older record, no estimate"; tokens not recorded; steps closed with shared work apart.
- *edge states* adds, each marked "design-state example": an agent that died (and its attention item), a Codex job needing recovery, 3-fixer-36's hand-back refused on 19 Oct, the run waiting, a Claude builder in four kinds on a priced model (estimate) and a fixer on an unpriced model ("model not priced").
- *past snapshot*: Execution shows its one line; Economics is cut to 16 Oct 2026, 09:07 UTC (the previous snapshot) with a Replayed note. The existing `replayed` tweak also hides Execution.
- `dataset: empty`: "No agents yet" and "Nothing used yet".
- Dark mode: theme variables only.

## Changes to existing lines (v4)
Everything is new lines inserted between v3's lines: the template blocks before the "Nothing called…" block, constants before the class, one routing line in `onHash`, one navigation line after the Architecture one, one render line after `archV`, and new methods at the end of the class. One existing line changed: the `data-props` on the script tag gains the `execSample` tweak. `viewer-data.js` is the brief's file, used as supplied (not changed). `support.js` is unchanged.

Screenshots (taken at a narrow preview width; the page reflows wider):
- exec-01, 02: the section top and Needs attention (current). 03: past items opened.
- 04: roster. 05: roster filtered to Codex.
- 06, 07: a working agent that ran six times: runs, brief linked, hand-back with a "not" line.
- 08: "brief not recorded". 09: a hand-back with no acceptance recorded, tokens not recorded.
- 10: timeline, 24 hours. 11: the whole run.
- 12: queue (every environment taken, running). 13: waiting with its reason.
- 14: rework per step. 15: rows broken more than once, one opened.
- 16, 17: copy a prompt, before and after "Copied".
- 18, 19: edge states (died, needs recovery, run waiting). 20: an agent that died. 21: a Codex job needing recovery. 22: a hand-back refused on a date.
- 23: past snapshot. 24: no agents yet. 25 to 27: dark mode.
- econ-01: the cards. 02: by role (two sums, an estimate, older records). 03: by agent.
- 04: cache read and fresh input. 05: context per agent.
- 06: test time by outcome. 07: by request kind. 08: close batches opened.
- 09, 10: rework cost (tokens not recorded; not yet known).
- 11: a step closed with its cost and shared work apart. 12: rows kept, briefs shared.
- 13, 14: edge states by model (Claude estimate, model not priced).
- 15: past snapshot. 16: nothing used yet. 17, 18: dark mode.

## Own review fixes
- A test request named by a past attention item links to the queue only while it is still there; otherwise it reads "no longer in the queue".
- Economics rows and rework items link to the agent by its try when the usage entry names no agent id.
- Past-snapshot cut keeps the 10 test passes with no asked time (cut by their start).
- Run manager card: four-kind records, if any, are shown apart from its older total, never relabelled.
- Rework cost in a past snapshot says why the agent-state kinds are absent.
- Badge text on red badges uses the theme background, for contrast in dark mode.

## Files returned (Execution and Economics)
- `VID Viewer v4.dc.html`, `NOTE.md`, `screenshots/exec-01`–`27`, `econ-01`–`18`. `viewer-data.js` and `support.js` are not changed.
