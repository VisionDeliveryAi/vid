#!/bin/sh
# Purpose: run the ViD ledger (tests/invariants/) — ONLY ever inside the
# container harness via docker-compose.test.yml, so tests physically cannot
# reach anything real. v0.9.2 (3.6: R9 the receipt, R21 one image):
#   sh checks/test.sh                 the certifiable FULL run: HEAD is exported
#                                     (git archive) into a temporary context
#                                     under .vid/, mounted read-only as the tests
#                                     service's /app and used as the product's
#                                     build context; refused on a worktree with
#                                     uncommitted changes ("commit first: a
#                                     receipt names a tree"); the export is
#                                     deleted after the run.
#   sh checks/test.sh -- <selector>   a SCOPED run: the selector is the runner's
#                                     own syntax, opaque here, handed to the
#                                     compose command through VID_SELECTOR; the
#                                     live tree is mounted; never certifiable.
# The receipt: the runner writes its per-case results report to
# .vid/ledger-results/pending.xml (the compose file names the flag); this
# script renames it, only on the runner's own exit, to
# <head-sha>.full.xml (export-backed) or <head-sha>.live.sel-<hash>.xml
# (scoped — an everything-selector through this door, init's red gate, is
# still .live.); an interrupted or killed run leaves no report. One
# `ledger-run seconds=S kind=full|scoped report=<name>` event is appended to
# .vid/metrics-events. The lock: .vid/ledger.lock (mkdir), released on exit;
# a second invocation while it exists is refused naming the holder's pid and
# start time; a stale lock (holder gone) is reported with its age and never
# removed here. VID_COMPOSE overrides the compose command (the selftest
# drives a recording stub in place of the daemon).
# v0.9.3 (3.3, 3.10; R4, R14, R15 — the ungated set, R22: this script reads no
# grammar and changes for every project when checks/ is refreshed):
#   --role builder|fixer|close|grader  names who ran the run; `role=` rides the
#                                     `ledger-run` event (the reader is the wall
#                                     allocation) and RUN-STATE names who ran what.
#   A run that did not run to its end publishes nothing: the compose exit
#   status must be one of the harness contract's `completed:` statuses
#   (x-vid-harness in docker-compose.test.yml — the runner's own "ran to the
#   end" statuses, all passed or some failed); any other status — a signal
#   death, the runner's own interrupt or internal error, a usage error,
#   nothing collected — discards pending.xml whatever it holds, because a
#   runner may have written the cases it got through. A complete report of
#   failing cases is published: red is evidence. Every `ledger-run` event
#   carries `status=<n>`. A compose file without `completed:` keeps the 0.9.2
#   rule (the wrapper's own interrupt flag) and says so on every run.
#   The host lease (3.10, R14): after the repository's lock and before any
#   stack comes up — full or scoped — the wrapper takes one of `stacks` slots
#   (`.vid/budget`, default 1) under ${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/vid-host/
#   (mkdir `stack.<k>`; holder file: pid, repository, compose project, start),
#   across every repository on the host. None free → refused naming each
#   holder. A slot whose holder pid is gone is reported STALE with its age and
#   kept while its containers may still be up (v0.9.7.0.8 T2.2, below).
#   Released on exit. Cleanup stays project-scoped.
#   The deployed shape (3.3, R4): when x-vid-harness declares
#   `deployed-selector:`, a full run is TWO passes on the same export under
#   one lease, each on a fresh stack: (1) the whole ledger as before, inline
#   → <sha>.full.xml; `down --remove-orphans --volumes` (the inline pass's
#   state must not leak; `down` alone keeps named volumes); (2) with
#   VID_INLINE=0 VID_SCHEDULE_FAST=1 and the `deployed` profile, `up -d
#   --build product <the profile's services>` — the product named first so
#   the image is rebuilt before any process starts from it — then the tests
#   with the deployed selector → <sha>.deployed.xml, `ledger-run …
#   kind=deployed`; `down --remove-orphans --volumes`. `--deployed --
#   <selector>` is the scoped deployed run for a builder or fixer chasing a
#   wiring failure: the live tree, the profile, the same order, named
#   <sha>.live.deployed.sel-<hash>.xml, never certifiable. A missing deployed
#   report after a full run is a missing report.
# v0.9.6 (3.7, 3.8, 3.10, 3.13; R7, R8, R10, R13) — two paths in one script.
#   Outside the gate (`sh checks/plan.sh gate` off: every verb but a 0.9.6
#   develop run, init's red gate included) everything above holds as it was,
#   with two changes: the EXIT trap and a signal run the `down` of the pass
#   in progress, with that pass's own arguments; and a run is refused while
#   a live gated run folder exists here (.vid/runs/).
#   Inside the gate, every run — full or scoped — tests a FROZEN copy made
#   from a git tree: a full run HEAD^{tree} (a dirty worktree still refused),
#   a scoped run the working tree as it is (a temporary index: read-tree
#   HEAD, add -A outside .vid/, write-tree; ignored files stay out). Each run
#   has its own folder at the run's home, .vid/runs/<run-id>/ (the id is the
#   start time and the pid): `holder` (pid=, start=, kind=, worktree=,
#   then slot=, project=, tree=), `ctx/` (git archive of the tree),
#   `results/` and `override.yml`; it is deleted after publish. Its compose
#   project is vid-s<k>-<folder name> (k the host slot, so unique on the
#   host); every Compose call and the harness contract read name the frozen
#   copy's file (--project-directory ctx -f ctx/docker-compose.test.yml -f
#   override.yml). The override gives the product and every `processes:`
#   service one image, vid-s<k>-<folder name>:run, maps the tests service's
#   /vid-results to the run's results/, and resets every service's ports:
#   and container_name: with Compose's !reset tag — asked of Compose once
#   per run (`config`); refused, the override keeps the rest, says so, and
#   slots above 1 are refused. The receipt lands in the HOME's
#   .vid/ledger-results/ under a name no later run reuses —
#   <head>.run-<id>.full.xml, <head>.run-<id>.deployed.xml,
#   <head>.live.sel-<hash>.run-<id>.xml, <head>.live.deployed.sel-<hash>.run-<id>.xml —
#   with <head>.full.xml and <head>.deployed.xml written as copies of the
#   newest; beside it <receipt>.tree (tree=, base=, frozen-at=, shape=) and
#   <receipt>.cases (the results reader's `case` lines); the `ledger-run`
#   event goes to the home, names the kept receipt and gains tree= and
#   run=. No .vid/ledger.lock is taken: a held one refuses the run, as the
#   lock refused before. Slots: one, until .vid/budget carries stacks≥2 AND
#   testenv=proved (v0.9.7.0.10 R14: `harness=<cksum>` of this checkout's
#   docker-compose.test.yml, the harness it was proved on); a run passed VID_TESTENV_PROVE=<id> (checks/testenv.sh
#   prove) may take a second slot, exactly two under one id. Teardown runs on
#   every exit path — the normal end, the EXIT trap, a signal — with the
#   `down` arguments of the pass in progress; the slot is released only once
#   it succeeds; a failing `down` keeps the slot and the run folder, marks
#   both holders `teardown-failed <UTC>` and writes `teardown=failed`.
#   --wait <seconds>: a full lease retries every 10 s until a slot is free
#   or the bound passes (then refused as before, naming the holders); a
#   signal while waiting leaves nothing held; `waited=<s>` rides the event.
# v0.9.6.1 (3.1, 3.8; R1, R8) — inside the gate only:
#   --role close -- <selection> [--deployed-selection <selection>]
#                                     a SELECTED CLOSE: export-backed like the
#                                     full run (HEAD's tree; a dirty worktree
#                                     refused), one slot, its own run folder and
#                                     compose project, published at the run's
#                                     home. The inline pass runs
#                                     VID_SELECTOR=<selection> →
#                                     <head>.run-<id>.close.xml, copy
#                                     <head>.close.xml, `ledger-run … kind=close`.
#                                     When the harness declares
#                                     deployed-selector:, the deployed pass runs
#                                     VID_SELECTOR=<the --deployed-selection
#                                     value> → <head>.run-<id>.close.deployed.xml,
#                                     copy <head>.close.deployed.xml,
#                                     `kind=deployed`; a missing
#                                     --deployed-selection is refused, naming it.
#                                     Teardown takes the full run's arguments per
#                                     pass. ViD never builds or combines a
#                                     selection: both are the runner's syntax,
#                                     given by the caller.
#   --role checkpoint -- <selection> [--deployed-selection <selection>]
#                                     a CHECKPOINT: the same path, with its own
#                                     names — <head>.run-<id>.checkpoint.xml,
#                                     <head>.checkpoint.xml, the deployed twin
#                                     <head>.run-<id>.checkpoint.deployed.xml and
#                                     <head>.checkpoint.deployed.xml — and
#                                     `kind=checkpoint`. It holds one slot like
#                                     any run, and is refused below two proved
#                                     environments (it would take the only
#                                     slot); nothing waits for it.
#   --deployed-selection outside a selected close or a checkpoint, or with a
#   harness that declares no deployed-selector:, is refused. Outside the gate
#   `--role close -- <selection>` stays a scoped run and `--role checkpoint`
#   is refused.
# v0.9.7.0.1 (3.1, R1, R2): the gate's home may be found among the
#   repository's checkouts (checks/plan.sh home-of): a worktree with no run
#   and no .vid/home runs gated at the one live run. Two or more live runs:
#   refused, exit 2, before any lock or slot, naming plan.sh home --brief.
# v0.9.7.0.1 (3.2, R5, R6): --role test-author (a test-author's proof) and
#   --role testenv (checks/testenv.sh's own runs) are scoped runs, with a
#   builder's kind, receipt and slot rules. Inside the gate a run with no
#   --role is refused, exit 2, before the lock; outside it runs as before
#   and its `ledger-run` event carries role=-.
# v0.9.7.0.1 (3.3, R7, R8): a pass that did not run to its end — its status
#   outside the harness contract's completed: — or that the wrapper's own
#   signal stopped runs no later pass: no deployed pass, no receipt, the
#   event report=none, a non-zero exit. A completed red pass keeps its
#   deployed pass. With no completed: key the status is classified as
#   before (with the note); only the wrapper's signal stops later passes.
#   Each pass's foreground Compose call runs as a waited child, so a signal
#   to the wrapper acts during the pass: the trap brings the pass down
#   (teardown), waits for that call to end — up to 30 s, else the slot and
#   the run folder are kept as a failed teardown — and exits 130.
#   v0.9.7.0.12 (3.9, R9): inside the gate the signal path stops the call
#   first: TERM to it and its children, up to VID_UP_REAP (60) s for them to
#   be reaped, then the pass's down; with Docker, the compose project's
#   containers are read (`ps -a --filter label=com.docker.compose.project=`)
#   and, any left, 10 s and the down again. The slot and the run folder are
#   released only when the call was reaped and Docker shows none left; a live
#   call, containers left, or a read that fails keeps them as a failed
#   teardown.
# v0.9.7.0.2 (3.1–3.3; R1–R3, R8, R9) — every run is a request:
#   request --type <type> --role <role> --why "<one line>" [--rows <ROW-id,…> | --rows-file <path>]
#           [--steps <id,…>] [--expect <seconds>] [-- <selection> [--deployed-selection <selection>]]
#     answers at once (at most 6 lines: the ticket, the estimate and the limits,
#     the rows with no history, the queue position, the next command) and
#     starts the run detached from the caller, in a new session where the
#     host offers one. Types and who may ask: prove-red (test-author,
#     orchestrator, fixer), iterate (builder, fixer, test-author, testenv),
#     close, checkpoint and full (orchestrator), deployed (builder, fixer).
#     Rows: --rows/--rows-file for prove-red, iterate and deployed; a close
#     reads them from `sh checks/metrics.sh close-rows --steps`, a checkpoint
#     from `sh checks/metrics.sh checkpoint --population` (v0.9.7.0.12 R7: the
#     eligible rows of closed steps and the materialised probes), full from
#     INVENTORY.md. The
#     selection is the caller's, in the runner's syntax (ViD never builds
#     one); full takes none. The ticket is .vid/requests/<UTC>-<4 hex>/ at the
#     run's home (here outside a run): `request` (the arguments, rows,
#     estimate, limits), `state` (queued, running, done, capped,
#     failed-to-start, stopped), `log` (the run's own output, never
#     printed), `passes`, `result`. The run is this script's matching
#     invocation with --wait (the lease's wait is the queue) and
#     VID_REQUEST=<ticket>; the run role is the asker's, except close and
#     full (`close`) and checkpoint (`checkpoint`).
#     The estimate: each row's case seconds in the newest .cases at the
#     home naming it, plus start-up — the median of (event seconds − summed
#     case seconds) over the newest 20 kept receipts, 90 s with none (v0.9.8.1
#     R11: a receipt whose case seconds exceed its event seconds is left out,
#     never counted as 0); a row
#     with no history 10 s; --expect <s> replaces the rows' case total of
#     one pass and is recorded (v0.9.8.1 R12: an iterate whose deployed
#     selection repeats an inline selection word counts the cases once a
#     pass, --expect included). v0.26.10.4 (R1–R5): the estimate stops nothing — it
#     plans, shows and chunks. A watcher started with the run (rq_watch) stops it on
#     silence: no new output for the silence limit (20 min), a watched pass's
#     start-up past the start-up limit (60 min), or the run limit (24 h awake) —
#     `.vid/budget` silence-minutes=, startup-minutes=, run-limit-minutes=; the env
#     VID_SILENCE_SECONDS, VID_STARTUP_SECONDS, VID_RUN_LIMIT_SECONDS override them
#     (the self-test's). Time is ticks × 5 s, so a host sleep never counts. It
#     writes `cap-hit` (reason=silent|startup|limit, last-output=) and stops the run
#     through the signal path (no later pass, no receipt, `capped=yes
#     stop=<reason>` in the event). The request carries silence=, startup=, limit=
#     (the estimate's start-up term is estimate-startup=; old tickets' cap= and
#     slept= are still read as written). Only the run's own completion writes a
#     final state, after `result`.
#   wait <ticket>  reads `state` every 5 s for at most 200 s: queued → one line
#     `queued <elapsed>s of estimate <e>s`; running → `running <awake>s of
#     estimate <e>s, silent <s>s of <limit>s`, the watcher's own counts from its
#     `watch` file (`stopping (<reason>)` while cap-hit exists), exit 75; still
#     running while its watcher's process is gone → `overdue`, exit 76; ended
#     (done, capped, failed-to-start, stopped, with `result`) → `result`, and
#     the run's own exit status; no such ticket → exit 2. Never the run's log.
#   VID_WAIT_MAX is a test-only override (the wait's bound in seconds).
#   v0.9.7.3 (3.9, R9): VID_WAIT_MAX is ignored in a checkout whose .vid/home
#   names a run. A capped result's first line says why (v0.26.10.4 R4).
# v0.9.7.0.3 (3.1; R1–R3) — the test analyst's triggers: a request's
#   completion, after `result` and before the final `state`, checks three
#   triggers in order (a legacy plain run never: it is no request):
#   cap — `cap-hit` is in the ticket folder (v0.26.10.4 R6: any of its three reasons; the event and the line carry
#   stop=<reason> last-output=<UTC>); setup — AN_SETUP_CASES or more
#   of the run's cases are red (not passed or skipped), each over
#   AN_SETUP_SECONDS, whatever their messages; slow — a case over
#   AN_SLOW_SECONDS, named by its row when `checks/evidence.sh reach`
#   credits one, else by its case id, unless an `analyst-done …
#   outcome=limit` at the home names it (its row in `rows=`, or its case id
#   in `cases=`). The run's cases are each kept report's .cases (else the
#   results reader's) and a candidate's kept in the ticket folder; a capped
#   run keeps no report, so only `cap` can fire on it. Each trigger that
#   fires appends one `analyst-due request=<ticket> reason=<reason>
#   [rows=<ids>] [cases=<ids>] [group="<message> (<n> cases); …"]` event at the home (v0.9.8.1 R42: group= is
#   built from the red cases over the setup limit that tripped the trigger, one entry per group with its count)
#   and one `analyst due: <reason> request=<ticket> …` line to `result`.
# v0.9.7.0.8 (T1): the <folder name> of a gated run's compose project and
#   image is the folder's name lowercased, each run of characters other
#   than [a-z0-9] one `-`, no `-` at either end, cut to 40, `project` when
#   nothing is left — so vid-s<k>-<name>:run is a valid image name.
# v0.9.7.0.8 (T2.1): a request says why it waits. At each try for a slot
#   the run writes the holders — the refusal's lines, live or STALE with
#   age, repository and compose project — to its ticket folder's `holders`;
#   `wait` prints them after its line while the state is `queued`; the
#   request's `queue:` line counts held slots live and stale.
# v0.9.7.0.8 (T2.2; reverses 0.9.3's "never removed", by the owner's ruling
#   of 2026-10-03): a run that finds no free slot — waiting or about to be
#   refused — frees a slot only when its holder pid is gone (kill -0 fails),
#   Docker answers, and `docker ps -a -q --filter
#   label=com.docker.compose.project=<the holder's project>` is empty. The
#   slot folder is moved aside to reclaim.<k>.<pid> (atomic: one waiter
#   wins), checked to hold the holder judged — else put back, it was
#   retaken meanwhile — then removed, with one `slot-reclaimed slot=<k>
#   project=<p> holder-pid=<pid> age=<s>` event at the run's home, and the
#   run tries again at once. Kept, as before, while Docker does not answer,
#   while any container of that project is left, or when the holder file is
#   unreadable; its STALE line then says which. A teardown-failed slot
#   takes the same container check. No time-based expiry: a long run is
#   not a dead one. VID_DOCKER overrides the docker command; with
#   VID_COMPOSE set and no VID_DOCKER, Docker is taken as not answering.
# v0.9.7.0.9 (3.1, R1): the estimate counts lines it has not seen. For a row
#   with history, its test file is the first token of its INVENTORY.md test
#   field; the lines holding the row's id (ROW-n or ROW_n, whole — the
#   builder brief's section 9 search, the same awk line as checks/brief.sh)
#   are counted at the commit the history's receipt names (the name's head
#   sha) and in the working tree; each line gained adds 10 s, and the
#   no-history line lists the row as `ROW-x (+k lines since its history)`.
#   No test field, no file or an unreadable commit: no change. Lines, not
#   cases: comments match too, so it only ever adds time.
# v0.9.7.0.9 (3.2, R2): a capped run set a floor on its rows' estimates —
#   removed by v0.26.10.4 (R5): a run stopped on silence says nothing about
#   its rows' duration. A capped run still keeps no receipt.
# v0.9.7.0.9 (3.3, R3): a selection word holding whitespace or a quote is
#   refused at once — by `request` before a ticket, by the direct run
#   before any stack — naming the word: the harness command can't carry it.
#   `serve` passes the ticket's selection as its words, one per argument,
#   so the joined string and its hash are unchanged.
# v0.9.7.0.9 (3.5, R6): `request --type iterate` by a builder, fixer or
#   test-author takes `--deployed-selection <selection>` when the harness
#   declares deployed-selector: (refused when it does not): one ticket, one
#   slot, one watcher; the inline pass (<head>.live.sel-<hash>.run-<id>.xml),
#   then unless stopped the deployed pass, named by its own selection's
#   hash (<head>.live.deployed.sel-<hash>.run-<id>.xml), each on a fresh
#   stack; the estimate counts the start-up twice and the cases once.
# v0.9.7.0.9 (3.4, R4): `sh checks/test.sh analyst-due` prints `analyst
#   due: request=<t> reason=<r>` for each `analyst-due` event at the run's
#   home (here outside a run) with no `analyst-done request=<t>` — at most
#   10 lines, then `(+k more)`; it writes nothing and refuses nothing. The
#   run manager alone starts the analyst: it runs this after every
#   test-author return and at each slice close, and `checks/brief.sh
#   return` prints the same lines after its `ok`.
# v0.9.7.0.10 (3.1; R1–R4, R10) — inside the gate each pass publishes, then
#   tears down: its `seconds=` holds no teardown, and each teardown is its
#   own `teardown seconds=<s> report=<name|none>` event. A request's last
#   pass published — the deployed pass, the inline pass with none after it,
#   or the inline pass when a later pass is stopped — this script writes
#   the ticket's `exit` (the aggregate status), `result`, the analyst's
#   triggers and the final `state` (rq_final, once; `serve` then writes
#   nothing), and stops the run's watcher; then it tears down. The slot and
#   the run folder are released after the final teardown, as before; `wait`
#   adds `teardown pending` while the ticket's run folder (`run` in the
#   ticket) is held. A teardown that fails between two passes stops the
#   later pass: a non-zero exit, a result naming it, the slot and the run
#   folder kept. Any failed teardown inside the gate writes
#   `teardown-failed request=<ticket|-> project=<p>` at the run's home; the
#   result stands. A run outside the gate keeps the old order: teardown,
#   then publish, then the result after cleanup. The estimate of a request
#   with two passes adds the teardown between them once: the median of the
#   newest 20 `teardown` events' seconds (none: 0).
# v0.9.7.0.10 (3.2, R5): each pass published inside the gate adds
#   `overhead=<s>` to its `ledger-run` event, after the request's fields:
#   its seconds minus the sum of its cases' seconds in its .cases, never
#   below 0 — everything outside the tests: the image build, the services,
#   installs, the runner's own start. A run outside the gate keeps no .cases
#   and records none.
# v0.9.7.0.10 (3.3, R6, revision 4; replaced by v0.9.7.0.11 R7, below): a gated request whose inline pass
#   recorded overhead= over TIMELINE_SECONDS saves the stack's Compose logs
#   (`logs --timestamps`) to the ticket's `timeline.log` before that pass's
#   teardown; nothing becomes due for it. R7: the due reader lists only the
#   retained reasons (cap, setup, slow), so a recorded `analyst-due …
#   reason=startup` stays in the events and is never listed.
# v0.26.10.5 (R8): `request --type full --stage N` — the full run of a stage close; `stage=N` in the request. Its
#   analyst's setup and slow triggers count only the cases of stages 1 to N (checks/stages.sh scope): later stages'
#   rows are red in that run and are not read. Nothing else in the run changes.
# v0.9.7.0.11 (3.1, R1): a request's report credits only the rows the request was frozen with. Before a report is
#   published its `<report>.rows` (a copy of the ticket's `rows`; a full run has none) is written beside it, and
#   copied with it to the commit-named copy. A report whose cases reach rows outside them is published and kept all
#   the same: the event carries `outside=<n>`, the ticket's `outside` names the rows, the result says `outside n=<n>
#   rows=<…> — not credited`, later passes run, and the exit comes from the cases (checks/evidence.sh credit).
# v0.9.7.0.11 (3.3, R3): inside the gate a request's pass watches its stack while the tests run. From the moment the
#   tests container is `running` until it has exited, every SVCPOLL s (15) one `docker inspect` over the run's compose
#   project: a container of another service that exited non-zero or was killed for memory (OOMKilled), its FinishedAt
#   at or after the tests' StartedAt, stops the run — the cause latched in the run folder first (`stopped: service
#   <name> exited code <c>|killed for memory at <UTC> — see services.<pass>.txt`), then the watcher's stop path (TERM to
#   this script). Nothing is published; the result's first line is the cause; `ledger-run … report=none status=130 …
#   stopped=service:<name>`. Exit 0 is no death (a one-shot); unhealthy is not judged. The watcher is stopped and
#   reaped before publish and teardown. Docker only (VID_DOCKER), so stack-neutral; none without Docker.
# v0.9.7.0.11 (3.4, R4): each gated pass of a request writes the ticket's services.<pass>.txt (inline|deployed) before
#   its `down`, inside teardown() — the signal path too: one line per container, name state= exit= memory-kill=
#   health= restarts= started-at= ready-at= (the first passing check Docker kept in its health log, else -) finished-at=.
#   v0.9.8 (R17): `ready-at=` is renamed `kept-healthy-at=` — what Docker still kept, not when the service was ready.
# v0.9.7.0.11 (3.7, R7; it replaces v0.9.7.0.10 R6's threshold and its timeline.log): each gated pass of a request,
#   after its result is written and before its `down`, saves the ticket's timeline.<pass>.log — `logs --timestamps
#   --tail 20000`, its last 20 MB, best-effort, at most 60 s. v0.9.8.1 (R27): a red pass, or one short of its end,
#   keeps its whole timeline instead, compressed, timeline.<pass>.log.gz, at most 100 MB keeping the end (tl_whole).
#   v0.9.8.1 (R44): short of its end includes a cap, a cancel and any stop — the signal path saves the whole timeline
#   and each service's last 200 lines (last-lines.<pass>.log) before the pass's down (tl_stop).
# v0.9.7.0.11 (3.5, R5): slot admission runs under one host lock, vid-host/admit.lock; with another ViD slot held, a
#   slot is taken only when Docker's MemTotal − non-ViD projects' containers' memory − env-mb × slots held (a
#   capacity estimate; a held slot reserves env-mb, started or not) ≥ env-mb + memory-headroom-mb (.vid/budget);
#   else the run waits as for a busy slot, its `holders` saying `waiting for memory: estimate <e> MB, needed <n> MB`.
#   The first slot is never held back; no env-mb (or no Docker), no check.
# v0.9.7.0.11 (3.6, R6): `request` refuses a close, full or checkpoint at once while the worktree has changes outside
#   .vid/, naming up to 5 paths. At serve, before taking a slot, a dirty worktree makes such a request wait,
#   re-checked each round, `waiting for a clean worktree` in its `holders`, for up to VID_DIRTY_WAIT (600) s, then
#   refused as before. What runs is HEAD's tree at serve, and the receipt names that HEAD.
# v0.9.7.0.11 (3.2, R2): harness rule 4 — the harness's x-vid-harness `case-limit:` is exported as VID_CASE_LIMIT
#   into the environment Compose interpolates; the tests service references it, and its runner stops one case at the
#   limit, failed by name, the run going on. No key, no variable.
# v0.9.7.0.11 (3.9, R9): `request --type deployed`, when the harness declares deployed-selector:, refuses before its
#   ticket any row that is neither a journey nor actor (process) (checks/evidence.sh kinds), naming them: a deployed
#   receipt can't credit them. An iterate with --deployed-selection is unchanged.
# v0.9.7.1 (3.5a, R5): `wait` returns within 200 s (was 240); VID_WAIT_MAX stays the self-test's override; the
#   exit codes, `teardown pending` and the result before teardown are unchanged.
# v0.9.7.1 (3.6, R6) — cancel by attempt. `request --try <id>` carries the attempt id of a builder's or fixer's
#   brief into the ticket (`try=`) and its events; a builder's or fixer's request without it is refused.
#   `cancel --try <id> [--by <who>]`: for each ticket at the run's home carrying that try (v0.9.8.1 R28: or `cancel
#   --ticket <id>`, the one ticket of that id — exactly one of the two; its event's try= empty when it has none) — a terminal one (done,
#   capped, failed-to-start, stopped, cancelled) is left alone; else a `cancel` mark is written (by, at), and,
#   when the state is `running` and the process `pid` names still has the start time `serve` recorded beside it
#   (`pid-start`) — or, with no start time recorded (a ticket served inside an agent's sandbox), it is the child of
#   the ticket's own `serve`, whose command names the ticket — TERM goes to it through the stop path. Nothing is ever signalled before its trap is set, nor a
#   stale pid. The mark is read by `serve` before it starts the run (a marked ticket never starts), and by the
#   run itself at each round of its wait for a slot and right after it writes `running` — then it takes its own
#   signal path, with the trap's cleanup. The ticket ends `cancelled` after its normal teardown: `exit` 77, the
#   result's first line `cancelled by <who>`; `wait` counts it terminal. Published results, receipts and
#   diagnostics are kept; a repeated cancel is a no-op. Event: `ticket-cancelled ticket= try= by=`. The run
#   manager's batch tickets carry no try and keep 0.9.7.0.12's stop.
# v0.9.8 (3.4, R4, R15) — a fault proof's runs. `request --purpose proof`, asked by the orchestrator, takes a prove-red,
#   or a deployed pass (for a row whose evidence is deployed-shape; `deployed` is otherwise a builder's or fixer's);
#   any other type or role is refused. One at a time: refused while another proof request at the run's home is not
#   terminal. The ticket carries `purpose=proof`, the `ledger-run` event `purpose=proof`, the `.tree` a
#   `purpose=proof` line, and the scoped receipt is named `.proof.` where an ordinary one is `.live.`
#   (<head>.proof.sel-<hash>.run-<id>.xml, <head>.proof.deployed.sel-<hash>.run-<id>.xml) — never an ordinary name, so
#   no copy or alias is overwritten. The one ordinary-receipt rule is checks/evidence.sh's (`ordinary`): every reader
#   that credits, claims, briefs, estimates or triggers skips such a receipt. Here: the estimate's history and its
#   start-up median read no proof receipt, and a proof's completion fires no analyst
#   trigger. Cost accounting keeps it (its `ledger-run` event stands).
set -eu
# v0.9.7.0.3 (3.1): the analyst's thresholds — named in skills/vid-test-manager
AN_SETUP_CASES=5; AN_SETUP_SECONDS=60; AN_SLOW_SECONDS=240
SVCPOLL=${VID_SERVICE_POLL:-15}   # v0.9.7.0.11 (3.3, R3): the stack watcher's period; the override is the self-test's, as VID_WAIT_MAX

