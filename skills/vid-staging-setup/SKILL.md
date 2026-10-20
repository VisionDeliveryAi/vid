---
name: vid-staging-setup
description: Internal — invoked by vid-init (Part 1, at its architecture step), by vid-deploy (Part 1 when the hosting block is missing; Part 2 from its staging target while no staging deploy has passed gate 2) and by vid-develop (Part 1 only, for the answers a setup stop named); not a verb, never run by the owner. Setting up the test site in one module — where the product runs and how ViD gets access, recorded by name only in ARCHITECTURE.md's vid-hosting block; then the build-out of staging and production from that block, stopping only for the owner's own hands.
user-invocable: false
---

# Setting up the test site (v0.26.10.8 R4)

Everything about setting staging up lives here and nowhere else; the
callers say only when to invoke it. It has two parts. It records no stage
event of its own, so its caller's stage and gate stay as they are.

**No credential, ever.** No password, token, key or secret value is
written in any file, commit, record, brief or log, and none is typed into
this conversation on your side. Access is recorded only by its shape. The
credential boundary is vid-deploy's, unchanged: the owner authenticates and
creates accounts; you operate through the already-authenticated CLI and
create variable NAMES.

## Part 1 — "Where it runs": the questions and their record

**Invoked** by vid-init at its architecture step, for every project; by
vid-deploy when ARCHITECTURE.md holds no `vid-hosting` block (a project
made by an older init); and by vid-develop at a setup stop for a missing
block, to ask only the answers the stop named.

**Ask, in one batch, in plain language:**
- the hosting platform and its region (a product question: where the users
  are and whose law applies);
- the staging and production web addresses, or the platform's own;
- when the product sends email, the sending address and its domain;
- the monthly spend cap;
- how ViD gets access, for the platform and, when the owner has one, the
  domain's DNS: the platform CLI's own log-in, done by the owner, or a
  token the owner keeps in an environment variable outside the repository,
  named by its variable. Say plainly: **"Never type a password or a token
  here — say which log-in, or the name of the variable that holds it."**;
- which outside services already have an account, and which go live on
  staging once built (`live-restricted`) or stay `fake`. Creating an
  account, accepting a provider's terms and adding payment details are the
  owner's own steps;
- the downtime tolerance for a release that changes the database — asked
  once per project, logged as a D-entry (default: brief maintenance-window
  migrations).

**An answer that holds a value** (anything that looks like a password, a
token or a key) is neither recorded nor cited. Ask again for the log-in or
the variable's name, and tell the owner in one line to treat the value as
exposed and replace it.

**Record** the answers in ARCHITECTURE.md as one fenced block, one `key:
value` line each — not a table, so the seam table's readers never see it:

````
```vid-hosting
platform: <name>
region: <region>
staging: <web address, or the platform's own>
production: <web address, or the platform's own>
sending: <address and domain, or none>
spend-cap: <amount a month>
access: cli-login <platform> | env <NAME> | none
dns-access: cli-login <platform> | env <NAME> | none
owner-only: <each step left to the owner's hands, named; or none>
providers: <each outside service: live-restricted | fake on staging>
```
````

- `access:` and `dns-access:` take only `cli-login <platform>` (the word
  equal to `platform:`), `env <NAME>` (NAME matching `[A-Z_][A-Z0-9_]*`)
  or `none`; the pre-commit hook refuses any other shape
  (`by=hosting-access`).
- These answers go only into the block and into DECISIONS, never verbatim
  into BASELINE's Owner hints.
- A later answer updates its key in place, in a commit citing the owner's
  answer (its A-NNN).

**Check the platform against BASELINE** here, from the platform's docs:
database version, Docker or buildpack support, workers, cron, pricing
against the cap. The verdict is a DECISIONS entry naming the rejected
alternatives. If the platform cannot run the stack, that is a product
tradeoff: put it to the owner by the two-channel rule.

## Part 2 — "Build the test site": from the block

**Invoked only** by vid-deploy's staging target, while no staging deploy
has passed gate 2 (no `deploy-gate gate=2 … result=pass` in the events),
whoever started the deploy — the owner, or develop with `--by develop`.
Gate 2 stays vid-deploy's.

- **Under the owner's deploy** ask only for what the block lacks (Part 1's
  questions for those keys).
- **Under `--by develop`** ask nothing: anything missing is a stop that
  names it.
- **Run again after a stop,** build only what isn't there yet.

In order:
1. **The log-in.** Check `access:` — `cli-login <platform>`: the
   platform CLI's own whoami; `env <NAME>`: that the variable is set (never
   print it). Not logged in, or the variable unset, is a stop naming the
   log-in command or the variable.
2. **Both environments,** staging and production, versions pinned from
   BASELINE, never the platform's defaults; the database and its
   migrations; the staging seed, synthetic.
3. **Every outside service ARCHITECTURE.md names,** not only those going
   live now: its variables by NAME, and its row in DEPLOYMENT.md's provider
   state table. A service whose code isn't built yet stays `fake`. Each
   account the owner hasn't created is an owner-only step, named.
4. **The sending domain.** When `dns-access` allows, publish the records
   the email provider asks for; otherwise each record, named, is an
   owner-only step. DEPLOYMENT.md records the domain as verified, with how,
   or as open, with what is missing.
5. **DEPLOYMENT.md,** from `${CLAUDE_PLUGIN_ROOT}/templates/DEPLOYMENT.md`,
   with no placeholder left, committed (the template's message).

**Hand back** one of:
- `built` — everything above is there; the caller runs gate 2 on staging
  (deploying the candidate, the smoke, the seams paid);
- `stopped: <what>` — what the owner's hands must do (a log-in, an account,
  terms, payment details, a value), what is missing from the block, or the
  platform being down, each named. The owner-only steps still open are
  named either way.

Platform-shaped fixes the build-out needs (configuration, the build
file, a migration's settings) are committed on HEAD; under the setup hold
the staging candidate is HEAD, so they reach staging through the same
deploy. A product correction is a `/vid fix`, as vid-deploy says.
