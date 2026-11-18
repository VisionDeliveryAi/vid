#!/bin/sh
# Purpose: selftest fixture — the pages' toy project (usability, B1 to B11). Sourced by the pages-* cases.
# `pg_toy <dir>` makes JobDigest's ViD repository there and enters it: PRD.md (a copy of prd-094-good.md), BASELINE.md,
# ARCHITECTURE.md (a seam table, the hosting block, the code block) and DECISIONS.md (three decisions, D-002 a ViD
# proposal), all committed; .vid/ with a metrics-events line and a plan folder holding one file. `pg_snap` prints a sum
# of every file of the project but .git, .vid/pages/ and .vid/pagelinks, one line a file, for a before-and-after.
pg_toy() {
  mkdir -p "$1"; cd "$1"; git init -q; git config user.email t@example.invalid; git config user.name t
  cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
  cat > BASELINE.md <<'MD'
# JobDigest — BASELINE

## Stack

| Layer | Choice | Forbidden alternatives |
|---|---|---|
| web | a server-rendered app | a single-page framework |

## Owner hints (verbatim)

"It's a website."

## Machine blocks

```vid-allowed-extensions
.md .sh .yml
```

```vid-forbidden
sqlalchemy
```
MD
  cat > ARCHITECTURE.md <<'MD'
# JobDigest — ARCHITECTURE

Import court: enforce
<!-- an annotation for the import court -->

## Modules

| Module | Responsibility | Owned tables/data | Public surface | Dependents |
|---|---|---|---|---|
| app/digest | the daily digest | digests | `app/digest` — send | none |

## Where it runs

```vid-hosting
platform: a hosting platform
region: eu
staging: the platform's own
production: jobs.example.invalid
access: env HOST_TOKEN
```
MD
  cat > DECISIONS.md <<'MD'
# JobDigest — DECISIONS

Append-only, except labels. One line per decision.

## Log

- **D-001** one digest per saved search | why: the owner's answer A-001 | enforced: convention | applies-to: REQ-001
- **D-002** a server-rendered web app | why: the owner gave no hint past "a website" | enforced: convention | scope: project | origin: proposal
- **D-003** the listing store is backed up daily | why: REQ-010 | enforced: convention | applies-to: REQ-010
MD
  mkdir -p .vid/plan; printf 'court name=prd seconds=1 at=2026-11-15T00:00:00Z\n' > .vid/metrics-events; printf 'step S01\n' > .vid/plan/PLAN.md
  git add PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md; git commit -qm toy
}
# usability (B5, B6, B14, B15): `pg_full <dir>` makes the planner's toy there (fixtures/planner-toy.sh: an INVENTORY.md
# with an entry of every kind, a grading checklist, STAGES.md with stage 0 and two stages and their cards), adds the
# pages' toy's BASELINE.md and DECISIONS.md, makes ROW-012's owed reason one with no class, appends six strength
# findings to PRD.md (F-10 open, F-11 repaired, F-12 repaired about ROW-099, which the list no longer holds, F-13 open
# about ROW-098, gone too, with no evidence, F-14 overruled, F-15 noted about a requirement, not an entry of the list),
# commits it all, and enters it. `pg_rungs <dir>` makes three rungs' scratch
# copies there as the stage skill makes them (PRD.md, INVENTORY.md, checks/ and STAGES.md): `three` (the toy's cut),
# `merged` (stage 1 holds every feature, no cards) and `single` (no STAGES.md).
pg_full() {
  _pd=$(pwd); mkdir -p "$1.t"; ( pg_toy "$1.t" ) > /dev/null; cd "$_pd"
  . "$CHECKS/selftest/fixtures/planner-toy.sh"; pt_toy "$1" > /dev/null 2>&1
  cp "$1.t/BASELINE.md" "$1.t/DECISIONS.md" .; rm -rf "$1.t"
  sed 's/| owed: fixture-source — a 10,000-job snapshot from the first feed partner, expected with the partner'"'"'s sandbox |/| owed: waiting on the partner |/' INVENTORY.md > I.x && mv I.x INVENTORY.md
  cat >> PRD.md <<'MD'

### 2026-08-31 (the strength check)

```vid-prd-findings
F-10 | strength | blocking | INVENTORY.md:ROW-007 | | evidence: a page that opens the unsubscribe form but never stops the digests still passes
F-11 | strength | advisory | INVENTORY.md:ROW-019 | repaired | evidence: a footer whose support address bounces still passes
F-12 | strength | advisory | INVENTORY.md:ROW-099 | repaired | evidence: ROW-099 repeated ROW-016 word for word and was dropped
F-13 | strength | blocking | INVENTORY.md:ROW-098 | |
F-14 | strength | advisory | INVENTORY.md:ROW-001 | overruled A-001 | evidence: a digest built once a week still passes
F-15 | strength | advisory | REQ-001 | noted | evidence: the rule is wider than the test of it
```
MD
  git init -q; git config user.email t@example.invalid; git config user.name t; git add -A; git commit -qm toy
}
pg_rungs() {
  for r in three merged single; do mkdir -p "$1/$r"; cp PRD.md INVENTORY.md "$1/$r/"; cp -R "$CHECKS" "$1/$r/checks"; done
  cp STAGES.md "$1/three/"
  printf '# JobDigest — STAGES\n\n## The cut\n\n```vid-stages\nSTAGE-1 | Everything at once | features: FEAT-01 FEAT-02 FEAT-03\n```\n' > "$1/merged/STAGES.md"
}
# usability (B12): `pg_design` writes a design brief (a manifest of two screens, three states) and an amendment
# record (two rulings) in the current directory, each fence with words after it and a comment line inside, which
# design-join.sh reads past.
pg_design() {
  printf '# JobDigest — DESIGN BRIEF\ngrammar: 0.9.2\n\n## The manifest\n\n```vid-design-manifest (one row a surface and state)\n# screen | state | requirements | pins\nS01 | default | REQ-001 | pins: search field present; email field present\nS01 | saved | REQ-001 | pins: the saved search shown; Check your inbox to confirm\nS02 | active | REQ-002 | pins: the search shows as active\n```\n' > DESIGN-BRIEF.md
  printf '# JobDigest — design amendment brief (2026-08-28 round)\n\n```vid-design-amendments (this round)\n# a note for the designer\nD-01 | S01/saved | REQ-001 | canvas says: a subtitle | row says: no subtitle named | ruling: design wins | status: landed\nD-02 | S02/active | REQ-002 | canvas says: grey title | row says: nothing on colour | ruling: not a disagreement | status: landed\n```\n' > DESIGN-AMENDMENT-BRIEF.md
}
# usability (B13): `pg_face <dir>` copies checks/ to <dir> with a stand-in for the panel's `face.sh waiting` beside its
# pages.sh: it prints the file <dir>/waiting when there is one (a sitting waiting, in the panel spec's form: the
# sitting's name, stop and title separated by tabs, then one line an item, its id, a tab, its words), else nothing.
# Every other call of the stand-in fails, as a face.sh without `waiting` does.
pg_face() { cp -R "$CHECKS" "$1"; printf '#!/bin/sh\n# stand-in for the panel lane: face.sh waiting\n[ "${1:-}" = waiting ] || exit 2\nD=$(cd "$(dirname "$0")" && pwd -P)\n[ -f "$D/waiting" ] && cat "$D/waiting"\nexit 0\n' > "$1/face.sh"; }
# usability (B14, B15): `pg_rest <page.md> <source>…` prints, one a line, every piece of the page that is not copied
# from a source document: ids and addresses, the markdown's own marks and link targets taken out, each line cut at
# the joins the script writes (` — `, `: `, `; `, `(`, `)`, `"`, `·`, a table's `|`). A piece with no number and no
# id is copied when it is found in a source. A piece holding a number or an id is copied only with its line: when it is
# a phrase of words found in a source, or when it and the piece beside it, with the join between them, are found there
# together; a number or an id standing alone between the script's own words is printed. What is left is what the
# script itself wrote.
pg_rest() { _m=$1; shift; cat "$@" > "$T/.src" 2>/dev/null || true
  awk -v src="$T/.src" 'BEGIN { while ((getline l < src) > 0) big = big "\n" l }
    function tr(x) { gsub(/^[ \t.,]+|[ \t.,]+$/, "", x); return x }
    /^[ \t]*$/ || /^\{at: [^}]*\}$/ || /^\{chapter: [0-9]*\}$/ || /^:::$/ || /^\[\[contents\]\]$/ || /^```/ || /^\|[ \t:|-]*$/ { next }
    { s = $0; gsub(/\{id: [^}]*\}/, "", s); gsub(/\]\(#[A-Za-z0-9_-]*\)/, "", s); gsub(/\[/, "", s); gsub(/\*\*/, "", s)
      sub(/^#+ /, "", s); sub(/^- /, "", s); sub(/^::: fold /, "", s); sub(/^!!! /, "", s)
      n = 0; while (match(s, / — |: |; | · |[()"|]/)) { P[++n] = substr(s, 1, RSTART - 1); J[n] = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } P[++n] = s
      for (i = 1; i <= n; i++) { x = tr(P[i]); if (x == "") continue
        if (x !~ /[0-9]/) { if (!index(big, x)) print x; continue }
        if (x ~ / / && x ~ /(^| )[A-Za-z]+( |$)/ && index(big, x)) continue
        if (i > 1 && tr(P[i - 1]) != "" && index(big, tr(P[i - 1] J[i - 1] P[i]))) continue
        if (i < n && tr(P[i + 1]) != "" && index(big, tr(P[i] J[i] P[i + 1]))) continue
        print x } }' "$_m"; }
pg_snap() { find . -type f ! -path './.git/*' ! -path './.vid/pages/*' ! -path ./.vid/pagelinks | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(cksum < "$f")" "$f"; done; }
