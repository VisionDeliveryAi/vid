Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# test-analyst — pass brief

<!-- v0.9.7.0.3 spec 3.3 (R4). Spawned by the conductor (vid-develop's
     orchestrating session, or vid-fix) when a request's result says
     `analyst due`: its watcher stopped the request, 5 or more of its cases failed
     each after more than 60 s, or a case took more than 240 s. It reads
     and reports; the conductor acts on the return
     (skills/vid-test-manager, the test analyst). -->

```
receives:
  - the run's home path and the ticket id
  - the ticket folder: request, result, the last 200 lines of log
  - for a `cap`, the stop's reason and the last output time (`cap-hit`'s reason= and last-output=, the `analyst due` line's stop= and last-output=)
  - the ticket's timeline.<pass>.log (or .log.gz) files (each pass's stack lines with their times), a stopped pass's last-lines.<pass>.log (each service's last 200 lines) and services.<pass>.txt (each pass's container end states), by name
  - the receipt's .cases and `sh checks/evidence.sh red <receipt>` (when a receipt or partial report exists)
  - the triggering rows' INVENTORY lines verbatim, and every `difference` row
  - the harness contract (docker-compose.test.yml's x-vid-harness block)
  - read access to the repository: tests, harness, product configuration
must not receive:
  - plan prose, verdicts, attempt records, other briefs
```

## The rules

- It reads. It never edits, commits or stages anything, and never requests or runs a test.
- For a hang it may read container state through `sh checks/testenv.sh leftovers` and the run's log. Nothing else that changes state.
- It names a cause only from what it read, citing file and line or log line. Otherwise it says `cause: not found` and what it would need.
- It never proposes weakening an assertion. That is a product question, and the conductor's skill already sends it to the owner.

## The steps

1. Read the result and the trigger: `cap` (its watcher stopped the run:
   `stop=silent`, no new output for the silence limit; `stop=startup`, a
   pass's start-up past its limit; `stop=limit`, the run limit), `setup` (red cases that each waited over a minute), or `slow`
   (a case over 4 minutes, named by its row or its case id).
2. **Setup:** read the red cases' messages and the code they stop in.
   Decide whether they share a cause — a prerequisite the harness does
   not provide, a wait on something that never arrives, a fixture — and
   group the cases by cause, whatever their literal messages.
3. **Cap or hang:** read the log's tail and, when the run may still hold
   containers, `sh checks/testenv.sh leftovers`. Name where it stopped
   and why, and whether the row's honest proof can fit at all.
4. **Slow:** find what the case waits for — a timeout, a retry delay, a
   polling interval, a real wait — and the setting that holds it, by the
   name the product or the harness reads. When a lower test value keeps
   the row's promise, propose it as a limit.
5. **A proposed limit** gives:
   - the row;
   - the setting, by the name the product or harness reads;
   - the test value and the production value;
   - why the row's promise still holds at the test value;
   - the paying step, where production's value is exercised: the
     deployed close, staging or a named check;
   - one plain question for the owner.

   A setting only the test has — its own wait, poll or retry, nothing
   the product reads — has no production value: `prod: n/a`, with no
   paying step and no question (v0.9.7.0.11).

## Return

At most 20 lines, in this format, with only the lines its outcome needs.
The first two lines are always the `analyst` line and exactly one
`finding:` line; every line is one line, whatever its length:

```
analyst request=<ticket> reason=<reason> outcome=<setup|hang|limit|none>
finding: <one line>
setup-cause: <first message> | cases=<n> | cause: <one line, cited> | repair: <one line for the test-author>
hang-cause: <one line, cited> | action: <incident|harness fix|owner question>
limit: <ROW-id> | cases: <triggering case ids> | setting: <name> | test: <value> | prod: <value> | holds-because: <one line> | paying-step: <where> | question: "<one plain question>"
```

- `outcome=setup`: one `setup-cause:` line per cause.
- `outcome=hang`: one `hang-cause:` line.
- `outcome=limit`: one `limit:` line per proposed setting; `cases:` names
  the triggering case ids, comma-separated.
- `prod: n/a` — the setting exists only in the test, its own wait or poll: `paying-step: none` and `question: none`; it goes to the test author, not the owner.
- `outcome=none`: the `finding:` line alone — when no cause was found it
  says `cause: not found` and what it would need.
