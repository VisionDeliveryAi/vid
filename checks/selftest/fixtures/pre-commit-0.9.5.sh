#!/bin/sh
# Purpose: ViD court — protected paths (ledger/checks/design), the law-change
# standalone rule (§4.1: a commit touching law may touch nothing else),
# Purpose: headers on new source files, enforcement refs on DECISIONS entries,
# then placement, conformance and the presence-gated courts including the
# census and the provider-seam court; Fail-if amendments counted (§10).
# Fails closed. Law: CLAUDE.md; rule-source list: checks/lawfiles.
# Installed via core.hooksPath.
# v0.9.5 (3.7-3.9; R7-R9): the hook times what it runs, into its own file,
# one line per commit attempt (refused ones included) —
#   hook result=pass|refused|killed seconds=<total> placement=<s> conformance=<s> imports=<s> seams=<s> inventory+census=<s> design-cite=<s> prd=<s|memo|-> harness=<s> selftest=<s|memo|-> at=<UTC>
# in .vid/hook-times, every field `-` until its court runs, written by the
# EXIT trap whatever the exit path, never able to turn a pass into a refusal
# (`result=pass` is this hook's; commit-msg can still refuse the commit); the
# courts run side by side — the quick gate (placement, conformance, imports,
# seams) together, then the lanes (inventory then census, design-cite, prd,
# harness) together — each job's output, status and seconds in its own file,
# replayed in a fixed order, every failing court named, exactly the commits
# the serial hook refused refused; and two memos skip work whose inputs are
# unchanged on disk — the PRD court, and the law commit's run of ViD's
# shipped self-test cases — only once rule 2a has run (HEAD carries checks/).
set -eu
IFS='
'

# --- v0.9.5 (3.7): the timing line, written on every exit path ---------------------
T0=$(date +%s); RESULT=''; TD=''; JOBS=''
F_placement=-; F_conformance=-; F_imports=-; F_seams=-; F_invcen=-; F_designcite=-; F_prd=-; F_harness=-; F_selftest=-
hook_times() {
  rc=$1; set +e
  [ -n "$RESULT" ] || { if [ "$rc" -eq 0 ]; then RESULT=pass; else RESULT=refused; fi; }
  { mkdir -p .vid && printf 'hook result=%s seconds=%s placement=%s conformance=%s imports=%s seams=%s inventory+census=%s design-cite=%s prd=%s harness=%s selftest=%s at=%s\n' \
      "$RESULT" "$(( $(date +%s) - T0 ))" "$F_placement" "$F_conformance" "$F_imports" "$F_seams" "$F_invcen" "$F_designcite" "$F_prd" "$F_harness" "$F_selftest" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/hook-times; } 2>/dev/null
  [ -n "$TD" ] && rm -rf "$TD" 2>/dev/null
  return 0
}
kill_tree() { for _c in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$_c"; done; kill "$1" 2>/dev/null; }
on_kill() { set +e; RESULT=killed; for _p in $JOBS; do kill_tree "$_p"; done; exit 143; }
trap 'rc=$?; hook_times "$rc"; exit $rc' EXIT
trap on_kill INT TERM

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
STAGED_ALL=$(git diff --cached --name-only --diff-filter=ACMRD)
[ -n "$STAGED_ALL" ] || exit 0

# v0.9.3 (3.9, R13, R22): a nudge the observer left is printed at every
# commit and never blocks; the session answers it with
# `sh checks/watchdog.sh claim run --evidence '<observation>'`.
if [ -f .vid/NUDGE ]; then
  case "$(git show :INVENTORY.md 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in
    'grammar: 0.9.3') echo "ViD pre-commit: note — the observer left a nudge: $(head -n 1 .vid/NUDGE). Answer it with an observation: sh checks/watchdog.sh claim run --evidence '<what you observed>'" ;;
  esac
fi

# 1. Ledger and courts are outside ordinary write scope (CLAUDE.md ledger law).
if [ "${VID_ROLE:-}" != "fix" ]; then
  PROT=$(printf '%s\n' "$STAGED_ALL" | grep -E '^(tests/invariants/|checks/|design/)' || true)
  if [ -n "$PROT" ]; then
    echo 'ViD pre-commit: rejected — protected paths staged without VID_ROLE=fix:' >&2
    printf '%s\n' "$PROT" | sed 's/^/    /' >&2
    echo 'Only owner-sanctioned writes may touch tests/invariants/, checks/ or design/.' >&2
    exit 1
  fi
