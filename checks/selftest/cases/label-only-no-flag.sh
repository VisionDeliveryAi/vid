#!/bin/sh
# Purpose: selftest case — a relabel raises nothing (v0.9.8 spec 3.3, R6). Normative content is compared canonically:
# D-302's label moved from `applies-to: P01` to `applies-to: ROW-201`, REQ-001's plain: and source: order edited, and a
# decision added since (D-307 citing REQ-001) flag nothing; the control — D-301's rule changed — flags ROW-201
# `what=D-301`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "label-only-no-flag: $*" >&2; exit 1; }
au_repo "$T/repo"; cp "$CHECKS/inventory.sh" checks/; g add -A && g commit -qm inventory; au_stamp
au_dec '' 'applies-to: ROW-201' > DECISIONS.md
sed 's/| plain: a link lasts a week/| plain: links last one week/' PRD.md > p && mv p PRD.md
printf -- '- **D-307** REQ-001 links are stored with their creation time | why: the lifetime | enforced: convention\n' >> DECISIONS.md
g commit -qam 'a relabel, a metadata edit, a decision added'
git diff --quiet HEAD~1 -- DECISIONS.md && fail 'the fixture edit did not change DECISIONS.md'
[ -z "$(au_flags)" ] || fail "a relabel, a metadata edit or an added decision flagged: '$(au_flags)'"
au_dec 'REQ-001 counts the lifetime in whole minutes' 'applies-to: ROW-201' > DECISIONS.md
printf -- '- **D-307** REQ-001 links are stored with their creation time | why: the lifetime | enforced: convention\n' >> DECISIONS.md
g commit -qam 'D-301 changed'
[ "$(au_flags)" = 'ROW-201 D-301' ] || fail "the control: a changed rule flags '$(au_flags)', not ROW-201 D-301"
exit 0
