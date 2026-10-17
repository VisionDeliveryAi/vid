# JobDigest — ARCHITECTURE (the work package, v0.9.3 §7 case 15)

Import court: enforce

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core/ingest | the feed pull, parsing, the listing store, the search index | `core.ingest` | core/digest, app |
| 2 | core/digest | match selection, digest assembly, send | `core.digest` | app |
| 3 | core/mailer | the mail-provider client | `core.mailer` | core/digest |
| 4 | app | the HTTP surface: saved searches, confirmation, unsubscribe, search | `app` | none |

## External boundaries

- **Feed A** and **Feed B** (the two source feeds) — pulled by core/ingest. Credentials: never (public feeds). The product's one external INPUT boundary: what enters here is parsed, stored, indexed for search, and matched into digests.
- **Mail provider** (transactional mail) — reached from core/mailer. Credentials: not-yet (the owner holds no account yet).

## Processes, the queue and the schedule

The product ships two processes beside the web process: a **worker** that
consumes the one queue, `work` (parse, store and index a pulled feed item;
assemble and send a digest), and a **scheduler** with one schedule, the
**daily run** at 06:00, which pulls both feeds and then enqueues one digest
job per saved search on `work`.

## Test harness

The harness runs every asynchronous task inline inside the web process and
fires the daily run at once when a test asks; the two feeds are played by a
harness fake serving fixture feed files at the feed addresses; the mail
provider is played by a capture fake that records every message.
