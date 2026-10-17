# Purpose: the journey ROW-010 for the Boardlet fixture — the REFERENCE test
# the checker must acquit (kept out of every pass's inputs). One step per
# transition, each operating the entry control through the engine door and
# asserting the effect on the page; setup uses no transition.
# Tests-by: test-author 2026-09-21 journeys (the fixture's reference)
journey_rows() { echo 'ROW-010 member 4'; }
journey_ROW_010_setup() { :; }   # a fresh member on P02/default is the starting state
journey_ROW_010_transition_1() {
  harness_press "$1" "$2" View
  harness_assert "$([ "$(harness_page)" = P03/default ] && echo 0 || echo 1)" 'ROW-010 t1: View did not open the role page'
  harness_assert "$(harness_text | grep -q 'Data Engineer' && echo 0 || echo 1)" 'ROW-010 t1: the role title is not shown'
}
journey_ROW_010_transition_2() {
  harness_press "$1" "$2" Apply
  harness_assert "$([ "$(harness_page)" = P03/applied ] && echo 0 || echo 1)" 'ROW-010 t2: Apply did not reach P03/applied'
  harness_assert "$(harness_text | grep -q 'Application sent' && echo 0 || echo 1)" 'ROW-010 t2: no "Application sent" notice'
  harness_assert "$(harness_text | grep -q '\[Apply\]' && echo 1 || echo 0)" 'ROW-010 t2: the Apply control is still shown'
}
journey_ROW_010_transition_3() {
  harness_press "$1" "$2" Withdraw
  harness_assert "$([ "$(harness_page)" = P03/default ] && echo 0 || echo 1)" 'ROW-010 t3: Withdraw did not return to P03/default'
  harness_assert "$(harness_text | grep -q 'Application sent' && echo 1 || echo 0)" 'ROW-010 t3: the notice is still shown'
  harness_assert "$(harness_text | grep -q '\[Apply\]' && echo 0 || echo 1)" 'ROW-010 t3: the Apply control is not back'
}
journey_ROW_010_transition_4() {
  harness_press "$1" "$2" 'My applications'
  harness_assert "$([ "$(harness_page)" = P04/default ] && echo 0 || echo 1)" 'ROW-010 t4: My applications did not open P04/default'
  harness_assert "$(harness_text | grep -q 'No applications' && echo 0 || echo 1)" 'ROW-010 t4: an application is still listed'
}
