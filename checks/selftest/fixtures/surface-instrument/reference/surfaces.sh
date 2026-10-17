# Purpose: the surface instrument for the Boardlet fixture — ONE ledger test
# for every screen (v0.9.2 3.4, R7). The REFERENCE instrument: the known-good
# the fixture's checker must acquit, kept out of every surface pass's inputs.
# Serves ROW-002, ROW-003, ROW-004 (the row table below); reads nothing but
# itself, the harness and design/ (the literal sets were read off
# design/screens/pack.html at production time and are carried here).
#
#   row     | marker/state  | actor     | route | fixture
#   ROW-002 | P01/default   | anonymous | /     | -
#   ROW-003 | P01/empty     | anonymous | /     | unlisted
#   ROW-004 | P02/default   | member    | /jobs | -
#
# Tests-by: test-author 2026-09-21 surface (the fixture's reference; a project's instrument carries the pass's own trailer in its commit)

surface_rows() {
  cat <<'ROWS'
ROW-002 P01/default anonymous / -
ROW-003 P01/empty anonymous / unlisted
ROW-004 P02/default member /jobs -
ROWS
}

# The per-state literal set — every property the canvas declares on every
# identified element, the content it draws, the controls it draws, the shell.
surface_literals() {
  case "$1/$2" in
    P01/default) cat <<'LIT'
prop page-title font-size 2rem
prop page-title color var(--ink)
prop search-form display flex
prop search-form gap 8px
prop search-field padding 8px
prop search-action background-color var(--accent)
prop search-action color var(--accent-ink)
prop search-action padding 8px 16px
prop featured-grid display grid
prop featured-grid grid-template-columns 1fr 1fr 1fr
prop featured-grid gap 16px
content Find your next role
control search-field
control search-action
shell C00/shell-anonymous
LIT
    ;;
    P01/empty) cat <<'LIT'
prop page-title font-size 2rem
prop page-title color var(--ink)
prop empty-notice color var(--muted)
prop empty-notice padding 24px
content Find your next role
content No roles are listed yet. Check back soon.
shell C00/shell-anonymous
LIT
    ;;
    P02/default) cat <<'LIT'
prop page-title font-size 1.5rem
prop page-title color var(--ink)
prop sort-control display flex
prop sort-control gap 8px
prop job-list display grid
prop job-list gap 12px
prop job-card border-radius 8px
prop job-card padding 16px
prop job-card background-color var(--surface)
prop job-title font-weight 600
prop job-salary color var(--muted)
content Jobs
content Sort by
control select:sort
shell C00/shell-anonymous
LIT
    ;;
  esac
}

# One case per row per engine: the actor door, ONE load, every literal in one
# measure, the state's content, no sibling state's control, no console error —
# then the row's pins hook on the same loaded page.
surface_case() {
  row=$1; eng=$2
  set -- $(surface_rows | awk -v r="$row" '$1 == r')
  ms=$2; actor=$3; route=$4; fx=$5; m=${ms%%/*}; s=${ms#*/}
  harness_fixture "$fx"
  lits=$(mktemp); out=$(mktemp)
  surface_literals "$m" "$s" > "$lits"
  measure_state "$eng" "$actor" "$route" "$m" "$s" < "$lits" > "$out"
  bad=$(grep -vE '^(ok |navigations=1$)' "$out" || true)
  rm -f "$lits" "$out"
  if [ -n "$bad" ]; then harness_assert 1 "$row $ms: $(printf '%s' "$bad" | tr '\n' ';')"; return 0; fi
  harness_assert 0 "$row $ms measured"
  harness_run_hook "pins_${m}_$(printf '%s' "$s" | tr '-' '_')" || true
}

# pins: the page title present; a search form with one field and one action; the featured grid present
pins_P01_default() {
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" page-title)" = 1 ] && echo 0 || echo 1)" "ROW-002: the page title is not present once"
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" search-form)" = 1 ] && [ "$(harness_count "$MEASURED_PAGE" search-field)" = 1 ] && [ "$(harness_count "$MEASURED_PAGE" search-action)" = 1 ] && echo 0 || echo 1)" "ROW-002: one search form with one field and one action"
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" featured-grid)" = 1 ] && echo 0 || echo 1)" "ROW-002: the featured grid is not present"
}

# pins: the empty notice present; no search form
pins_P01_empty() {
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" empty-notice)" = 1 ] && echo 0 || echo 1)" "ROW-003: the empty notice is not present"
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" search-form)" = 0 ] && echo 0 || echo 1)" "ROW-003: a search form is drawn on the empty state"
}

# pins: card count = page size; sort control present; salary shown when the record carries one
pins_P02_default() {
  size=$(harness_page_size); cards=$(harness_count "$MEASURED_PAGE" job-card)
  harness_assert "$([ "$cards" = "$size" ] && echo 0 || echo 1)" "ROW-004: card count $cards is not the page size $size"
  harness_assert "$([ "$(harness_count "$MEASURED_PAGE" sort-control)" = 1 ] && echo 0 || echo 1)" "ROW-004: the sort control is not present"
  n=1
  while [ "$n" -le "$cards" ]; do
    rec=$(harness_attr "$MEASURED_PAGE" job-card "$n" data-record)
    salary=$(harness_records | awk -F'|' -v r="$rec" '$1 == r { print $3 }')
    text=$(harness_element_text "$MEASURED_PAGE" job-card "$n")
    if [ -n "$salary" ] && [ "$salary" != - ]; then
      harness_assert "$(printf '%s' "$text" | grep -qF "$salary" && echo 0 || echo 1)" "ROW-004: record $rec carries the salary $salary and card $n does not show it"
    else
      harness_assert "$(printf '%s' "$text" | grep -qE '£[0-9]' && echo 1 || echo 0)" "ROW-004: record $rec carries no salary and card $n shows one"
    fi
    n=$((n + 1))
  done
}
