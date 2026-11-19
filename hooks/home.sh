# Purpose: ViD's run finder for the plugin's hooks (v0.9.7.0.6 spec 3.4,
# 3.8: one home resolver) — sourced by hooks/record.sh, hooks/reentry.sh,
# hooks/reread.sh, (v0.9.7.0.7) hooks/net.sh and (0.26.11.1.3) hooks/stop-failure.sh and hooks/waits.sh, never
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
#                    test before the resolver (3.8, fast exit 2). From 0.26.11.1.3
#                    (R1) it normalises <cwd> once, with cd and pwd -P (which
#                    also turns a Windows C:\… path into the shell's form), into
#                    VID_CW, and every walk here climbs with ${d%/*}: no
#                    process at all.
#   vid_reach <cwd>  (0.26.11.1.3, R1) the cheap test before the resolver for
#                    hooks/record.sh and hooks/reentry.sh: vid_near, or else the
#                    checkout top holding <cwd> (the nearest folder with .git)
#                    has checks/plan.sh, whose home-of may still find the live
#                    run for a worktree with no .vid/. No process either way.
#   vid_plain        (0.26.11.1.3, R1) after vid_near: exit 0, the home in VID_H,
#                    when the home is plain — walking up from VID_CW, no
#                    further than the first folder holding .git (where the
#                    resolver's git would stop), the nearest .vid/ sits in that
#                    checkout's top and holds RUN-STATE.md, or holds `home`
#                    naming a checkout top whose .vid/ holds RUN-STATE.md.
#                    plan.sh home-of answers the same there (its steps 1 and
#                    2), so no git and no nested plan.sh run. Anything else
#                    exits 1, and the caller runs vid_home, as before.
vid_home() {
  _hc=$1; _hd=''; _ht=''
  if [ -n "$_hc" ] && [ -d "$_hc" ]; then
    _ht=$(git -C "$_hc" rev-parse --show-toplevel 2>/dev/null || true)
    _hw=$(cd "$_hc" && pwd -P); [ -n "$_ht" ] && _ht=$(cd "$_ht" && pwd -P)
    while [ -n "$_hw" ]; do
      if [ -d "$_hw/.vid" ]; then _hd=$_hw; break; fi
      { [ -z "$_ht" ] || [ "$_hw" = "$_ht" ] || [ "$_hw" = / ]; } && break
      _hw=${_hw%/*}; [ -n "$_hw" ] || _hw=/
    done
  fi
  if [ -z "$_hd" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.vid" ]; then _hd=$CLAUDE_PROJECT_DIR; fi
  if [ -n "$_hd" ] && [ ! -f "$_hd/.vid/RUN-STATE.md" ] && [ -f "$_hd/.vid/home" ]; then
    _hh=''; IFS= read -r _hh < "$_hd/.vid/home" || :; if [ -n "$_hh" ] && [ -f "$_hh/.vid/RUN-STATE.md" ]; then _hd=$_hh; fi
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
  VID_CW=''; [ -n "$1" ] && [ -d "$1" ] && VID_CW=$(cd "$1" && pwd -P) || VID_CW=''
  [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.vid" ] && return 0
  _nw=$VID_CW; [ -n "$_nw" ] || return 1
  while :; do
    [ -d "$_nw/.vid" ] && return 0
    [ "$_nw" = / ] && return 1
    _nw=${_nw%/*}; [ -n "$_nw" ] || _nw=/
  done
}
vid_reach() {
  vid_near "$1" && return 0
  _rw=$VID_CW; [ -n "$_rw" ] || return 1
  while [ ! -e "$_rw/.git" ]; do [ "$_rw" = / ] && return 1; _rw=${_rw%/*}; [ -n "$_rw" ] || _rw=/; done
  [ -f "$_rw/checks/plan.sh" ]
}
vid_plain() {
  VID_H=''; _pw=$VID_CW; [ -n "$_pw" ] || return 1
  while [ ! -d "$_pw/.vid" ]; do
    { [ -e "$_pw/.git" ] || [ "$_pw" = / ]; } && return 1
    _pw=${_pw%/*}; [ -n "$_pw" ] || _pw=/
  done
  [ -e "$_pw/.git" ] || return 1
  if [ -f "$_pw/.vid/RUN-STATE.md" ]; then VID_H=$_pw; return 0; fi
  [ -f "$_pw/.vid/home" ] || return 1
  _ph=''; IFS= read -r _ph < "$_pw/.vid/home" || :
  [ -n "$_ph" ] && [ -e "$_ph/.git" ] && [ -f "$_ph/.vid/RUN-STATE.md" ] || return 1
  VID_H=$_ph
}
