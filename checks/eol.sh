#!/bin/sh
# Purpose: the spec files' line endings (0.26.10.28.1, 9.1 R4, F1). ViD's checks read their law files by exact lines,
# so a file saved with Windows line endings (CR LF) is misread silently. Two subcommands, run at the project's root:
#   check   one line per spec file that holds a carriage return, in its working-tree copy or its staged copy
#           (git show :<file>), and exit 1 if any does; exit 0 when none does. The spec files: PRD.md, every file
#           checks/lawfiles lists, DECISIONS.md, DESIGN-BRIEF.md, DESIGN-AMENDMENT-BRIEF.md and SEED.md, each where
#           it exists. checks/hooks/pre-commit runs it before its courts.
#   file <file>...   0.26.10.29.3 (R9, F53): the same test and the same line on the files named, each where it exists —
#           the courts that read a spec file (prd.sh, inventory.sh, stages.sh) run it on their input first, so a court run
#           directly refuses a CR LF file as the commit hook does, never misreading it and never stripping its carriage returns.
#   write   .gitattributes with the four pins below, or, when one exists, only the pins it lacks added. /vid init
#           runs the plugin's copy at its start, so the project's first commit carries them.
# Usage: sh checks/eol.sh check | file <file>... | write
# serves: both (0.26.10.28.4, M9)
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
CR=$(printf '\r')
# crlf <file>...: one line each for the files holding a carriage return, in the working tree or staged; 1 if any does
crlf() {
  B=0
  for f in "$@"; do
    c=''
    if [ -f "$f" ] && LC_ALL=C grep -q "$CR" "$f"; then c=1; fi
    # the staged copy is read for a path inside the project only (`file` may name a file anywhere)
    case "$f" in /*|../*) ;; *) if [ -z "$c" ] && git rev-parse -q --verify ":$f" > /dev/null 2>&1 && git show ":$f" 2>/dev/null | LC_ALL=C grep -q "$CR"; then c=1; fi ;; esac
    [ -z "$c" ] || { echo "ViD: refused — $f has Windows line endings (CR LF), which ViD's checks cannot read. Save it with LF line endings; .gitattributes keeps git from adding them back (sh checks/eol.sh write)." >&2; B=1; }
  done
  return "$B"
}
case "${1:-}" in
  check)
    crlf PRD.md $(sed -n 's/^\([^#[:space:]][^[:space:]]*\)[[:space:]].*/\1/p' "$HERE/lawfiles" 2>/dev/null | sort -u) DECISIONS.md DESIGN-BRIEF.md DESIGN-AMENDMENT-BRIEF.md SEED.md
    exit $? ;;
  file) shift; crlf "$@"; exit $? ;;
  write)
    [ ! -f .gitattributes ] || [ ! -s .gitattributes ] || [ -z "$(tail -c 1 .gitattributes)" ] || echo >> .gitattributes
    for l in '*.md text eol=lf' '*.sh text eol=lf' 'checks/** text eol=lf' 'docker-compose.test.yml text eol=lf'; do
      grep -qxF "$l" .gitattributes 2>/dev/null || printf '%s\n' "$l" >> .gitattributes
    done
    echo 'ViD: .gitattributes pins the spec files, the scripts and checks/ to LF line endings' ;;
  *) echo 'ViD eol: usage — sh checks/eol.sh check | file <file>... | write' >&2; exit 2 ;;
esac
