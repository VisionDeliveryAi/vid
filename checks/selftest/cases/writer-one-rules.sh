#!/bin/sh
# Purpose: selftest case — one rule set for what a published ticket is owed (GM-4 F7). The writer's gate reads the setup: in GitHub
# auto too, with issue-form: set, an uncommitted change to the form shuts it, naming the form (TW's toy). In writer.sh no
# GitHub-manual-only subcommand stays (mowed, followups, qat), and each place where GitHub manual still differs names its ruling (a GM
# M<n>, GM-2 T<n>, GM-3 U<n> or GM-4 item) on its line, the line above, or the comment lines just above it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "writer-one-rules: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
WS=$CHECKS/writer.sh
# the gate reads the setup in GitHub auto
tw_toy "$T/toy"; mkdir -p forms; fm_form forms/issue.md; g add forms/issue.md; g commit -qm 'the issue form'; printf 'issue-form: forms/issue.md\n' >> .vid/tw/settings
sh "$WS" gate > "$T/out" 2>&1 || fail 'the gate is shut with the form committed'
echo 'The toy team adds a line.' >> forms/issue.md; RC=0; sh "$WS" gate > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'forms/issue.md has an uncommitted change' "$T/out" || fail "GitHub auto: an uncommitted change to the issue form leaves the gate open (exit $RC)"
# no GitHub-manual-only subcommand
grep -nE '^  (mowed|followups|qat)\)' "$WS" > "$T/out" && fail 'a GitHub-manual-only subcommand stays in the writer'
# each remaining difference names its ruling
awk 'function rul(s) { return s ~ /GM M[0-9]|GM-[234] [A-Z][0-9]|GM-[234] [A-Z]+[0-9]*[:,; )]|GM-4 F[0-9]|E[0-9]+[),:; ]/ }
  { L[NR] = $0 }
  END { for (i = 1; i <= NR; i++) { l = L[i]; if (l ~ /^[ \t]*#/) continue
      if (l !~ /(^|[;&|{!(]|if|then|else|do)[ \t]*manual[ \t]*($|[;&|})])/ || rul(l) || rul(L[i - 1])) continue
      ok = 0; for (j = i - 1; j > 0 && L[j] ~ /^[ \t]*#/; j--) if (rul(L[j])) ok = 1; if (!ok) print i ": " l } }' "$WS" > "$T/out"
[ ! -s "$T/out" ] || fail "a GitHub manual difference in writer.sh names no ruling: $(head -n 3 "$T/out")"
exit 0
