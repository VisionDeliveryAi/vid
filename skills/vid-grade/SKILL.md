---
name: vid-grade
description: Standalone read-only adversarial grade of any repository — fresh-context graders hunt counterexamples against the PRD's Fail-if clauses (or against reasonable expectations when no PRD exists), rank findings by consequence, and save a dated report. Grading loops carry a written exit bar and a convergence stop rule. Where a ratified design exists the stochastic screenshot review against it runs as a standard part of the grade (--visual forces it explicitly). --robustify <areas> takes critical subsystems as built and emits proposed rows, never findings. Changes nothing, applies nothing. Use when the owner says "vid grade", wants an adversarial review or drift check without fixes, or on a schedule.
---

# /vid grade

The look-only verb. GRADE is not TEST: `sh checks/test.sh` runs the ledger —
deterministic, author-written. A grade is an adversarial fresh-context
review — stochastic, probe-based, hunting what the ledger's authors could not
see. Keep the two words strictly distinct.

Usage: `/vid grade [focus areas] [--vs <path-to-second-build>] [--visual]
[--robustify <area>[, <area>…]]`
e.g. `/vid grade alerts, ingestion lifecycle` · `/vid grade --vs ../build-b`
· `/vid grade --robustify notifications`

## Hard constraints — what makes this the verb that is always safe to run

- **READ-ONLY.** You and your graders change nothing, fix nothing, commit
  nothing, and never auto-apply a finding. The only thing written is the
  report file below — untracked output; this verb never stages or commits.
- No owner sitting required. Suitable for scheduled/cron use as drift
  detection.
- Works on ANY repository — ViD or not, anywhere, anytime.

## The exit bar and the convergence rule (law for any grading LOOP)

A single grade needs neither. The moment grades are run in rounds
(grade → fix → grade …), two rules bind, written BEFORE round one:

- **The exit bar precedes the loop.** Write down what "out" means — e.g.
  "no Tier-0 breach, no PARTIAL on a T1" — before the first round. A field
  run agreed its bar after nine rounds; the bar must precede round one.
- **Stop on non-convergence and escalate.** When
  `findings(N+1) ≈ findings(N)` — counts flat round over round — the loop
  STOPS. Non-convergence is *information*: the remaining defects are in a
  class the loop cannot see, and further rounds are the wrong response. The
  escalation to the owner names the suspected invisible class (visual layer,
  cross-module coupling, fixture blindness…) and what evidence class would
  see it.
- Every fix round reports **two separate numbers: regressions introduced vs
  pre-existing defects newly exposed**. They are different problems with
  different fixes — conflating them hides whether the codebase is coupled or
  merely under-explored.

## Dispatch