fi

# 2. Law-change standalone rule (§4.1): a commit that touches any vid-*
#    machine block, any file in checks/, or that deletes/weakens a ledger
#    assertion, may touch nothing else. Additions to the ledger stay free —
#    the dual-write depends on it. Skipped while HEAD carries no checks/
#    (the commit that installs the courts is the ratification act itself;
#    since v0.8.1b the PRD's ratification commits precede it as the
#    project's first history, so "root commit" is no longer the test).
#    Rule sources are enumerated once, in checks/lawfiles.
LAWCOMMIT=no
MEMO_OK=no
if git rev-parse -q --verify HEAD:checks >/dev/null 2>&1; then
  # 2a. The courts judge with the WORKING TREE. Law sources carrying
  #     unstaged or untracked changes would let this commit be judged by law
  #     that is never committed (F12, made invisible) — refuse to proceed.
  set -- checks design DESIGN-BRIEF.md
  if [ -f checks/lawfiles ]; then
    for lf in $(grep -v '^#' checks/lawfiles | grep -v '^[[:space:]]*$' || true); do
      set -- "$@" "${lf%% *}"
    done
  fi
  LAWDIRTY=$(git diff --name-only -- "$@" 2>/dev/null || true)
  LAWNEW=$(git ls-files --others --exclude-standard -- checks/ design/ 2>/dev/null || true)
  if [ -n "$LAWDIRTY$LAWNEW" ]; then
    echo 'ViD pre-commit: rejected — law sources differ from what this commit stages (unstaged/untracked law):' >&2
    printf '%s\n%s\n' "$LAWDIRTY" "$LAWNEW" | grep -v '^$' | sort -u | sed 's/^/    /' >&2
    echo 'The courts judge with the working tree; stage the law change (its own standalone commit) or restore the files first.' >&2
    exit 1
  fi
  MEMO_OK=yes   # v0.9.5 (3.9): disk equals the index under checks/ from here — the memos may be read and written

  extract() { # $1=git blob ref ($1 may not exist: empty) $2=region name
    C=$(git show "$1" 2>/dev/null || true)
    case "$2" in
      seam-table) printf '%s\n' "$C" | grep -E '^\||^Import court:' || true ;;
      whole) printf '%s\n' "$C" ;;   # v0.9.3 3.3: the whole file is the region
      *) printf '%s\n' "$C" | sed -n '/^```'"$2"'/,/^```$/p' || true ;;
    esac
  }
  TRIGGERS=''
  # (a) any staged change under checks/
  if printf '%s\n' "$STAGED_ALL" | grep -q '^checks/'; then
    TRIGGERS="${TRIGGERS}checks/ (the courts and their harness)
