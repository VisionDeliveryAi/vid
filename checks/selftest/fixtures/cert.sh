# Purpose: selftest fixture — the self-test certificate's toy project (v0.9.7.3 spec 3.6, R6). Sourced by a case after
# it has made $T (Env: CHECKS, T). ct_repo <dir> makes, there, stub courts under the real hook, a copy of run.sh, a
# skills/ file (part of the key), one shipped case — it appends to $T/shipped.ran, then runs $T/hook-in.sh when that
# exists (a case's hook into the run: a pause, an edit) — and enters it. ct_cert: the certificate directory,
# <absolute git common dir>/vid-selftest. ct_row <n>: a law change staged (an INVENTORY row). ct_law <msg>: the hook
# on it, then the commit (refusal fails the case). ct_runs: how many times the shipped case ran.
ct_repo() {
  mkdir -p "$1"; cd "$1"
  . "$CHECKS/selftest/fixtures/stub-courts.sh"
  mkdir -p checks/selftest/cases skills
  cp "$CHECKS/selftest/run.sh" checks/selftest/run.sh
  printf '#!/bin/sh\n# Purpose: a shipped case\necho x >> "%s/shipped.ran"\nif [ -f "%s/hook-in.sh" ]; then sh "%s/hook-in.sh" || exit 1; fi\nexit 0\n' "$T" "$T" "$T" > checks/selftest/cases/shipped-one.sh
  printf '# Purpose: the cases the plugin ships\nshipped-one.sh\n' > checks/selftest/shipped
  printf 'INVENTORY.md vid-inventory\n' > checks/lawfiles
  printf '# a skill\n' > skills/one.md
  printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x\n```\n' > INVENTORY.md
  g add -A && g commit -qm 'a project with a suite'
}
ct_cert() { printf '%s/vid-selftest\n' "$(cd "$(git rev-parse --git-common-dir)" && pwd -P)"; }
ct_row() { printf 'ROW-%03d | behavior | REQ-001 | n/a | n/a | row %s | REQ-001 | owed: prerequisite — x\n' "$1" "$1" > "$T/r"
  awk -v r="$(cat "$T/r")" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > "$T/i" && mv "$T/i" INVENTORY.md; g add INVENTORY.md; }
ct_law() { sh checks/hooks/pre-commit > "$T/out" 2>&1 || { echo "the law commit was refused: $1" >&2; cat "$T/out" >&2; exit 1; }; g commit -qm "$1" --no-verify; }
ct_runs() { if [ -f "$T/shipped.ran" ]; then grep -c . "$T/shipped.ran"; else echo 0; fi; }
