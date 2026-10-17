# Linkling — CLAUDE.md (the ViD law file)

Linkling shortens web links: a person pastes a long address and gets a
short code that redirects to it for thirty days. The product is small on
purpose; its promises are about trust — a short link never points anywhere
the person did not paste.

This project runs under ViD (VisionDelivery.ai): the spec (PRD.md) binds what
gets built; the ledger (tests/invariants/) binds what stays built. Everything
in this file is law, not advice.

## Reading order (every session, before any work)

1. **PRD.md** — base first, then `## Appends`. Later appends win over the base
   and over earlier appends.
2. **BASELINE.md** — stack, named FORBIDDEN alternatives, Tier-0 rows, test environment.
3. **ARCHITECTURE.md** — the seam table: who owns what. Executed, not
   descriptive — it is the import court's rule source.
4. **DECISIONS.md** — choices already made. Do not re-litigate them.
5. **INVENTORY.md** — the ratified Test Inventory: every row is an obligation
   the ledger verifies; the inventory court reads it at every commit.

## Placement rules

```vid-placement
app
tests
```

## Ledger and docs laws

- tests/invariants/ is the ledger: tests keyed to REQ IDs in their names, behavior-keyed through public surfaces only — never implementation-keyed.
- Invariant tests exercise behavior, never text: a ledger test must not read application source files as strings.
- Fixture law: ledger-test fixtures create their state through the same public paths production uses — never hand-set state.
- The ledger runs ONLY via `sh checks/test.sh`. It must be green at every commit.
- A row's test is evidence only after it has been seen to fail: rows carry `proved-red: <commit-sha>`.
- The builder never writes a ledger test: a file under tests/invariants/ is created only by a test-author pass.
- A seam change is a law change: ARCHITECTURE.md changes in its own standalone commit.
- A placement change is a law change: the vid-placement block changes in its own standalone commit.

## Two-channel question rule

- Product questions — behavior, domain semantics, policy, priorities — go to the owner at once, in plain language, with a recommendation where the evidence supports one.
- Technical questions are decided, logged in DECISIONS.md, and never asked.

## Verdict-pass doctrine (develop, per slice)

At slice close, after the ledger runs green, one fresh grader verdicts every row the slice claims paid against its ratified Fail-if: KEPT / BREACHED. Rows are ratified law, so BREACHED is "not done", not a finding needing adjudication.