"
  fi
  # (b) any staged change to a machine-read rule-source region
  if [ -f checks/lawfiles ]; then
    for lf in $(grep -v '^#' checks/lawfiles | grep -v '^[[:space:]]*$' || true); do
      f=${lf%% *}; reg=${lf#* }
      printf '%s\n' "$STAGED_ALL" | grep -qxF "$f" || continue
      if [ "$(extract "HEAD:$f" "$reg")" != "$(extract ":$f" "$reg")" ]; then
        TRIGGERS="${TRIGGERS}$f ($reg)
"
      fi
    done
  fi
  # (c) deletions/weakenings in the ledger: removed assert lines or removed
  #     test functions in the staged diff (additions do not trigger).
  KILLS=$(git diff --cached -U0 -- tests/invariants/ 2>/dev/null | grep -E '^-' | grep -v '^---' \
    | grep -cE '\bassert\b|\bexpect\(|def test_|\bit\(|\btest\(' || true)
  if [ "${KILLS:-0}" -gt 0 ]; then
    TRIGGERS="${TRIGGERS}tests/invariants/ ($KILLS removed assertion/test line(s) — deleting or weakening is a law change; adding is free)
"
  fi
  # (c2) neutering by ADDITION: an added skip/xfail marker over a row-bound
  #      test has the same effect as deleting its assertions — same law.
  SKIPS=$(git diff --cached -U0 -- tests/invariants/ 2>/dev/null | grep '^+' | grep -v '^+++' \
    | grep -cE '@[A-Za-z_.]*skip|\bskipif\b|\bxfail\b|\bskipTest\b|\.skip\(|\bpytest\.skip\b' || true)
  if [ "${SKIPS:-0}" -gt 0 ]; then
    TRIGGERS="${TRIGGERS}tests/invariants/ ($SKIPS added skip/xfail marker(s) — neutering by addition is a law change)
"
  fi
  # (d) the ratified design changes only as a visible, standalone act:
  #     modifications/deletions under design/ are law changes; additions
  #     stay free (the ratification import and new screens).
  DMOD=$(git diff --cached --name-only --diff-filter=MD -- design/ 2>/dev/null || true)
  if [ -n "$DMOD" ]; then
    TRIGGERS="${TRIGGERS}design/ (modified/deleted — the ratified design has ledger standing)
"
  fi
  if [ -n "$TRIGGERS" ]; then
    LAWCOMMIT=yes
    NONLAW=''
    for f in $STAGED_ALL; do
      case "$f" in checks/*|tests/invariants/*|design/*|DESIGN-BRIEF.md) continue ;; esac
      grep -v '^#' checks/lawfiles 2>/dev/null | grep -q "^$f " && continue
      NONLAW="$NONLAW$f
"
    done
    if [ -n "$NONLAW" ]; then
      echo 'ViD pre-commit: rejected — this commit changes law and must touch nothing else (§4.1).' >&2
      echo 'Law changed:' >&2
      printf '%s' "$TRIGGERS" | sed 's/^/    /' >&2
      echo 'Also staged (split these into their own commit):' >&2
      printf '%s' "$NONLAW" | sed 's/^/    /' >&2
      echo 'A law change is a standalone, owner-visible act: its Decisions: trailer states what it admits and why.' >&2
      exit 1
    fi
  fi
fi

# 3. Every new source file declares its purpose up front.
# design/ is exempt: ratified design artifacts are imported verbatim from the
# owner — they are spec, not source (CLAUDE.md design law).
for f in $(git diff --cached --name-only --diff-filter=A); do
  case "$f" in
    design/*) continue ;;
    *.md|*.yml|*.yaml|*.json|*.toml|*.ini|*.cfg|*.lock|*.txt|*.csv|*.svg|*.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2) continue ;;
    LICENSE*|*/LICENSE*|.*|*/.*) continue ;;
    checks/lawfiles) continue ;;
  esac
  if ! git show ":$f" | head -n 15 | grep -q 'Purpose:'; then
    echo "ViD pre-commit: rejected — new source file '$f' has no \"Purpose:\" header in its first 15 lines." >&2
    exit 1
  fi
done

# 4. DECISIONS entries must say where they are enforced.
DLINES=$(git diff --cached -U0 -- DECISIONS.md 2>/dev/null | grep '^+- \*\*D-' || true)
BAD=$(printf '%s\n' "$DLINES" | grep -v '| enforced:' | grep -v '^$' || true)
if [ -n "$BAD" ]; then
  echo 'ViD pre-commit: rejected — DECISIONS.md entries without an enforcement ref:' >&2
  printf '%s\n' "$BAD" | sed 's/^/    /' >&2
  echo 'Format: - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention">' >&2
  exit 1
fi

# 4b. Enforcement refs must not be promissory: a named ledger test must exist,
# and "future/planned/TBD" is not enforcement.
for p in $(printf '%s\n' "$DLINES" | grep -oE 'tests/invariants/[A-Za-z0-9_./-]+' | sed 's/[.,;]*$//' | sort -u); do
  if [ ! -f "$p" ]; then
    echo "ViD pre-commit: rejected — DECISIONS.md cites '$p' as enforcement, but no such file exists." >&2
    echo 'Write the ledger test first; promissory refs are invalid.' >&2
    exit 1
  fi
done
if printf '%s\n' "$DLINES" | grep -qiE '\| enforced:[^|]*(future|planned|TBD)'; then
  echo 'ViD pre-commit: rejected — promissory enforced: ref ("future/planned/TBD" is not enforcement).' >&2
  echo 'Write the test first, or cite a hook/convention that exists today.' >&2
  exit 1
fi

