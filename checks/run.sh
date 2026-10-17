#!/bin/sh
# Purpose: ViD's run id (v0.9.6.2 spec 3.1, R1) — one id per trial, kept in
# .vid/run at the run's home, through handoffs, restarts and refreshes of
# checks/. The HOME is resolved as checks/plan.sh does (home_of): this
# worktree's top level when it holds .vid/RUN-STATE.md, else the path its
# .vid/home names (when that path holds a run), else this worktree's top
# level (outside a repository, this directory). .vid/run holds key=value
# lines: id= (the UTC time plus 6 random hex characters), path= (the home's
# absolute path when the id was made), start= (HEAD then, 12 hex, or
# `none`), parent= (the id it was renewed from, or `-`), parent-start= (the
# parent's start=, or `-`), copied-at= (HEAD when a copy was detected, or
# `-`), created= (the UTC time), team= and series= (`unknown` until the
# owner sets them).
#   id                       checks/event.sh's, on every `stage … state=start`
#                            line: prints the run id, creating .vid/run when
#                            it is missing; when its path= is not the home's
#                            path (the project was copied), it writes a new id
#                            with parent=, parent-start= and copied-at=, the
#                            old file kept as .vid/run.parent. A builder
#                            worktree is never taken for a copy: path= is
#                            compared with the home, not with the worktree.
#   new                      the owner's choice of a new trial in the same
#                            folder: a new id with parent= the old one (the
#                            old file kept as .vid/run.parent). ViD never
#                            decides that a trial ended.
#   label team=<t> series=<s>   sets team= and series= (either or both).
# Usage: sh checks/run.sh id | new | label team=<t> series=<s>
set -eu
usage() { echo 'ViD run: usage — sh checks/run.sh id | new | label team=<t> series=<s>' >&2; exit 2; }
TOP=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
H=$TOP
if [ ! -f "$TOP/.vid/RUN-STATE.md" ] && [ -f "$TOP/.vid/home" ]; then
  _h=$(sed -n 1p "$TOP/.vid/home")
  if [ -n "$_h" ] && [ -f "$_h/.vid/RUN-STATE.md" ]; then H=$_h; fi
fi
# v0.9.7.0.1 (3.1, R4): the plan.sh beside this script resolves the home
# (home-of); missing, older, or any exit but 0 keeps the lookup above
_pl="$(dirname "$0")/plan.sh"
if [ -f "$_pl" ]; then
  _prc=0; _ph=$(sh "$_pl" home-of 2>/dev/null) || _prc=$?
  if [ "$_prc" -eq 0 ] && [ -n "$_ph" ] && [ -d "$_ph" ]; then H=$_ph
  elif [ "$_prc" -eq 3 ]; then echo "ViD run: note — $_ph; written here, at $H." >&2; fi
fi
HP=$(cd "$H" && pwd -P)
RF="$HP/.vid/run"
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
newid() { printf '%s-%s\n' "$(date -u '+%Y%m%dT%H%M%SZ')" "$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')"; }
headc() { git -C "$HP" rev-parse --short=12 HEAD 2>/dev/null || echo none; }
field() { sed -n "s/^$1=//p" "$2" | head -n 1; }
# writerun <parent> <parent-start> <copied-at>: a new .vid/run, written whole
writerun() {
  mkdir -p "$HP/.vid"
  printf 'id=%s\npath=%s\nstart=%s\nparent=%s\nparent-start=%s\ncopied-at=%s\ncreated=%s\nteam=unknown\nseries=unknown\n' \
    "$(newid)" "$HP" "$(headc)" "$1" "$2" "$3" "$(utc)" > "$RF.tmp.$$" && mv "$RF.tmp.$$" "$RF"
}
# renew <copied-at>: a new id whose parent is the current one, the current file kept as .vid/run.parent
renew() { cp "$RF" "$HP/.vid/run.parent"; writerun "$(field id "$RF")" "$(field start "$RF")" "$1"; }
case "${1:-}" in
  id)
    if [ ! -f "$RF" ]; then writerun - - -
    elif [ "$(field path "$RF")" != "$HP" ]; then renew "$(headc)"; fi
    field id "$RF" ;;
  new)
    if [ -f "$RF" ]; then renew -; else writerun - - -; fi
    echo "ViD run: new trial $(field id "$RF") (parent $(field parent "$RF"))" ;;
  label)
    shift; [ $# -ge 1 ] || usage
    [ -f "$RF" ] || { echo 'ViD run: refused — no .vid/run yet; the run id is made at the first `stage … state=start` event.' >&2; exit 1; }
    cp "$RF" "$RF.tmp.$$"
    for kv in "$@"; do
      k=${kv%%=*}; v=${kv#*=}
      case "$k" in team|series) ;; *) rm -f "$RF.tmp.$$"; usage ;; esac
      case "$v" in ''|*[!A-Za-z0-9._-]*) rm -f "$RF.tmp.$$"; echo "ViD run: refused — $k= is one word of letters, digits, '.', '_' or '-'." >&2; exit 2 ;; esac
      grep -v "^$k=" "$RF.tmp.$$" > "$RF.tmp2.$$" || true; printf '%s=%s\n' "$k" "$v" >> "$RF.tmp2.$$"; mv "$RF.tmp2.$$" "$RF.tmp.$$"
    done
    mv "$RF.tmp.$$" "$RF"
    echo "ViD run: $(field id "$RF") — team=$(field team "$RF") series=$(field series "$RF")" ;;
  *) usage ;;
esac
