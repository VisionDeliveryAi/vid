# JobDigest — ARCHITECTURE

Import court: enforce

| # | Module | Owns | Public surface | Dependents |
|---|--------|------|----------------|------------|
| 1 | core/ingest | feed polling, listing store | `core.ingest` | core/digest |
| 2 | core/digest | match selection, digest assembly, send | `core.digest` | app |
| 3 | core/mailer | the mail-provider client, suppression sync | `core.mailer` | core/digest |
| 4 | app | HTTP surface | `app` | none |

## External boundaries

- **Mail provider** (transactional mail, suppression list, contact store) — reached from core/mailer. Credentials: not-yet.
- **Feed A** and **Feed B** (the two source feeds) — reached from core/ingest. Credentials: never (public feeds).
