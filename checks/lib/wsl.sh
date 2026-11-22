#!/bin/sh
# Purpose: ViD on native Windows — the WSL notice and the route (0.26.10.29.3, R6; 0.26.11.1.3, R2). ViD runs on a native
# Windows shell (Git Bash, MSYS, Cygwin: `uname -s` starting MINGW, MSYS or CYGWIN), only more slowly, since starting a
# process is slow there. The route is on unless the owner turns it off: once per machine ViD checks that WSL starts
# (`wsl.exe` on the PATH runs `sh -c true`) and records the answer in .vid/windows (`wsl: yes` or `wsl: no`,
# untracked) at the main checkout, the parent of `git rev-parse --git-common-dir` (outside a repository, this
# directory), so builder worktrees, agents and a second session follow the same answer. Nothing is asked: the owner
# changes the answer by editing that file, and ViD never checks again while it exists.
# Two uses:
#   sh checks/lib/wsl.sh notice         on a native Windows shell with no answer recorded: probes WSL once, records
#                                       `wsl: yes`, or `wsl: no` with a `# WSL did not start <UTC>` line, and prints
#                                       one line saying so and how to change it. Prints nothing anywhere else, and on
#                                       every later call. Exit 0; 1 when the answer cannot be written.
#                                       (0.26.11.1.3, R2: it replaces the question, `ask` and `record`, which are cut.)
#                                       FB-1 D2: once across sessions: before the probe it claims `<answer file>.claim`
#                                       by an exclusive create (set -C), the answer file untouched, so a court started
#                                       meanwhile reads no answer, as before. A call that loses the claim exits silently;
#                                       the winner reads the answer again (another session may have answered since its
#                                       first read), and with one there removes its claim and exits silently, else
#                                       probes, writes and prints as above, then removes the claim. A claim older than
#                                       2 minutes (a call stopped during the probe) is taken over by a rename to a name
#                                       of the call's own, which one call alone wins, and claimed again.
#   sourced at the top of a court       (the courts the agents and skills run directly: prd, inventory,
#                                       design-join, imports, seams, stages) re-runs that court under WSL when the
#                                       answer is `wsl: yes` (with no file yet, natively): `wsl.exe -e sh <court>
#                                       <args>`, an argument naming an existing file or folder translated by
#                                       `wslpath -a` inside WSL. Standard input,
#                                       output and the exit code pass through; nothing is added to standard output.
#                                       It does nothing under a git hook (GIT_INDEX_FILE or GIT_DIR set: the hook's
#                                       git setting cannot be carried across), inside WSL, on macOS and on Linux.
#                                       When wsl.exe fails before the court starts — it does not run, or the
#                                       court or a file argument is not there at its translated path (a drive WSL
#                                       does not mount) — the court runs natively and says so once on standard error; VID_WSL_FAILED=1 is exported, so a court
#                                       it starts runs natively without saying it again. ViD's own VID_* settings
#                                       cross through WSLENV. Not routed: observe.sh and run.sh, which read process
#                                       ids and record absolute paths, both of which differ between the two sides.
# One more use, the same mechanism for another per-machine answer (0.26.10.29.3 phase 2, R5):
#   sh checks/lib/wsl.sh reviewers ask           prints the second-reviewer question when `codex` is on the PATH and
#                                                no answer is in .vid/reviewers (beside .vid/windows); else nothing.
#   sh checks/lib/wsl.sh reviewers record yes|no writes `codex: yes|no` there and says where. Exit 2 on another word.
#   sh checks/lib/wsl.sh reviewers               prints `yes` (recorded yes and `codex` on the PATH), `no`, or
#                                                nothing (codex here, no answer yet).
# A court sources it with one line, `_vidwsl=${0%/*}/lib/wsl.sh; [ ! -f "$_vidwsl" ] || . "$_vidwsl"`, so a court
# copied without lib/ (a case's scratch copy) runs natively as before.
# serves: both (0.26.10.29.3, R6)
VID_CODEX_Q='A second model, Codex, is installed on this machine. May ViD use it as a second reviewer beside its own?'
vid_wsl_native_windows() { case $(uname -s 2>/dev/null) in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac; return 1; }
# Git for Windows and MSYS2 rewrite arguments that look like POSIX paths on their way to a Windows program; off for wsl.exe.
vid_wsl_exe() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' wsl.exe "$@"; }
vid_wsl_file() { # the answer's file: .vid/windows at the main checkout
  _vw_top=$(git rev-parse --show-toplevel 2>/dev/null) || _vw_top=''
  if [ -n "$_vw_top" ]; then
    _vw_c=$(cd "$_vw_top" && git rev-parse --git-common-dir 2>/dev/null) || _vw_c=.git
    case $_vw_c in /*|[A-Za-z]:[/\\]*) ;; *) _vw_c=$_vw_top/$_vw_c ;; esac
    _vw_m=$(cd "$_vw_c/.." 2>/dev/null && pwd) || _vw_m=$_vw_top
  else _vw_m=$(pwd); fi
  printf '%s/.vid/windows\n' "$_vw_m"
}
vid_wsl_answer() { # $1 the file, $2 its key (default wsl) → yes | no | '' (none recorded)
  [ -f "$1" ] || { printf '\n'; return 0; }
  _vw_a=no; _vw_k=${2:-wsl}
  while IFS= read -r _vw_l || [ -n "$_vw_l" ]; do
    case $_vw_l in "$_vw_k":*) _vw_w=${_vw_l#"$_vw_k":}; _vw_w=${_vw_w#"${_vw_w%%[![:space:]]*}"}
      case $_vw_w in yes|yes[[:space:]]*) _vw_a=yes ;; *) _vw_a=no ;; esac ;; esac
  done < "$1"
  printf '%s\n' "$_vw_a"
}
# Every call is `wsl.exe -e …` (--exec): the command runs as given, not re-read by the distribution's login shell, so
# an argument holding a space stays one argument and the probe's small script reaches `sh` whole.
vid_wsl_available() { command -v wsl.exe > /dev/null 2>&1 && vid_wsl_exe -e sh -c true < /dev/null > /dev/null 2>&1; }
# $1 a native path, $2 the test it must pass inside WSL (-r readable, -e there) → its WSL path, or fail. One WSL start
# translates and tests: a path WSL translates but cannot reach (the project on a network or mapped drive WSL does not
# mount) fails here, before the court is handed over. The script holds no double quote, so no Windows quoting rule
# touches it: with IFS empty and `set -f` its bare $1, $2 and $p are never split or matched against file names.
vid_wsl_path() {
  _vw_p=$1
  if command -v cygpath > /dev/null 2>&1; then _vw_p=$(cygpath -w "$1" 2>/dev/null) || _vw_p=$1; fi
  vid_wsl_exe -e sh -c "set -f; IFS=; p=\$(wslpath -a \$1) && [ \$2 \$p ] && printf '%s\n' \$p" vid-wsl "$_vw_p" "$2" < /dev/null 2>/dev/null
}
vid_wsl_failed() { echo "ViD: WSL did not start, so this check runs natively (slower)." >&2; VID_WSL_FAILED=1; export VID_WSL_FAILED; }
vid_wsl_route() { # the court's arguments
  [ -z "${GIT_INDEX_FILE:-}" ] && [ -z "${GIT_DIR:-}" ] || return 0
  [ -z "${VID_WSL_FAILED:-}" ] || return 0   # a court this one starts, after WSL failed: native, and said once
  vid_wsl_native_windows || return 0
  command -v wsl.exe > /dev/null 2>&1 || return 0
  [ "$(vid_wsl_answer "$(vid_wsl_file)")" = yes ] || return 0
  # the court's own path, translated and shown readable inside WSL: the proof that WSL starts and can run this court
  _vw_s=$(vid_wsl_path "$0" -r) && [ -n "$_vw_s" ] || { vid_wsl_failed; return 0; }
  _vw_n=$#; _vw_i=0
  while [ "$_vw_i" -lt "$_vw_n" ]; do
    _vw_x=$1; shift
    if [ -e "$_vw_x" ]; then _vw_t=$(vid_wsl_path "$_vw_x" -e) && [ -n "$_vw_t" ] || { vid_wsl_failed; return 0; }
    else _vw_t=$_vw_x; fi
    set -- "$@" "$_vw_t"; _vw_i=$((_vw_i + 1))
  done
  # ViD's own settings (VID_*) cross with the court; WSL passes only the variables WSLENV names
  for _vw_v in $(env | sed -n 's/^\(VID_[A-Za-z0-9_]*\)=.*/\1/p'); do WSLENV="${WSLENV:+$WSLENV:}$_vw_v"; done
  [ -z "${WSLENV:-}" ] || export WSLENV
  # from here the court is WSL's: a failure in the short time between the probe above and this start (WSL stopping,
  # the drive going away) is not caught, and the court's exit code is then wsl.exe's
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' exec wsl.exe -e sh "$_vw_s" "$@"
}
case ${0##*/} in
  wsl.sh)
    case ${1:-} in
      notice)
        vid_wsl_native_windows || exit 0
        _vw_f=$(vid_wsl_file); [ -z "$(vid_wsl_answer "$_vw_f")" ] || exit 0
        mkdir -p "${_vw_f%/*}" || exit 1
        # FB-1 D2: the claim, so two sessions in the probe's window print once; an old one is a call stopped mid-probe
        _vw_cl=$_vw_f.claim
        # an old claim is taken over by a rename to this call's own name, which one call alone wins; a fresh claim moved by a
        # call that found it old a moment before is put back, and that call exits
        if [ -n "$(find "$_vw_cl" -mmin +2 2>/dev/null)" ]; then
          mv "$_vw_cl" "$_vw_cl.old.$$" 2>/dev/null || exit 0
          [ -n "$(find "$_vw_cl.old.$$" -mmin +2 2>/dev/null)" ] || { mv "$_vw_cl.old.$$" "$_vw_cl" 2>/dev/null || rm -f "$_vw_cl.old.$$"; exit 0; }
          rm -f "$_vw_cl.old.$$"
        fi
        ( set -C; : > "$_vw_cl" ) 2>/dev/null || exit 0
        [ -z "$(vid_wsl_answer "$_vw_f")" ] || { rm -f "$_vw_cl"; exit 0; }
        if vid_wsl_available; then
          printf 'wsl: yes\n' > "$_vw_f" || { rm -f "$_vw_cl"; exit 1; }
          printf 'ViD runs its checks through WSL on this PC, which is much faster. To stop it, change `wsl: yes` to `wsl: no` in `%s`.\n' "$_vw_f"
        else
          printf 'wsl: no\n# WSL did not start %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$_vw_f" || { rm -f "$_vw_cl"; exit 1; }
          printf 'WSL did not start on this PC, so ViD runs its checks natively, more slowly. Once WSL works, delete `%s` and ViD will check again.\n' "$_vw_f"
        fi
        rm -f "$_vw_cl"; exit 0 ;;
      reviewers) # 0.26.10.29.3 (phase 2 R5): the Codex answer, kept and read as the WSL answer is, in .vid/reviewers
        _vw_f=$(vid_wsl_file); _vw_f=${_vw_f%/windows}/reviewers
        _vw_c=no; command -v codex > /dev/null 2>&1 && _vw_c=yes
        case ${2:-} in
          ask) [ "$_vw_c" = yes ] && [ -z "$(vid_wsl_answer "$_vw_f" codex)" ] && printf '%s\n' "$VID_CODEX_Q"; exit 0 ;;
          record) case ${3:-} in yes|no) ;; *) echo "ViD reviewers: record takes yes or no, got '${3:-}'." >&2; exit 2 ;; esac
            mkdir -p "${_vw_f%/*}" && printf 'codex: %s\n' "$3" > "$_vw_f" || exit 1
            echo "ViD reviewers: codex: $3 recorded in $_vw_f (this machine only; edit the file to change it)."; exit 0 ;;
          '') [ "$_vw_c" = yes ] || { echo no; exit 0; }; vid_wsl_answer "$_vw_f" codex; exit 0 ;;
        esac
        echo 'ViD reviewers: usage — sh checks/lib/wsl.sh reviewers [ask | record yes|no]' >&2; exit 2 ;;
      *) echo 'ViD wsl: usage — sh checks/lib/wsl.sh notice | reviewers [ask | record yes|no]' >&2; exit 2 ;;
    esac ;;
  *) vid_wsl_route "$@" ;;
esac
