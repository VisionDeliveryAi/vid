#!/bin/sh
# Purpose: results reader (fixture) — the toy runner already prints case lines.
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
grep '^case ' "$1"