# --- v0.9.7.0.2 (3.1–3.3): requests, waits and the detached run ----------------------
TX=$(printf '\t')
rq_die() { echo "ViD test: refused — $*" >&2; exit 2; }
rq_usage() { echo 'ViD test: usage — sh checks/test.sh request --type prove-red|iterate|close|checkpoint|full|deployed --role <role> [--try <id>] [--purpose proof] --why "<one line>" [--rows <ROW-id,…> | --rows-file <path>] [--steps <id,…>] [--expect <seconds>] [--stage <N>] [-- <selection> [--deployed-selection <selection>]] | request --type close --role orchestrator --steps <id,…> --batch --phase1 <file> --phase2 <file> --why "<one line>" | wait <ticket> | cancel --try <id>|--ticket <id> [--by <who>] | analyst-due' >&2; exit 2; }
rq_kv() { sed -n "s/^$1=//p" "$2" 2>/dev/null | head -n 1; }
# v0.9.7.0.9 (3.3, R3): a selection word holding whitespace or a quote, which the harness command can't carry — refused at once
selword() { case "$1" in *[[:space:]]*|*\'*|*\"*) echo "ViD test: refused — the selection word '$1' holds a space or a quote, which the harness command can't carry; select by test ids, without spaces" >&2; exit 2 ;; esac; }
rq_put() { printf '%s\n' "$2" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"; }   # one value, replaced whole
# pid_alive <pid>: the process exists — v0.9.7.1 (found in rehearsal R-6): a run started inside an agent's sandbox can't
# signal other processes (kill -0 says "Operation not permitted"); only "No such process" means gone
pid_alive() { [ -n "$1" ] || return 1; _pe=$(kill -0 "$1" 2>&1) && return 0; case "$_pe" in *'No such process'*) return 1 ;; esac; return 0; }
rq_hostd() { _hd="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"; printf '%s/vid-host\n' "${_hd%/}"; }
# rq_sub <id>: a ticket id's folder under .vid/requests/ — v0.9.7.0.12 (3.2, R2): a batch's chunk `<ticket>/<n>` is <ticket>/chunks/<n>
rq_sub() { case "$1" in */*) printf '%s/chunks/%s\n' "${1%%/*}" "${1#*/}" ;; *) printf '%s\n' "$1" ;; esac; }
# rq_dir <ticket> [<home>]: the ticket's folder — at the run's home, else here
rq_dir() { for _d in "${2:-.}/.vid/requests/$(rq_sub "$1")" ".vid/requests/$(rq_sub "$1")"; do [ -d "$_d" ] && { (cd "$_d" && pwd); return 0; }; done; return 1; }
# v0.26.10.3 (R8, F-42): the run's home whether the gate is on or not (plan.sh home-of), else '' — and a ticket found
# wherever its run is: at that home, here, then in every checkout's .vid/requests/ (ticket ids are unique), so a stopped
# run's ticket is found after its agent has ended; rq_stopped <ticket dir> prints "the run is stopped" when its home's
# RUN-STATE says so
rq_home() { [ -f checks/plan.sh ] || return 0; sh checks/plan.sh home-of 2>/dev/null | head -n 1; }
rq_find() { rq_dir "$1" "$2" && return 0
  for _w in $(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do [ -d "$_w/.vid/requests/$(rq_sub "$1")" ] && { (cd "$_w/.vid/requests/$(rq_sub "$1")" && pwd); return 0; }; done; return 1; }
rq_stopped() { _sh=${1%/.vid/requests/*}; [ "$(sed -n 's/^run:[[:space:]]*//p' "$_sh/.vid/RUN-STATE.md" 2>/dev/null | head -n 1 | awk '{ print $1 }')" = stopped ] && echo 'the run is stopped'; return 0; }
# ROWLINES: the awk program of the builder brief's section 9 search (checks/brief.sh holds the same line) — the numbers
# of the lines holding row id `a` as ROW-n or ROW_n, a whole id, comma-separated
ROWLINES='BEGIN { b = a; gsub(/-/, "_", b) } function w(s, id,   p, q, o, x, y) { q = s; o = 0; while ((p = index(q, id)) > 0) { x = (o + p > 1) ? substr(s, o + p - 1, 1) : ""; y = substr(s, o + p + length(id), 1); if (x !~ /[A-Za-z0-9]/ && y !~ /[A-Za-z0-9]/) return 1; o += p; q = substr(s, o + 1) } return 0 } w($0, a) || w($0, b) { printf "%s%d", (n++ ? "," : ""), NR }'
# rq_nlines <row>: how many lines of stdin name the row (the section 9 search)
rq_nlines() { awk -v a="$1" "$ROWLINES" | tr ',' '\n' | grep -c . || true; }
# rq_estimate <home> <rows file> → STARTUP CASES EST NH, $RQT/nohist, $RQT/unseen (R8; v0.9.7.0.9 R1; v0.26.10.4 R5: no cap, no floor)
# SUPN (default 1): how many times the start-up is counted — 2 for an iterate request carrying both passes (R6)
# CASN (default 1): how many times the cases are counted — 2 when that request's deployed selection repeats an inline word (v0.9.8.1 R12)
# TWOP (default no): yes for a request with two passes — its teardown between them is counted once, TDN
# (v0.9.7.0.10 3.1, R10: the median of the newest 20 `teardown` events' seconds at the home; none, 0)
rq_estimate() {
  _ev="$1/.vid/metrics-events"; _rd="$1/.vid/ledger-results"
  : > "$RQT/kept"
  if [ -f "$_ev" ]; then   # the kept receipts with their cases, oldest first: name, event seconds
    awk '$1 == "ledger-run" { r = ""; s = ""; for (i = 2; i <= NF; i++) { if (index($i, "report=") == 1) r = substr($i, 8); else if (index($i, "seconds=") == 1) s = substr($i, 9) }
      if (r != "" && r != "none" && !index(r, ".proof.")) print r "\t" s }' "$_ev" | while IFS="$TX" read -r _r _s; do [ -f "$_rd/$_r.cases" ] && printf '%s\t%s\n' "$_r" "$_s"; done > "$RQT/kept" || true   # v0.9.8 (R15): a proof receipt estimates nothing
  fi
  # v0.9.8.1 (R11, F-10; the live project's A-274): a receipt whose case seconds exceed its wall time (a merged split
  # run, parallel chunks) tells nothing of start-up — it is left out, never counted as 0
  STARTUP=$(tail -n 20 "$RQT/kept" | while IFS="$TX" read -r _r _s; do awk -v s="${_s:-0}" '$1 == "case" { c += $4 } END { d = s - c; if (d >= 0) print d }' "$_rd/$_r.cases"; done |
    sort -n | awk '{ v[NR] = $1 } END { if (NR == 0) print 90; else if (NR % 2) printf "%d\n", v[(NR + 1) / 2] + 0.5; else printf "%d\n", (v[NR / 2] + v[NR / 2 + 1]) / 2 + 0.5 }')
  # v0.9.8.1 (R32, F-22): the start-up of each profile is the median overhead= of the newest 10 ledger-run events of
  # that profile (deployed: kind=deployed or a .deployed. report; else inline; never a proof's); with fewer than 3,
  # the figure above. STARTUP is the inline one, STARTUPD the deployed one
  _ovm() { [ -f "$_ev" ] || return 0; awk -v want="$1" '$1 == "ledger-run" { o = ""; r = ""; k = ""
        for (i = 2; i <= NF; i++) { if (index($i, "overhead=") == 1) o = substr($i, 10); else if (index($i, "report=") == 1) r = substr($i, 8); else if (index($i, "kind=") == 1) k = substr($i, 6) }
        if (o == "" || r == "" || r == "none" || index(r, ".proof.")) next
        p = (k == "deployed" || index(r, ".deployed.")) ? "deployed" : "inline"; if (p == want) print o }' "$_ev" | tail -n 10 | sort -n |
      awk '{ v[NR] = $1 } END { if (NR < 3) exit; if (NR % 2) printf "%d\n", v[(NR + 1) / 2] + 0.5; else printf "%d\n", (v[NR / 2] + v[NR / 2 + 1]) / 2 + 0.5 }'; }
  STARTUPD=$(_ovm deployed); [ -n "$STARTUPD" ] || STARTUPD=$STARTUP
  _sui=$(_ovm inline); [ -n "$_sui" ] && STARTUP=$_sui
  # each row's case seconds in the newest .cases naming it (its id, or the spelling a test name uses)
  # (and, v0.9.7.0.9, the receipt it came from: H <row> <seconds> <receipt>)
  awk '{ a[NR] = $1 } END { for (i = NR; i >= 1; i--) print a[i] }' "$RQT/kept" | while IFS= read -r _r; do printf '\001FILE\t%s\n' "$_r"; cat "$_rd/$_r.cases"; done |
    awk -v rf="$2" 'function flush(  r) { for (r in CUR) if (!(r in D)) { D[r] = CUR[r]; F[r] = cf; nd++ } split("", CUR) }
      BEGIN { while ((getline l < rf) > 0) if (l != "" && !(l in W)) { W[l] = 1; nw++ } }
      index($0, "\001FILE\t") == 1 { flush(); if (nd >= nw) exit; cf = substr($0, 7); next }
      $1 == "case" { t = $2; split("", SN); while (match(t, /ROW[-_][0-9]+/)) { m = substr(t, RSTART, RLENGTH); gsub(/_/, "-", m); t = substr(t, RSTART + RLENGTH)
          if ((m in W) && !(m in D) && !(m in SN)) { CUR[m] += $4; SN[m] = 1 } } }
      END { flush(); for (r in W) if (r in D) print "H\t" r "\t" D[r] "\t" F[r]; else print "N\t" r }' > "$RQT/hist"
  grep '^N' "$RQT/hist" | cut -f2 | sort > "$RQT/nohist" || true
  NH=$(grep -c . "$RQT/nohist" || true)
  # v0.9.7.0.9 (3.1, R1): a row with history adds 10 s for each line naming it that its test file (the first token of
  # its INVENTORY.md test field) has gained since the commit its history's receipt names — lines, never cases
  : > "$RQT/unseen"
  if [ -f INVENTORY.md ]; then
    sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      { id = tr($1); if (id !~ /^ROW-/) next; t = tr($8); sub(/[ \t].*/, "", t); print id "\t" t }' > "$RQT/tests"
    awk -F'\t' '$1 == "H" { print $2 "\t" $4 }' "$RQT/hist" | sort | while IFS="$TX" read -r _id _rc; do
      _t=$(awk -F'\t' -v r="$_id" '$1 == r { print $2; exit }' "$RQT/tests")
      case "$_t" in ''|owed:*) continue ;; esac
      [ -f "$_t" ] || continue
      _sha=${_rc%%.*}
      git cat-file -e "$_sha:./$_t" 2>/dev/null || continue
      _n0=$(git show "$_sha:./$_t" 2>/dev/null | rq_nlines "$_id"); _n1=$(rq_nlines "$_id" < "$_t")
      [ "$_n1" -gt "$_n0" ] && printf '%s\t%s\n' "$_id" "$((_n1 - _n0))"
    done > "$RQT/unseen" || true
  fi
  # v0.26.10.4 (R5): no capped floor — a run stopped on silence says nothing about its rows' duration
  CASES=$(awk -F'\t' -v uf="$RQT/unseen" '
    BEGIN { while ((getline l < uf) > 0) { split(l, a, "\t"); U[a[1]] = a[2] } }
    { r = $2; if ($1 == "H") v = $3 + 10 * U[r]; else v = 10; s += v }
    END { printf "%d\n", s + 0.999 }' "$RQT/hist")
  # v0.9.8.1 (R26, F-15): a selection word that names a test file reaches every recorded case of it — the newest
  # seconds of each, inline receipts for the inline selection, deployed ones for the deployed — and the larger of
  # that and the rows' own figure is taken (FROMF=yes). A word resolving to no recorded case (a -k expression, a
  # marker, a new file) leaves the figure as it is and is listed in $RQT/unresolved. Only file paths are resolved;
  # the runner's selection stays opaque.
  FROMF=no; : > "$RQT/unresolved"
  _fw=no; for _w in ${RSEL:-} ${RDSEL:-}; do case "$_w" in *::*) ;; *) _fw=yes ;; esac; done   # test ids alone: the rows' figure covers them
  if [ "$_fw" = yes ] && [ -z "$EXPECT" ]; then
    awk '{ a[NR] = $1 } END { for (i = NR; i >= 1; i--) print a[i] }' "$RQT/kept" | while IFS= read -r _r; do
      _sh=$(sed -n 's/^shape=//p' "$_rd/$_r.tree" 2>/dev/null | head -n 1); [ "$_sh" = deployed ] || _sh=inline
      awk -v s="$_sh" '$1 == "case" { print s "\t" $2 "\t" $4 }' "$_rd/$_r.cases"; done | awk -F'\t' '!(($1, $2) in x) { x[$1, $2] = 1; print }' > "$RQT/allcases"
    FILEC=$(awk -F'\t' -v si="${RSEL:-}" -v sd="${RDSEL:-}" -v uf="$RQT/unresolved" '
      BEGIN { ni = split(si, I, " "); nd = split(sd, D, " ") }
      { CI[++n] = $2; S[n] = $3; SH[n] = $1 }
      function reach(w, shape,   i, t, hit) { t = 0; hit = 0
        for (i = 1; i <= n; i++) { if (CI[i] == w) hit = 1; if (index(CI[i], w "::") == 1) { hit = 1; if (SH[i] == shape) t += S[i] } }
        if (!hit && !(w in U)) { U[w] = 1; print w > uf }
        return t }
      END { for (k = 1; k <= ni; k++) f += reach(I[k], "inline"); for (k = 1; k <= nd; k++) f += reach(D[k], "deployed"); printf "%d\n", f + 0.999 }' "$RQT/allcases")
    if [ "${FILEC:-0}" -gt $(( ${CASN:-1} * CASES )) ]; then CASES=$FILEC; CASN=1; FROMF=yes; fi
  fi
  [ -n "$EXPECT" ] && CASES=$EXPECT
  TDN=0
  if [ "${TWOP:-no}" = yes ] && [ -f "$_ev" ]; then
    TDN=$(awk '$1 == "teardown" { for (i = 2; i <= NF; i++) if (index($i, "seconds=") == 1) print substr($i, 9) }' "$_ev" | tail -n 20 |
      sort -n | awk '{ v[NR] = $1 } END { if (NR == 0) print 0; else if (NR % 2) printf "%d\n", v[(NR + 1) / 2] + 0.5; else printf "%d\n", (v[NR / 2] + v[NR / 2 + 1]) / 2 + 0.5 }')
  fi
  # the start-up term: a deployed-only request the deployed figure; two passes the inline and the deployed; else the inline
  if [ "${TYPE:-}" = deployed ]; then SUT=$STARTUPD; elif [ "${SUPN:-1}" -eq 2 ]; then SUT=$((STARTUP + STARTUPD)); else SUT=$STARTUP; fi
  EST=$(( SUT + ${CASN:-1} * CASES + TDN ))
}
# v0.26.10.4 (R1–R3): rq_limits <home> → SIL SUL LIM, the silence, start-up and run limits in seconds — 20, 60 and
# 1440 minutes, else the home's .vid/budget `silence-minutes=`, `startup-minutes=`, `run-limit-minutes=`; the env
# VID_SILENCE_SECONDS, VID_STARTUP_SECONDS, VID_RUN_LIMIT_SECONDS override them (the self-test's)
rq_limits() {
  _bm() { _v=$(sed -n "s/^$1=\([0-9][0-9]*\).*/\1/p" "$2/.vid/budget" 2>/dev/null | head -n 1); [ -n "$_v" ] && [ "$_v" -gt 0 ] && echo $((_v * 60)) || echo "$3"; }
  SIL=$(_bm silence-minutes "$1" 1200); SUL=$(_bm startup-minutes "$1" 3600); LIM=$(_bm run-limit-minutes "$1" 86400)
  case "${VID_SILENCE_SECONDS:-}" in ''|*[!0-9]*) ;; *) SIL=$VID_SILENCE_SECONDS ;; esac
  case "${VID_STARTUP_SECONDS:-}" in ''|*[!0-9]*) ;; *) SUL=$VID_STARTUP_SECONDS ;; esac
  case "${VID_RUN_LIMIT_SECONDS:-}" in ''|*[!0-9]*) ;; *) LIM=$VID_RUN_LIMIT_SECONDS ;; esac
}
# rq_dur <seconds>: a limit as said — `20 min`, `24 h`, `45 s`
rq_dur() { if [ "$1" -gt 3600 ] && [ $(($1 % 3600)) -eq 0 ]; then echo "$(($1 / 3600)) h"; elif [ "$1" -ge 60 ] && [ $(($1 % 60)) -eq 0 ]; then echo "$(($1 / 60)) min"; else echo "$1 s"; fi; }
# rq_size <file>: its bytes, 0 when it is not there
rq_size() { if [ -f "$1" ]; then wc -c < "$1" | tr -d ' '; else echo 0; fi; }
# rq_watch <ticket dir>: the run's watcher (v0.26.10.4 R1–R3; it replaces the cap's) — from `running`, one tick each
# 5 s, every count ticks × 5 s, so a host sleep pauses it and never counts. The pass is the run's `pass` file
# (inline|deployed); its phase is `tests` once `tests-at.<pass>` exists, else `startup`. New output: new bytes in the
# ticket's `log`; during start-up also new bytes in the pass's Compose output (`compose.<pass>.err`) and a changed
# last line of any service (`svcout.<pass>`, the services watcher's); after the tests start, only the tests
# service's line. Each tick writes `watch` (awake= silent= pass= phase= at=). It stops the run — `cap-hit` with
# reason= and last-output=, then TERM through the signal path — when the silence reaches the silence limit, a
# watched pass's start-up (the services watcher started for it) reaches the start-up limit, or the awake time the run limit.
rq_watch() {
  while :; do
    case "$(cat "$1/state" 2>/dev/null)" in running) break ;; queued) ;; *) return 0 ;; esac
    kill -0 "$(cat "$1/supervisor" 2>/dev/null || echo 0)" 2>/dev/null || return 0
    sleep 1
  done
  _sil=$(rq_kv silence "$1/request"); _sul=$(rq_kv startup "$1/request"); _lim=$(rq_kv limit "$1/request")
  _p0=inline; { [ "$(rq_kv type "$1/request")" = deployed ] || { [ -z "$(rq_kv sel "$1/request")" ] && [ "$(rq_kv hasdsel "$1/request")" = yes ]; }; } && _p0=deployed
  _aw=0; _si=0; _su=0; _pa=''; _last=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); _ls=$(rq_size "$1/log"); _ws=0; _sv=''; _ph=''
  _why=''
  while [ -z "$_why" ]; do
    sleep 5
    [ "$(cat "$1/state" 2>/dev/null)" = running ] && [ ! -f "$1/result" ] || return 0
    _aw=$((_aw + 5))
    _p=$(cat "$1/pass" 2>/dev/null || true); [ -n "$_p" ] || _p=$_p0
    _f=startup; [ -f "$1/tests-at.$_p" ] && _f=tests
    if [ "$_p" != "$_pa" ] || [ "$_f" != "$_ph" ]; then   # a new pass or phase: its own baselines, never output in itself
      [ "$_p" != "$_pa" ] && { _su=0; _ws=$(rq_size "$1/compose.$_p.err"); }
      _pa=$_p; _ph=$_f; _sv=$(if [ "$_f" = tests ]; then grep '^tests	' "$1/svcout.$_p"; else cat "$1/svcout.$_p"; fi 2>/dev/null || true)
    fi
    _o=no
    _n=$(rq_size "$1/log"); [ "$_n" -gt "$_ls" ] && _o=yes; _ls=$_n
    if [ "$_f" = startup ]; then _n=$(rq_size "$1/compose.$_p.err"); [ "$_n" -gt "$_ws" ] && _o=yes; _ws=$_n; fi
    _n=$(if [ "$_f" = tests ]; then grep '^tests	' "$1/svcout.$_p"; else cat "$1/svcout.$_p"; fi 2>/dev/null || true)
    [ "$_n" != "$_sv" ] && [ -n "$_n" ] && _o=yes; _sv=$_n
    if [ "$_o" = yes ]; then _si=0; _last=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); else _si=$((_si + 5)); fi
    [ "$_f" = startup ] && _su=$((_su + 5))
    rq_put "$1/watch" "awake=$_aw silent=$_si pass=$_p phase=$_f at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    if [ "$_si" -ge "${_sil:-1200}" ]; then _why=silent
    elif [ "$_f" = startup ] && [ -f "$1/svcout.$_p" ] && [ "$_su" -ge "${_sul:-3600}" ]; then _why=startup
    elif [ "$_aw" -ge "${_lim:-86400}" ]; then _why=limit; fi
  done
  [ "$(cat "$1/state" 2>/dev/null)" = running ] && [ ! -f "$1/result" ] || return 0
  printf 'reason=%s\npass=%s\nlast-output=%s\nat=%s\n' "$_why" "$_p" "$_last" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$1/cap-hit.tmp" && mv "$1/cap-hit.tmp" "$1/cap-hit"
  kill -TERM "$(cat "$1/pid" 2>/dev/null || echo 0)" 2>/dev/null || true
}
# rq_stopline <ticket dir>: the result's line saying why the watcher stopped the run (v0.26.10.4 R4)
rq_stopline() {
  _r=$(rq_kv reason "$1/cap-hit"); _lo=$(rq_kv last-output "$1/cap-hit" | sed 's/^[0-9-]*T\([0-9][0-9]:[0-9][0-9]\).*/\1/')
  case "$_r" in
    silent) echo "stopped: no new output for $(rq_dur "$(rq_kv silence "$1/request")") (last at $_lo UTC)" ;;
    startup) echo "stopped: the $(rq_kv pass "$1/cap-hit") pass's start-up passed $(rq_dur "$(rq_kv startup "$1/request")")" ;;
    limit) echo "stopped at the run limit ($(rq_dur "$(rq_kv limit "$1/request")") awake)" ;;
  esac
}
# rq_result <ticket dir> <exit status>: `result` — never the log (R2)
rq_result() {
  _rep=$(awk -F'\t' '$1 != "none" { printf "%s%s", (n++ ? "," : ""), $1 }' "$1/passes" 2>/dev/null || true)
  _rte=$(tail -n 1 "$1/passes" 2>/dev/null | cut -f4); _cp=no; [ -f "$1/cap-hit" ] && _cp=yes
  {
    [ -s "$1/build-failed" ] && cat "$1/build-failed"   # v0.9.7.3 (3.9, R9): a failed image build, named first
    [ -s "$1/stopped" ] && cat "$1/stopped"   # v0.9.7.0.11 (3.3, R3): a service's death, named first
    [ "$_cp" = yes ] && rq_stopline "$1"   # v0.26.10.4 (R4): why the watcher stopped it, in one line
    echo "status=$2 ran-to-end=${_rte:-no} capped=$_cp report=${_rep:-none}"
    # v0.26.10.3 (R9, F-43): the counts from the receipt kept for the ticket — its .cases, else the report itself read by
    # the results reader — so `cases none` means only that the receipt holds no case
    awk -F'\t' '$1 != "none" { print $5 "/" $1 }' "$1/passes" 2>/dev/null | while IFS= read -r _f; do
      if [ -f "$_f.cases" ]; then cat "$_f.cases"; elif [ -f "$_f" ] && [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh "$_f" 2>/dev/null | grep -E '^case ' || true; fi; done |
      awk '$1 == "case" { n[$3]++; t++ } END { if (!t) { print "cases none"; exit } o = "cases"; split("passed failed error skipped", k, " ")
        for (i = 1; i <= 4; i++) if (k[i] in n) { o = o " " k[i] "=" n[k[i]]; delete n[k[i]] } for (s in n) o = o " " s "=" n[s]; print o }'
    if [ -f checks/evidence.sh ]; then
      awk -F'\t' '$1 != "none" { print $5 "/" $1 }' "$1/passes" 2>/dev/null | while IFS= read -r _f; do
        [ -f "$_f.cases" ] && awk '$1 == "case" && $3 != "passed" && $3 != "skipped" { f = 1 } END { exit !f }' "$_f.cases" && sh checks/evidence.sh red "$_f" 2>/dev/null
      done | head -n 20
    fi
    [ -s "$1/outside" ] && echo "outside n=$(sort -u "$1/outside" | grep -c .) rows=$(sort -u "$1/outside" | head -n 10 | paste -sd ',' -) — not credited"
    # v0.9.8.1 (R41, F-29): an iterate whose inline pass published and whose deployed pass alone ended outside completed:
    # keeps the inline receipt (report= names it) and says so, never reading as a run with no receipt
    _dx=$(awk -F'\t' 'NR == 1 { i = ($1 != "none") } END { if (NR >= 2 && i && $1 == "none" && $4 == "no" && $3 != 130 && $3 != 143) print $3 }' "$1/passes" 2>/dev/null || true)
    if [ -n "$_dx" ]; then echo "deployed pass: ended outside completed (exit $_dx), no receipt — the inline pass's receipt is kept"
      grep -E '^V[Ii]D test: (refused|teardown FAILED|the inline pass did not)' "$1/log" 2>/dev/null | head -n 3 | sed 's/^V[Ii]D test: /why: /'
    else grep -E '^V[Ii]D test: (refused|no report|teardown FAILED|the inline pass did not)' "$1/log" 2>/dev/null | head -n 3 | sed 's/^V[Ii]D test: /why: /'; fi
  } > "$1/result.tmp"
  mv "$1/result.tmp" "$1/result"
}
# rq_final <ticket dir> <exit status>: `exit`, `result`, the analyst's triggers, then the final state — once
# (v0.9.7.0.10 3.1, R1: by the run when a gated request's last pass is published, else by `serve` after the run)
rq_final() {
  case "$(cat "$1/state" 2>/dev/null)" in done|capped|failed-to-start|stopped|cancelled) return 0 ;; esac
  # v0.9.7.1 (3.6, R6): a cancelled ticket ends cancelled, exit 77, after its teardown
  if [ -f "$1/cancel" ]; then
    rq_put "$1/exit" 77; rq_result "$1" 77
    { echo "cancelled by $(rq_kv by "$1/cancel")"; cat "$1/result"; } > "$1/result.tmp" && mv "$1/result.tmp" "$1/result"
    rq_put "$1/state" cancelled; kill "$(cat "$1/watcher" 2>/dev/null || echo 0)" 2>/dev/null || true; return 0
  fi
  rq_put "$1/exit" "$2"
  rq_result "$1" "$2"
  # v0.9.8 (R15): a proof's run triggers no analyst — its red is the fault's, by design
  [ "$(rq_kv purpose "$1/request")" = proof ] || rq_analyst "$1" || true   # v0.9.7.0.3 (3.1): before the final state, so a wait always sees it
  # only this completion writes a final state, after the result (3.1)
  if [ -f "$1/cap-hit" ]; then _fs=capped
  elif [ "$2" -eq 130 ] || [ "$2" -eq 143 ]; then _fs=stopped
  elif [ ! -s "$1/passes" ]; then _fs=failed-to-start
  else _fs=done; fi
  rq_put "$1/state" "$_fs"
  kill "$(cat "$1/watcher" 2>/dev/null || echo 0)" 2>/dev/null || true   # the run's watcher stops with the result
}
# rq_analyst <ticket dir>: the analyst's triggers (v0.9.7.0.3 3.1) — one event and one result line per trigger that fires
rq_analyst() {
  _h=${1%/.vid/requests/*}; _tk=${1#"$_h"/.vid/requests/}; _tk=$(printf '%s' "$_tk" | sed 's#/chunks/#/#'); _at=$(mktemp -d)
  # the run's reports: each kept pass, and a candidate kept in the ticket folder
  { awk -F'\t' '$1 != "none" { print $5 "/" $1 }' "$1/passes" 2>/dev/null; for _c in "$1"/*.xml; do [ -f "$_c" ] && printf '%s\n' "$_c"; done; } > "$_at/reports" || true
  : > "$_at/cases"; : > "$_at/lines"
  while IFS= read -r _f; do
    [ -f "$_f" ] || continue
    if [ -f "$_f.cases" ]; then cat "$_f.cases"; elif [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh "$_f" 2>/dev/null | grep -E '^case ' || true; fi >> "$_at/cases"
  done < "$_at/reports"
  # v0.26.10.5 (R8): a request carrying stage=N — only the cases of stages 1 to N count for the setup and slow triggers:
  # a case naming a scoped obligation is kept; one whose credited rows (checks/evidence.sh reach) are all outside the
  # scope, or that names only obligations outside it, is left out; a case naming nothing and reaching nothing is kept
  _stg=$(rq_kv stage "$1/request")
  if [ -n "$_stg" ] && [ -f "$_h/STAGES.md" ] && [ -f "$_h/checks/stages.sh" ] && ( cd "$_h" && sh checks/stages.sh scope --upto "$_stg" ) > "$_at/scope" 2>/dev/null; then
    : > "$_at/reachr"
    if [ -f checks/evidence.sh ]; then while IFS= read -r _f; do [ -f "$_f" ] && sh checks/evidence.sh reach "$_f" --raw 2>/dev/null; done < "$_at/reports" > "$_at/reachr" || true; fi
    awk -v sf="$_at/scope" -v rf="$_at/reachr" 'BEGIN { while ((getline l < sf) > 0) { S[++k] = l; a = l; gsub(/-/, "_", a); A[k] = a; IN[l] = 1 }
        while ((getline l < rf) > 0) { split(l, x, "\t"); R[x[1]] = R[x[1]] " " x[2] } }
      $1 != "case" { print; next }
      { for (i = 1; i <= k; i++) if (index($2, S[i]) || index($2, A[i])) { print; next }
        if ($2 in R) { n = split(R[$2], r, " "); for (i = 1; i <= n; i++) if (r[i] in IN) { print; next } next }
        if ($2 ~ /(ROW|HOS|RULE)[-_][0-9]+/) next
        print }' "$_at/cases" > "$_at/cases.s" && mv "$_at/cases.s" "$_at/cases"
  fi
  an_fire() { # <reason> <fields>
    printf 'analyst-due request=%s reason=%s%s at=%s\n' "$_tk" "$1" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$_h/.vid/metrics-events"
    printf 'analyst due: %s request=%s%s\n' "$1" "$_tk" "$2" >> "$_at/lines"
  }
  # v0.26.10.4 (R6): the cap trigger fires on all three reasons the watcher stops a run, with the reason and the last output time
  [ -f "$1/cap-hit" ] && an_fire cap " stop=$(rq_kv reason "$1/cap-hit") last-output=$(rq_kv last-output "$1/cap-hit")"
  _n=$(awk -v s="$AN_SETUP_SECONDS" '$1 == "case" && $3 != "passed" && $3 != "skipped" && $4 + 0 > s { n++ } END { print n + 0 }' "$_at/cases")
  if [ "$_n" -ge "$AN_SETUP_CASES" ]; then
    _g=''
    if [ -f checks/evidence.sh ]; then
      # v0.9.8.1 (R42, F-30): the groups of the red cases over the limit that tripped the trigger, each with its count
      awk -v s="$AN_SETUP_SECONDS" '$1 == "case" && $3 != "passed" && $3 != "skipped" && $4 + 0 > s { print $2 }' "$_at/cases" > "$_at/setup"
      _g=$(while IFS= read -r _f; do [ -f "$_f" ] && sh checks/evidence.sh red "$_f" 2>/dev/null; done < "$_at/reports" |
        awk -v sf="$_at/setup" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1 }
          /^group setup / { m = "(setup errors)"; next } /^group failed / { m = $0; sub(/^[^"]*"/, "", m); sub(/"$/, "", m); if (m == "") m = "(no message)"; next }
          /^    / { c = $0; sub(/^    /, "", c); sub(/ at [^ ]*( \(declaration\))?$/, "", c); if ((c in S) && !D[c]++) { if (!(m in N)) O[++k] = m; N[m]++ } }
          END { for (i = 1; i <= k; i++) printf "%s%s (%d case%s)", (i > 1 ? "; " : ""), O[i], N[O[i]], (N[O[i]] == 1 ? "" : "s") }' | tr '"' "'")
    fi
    an_fire setup "${_g:+ group=\"$_g\"}"
  fi
  awk -v s="$AN_SLOW_SECONDS" '$1 == "case" && $4 + 0 > s { print $2 }' "$_at/cases" | sort -u > "$_at/slow"
  if [ -s "$_at/slow" ]; then
    : > "$_at/reach"
    if [ -f checks/evidence.sh ]; then while IFS= read -r _f; do [ -f "$_f" ] && sh checks/evidence.sh reach "$_f" 2>/dev/null; done < "$_at/reports" > "$_at/reach" || true; fi
    # each slow case: its credited rows, else its case id — unless a limit proposal already names it
    [ -f "$_h/.vid/metrics-events" ] && awk '$1 == "analyst-done" { o = ""; r = ""; c = ""; for (i = 2; i <= NF; i++) { if (index($i, "outcome=") == 1) o = substr($i, 9); else if (index($i, "rows=") == 1) r = substr($i, 6); else if (index($i, "cases=") == 1) c = substr($i, 7) }
        if (o == "limit") print r "\t" c }' "$_h/.vid/metrics-events" > "$_at/limits" || : > "$_at/limits"
    awk -F'\t' -v rf="$_at/reach" -v lf="$_at/limits" 'BEGIN { while ((getline l < rf) > 0) { split(l, a, "\t"); CR[a[1]] = CR[a[1]] a[2] "," }
        while ((getline l < lf) > 0) { split(l, a, "\t"); LR = LR "," a[1] ","; LC = LC "," a[2] "," } }
      { c = $0; if (index(LC, "," c ",")) next
        if (c in CR) { n = split(CR[c], rr, ","); out = ""; for (i = 1; i <= n; i++) if (rr[i] != "" && !index(LR, "," rr[i] ",")) out = out rr[i] ","; if (out != "") print "R\t" out; next }
        print "C\t" c }' "$_at/slow" > "$_at/named"
    _r=$(awk -F'\t' '$1 == "R" { n = split($2, a, ","); for (i = 1; i <= n; i++) if (a[i] != "" && !s[a[i]]++) printf "%s%s", (k++ ? "," : ""), a[i] }' "$_at/named")
    _c=$(awk -F'\t' '$1 == "C" { printf "%s%s", (k++ ? "," : ""), $2 }' "$_at/named")
    [ -n "$_r$_c" ] && an_fire slow "${_r:+ rows=$_r}${_c:+ cases=$_c}"
  fi
  if [ -s "$_at/lines" ]; then cat "$1/result" "$_at/lines" > "$1/result.tmp" && mv "$1/result.tmp" "$1/result"; fi
  rm -rf "$_at"
}

# --- v0.9.7.0.12 (3.2–3.4, 3.10; R2–R4, R10): the close batch ------------------------------------------------
# bt_parse <file> <phase>: a phase file's groups, one per line `<rows> | <inline words> | <deployed words>` (blank and #
# lines skipped) → `G <phase> <group: phase.line> <rows,…> <inline> <deployed> <the line as given>` (tab-separated), or
# `BAD <why>`.
# ViD never splits a line and never reads its words' syntax.
bt_parse() {
  awk -v ph="$2" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/[ \t]+/, " ", s); return s }
    /^[ \t]*$/ || /^[ \t]*#/ { next }
    { raw = $0; n = split($0, f, "|"); at = "phase " ph " line " NR ": "
      if (n != 3) { print "BAD\t" at "a group is <rows> | <inline words> | <deployed words>"; next }
      r = f[1]; gsub(/,/, " ", r); r = tr(r); k = split(r, rr, " "); out = ""; bad = 0
      for (i = 1; i <= k; i++) { if (rr[i] !~ /^(ROW|HOS)-[0-9A-Za-z-]*[0-9A-Za-z]$/) { print "BAD\t" at rr[i] " is not a row id"; bad = 1; break } out = out (out == "" ? "" : ",") rr[i] }
      if (bad) next
      if (out == "") { print "BAD\t" at "a group names its rows"; next }
      w = tr(f[2]); d = tr(f[3])
      if (w d == "") { print "BAD\t" at "a group names its inline or its deployed selection words"; next }
      if ((w d) ~ /["\047]/) { print "BAD\t" at "a selection word holds a quote, which the harness command cannot carry"; next }
      print "G\t" ph "\t" ph "." NR "\t" out "\t" w "\t" d "\t" raw }' "$1"
}
bt_load() { uptime 2>/dev/null | sed 's/.*load average[s]*: *//' | awk '{ gsub(/,/, "", $1); print $1 }'; }
bt_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
bt_final() { case "$(cat "$1/state" 2>/dev/null)" in done|capped|failed-to-start|stopped|cancelled) return 0 ;; *) return 1 ;; esac; }
# bt_refuse <why>: the batch ends before any chunk ran — the result, exit 2, failed-to-start
bt_refuse() {
  { echo "refused: $1"; [ -s "$RQT/why" ] && head -n 20 "$RQT/why"; } > "$TD/result.tmp" && mv "$TD/result.tmp" "$TD/result"
  rq_put "$TD/exit" 2; rq_put "$TD/state" failed-to-start; rm -rf "$RQT"; exit 0
}
# bt_mkchunk <id> <phase> <group line numbers, comma-separated> <case seconds>: a sub-ticket — its own request, rows and groups
bt_mkchunk() {
  _cd="$TD/chunks/$1"; mkdir -p "$_cd"
  awk -F'\t' -v ix=",$3," 'index(ix, "," $3 ",") { print }' "$TD/groups" > "$_cd/groups.t"
  cut -f7- "$_cd/groups.t" > "$_cd/groups"
  cut -f4 "$_cd/groups.t" | tr ',' '\n' | grep -v '^$' | sort -u > "$_cd/rows"
  _sl=$(awk -F'\t' '$5 != "" { printf "%s%s", (n++ ? " " : ""), $5 }' "$_cd/groups.t"); _dl=$(awk -F'\t' '$6 != "" { printf "%s%s", (n++ ? " " : ""), $6 }' "$_cd/groups.t")
  _sp=1; _td=0; _hd=no; [ -n "$_dl" ] && _hd=yes
  if [ -n "$_sl" ] && [ -n "$_dl" ]; then _sp=2; _td=$TDN; fi
  _e=$(( _sp * STARTUP + $4 + _td ))   # v0.26.10.4 (R2): each chunk its own limits, the batch's (SIL SUL LIM)
  printf 'id=%s/%s\nbatch=%s\nchunk=%s\nphase=%s\ntype=close\nrole=orchestrator\nrunrole=close\nwhy=%s — chunk %s, phase %s\nrows=%s\nestimate=%s\nsilence=%s\nstartup=%s\nlimit=%s\nestimate-startup=%s\nteardown=%s\ncases=%s\nexpect=\nno-history=0\ncwd=%s\nsel=%s\ndsel=%s\nhasdsel=%s\nsteps=%s\ngated=yes\nprove=\nexport=%s\ntree=%s\nbase=%s\ncreated=%s\n' \
    "$BID" "$1" "$BID" "$1" "$2" "$(rq_kv why "$TD/request")" "$1" "$2" "$(grep -c . "$_cd/rows" || true)" "$_e" "$SIL" "$SUL" "$LIM" "$STARTUP" "$_td" "$4" "$PWD" "$_sl" "$_dl" "$_hd" "$(rq_kv steps "$TD/request")" "$BEXP" "$BTREE" "$BBASE" "$(date +%s)" > "$_cd/request"
  echo "$2" > "$_cd/phase"; rm -f "$_cd/groups.t"
  rq_put "$_cd/state" queued; : > "$_cd/log"
}
# bt_judge <rows file> <receipts file> <out>: the chunk against the frozen expected cases (checks/metrics.sh batch-judge)
bt_judge() { sh checks/metrics.sh batch-judge "$TD/frozen" "$1" "$2" > "$3" 2>/dev/null; }
# bt_classify <chunk id> → BTO green|red|incomplete|retry and BTW (why), from its sub-ticket once its run has ended
bt_classify() {
  _cd="$TD/chunks/$1"; BTO=incomplete; BTW=''
  case "$(cat "$_cd/state" 2>/dev/null)" in
    capped) BTO=retry; BTW=cap ;;
    stopped)
      if [ -s "$_cd/stopped" ]; then
        _sv=$(sed -n 's/^stopped: service \([^ ]*\) .*/\1/p' "$_cd/stopped" | head -n 1)
        case " $BPROCS " in *" $_sv "*) BTO=red; BTW="the product's process $_sv died" ;; *) BTO=retry; BTW="service $_sv died" ;; esac
      else BTO=retry; BTW=signal; fi ;;
    done)
      _np=1; [ -n "$(rq_kv sel "$_cd/request")" ] && [ "$(rq_kv hasdsel "$_cd/request")" = yes ] && _np=2
      awk -F'\t' '$1 != "none" { print $5 "/" $1 "\t" ($2 == "deployed" ? "deployed" : "inline") }' "$_cd/passes" 2>/dev/null > "$_cd/receipts" || : > "$_cd/receipts"
      if [ "$(grep -c . "$_cd/receipts" || true)" -lt "$_np" ]; then
        BTW=$(grep -E '^why: ' "$_cd/result" 2>/dev/null | head -n 1 | sed 's/^why: //'); BTW=${BTW:-no complete report}
      else
        bt_judge "$_cd/rows" "$_cd/receipts" "$_cd/judged"
        if grep -q '^FAILED' "$_cd/judged"; then BTO=red; BTW="rows $(awk -F'\t' '$1 == "FAILED" && !s[$2]++ { printf "%s%s", (n++ ? "," : ""), $2 }' "$_cd/judged")"
        elif grep -q '^NOTRUN' "$_cd/judged"; then BTW="not covered: $(awk -F'\t' '$1 == "NOTRUN" { printf "%s%s", (n++ ? "," : ""), $2 ($3 == "-" ? "" : " " $3) }' "$_cd/judged" | cut -c1-300)"
        else BTO=green; fi
      fi ;;
    *) BTW=$(grep -E '^why: ' "$_cd/result" 2>/dev/null | head -n 1 | sed 's/^why: //'); BTW=${BTW:-it did not start} ;;
  esac
  printf '%s\n' "$BTO" > "$_cd/outcome"; [ -z "$BTW" ] || printf '%s\n' "$BTW" > "$_cd/why"
}
# bt_others_queued: yes when a request other than this batch's waits — its own parent and chunks aside, and a batch's parent, which holds no slot
bt_others_queued() {
  for _s in "$RQH"/.vid/requests/*/state "$RQH"/.vid/requests/*/chunks/*/state; do
    [ -f "$_s" ] && [ "$(cat "$_s" 2>/dev/null)" = queued ] || continue
    _d=${_s%/state}; case "$_d" in "$TD"|"$TD"/*) continue ;; esac
    grep -q '^batch=yes$' "$_d/request" 2>/dev/null && continue
    echo yes; return 0
  done
}
# bt_stop_queued: a chunk still waiting for a test environment is stopped (TERM to its run); one running goes on to its end
bt_stop_queued() {
  for _n in $BACT; do _cd="$TD/chunks/${_n%%:*}"
    [ "$(cat "$_cd/state" 2>/dev/null)" = queued ] && kill -TERM "$(cat "$_cd/pid" 2>/dev/null || echo 0)" 2>/dev/null || true
  done
}
# bt_phase <p>: the phase's chunks, at most the slots allowed at once; 0 when every chunk ends green, else 1 (BEND says why)
bt_phase() {
  BPEND=$(awk -F'\t' -v p="$1" '$2 == p && $3 == "run" { printf "%s ", $1 }' "$TD/layout"); BACT=''; _stopping=no
  while [ -n "$BPEND$BACT" ]; do
    _left=''
    for _a in $BACT; do
      _n=${_a%%:*}; _p=${_a#*:}
      if pid_alive "$_p"; then _left="$_left $_a"; continue; fi
      wait "$_p" 2>/dev/null || true
      bt_classify "$_n"
      [ "$BTO" = retry ] && [ "$_stopping" = yes ] && { BTO=stopped; echo stopped > "$TD/chunks/$_n/outcome"; }
      case "$BTO" in
        retry)
          case "$_n" in
            *-retry) echo incomplete > "$TD/chunks/$_n/outcome"; BINC="$BINC ${_n%-retry}"; printf 'incomplete chunk=%s why=its retry was lost too (%s)\n' "${_n%-retry}" "$BTW" >> "$RQT/ends"; _stopping=yes ;;
            *) BRET=$((BRET + 1)); mkdir -p "$TD/chunks/$_n-retry"; sed "s#^id=.*#id=$BID/$_n-retry#; s#^created=.*#created=$(date +%s)#; s#^chunk=.*#chunk=$_n-retry#" "$TD/chunks/$_n/request" > "$TD/chunks/$_n-retry/request"
               cp "$TD/chunks/$_n/rows" "$TD/chunks/$_n/groups" "$TD/chunks/$_n/phase" "$TD/chunks/$_n-retry/"; rq_put "$TD/chunks/$_n-retry/state" queued; : > "$TD/chunks/$_n-retry/log"
               [ "$_stopping" = yes ] || BPEND="$_n-retry $BPEND" ;;
          esac ;;
        red) BRED="$BRED ${_n%-retry}"; awk -F'\t' '$1 == "FAILED" { print "red row=" $2 " case=" $3 }' "$TD/chunks/$_n/judged" 2>/dev/null >> "$RQT/reds"; [ -f "$TD/chunks/$_n/judged" ] || printf 'red chunk=%s why=%s\n' "${_n%-retry}" "$BTW" >> "$RQT/reds"; _stopping=yes ;;
        incomplete) BINC="$BINC ${_n%-retry}"; printf 'incomplete chunk=%s why=%s\n' "${_n%-retry}" "$BTW" >> "$RQT/ends"; _stopping=yes ;;
      esac
    done
    BACT=$_left
    if [ -n "$BSIG" ] && [ "$_stopping" = no ]; then   # the batch itself was signalled: every chunk stops
      _stopping=yes; for _a in $BACT; do kill -TERM "$(cat "$TD/chunks/${_a%%:*}/pid" 2>/dev/null || echo 0)" 2>/dev/null || true; done
    fi
    if [ "$_stopping" = yes ]; then BPEND=''; bt_stop_queued; fi
    # builders keep a slot: while another request waits, at most stacks − 1 chunks at once
    _allow=$BLIM; [ -n "$(bt_others_queued)" ] && _allow=$((BLIM - 1))
    while [ -n "$BPEND" ] && [ "$(echo $BACT | wc -w | tr -d ' ')" -lt "$_allow" ]; do
      set -- $BPEND; _n=$1; shift; BPEND="$*"
      sh "$SELFP" serve "$TD/chunks/$_n" < /dev/null >> "$TD/chunks/$_n/log" 2>&1 & BACT="$BACT $_n:$!"
    done
    [ -n "$BPEND$BACT" ] && { sleep 2 & wait $! || true; }
  done
  [ -z "$BRED$BINC$BSIG" ] && return 0
  return 1
}
# bt_progress: `<done>/<total>` — a chunk is done once its newest sub-ticket has an outcome other than a retry
bt_progress() {
  awk -F'\t' -v td="$TD" '{ n++; f = td "/chunks/" $1 "-retry/outcome"; if ((getline o < f) <= 0) { f = td "/chunks/" $1 "/outcome"; o = ""; if ((getline o < f) <= 0) o = "" } close(f); if (o != "" && o != "retry") d++ }
    END { printf "%d/%d\n", d + 0, n + 0 }' "$TD/layout" 2>/dev/null
}
# bt_key: what close-rows reads besides the evidence — the tree, the steps, the slice's rows file and the plan
bt_key() {
  _sl=$(sed -n 's/^slice:[[:space:]]*\([0-9][0-9]*\).*/\1/p' .vid/RUN-STATE.md 2>/dev/null | head -n 1)
  printf 'tree=%s\nsteps=%s\nslice=%s\nrows-file=%s\nplan=%s\n' "$BTREE" "$STEPS" "${_sl:--}" \
    "$(cksum < ".vid/close/${_sl:-x}.rows" 2>/dev/null | cut -d' ' -f1 || echo -)" "$(sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md 2>/dev/null | cksum | cut -d' ' -f1)"
}
# bt_reuse <key>: the newest earlier batch whose frozen key matches, when every event since its freeze is its own (names
# it), one of its chunks', a run that kept no report, or of a type close-rows never reads; else nothing
bt_reuse() {
  ls -r "$RQH"/.vid/requests/*/frozen/key 2>/dev/null | while IFS= read -r _ob; do
    _od=${_ob%/frozen/key}; _oid=${_od##*/}
    [ "$_od" != "$TD" ] && [ -s "$_od/frozen/required" ] || continue
    [ "$(grep -v '^events=' "$_ob")" = "$1" ] || continue
    _n=$(sed -n 's/^events=//p' "$_ob"); [ -n "$_n" ] || continue
    tail -n +"$((_n + 1))" "$RQH/.vid/metrics-events" 2>/dev/null | awk -v b="$_oid" '
      index($0, "request=" b "/") || index($0, "batch=" b) || index($0, "id=" b " ") { next }
      $1 == "ledger-run" && / report=none / { next }
      $1 ~ /^(teardown|teardown-failed|analyst-due|analyst-done|slot-reclaimed|progress|agent-start|agent-stop|session|stall|tokens|court|close-batch)$/ { next }
      { bad = 1; exit } END { exit bad }' || continue
    printf '%s\n' "$_oid"; break
  done
}
# batch_serve: the batch supervisor — the parent ticket's serve; it alone writes the parent's state, result and exit
batch_serve() {
  RQT=$(mktemp -d); BID=${TD##*/}; RQH=${TD%/.vid/requests/*}; STEPS=$(rq_kv steps "$TD/request")
  SELFP="$(cd "$(dirname "$0")" && pwd)/${0##*/}"
  BSIG=''; trap 'BSIG=yes' TERM INT HUP
  # 0.9.7.0.11's dirty wait, then HEAD's tree once
  DW0=$(date +%s)
  while :; do
    _dy=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null || true)
    [ -n "$_dy" ] || break
    if [ $(( $(date +%s) - DW0 )) -ge "${VID_DIRTY_WAIT:-600}" ]; then printf '%s\n' "$_dy" | head -n 5 | sed 's/^/    /' > "$RQT/why"; bt_refuse 'the worktree carries uncommitted changes; commit first: a receipt names a tree'; fi
    echo "    waiting for a clean worktree: $(printf '%s\n' "$_dy" | head -n 5 | cut -c4- | paste -sd ',' - | sed 's/,/, /g') — $(( $(date +%s) - DW0 )) s of ${VID_DIRTY_WAIT:-600} s" > "$TD/holders"
    sleep 2
  done
  BTREE=$(git rev-parse 'HEAD^{tree}'); BBASE=$(git rev-parse --short=12 HEAD)
  # the frozen rows, phases, shapes, expected cases' inputs and population reference
  # an earlier batch's freeze is reused when nothing close-rows reads has changed since (bt_reuse); else computed
  BKEY=$(bt_key); BREUSE=$(bt_reuse "$BKEY"); _evn=$(grep -c . "$RQH/.vid/metrics-events" 2>/dev/null || true)
  if [ -n "$BREUSE" ]; then cp -R "$RQH/.vid/requests/$BREUSE/frozen" "$TD/frozen"
  else
    sh checks/metrics.sh close-freeze --steps "$STEPS" --out "$TD/frozen" --tree "$BTREE" > "$RQT/fz" 2>&1 || { sed 's/^/    /' "$RQT/fz" > "$RQT/why"; bt_refuse "the close's rows could not be frozen (sh checks/metrics.sh close-freeze --steps $STEPS)"; }
  fi
  { printf '%s\n' "$BKEY"; printf 'events=%s\n' "${_evn:-0}"; } > "$TD/frozen/key.tmp" && mv "$TD/frozen/key.tmp" "$TD/frozen/key"
  awk -F'\t' -v rf="$TD/frozen/required" 'BEGIN { while ((getline l < rf) > 0) { split(l, a, "\t"); P[a[1]] = a[4]; S[a[1]] = a[2] } }
    { n = split($4, r, ","); for (i = 1; i <= n; i++) { G[r[i]] = 1
        if (!(r[i] in P)) print "    " r[i] " (group " $3 ") is not a required row of close-rows --steps"
        else if (P[r[i]] != $2) print "    " r[i] " is phase " P[r[i]] " (sets " S[r[i]] ") but its group " $3 " is in phase " $2 } }
    END { for (x in P) if (!(x in G)) m = m (m == "" ? "" : ",") x; if (m != "") print "    required rows in no group: " m }' "$TD/groups" > "$RQT/why"
  [ -s "$RQT/why" ] && bt_refuse "the groups do not hold close-rows' required rows, each in its phase"
  # one export of the tree, made once; every chunk and retry runs from it and reads its harness from it
  BEXP="$TD/export"; mkdir -p "$BEXP"; git archive --format=tar "$BTREE" | tar -xf - -C "$BEXP" || bt_refuse 'the tree could not be exported'
  BPROCS=" $(awk -v k=product: '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1==k { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' "$BEXP/docker-compose.test.yml" 2>/dev/null) $(awk -v k=processes: '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1==k { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' "$BEXP/docker-compose.test.yml" 2>/dev/null | tr '[],' '   ') "
  case "$BPROCS" in '  '*' ') BPROCS=" product $BPROCS" ;; esac
  # the slots it may use: the proved environments, as the run admits them
  BLIM=1; _bs=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' "$RQH/.vid/budget" 2>/dev/null | head -n 1)
  if [ -n "$_bs" ] && [ "$_bs" -ge 2 ] && [ -f docker-compose.test.yml ] && grep -qxF "testenv=proved harness=$(cksum < docker-compose.test.yml | cut -d' ' -f1)" "$RQH/.vid/budget" 2>/dev/null; then BLIM=$_bs; fi
  # packing: each phase's groups in order into chunks of about chunk-seconds of recorded case seconds; a group with no
  # history counts as the median per word (10 s a row when no group has any)
  CS=$(sed -n 's/^chunk-seconds=\([0-9][0-9]*\).*/\1/p' "$RQH/.vid/budget" 2>/dev/null | head -n 1); CS=${CS:-1200}
  EXPECT=''; SUPN=1; TWOP=yes; rq_estimate "$RQH" "$TD/rows"; rq_limits "$RQH"
  awk -F'\t' -v hf="$RQT/hist" 'BEGIN { while ((getline l < hf) > 0) { split(l, a, "\t"); if (a[1] == "H") H[a[2]] = a[3] } }
    { n = split($4, r, ","); s = 0; h = 0; for (i = 1; i <= n; i++) if (r[i] in H) { s += H[r[i]]; h = 1 }
      w = split($5 " " $6, ww, " "); print $2 "\t" $3 "\t" (h ? s : -1) "\t" w "\t" n }' "$TD/groups" > "$RQT/gsec"
  _med=$(awk -F'\t' '$3 >= 0 && $4 > 0 { print $3 / $4 }' "$RQT/gsec" | sort -n | awk '{ v[NR] = $1 } END { if (NR == 0) print -1; else if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }')
  awk -F'\t' -v m="$_med" '{ s = $3; if (s < 0) s = (m >= 0) ? m * $4 : 10 * $5; printf "%s\t%s\t%d\n", $1, $2, s + 0.999 }' "$RQT/gsec" > "$RQT/gs"
  # adoption: an earlier batch's green chunk at this tree whose groups are byte-identical, judged green on this batch's frozen cases
  : > "$RQT/used"; : > "$TD/layout"; _k=0; BADO=0
  ls -r "$RQH"/.vid/requests/*/batch 2>/dev/null > "$RQT/obs" || true
  while IFS= read -r _ob; do
    _od=${_ob%/batch}; [ "$_od" != "$TD" ] && [ "$(rq_kv tree "$_ob")" = "$BTREE" ] || continue
    for _oc in "$_od"/chunks/*; do
      [ "$(cat "$_oc/outcome" 2>/dev/null)" = green ] && [ -s "$_oc/receipts" ] && [ -f "$_oc/phase" ] || continue
      _ph=$(cat "$_oc/phase")
      awk -F'\t' -v ph="$_ph" -v uf="$RQT/used" -v gf="$_oc/groups" 'BEGIN { while ((getline l < uf) > 0) U[l] = 1; while ((getline l < gf) > 0) W[l] = 1 }
        { raw = $0; for (i = 1; i <= 6; i++) sub(/^[^\t]*\t/, "", raw) } $2 == ph && (raw in W) && !($3 in U) { print $3; F[raw] = 1 }
        END { for (w in W) if (!(w in F)) exit 1 }' "$TD/groups" > "$RQT/hit" || continue
      [ "$(grep -c . "$RQT/hit" || true)" -eq "$(grep -c . "$_oc/groups" || true)" ] || continue
      bt_judge "$_oc/rows" "$_oc/receipts" "$RQT/aj"; grep -qE '^(NOTRUN|FAILED)' "$RQT/aj" && continue
      _k=$((_k + 1)); _cd="$TD/chunks/$_k"; mkdir -p "$_cd"
      cp "$_oc/groups" "$_oc/rows" "$_oc/receipts" "$_oc/phase" "$_cd/"; cp "$RQT/aj" "$_cd/judged"
      _src=$(cat "$_oc/adopted" 2>/dev/null || printf '%s/%s' "${_od##*/}" "${_oc##*/}"); echo "$_src" > "$_cd/adopted"; echo green > "$_cd/outcome"
      cat "$RQT/hit" >> "$RQT/used"
      printf '%s\t%s\tadopted\t%s\n' "$_k" "$_ph" "$_src" >> "$TD/layout"
    done
  done < "$RQT/obs"
  BADO=$(awk -F'\t' '$3 == "adopted"' "$TD/layout" | grep -c . || true)
  for _ph in 1 2; do
    awk -F'\t' -v ph="$_ph" -v uf="$RQT/used" -v cs="$CS" 'BEGIN { while ((getline l < uf) > 0) U[l] = 1 }
      $1 == ph && !($2 in U) { if (c > 0 && c + $3 > cs) { print ix "\t" c; ix = ""; c = 0 } ix = ix (ix == "" ? "" : ",") $2; c += $3 }
      END { if (ix != "") print ix "\t" c }' "$RQT/gs" | while IFS="$TX" read -r _ix _sec; do
      _k=$(( $(grep -c . "$TD/layout" || true) + 1 )); bt_mkchunk "$_k" "$_ph" "$_ix" "$_sec"
      printf '%s\t%s\trun\t%s\n' "$_k" "$_ph" "$_sec" >> "$TD/layout"
    done
  done
  printf 'id=%s\ntree=%s\nbase=%s\nsteps=%s\nchunk-seconds=%s\nstacks=%s\nexport=%s\nfrozen-at=%s\nfrozen=%s\n' "$BID" "$BTREE" "$BBASE" "$STEPS" "$CS" "$BLIM" "$BEXP" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$([ -n "$BREUSE" ] && echo "reused from $BREUSE" || echo computed)" > "$TD/batch"
  BRUN0=$(date +%s); echo "$BRUN0" > "$TD/running-at"; rq_put "$TD/state" running; LS=$(bt_load)
  BRET=0; BRED=''; BINC=''; : > "$RQT/reds"; : > "$RQT/ends"; _ph=''
  # the phase gate: phase 2 starts only when every phase-1 chunk is published, covers its rows' expected cases, and has no red case
  for _ph in 1 2; do bt_phase "$_ph" || break; done
  # a chunk the batch never launched ends stopped — never left queued, where it would hold a later batch to stacks − 1
  for _s in "$TD"/chunks/*/state; do
    [ "$(cat "$_s" 2>/dev/null)" = queued ] || continue
    echo "stopped: not run — the batch ended at phase $_ph" > "${_s%/state}/result"; rq_put "${_s%/state}/state" stopped
  done
  # the end: the result, the record, the close-batch event, then the exit and the final state
  # each chunk run's seconds from its slot to its result; stacks-max, the most of them at once
  _w=$(( $(date +%s) - BRUN0 ))
  for _cd in "$TD"/chunks/*; do [ -f "$_cd/running-at" ] && [ -f "$_cd/exit" ] && printf '%s\t%s\n' "$(cat "$_cd/running-at")" "$(bt_mtime "$_cd/exit")"; done > "$RQT/spans" || true
  _sum=$(awk -F'\t' '{ s += $2 - $1 } END { print s + 0 }' "$RQT/spans")
  BSMAX=$(awk -F'\t' '{ print $1 "\t0"; print $2 "\t1" }' "$RQT/spans" | sort -n -k1,1 -k2,2 | awk -F'\t' '{ if ($2 == 0) { c++; if (c > m) m = c } else c-- } END { print m + 0 }')
  : > "$TD/receipts"
  awk -F'\t' '{ print $1 }' "$TD/layout" | while IFS= read -r _n; do _f="$TD/chunks/$_n"; [ -d "$_f-retry" ] && _f="$_f-retry"
    [ -s "$_f/receipts" ] && awk -F'\t' -v c="${_f##*/}" '{ print c "\t" $1 "\t" $2 }' "$_f/receipts"; done >> "$TD/receipts" || true
  _nc=$(grep -c . "$TD/layout" || true)
  {
    if [ -n "$BSIG" ]; then echo 'stopped: the batch was signalled — chunks still waiting were stopped'
    elif [ -n "$BRED" ]; then _rr=$(sed -n 's/^red row=\([^ ]*\) .*/\1/p' "$RQT/reds" | sort -u | head -n 20 | paste -sd ',' -)
      _rc=$(sed -n 's/^red chunk=\([^ ]*\) .*/\1/p' "$RQT/reds" | sort -un | paste -sd ',' -)
      echo "red phase $_ph${_rr:+, rows $_rr}${_rc:+, chunks $_rc}"
    elif [ -n "$BINC" ]; then echo "incomplete phase $_ph, chunks $(echo $BINC | tr ' ' '\n' | sort -un | paste -sd ',' -)"
    else echo green; fi
    echo "chunks $_nc retried=$BRET adopted=$BADO stacks-max=$BSMAX wall=$_w chunk-seconds-sum=$_sum"
    head -n 20 "$RQT/ends"; head -n 20 "$RQT/reds"
    awk -F'\t' '{ print $1 }' "$TD/layout" | while IFS= read -r _n; do _f="$TD/chunks/$_n"; [ -d "$_f-retry" ] && _f="$_f-retry"
      printf 'chunk %s phase=%s %s%s%s\n' "${_f##*/}" "$(cat "$_f/phase")" "$(cat "$_f/outcome" 2>/dev/null || echo not-run)" "$([ -f "$_f/adopted" ] && echo " adopted=$(cat "$_f/adopted")")" "$([ -s "$_f/receipts" ] && echo " report=$(cut -f1 "$_f/receipts" | sed 's#.*/##' | paste -sd ',' -)")"
    done | head -n 30
    cat "$TD"/chunks/*/result 2>/dev/null | grep '^analyst due: ' || true
  } > "$TD/result.tmp" && mv "$TD/result.tmp" "$TD/result"
  printf 'close-batch id=%s chunks=%s retried=%s adopted=%s stacks-max=%s wall=%s chunk-seconds-sum=%s load-start=%s load-end=%s at=%s\n' "$BID" "$_nc" "$BRET" "$BADO" "$BSMAX" "$_w" "$_sum" "${LS:--}" "$(bt_load || echo -)" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$RQH/.vid/metrics-events"
  rm -rf "$BEXP"
  if [ -n "$BSIG" ]; then rq_put "$TD/exit" 130; rq_put "$TD/state" stopped
  elif [ -n "$BRED$BINC" ]; then rq_put "$TD/exit" 1; rq_put "$TD/state" done
  else rq_put "$TD/exit" 0; rq_put "$TD/state" done; fi
  rm -rf "$RQT"
}

case "${1:-}" in
  request)
    shift; TYPE=''; RROLE=''; WHY=''; ROWS=''; ROWSF=''; STEPS=''; EXPECT=''; RSEL=''; RDSEL=''; RHASD=no; HASSEL=no; BATCH=no; PH1=''; PH2=''; RTRY=''; RPURP=''; RSTAGE=''
    while [ $# -gt 0 ]; do
      case "$1" in
        --batch) BATCH=yes; shift ;;
        --type|--role|--why|--rows|--rows-file|--steps|--expect|--phase1|--phase2|--try|--purpose|--stage)
          [ $# -ge 2 ] || rq_usage
          case "$1" in --type) TYPE=$2 ;; --role) RROLE=$2 ;; --why) WHY=$2 ;; --rows) ROWS=$2 ;; --rows-file) ROWSF=$2 ;; --steps) STEPS=$2 ;; --expect) EXPECT=$2 ;; --phase1) PH1=$2 ;; --phase2) PH2=$2 ;; --try) RTRY=$2 ;; --purpose) RPURP=$2 ;; --stage) RSTAGE=$2 ;; esac
          shift 2 ;;
        --) shift; HASSEL=yes
            while [ $# -gt 0 ] && [ "$1" != --deployed-selection ]; do selword "$1"; RSEL="${RSEL:+$RSEL }$1"; shift; done
            if [ $# -gt 0 ]; then shift; for _w in "$@"; do selword "$_w"; done; RDSEL="$*"; RHASD=yes; fi
            break ;;
        *) rq_usage ;;
      esac
    done
    [ -n "$WHY" ] || rq_die 'a request says why, in one line: --why "<one line>".'
    case "$WHY" in *'
'*) rq_die 'the reason is one line.' ;; esac
    case "$EXPECT" in *[!0-9]*) rq_die '--expect takes whole seconds.' ;; esac
    # v0.26.10.5 (R8): a full run for a stage close carries --stage N: the analyst's setup and slow triggers count only
    # the cases of stages 1 to N (checks/stages.sh scope at the home); later stages' red cases are not read
    case "$RSTAGE" in '') ;; *[!0-9]*|0) rq_die "--stage takes a stage number (1 or more), not '$RSTAGE'." ;; *) [ "$TYPE" = full ] || rq_die '--stage belongs to a full run, the whole suite for a stage close.' ;; esac
    # R3: the types and who may ask
    case "$TYPE" in
      prove-red) _who='test-author orchestrator fixer' ;;
      iterate) _who='builder fixer test-author testenv' ;;
      close|checkpoint|full) _who='orchestrator' ;;
      deployed) _who='builder fixer' ;;
      *) rq_usage ;;
    esac
    # v0.9.8 (3.4, R4, R15): a fault proof's run — a prove-red, or a deployed pass for a deployed-shape row, asked by the
    # orchestrator with --purpose proof; its receipts are no ordinary receipts (named .proof., never credited)
    case "$RPURP" in
      '') ;;
      proof) case "$TYPE" in prove-red|deployed) ;; *) rq_die "--purpose proof belongs to a prove-red or a deployed request — not a $TYPE." ;; esac
        [ "$RROLE" = orchestrator ] || rq_die "a proof's runs are the run manager's: --purpose proof is asked by orchestrator — not by '${RROLE:-no role}'."
        [ "$TYPE" = deployed ] && _who="$_who orchestrator" ;;
      *) rq_die "--purpose takes proof, the one purpose — not '$RPURP'." ;;
    esac
    case " $_who " in *" $RROLE "*) ;; *) rq_die "a $TYPE request is asked by: $_who — not by '${RROLE:-no role}'." ;; esac
    # v0.9.7.1 (3.6, R6): a builder's and a fixer's request carries its brief's attempt id
    case "$RROLE" in builder|fixer) [ -n "$RTRY" ] || rq_die "a $RROLE's request carries its brief's attempt id: --try <id> (the brief's header, try:)." ;; esac
    case "$RTRY" in *[!A-Za-z0-9._-]*) rq_die "--try takes the brief's attempt id, letters, digits, '.', '_' and '-': not '$RTRY'." ;; esac
    case "$TYPE" in
      close|full) RUNROLE=close ;; checkpoint) RUNROLE=checkpoint ;; *) RUNROLE=$RROLE ;;
    esac
    case "$TYPE" in
      prove-red|iterate|deployed)
        # v0.9.7.0.9 (3.5, R6): an iterate request asked by a builder, fixer or test-author may carry the deployed pass too
        [ -n "$STEPS" ] && rq_usage
        if [ "$RHASD" = yes ]; then
          [ "$TYPE" = iterate ] || rq_usage
          case "$RROLE" in builder|fixer|test-author) ;; *) rq_die "--deployed-selection on an iterate request is asked by: builder fixer test-author — not by '$RROLE'." ;; esac
          [ -n "$RDSEL" ] || rq_die 'an iterate request with --deployed-selection names the deployed pass'"'"'s selection, in the runner'"'"'s syntax: --deployed-selection <selection>.'
        fi
        [ "$HASSEL" = yes ] && [ -n "$RSEL" ] || rq_die "a $TYPE request names its selection, in the runner's syntax: -- <selection> (ViD never builds one)." ;;
      close) [ -n "$STEPS" ] || rq_die 'a close names its steps: --steps <id,…> (the rows come from sh checks/metrics.sh close-rows).'
        [ -z "$ROWS$ROWSF" ] || rq_usage
        # v0.9.7.0.12 (3.2, R2): a close batch takes its phases as groups, no selection of its own
        if [ "$BATCH" = yes ]; then
          [ "$HASSEL" = no ] && [ -z "$EXPECT" ] || rq_die 'a close batch takes its selections from its groups (--phase1, --phase2): no -- <selection> and no --expect.'
          [ -n "$PH1" ] && [ -n "$PH2" ] || rq_die 'a close batch names both phase files: --phase1 <file> --phase2 <file> (one group per line: <rows> | <inline words> | <deployed words>; a file may be empty).'
          [ -f "$PH1" ] || rq_die "no phase file $PH1."; [ -f "$PH2" ] || rq_die "no phase file $PH2."
        else [ -z "$PH1$PH2" ] || rq_die '--phase1 and --phase2 belong to a close batch (--batch).'; fi
        [ "$BATCH" = yes ] || [ -n "$RSEL" ] || rq_die 'a close names its selection, built from close-rows'"'"' list in the runner'"'"'s syntax: -- <selection> [--deployed-selection <selection>].' ;;
      checkpoint) [ -z "$ROWS$ROWSF$STEPS" ] || rq_usage
        [ -n "$RSEL" ] || rq_die 'a checkpoint names its selection — every built row, every variant, in the runner'"'"'s syntax: -- <selection>.' ;;
      full) [ -z "$ROWS$ROWSF$STEPS" ] && [ "$HASSEL" = no ] || rq_die 'a full request runs the whole ledger: no rows, steps or selection.' ;;
    esac
    [ "$BATCH" = no ] || [ "$TYPE" = close ] || rq_die '--batch belongs to a close: --type close --steps <id,…> --batch --phase1 <file> --phase2 <file>.'
    [ "$TYPE" = close ] || [ -z "$PH1$PH2" ] || rq_usage
    [ -z "$ROWSF" ] || [ -f "$ROWSF" ] || rq_die "no rows file $ROWSF."
    # v0.9.7.0.11 (3.6, R6): an export-backed request runs a committed tree — a worktree with changes outside .vid/ is refused now
    case "$TYPE" in close|full|checkpoint)
      _dy=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null || true)
      [ -z "$_dy" ] || rq_die "the worktree carries uncommitted changes, and a $TYPE runs HEAD's tree — commit first: $(printf '%s\n' "$_dy" | head -n 5 | cut -c4- | paste -sd ',' - | sed 's/,/, /g')$([ "$(printf '%s\n' "$_dy" | grep -c .)" -gt 5 ] && echo ' …')." ;;
    esac
    RQH=$PWD; RQG=no
    if [ -f checks/plan.sh ]; then
      _grc=0; _g=$(sh checks/plan.sh gate 2>/dev/null) || _grc=$?
      [ "$_grc" -eq 3 ] && rq_die "${_g#off } (sh checks/plan.sh gate)."
      case "$_g" in 'on '*) [ -d "${_g#on }/.vid" ] && { RQH=${_g#on }; RQG=yes; } ;; esac
    fi
    # R5: outside a live develop run a close or a checkpoint has no plan to close against
    if [ "$RQG" = no ]; then case "$TYPE" in close|checkpoint) rq_die "a $TYPE runs only inside a develop run (sh checks/plan.sh gate is off); outside one, request prove-red, iterate, full or deployed." ;; esac; fi
    # v0.9.8 (3.4, R4): one fault at a time — a proof request waits for none: it is refused while another is open
    if [ "$RPURP" = proof ]; then
      for _pq in "$RQH"/.vid/requests/*/request; do
        [ -f "$_pq" ] && [ "$(rq_kv purpose "$_pq")" = proof ] || continue
        case "$(cat "${_pq%/request}/state" 2>/dev/null)" in done|capped|failed-to-start|stopped|cancelled) ;; *) rq_die "one fault at a time: the proof request $(basename "$(dirname "$_pq")") is still open — wait for it (sh checks/test.sh wait $(basename "$(dirname "$_pq")"))." ;; esac
      done
    fi
    RQT=$(mktemp -d); trap 'rm -rf "$RQT"' EXIT
    # the rows
    case "$TYPE" in
      prove-red|iterate|deployed)
        { printf '%s\n' "$ROWS"; [ -n "$ROWSF" ] && cat "$ROWSF"; } | grep -oE 'ROW-[0-9A-Za-z-]*[0-9A-Za-z]' | sort -u > "$RQT/rows" || true ;;
      close)
        if [ "$BATCH" = yes ]; then   # v0.9.7.0.12 (3.2, R2): the groups' rows; close-rows is read once, at serve, and frozen
          { bt_parse "$PH1" 1; bt_parse "$PH2" 2; } > "$RQT/groups"
          grep -q '^BAD' "$RQT/groups" && rq_die "the phase files do not parse:
