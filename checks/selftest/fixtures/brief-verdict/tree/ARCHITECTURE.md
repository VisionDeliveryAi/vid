# Linkling — ARCHITECTURE

Import court: enforce

| Module | Responsibility | Owned tables/data | Public surface | Dependents |
|---|---|---|---|---|
| app | the link store: create, resolve, expire, delete | one file per link | `app/links.sh` — link_create, link_resolve, link_delete | tests/invariants |
