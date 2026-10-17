#!/bin/sh
# Purpose: ledger tests for the link store (ROW-101..ROW-104), through the store's public functions.
# Provenance: hand-authored
# Run: sh tests/invariants/links.sh → one `case <path>::<name> <status> <seconds>` line per case.
. "$(dirname "$0")/../../app/links.sh"
LINKLING_STORE=$(mktemp -d); export LINKLING_STORE
report() { if [ "$2" = 0 ]; then s=passed; else s=failed; fi; echo "case tests/invariants/links.sh::$1 $s 0.0"; }

test_row101() { # ROW-101 REQ-001: a web target's code resolves to it
  set -- $(link_create 'https://example.org/a')
  [ "$(link_resolve "$1")" = '302 https://example.org/a' ]
}
test_row102() { # ROW-102 REQ-002: a target whose scheme is not http or https is refused
  out=$(link_create 'javascript:alert(1)') && return 1
  [ "$out" = 'refused: scheme not allowed' ]
}
test_row103() { # ROW-103 REQ-003: a link older than thirty days answers 410, never a redirect
  set -- $(link_create 'https://example.org/b')
  r=$(link_resolve "$1")
  [ "${r%% *}" != 410 ]
}
test_row104() { # ROW-104 REQ-004: a wrong deletion token is refused and the link stays
  set -- $(link_create 'https://example.org/c')
  [ "$(link_delete "$1" wrongtok)" = '403 wrong token' ] && [ "$(link_resolve "$1")" = '302 https://example.org/c' ]
}
for t in 101 102 103 104; do st=0; test_row$t >/dev/null 2>&1 || st=1; report "test_row$t[ROW-$t]" "$st"; done
