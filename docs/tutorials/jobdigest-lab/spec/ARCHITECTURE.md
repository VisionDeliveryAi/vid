# JobDigest — ARCHITECTURE

| Module | Responsibility | Owned tables/data | Public surface | Dependents |
|---|---|---|---|---|
| web | the pages | none | the pages | none |
| ingest | reading the feeds | listings | the listings | digest |
| digest | the morning digest | saved searches | the digest run | none |
| mail | sending mail | none | send | digest |
| search | synonym-aware search | synonyms | search | digest |

```vid-hosting
platform: one small hosting platform, named at the first deploy
staging: the platform's own address
production: the platform's own address
```
