#!/bin/sh
# Purpose: selftest case — the weak-test checks measured (v0.9.8 spec 3.6, R11). Two toy extractors (a vacuity and a
# strength, reading plain-text toy tests) run by `census.sh --measure` over a labelled fixture: per class and rule the
# counts are exact — a weak label its orphan names with its rule (tp), an orphan on a good label, an unlabelled subject or
# with another rule (fp), a weak
# label no orphan names (fn) — with precision and recall as counts over counts; the measure exits 0 (advisory) and
# writes nothing; without labels it is a usage error. In the plugin repository the README carries the three repairs
# and the measure. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "detector-measured: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks/extractors" "$T/p/fx/tests/invariants"; cd "$T/p"; cp "$CHECKS/census.sh" checks/
# the toy vacuity extractor: a line `assert-message <text>` with no `{` is placeholderless; a line `assert-true` is vacuous
cat > checks/extractors/vacuity.toy.sh <<'X'
#!/bin/sh
# Purpose: toy vacuity extractor
for f in tests/invariants/*.txt; do
  awk -v f="$f" '/^assert-message / && !/\{/ { print "orphan " f ":" NR " placeholderless-format a message with no placeholder" } /^assert-true$/ { print "orphan " f ":" NR " always-true the assertion holds whatever the product" }' "$f"
done
X
# the toy strength extractor: a file whose only assertion is `assert-exists` is existence-only
cat > checks/extractors/strength.toy.sh <<'X'
#!/bin/sh
# Purpose: toy strength extractor
for f in tests/invariants/*.txt; do
  grep -q '^assert-equals' "$f" || { grep -q '^assert-exists' "$f" && echo "orphan $f:1 existence-only the strongest assertion is existence"; }
done
X
printf 'assert-message the link is gone\n' > fx/tests/invariants/a.txt          # weak (vacuity), caught
printf "assert-message the link isn't {state}\n" > fx/tests/invariants/b.txt   # good: an apostrophe, a placeholder — no orphan
printf 'assert-true\n' > fx/tests/invariants/c.txt                              # weak (vacuity), caught
printf 'assert-message fine {x}\nassert-exists\n' > fx/tests/invariants/d.txt   # weak (strength), caught
printf 'assert-exists\nassert-equals 7 days\n' > fx/tests/invariants/e.txt      # good (strength), no orphan
printf 'assert-message a near miss\n' > fx/tests/invariants/f.txt               # good, but the toy flags it: fp
printf 'assert-message ok {y}\nassert-matches .*\n' > fx/tests/invariants/g.txt # weak (vacuity, any-pattern) the toy misses: fn
printf 'assert-message nothing here\n' > fx/tests/invariants/h.txt              # weak for another rule (always-true): fp and fn
cat > fx/labels <<'L'
# the labelled fixture
weak vacuity tests/invariants/a.txt:1 placeholderless-format
good vacuity tests/invariants/b.txt:1
weak vacuity tests/invariants/c.txt:1 always-true
weak strength tests/invariants/d.txt:1 existence-only
good strength tests/invariants/e.txt:1
good vacuity tests/invariants/f.txt:1
weak vacuity tests/invariants/g.txt:2 any-pattern
weak vacuity tests/invariants/h.txt:1 always-true
L
sh checks/census.sh --measure fx > "$T/out" 2>&1 || fail 'the measure did not exit 0'
cat > "$T/want" <<'W'
measure class=strength rule=existence-only tp=1 fp=0 fn=0 precision=1/1 recall=1/1
measure class=vacuity rule=always-true tp=1 fp=0 fn=1 precision=1/1 recall=1/2
measure class=vacuity rule=any-pattern tp=0 fp=0 fn=1 precision=0/0 recall=0/1
measure class=vacuity rule=placeholderless-format tp=1 fp=2 fn=0 precision=1/3 recall=1/1
measure extractors=2 labels=8 orphans=5 — advisory: no bar is set
W
cmp -s "$T/out" "$T/want" || { diff "$T/want" "$T/out" >&2; fail 'the measure is not the expected counts'; }
[ -z "$(find . -newer fx/labels -type f ! -path './fx/*' ! -path './checks/*' 2>/dev/null)" ] || fail 'the measure wrote a file'
rm fx/labels; if sh checks/census.sh --measure fx > "$T/out" 2>&1; then fail 'a measure with no labels was not a usage error'; fi
R=$(cd "$CHECKS/.." && pwd)
if [ -f "$R/seed/extractors/README.md" ]; then
  for p in '**The repair and the measure (v0.9.8, R11).**' '**Vacuity, the placeholderless format string:**' '**Strength, the parameterised test:**' '**Strength, the ladder:**' 'sh checks/census.sh --measure checks/selftest/fixtures/detectors'; do
    grep -qF -- "$p" "$R/seed/extractors/README.md" || fail "the README lacks: $p"; done
fi
exit 0
