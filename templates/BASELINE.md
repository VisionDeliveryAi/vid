# {{PROJECT_NAME}} — BASELINE

One page: what the stack IS, what it is NOT, and the rows that must never break.

## Stack

| Layer | Choice | FORBIDDEN alternatives (named) |
|---|---|---|
| {{LAYER}} | {{CHOICE}} | {{FORBIDDEN_NAMED}} |

## Module seams & data ownership

The seam table lives in ARCHITECTURE.md. Ownership law: each table/data store
is written by exactly one module; everyone else goes through that module's
public surface.

## Tier-0 rows

<!-- typical rows: append-only tables (no UPDATE/DELETE on X), no prod
     credentials anywhere in repo or test env, all outbound calls through one
     egress module -->

| Rule | Meaning |
|---|---|
| {{T0_RULE}} | {{T0_MEANING}} |

## Test environment

The ledger runs ONLY inside Docker: `sh checks/test.sh` → docker compose -f
docker-compose.test.yml. No test process ever receives real credentials.

## Owner hints (verbatim)

- Design: {{DESIGN_HINTS_OR_none_given}}
- Architecture/stack: {{ARCH_HINTS_OR_none_given}}

## Machine blocks

Parsed by checks/conformance.sh at every commit. Extensions space- or
newline-separated. Forbidden terms one per line: dependency/import names that
must never appear in staged source additions — pick tokens that will not
legitimately occur in code or config otherwise.

```vid-allowed-extensions
{{ALLOWED_EXTENSIONS}}
```

```vid-forbidden
{{FORBIDDEN_TERMS}}
```
