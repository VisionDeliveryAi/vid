#!/bin/sh
# Purpose: selftest case — an owner's ruling carries the owner's words
# (0.26.10.29.3, R2). The commit-msg hook, run on a staged PRD.md against
# HEAD's in a scratch repository: a new `human` answer with no `Owner:`
# trailer is refused, naming the answer; the same commit passes with
# `Owner: "<words>"` and with one trailer per answer, `Owner: A-NNN
# "<words>"`; an `Owner:` line quoting nothing is no trailer. A ViD draft
# restated `human` with the same `A:` (the draft promoted) is a new ruling
# too, and is refused without the trailer; a new `model_proposed` answer, and
# a commit that leaves the PRD alone, need none, and so does the first commit
# of a PRD.md HEAD does not hold (an adopted file). Env: CHECKS.
set -eu
FIXTURES="$CHECKS/selftest/fixtures"; HOOK="$CHECKS/hooks/commit-msg"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "commit-msg-refuses-human-without-owner: $*" >&2; exit 1; }
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
msg() { printf 'A ruling\n\nDecisions: none — nothing surprising\n%s' "$1" > "$T/msg"; }
runs() { sh "$HOOK" "$T/msg" >"$T/out" 2>&1; }
cp "$FIXTURES/prd-known-good.md" PRD.md
g add PRD.md
msg ''
runs || { cat "$T/out" >&2; fail 'the first commit of a PRD.md (an adopted file) was asked for an Owner: trailer'; }
g commit -qm 'root' --no-verify
append() { printf '\n### 2026-09-30 (owner answer)\n\n```vid-prd-answers\n%s\n```\n' "$1" >> PRD.md; g add PRD.md; }
# 1. a new human answer
append 'A-007 | human | 2026-09-30 | Q: may a subscriber pause digests? | A: yes, for up to four weeks | settles: REQ-001'
msg ''
if runs; then fail 'a new human answer with no Owner: trailer was accepted'; fi
grep -q 'A-007' "$T/out" || { cat "$T/out" >&2; fail 'the refusal does not name A-007'; }
grep -q 'Owner:' "$T/out" || fail 'the refusal does not say what the trailer is'
msg 'Owner: yes'
if runs; then fail 'an Owner: line quoting nothing was taken as the trailer'; fi
msg 'Owner: "yes, four weeks at most"'
runs || { cat "$T/out" >&2; fail 'the same commit with an Owner: trailer was refused'; }
msg 'Owner: A-007 "yes, four weeks at most"'
runs || { cat "$T/out" >&2; fail 'the per-answer trailer was refused'; }
# 2. a ViD draft committed, then promoted to human with the same A: (the draft's words, not the owner's)
git checkout -q -- PRD.md 2>/dev/null || true; g reset -q --hard
append 'A-007 | model_proposed | 2026-09-30 | Q: may a subscriber pause digests? | A: yes, for up to four weeks | settles: REQ-001'
msg ''
runs || { cat "$T/out" >&2; fail 'a new model_proposed answer was refused (a draft needs no trailer)'; }
g commit -qm 'the draft' --no-verify
append 'A-007 AMENDED | human | 2026-10-01 | Q: may a subscriber pause digests? | A: yes, for up to four weeks | settles: REQ-001'
msg ''
if runs; then fail 'a draft restated human with its own A: was accepted with no Owner: trailer'; fi
grep -q 'A-007' "$T/out" || fail 'the promoted draft is not named'
msg 'Owner: "yes"'
runs || { cat "$T/out" >&2; fail 'the promoted draft with the trailer was refused'; }
# 3. a commit that does not touch the PRD
g reset -q --hard; printf 'x\n' > notes.txt; g add notes.txt; msg ''
runs || { cat "$T/out" >&2; fail 'a commit that leaves the PRD alone was refused'; }
exit 0
