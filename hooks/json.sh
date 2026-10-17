# Purpose: ViD's JSON reader for the plugin's hooks (v0.9.6.2 spec 3.2) —
# sourced by hooks/stop-failure.sh and hooks/record.sh, never run alone. A
# hook's input is JSON on stdin, read with POSIX tools only: a scanner walks
# it character by character, strings and escapes included, and takes a key
# only at the top level of the object, so compact and pretty-printed input
# both parse and text inside a string value can never be taken for a key.
#   json_fields   reads the JSON on stdin; prints one `<key>\t<value>` line
#                 per top-level key (a string value unescaped, tabs and line
#                 breaks as spaces; any other value empty); exits 1 when the
#                 brackets do not balance (the input does not parse).
#   jget <key>    the value of <key> in $F (json_fields's output), or nothing.
#   jhas <key>    exit 0 when $F holds <key>.
json_fields() {
  awk 'BEGIN { RS = "\001" }
    { s = $0; n = length(s); i = 1; depth = 0; mode = ""
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\"") {
          j = i + 1; v = ""
          while (j <= n) {
            d = substr(s, j, 1)
            if (d == "\\") { e = substr(s, j + 1, 1)
              if (e == "n" || e == "t" || e == "r") v = v " "; else if (e == "u") { v = v "?"; j += 4 } else v = v e
              j += 2; continue }
            if (d == "\"") break
            v = v d; j++
          }
          if (depth == 1 && mode == "key") { k = v; seen[k] = 1; mode = "colon" }
          else if (depth == 1 && mode == "value") { val[k] = v; mode = "after" }
          i = j + 1; continue
        }
        if (c == "{" || c == "[") { if (depth == 1 && mode == "value") mode = "after"; depth++; if (depth == 1) mode = "key" }
        else if (c == "}" || c == "]") depth--
        else if (c == "," && depth == 1) mode = "key"
        else if (c == ":" && depth == 1 && mode == "colon") mode = "value"
        else if (depth == 1 && mode == "value" && c !~ /[ \t\r\n]/) mode = "after"
        i++
      }
      if (depth != 0) exit 1
      for (k in seen) { v = val[k]; gsub(/[\t\n\r]/, " ", v); printf "%s\t%s\n", k, v }
    }'
}
jget() { printf '%s\n' "$F" | awk -F'\t' -v k="$1" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }'; }
jhas() { printf '%s\n' "$F" | awk -F'\t' -v k="$1" '$1 == k { f = 1 } END { exit f ? 0 : 1 }'; }
