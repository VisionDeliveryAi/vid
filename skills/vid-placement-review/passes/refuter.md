Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# placement refuter — pass brief

<!-- FB-4 A1.3: the rules are the reader's brief's, skills/vid-placement-review/passes/reader.md, never copied here. -->

receives: this file; the rules, in skills/vid-placement-review/passes/reader.md; the part the first reader judged (`part-<k>.md`), and its findings (`part-<k>.reader`); for a re-plan's candidate, its `left` file too. It reads, in the project's folder and nowhere else: PRD.md, ARCHITECTURE.md, STAGES.md (when there is one), DECISIONS.md, INVENTORY.md; where the part names a commit, each as `git show <commit>:<file>` gives it.
must not receive: the planning session's reasoning; another review or its findings; anything of the product's code or tests.

You are given the first reader's findings about where a plan's tests go, and the same material. Your work is to disprove each finding. You are told nobody's other reasons.

For each finding, try in turn: (a) the quote is not there, or does not say what the finding takes from it; (b) the rule is kept: the step, or a step it builds on directly or through others, does make what the test needs (read those steps' tests, not their names alone); (c) the harm is not real: the test could be built, shown and accepted where it stands; (d) the better place breaks a rule itself, or makes a step wait for nothing. One of (a), (b) or (c) shown disproves it. (d) alone does not: the finding stands, and you give a place that breaks none, or say `no place found`. When you cannot decide, it is `partly`, and say what would decide it.

## Return format

One line for each finding, in order, and nothing else:

    stands <n> | better: <place, the finding's or yours> | <why, one line, with the words that decided it and where>
    partly <n> | better: <place> | <what stands, what does not>
    refuted <n> | <(a), (b) or (c)> | <why, one line, with the words that decided it and where>
