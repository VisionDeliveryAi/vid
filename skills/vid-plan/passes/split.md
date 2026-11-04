Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# split — pass brief: the split guidance, for `split: fine` (v0.26.10.12.3.1, R6)

receives: this file, the drafted plan block with its prose, PRD.md, ARCHITECTURE.md and `sh checks/planner.sh rows --short`; it returns the block split, and the planner checks and owns it.
must not receive: the planning session's reasoning; anything of the product's code or tests.

In ticket mode the guidance's words mean:
- **The plan's steps** are the planner's draft. **Rows plus guards** are a step's planned rows: every guard (a
  hostility, rule, difference or seam row) is a row in ticket mode, counted once.
- **Point 5's steps "with no rows of their own"** hold the rows their modules own (rules, outside services, test
  differences), or merge into a neighbour: a step always holds rows. **"So nobody waits on day one"** means the first
  steps after the skeleton: stage 0 holds the skeleton alone, and admission holds stage 1 until stage 0 has its candidate.
- **Solid** is `builds-on:`, **dashed** is `fakes:`, a **lane** is a lane of the setup.
- **The last two bullets** become: the page is written again, and the prose says, for each drafted step split, what it
  became and the size of each part, and names the steps left whole with the reason.

> Split the plan's steps into smaller ones. Go through every step, one at a time, starting with the earliest (the foundation and the first steps of each lane), and ask whether it can be split. Don't re-plan the tracks or change which team owns what.
>
> How to split each step:
> 1. List the step's requirements and its rows, grouped by requirement. Count rows plus guards.
> 2. Find natural seams. In order of preference:
>    a. Separate requirements or groups of requirements that build different behaviour (for example: creating a record / editing it / sharing it with others).
>    b. Separate stages of a pipeline (for example: reading and checking the input / transforming it / storing the result / handling failures / running at volume).
>    c. Separate the engine from its screen, or the automatic path from the staff path (for example: the automatic check / a person settles it on a review screen).
>    d. Separate the core rule from a rule layered on top (for example: the base calculation / a discount rule / a rounding rule).
>    e. When one requirement carries many rows, split by subject: the immediate effect versus every copy or later effect (for example: removing an item now / removing every copy of it later).
> 3. Make each new step one modular unit: its rows test the same modules and share one test setup, so one person can make them pass together.
> 4. Target size: usually 5 to 20 rows plus guards. Never above 60 unfinished rows. Under about 5, merge it back unless it's distinct logic the owner cares about seeing on its own (such a rule stays its own step even at 3 rows). A step that came out at 1 row goes back into its neighbour.
> 5. Steps with no rows of their own (infrastructure, shared services) still split by deliverable: for example repository and CI / the test environment / the database schema / the API contract and test harness. Spread them across lanes so nobody waits on day one.
> 6. Keep a step whole when its rows share one module and one setup, even if it's large (say so, with the reason).
>
> Placing rows and guards after a split:
> - Assign every row to exactly one new step. Use the first child whose requirements match; the remaining rows go to a named default child. Check that nothing is left over and nothing is counted twice.
> - An abuse probe goes with the row or rule it protects. An everywhere-rule goes with the requirement it comes from. A test difference or outside service goes to the step that first builds against it.
>
> Dependencies after a split:
> - Inside a split step, link the children only where it's real: solid when a child's tests need a sibling's code, dashed when only the interface is needed. Siblings that don't depend on each other run in parallel.
> - Redirect every link that pointed at the old step to the specific child that provides the thing needed (for example, the one screen it needs, not the whole feature).
> - Check that no link points to a step that no longer exists.
>
> Naming and output:
> - Give each new step an id derived from its parent (A3-2 becomes A3-2a, A3-2b, A3-2c), a plain product name, a one-line description, its modules, its dependencies and its outside access.
> - Keep each child in its parent's lane, in build order, except the foundation pieces, which are spread across lanes.
> - Republish the same artifact at the same link. Keep the previous version as its own page for comparison, counted against the same inventory.
> - Report, for each original step, what it became and the size of each part, and list the steps left whole with the reason.