$(sed -n 's/^BAD\t/    /p' "$RQT/groups" | head -n 10)"
          cut -f4 "$RQT/groups" | tr ',' '\n' | grep -v '^$' | sort | uniq -d > "$RQT/dup"
          [ -s "$RQT/dup" ] && rq_die "a row belongs to one group only: $(head -n 10 "$RQT/dup" | paste -sd ',' - | sed 's/,/, /g') in two."
          cut -f4 "$RQT/groups" | tr ',' '\n' | grep -v '^$' | sort -u > "$RQT/rows"
          [ -s "$RQT/groups" ] || rq_die 'the phase files hold no group.'
        else
        sh checks/metrics.sh close-rows --steps "$STEPS" > "$RQT/cr" 2> "$RQT/cr.err" || { cat "$RQT/cr.err" >&2; rq_die "close-rows did not give the close's rows (sh checks/metrics.sh close-rows --steps $STEPS)."; }
        sed -n 's/^required row=\([^ ]*\).*/\1/p' "$RQT/cr" | sort -u > "$RQT/rows"; fi ;;
      checkpoint)   # v0.9.7.0.12 (3.7, R7): the one population — the eligible rows of closed steps and the materialised probes
        sh checks/metrics.sh checkpoint --population 2>/dev/null | grep -E '^(ROW|HOS)-' | sort -u > "$RQT/rows" || true ;;
      full)
        { [ -f INVENTORY.md ] && sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' '$1 ~ /^[[:space:]]*ROW-/ { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); print id }'; } | sort -u > "$RQT/rows" || true ;;
    esac
    if [ "$BATCH" = yes ]; then   # v0.9.7.0.12 (3.6, R6): deployed words need the deployed shape; a deployed-paid row's group runs it deployed only
      _ds=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' docker-compose.test.yml 2>/dev/null)
      if [ -z "$_ds" ]; then
        awk -F'\t' '$6 != "" { print "    group " $3 ": " $7 }' "$RQT/groups" > "$RQT/bad"
        [ -s "$RQT/bad" ] && rq_die "the harness contract declares no deployed-selector:, so no group carries deployed words:
