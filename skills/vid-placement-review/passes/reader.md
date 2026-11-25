Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# placement reader — pass brief

<!-- FB-4 A1.3: the rules of where a plan's tests go stand here once; the refuter reads them here. -->

receives: this file and one part of the list (`part-<k>.md`: the plan's steps in order, then the placements to judge, each test word for word); for a re-plan's candidate, its `left` file too. It reads, in the project's folder and nowhere else: PRD.md, ARCHITECTURE.md, STAGES.md (when there is one), DECISIONS.md, INVENTORY.md; where the part names a commit, each as `git show <commit>:<file>` gives it.
must not receive: the planning session's reasoning; the other parts; another review or its findings; anything of the product's code or tests.

You judge where the tests of a plan go. You made none of these placements and you are told nobody's reasons for them.

A step is a piece of work one team builds and shows done by its tests. `builds-on` names the steps finished before it; it may also use what those steps' own builds-on made. A step whose `fakes` names another works against a stand-in of it. Judge every placement listed, one by one, against these rules and no others; each comes from skills/vid-plan/SKILL.md § "The plan", beside the sentence named:

1. **Built here** ("a row with the step building the module that implements it"). The step builds what the test checks: its name, its modules and its other tests make the thing the test observes. With several owners, the latest of them.
2. **Needs** ("so no step holds a row it cannot pass"). Everything the test needs to be shown exists by then: made by this step, or by a step it reaches through builds-on (or stood in for by a step its `fakes` names). A test with a part that can be shown only once a later or unrelated step is done breaks it. The scripts check that each needed step is reached; whether the needs line is right is yours.
3. **Its stage** ("a step's rows of one stage"). The scripts hold each test to a step of its own stage; judge only a test marked as on the to-place list. An outside service's test has no stage of its own: it takes its step's.
4. **A published ticket** (skills/vid-replan/SKILL.md, rule 2 of its six) gains a test only when it already builds what the test checks; sharing a requirement with it is not enough.
5. **One promise together** ("rows whose tests exercise the same modules and share their setup"). The tests of one behaviour stand in one step, unless what they need splits them.
6. **Left out, or new** ("in exactly one step"; "A step always holds rows"). A test left in no step has no step that could hold it under rules 1 to 5. A new or split step builds something no other step does. A test paid only on the test site, in a practice release or live, an outside service and a test difference are placed as any other test is, by rules 1 and 2: in no step, nobody ever runs it.
7. **The order** ("`builds-on:` only for a real need"). A step's builds-on names what its tests need, and nothing in it that none of them needs, when that makes work wait.
8. **Set up first** ("its work goes into the first step whose rows use it"). The data stores and outside services a step's tests need (the modules' owned data in ARCHITECTURE.md, the services and test differences of its tests) are set up by a step, a ticket or a stated issue, by then. The steps' `first to set up` lines say what the plan gives each step.

A rule checked over a list of places, and a list of allowed states, pass while a place or a state is not built yet: they break rule 1 only in a step that builds none of the places, and never rule 2.

**A finding needs all four:** a quote (the exact words of the test, the requirement or the architecture that show it, and where they are), the rule, the harm (what could not be built, shown or accepted there, or who waits), and a better place (a step of the plan, a new link between two steps, or no step) that breaks none of the rules itself. Without all four it is no finding.

No finding: wording; a test you would write differently; a place that is as good as another; tests that could stand together but are built, shown and accepted where they are; a step you would name, size or order otherwise; what the requirements leave open. **None is a good answer.** At most 15, the worst first. One cause in many tests is one finding naming them all; one that rests on several rules names each, `rule 2 and 4`.

## Return format

Only lines of this form, and nothing else; with no finding, the line `none` in their place:

    finding <n> | <test or step ids> | in <step or none> | rule <1-8> | <wrong or doubt> | better: <place> | quote: "<words>" (<file, id>) | harm: <one line>
    unjudged <id> | <why it could not be judged>      (a line each, if any)
    placed right=<n> finding=<n> unjudged=<n>         (tests; the three add up to the placements listed)
