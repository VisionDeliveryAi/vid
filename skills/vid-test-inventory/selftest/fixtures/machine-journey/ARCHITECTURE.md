# JobDigest — ARCHITECTURE

Import court: enforce

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core/ingest | feed polling, parsing, the listing store, the search index | `core.ingest` | core/digest |
| 2 | core/digest | match selection, digest assembly, send | `core.digest` | app |
| 3 | core/mailer | the mail-provider client | `core.mailer` | core/digest |
| 4 | app | HTTP surface | `app` | none |

## External boundaries

- **Feed A** and **Feed B** (the two source feeds) — pulled by core/ingest on a schedule every fifteen minutes. Credentials: never (public feeds). This is the product's one external INPUT boundary: what enters here is parsed, stored, indexed for search, and matched into digests.
- **Mail provider** (transactional mail) — reached from core/mailer. Credentials: held.

## Processes

The product ships three processes: the web process (the HTTP surface), a
**worker** that consumes the `ingest` queue (parse, store, index) and the
`digest` queue (match, assemble, send), and a **scheduler** that fires the
feed pull every fifteen minutes and the daily digest run.

## Test harness

The harness runs every asynchronous task inline inside the web process
(the product setting `TASKS_INLINE`), so no worker runs in the harness, and
it makes declared schedules fire at once (the setting `SCHEDULES_FAST`) so
a test need not wait fifteen minutes. The two feeds are played by a
harness fake serving fixture feed files at the feed addresses; the mail
provider is played by a capture fake that records every message.
