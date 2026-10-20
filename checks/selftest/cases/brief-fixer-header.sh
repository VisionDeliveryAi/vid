#!/bin/sh
# Purpose: selftest case — a fixer's brief carries its own row's cells (v0.26.10.4 spec R9, F-45; §5
# brief-fixer-header). The brief-write fixture with bw_builder; the toy plugin's role section gains, above its table,
# the header template develop carries (`role: builder|fixer|grader|test-author …`, whose `|`-split second field is
# `fixer`), and its grader row a `"<reason>"` cell. `write --role fixer` writes the fixer row's cells, never the
# template's, and `brief.sh <brief>` says ok; the same brief with the template's garbled cells is refused, naming the
# fixer row; a grader brief, whose row holds `"<reason>"`, passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-fixer-header: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin
cat > "$P/skills/vid-develop/SKILL.md" <<'SK'
# toy develop

## Spawned roles

```
role: builder|fixer|grader|test-author    slice: <N>    step: <id>   (builder, fixer)
quoted-at: <commit sha>
receives: <this role's items>    must not receive: <this role's exclusions>
```

| role | receives | must not receive |
|---|---|---|
| builder | 1–3, 5–12 | another batch's brief or verdicts |
| fixer | 1–8 (7 carries the counterexample) | another batch's brief |
| grader (slice close) | 1–6; the toy grader's extras | item 7; `.vid/verdicts/`; a legacy `owed: reverted — "<reason>"` sibling's detail, carried as `owed: reverted — (detail withheld from graders)` |
| test-author | what the toy pass lists | what it lists |

## Slice close
SK
bw_repo "$T/repo"; bw_builder
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
WANT="receives: 1–8 (7 carries the counterexample)    must not receive: another batch's brief"
bw_write --role fixer --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the fixer brief'
F=$(bw_out); grep -qxF -- "$WANT" "$F" || fail "the fixer brief's receives: line is not the fixer row: $(grep '^receives:' "$F")"
sh checks/brief.sh "$F" > "$T/wout" 2>&1 || fail 'the written fixer brief was refused'
sed "s/^receives: .*/receives: grader    must not receive: test-author    slice: <N>    step: <id>   (builder, fixer)/" "$F" > "$T/garbled.md"
if sh checks/brief.sh "$T/garbled.md" > "$T/wout" 2>&1; then fail 'a fixer brief with the template'"'"'s cells was accepted'; fi
grep -qF "the receives: line is not the fixer row of develop's role table" "$T/wout" || fail 'the refusal does not name the fixer row'
bw_write --role grader --slice 2 --rows ROW-104 --receipt "$S.full.xml" || fail 'the writer refused the grader brief'
G=$(bw_out); grep -qF '"<reason>"' "$G" || fail 'the grader brief does not carry its row'"'"'s "<reason>" cell'
sh checks/brief.sh "$G" > "$T/wout" 2>&1 || fail 'a grader brief with "<reason>" in its row was refused'
exit 0