$(head -n 10 "$RQT/bad")"
      elif [ -f checks/evidence.sh ]; then
        sh checks/evidence.sh kinds "$RQT/rows" > "$RQT/kinds" 2>/dev/null || : > "$RQT/kinds"
        awk -F'\t' -v kf="$RQT/kinds" 'BEGIN { while ((getline l < kf) > 0) { split(l, a, " "); if (a[2] == "journey" || a[3] == "(process)") D[a[1]] = 1 } }
          { n = split($4, r, ","); d = ""; o = ""; for (i = 1; i <= n; i++) if (r[i] in D) d = d (d == "" ? "" : ",") r[i]; else o = o (o == "" ? "" : ",") r[i]
            if ($5 != "" && d != "") print "    group " $3 ": " d " — a journey or actor (process) row, paid deployed only at close: no inline words in its group"
            else if ($5 == "" && o != "") print "    group " $3 ": " o " — paid inline, but the group carries no inline words" }' "$RQT/groups" > "$RQT/bad"
        [ -s "$RQT/bad" ] && rq_die "the groups do not fit their rows' shapes:
$(head -n 10 "$RQT/bad")"
      fi
    elif [ "$TYPE" = close ] || [ "$TYPE" = checkpoint ] || [ "$RHASD" = yes ]; then   # a deployed-shape selection when the harness declares one (test.sh would refuse it after taking a slot)
      _ds=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' docker-compose.test.yml 2>/dev/null)
      if [ "$TYPE" != iterate ] && [ -n "$_ds" ] && { [ "$RHASD" = no ] || [ -z "$RDSEL" ]; }; then rq_die "the harness contract declares deployed-selector:, so a $TYPE names its deployed-shape selection too: --deployed-selection <selection>."; fi
      if [ -z "$_ds" ] && [ "$RHASD" = yes ]; then rq_die 'the harness contract declares no deployed-selector:, so a '"$TYPE"' is one inline pass: no --deployed-selection.'; fi
    fi
    # v0.9.7.0.11 (3.9, R9): a deployed run credits only journey and (process) rows — any other is refused before the ticket
    if [ "$TYPE" = deployed ] && [ -f checks/evidence.sh ] && [ -n "$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' docker-compose.test.yml 2>/dev/null)" ]; then
      sh checks/evidence.sh kinds "$RQT/rows" > "$RQT/kinds" 2>/dev/null || : > "$RQT/kinds"
      awk 'NR == FNR { if ($2 == "journey" || $3 == "(process)") K[$1] = 1; next } !($1 in K)' "$RQT/kinds" "$RQT/rows" > "$RQT/nodep"
      [ -s "$RQT/nodep" ] && rq_die "a deployed run credits only journey and (process) rows; not: $(head -n 10 "$RQT/nodep" | paste -sd ',' - | sed 's/,/, /g')$([ "$(grep -c . "$RQT/nodep")" -gt 10 ] && echo ' …') — request them inline (an iterate)."
    fi
    # R6: inside a live run, before the ticket — no empty row list; no row of a step not yet started (full and the testenv pass's measurement excepted)
    if [ "$RQG" = yes ]; then
      [ -s "$RQT/rows" ] || rq_die "the request names no row (a $TYPE inside a develop run runs rows: --rows <ROW-id,…>, or a close's steps with required rows)."
      if [ "$TYPE" != full ] && [ "$RROLE" != testenv ] && sh checks/plan.sh parse > "$RQT/parsed" 2>/dev/null; then
        { [ -f "$RQH/.vid/metrics-events" ] && awk '$1 == "step-start" { for (i = 2; i <= NF; i++) if (index($i, "step=") == 1) print substr($i, 6) }' "$RQH/.vid/metrics-events"; } | sort -u > "$RQT/started" || true
        awk -F'\t' -v sf="$RQT/started" -v rf="$RQT/rows" 'BEGIN { while ((getline l < sf) > 0) S[l] = 1; while ((getline l < rf) > 0) W[l] = 1 }
          $1 == "row" && ($2 in W) && !($3 in S) { print $2 " (step " $3 ")" }' "$RQT/parsed" > "$RQT/unstarted"
        [ -s "$RQT/unstarted" ] && rq_die "rows of a step not yet started (no step-start): $(head -n 10 "$RQT/unstarted" | paste -sd ',' - | sed 's/,/, /g') — start the step first (sh checks/plan.sh start <id>, or its brief's admission); a row the plan does not hold is never refused."
      fi
    fi
    SUPN=1; [ "$TYPE" = iterate ] && [ "$RHASD" = yes ] && SUPN=2   # R6: two passes, two start-ups, the cases once
    # v0.9.8.1 (R12, F-11): when the deployed selection repeats an inline selection word (the same file or test id),
    # the deployed pass runs those cases again, so the cases are counted once a pass (CASN=2); --expect is one pass's
    CASN=1
    if [ "$SUPN" = 2 ]; then for _dw in $RDSEL; do for _iw in $RSEL; do [ "$_dw" = "$_iw" ] && CASN=2; done; done; fi
    # v0.9.7.0.10 (3.1, R10): a request with two passes — a deployed selection given, or a full run under a harness
    # declaring deployed-selector: — counts the teardown between them once
    TWOP=no; [ "$RHASD" = yes ] && TWOP=yes
    if [ "$TYPE" = full ] && [ -n "$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { print; exit }' docker-compose.test.yml 2>/dev/null)" ]; then TWOP=yes; fi
    rq_estimate "$RQH" "$RQT/rows"; rq_limits "$RQH"
    NROWS=$(grep -c . "$RQT/rows" || true)
    TK="$(date -u '+%Y%m%dT%H%M%SZ')-$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
    mkdir -p "$RQH/.vid/requests"
    mkdir "$RQH/.vid/requests/$TK" || rq_die "the ticket $TK exists already; ask again."
    TD=$(cd "$RQH/.vid/requests/$TK" && pwd)
    cp "$RQT/rows" "$TD/rows"; cp "$RQT/nohist" "$TD/nohist"
    [ "$BATCH" = no ] || cp "$RQT/groups" "$TD/groups"
    printf 'type=%s\nrole=%s\nrunrole=%s\nwhy=%s\nrows=%s\nestimate=%s\nsilence=%s\nstartup=%s\nlimit=%s\nestimate-startup=%s\nteardown=%s\ncases=%s\nexpect=%s\nno-history=%s\ncwd=%s\nsel=%s\ndsel=%s\nhasdsel=%s\nsteps=%s\ngated=%s\nprove=%s\ncreated=%s\ntry=%s\n' \
      "$TYPE" "$RROLE" "$RUNROLE" "$(printf '%s' "$WHY" | tr '"' "'")" "$NROWS" "$EST" "$SIL" "$SUL" "$LIM" "$STARTUP" "$TDN" "$CASES" "$EXPECT" "$NH" "$PWD" "$RSEL" "$RDSEL" "$RHASD" "$STEPS" "$RQG" "${VID_TESTENV_PROVE:-}" "$(date +%s)" "$RTRY" > "$TD/request"
    [ -z "$RPURP" ] || echo "purpose=$RPURP" >> "$TD/request"   # v0.9.8 (R15)
    [ "$BATCH" = no ] || echo 'batch=yes' >> "$TD/request"
    [ -z "$RSTAGE" ] || echo "stage=$RSTAGE" >> "$TD/request"   # v0.26.10.5 (R8)
    rq_put "$TD/state" queued
    : > "$TD/log"
    SELFP="$(cd "$(dirname "$0")" && pwd)/${0##*/}"
    # detached: a new session where the host offers one, else immune to hangups — never tied to the caller's process group
    if command -v setsid >/dev/null 2>&1; then ( setsid sh "$SELFP" serve "$TD" < /dev/null >> "$TD/log" 2>&1 & )
    elif command -v perl >/dev/null 2>&1; then ( perl -e 'use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' sh "$SELFP" serve "$TD" < /dev/null >> "$TD/log" 2>&1 & )
    else ( trap '' HUP; sh "$SELFP" serve "$TD" < /dev/null >> "$TD/log" 2>&1 & ); fi
    # v0.9.7.0.8 (T2.1): held slots, live and stale (the holder pid gone), as the refusal tells them apart
    HD=$(rq_hostd); _live=0; _stale=0
    for _s in "$HD"/stack.*; do
      [ -d "$_s" ] || continue
      _p=$(sed -n 1p "$_s/holder" 2>/dev/null || true)
      if [ -n "$_p" ] && pid_alive "$_p"; then _live=$((_live + 1)); else _stale=$((_stale + 1)); fi
    done
    _qb=$(for _s in "$RQH"/.vid/requests/*/state; do [ -f "$_s" ] && [ "$(cat "$_s")" = queued ] && basename "$(dirname "$_s")"; done | awk -v t="$TK" '$0 < t' | grep -c . || true)
    if [ "$BATCH" = yes ]; then echo "ViD test: request $TK — close batch, $NROWS row(s) in $(grep -c . "$TD/groups") group(s), role $RROLE; chunks are packed at serve, after close-rows is frozen"
    else echo "ViD test: request $TK — $TYPE, $NROWS row(s), role $RROLE"; fi
    if [ "$TYPE" = deployed ]; then _sul="${STARTUPD}s"; elif [ "$SUPN" -eq 2 ] && [ "$STARTUP" = "$STARTUPD" ]; then _sul="2 × ${STARTUP}s"; elif [ "$SUPN" -eq 2 ]; then _sul="${STARTUP}s + ${STARTUPD}s deployed"; else _sul="${STARTUP}s"; fi
    echo "estimate ${EST}s (start-up $_sul + cases $([ "$CASN" -eq 2 ] && echo '2 × ')${CASES}s${EXPECT:+, from --expect}$([ -z "$EXPECT" ] && [ "$FROMF" = yes ] && echo ", from the selection's files")$([ "$TDN" -gt 0 ] && echo " + teardown between the passes ${TDN}s")) · stops after $(rq_dur "$SIL") with no output, $(rq_dur "$SUL") of start-up, or $(rq_dur "$LIM")"
    # v0.9.8.1 (R26): the selection words resolving to no recorded case — the estimate cannot see what they reach
    if [ -z "$EXPECT" ] && [ -s "$RQT/unresolved" ]; then echo "selection reaches more than the rows: give --expect ($(head -n 10 "$RQT/unresolved" | paste -sd ' ' -) — no recorded case)"; fi
    # v0.9.7.0.9 (3.1, R1): a row whose test file gained lines naming it since its history is listed beside the rows with none
    NU=$(grep -c . "$RQT/unseen" || true)
    if [ "$NH" -gt 0 ] || [ "$NU" -gt 0 ]; then
      { cat "$RQT/nohist"; awk -F'\t' '{ print $1 " (+" $2 " lines since its history)" }' "$RQT/unseen"; } > "$RQT/listed"
      echo "no-history $NH: $(head -n 10 "$RQT/listed" | paste -sd ',' -)$([ $((NH + NU)) -gt 10 ] && echo ' …') — 10 s each; give --expect <seconds> when they are slow"
    fi
    echo "queue: $_live slot(s) held live and $_stale stale on this host, $_qb request(s) queued before this one"
    echo "next: sh checks/test.sh wait $TK"
    exit 0 ;;
  serve)   # the detached run of a request (started by `request`; never called by hand)
    TD=${2:-}; [ -f "$TD/request" ] || exit 2
    cd "$(rq_kv cwd "$TD/request")" || exit 2
    echo "$$" > "$TD/supervisor"
    if [ "$(rq_kv batch "$TD/request")" = yes ]; then batch_serve; exit 0; fi   # v0.9.7.0.12 (3.2, R2): the batch supervisor
    _pv=$(rq_kv prove "$TD/request"); [ -n "$_pv" ] && { VID_TESTENV_PROVE=$_pv; export VID_TESTENV_PROVE; }
    set -- --wait "${VID_REQUEST_QUEUE:-14400}" --role "$(rq_kv runrole "$TD/request")"
    [ "$(rq_kv type "$TD/request")" = deployed ] && set -- "$@" --deployed
    # v0.9.7.0.9 (3.3, R3): the selection as its words, one per argument — `request` refused any word holding a space,
    # so the direct run's own check sees the same words and the joined string is unchanged
    # v0.9.7.0.12: a chunk always passes `--`, so a deployed-only chunk's words reach --deployed-selection whole
    set -f; _s=$(rq_kv sel "$TD/request"); { [ -n "$_s" ] || [ -n "$(rq_kv batch "$TD/request")" ]; } && set -- "$@" -- $_s
    [ "$(rq_kv hasdsel "$TD/request")" = yes ] && set -- "$@" --deployed-selection $(rq_kv dsel "$TD/request")
    set +f
    # v0.9.7.1 (3.6, R6): a marked ticket never starts
    if [ -f "$TD/cancel" ]; then rq_final "$TD" 77; exit 0; fi
    rq_watch "$TD" & echo "$!" > "$TD/watcher"
    _id=$(rq_kv id "$TD/request"); VID_REQUEST=${_id:-${TD##*/}} sh checks/test.sh "$@" >> "$TD/log" 2>&1 &
    TP=$!; echo "$TP" > "$TD/pid"
    rq_put "$TD/pid-start" "$(ps -o lstart= -p "$TP" 2>/dev/null | sed 's/^ *//')"
    ST=0; wait "$TP" || ST=$?
    rq_final "$TD" "$ST"   # v0.9.7.0.10 (3.1, R1): nothing, when the run wrote its result before its final teardown
    exit 0 ;;
  analyst-due)   # v0.9.7.0.9 (3.4, R4): each analyst-due at the run's home with no analyst-done for its ticket; writes nothing, refuses nothing (v0.9.7.0.10 R7: the retained reasons only)
    # v0.9.7.3 (3.9, R9): --try <id> keeps only the tickets that attempt asked (their request's try=)
    _atry=''; [ "${2:-}" = --try ] && _atry=${3:-}
    _h=.; if [ -f checks/plan.sh ]; then _g=$(sh checks/plan.sh gate 2>/dev/null) || true; case "$_g" in 'on '*) [ -d "${_g#on }/.vid" ] && _h=${_g#on } ;; esac; fi
    [ -f "$_h/.vid/metrics-events" ] || exit 0
    _adf=$(mktemp)
    if [ -n "$_atry" ]; then for _rq in "$_h"/.vid/requests/*/request; do [ -f "$_rq" ] && grep -qx "try=$_atry" "$_rq" && basename "$(dirname "$_rq")"; done > "$_adf" 2>/dev/null || true; fi
    awk -v tf="$_adf" -v want="${_atry:+yes}" 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      BEGIN { while ((getline l < tf) > 0) TK[l] = 1 }
      NR == FNR { if ($1 == "analyst-done") D[kv("request")] = 1; next }
      $1 == "analyst-due" && kv("reason") ~ /^(cap|setup|slow)$/ && !(kv("request") in D) { r = kv("request"); t = r; sub(/\/.*/, "", t); if (want == "yes" && !(t in TK)) next; print "analyst due: request=" r " reason=" kv("reason") }' "$_h/.vid/metrics-events" "$_h/.vid/metrics-events" |
      awk 'NR <= 10 { print } END { if (NR > 10) print "(+" NR - 10 " more)" }'
    rm -f "$_adf"
    exit 0 ;;
  cancel)   # v0.9.7.1 (3.6, R6): an agent's own tickets, by its attempt id; v0.9.8.1 (R28, F-17): or one ticket by its id
    shift; CTRY=''; CTK=''; CBY=run-manager
    while [ $# -gt 0 ]; do case "$1" in --try) CTRY=${2:-}; shift 2 ;; --ticket) CTK=${2:-}; shift 2 ;; --by) CBY=${2:-}; shift 2 ;; *) rq_usage ;; esac; done
    if [ -n "$CTRY" ] && [ -n "$CTK" ]; then rq_usage; fi
    [ -n "$CTRY$CTK" ] || rq_usage
    case "$CTRY$CTK$CBY" in *[!A-Za-z0-9._:-]*) rq_die "cancel takes an attempt id or a ticket id, and a name: letters, digits, '.', '_', ':' and '-'." ;; esac
    # v0.26.10.3 (R8): at the home whether the gate is on or not; with no match there, in every checkout
    _h=.; _hh=$(rq_home); [ -n "$_hh" ] && [ -d "$_hh/.vid" ] && _h=$_hh
    _hp=$(cd "$_h" && pwd -P); _cands=$_h
    _n=0
    for _cw in $(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do [ "$(cd "$_cw" 2>/dev/null && pwd -P)" = "$_hp" ] || _cands="$_cands
$_cw"; done
    for _ch in $_cands; do
    [ "$_n" -gt 0 ] && break
    for _r in "$_ch"/.vid/requests/*/request; do
      [ -f "$_r" ] || continue
      if [ -n "$CTK" ]; then _rd=$(dirname "$_r"); [ "${_rd##*/}" = "$CTK" ] || continue; else [ "$(rq_kv try "$_r")" = "$CTRY" ] || continue; fi
      _d=$(cd "$(dirname "$_r")" && pwd); _t=${_d##*/}; _n=$((_n + 1)); _ctry=$(rq_kv try "$_r")   # the ticket's own try, empty when none
      _s=$(cat "$_d/state" 2>/dev/null || echo queued)
      case "$_s" in done|capped|failed-to-start|stopped|cancelled) echo "$_t: $_s — left alone"; continue ;; esac
      if [ -f "$_d/cancel" ]; then echo "$_t: cancel already marked — nothing more"; continue; fi
      printf 'by=%s\nat=%s\n' "$CBY" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$_d/cancel.tmp.$$" && mv "$_d/cancel.tmp.$$" "$_d/cancel"
      printf 'ticket-cancelled ticket=%s try=%s by=%s at=%s\n' "$_t" "$_ctry" "$CBY" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$_ch/.vid/metrics-events"
      _sig=no
      if [ "$(cat "$_d/state" 2>/dev/null)" = running ]; then
        _p=$(cat "$_d/pid" 2>/dev/null || true); _ps=$(cat "$_d/pid-start" 2>/dev/null || true)
        if [ -n "$_p" ] && [ -n "$_ps" ] && [ "$(ps -o lstart= -p "$_p" 2>/dev/null | sed 's/^ *//')" = "$_ps" ]; then kill -TERM "$_p" 2>/dev/null && _sig=yes
        # v0.9.7.1 (found in rehearsal R-6): a ticket served inside an agent's sandbox records no start time (ps can't
        # read it there); its run is identified instead as the child of the ticket's own serve, whose command names it
        elif [ -n "$_p" ] && [ -z "$_ps" ] && _sv=$(cat "$_d/supervisor" 2>/dev/null) && [ -n "$_sv" ] \
          && [ "$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')" = "$_sv" ] \
          && ps -o command= -p "$_sv" 2>/dev/null | grep -qF -- "serve $_d"; then kill -TERM "$_p" 2>/dev/null && _sig=yes; fi
      fi
      echo "$_t: $_s — cancel marked$([ "$_sig" = yes ] && echo ', TERM sent to its run'); confirm with sh checks/test.sh wait $_t"
      rq_stopped "$_d"
    done
    done
    if [ "$_n" -eq 0 ]; then if [ -n "$CTK" ]; then echo "ViD test: no ticket $CTK at $_h/.vid/requests/"; else echo "ViD test: no ticket carries try=$CTRY at $_h/.vid/requests/"; fi; fi
    exit 0 ;;
  wait)
    TK=${2:-}; [ -n "$TK" ] || rq_usage
    _h=$(rq_home)   # v0.26.10.3 (R8): the home whether the gate is on or not, then every checkout
    TD=$(rq_find "$TK" "$_h") || { echo "ViD test: no ticket $TK (.vid/requests/ at the run's home, here, or in any checkout)." >&2; exit 2; }
    STOPL=$(rq_stopped "$TD")
    MAX=${VID_WAIT_MAX:-200}; W0=$(date +%s)
    # v0.9.7.3 (3.9, R9): VID_WAIT_MAX is the self-test's override only — ignored in a checkout whose .vid/home names
    # a run (a builder's worktree): its wait returns within 200 s
    _wt=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P); _wh=$(sed -n 1p "$_wt/.vid/home" 2>/dev/null || true)
    if [ -n "$_wh" ] && [ -f "$_wh/.vid/RUN-STATE.md" ]; then MAX=200; fi
    E=$(rq_kv estimate "$TD/request"); SL=$(rq_kv silence "$TD/request")
    while :; do
      S=$(cat "$TD/state" 2>/dev/null || echo queued)
      case "$S" in done|capped|failed-to-start|stopped|cancelled) if [ -f "$TD/result" ]; then cat "$TD/result"
          # v0.9.7.0.10 (3.1, R1): the result came before the final teardown — said while the run folder is held
          _rf=$(cat "$TD/run" 2>/dev/null || true)
          if [ -n "$_rf" ] && [ -d "$_rf" ]; then
            if grep -q '^teardown-failed' "$_rf/holder" 2>/dev/null; then echo 'teardown failed — the slot and the run folder are kept (teardown-failed at the run'"'"'s home); the result stands'
            else echo 'teardown pending'; fi
          fi
          [ -n "$STOPL" ] && echo "$STOPL"
          exit "$(cat "$TD/exit" 2>/dev/null || echo 1)"; fi ;; esac
      NOW=$(date +%s)
      # v0.9.7.0.12 (3.2, R2): a batch's parent — its chunks' progress; it has no limits of its own (each chunk has its own)
      if [ "$(rq_kv batch "$TD/request")" = yes ]; then
        if [ $(( NOW - W0 )) -ge "$MAX" ]; then
          if [ "$S" = running ]; then echo "running $(( NOW - $(cat "$TD/running-at" 2>/dev/null || echo "$NOW") ))s — chunks $(TD=$TD bt_progress) done"
          else echo "queued $(( NOW - $(rq_kv created "$TD/request") ))s — freezing close-rows and packing the chunks"; [ -s "$TD/holders" ] && cat "$TD/holders"; fi
          [ -n "$STOPL" ] && echo "$STOPL"
          exit 75
        fi
        _l=$(( MAX - (NOW - W0) )); [ "$_l" -gt 5 ] && _l=5; sleep "$_l"; continue
      fi
      # v0.26.10.4 (R4): a running request's counts are its watcher's own (the `watch` file: awake, silent), so the two
      # never disagree; `overdue` means the run is still running while its watcher's process is gone
      if [ "$S" = running ]; then EL=$(sed -n 's/^awake=\([0-9]*\).*/\1/p' "$TD/watch" 2>/dev/null || true); SI=$(sed -n 's/.* silent=\([0-9]*\).*/\1/p' "$TD/watch" 2>/dev/null || true)
        EL=${EL:-0}; SI=${SI:-0}
      else EL=$(( NOW - $(rq_kv created "$TD/request") )); fi
      if [ "$S" = running ] && [ ! -f "$TD/cap-hit" ] && [ -s "$TD/watcher" ] && ! pid_alive "$(cat "$TD/watcher")" \
        && [ ! -f "$TD/result" ] && [ "$(cat "$TD/state" 2>/dev/null)" = running ]; then
        echo "overdue ${EL}s of estimate ${E}s — still running and its watcher's process ($(cat "$TD/watcher")) is gone: nothing stops it on silence (ticket $TK)"
        exit 76
      fi
      if [ $(( NOW - W0 )) -ge "$MAX" ]; then
        if [ -f "$TD/cap-hit" ]; then echo "stopping ($(rq_kv reason "$TD/cap-hit")) ${EL}s of estimate ${E}s"
        elif [ "$S" = running ]; then echo "running ${EL}s of estimate ${E}s, silent ${SI}s of ${SL:-1200}s"
        else echo "$S ${EL}s of estimate ${E}s"; fi
        # v0.9.7.0.8 (T2.1): while queued, why — the slots' holders as the run last saw them
        [ "$S" = queued ] && [ -s "$TD/holders" ] && cat "$TD/holders"
        [ -n "$STOPL" ] && echo "$STOPL"
        exit 75
      fi
      _l=$(( MAX - (NOW - W0) )); [ "$_l" -gt 5 ] && _l=5
      sleep "$_l"
    done ;;
