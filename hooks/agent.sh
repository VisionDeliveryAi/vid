# Purpose: ViD's shared readers for the plugin's agent-aware hooks (v0.9.7.0.7 spec 3.6, 3.7) —
# sourced by hooks/reread.sh and hooks/net.sh, never run alone; `keys`, `kv` and
# `jesc` moved here from reread.sh (v0.9.7.0.6 3.8) unchanged.
#   keys <k>…      one `<key>\t<value>` line for each key's first occurrence in $IN, the hook's
#                  input: a key is taken only where it follows `{` or `,` (text inside a JSON
#                  string never shows one unescaped); a string is unescaped. Exits 1 on input
#                  whose brackets outside strings do not balance.
#   kv <key>       a value from $KV (keys' output).
#   jesc <text>    the text as a JSON string's inside.
#   vid_agent_transcript <home> <agent id> [<fallback>]   the agent's own transcript: from the
#                  home's latest `agent-start agent=<id> … transcript=<parent>` (hooks/record.sh),
#                  <parent without .jsonl>/subagents/agent-<id>.jsonl; else <fallback> when its
#                  name is agent-<id>.jsonl; nothing when neither is readable.
#   vid_brief_path <home> <transcript>   (v0.9.8.1 R14) the brief path below, for any role, relative to the home.
#   vid_agent_brief <home> <transcript>   the agent's brief, when its role is builder or fixer:
#                  the first `.vid/briefs/<slice>/<role>-<n>.md` path in the transcript's first
#                  user entry, read as a path under the home, printed absolute when that file
#                  exists; nothing otherwise (another role, no path, no file).
#   vid_context <transcript>   the agent's latest API context — its last assistant entry's
#                  input_tokens + cache_read_input_tokens + cache_creation_input_tokens, as
#                  `sh checks/brief.sh return` counts each call (3.3); nothing when no entry
#                  carries usage. Only the file's last 200 lines are read.
keys() {
  printf '%s' "$IN" | awk -v keys="$(printf '%s ' "$@")" 'BEGIN { RS = "\001"; nk = split(keys, K, " ") }
    { s = $0; t = s; gsub(/"([^"\\]|\\.)*"/, "", t); o = gsub(/[{[]/, "", t); c = gsub(/[]}]/, "", t)
      if (o == 0 || o != c) exit 1
      for (i = 1; i <= nk; i++) {
        if (!match(s, "[{,][ \t\r\n]*\"" K[i] "\"[ \t\r\n]*:[ \t\r\n]*")) continue
        r = substr(s, RSTART + RLENGTH)
        if (substr(r, 1, 1) == "\"") { v = ""; j = 2
          while (1) { ch = substr(r, j, 1); if (ch == "" || ch == "\"") break
            if (ch == "\\") { e = substr(r, j + 1, 1); if (e == "n" || e == "t" || e == "r") v = v " "; else v = v e; j += 2; continue }
            v = v ch; j++ }
        } else { match(r, /^[^],} \t\r\n]*/); v = substr(r, 1, RLENGTH) }
        print K[i] "\t" v } }'
}
kv() { printf '%s\n' "$KV" | awk -F'\t' -v k="$1" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }'; }
jesc() { printf '%s' "$1" | awk 'BEGIN { RS = "\001" } { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\n/, " "); printf "%s", $0 }'; }
vid_agent_transcript() {
  _ap=''; [ -f "$1/.vid/metrics-events" ] && _ap=$(awk -v a="agent=$2" '$1 == "agent-start" { hit = 0; for (i = 2; i <= NF; i++) if ($i == a) hit = 1; if (!hit) next
      p = index($0, " transcript="); if (!p) next; t = substr($0, p + 12); if (substr(t, 1, 1) == "\"") { t = substr(t, 2); q = index(t, "\""); t = substr(t, 1, q - 1) } else sub(/ .*/, "", t); last = t } END { print last }' "$1/.vid/metrics-events")
  case "$_ap" in ''|-) ;; *) _at="${_ap%.jsonl}/subagents/agent-$2.jsonl"; [ -r "$_at" ] && { printf '%s\n' "$_at"; return 0; } ;; esac
  case "${3:-}" in */agent-"$2".jsonl) [ -r "$3" ] && printf '%s\n' "$3" ;; esac
  return 0
}
# v0.9.8.1 (R14): the lookup apart from its role gate — vid_brief_path prints the brief path, relative to the home,
# for any role; vid_agent_brief keeps the builder and fixer gate the context net uses
vid_brief_path() {
  [ -r "$2" ] || return 0
  _ab=$(awk 'index($0, "\"type\":\"user\"") { print; exit }' "$2" | grep -o '\.vid/briefs/[^/"\\ ]*/[a-z-]*-[0-9]*\.md' | head -n 1)
  [ -n "$_ab" ] && [ -f "$1/$_ab" ] && printf '%s\n' "$_ab"
  return 0
}
vid_agent_brief() {
  _ab=$(vid_brief_path "$1" "$2")
  case "${_ab##*/}" in builder-*|fixer-*) printf '%s/%s\n' "$1" "$_ab" ;; esac
  return 0
}
vid_context() {
  tail -n 200 "$1" 2>/dev/null | awk '
    function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
    index($0, "\"role\":\"assistant\"") && (u = index($0, "\"usage\":{")) { s = substr($0, u); c = num(s, "input_tokens") + num(s, "cache_read_input_tokens") + num(s, "cache_creation_input_tokens"); any = 1 }
    END { if (any) print c }'
}