# 5–6. The courts — placement and conformance always; the rest presence-gated,
# each on its own rule source (seam table import specifiers, INVENTORY.md,
# @screen markers, census rows/extractors), so earlier projects refresh
# checks/ without breaking. v0.9.5 (3.8, R8): side by side. No court writes a
# shared file or reads another's output (courts-events-map A10); inventory and
# census share one lane, since both run the project's routes extractor.
TD=$(mktemp -d)
# job <name> <command…>: stdout, stderr, status and seconds, each in its own file
job() { _n=$1; shift; ( set +e; _s=$(date +%s); "$@" > "$TD/$_n.out" 2> "$TD/$_n.err"; _r=$?; echo $(( $(date +%s) - _s )) > "$TD/$_n.sec"; echo "$_r" > "$TD/$_n.st" ) & JOBS="$JOBS
$!"; }
court() { : > "$TD/$1.run"; job "$@"; }
settle() { for _p in $JOBS; do [ -n "$_p" ] && { wait "$_p" || true; }; done; JOBS=''; }
sec() { cat "$TD/$1.sec" 2>/dev/null || echo -; }
FAILED=''
# replay <name>…: each court's output in the fixed order; a missing status file is a failure
replay() {
  for _n in "$@"; do
    [ -f "$TD/$_n.run" ] || continue
    [ -f "$TD/$_n.out" ] && cat "$TD/$_n.out"
    [ -f "$TD/$_n.err" ] && cat "$TD/$_n.err" >&2
    _st=$(cat "$TD/$_n.st" 2>/dev/null || true)
    [ "$_st" = 0 ] || FAILED="$FAILED $_n"
  done
}
# the quick gate: the diff-reading courts together; a refusal usually comes from them
court placement sh checks/placement.sh
court conformance sh checks/conformance.sh
if [ -f checks/imports.sh ]; then court imports sh checks/imports.sh; fi
if [ -f checks/seams.sh ]; then court seams sh checks/seams.sh; fi
settle
F_placement=$(sec placement); F_conformance=$(sec conformance)
if [ -f "$TD/imports.run" ]; then F_imports=$(sec imports); fi
if [ -f "$TD/seams.run" ]; then F_seams=$(sec seams); fi
replay placement conformance imports seams
if [ -n "$FAILED" ]; then
  echo "ViD pre-commit: rejected — refused by:$FAILED" >&2
  exit 1
fi
# the PRD court's memo (3.9): its key is checks/ as staged, PRD.md and the seed
# file, each by the sha256 of its bytes on disk; no skip and no memo when any
# hash fails
MEMOD=''; if [ "$MEMO_OK" = yes ]; then MEMOD=$(git rev-parse --git-path vid-memo 2>/dev/null || true); fi
h256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; else sha256sum "$1" 2>/dev/null | cut -d' ' -f1; fi; }
hline() { _h=$(h256 "$2"); [ -n "$_h" ] || return 1; printf '%s %s\n' "$1" "$_h"; }
checks_line() { git ls-files -s -- checks > "$TD/checks.ls" 2>/dev/null || return 1; hline checks/ "$TD/checks.ls"; }
keyof() { _k=$(h256 "$1"); [ -n "$_k" ] || return 1; printf '%s\n' "$_k"; }
PRDKEY=''
if [ -n "$MEMOD" ] && [ -f checks/prd.sh ]; then
  if (   # set -e is ignored inside an if condition: every line exits on its own failure
    checks_line || exit 1
    if [ -f PRD.md ]; then hline PRD.md PRD.md || exit 1; else echo 'PRD.md -'; fi
    _sp=''; if [ -f PRD.md ]; then _sp=$(awk '/^## /{exit} /^Seed:[ \t]+[^ \t]+[ \t]+\(sha256 [0-9a-f]+\)/{print; exit}' PRD.md | sed -E 's/^Seed:[ \t]+([^ \t]+).*/\1/'); fi
    if [ -n "$_sp" ] && [ -f "$_sp" ]; then hline "$_sp" "$_sp" || exit 1; else echo "seed ${_sp:--}"; fi
  ) > "$TD/prd.key.lines" 2>/dev/null; then PRDKEY=$(keyof "$TD/prd.key.lines" || true); fi