esac

SEL=''; ROLE=''; DEPLOYED=no; WAIT=''; DSELX=''; HAVEDSX=no
usage() { echo "ViD test: usage — sh checks/test.sh [--role builder|fixer|test-author|orchestrator|close|checkpoint|grader|testenv] [--deployed] [--deployed-selection <selection>] [--wait <seconds>] [-- <selector>]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --role) [ $# -ge 2 ] || usage; ROLE=$2; case "$ROLE" in builder|fixer|test-author|orchestrator|close|checkpoint|grader|testenv) ;; *) usage ;; esac; shift 2 ;;
    --deployed) DEPLOYED=yes; shift ;;
    --deployed-selection) [ $# -ge 2 ] || usage; selword "$2"; DSELX=$2; HAVEDSX=yes; shift 2 ;;
    --wait) [ $# -ge 2 ] || usage; WAIT=$2; case "$WAIT" in ''|*[!0-9]*) usage ;; esac; shift 2 ;;
    --) shift
        # v0.9.6.1: a trailing `--deployed-selection <selection>` after the selection is the deployed pass's own
        SEL=''; while [ $# -gt 0 ] && [ "$1" != --deployed-selection ]; do selword "$1"; SEL="${SEL:+$SEL }$1"; shift; done
        if [ $# -gt 0 ]; then shift; for _w in "$@"; do selword "$_w"; done; DSELX="$*"; HAVEDSX=yes; fi
        break ;;
    *) usage ;;
  esac
done
[ "$DEPLOYED" = yes ] && [ -z "$SEL" ] && { echo 'ViD test: --deployed is a scoped run: sh checks/test.sh --deployed -- <selector>. A full run pays the deployed pass itself when the harness declares deployed-selector:.' >&2; exit 2; }

COMPOSE=${VID_COMPOSE:-}
if [ -z "$COMPOSE" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo 'ViD test: Docker is not installed (or not on PATH).' >&2
    echo 'The ledger only runs inside the test container so it can never touch' >&2
    echo 'real credentials or live services. Install Docker Desktop, start it,' >&2
    echo 'then run: sh checks/test.sh' >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo 'ViD test: Docker is installed but the daemon is not running — start Docker Desktop and retry.' >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo 'ViD test: the "docker compose" (v2) plugin is missing. Update Docker and retry.' >&2
    exit 1
  fi
  COMPOSE='docker compose'
fi
[ -f docker-compose.test.yml ] || { echo 'ViD test: docker-compose.test.yml missing — failing closed.' >&2; exit 1; }

# --- v0.9.6: the gate (3.6) ------------------------------------------------------
GATED=no; VHOME=''
if [ -f checks/plan.sh ]; then
  _grc=0; _g=$(sh checks/plan.sh gate 2>/dev/null) || _grc=$?
  case "$_g" in 'on '*) VHOME=${_g#on }; [ -d "$VHOME/.vid" ] && GATED=yes ;; esac
  # v0.9.7.0.1 (3.1, R2): two or more live runs — never pick one, never run ungated
  if [ "$_grc" -eq 3 ]; then echo "ViD test: refused — ${_g#off } (sh checks/plan.sh gate)." >&2; exit 2; fi
fi
# v0.9.7.0.2 (3.4, R4): inside a develop run nobody runs this script directly — every run is a request
if [ "$GATED" = yes ] && [ -z "${VID_REQUEST:-}" ]; then
  echo 'ViD test: refused — inside a develop run nobody runs the test runner directly: make a request to the test manager (skills/vid-test-manager): sh checks/test.sh request --type <type> --role <role> --rows <ROW-id,…> --why "<one line>" -- <selection>, then sh checks/test.sh wait <ticket>.' >&2
  exit 2
fi
# v0.9.7.0.1 (3.2, R5): inside a develop run every test run names who runs it — refused before the lock
if [ "$GATED" = yes ] && [ -z "$ROLE" ]; then
  echo 'ViD test: refused — inside a develop run every test run names its role: --role builder|fixer|test-author|close|checkpoint|grader|testenv.' >&2
  exit 2
fi
if [ "$GATED" = yes ]; then
  RDIR="$VHOME/.vid/ledger-results"; EV="$VHOME/.vid/metrics-events"; BUDGET="$VHOME/.vid/budget"
else
  RDIR=.vid/ledger-results; EV=.vid/metrics-events; BUDGET=.vid/budget
fi
# v0.9.7.0.10 (3.7, R14): the environments are proved only on the harness they were proved on
TVOK=no
if [ -f "$BUDGET" ] && [ -f docker-compose.test.yml ] && grep -qxF "testenv=proved harness=$(cksum < docker-compose.test.yml | cut -d' ' -f1)" "$BUDGET"; then TVOK=yes; fi
mkdir -p "$RDIR"
# v0.9.7.0.2 (3.1): a request's run — its ticket folder at the run's home (here outside a run)
TD=''; RQF=''; RQW=''; CHUNK=no; BEXP=''; CTXD=''; PURPOSE=''
if [ -n "${VID_REQUEST:-}" ]; then
  for _d in "${VHOME:-.}/.vid/requests/$(rq_sub "$VID_REQUEST")" ".vid/requests/$(rq_sub "$VID_REQUEST")"; do [ -d "$_d" ] && { TD=$(cd "$_d" && pwd); break; }; done
  if [ -n "$TD" ]; then   # the request's fields ride its events; a direct call with no ticket (the runner's own tests) records none
    _rk() { sed -n "s/^$1=//p" "$TD/request" | head -n 1; }
    RQF=" request=$VID_REQUEST type=$(_rk type) rows=$(_rk rows) estimate=$(_rk estimate) silence=$(_rk silence) startup=$(_rk startup) limit=$(_rk limit)"
    [ -n "$(_rk try)" ] && RQF="$RQF try=$(_rk try)"   # v0.9.7.1 (3.6, R6)
    [ -n "$(_rk expect)" ] && RQF="$RQF expect=$(_rk expect)"
    [ "$(_rk no-history)" != 0 ] && RQF="$RQF no-history=$(_rk no-history)"
    PURPOSE=$(_rk purpose); [ -n "$PURPOSE" ] && RQF="$RQF purpose=$PURPOSE"   # v0.9.8 (R15): a proof's receipts, never ordinary
    RQW=" why=\"$(_rk why)\""
    # v0.9.7.0.12 (3.2, R2): a close batch's chunk runs the batch's export at its frozen tree; its events carry batch=
    if [ -n "$(_rk batch)" ] && [ "$GATED" = yes ]; then CHUNK=yes; BEXP=$(_rk export); BTREE=$(_rk tree); BBASE=$(_rk base); RQF="$RQF batch=$(_rk batch)"; fi
  fi
fi
HEAD=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)
# v0.9.6.1 (3.1, 3.8): a selected close or a checkpoint — inside the gate, a selection given
SELCLOSE=no
if [ "$GATED" = yes ] && { [ -n "$SEL" ] || [ "$CHUNK" = yes ]; }; then case "$ROLE" in close|checkpoint) SELCLOSE=yes ;; esac; fi
if [ "$ROLE" = checkpoint ] && [ "$SELCLOSE" = no ]; then
  if [ "$GATED" = no ]; then echo 'ViD test: refused — a checkpoint runs only inside a develop run under a 0.9.6 plan.' >&2
  else echo 'ViD test: refused — a checkpoint runs a selection: sh checks/test.sh --role checkpoint -- <selection> (every built row, in the runner'"'"'s syntax).' >&2; fi
  exit 2
