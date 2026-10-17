# Purpose: selftest fixture — the test analyst's trigger cases (v0.9.7.0.3
# spec 3.1, §6 A-1…A-6). Sourced after gated-run.sh and plan-run.sh (Env:
# CHECKS, T). report <file> <case>=<status>:<seconds> …: a report the toy
# results reader reads (`case <id> <status> <seconds>`) and that
# checks/evidence.sh red groups by message, each red case carrying its own
# message (m1, m2, …), or the one given as <case>=<status>:<seconds>:<message>
# (v0.9.8.1); each testcase is named as its case id. ask <report> <request arguments…>: makes the
# request with that report, waits for it, and prints its ticket; the
# result is in $T/res.
report() {
  _f=$1; shift; _i=0
  { printf '<report>\n'
    for _kv in "$@"; do _i=$((_i + 1)); _c=${_kv%=*}; _s=${_kv##*=}; _st=${_s%%:*}; _sec=${_s#*:}; _mm=m$_i
      case $_sec in *:*) _mm=${_sec#*:}; _sec=${_sec%%:*} ;; esac   # v0.9.8.1: <case>=<status>:<seconds>:<message> gives the message
      _m=''; [ "$_st" = failed ] && _m="<failure message=\"$_mm\"/>"
      printf '<testcase name="%s" classname="%s"><case name="%s" status="%s" time="%s"/>%s</testcase>\n' "${_c#*::}" "${_c%%::*}" "$_c" "$_st" "$_sec" "$_m"; done
    printf '</report>\n'; } > "$_f"
}
ask() {
  _r=$1; shift
  STUB_REPORT=$_r sh checks/test.sh request "$@" > "$T/ask" 2>&1 || { cat "$T/ask" >&2; return 1; }
  _k=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/ask")
  VID_WAIT_MAX=60 sh checks/test.sh wait "$_k" > "$T/res" 2>&1 || true
  printf '%s\n' "$_k"
}
# due <ticket>: the analyst-due events of that ticket, at the home
due() { grep "^analyst-due request=$1 " .vid/metrics-events 2>/dev/null || true; }
