#!/bin/sh
# Purpose: selftest case — the PRD court starts the same number of processes whatever the PRD's size (0.26.10.29.3,
# R6). From the known-good fixture, two PRDs are made with 10 and with 100 added items, each item with its own
# answer (human and ViD's draft in turn), its own amendment (an AMENDED row accounting for its arms), mechanism,
# finding and, every fifth, a pending item on its own open question and a resolved carrier. The court runs on each,
# plain and with --pause, with every external command it can start counted through a PATH shim; the counts for 10
# and for 100 items are equal. And the court reads the same in every locale: white space outside ASCII is not white
# space to it — a no-break space before a field stays in the field (here, an unknown type), under the C locale and,
# where the machine has it, under en_US.UTF-8; and a block line holding only a no-break space is a row, not a blank
# line, to the court's three block readers (the blocks it judges, --effective, and --before's file), in both. The
# --arms listing (0.26.10.29.4, phase 3 R4) starts the same number of processes on 10 and on 100 reworded arms. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "prd-court-forks-constant: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/shim"
for c in awk sed grep cut tr head tail sort uniq cksum dirname basename cat wc shasum sha256sum date mktemp rm mv cp \
  env expr uname git ls find tee xargs od paste comm cmp diff printf echo test; do
  p=$(command -v "$c" 2>/dev/null || true); case "$p" in /*) ;; *) continue ;; esac
  printf '#!/bin/sh\nprintf "%%s\\n" %s >> "$SHIMLOG"\nexec "%s" "$@"\n' "$c" "$p" > "$T/shim/$c"; chmod +x "$T/shim/$c"
done
gen() { # n, out
  n=$1; cp "$CHECKS/selftest/fixtures/prd-known-good.md" "$2"
  {
    printf '\n### 2026-09-01 (generated)\n\n```vid-prd-answers\n'
    i=1; while [ "$i" -le "$n" ]; do
      tier=human; [ $((i % 2)) = 0 ] && tier=model_proposed
      printf 'A-%03d | %s | 2026-09-01 | Q: does rule %d hold? | A: yes, rule %d holds | settles: REQ-%03d\n' $((100 + i)) "$tier" "$i" "$i" $((100 + i))
      i=$((i + 1)); done
    printf '```\n\n```vid-prd-mechanisms\n'
    i=1; while [ "$i" -le "$n" ]; do printf 'MECH-%03d | G1 | Generated mechanism %d. | stated: answer A-%03d\n' $((100 + i)) "$i" $((100 + i)); i=$((i + 1)); done
    printf '```\n\n```vid-prd\n'
    i=1; while [ "$i" -le "$n" ]; do
      if [ $((i % 5)) = 0 ]; then
        printf 'REQ-%03d | functional | T1 | P1 | Generated pending rule %d. | fail-if: rule %d breaks | serves: s%d | authority: pending | confirms_via: owner-decision OQ-%d/no | source: thesis\n' $((100 + i)) "$i" "$i" "$i" $((100 + i))
      else
        printf 'REQ-%03d | functional | T1 | P1 | Generated rule number %d holds. | fail-if: rule %d breaks, or rule %d is skipped | serves: s%d | authority: authoritative | source: thesis, A-%03d | covers: DIM-notifications | spans: REQ-001\n' $((100 + i)) "$i" "$i" "$i" "$i" $((100 + i))
      fi
      i=$((i + 1)); done
    i=1; while [ "$i" -le "$n" ]; do
      [ $((i % 5)) = 0 ] || printf 'REQ-%03d AMENDED | functional | T1 | P1 | Generated rule number %d holds always. | fail-if: rule %d breaks, or rule %d is skipped | serves: s%d | authority: authoritative | source: thesis, A-%03d | covers: DIM-notifications | spans: REQ-001 | arms: 1 retained, 2 strengthened\n' $((100 + i)) "$i" "$i" "$i" "$i" $((100 + i))
      i=$((i + 1)); done
    printf '```\n\n```vid-prd-findings\n'
    i=1; while [ "$i" -le "$n" ]; do printf 'F-%03d | review | advisory | REQ-%03d | noted | evidence: generated %d\n' $((100 + i)) $((100 + i)) "$i"; i=$((i + 1)); done
    printf '```\n\n'
    i=5; while [ "$i" -le "$n" ]; do printf 'VID-QUESTION: (OQ-%d) Does pending rule %d hold?\nRESOLVED: (OQ-%d) A-%03d — rule %d\n' $((100 + i)) "$i" $((200 + i)) $((100 + i)) "$i"; i=$((i + 5)); done
  } >> "$2"
}
gen 10 "$T/p10.md"; gen 100 "$T/p100.md"
count() { # file, flag…: the external commands the court starts
  : > "$T/log"; f=$1; shift
  SHIMLOG="$T/log" PATH="$T/shim:$PATH" sh "$CHECKS/prd.sh" "$f" "$@" > "$T/out" 2>&1 || true
  grep -q '^prd: items=' "$T/out" || fail "the court printed no report line on $(basename "$f") $*: $(tail -n 3 "$T/out")"
  grep -c . "$T/log" || true
}
for m in '' --pause; do
  a=$(count "$T/p10.md" $m); b=$(count "$T/p100.md" $m)
  [ "$a" -gt 0 ] || fail "the shim counted no command at all${m:+ with $m} — it does not see the court's commands"
  [ "$a" = "$b" ] || fail "${m:-plain}: the court started $a external commands on 10 added items and $b on 100 — not constant"
done
# 0.26.10.29.4 (phase 3 R4): --arms too, on the same files with every amendment's arm 2 reworded, so each lists one entry
for n in 10 100; do sed '/ AMENDED |/ s/, or rule \([0-9]*\) is skipped |/, or rule \1 is skipped twice |/' "$T/p$n.md" > "$T/a$n.md"; done
countarms() { # file, entries wanted: the external commands --arms starts
  : > "$T/log"
  SHIMLOG="$T/log" PATH="$T/shim:$PATH" sh "$CHECKS/prd.sh" --arms "$1" > "$T/out" 2>&1 || true
  [ "$(grep -c '^REQ-[0-9]* arm 2 strengthened | was: rule [0-9]* is skipped | now: ' "$T/out" || true)" = "$2" ] \
    || fail "--arms on $(basename "$1") did not list its $2 reworded arms: $(tail -n 3 "$T/out")"
  grep -c . "$T/log" || true
}
a=$(countarms "$T/a10.md" 8); b=$(countarms "$T/a100.md" 80)
[ "$a" -gt 0 ] || fail 'the shim counted no command at all with --arms'
[ "$a" = "$b" ] || fail "--arms: the court started $a external commands on 10 added items and $b on 100 — not constant"
# white space outside ASCII is not white space to the court, whatever the locale and the shell
NB=$(printf '\302\240')
sed "s/^REQ-010 | nfr | /REQ-010 | ${NB}nfr | /" "$CHECKS/selftest/fixtures/prd-known-good.md" > "$T/nb.md"
grep -q "^REQ-010 | ${NB}nfr | " "$T/nb.md" || fail 'the fixture with a no-break space before a field was not made'
LOCS=C; if locale -a 2>/dev/null | grep -qx 'en_US.UTF-8'; then LOCS='C en_US.UTF-8'; fi
for l in $LOCS; do
  LC_ALL=$l sh "$CHECKS/prd.sh" "$T/nb.md" --report > "$T/nb.$l" 2>&1 || true
  grep -qF "join 2 (REQ-010): unknown type '${NB}nfr'" "$T/nb.$l" \
    || fail "under LC_ALL=$l a no-break space before a field was trimmed: the court does not name the type '<no-break space>nfr' as unknown"
  cmp -s "$T/nb.C" "$T/nb.$l" || fail "the court's output on a no-break space differs between the C locale and $l"
done
# the same rule for a line that holds nothing but a no-break space: it is a row to every block reader, in every locale
F="$CHECKS/selftest/fixtures/prd-known-good.md"
awk -v nb="$NB" '{ print } /^```vid-prd$/ && !d { print nb; d = 1 }' "$F" > "$T/nbi.md"            # in the items block
awk -v nb="$NB" '{ print } /^```vid-prd-mechanisms$/ && !d { print nb; d = 1 }' "$F" > "$T/nbm.md"  # in the mechanisms block
[ "$(grep -cx "$NB" "$T/nbi.md")" = 1 ] && [ "$(grep -cx "$NB" "$T/nbm.md")" = 1 ] || fail 'the fixtures with a line of one no-break space were not made'
for l in $LOCS; do
  LC_ALL=$l sh "$CHECKS/prd.sh" "$T/nbi.md" --report > "$T/nbi.$l" 2>&1 || true
  grep -qF "join 1 (${NB}): row under-parses" "$T/nbi.$l" \
    || fail "under LC_ALL=$l an item-block line holding only a no-break space was dropped as blank: no 'row under-parses' for it"
  LC_ALL=$l sh "$CHECKS/prd.sh" --effective "$T/nbi.md" > "$T/nbe.$l" 2>&1 || true
  grep -q "^${NB} |" "$T/nbe.$l" || fail "under LC_ALL=$l --effective dropped the line holding only a no-break space"
  LC_ALL=$l sh "$CHECKS/prd.sh" "$F" --report --before "$T/nbm.md" > "$T/nbb.$l" 2>&1 || true
  grep -qF "${NB} is in the pre-consolidation file's effective mechanisms and missing here" "$T/nbb.$l" \
    || fail "under LC_ALL=$l --before dropped its file's mechanism line holding only a no-break space"
  cmp -s "$T/nbi.C" "$T/nbi.$l" && cmp -s "$T/nbe.C" "$T/nbe.$l" && cmp -s "$T/nbb.C" "$T/nbb.$l" \
    || fail "the court's output on a line of one no-break space differs between the C locale and $l"
done
echo 'prd-court-forks-constant: ok'