fi
# v0.9.7.0.9 (3.5, R6): a builder's, fixer's or test-author's scoped run may carry its deployed pass too — BOTH
BOTH=no
if [ "$HAVEDSX" = yes ] && [ "$SELCLOSE" = no ] && [ -n "$SEL" ] && [ "$DEPLOYED" = no ] && [ -n "$DSELX" ]; then
  case "$ROLE" in builder|fixer|test-author) BOTH=yes ;; esac
fi
if [ "$HAVEDSX" = yes ] && [ "$SELCLOSE" = no ] && [ "$BOTH" = no ]; then
  echo 'ViD test: refused — --deployed-selection belongs to a selected close or a checkpoint inside a develop run under a 0.9.6 plan (sh checks/test.sh --role close -- <selection> --deployed-selection <selection>), or to a builder'"'"'s, fixer'"'"'s or test-author'"'"'s scoped run carrying its deployed pass (--role builder -- <selection> --deployed-selection <selection>).' >&2
  exit 2
fi
if [ "$ROLE" = checkpoint ]; then   # v0.9.6.1 (3.8): beside the build — never in the only slot
  _cs=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' "$BUDGET" 2>/dev/null | head -n 1)
  if [ "${_cs:-1}" -lt 2 ] || [ "$TVOK" != yes ] || [ -n "${VID_TESTENV_PROVE:-}" ]; then
    echo "ViD test: refused — a checkpoint runs only with two or more proved test environments (.vid/budget stacks=${_cs:-1} and testenv=proved harness=<this harness's hash>); with one it would take the only slot the build has." >&2
    exit 2
  fi
fi
if [ "$SELCLOSE" = yes ] && [ "$DEPLOYED" = yes ]; then
  echo "ViD test: refused — --deployed is a scoped run; a $ROLE's deployed pass takes --deployed-selection <selection>." >&2
  exit 2
fi

# --- the lock -----------------------------------------------------------------
LOCK=.vid/ledger.lock
lock_refused() {
  HPID=''; HSTART=''
  [ -f "$LOCK/holder" ] && { HPID=$(sed -n '1p' "$LOCK/holder"); HSTART=$(sed -n '2p' "$LOCK/holder"); }
  if [ -n "$HPID" ] && pid_alive "$HPID"; then
    echo "ViD test: refused — a ledger run is in progress (pid $HPID, started $HSTART; $LOCK). One run at a time: two stacks on one host is the recorded incident class." >&2
  else
    AGE='unknown age'
    if [ -f "$LOCK/holder" ]; then
      NOW=$(date +%s); THEN=$(sed -n '3p' "$LOCK/holder"); [ -n "$THEN" ] && AGE="$((NOW - THEN)) s old"
    fi
    echo "ViD test: refused — $LOCK exists and its holder (pid ${HPID:-unknown}, started ${HSTART:-unknown}) is gone: a STALE lock, $AGE. This script never removes it; look at what died, then remove the directory yourself." >&2
  fi
  exit 1
}
if [ "$GATED" = no ]; then
  # v0.9.6: the two kinds never run side by side in one folder
  for _h in .vid/runs/*/holder; do
    [ -f "$_h" ] || continue
    _p=$(sed -n 's/^pid=//p' "$_h" | head -n 1)
    if [ -n "$_p" ] && pid_alive "$_p"; then
      echo "ViD test: refused — a gated develop run is in progress here (${_h%/holder}, pid $_p); a run outside the gate waits until it ends." >&2
      exit 1
    fi
  done
  if ! mkdir "$LOCK" 2>/dev/null; then lock_refused; fi
  printf '%s\n%s\n%s\n' "$$" "$(date '+%Y-%m-%d %H:%M:%S')" "$(date +%s)" > "$LOCK/holder"
else
  [ -d "$LOCK" ] && lock_refused
fi

# --- v0.9.6: the run folder (3.7.2), at the run's home ------------------------------
RUN=''; RUNID=''
PENDING=.vid/ledger-results/pending.xml
if [ "$GATED" = yes ]; then
  for _h in "$VHOME"/.vid/runs/*/holder; do   # a stale run folder is reported with its age, never removed here
    [ -f "$_h" ] || continue
    _p=$(sed -n 's/^pid=//p' "$_h" | head -n 1); _t=$(sed -n 's/^start=//p' "$_h" | head -n 1)
    pid_alive "${_p:-0}" && continue
    echo "ViD test: note — ${_h%/holder} is a STALE run folder (pid ${_p:-unknown} is gone, $(( $(date +%s) - ${_t:-0} )) s old$(grep -q '^teardown-failed' "$_h" && echo '; its teardown failed')). Never removed here: inspect its compose project, bring it down, then remove the folder (and its slot, if held)." >&2
  done
  RUNID="$(date -u '+%Y%m%dT%H%M%SZ')-$$"
  RUN="$VHOME/.vid/runs/$RUNID"
  mkdir -p "$RUN/results"
  PENDING="$RUN/results/pending.xml"
  _kd=full; [ -n "$SEL" ] && _kd=scoped; [ "$DEPLOYED" = yes ] && _kd=scoped-deployed; [ "$SELCLOSE" = yes ] && _kd=$ROLE
  printf 'pid=%s\nstart=%s\nkind=%s\nworktree=%s\n' "$$" "$(date +%s)" "$_kd" "$PWD" > "$RUN/holder"
  # v0.9.7.0.10 (3.1): wait says `teardown pending` while it is held; v0.9.8.1 (R45, F-37): written only once the folder
  # and its holder exist, and removed with the folder at the run's end
  [ -z "$TD" ] || { [ -f "$RUN/holder" ] && printf '%s\n' "$RUN" > "$TD/run"; } || true
fi

# --- the host lease (v0.9.3 3.10) --------------------------------------------------
HOSTD="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"; HOSTD="${HOSTD%/}/vid-host"
STACKS=1
if [ -f "$BUDGET" ]; then
  B=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' "$BUDGET" | head -n 1)
  [ -n "$B" ] && [ "$B" -ge 1 ] && STACKS=$B
fi
LIMIT=$STACKS
PROVE=${VID_TESTENV_PROVE:-}
if [ "$GATED" = yes ]; then
  # v0.9.6 (3.9): slots above 1 only once the environments are proved; the proof itself takes exactly two
  # v0.9.7.0.10 (R14): proved on another harness, or a bare testenv=proved, is one environment until the pass re-proves
  if [ "$TVOK" = yes ]; then :; else LIMIT=1; [ -n "$PROVE" ] && LIMIT=2; fi
fi
mkdir -p "$HOSTD"
LEASE=''; K=''
# v0.9.7.0.11 (3.5, R5): admission under one host lock (v0.9.8 R16: a symbolic link naming its holder's pid and
# start time, below; a stale one is moved aside, checked and removed, as a stale slot is); with another ViD slot held, a slot is taken only when the
# capacity estimate — Docker's MemTotal, less the memory of non-ViD projects' containers, less env-mb for each slot
# held, started or not — is at least env-mb + memory-headroom-mb; else MEMWAIT says so and the run waits as for a
# busy slot. The first slot is never held back; no env-mb in .vid/budget (or no Docker), no check.
ADMIT=''; MEMWAIT=''
# v0.9.8 (R16): the lock is a symbolic link made in one step, `ln -s "<pid> <start time>" admit.lock` — its target text
# names the holder, so there is no moment with a lock and no holder; `ln -s` fails when it exists. It is stale when
# its pid is gone or that pid's start time (ps -o lstart=, as a ticket's pid-start) differs (a reused pid); a directory
# lock an older ViD left is stale once no live pid is in it and it is older than 30 s. A stale lock is reclaimed as a
# stale slot is: moved aside, checked to be the one judged, removed.
admit_mine() { _s=$(ps -o lstart= -p "$$" 2>/dev/null | sed 's/^ *//; s/ *$//'); printf '%s %s' "$$" "$_s" | sed 's/ $//'; }
admit_stale() { # $1=the lock → exit 0 when stale; prints what was judged (the link's text, or the directory's pid)
  if [ -L "$1" ]; then
    _at=$(readlink "$1" 2>/dev/null) || return 1
    _ap=${_at%% *}; _as=''; case "$_at" in *' '*) _as=${_at#* } ;; esac
    printf '%s\n' "$_at"
    case "$_ap" in ''|*[!0-9]*) return 0 ;; esac
    pid_alive "$_ap" || return 0
    if [ -n "$_as" ]; then _now=$(ps -o lstart= -p "$_ap" 2>/dev/null | sed 's/^ *//; s/ *$//'); [ -z "$_now" ] || [ "$_now" = "$_as" ] || return 0; fi
    return 1
  elif [ -d "$1" ]; then
    _ap=$(cat "$1/pid" 2>/dev/null || true); printf 'dir %s\n' "$_ap"
    if [ -n "$_ap" ] && pid_alive "$_ap"; then return 1; fi
    _am=$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0)
    [ $(( $(date +%s) - _am )) -gt 30 ] && return 0
    return 1
  fi
  return 1
}
admit_lock() {
  _al="$HOSTD/admit.lock"; _ai=0; _mine=$(admit_mine)
  # `ln -s` onto an existing directory makes the link inside it and succeeds: the lock is ours only when nothing was
  # there and the link at the lock's path names us; a link made inside an older ViD's directory lock is removed
  while ! { [ ! -e "$_al" ] && [ ! -L "$_al" ] && ln -s "$_mine" "$_al" 2>/dev/null && [ -L "$_al" ] && [ "$(readlink "$_al" 2>/dev/null)" = "$_mine" ]; }; do
    if [ -d "$_al" ] && [ ! -L "$_al" ]; then rm -f "$_al/$_mine" 2>/dev/null || true; fi
    if _aj=$(admit_stale "$_al"); then
      _ax="$HOSTD/admit.stale.$$"
      if mv "$_al" "$_ax" 2>/dev/null; then
        # the one judged, or one taken meanwhile: put back what is not ours to remove
        if [ -L "$_ax" ]; then _ak=$(readlink "$_ax" 2>/dev/null); else _ak="dir $(cat "$_ax/pid" 2>/dev/null || true)"; fi
        if [ "$_ak" = "$_aj" ]; then rm -rf "$_ax"; else [ -e "$_al" ] || [ -L "$_al" ] || mv "$_ax" "$_al" 2>/dev/null || true; fi
      fi
      continue
    fi
    _ai=$((_ai + 1)); [ "$_ai" -lt 30 ] || return 1; sleep 1
  done
  ADMIT=$_al
}
admit_unlock() { [ -n "$ADMIT" ] && rm -rf "$ADMIT"; ADMIT=''; }
# mb: Docker's sizes (123.4MiB, 1.2GiB, 512KiB, 0B …) → whole MB, summed over stdin (checks/testenv.sh's)
mb() { awk '{ v = $0; n = v + 0; u = v; sub(/^[0-9.]+/, "", u)
  if (u ~ /^Gi?B/) n = n * 1024; else if (u ~ /^Ki?B/ || u ~ /^kB/) n = n / 1024; else if (u == "B") n = n / 1048576
  s += n } END { printf "%d\n", s }'; }
mem_ok() {
  MEMWAIT=''
  _em=$(sed -n 's/^env-mb=\([0-9][0-9]*\).*/\1/p' "$BUDGET" 2>/dev/null | head -n 1)
  [ -n "$_em" ] && [ "$_em" -gt 0 ] && [ -n "$DOCKER" ] || return 0
  _held=0; for _s in "$HOSTD"/stack.*; do [ -d "$_s" ] && _held=$((_held + 1)); done
  [ "$_held" -gt 0 ] || return 0
  _hr=$(sed -n 's/^memory-headroom-mb=\([0-9][0-9]*\).*/\1/p' "$BUDGET" 2>/dev/null | head -n 1); _hr=${_hr:-2048}
  _tot=$($DOCKER info --format '{{.MemTotal}}' 2>/dev/null | awk '{ printf "%d\n", $1 / 1048576 }')
  [ -n "$_tot" ] && [ "$_tot" -gt 0 ] || return 0
  _oth=0
  for _l in $($DOCKER ps --format '{{.ID}}	{{.Label "com.docker.compose.project"}}' 2>/dev/null | awk -F'\t' '$2 !~ /^vid-s[0-9]+-/ { print $1 }'); do
    _m=$($DOCKER stats --no-stream --format '{{.MemUsage}}' "$_l" 2>/dev/null | awk -F' / ' '{ print $1 }' | mb); _oth=$((_oth + ${_m:-0}))
  done
  _est=$((_tot - _oth - _em * _held)); _need=$((_em + _hr))
  [ "$_est" -ge "$_need" ] && return 0
  MEMWAIT="waiting for memory: estimate $_est MB, needed $_need MB (Docker $_tot MB, other projects $_oth MB, $_held slot(s) held × env-mb $_em)"
  return 1
}
take_slot() {
  if [ "$GATED" = yes ] && [ -n "$PROVE" ]; then
    _n=0
    for _s in "$HOSTD"/stack.*; do
      [ -f "$_s/holder" ] || continue
      [ "$(sed -n 5p "$_s/holder")" = "prove=$PROVE" ] || continue
      pid_alive "$(sed -n 1p "$_s/holder")" && _n=$((_n + 1))
    done
    [ "$_n" -lt 2 ] || return 1
  fi
  MEMWAIT=''
  k=1; while [ "$k" -le "$LIMIT" ] && [ -d "$HOSTD/stack.$k" ]; do k=$((k + 1)); done
  [ "$k" -le "$LIMIT" ] || return 1   # every slot held: no admission to make
  admit_lock || return 1
  mem_ok || { admit_unlock; return 1; }
  k=1
  while [ "$k" -le "$LIMIT" ]; do
    if mkdir "$HOSTD/stack.$k" 2>/dev/null; then LEASE="$HOSTD/stack.$k"; K=$k; printf '%s\n' "$$" > "$LEASE/holder"; admit_unlock; return 0; fi
    k=$((k + 1))
  done
  admit_unlock; return 1
}
# slot_read <slot dir>: its holder's pid, repository, compose project and start → LP LR LC LT
slot_read() {
  LP=$(sed -n '1p' "$1/holder" 2>/dev/null || true); LR=$(sed -n '2p' "$1/holder" 2>/dev/null || true)
  LC=$(sed -n '3p' "$1/holder" 2>/dev/null || true); LT=$(sed -n '4p' "$1/holder" 2>/dev/null || true)
}
# v0.9.7.0.8 (T2.2): a stale slot is freed only when Docker answers and no container, running or stopped,
# carries its holder's compose project label. VID_DOCKER overrides the docker command; with VID_COMPOSE
# set and no VID_DOCKER (a selftest's stub), Docker is taken as not answering — the slot is kept.
DOCKER=${VID_DOCKER:-}; [ -n "$DOCKER" ] || [ -n "${VID_COMPOSE:-}" ] || DOCKER=docker
# slot_why: after slot_read of a slot whose holder pid is gone — nothing when it may be freed, else why it is kept
slot_why() {
  case "$LP" in ''|*[!0-9]*) echo 'its holder file is unreadable'; return 0 ;; esac
  case "$LT" in ''|*[!0-9]*) echo 'its holder file is unreadable'; return 0 ;; esac
  _pn=$(printf '%s' "$LC" | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C tr -cd 'a-z0-9_-' | sed 's/^[-_]*//')   # as Compose names it
  [ -n "$_pn" ] || { echo 'its holder file is unreadable'; return 0; }
  [ -n "$DOCKER" ] || { echo 'Docker does not answer'; return 0; }
  _ct=$($DOCKER ps -a -q --filter "label=com.docker.compose.project=$_pn" 2>/dev/null) || { echo 'Docker does not answer'; return 0; }
  [ -z "$_ct" ] || echo "$(printf '%s\n' "$_ct" | grep -c .) container(s) of compose project $_pn are left"
}
# reclaim_stale: frees each stale slot it may — moved aside (one waiter wins the move), checked to be the
# holder judged (else put back: it was retaken meanwhile), removed, one slot-reclaimed event; 0 when one was freed
reclaim_stale() {
  _fr=1
  for _sl in "$HOSTD"/stack.*; do
    [ -d "$_sl" ] || continue
    slot_read "$_sl"
    { [ -n "$LP" ] && pid_alive "$LP"; } && continue
    [ -z "$(slot_why)" ] || continue
    _as="$HOSTD/reclaim.${_sl##*.}.$$"
    mv "$_sl" "$_as" 2>/dev/null || continue
    _mp=$(sed -n 1p "$_as/holder" 2>/dev/null || true); _mt=$(sed -n 4p "$_as/holder" 2>/dev/null || true)
    if [ "$_mp" != "$LP" ] || [ "$_mt" != "$LT" ]; then [ -e "$_sl" ] || mv "$_as" "$_sl" 2>/dev/null || true; continue; fi
    rm -rf "$_as"
    printf 'slot-reclaimed slot=%s project=%s holder-pid=%s age=%s at=%s\n' "${_sl##*.}" "$LC" "$LP" "$(( $(date +%s) - LT ))" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    echo "ViD test: reclaimed ${_sl##*/} — its holder pid $LP is gone and no container of compose project $LC is left ($(( $(date +%s) - LT )) s old)." >&2
    _fr=0
  done
  return "$_fr"
}
# holders: one line per held slot on the host — live, or STALE with its age and why it is kept (the refusal's lines; v0.9.7.0.8 T2.1)
holders() {
  for sl in "$HOSTD"/stack.*; do
    [ -d "$sl" ] || continue
    slot_read "$sl"
    if [ -n "$LP" ] && pid_alive "$LP"; then
      echo "    ${sl##*/}: held by pid $LP — repository $LR, compose project $LC, for $(( $(date +%s) - ${LT:-0} )) s"
    else
      _w=$(slot_why)
      echo "    ${sl##*/}: STALE — pid ${LP:-unknown} is gone (repository ${LR:-unknown}, compose project ${LC:-unknown}), $(( $(date +%s) - ${LT:-0} )) s old$(grep -q '^teardown-failed' "$sl/holder" 2>/dev/null && echo ', its teardown failed'). Kept: ${_w:-being freed} — inspect that project's containers, stop them, then remove $sl yourself."
    fi
  done
}