Run the grading engine per `GRADING.md` in this skill's directory
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-grade/GRADING.md`):

- Graders are fresh-context subagents (Agent tool, subagent type `vid:grader`) that
  receive NO context from this session — only the repo path and the brief:
  adversarial stance, falsifiable criteria, institutional distrust, the six
  probes, verify-before-report.
- **Phase and executor** (v0.9.1 3.6, the rules live in GRADING.md): every
  live `pilot` REQ is collected and every `later` REQ listed as deferred;
  each brief states each item's phase and each row's executor; a
  deploy-owed row's in-repo half is graded as a full obligation, its
  deploy-only half at staging; ABSENT is a pilot-only verdict.
- **Three required brief inputs** (v0.7 §8), gathered before dispatch and
  injected verbatim into every grader's brief:
  1. the census tables — `sh checks/census.sh --report` (populations,
     orphans, exceptions, suppressions, the divergence table). **Execute
     this only on the session's own ViD project.** On a foreign repository
     (a `--vs` target, an arbitrary repo, a scheduled grade of third-party
     code) do NOT run the repo's checks/ or its inventory census commands —
     they are arbitrary shell authored by that repo; read INVENTORY.md and
     checks/ as text instead and mark the census tables "unexecuted",
     unless the owner explicitly opts in;
  2. GRADING-CHECKLIST.md, whole — the domain's known failure modes,
     including the standing harness-attack line;
  3. the law-change log — every commit since the last grade that touched
     law: `git log --oneline <last-grade>..HEAD -- checks/ tests/invariants/
     CLAUDE.md BASELINE.md ARCHITECTURE.md INVENTORY.md` (use the date of
     the newest report in .vid/grades/, or full history on a first grade).
     The report lists every law change; each one's Decisions: trailer must
     state what it admits — one that does not is an automatic finding.
- **Denominator attacks** — a standing instruction in every brief: find one
  site a census command misses, and one path that defeats a guard WITHOUT
  appearing in its denominator — state erasure, ordering, a second
  vocabulary for the same key. Attacks on a guard's input are invisible to
  a sites-guarded census; the graders are where that residual risk is paid.
- **Seam-edge instruction** (standing, §3.4): the brief carries the seam
  table (the provider rows, their probe states, quirks, and evidence
  paths) with — "find a behavior of this service the probe did not pin:
  identifier-namespace surprises, empty-vs-error semantics, pagination
  and limit behavior, encoding. An owed or unreachable-risk seam is a
  standing question, not a settled one."
- **State-machine instruction** (standing, §6.1): "find a state mutation
  outside the declared table — a second vocabulary for the same field, a
  bulk update, a migration, a serializer default, an admin path. The
  table is the field's whole legal vocabulary and you are its adversary."
- **Findings arrive tagged `bug` or `rule`** (the promotion tell, §5): if
  the fix is "add the protection that already exists somewhere else," the
  finding is a rule, not a bug — /vid fix forks its protocol on this tag.
- **PRD mode** — PRD.md with Fail-if clauses present: grade every live REQ
  against its own Fail-if (base + Appends, later appends win), batched by
  domain ~25–30 REQs per grader, in parallel.
- **Degraded mode** — no PRD: grade against reasonable user/operator
  expectations for what the repo evidently is. Still useful; the report
  header must say so: "degraded mode — no PRD; graded against inferred
  expectations".
- **The wanderer (§5)** — whenever the product can be brought up in the
  browser harness, one additional fresh-context grader runs IN PARALLEL
  with the readers: it drives the RUNNING app with an unscripted
  exploratory brief — out-of-order actions, unusual inputs, boundary-of-
  flow behaviour, anomaly noticing (GRADING.md §The wanderer). It carries
  GRADING-CHECKLIST.md; it is NOT given the journey scripts (following
  them defeats the point) and NOT given any reader's findings — readers
  and wanderer are mutually blind (the verdict-blindness rule: announced
  findings pull judgment toward them). Findings merge only at the owner's
  adjudication, tagged bug/rule like every finding, and NEVER gate. The
  overlap is information: the same defect from both referents is strong
  confirmation; disjoint sets say the defect population is larger than
  either sees. After fixes, a short re-wander over the touched surfaces
  rides with the mandatory re-grade. Cannot bring the product up → the
  report states "wanderer: not run — <reason>"; never a silent skip.
- **Focus areas**, when given, are graded first and deepest; sweep the rest
  only if context allows, and say in the report which areas got depth and
  which got the sweep.
- **Differential mode** (`--vs <path>`): additionally compare the two builds'
  interpretation per requirement/behavior and flag divergences with a
  which-is-more-faithful judgment (GRADING.md §Differential mode).
- **The visual review — standard since v0.8 (§9), no flag needed** (the
  `--visual` flag remains accepted and forces it): wherever a ratified
  design/ exists and the environment can render, screenshot each ratified
  surface × state and put the image beside its cited canvas section for a
  multimodal fidelity read — "does this match P02/populated; is it
  coherent?" — what computed values cannot express: overlap, ordering,
  visual coherence. Judgment, therefore FINDINGS, never a gate and never a
  ledger test. Where the wanderer runs, it carries this review (it is
  already driving the running product — the §5/§9 merge); where rendering
  is impossible, the report states "visual: not run — <reason>", never a
  silent skip. Pixel-diff baselines stay explicitly rejected — flaky on
  fonts and antialiasing, high maintenance, failing for reasons nobody
  cares about; the deterministic sibling is the rendered-vs-cited census
  class (report-only), which asserts named computed properties against
  ratified values, never image equality. Marker citations make spot-checks
  cheap: "compare `.jt-header` to P01's header section" is a 30-second
  grader task because the citation names the target.
- **ViD repos additionally get the decision-mining sweep** — "what choices
  does this code embody that are NOT in DECISIONS.md?", each with file:line
  and the plausible alternative it rejected; plus the data-semantics line
  (§6.3): "list the data-semantics choices this code embodies — what stored
  values mean, their units, casing, monotonicity; which have no constraint
  or test?"; a hand-rolled security mechanism
  (crypto, TOTP/MFA, tokens, signing) without a D-entry is an automatic
  finding. The sweep includes the **court-edit check** (CLAUDE.md court
  governance): `git log --oneline -- checks/` — every commit touching
  checks/ after init must trace to owner law (a PRD append, an owner answer,
  an accepted correction, named in its message or trail); a court edit
  without one is an automatic finding, severity high — the examiner marked
  its own paper. A court WIDENED in the same commit as work it gates is the
  canonical instance. Optionally add the cold-start probe: ask a throwaway
  fresh context "where would you implement <small plausible feature>, and
  which constraints apply?" A wrong answer is a hole in
  CLAUDE.md/ARCHITECTURE.md; the finding is the doc gap, not the feature.

## --robustify — gray-box hardening (§7)

The end grade spreads its budget across all REQs; no grader goes deep on
one subsystem. `--robustify` takes a critical subsystem AS BUILT and
hardens that construction — the fuzzing lesson at subsystem level:
gray-box (structural feedback aiming black-box execution) dominates both
pure strategies. Bounded to 3–5 areas per invocation. Runs after the end
grade's fix rounds stabilise the subsystem; also standalone later.

- **Selection — three doors, all existing signals:** the owner's tier
  (T0 areas); the genus pass; and mechanical discovery — nominate the
  modules with the highest density of Tier-0 rows, rule rows, and
  accepted grade findings (all three already computed: the inventory's
  tier column, the census tables, .vid/grades/). State which door
  nominated each area.
- **The as-built dossier assembles itself** from the coverage join + the
  seam tables: per area, the modules, files, and interfaces implementing
  the area's rows — REQ citations under app source (checks/coverage.sh),
  the ARCHITECTURE.md rows owning those paths, the provider seam rows
  they touch. Mechanical assembly, no narration.
- **The pass:** one fresh deep grader per area (Agent tool, NO
  build-session context), given the area's rows verbatim PLUS the
  as-built map, briefed to enumerate the subsystem's real internal
  interfaces, states, and failure modes. **The output contract is
  proposed ROWS, not findings** — invariant rule rows with denominators,
  state-machine transition tables, additional executable checks, gates
  where warranted — each with provenance and a census command. A return
  that reads like a grade report is re-briefed, not accepted.
- **Doctrine:** selection may be implementation-informed; assertions stay
  behavior-keyed. The grader uses the real construction to decide WHERE
  to aim; what it writes asserts observable behavior at public
  interfaces. A proposed row asserting on an implementation symbol is a
  spec violation, not a style preference — reject it. Independence was
  never ignorance of the code; it is the session boundary.
- **Refusal carried in:** the pass emits rows and probes, NEVER a
  subsystem coverage score — adequacy metrics are measured-unreliable
  proxies, and a percentage would be manufactured comfort.
- Proposals are owner-ratified and enter through /vid fix's normal
  dual-write; nothing lands from this mode directly.

## Output

The first line, in the conversation and in the saved report, is the rows
headline (v0.9.2 3.11, R10): `sh checks/metrics.sh`'s `rows: kept K ·
unverdicted U · breached B · red R · owed O · deploy-owed D (unmet …)` —
`receipt: none` when HEAD has no export-backed report — rows, never
tests, never a proportion (a non-ViD repository has no inventory and the
line is absent, stated). Then one merged findings table, ranked by product
consequence (plain words, no scores):

    severity | area/REQ | bug|rule | finding (one sentence) | evidence file:line | reproduction hint

The report also carries: the law-change log since the last grade (every
law change, with what its trailer admits); and the queued ROW-AMBIGUOUS
rows plus .vid/end-grade-queue.md items from develop's verdict passes, so
nothing filed to the end grade is dropped. In a ViD project it also reads
the open deferrals — each `deferred` event with no later
`deferred-resolved` for its row (v0.9.7.2 3.7, R11), which a breadth-first
develop records in place of that file — and lists each with its row, kind,
why and source, beside the file's items when the file exists.

Present it in the conversation AND save it as a dated report:
`.vid/grades/YYYY-MM-DD-grade.md` (create the directory if absent; second
grade the same day gets `-2`). The header states mode (PRD / degraded /
differential / visual), focus areas if any, grader batch count — and, when
the grade is a round in a loop, the written exit bar and this round's two
numbers (introduced vs exposed). The header also names what was graded
(v0.9.6.2 3.6, R6): `graded: <HEAD's commit, 12 hex>` and `dirty: yes|no`
— yes when the worktree had uncommitted changes. Write each row so the owner can mark it —
an empty `adjudication:` cell per row (accept / dispute / defer) — and hand
the file to `/vid fix <path>`, which applies exactly the accepted rows. The
report is a record, not an artifact: no state, no IDs, nothing downstream
reads it automatically; the owner's adjudication is the only bridge to
/vid fix.