fi
PRDSKIP=no
if [ -n "$PRDKEY" ] && [ -f "$MEMOD/prd" ] && [ "$(cat "$MEMOD/prd" 2>/dev/null)" = "$PRDKEY" ]; then PRDSKIP=yes; fi
# the lanes, started together: inventory then census in one, design-cite, prd, harness
if [ -f checks/inventory.sh ] || [ -f checks/census.sh ]; then
  if [ -f checks/inventory.sh ]; then : > "$TD/inventory.run"; fi
  if [ -f checks/census.sh ]; then : > "$TD/census.run"; fi
  ( set +e; _s=$(date +%s)
    if [ -f checks/inventory.sh ]; then sh checks/inventory.sh > "$TD/inventory.out" 2> "$TD/inventory.err"; echo $? > "$TD/inventory.st"; fi
    if [ -f checks/census.sh ]; then sh checks/census.sh > "$TD/census.out" 2> "$TD/census.err"; echo $? > "$TD/census.st"; fi
    echo $(( $(date +%s) - _s )) > "$TD/invcen.sec" ) & JOBS="$JOBS
$!"
fi
if [ -f checks/design-cite.sh ]; then court design-cite sh checks/design-cite.sh; fi
if [ -f checks/prd.sh ]; then
  if [ "$PRDSKIP" = yes ]; then F_prd=memo; else court prd sh checks/prd.sh; fi
fi
if [ -f checks/harness.sh ]; then court harness sh checks/harness.sh; fi
settle
if [ -f "$TD/inventory.run" ] || [ -f "$TD/census.run" ]; then F_invcen=$(sec invcen); fi
if [ -f "$TD/design-cite.run" ]; then F_designcite=$(sec design-cite); fi
if [ -f "$TD/prd.run" ]; then F_prd=$(sec prd); fi
if [ -f "$TD/harness.run" ]; then F_harness=$(sec harness); fi
replay inventory census design-cite prd harness
if [ "$PRDSKIP" = yes ]; then echo 'prd: unchanged since its last pass — skipped (memo)'; fi
if [ -n "$FAILED" ]; then
  echo "ViD pre-commit: rejected — refused by:$FAILED" >&2
  exit 1
fi
# the PRD memo is written only after the court passed here, atomically
if [ -n "$PRDKEY" ] && [ -f "$TD/prd.run" ]; then
  { mkdir -p "$MEMOD" && printf '%s\n' "$PRDKEY" > "$MEMOD/.prd.tmp" && mv "$MEMOD/.prd.tmp" "$MEMOD/prd"; } 2>/dev/null || true
fi