EXPORT=''
INTERRUPTED=0
DOWNA=''; DOWNP=''; TDFAIL=no; CLEANED=no; PLOCK=''; UPPID=''; RAN_TO_END=yes
dc() { # every Compose call: the frozen copy's files inside the gate
  if [ "$GATED" = yes ]; then $COMPOSE --project-directory "$CTXD" -f "$CF" -f "$RUN/override.yml" "$@"
  else $COMPOSE -f docker-compose.test.yml "$@"; fi
}
# teardown: the `down` of the pass in progress (v0.9.6 3.10), then none is
teardown() {
  [ -n "$DOWNA" ] || return 0
  _a=$DOWNA; _pr=$DOWNP; DOWNA=''; DOWNP=''
  if [ "$_pr" = deployed ]; then set -- --profile deployed down; else set -- down; fi
  [ "$INTERRUPTED" -eq 1 ] && norestart   # v0.26.10.3 (R11): before the logs below, whichever path got here
  if [ "$GATED" = yes ]; then
    svc_states "${_pr:-inline}"   # v0.9.7.0.11 (3.4, R4): the pass's container states, before its down — the signal path too
    [ "$INTERRUPTED" -eq 1 ] && tl_stop "${_pr:-inline}"   # v0.9.8.1 (R44): a stopped pass's logs, before its down
    _t0=$(date +%s)
    # shellcheck disable=SC2086
    if dc "$@" $_a >/dev/null 2>&1; then   # v0.9.7.0.10 (3.1): each teardown recorded on its own
      printf 'teardown seconds=%s report=%s at=%s\n' "$(( $(date +%s) - _t0 ))" "${TDREP:-none}" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    else TDFAIL=yes; fi
  else
    # shellcheck disable=SC2086
    dc "$@" $_a >/dev/null 2>&1 || true
  fi
}
# proj_left: how many containers the run's compose project still has (Docker only), or exit 1 when Docker cannot say
proj_left() { _o=$($DOCKER ps -a -q --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" 2>/dev/null) || return 1; printf '%s\n' "$_o" | grep -c . || true; }
# up_stop: v0.9.7.0.12 (3.9, R9) — the signal path while a pass's Compose call runs: TERM to it and its children, reaped
# within VID_UP_REAP (60) s, then the down; with Docker, the project's containers confirmed gone (else 10 s, the down again)
# norestart: v0.9.8.1 (R45, F-37) — a stop is final: no restart policy applies to the project's containers, so none (the
# tests container's above all) starts again before the down (Docker only). v0.26.10.3 (R11): every interrupted teardown
# path runs it before it collects logs — a cancel or TERM during a deployed run's first `up -d` included
norestart() {
  [ -n "$DOCKER" ] && [ -n "${COMPOSE_PROJECT_NAME:-}" ] || return 0
  _ids=$($DOCKER ps -a -q --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" 2>/dev/null || true)
  # shellcheck disable=SC2086
  [ -z "$_ids" ] || $DOCKER update --restart=no $_ids >/dev/null 2>&1 || true
}
up_stop() {
  _da=$DOWNA; _dp=$DOWNP; _kids=$(pgrep -P "$UPPID" 2>/dev/null || true)
  norestart   # before the TERM
  # shellcheck disable=SC2086
  kill -TERM $_kids 2>/dev/null || true; kill -TERM "$UPPID" 2>/dev/null || true
  _live() { for _p in "$UPPID" $_kids; do kill -0 "$_p" 2>/dev/null && return 0; done; return 1; }
  _w=0; while _live && [ "$_w" -lt "${VID_UP_REAP:-60}" ]; do sleep 1; _w=$((_w + 1)); done
  if _live; then TDFAIL=yes; echo "ViD test: the pass's Compose call (pid $UPPID) is still running ${VID_UP_REAP:-60} s after TERM." >&2
  else wait "$UPPID" 2>/dev/null || true; fi
  UPPID=''
  teardown
  [ -n "$DOCKER" ] && [ -n "${COMPOSE_PROJECT_NAME:-}" ] || return 0
  if ! _n=$(proj_left); then TDFAIL=yes; echo "ViD test: Docker did not say whether compose project $COMPOSE_PROJECT_NAME has containers left." >&2; return 0; fi
  [ "$_n" -eq 0 ] && return 0
  sleep 10; DOWNA=$_da; DOWNP=$_dp; teardown
  if ! _n=$(proj_left) || [ "$_n" -gt 0 ]; then TDFAIL=yes; echo "ViD test: compose project $COMPOSE_PROJECT_NAME still has ${_n:-unknown} container(s) after two downs." >&2; fi
  return 0
}
cleanup() {
  [ "$CLEANED" = no ] || return 0
  CLEANED=yes
  [ -n "$PLOCK" ] && rmdir "$PLOCK" 2>/dev/null
  admit_unlock
  [ -z "${SWPID:-}" ] || svc_stop   # v0.9.7.0.11 (3.3): the stack watcher, reaped before the teardown
  if [ "$INTERRUPTED" -eq 1 ] && [ -n "$UPPID" ] && [ "$GATED" = yes ]; then up_stop; else teardown; fi
  # v0.9.7.0.1 (3.3, R7): a pass's Compose call still running ends before anything is released
  if [ -n "$UPPID" ]; then
    _w=0; while kill -0 "$UPPID" 2>/dev/null && [ "$_w" -lt 30 ]; do sleep 1; _w=$((_w + 1)); done
    if kill -0 "$UPPID" 2>/dev/null; then
      TDFAIL=yes; echo "ViD test: the pass's Compose call (pid $UPPID) is still running 30 s after its down." >&2
    else wait "$UPPID" 2>/dev/null || true; fi
    UPPID=''
  fi
  [ -n "$EXPORT" ] && rm -rf "$EXPORT"
  if [ "$GATED" = yes ]; then
    if [ "$TDFAIL" = yes ]; then
      _u=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
      [ -n "$LEASE" ] && printf 'teardown-failed %s\n' "$_u" >> "$LEASE/holder"
      [ -n "$RUN" ] && printf 'teardown-failed %s\n' "$_u" >> "$RUN/holder"
      echo "ViD test: teardown FAILED — compose project ${COMPOSE_PROJECT_NAME:-?} may still be up; slot ${K:-?} and $RUN are kept. Inspect the project's containers, bring them down, then remove both." >&2
      _rqt=-; [ -z "$TD" ] || _rqt=$VID_REQUEST   # v0.9.7.0.10 (3.1, R4): the failed teardown, at the run's home
      printf 'teardown-failed request=%s project=%s at=%s\n' "$_rqt" "${COMPOSE_PROJECT_NAME:-?}" "$_u" >> "$EV"
    else
      [ -n "$LEASE" ] && rm -rf "$LEASE"
      [ -n "$RUN" ] && rm -rf "$RUN"
      [ -n "$TD" ] && [ -n "$RUN" ] && [ ! -d "$RUN" ] && rm -f "$TD/run"   # v0.9.8.1 (R45): `run` never names a removed folder
    fi
  else
    [ -n "$LEASE" ] && rm -rf "$LEASE"
    rm -rf "$LOCK"
  fi
  return 0
}
# v0.9.7.0.2 (3.1, R9): a request stopped at its cap — the event, written after teardown: report=none capped=yes
# (v0.9.7.0.11 3.3, R3: or <mark>, stopped=service:<name> for a service's death; v0.26.10.4 R4: a run its watcher
# stopped, capped=yes stop=silent|startup|limit)
rq_capev() {
  _k=${KIND:-}; [ -n "$_k" ] || { _k=full; [ -n "$SEL" ] && _k=scoped; [ "$SELCLOSE" = yes ] && _k=$ROLE; }
  _x=''; [ "$GATED" = yes ] && _x=" tree=${TREE:-} run=$RUNID"; [ "$TDFAIL" = yes ] && _x="$_x teardown=failed"
  printf 'ledger-run seconds=%s kind=%s report=none status=130 role=%s%s%s %s%s at=%s\n' "$(( $(date +%s) - $(cat "$TD/running-at" 2>/dev/null || date +%s) ))" "$_k" "${ROLE:--}" "$_x" "$RQF" "${1:-capped=yes}" "$RQW" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
}
on_signal() { INTERRUPTED=1; rm -f "$PENDING"
  [ -n "${WERR:-}" ] && { cat "$WERR" >&2 2>/dev/null; rm -f "$WERR"; WERR=''; }   # v0.9.7.3 (R9): the Compose child's lines so far
  _sv=''; [ -n "$RUN" ] && [ -s "$RUN/stopped" ] && _sv=$(cat "$RUN/stopped")   # v0.9.7.0.11 (3.3, R3): latched before the signal
  [ -n "$_sv" ] && [ -n "$TD" ] && rq_put "$TD/stopped" "$_sv"
  cleanup
  if [ -n "$TD" ] && [ -f "$TD/cap-hit" ]; then rq_capev "capped=yes stop=$(rq_kv reason "$TD/cap-hit")"; echo "ViD test: $(rq_stopline "$TD") — no later pass, no receipt." >&2
  elif [ -n "$TD" ] && [ -f "$TD/cancel" ] && [ -f "$TD/running-at" ]; then rq_capev 'cancelled=yes'; echo 'ViD test: cancelled — no later pass, no receipt.' >&2
  elif [ -n "$TD" ] && [ -n "$_sv" ]; then rq_capev "stopped=service:$(printf '%s\n' "$_sv" | sed -n 's/^stopped: service \([^ ]*\) .*/\1/p')"; echo "ViD test: $_sv — no later pass, no receipt." >&2; fi
  echo 'ViD test: interrupted — no report written (a receipt names a run that completed).' >&2; exit 130; }
trap cleanup EXIT
trap on_signal INT TERM HUP

# chunk_yield: yes (0) when a request at the home other than this batch's waits and the batch's chunks already hold
# LIMIT − 1 slots (a chunk's state is running once it holds one); sets MEMWAIT to say so
chunk_yield() {
  _bh=${TD%/.vid/requests/*}; _bt=$_bh/.vid/requests/${TD#"$_bh"/.vid/requests/}; _bt=${_bt%%/chunks/*}
  [ "$LIMIT" -ge 2 ] || return 1
  _q=''
  for _s in "$_bh"/.vid/requests/*/state "$_bh"/.vid/requests/*/chunks/*/state; do
    [ -f "$_s" ] && [ "$(cat "$_s" 2>/dev/null)" = queued ] || continue
    _d=${_s%/state}; case "$_d" in "$_bt"|"$_bt"/*) continue ;; esac
    grep -q '^batch=yes$' "$_d/request" 2>/dev/null && continue
    _q=${_d#"$_bh"/.vid/requests/}; break
  done
  [ -n "$_q" ] || return 1
  _n=0; for _s in "$_bt"/chunks/*/state; do [ "$(cat "$_s" 2>/dev/null)" = running ] && _n=$((_n + 1)); done
  [ "$_n" -ge $((LIMIT - 1)) ] || return 1
  MEMWAIT="giving way: request $_q waits and this batch holds $_n of $LIMIT slot(s)"; return 0
}
# dirty_refuse <porcelain lines>: the export-backed run's refusal of a worktree with uncommitted changes
dirty_refuse() {
  echo 'ViD test: refused — the worktree carries uncommitted changes; commit first: a receipt names a tree.' >&2
  printf '%s\n' "$1" | head -n 5 | sed 's/^/    /' >&2
  echo 'A scoped run (sh checks/test.sh -- <selector>) uses the live tree and is never certifiable.' >&2
  exit 1
}
W0=$(date +%s); DW0=''
while :; do
  [ -n "$TD" ] && [ -f "$TD/cancel" ] && { kill -TERM $$; sleep 1; }   # v0.9.7.1 (3.6, R6): cancelled while queued — the signal path, nothing held
  # v0.9.7.0.11 (3.6, R6): an export-backed request waits out a dirty worktree before it takes a slot — each round,
  # up to VID_DIRTY_WAIT (600) s from the first dirty sight, then refused as before; HEAD's tree at serve still runs
  if [ -n "$TD" ] && [ "$CHUNK" = no ] && { [ -z "$SEL" ] || [ "$SELCLOSE" = yes ]; }; then
    _dy=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null || true)
    if [ -n "$_dy" ]; then
      [ -n "$DW0" ] || DW0=$(date +%s)
      [ $(( $(date +%s) - DW0 )) -lt "${VID_DIRTY_WAIT:-600}" ] || dirty_refuse "$_dy"
      { echo "    waiting for a clean worktree: $(printf '%s\n' "$_dy" | head -n 5 | cut -c4- | paste -sd ',' - | sed 's/,/, /g') — $(( $(date +%s) - DW0 )) s of ${VID_DIRTY_WAIT:-600} s"; } > "$TD/holders.tmp" && mv "$TD/holders.tmp" "$TD/holders"
      sleep 2 & wait $! || true
      continue
    fi
    DW0=''
  fi
  # v0.9.7.0.12 (3.2, R2; found in rehearsal R-1): a chunk launched before another request came gives way at the slot —
  # while a request at the home waits and its batch already holds stacks − 1 slots, it takes none
  if [ "$CHUNK" = yes ] && chunk_yield; then :; else
    take_slot && break
    reclaim_stale && continue   # v0.9.7.0.8 (T2.2): a stale slot freed when safe — try again at once
  fi
  # v0.9.7.0.8 (T2.1): a request says why it waits — the holders as of this try, in its ticket folder
  if [ -n "$TD" ]; then { holders; [ -z "$MEMWAIT" ] || echo "    $MEMWAIT"; } > "$TD/holders.tmp" && mv "$TD/holders.tmp" "$TD/holders"; fi
  if [ -n "$WAIT" ] && [ $(( $(date +%s) - W0 )) -lt "$WAIT" ]; then
    _left=$(( WAIT - ($(date +%s) - W0) )); [ "$_left" -gt 10 ] && _left=10
    sleep "$_left" & wait $! || true
    continue
  fi
  if [ -n "$PROVE" ] && [ "$GATED" = yes ] && [ "$LIMIT" -eq 2 ]; then
    echo "ViD test: refused — the environment proof $PROVE holds its two slots, or every slot it may take is held:" >&2
  else
    echo "ViD test: refused — the host budget allows $LIMIT test stack(s) at once and every slot is held (.vid/budget stacks=$STACKS; the recorded incident was three stacks on one machine)$([ -n "$MEMWAIT" ] && echo ", or the memory is short — $MEMWAIT"):" >&2
  fi
  holders >&2
  exit 1
done
WAITED=$(( $(date +%s) - W0 ))
if [ -n "$TD" ]; then date +%s > "$TD/running-at"; printf 'running\n' > "$TD/state.tmp.$$" && mv "$TD/state.tmp.$$" "$TD/state"; fi
# v0.9.7.1 (3.6, R6): a cancel that landed before `running` — read now, after the trap is set and the state written
if [ -n "$TD" ] && [ -f "$TD/cancel" ]; then kill -TERM $$; sleep 1; fi
if [ "$GATED" = yes ]; then
  # v0.9.7.0.8 (T1): one `-` for each run of other characters, no `-` at either end, at most 40, never empty —
  # a valid image name and compose project by construction
  SAN=$(basename "$PWD" | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//' | cut -c1-40 | sed 's/-$//')
  [ -n "$SAN" ] || SAN=project
  COMPOSE_PROJECT_NAME="vid-s$K-$SAN"; export COMPOSE_PROJECT_NAME
  IMG="vid-s$K-$SAN:run"
  printf '%s\n%s\n%s\n%s\n' "$$" "$PWD" "$COMPOSE_PROJECT_NAME" "$(date +%s)" > "$LEASE/holder"
  [ -n "$PROVE" ] && printf 'prove=%s\n' "$PROVE" >> "$LEASE/holder"
  printf 'slot=%s\nproject=%s\n' "$K" "$COMPOSE_PROJECT_NAME" >> "$RUN/holder"
else
  printf '%s\n%s\n%s\n%s\n' "$$" "$PWD" "${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}" "$(date +%s)" > "$LEASE/holder"
fi

# --- what runs: an export of HEAD, or the live tree -----------------------------
HEAD=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)   # v0.9.7.0.11 (3.6, R6): HEAD at serve, after any wait
# v0.9.8 (R15): a proof's scoped receipt is named .proof. where an ordinary one is .live. — the one mark every reader
# skips (checks/evidence.sh ordinary); the name is never an ordinary one's, so no copy or alias is ever overwritten
LV=live; [ "$PURPOSE" = proof ] && LV=proof
if [ "$CHUNK" = yes ]; then   # v0.9.7.0.12 (3.2, R2): the batch's tree and the commit it was frozen at, whatever HEAD is now
  KIND=close; HEAD=$BBASE; TREE=$BTREE; NAME="$HEAD.run-$RUNID.$KIND.xml"
  [ -f "$BEXP/docker-compose.test.yml" ] || { echo "ViD test: refused — the batch's export $BEXP is gone or holds no docker-compose.test.yml — failing closed." >&2; exit 1; }
elif [ -z "$SEL" ] || [ "$SELCLOSE" = yes ]; then
  KIND=full; [ "$SELCLOSE" = yes ] && KIND=$ROLE
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo 'ViD test: refused — no commit to export; a full run is export-backed (commit first: a receipt names a tree). Before the initial commit, run the whole ledger through the live path with the everything-selector: sh checks/test.sh -- <selector>.' >&2
    exit 1
  fi
  DIRTY=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null || true)
  [ -z "$DIRTY" ] || dirty_refuse "$DIRTY"
  if [ "$GATED" = yes ]; then
    TREE=$(git rev-parse 'HEAD^{tree}')
    NAME="$HEAD.run-$RUNID.$KIND.xml"
  else
    EXPORT=$(mktemp -d "$PWD/.vid/export.XXXXXX")
    git archive --format=tar HEAD | tar -xf - -C "$EXPORT"
    VID_TEST_CONTEXT=$EXPORT
    NAME="$HEAD.full.xml"
  fi
else
  KIND=scoped
  VID_TEST_CONTEXT=.
  HASH=$(printf '%s' "$SEL" | cksum | cut -d' ' -f1)
  DHASH=$(printf '%s' "$DSELX" | cksum | cut -d' ' -f1)   # R6: the deployed pass's receipt is named by its own selection
  NAME="$HEAD.$LV.sel-$HASH.xml"
  if [ "$GATED" = yes ]; then
    # v0.9.6 (3.7.1): the working tree as it is, frozen through a temporary index
    NAME="$HEAD.$LV.sel-$HASH.run-$RUNID.xml"
    # .vid/ stays out: named as an exclusion only when it is not ignored (git refuses to name an ignored path)
    _xv=':(exclude).vid'; git check-ignore -q .vid 2>/dev/null && _xv=.
    { GIT_INDEX_FILE="$RUN/index" git read-tree HEAD 2>/dev/null || GIT_INDEX_FILE="$RUN/index" git read-tree --empty; } \
      && GIT_INDEX_FILE="$RUN/index" git add -A -- . "$_xv" \
      && TREE=$(GIT_INDEX_FILE="$RUN/index" git write-tree) \
      || { echo 'ViD test: refused — the working tree could not be frozen (temporary index).' >&2; exit 1; }
  fi
fi
if [ "$GATED" = yes ]; then
  FROZEN_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  if [ "$CHUNK" = yes ]; then CTXD=$BEXP   # one export per batch, read in place by every chunk
  else CTXD="$RUN/ctx"; mkdir -p "$CTXD"; git archive --format=tar "$TREE" | tar -xf - -C "$CTXD"; fi
  printf 'tree=%s\n' "$TREE" >> "$RUN/holder"
  VID_TEST_CONTEXT=$CTXD
  CF="$CTXD/docker-compose.test.yml"
  [ -f "$CF" ] || { echo 'ViD test: docker-compose.test.yml missing from the frozen tree — failing closed.' >&2; exit 1; }
else
  CF=docker-compose.test.yml
fi
export VID_TEST_CONTEXT
VID_SELECTOR=$SEL; export VID_SELECTOR

# --- the harness contract ----------------------------------------------------------
hkey() { awk -v k="$1:" '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1==k { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' "$CF"; }
COMPLETED=$(hkey completed | tr '[],' '   ' | tr -s ' ' | sed 's/^ //;s/ $//')
# v0.9.7.0.11 (3.2, R2): harness rule 4 — the per-case limit, handed to the tests service, which hands it to its runner
VID_CASE_LIMIT=$(hkey case-limit); if [ -n "$VID_CASE_LIMIT" ]; then export VID_CASE_LIMIT; else unset VID_CASE_LIMIT; fi
DSEL=$(hkey deployed-selector)
PROFSVCS=$(awk '
  /^services:/ { ins=1; next } ins && /^[^ ]/ { ins=0 }
  ins && /^  [A-Za-z0-9_.-]+:/ { name=$1; sub(/:$/,"",name); inprof=0; next }
  ins && name != "" && /^    profiles:/ { v=$0; sub(/^[^:]*:/,"",v); if (v ~ /deployed/) p[name]=1; inprof=1; next }
  ins && name != "" && inprof && /^      - / { if ($0 ~ /deployed/) p[name]=1; next }
  ins && name != "" && /^    [a-z]/ { inprof=0 }
  END { for (s in p) print s }' "$CF" | sort | tr '\n' ' ' | sed 's/ $//')
if [ "$DEPLOYED" = yes ] && [ -z "$DSEL" ]; then
  echo 'ViD test: refused — --deployed needs the harness contract to declare deployed-selector: and the deployed profile (docker-compose.test.yml x-vid-harness); this product declares no process beside the web process.' >&2
  exit 1
fi
if [ "$BOTH" = yes ] && [ -z "$DSEL" ]; then
  echo 'ViD test: refused — --deployed-selection was given, but the harness contract declares no deployed-selector: (docker-compose.test.yml x-vid-harness); this run is one inline pass.' >&2
  exit 2
fi
if [ "$SELCLOSE" = yes ]; then
  if [ "$CHUNK" = no ] && [ -n "$DSEL" ] && { [ "$HAVEDSX" = no ] || [ -z "$DSELX" ]; }; then
    echo "ViD test: refused — the harness contract declares deployed-selector:, so a $ROLE names its deployed-shape selection too: --deployed-selection <selection> (the runner's syntax; ViD never builds one)." >&2
    exit 2
  fi
  if [ -z "$DSEL" ] && [ "$HAVEDSX" = yes ]; then
    echo "ViD test: refused — --deployed-selection was given, but the harness contract declares no deployed-selector: (docker-compose.test.yml x-vid-harness); a $ROLE here is one inline pass." >&2
    exit 2
  fi
fi
if [ -z "$COMPLETED" ]; then
  echo "ViD test: note — docker-compose.test.yml's x-vid-harness declares no completed: statuses; a partial report after a runner interrupt cannot be told from a complete one (v0.9.3 3.3). Add the runner's ran-to-the-end statuses." >&2
fi

# --- v0.9.6 (3.7.3, 3.7.8): the run's override ---------------------------------------
if [ "$GATED" = yes ]; then
  SVCS=$(awk '/^services:/ { ins=1; next } ins && /^[^ ]/ { ins=0 } ins && /^  [A-Za-z0-9_.-]+:/ { n=$1; sub(/:$/,"",n); print n }' "$CF")
  PSVC=$(hkey product); [ -n "$PSVC" ] || PSVC=product
  PROCS=" $PSVC $(hkey processes | tr '[],' '   ') "
  write_override() { # $1=yes|no: the ports and container_name resets
    {
      echo '# the run override (checks/test.sh, v0.9.6 3.7.3) — deleted with the run folder'
      echo 'services:'
      for _s in $SVCS; do
        echo "  $_s:"
        case "$PROCS" in *" $_s "*) echo "    image: $IMG" ;; esac
        if [ "$_s" = tests ]; then echo '    volumes:'; echo "      - \"$RUN/results:/vid-results\""; fi
        if [ "$1" = yes ]; then echo '    ports: !reset []'; echo '    container_name: !reset null'; fi
      done
    } > "$RUN/override.yml"
  }
  write_override yes
  if ! dc config >/dev/null 2>&1; then
    write_override no
    if dc config >/dev/null 2>&1; then
      echo 'ViD test: note — this Compose refuses the !reset tag, so the run keeps the fixed host ports and container names of docker-compose.test.yml; everything else is the run'"'"'s own. Slots above 1 are refused until Compose is updated.' >&2
      if [ "$K" -gt 1 ]; then
        echo "ViD test: refused — slot $K: without the resets two environments would collide on ports and names." >&2
        exit 1
      fi
    else
      write_override yes
    fi
  fi
fi
# outside <shape>: v0.9.7.0.2 (3.3, R7), v0.9.7.0.11 (3.1, R1) — before a request's report is published: the rows its cases
# reach (checks/evidence.sh reach --raw, the evidence join) outside the request's frozen rows are added to the ticket's
# `outside` and said; the report is published and kept all the same, and credits only its frozen rows (its `.rows`). Never
# withholds: always 1. Full: no frozen rows, never outside.
OUTN=0
outside() {
  OUTN=0
  [ -n "$TD" ] && [ -f "$TD/rows" ] && [ "$(sed -n 's/^type=//p' "$TD/request")" != full ] || return 1
  [ -f checks/evidence.sh ] && [ -f checks/extractors/results.sh ] || return 1
  sh checks/extractors/results.sh "$PENDING" 2>/dev/null | grep -E '^case ' > "$PENDING.cases" || true
  sh checks/evidence.sh reach "$PENDING" --shape "$1" --raw 2>/dev/null | cut -f2 | sort -u | grep -vxF -f "$TD/rows" > "$TD/outside.new" || true
  rm -f "$PENDING.cases"
  if [ -s "$TD/outside.new" ]; then
    OUTN=$(grep -c . "$TD/outside.new"); cat "$TD/outside.new" >> "$TD/outside"
    echo "ViD test: the run reached $OUTN row(s) outside the request ($(head -n 10 "$TD/outside.new" | paste -sd ',' -)): kept, not credited." >&2
  fi
  rm -f "$TD/outside.new"
  return 1
}
ROLEF=" role=${ROLE:--}"   # v0.9.7.0.1 (3.2, R5): an ungated roleless run is recorded role=-
[ "$GATED" = no ] && [ -z "${VID_REQUEST:-}" ] && ROLEF="$ROLEF form=legacy"   # v0.9.7.0.2 (3.4, R5): a plain call outside a run
FINAL=0

# publish <name> <kind> <status> <seconds> [<copy name>] [<shape>]: renamed only when the run ran to its end
publish() {
  RAN_TO_END=yes; WHY=''
  if [ -n "$COMPLETED" ]; then
    case " $COMPLETED " in *" $3 "*) ;; *) RAN_TO_END=no; WHY="compose exit $3 is outside the harness contract's completed: [$COMPLETED] — the run did not run to its end" ;; esac
  fi
  XF=''; OVH=''
  if [ "$GATED" = yes ]; then
    XF=" tree=$TREE run=$RUNID"; [ "$WAITED" -gt 0 ] && XF="$XF waited=$WAITED"; [ "$TDFAIL" = yes ] && XF="$XF teardown=failed"
  fi
  XF="$XF$RQF"
  if [ "$INTERRUPTED" -eq 0 ] && [ "$RAN_TO_END" = yes ] && [ -f "$PENDING" ]; then
    outside "${6:-inline}" || true; [ "$OUTN" -gt 0 ] && XF="$XF outside=$OUTN"
    # v0.9.7.0.11 (3.1, R1): the request's frozen rows ride the report — written before it is published (full: none)
    rm -f "$RDIR/$1.rows"
    if [ -n "$TD" ] && [ -f "$TD/rows" ] && [ "$(sed -n 's/^type=//p' "$TD/request")" != full ]; then cp "$TD/rows" "$RDIR/.$1.rows.$$" && mv "$RDIR/.$1.rows.$$" "$RDIR/$1.rows"; fi
    mv "$PENDING" "$RDIR/$1"; TDREP=$1
    if [ "$GATED" = yes ]; then
      printf 'tree=%s\nbase=%s\nfrozen-at=%s\nshape=%s\n' "$TREE" "$HEAD" "$FROZEN_AT" "${6:-inline}" > "$RDIR/$1.tree"
      [ "$PURPOSE" = proof ] && echo 'purpose=proof' >> "$RDIR/$1.tree"   # v0.9.8 (R15)
      if [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh "$RDIR/$1" 2>/dev/null | grep -E '^case ' > "$RDIR/$1.cases" || true; else : > "$RDIR/$1.cases"; fi
      # v0.9.7.0.10 (3.2, R5): the pass's overhead — its seconds minus its cases' seconds, never below 0
      OVH=$(awk -v s="$4" '$1 == "case" { c += $4 } END { d = s - c; if (d < 0) d = 0; printf "%d\n", d + 0.5 }' "$RDIR/$1.cases")
      XF="$XF overhead=$OVH"
      # the commit-named copy and the event in one step, so the copy is the newest event's
      _pl=0; while ! mkdir "$RDIR/.publish.lock" 2>/dev/null && [ "$_pl" -lt 20 ]; do sleep 1; _pl=$((_pl + 1)); done; PLOCK="$RDIR/.publish.lock"
      if [ -n "${5:-}" ]; then   # the copy carries the report's .rows, or none
        if [ -f "$RDIR/$1.rows" ]; then cp "$RDIR/$1.rows" "$RDIR/.$5.rows.$$" && mv "$RDIR/.$5.rows.$$" "$RDIR/$5.rows"; else rm -f "$RDIR/$5.rows"; fi
        cp "$RDIR/$1" "$RDIR/.$5.tmp.$$" && mv "$RDIR/.$5.tmp.$$" "$RDIR/$5"
      fi
    fi
    echo "ViD test: report $RDIR/$1 ($2 run, tree $HEAD, exit $3)"
    printf 'ledger-run seconds=%s kind=%s report=%s status=%s%s%s%s at=%s\n' "$4" "$2" "$1" "$3" "$ROLEF" "$XF" "$RQW" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    [ -n "$PLOCK" ] && { rmdir "$PLOCK" 2>/dev/null || true; PLOCK=''; }
    if [ -n "$TD" ]; then printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$RAN_TO_END" "$(cd "$RDIR" && pwd)" >> "$TD/passes"; fi
  else
    rm -f "$PENDING"
    if [ "$RAN_TO_END" = no ]; then
      echo "ViD test: no report — $WHY; whatever the runner wrote is discarded (a receipt names a run that completed)." >&2
    else
      echo "ViD test: no report — the runner did not write one (exit $3); nothing is green that did not run." >&2
    fi
    printf 'ledger-run seconds=%s kind=%s report=none status=%s%s%s%s at=%s\n' "$4" "$2" "$3" "$ROLEF" "$XF" "$RQW" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EV"
    if [ -n "$TD" ]; then printf 'none\t%s\t%s\t%s\t-\n' "$2" "$3" "$RAN_TO_END" >> "$TD/passes"; fi
  fi
  [ "$FINAL" -ne 0 ] || FINAL=$3
}
# --- v0.9.7.0.11 (3.3, 3.4, 3.7; R3, R4, R7): the stack watched, its states and its timeline kept ------------------
# svc_inspect <format>: one `docker inspect` line per container of this run's compose project (Docker only: stack-neutral)
svc_inspect() {
  _ids=$($DOCKER ps -a -q --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" 2>/dev/null) || return 1
  [ -n "$_ids" ] || return 0
  # shellcheck disable=SC2086
  $DOCKER inspect --format "$1" $_ids 2>/dev/null
}
# svc_watch <pass>: every SVCPOLL s from the pass's bring-up (v0.26.10.4 R1: the deployed pass's too, before its `up -d`)
# — each service's last log line to the ticket's svcout.<pass> (`<service><TAB><line>`; a changed line is the service's
# new output, read by the run's watcher); and, while the tests container runs, a container of another service that
# exited non-zero or was killed for memory, finished after the tests started, stops the run through the watcher's stop
# path — the cause first
svc_watch() {
  _wf='{{index .Config.Labels "com.docker.compose.service"}}|{{.State.Status}}|{{.State.ExitCode}}|{{.State.OOMKilled}}|{{.State.StartedAt}}|{{.State.FinishedAt}}|{{.Name}}'
  while :; do
    sleep "$SVCPOLL"
    svc_inspect "$_wf" > "$RUN/svc.now" 2>/dev/null || continue
    awk -F'|' 'NF >= 7 && $1 != "" { n = $7; sub(/^\//, "", n); print $1 "\t" n }' "$RUN/svc.now" | while IFS="$TX" read -r _sn _cn; do
      printf '%s\t%s\n' "$_sn" "$($DOCKER logs --timestamps --tail 1 "$_cn" 2>&1 | tail -n 1 | cut -c1-300)"; done > "$TD/svcout.$1.tmp" 2>/dev/null && mv "$TD/svcout.$1.tmp" "$TD/svcout.$1"
    _t0=$(awk -F'|' '$1 == "tests" && $2 == "running" { print substr($5, 1, 19); exit }' "$RUN/svc.now")
    [ -n "$_t0" ] || continue   # armed only while the tests container runs
    # v0.26.10.4 (R1): the moment this pass's tests are first seen running — its start-up ends; the watcher judges its
    # output by the tests service alone from then (v0.9.8.1 R40's tests-at, now one per pass)
    [ -f "$TD/tests-at.$1" ] || { date +%s > "$TD/tests-at.$1.tmp" && mv "$TD/tests-at.$1.tmp" "$TD/tests-at.$1"; }
    _d=$(awk -F'|' -v t0="$_t0" '$1 != "tests" && ($2 == "exited" || $2 == "dead") && ($3 != 0 || $4 == "true") && substr($6, 1, 19) >= t0 {
        print $1 "|" ($4 == "true" ? "killed for memory" : "exited code " $3) "|" substr($6, 1, 19) "Z"; exit }' "$RUN/svc.now")
    [ -n "$_d" ] || continue
    printf '%s\n' "$_d" | awk -F'|' -v p="$1" '{ print "stopped: service " $1 " " $2 " at " $3 " — see services." p ".txt" }' > "$RUN/stopped.tmp" && mv "$RUN/stopped.tmp" "$RUN/stopped"
    kill -TERM $$ 2>/dev/null
    exit 0
  done
}
SWPID=''
# svc_start <pass>: the services watcher, with an empty svcout.<pass> at once — a watched pass, whose start-up the
# run's watcher may bound (v0.26.10.4 R2)
svc_start() { [ "$GATED" = yes ] && [ -n "$TD" ] && [ -n "$DOCKER" ] || return 0; : > "$TD/svcout.$1"; svc_watch "$1" & SWPID=$!; }
svc_stop() { [ -n "$SWPID" ] || return 0; kill "$SWPID" 2>/dev/null || true; wait "$SWPID" 2>/dev/null || true; SWPID=''; }
# svc_states <pass>: the ticket's services.<pass>.txt — name, state, exit, memory kill, health, restarts, started-at,
# kept-healthy-at (v0.9.8 R17, was ready-at: the first passing check Docker still kept in its rolling health log when
# ViD read it — not when the service became ready; else -), finished-at
svc_states() {
  [ -n "$TD" ] && [ -n "$DOCKER" ] || return 0
  _sf='{{.Name}}|{{.State.Status}}|{{.State.ExitCode}}|{{.State.OOMKilled}}|{{if .State.Health}}{{.State.Health.Status}}{{else}}-{{end}}|{{.RestartCount}}|{{.State.StartedAt}}|{{.State.FinishedAt}}|{{if .State.Health}}{{range .State.Health.Log}}{{if eq .ExitCode 0}}{{json .End}} {{end}}{{end}}{{end}}'
  { echo '# name state exit memory-kill health restarts started-at kept-healthy-at finished-at'
    svc_inspect "$_sf" | awk -F'|' 'NF >= 8 { n = $1; sub(/^\//, "", n); r = $9; sub(/^ +/, "", r); sub(/ .*/, "", r); gsub(/"/, "", r); if (r == "") r = "-"; f = $8; if (f ~ /^0001-/) f = "-"
      print n " state=" $2 " exit=" $3 " memory-kill=" ($4 == "true" ? "yes" : "no") " health=" $5 " restarts=" $6 " started-at=" $7 " kept-healthy-at=" r " finished-at=" f }'
  } > "$TD/services.$1.txt" 2>/dev/null || true
}
# tl_save <pass> [--profile deployed]: the ticket's timeline.<pass>.log — the stack's own lines with their times, the
# last 20000 and at most 20 MB, best-effort, at most 60 s; after the pass's result, before its down
# v0.9.8.1 (R27, F-16): a pass that is red or ran short of its end (status not 0, or not run to its end) keeps its
# whole timeline instead — `logs --timestamps` with no tail, compressed, timeline.<pass>.log.gz — capped at 100 MB
# compressed (VID_TIMELINE_CAP bytes), keeping the end when cut, the cut said on its first line and on standard error;
# still best-effort, its time bound scaled to the pass's length (a tenth of it, 60 s to 1800 s)
tl_save() {
  [ "$GATED" = yes ] && [ -n "$TD" ] || return 0
  if [ "${STATUS:-0}" -ne 0 ] || [ "${RAN_TO_END:-yes}" = no ]; then tl_whole "$@"; return 0; fi
  _tf="$TD/timeline.$1.log"; shift
  # shellcheck disable=SC2086
  $COMPOSE --project-directory "$CTXD" -f "$CF" -f "$RUN/override.yml" "$@" logs --timestamps --tail 20000 > "$_tf.tmp" 2>&1 &
  _lp=$!; _lw=0
  while kill -0 "$_lp" 2>/dev/null && [ "$_lw" -lt 60 ]; do sleep 1; _lw=$((_lw + 1)); done
  kill "$_lp" 2>/dev/null || true; wait "$_lp" 2>/dev/null || true
  tail -c 20000000 "$_tf.tmp" > "$_tf" 2>/dev/null || true; rm -f "$_tf.tmp"
}
# tl_stop <pass>: v0.9.8.1 (R44, F-36) — on the signal path (a cap, a cancel, a service's death, a TERM), before the
# pass's down: its whole timeline (tl_whole, as a pass short of its end) and each service's last 200 lines,
# last-lines.<pass>.log, best-effort, at most 60 s — kept in the ticket folder, which outlives the run folder
tl_stop() {
  [ "$GATED" = yes ] && [ -n "$TD" ] || return 0
  [ -f "$TD/last-lines.$1.log" ] && return 0   # once a pass: up_stop's second down finds the stack gone
  if [ "$1" = deployed ]; then set -- deployed --profile deployed; fi
  RAN_TO_END=no; tl_whole "$@"
  _tf="$TD/last-lines.$1.log"; shift
  # shellcheck disable=SC2086
  $COMPOSE --project-directory "$CTXD" -f "$CF" -f "$RUN/override.yml" "$@" logs --timestamps --tail 200 > "$_tf.tmp" 2>&1 &
  _lp=$!; _lw=0
  while kill -0 "$_lp" 2>/dev/null && [ "$_lw" -lt 60 ]; do sleep 1; _lw=$((_lw + 1)); done
  kill "$_lp" 2>/dev/null || true; wait "$_lp" 2>/dev/null || true
  mv "$_tf.tmp" "$_tf" 2>/dev/null || true
}
tl_whole() {
  _tf="$TD/timeline.$1.log.gz"; shift
  _tb=$(( ($(date +%s) - ${START:-$(date +%s)}) / 10 )); [ "$_tb" -lt 60 ] && _tb=60; [ "$_tb" -gt 1800 ] && _tb=1800
  # shellcheck disable=SC2086
  $COMPOSE --project-directory "$CTXD" -f "$CF" -f "$RUN/override.yml" "$@" logs --timestamps > "$_tf.raw" 2>&1 &
  _lp=$!; _lw=0
  while kill -0 "$_lp" 2>/dev/null && [ "$_lw" -lt "$_tb" ]; do sleep 1; _lw=$((_lw + 1)); done
  kill "$_lp" 2>/dev/null || true; wait "$_lp" 2>/dev/null || true
  _cap=${VID_TIMELINE_CAP:-104857600}
  gzip -c "$_tf.raw" > "$_tf.tmp" 2>/dev/null || { rm -f "$_tf.raw" "$_tf.tmp"; return 0; }
  _gz=$(wc -c < "$_tf.tmp" | tr -d ' ')
  if [ "$_gz" -gt "$_cap" ]; then   # keep the end: the share of the raw lines the cap holds, less a margin, then said
    _rw=$(wc -c < "$_tf.raw" | tr -d ' '); _keep=$(awk -v r="$_rw" -v g="$_gz" -v c="$_cap" 'BEGIN { printf "%d\n", r * c / g * 0.9 }')
    { echo "ViD test: timeline cut — its first $((_rw - _keep)) of $_rw bytes dropped to keep the compressed file under $_cap bytes; the end is kept"
      tail -c "$_keep" "$_tf.raw"; } | gzip -c > "$_tf.tmp" 2>/dev/null || true
    echo "ViD test: the timeline of this red pass was cut to its last $_keep bytes ($(basename "$_tf"))" >&2
  fi
  mv "$_tf.tmp" "$_tf" 2>/dev/null || true; rm -f "$_tf.raw"
}
# waited <command…>: a pass's foreground Compose call, run as a waited child so the wrapper's own
# signal acts during the pass (v0.9.7.0.1 3.3, R7) — on_signal brings it down through teardown
# v0.9.7.3 (R9): with WERR set, only the Compose child's standard error goes to that file (the wrapper's own lines,
# a signal's included, stay on its standard error)
WERR=''
waited() { if [ -n "$WERR" ]; then "$@" 2> "$WERR" & else "$@" & fi; UPPID=$!; _ws=0; wait "$UPPID" || _ws=$?; UPPID=''; return "$_ws"; }
# stopped: the pass just run did not run to its end, or the wrapper was signalled — or, inside the gate, its
# teardown failed (v0.9.7.0.10 3.1, R3: the later pass would not start on a fresh stack) — no later pass; said
# once, and a request's result is written then
STOPPED=no
stopped() {
  [ "$STOPPED" = no ] || return 0
  [ "$RAN_TO_END" = no ] || [ "$INTERRUPTED" -eq 1 ] || [ "$TDFAIL" = yes ] || return 1
  STOPPED=yes
  if [ "$RAN_TO_END" = no ] || [ "$INTERRUPTED" -eq 1 ]; then echo 'ViD test: the inline pass did not run to its end — no later pass starts.' >&2
  else echo "ViD test: teardown FAILED between the passes — no later pass starts: its stack would not be fresh (compose project ${COMPOSE_PROJECT_NAME:-?})." >&2; fi
  [ "$FINAL" -ne 0 ] || FINAL=1
  rq_early
  return 0
}
# rq_early: v0.9.7.0.10 (3.1, R1) — a gated request's last pass is published: its exit, result and final state
# now, before the final teardown (once; outside the gate, or with no ticket, `serve` writes them after the run)
EARLY=no
rq_early() { [ "$GATED" = yes ] && [ -n "$TD" ] && [ "$EARLY" = no ] || return 0; EARLY=yes; rq_final "$TD" "$FINAL"; }
# v0.9.7.3 (3.9, R9): a failed image build — the pass's Compose call exited non-zero, no runner wrote a report, and
# Compose's own output names a failed build — ends the request like a pass that did not run to its end: no later
# pass and no receipt; the result says `build failed: no test ran — <the build's last error line>`.
# build_failed <status> <Compose's captured standard error>
build_failed() {
  [ "$1" -ne 0 ] && [ ! -f "$PENDING" ] || return 1
  grep -qiE 'failed to solve|failed to build|failed to compute cache key|error building' "$2" 2>/dev/null || return 1
  _bl=$(grep -iE 'error|failed' "$2" | tail -n 1 | sed 's/^[[:space:]]*//' | cut -c1-300)
  echo "ViD test: build failed: no test ran — $_bl" >&2
  [ -n "$TD" ] && printf 'build failed: no test ran — %s\n' "$_bl" > "$TD/build-failed"
  return 0
}
# inline_pass <name> <kind> <down-args> [<copy name>] [more]: `more` when a deployed pass may follow
inline_pass() {
  rm -f "$PENDING"; TDREP=none
  START=$(date +%s); STATUS=0
  DOWNA=$3; DOWNP=''
  [ -z "$TD" ] || rq_put "$TD/pass" inline   # v0.26.10.4 (R1): the pass the run's watcher judges
  svc_start inline
  # v0.9.7.3 (R9): Compose's standard error, kept to read a failed build, then passed on; v0.26.10.4 (R1): a request's
  # in its ticket folder, compose.inline.err, so the run's watcher sees it grow during the start-up
  if [ -n "$TD" ]; then WERR="$TD/compose.inline.err"; : > "$WERR"; else WERR=$(mktemp); fi
  waited dc up --build --exit-code-from tests tests || STATUS=$?
  cat "$WERR" >&2 2>/dev/null || true
  BUILDFAIL=no; build_failed "$STATUS" "$WERR" && BUILDFAIL=yes; rm -f "$WERR"; WERR=
  svc_stop   # v0.9.7.0.11 (3.3): reaped before publish and teardown
  if [ "$GATED" = yes ]; then   # v0.9.7.0.10 (3.1): publish, then tear down
    publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))" "${4:-}" inline
    [ "$BUILDFAIL" = no ] || RAN_TO_END=no
    if [ "${5:-}" = more ]; then stopped || true; else rq_early; fi
    tl_save inline   # v0.9.7.0.11 (3.7, R7): every pass's timeline, after its result, before its down
    teardown
  else
    teardown
    publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))" "${4:-}" inline
    [ "$BUILDFAIL" = no ] || RAN_TO_END=no
  fi
}
# v0.9.7.0.10 (3.8, R15): a deployed-only request has no inline pass to build the tests' image — it builds it here, from its frozen checkout
deployed_up() { VID_INLINE=0; VID_SCHEDULE_FAST=1; export VID_INLINE VID_SCHEDULE_FAST
  if { [ "$DEPLOYED" = yes ] && [ -n "$TD" ]; } || { [ "$CHUNK" = yes ] && [ -z "$SEL" ]; }; then dc --profile deployed up --build --exit-code-from tests tests; else dc --profile deployed up --exit-code-from tests tests; fi; }
