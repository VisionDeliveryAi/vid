# Purpose: ViD's run finder for the plugin's hooks (v0.9.7.0.6 spec 3.4,
# 3.8: one home resolver) — sourced by hooks/record.sh, hooks/reentry.sh,
# hooks/reread.sh and (v0.9.7.0.7) hooks/net.sh, never
# run alone; moved here from record.sh unchanged.
#   vid_home <cwd>   prints the run's home, or nothing. In order: from <cwd>,
#                    the nearest directory holding .vid/, walking up no
#                    further than that directory's git toplevel (outside a
#                    repository, <cwd> alone); then $CLAUDE_PROJECT_DIR; then
#                    through that .vid/home to the run's home, when the path
#                    it names holds .vid/RUN-STATE.md. v0.9.7.0.1 (3.1, R4):
#                    then, when that directory's git top level (with no .vid/
#                    found: the cwd's) has checks/plan.sh, its `home-of`
#                    answer, when it prints one — so an agent's fresh worktree
#                    resolves to the one live run; any failure, or a plan.sh
#                    older than home-of, keeps the result above.
#   vid_near <cwd>   exit 0 when a .vid/ directory exists walking up from
#                    <cwd> to the root, or at $CLAUDE_PROJECT_DIR — the cheap
#                    test before the resolver (3.8, fast exit 2).
vid_home() {
  _hc=$1; _hd=''; _ht=''
  if [ -n "$_hc" ] && [ -d "$_hc" ]; then
    _ht=$(git -C "$_hc" rev-parse --show-toplevel 2>/dev/null || true)
    _hw=$(cd "$_hc" && pwd -P); [ -n "$_ht" ] && _ht=$(cd "$_ht" && pwd -P)
    while [ -n "$_hw" ]; do
      if [ -d "$_hw/.vid" ]; then _hd=$_hw; break; fi
      { [ -z "$_ht" ] || [ "$_hw" = "$_ht" ] || [ "$_hw" = / ]; } && break
      _hw=$(dirname "$_hw")
    done
  fi
  if [ -z "$_hd" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.vid" ]; then _hd=$CLAUDE_PROJECT_DIR; fi
  if [ -n "$_hd" ] && [ ! -f "$_hd/.vid/RUN-STATE.md" ] && [ -f "$_hd/.vid/home" ]; then
    _hh=$(sed -n 1p "$_hd/.vid/home"); if [ -n "$_hh" ] && [ -f "$_hh/.vid/RUN-STATE.md" ]; then _hd=$_hh; fi
  fi
  _hb=${_hd:-$_ht}; _hbt=''
  [ -n "$_hb" ] && _hbt=$(git -C "$_hb" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$_hbt" ] && [ -f "$_hbt/checks/plan.sh" ]; then
    _hh=$(cd "$_hbt" && sh checks/plan.sh home-of 2>/dev/null) && [ -n "$_hh" ] && [ -d "$_hh/.vid" ] && _hd=$_hh
  fi
  [ -n "$_hd" ] && printf '%s\n' "$_hd"
  return 0
}
vid_near() {
  [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.vid" ] && return 0
  [ -n "$1" ] && [ -d "$1" ] || return 1
  _nw=$(cd "$1" && pwd -P) || return 1
  while :; do
    [ -d "$_nw/.vid" ] && return 0
    [ "$_nw" = / ] && return 1
    _nw=$(dirname "$_nw")
  done
}