# 6b. Fail-if amendments are COUNTED, never blocked (§10, F9): an amendment
# is legitimate, but uncounted it is indistinguishable from moving the
# goalposts. Counted = added "REQ-NNN AMENDED" lines plus removed Fail-if
# lines in the staged PRD diff; the count lands in .vid/metrics-events for
# checks/metrics.sh.
# v0.9.3 (3.7, R22): under an inventory block opening with `grammar: 0.9.3`
# the removed-line grep matches the enriched grammar's `fail-if:` field too
# (the 0.9.2 grep matched `Fail-if` only — a 0.9.1 defect), and a
# consolidation commit (it adds a PRD-HISTORY-<date>.md) counts none: its
# effective text is unchanged by construction. The `amended` events are
# checks/hooks/post-commit's.
if git diff --cached --name-only | grep -qxF PRD.md; then
  # v0.9.5 (3.13): a staged grammar line lower than HEAD's is refused — the
  # one route for switching join 21 or 0.9.4's joins off; a grammar line
  # removed reads as lowered.
  gram() { git show "$1" 2>/dev/null | awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{sub(/^grammar:[ \t]*/,""); sub(/[ \t]*$/,""); print; exit}'; }
  if git rev-parse -q --verify HEAD:PRD.md >/dev/null 2>&1; then
    GH=$(gram HEAD:PRD.md); GS=$(gram :PRD.md)
    if [ -n "$GH" ] && [ "$(printf '%s\n%s\n' "${GS:-0}" "$GH" | awk -F. 'NR == 1 { for (i = 1; i <= 3; i++) a[i] = $i + 0 } NR == 2 { for (i = 1; i <= 3; i++) { b = $i + 0; if (a[i] < b) { print "lower"; exit } if (a[i] > b) { print "ok"; exit } } print "ok" }')" = lower ]; then
      echo "ViD pre-commit: rejected — PRD.md's grammar line goes from $GH to ${GS:-none}; a grammar is never lowered (v0.9.5 3.13)." >&2
      exit 1
    fi
  fi
  PDIFF=$(git diff --cached -U0 -- PRD.md 2>/dev/null || true)
  A1=$(printf '%s
' "$PDIFF" | grep '^+' | grep -v '^+++' | grep -cE 'REQ-[0-9]+[[:space:]]+AMENDED' || true)
  IG93=no
  case "$(git show :INVENTORY.md 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in 'grammar: 0.9.3') IG93=yes ;; esac
  if [ "$IG93" = yes ]; then
    A2=$(printf '%s
' "$PDIFF" | grep '^-' | grep -v '^---' | grep -ciE 'fail-if' || true)
    if git diff --cached --name-only --diff-filter=A | grep -qE '^PRD-HISTORY-[^/]*\.md$'; then A1=0; A2=0; fi
  else
  A2=$(printf '%s
' "$PDIFF" | grep '^-' | grep -v '^---' | grep -c 'Fail-if' || true)
  fi
  AMEND=$(( ${A1:-0} + ${A2:-0} ))
  if [ "$AMEND" -gt 0 ]; then
    mkdir -p .vid
    printf 'failif-amendment n=%s at=%s\n' "$AMEND" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
    echo "ViD pre-commit: note — $AMEND Fail-if amendment(s) counted (F9: legitimate, and counted)."
  fi
fi

# 7. Touch the law, prove the judge still convicts (§4.2): a law-change
# commit re-runs the court self-tests before it may land.
# v0.9.5 (3.9): the memo skips only the cases the plugin ships
# (checks/selftest/shipped); every other case — a generated extractor's —
# runs at every law commit. Its key: checks/ as staged, the plugin-root trees
# and files the cases read where present, the tools and git's version, the
# locale; with git 2.32 or later only (the cases read no git configuration
# outside their scratch repositories, which needs GIT_CONFIG_GLOBAL).
if [ "$LAWCOMMIT" = yes ] && [ -f checks/selftest/run.sh ]; then
  STKEY=''
  GV=$(git --version 2>/dev/null | sed -n 's/^git version \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')
  GOK=no
  if [ -n "$GV" ]; then
    if [ "${GV% *}" -gt 2 ] || { [ "${GV% *}" -eq 2 ] && [ "${GV#* }" -ge 32 ]; }; then GOK=yes; fi
  fi
  if [ -n "$MEMOD" ] && [ "$GOK" = yes ] && [ -f checks/selftest/shipped ]; then
    if (   # every line exits on its own failure, as above
      checks_line || exit 1
      for _r in skills templates hooks RECORDS.md; do
        [ -e "$_r" ] || continue
        for _f in $(find "$_r" -type f | LC_ALL=C sort); do hline "$_f" "$_f" || exit 1; done
      done
      echo "env uname $(uname -sr)"; echo "env $(git --version)"
      for _t in sh awk sed grep sort; do echo "env $_t $(command -v "$_t")"; done
      echo "env LANG=${LANG:-} LC_ALL=${LC_ALL:-} LC_CTYPE=${LC_CTYPE:-}"
    ) > "$TD/st.key.lines" 2>/dev/null; then STKEY=$(keyof "$TD/st.key.lines" || true); fi
  fi
  if [ -n "$STKEY" ] && [ -f "$MEMOD/selftest" ] && [ "$(cat "$MEMOD/selftest" 2>/dev/null)" = "$STKEY" ]; then
    echo "selftest: ViD's shipped checks unchanged since their last pass — skipped (memo)"
    VID_SELFTEST_UNLISTED=1 sh checks/selftest/run.sh
    F_selftest=memo
  else
    _s=$(date +%s); sh checks/selftest/run.sh; F_selftest=$(( $(date +%s) - _s ))
    if [ -n "$STKEY" ]; then
      { mkdir -p "$MEMOD" && printf '%s\n' "$STKEY" > "$MEMOD/.selftest.tmp" && mv "$MEMOD/.selftest.tmp" "$MEMOD/selftest"; } 2>/dev/null || true
    fi
  fi
fi
exit 0