# deployed_pass <name> <kind> <selector> [<copy name>]: a fresh stack in the profile, nothing inline
deployed_pass() {
  rm -f "$PENDING"; TDREP=none
  START=$(date +%s); STATUS=0
  VID_SELECTOR=$3; export VID_SELECTOR
  DOWNA='--remove-orphans --volumes'; DOWNP=deployed
  [ -z "$TD" ] || rq_put "$TD/pass" deployed   # v0.26.10.4 (R1): the pass the run's watcher judges
  svc_start deployed   # v0.26.10.4 (R1): from the bring-up, not after `up -d` returns
  # shellcheck disable=SC2086
  if ( VID_INLINE=0; VID_SCHEDULE_FAST=1; export VID_INLINE VID_SCHEDULE_FAST; dc --profile deployed up -d --build product $PROFSVCS ); then
    waited deployed_up || STATUS=$?
  else
    STATUS=$?; echo "ViD test: the deployed shape did not come up (product and $PROFSVCS) — no deployed report." >&2
  fi
  svc_stop
  if [ "$GATED" = yes ]; then   # v0.9.7.0.10 (3.1): publish, the result, then tear down
    publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))" "${4:-}" deployed
    rq_early
    tl_save deployed --profile deployed
    teardown
  else
    teardown
    publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))" "${4:-}" deployed
  fi
}

# --- the run --------------------------------------------------------------------
if [ "$CHUNK" = yes ]; then   # v0.9.7.0.12 (3.2, 3.6; R2, R6): a chunk's passes, its own receipts only (no copies)
  if [ -n "$SEL" ] && [ -n "$DSELX" ]; then
    inline_pass "$NAME" close '--remove-orphans --volumes' '' more
    stopped || deployed_pass "$HEAD.run-$RUNID.close.deployed.xml" deployed "$DSELX" ''
  elif [ -n "$SEL" ]; then inline_pass "$NAME" close '--remove-orphans' ''
  else deployed_pass "$HEAD.run-$RUNID.close.deployed.xml" deployed "$DSELX" ''; fi
elif [ "$GATED" = yes ]; then
  if [ "$SELCLOSE" = yes ] && [ -n "$DSEL" ]; then
    inline_pass "$NAME" "$KIND" '--remove-orphans --volumes' "$HEAD.$KIND.xml" more
    stopped || deployed_pass "$HEAD.run-$RUNID.$KIND.deployed.xml" deployed "$DSELX" "$HEAD.$KIND.deployed.xml"
  elif [ "$SELCLOSE" = yes ]; then
    inline_pass "$NAME" "$KIND" '--remove-orphans' "$HEAD.$KIND.xml"
  elif [ "$KIND" = full ] && [ -n "$DSEL" ]; then
    inline_pass "$NAME" full '--remove-orphans --volumes' "$HEAD.full.xml" more
    stopped || deployed_pass "$HEAD.run-$RUNID.deployed.xml" deployed "$DSEL" "$HEAD.deployed.xml"
  elif [ "$DEPLOYED" = yes ]; then
    deployed_pass "$HEAD.$LV.deployed.sel-$HASH.run-$RUNID.xml" scoped "$SEL"
  elif [ "$BOTH" = yes ]; then   # v0.9.7.0.9 (R6): one slot, the inline pass, then unless stopped the deployed pass
    inline_pass "$NAME" scoped '--remove-orphans --volumes' '' more
    stopped || deployed_pass "$HEAD.$LV.deployed.sel-$DHASH.run-$RUNID.xml" scoped "$DSELX"
  elif [ "$KIND" = full ]; then
    inline_pass "$NAME" full '--remove-orphans' "$HEAD.full.xml"
  else
    inline_pass "$NAME" scoped '--remove-orphans'
  fi
elif [ "$KIND" = full ] && [ -n "$DSEL" ]; then
  inline_pass "$NAME" full '--remove-orphans --volumes'
  stopped || deployed_pass "$HEAD.deployed.xml" deployed "$DSEL"
elif [ "$DEPLOYED" = yes ]; then
  deployed_pass "$HEAD.$LV.deployed.sel-$HASH.xml" scoped "$SEL"
elif [ "$BOTH" = yes ]; then
  inline_pass "$NAME" scoped '--remove-orphans --volumes'
  stopped || deployed_pass "$HEAD.$LV.deployed.sel-$DHASH.xml" scoped "$DSELX"
else
  inline_pass "$NAME" "$KIND" '--remove-orphans'
fi
exit $FINAL
