#!/bin/sh
# Purpose: selftest case — a written brief's stamp (v0.9.7.0.5 spec 3.3,
# R6; §6 W-5). The brief-write fixture. Convicts unless checks/brief.sh:
# passes a brief as written; refuses it after one character is changed
# ("changed after writing — write it again"), also under --at HEAD; and
# checks an unstamped hand-made brief as before — passed when well formed
# (the expected-unchanged control). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-stamp: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"
bw_write --role fixer --slice 7 --rows ROW-101,ROW-102 || { cat "$T/wout" >&2; fail 'the writer refused a well-formed fixer brief'; }
F=$(bw_out)
sh checks/brief.sh "$F" > "$T/out" 2>&1 || fail 'the brief as written was refused'
sed 's/a created code resolves to exactly/a created code resolves to exacty/' "$F" > "$T/one.md"
cmp -s "$F" "$T/one.md" && fail 'the edit changed nothing'
if sh checks/brief.sh "$T/one.md" > "$T/out" 2>&1; then fail 'a brief changed after writing was accepted'; fi
grep -qF 'changed after writing — write it again' "$T/out" || fail 'the refusal does not say changed after writing'
# a one-character edit outside any quoted record (section 8) is caught too
sed 's/^ARCHITECTURE\.md$/ARCHITECTURE.mdx/' "$F" > "$T/two.md"
if sh checks/brief.sh "$T/two.md" > "$T/out" 2>&1; then fail 'an edit in further reading was accepted'; fi
grep -qF 'changed after writing' "$T/out" || fail 'the further-reading edit is not refused by the stamp'
# --at HEAD applies the stamp check too
if sh checks/brief.sh "$T/two.md" --at HEAD > "$T/out" 2>&1; then fail '--at HEAD accepted a brief changed after writing'; fi
grep -qF 'changed after writing' "$T/out" || fail '--at HEAD does not check the stamp'
sh checks/brief.sh "$F" --at HEAD > "$T/out" 2>&1 || fail '--at HEAD refused the brief as written'
# the control: an unstamped hand-made brief is checked as before
Q=$(git rev-parse --short=12 HEAD)
{ printf 'role: fixer    slice: 7\nquoted-at: %s\nreceives: 1–8    must not receive: another batch'"'"'s brief\n\n## 1 rows\n%s\n## 8 further reading (optional)\nPRD.md\n' "$Q" "$(grep '^ROW-101 ' INVENTORY.md)"; } > "$T/hand.md"
sh checks/brief.sh "$T/hand.md" > "$T/out" 2>&1 || fail 'an unstamped hand-made brief was refused'
sed 's/a created code resolves to exactly/a created code resolves to exacty/' "$T/hand.md" > "$T/hand2.md"
if sh checks/brief.sh "$T/hand2.md" > "$T/out" 2>&1; then fail 'an unstamped paraphrase passed'; fi
grep -qF 'not byte-identical' "$T/out" || fail 'the unstamped paraphrase is not refused as before'
grep -qF 'changed after writing' "$T/out" && fail 'an unstamped brief got the stamp refusal'
exit 0
