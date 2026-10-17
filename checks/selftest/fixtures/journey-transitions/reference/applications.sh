# Purpose: the behavior rows ROW-011..014 for the Boardlet fixture — the
# REFERENCE cases the checker must acquit; the API door, the cheapest
# boundary that observes each promise (R6).
# Tests-by: test-author 2026-09-21 applications (the fixture's reference)
behavior_rows() { printf 'ROW-011 member\nROW-012 member\nROW-013 member\nROW-014 member\n'; }
case_ROW_011() {
  st=$(harness_api "$1" "$2" POST /applications/role-7 | head -n 1)
  harness_assert "$([ "$st" = 201 ] && echo 0 || echo 1)" "ROW-011: applying answered $st, not created"
  n=$(harness_api "$1" "$2" GET /applications | sed 1d | grep -c 'role-7')
  harness_assert "$([ "$n" = 1 ] && echo 0 || echo 1)" "ROW-011: $n applications recorded for the role, not one"
}
case_ROW_012() {
  harness_api "$1" "$2" POST /applications/role-7 >/dev/null
  st=$(harness_api "$1" "$2" POST /applications/role-7 | head -n 1)
  harness_assert "$([ "$st" = 409 ] && echo 0 || echo 1)" "ROW-012: a second application answered $st, not a conflict"
  n=$(harness_api "$1" "$2" GET /applications | sed 1d | grep -c 'role-7')
  harness_assert "$([ "$n" = 1 ] && echo 0 || echo 1)" "ROW-012: the count is $n after the refused second application"
}
case_ROW_013() {
  harness_api "$1" "$2" POST /applications/role-7 >/dev/null
  st=$(harness_api "$1" "$2" DELETE /applications/role-7 | head -n 1)
  harness_assert "$([ "$st" = 204 ] && echo 0 || echo 1)" "ROW-013: withdrawing answered $st"
  n=$(harness_api "$1" "$2" GET /applications | sed 1d | grep -c 'role-7')
  harness_assert "$([ "$n" = 0 ] && echo 0 || echo 1)" "ROW-013: the application is still recorded"
  st=$(harness_api "$1" "$2" DELETE /applications/role-9 | head -n 1)
  harness_assert "$([ "$st" = 404 ] && echo 0 || echo 1)" "ROW-013: withdrawing a role never applied to answered $st, not not-found"
}
case_ROW_014() {
  harness_api "$1" "$2" POST /applications/role-7 >/dev/null
  harness_api "$1" "$2" POST /applications/role-8 >/dev/null
  harness_api "$1" "$2" DELETE /applications/role-8 >/dev/null
  harness_actor "$1" other-member >/dev/null && harness_api "$1" other-member POST /applications/role-9 >/dev/null
  list=$(harness_api "$1" "$2" GET /applications | sed 1d)
  harness_assert "$([ "$list" = role-7 ] && echo 0 || echo 1)" "ROW-014: the list answers '$list', not the one current application (the withdrawn role-8 gone, the other member's role-9 absent)"
}
