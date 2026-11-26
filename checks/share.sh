#!/bin/sh
# Purpose: ViD's share bundle (0.26.10.28.7, stage 3, R2 to R4) — one run's records, a named logs folder and the run's
# Claude Code transcripts, packed in the findings repository's layout (version 1), every file redacted and the whole
# bundle scanned after. It READS the project and writes only its own output folder, .vid/shares/ at the run's home
# (.vid/home followed, as the export does). It sends nothing: the verb shows the summary and asks; the push is github.sh's.
# serves: both
#
# Usage:
#   sh checks/share.sh build [--run <name>] [--logs <folder>] [--session <path|id>]... [--redact-file <file>]
#                            [--leave-out conversations|logs]...
#   sh checks/share.sh scan <folder>
#   sh checks/share.sh pack <folder>
#
# build    writes the bundle to .vid/shares/<run>/ and its summary to .vid/shares/<run>.summary, replacing an earlier
#          bundle of the same run name (ViD's own output; nothing else is touched).
#   --run <name>          the run's folder name; default <yyyy-mm>-<mode>-<short name>: the month of the run's first
#                         event, its mode (local-auto, github-auto, github-manual; FB-1 C1) and the project folder's name in
#                         lowercase letters, digits and hyphens. Letters, digits, '.', '_' and '-' only.
#   --logs <folder>       a dev-side folder copied to logs/, its clones, blind copies, checkouts and trees left out, and in the two GitHub modes its package stores and caches.
#   --session <path|id>   a further session: a transcript's exact path, or a session id found as <id>.jsonl in a
#                         folder of the Claude projects folder (repeatable). Never a whole folder, never a prefix.
#   --redact-file <file>  literal strings to redact, one a line ([REDACTED:literal]); read, never copied.
#   --leave-out <part>    conversations or logs: that part is not written, and the manifest says why (repeatable).
#          Exit 0 when the bundle is written and its scan is clean; 1 when the scan found something left (the bundle
#          stays, for the user to look at, and the summary says so); 2 on a usage error.
#
# scan     reads every file of <folder> back, whatever its name (gzipped, split and orphan parts included), and every
#          path, for every kind redaction covers; the personal values it needs are in <folder>.known, beside it, written
#          by build (never inside the bundle). Prints one line a finding, `<file>\t<kind>\t<count>`, never the value.
#          Exit 0 when nothing is left, 1 when anything is, a gzip does not unzip, <folder> is not a bundle or has no
#          .known beside it (the personal kinds cannot be checked), 2 on a usage error.
#
# pack     scans <folder> first and refuses on anything left; then writes <folder>.tar.gz beside it, one archive file
#          holding the folder under its own name, and prints its path. Exit 0 on success, 1 on a refusal.
#
# The summary, .vid/shares/<run>.summary: one item a line, the key first, its fields tab-separated, every line redacted
# but folder's, which is relative to the project (no home path in it), in this order:
#   summary        1                                   the summary's version
#   folder         .vid/shares/<run>, the bundle's path relative to the project
#   size           <bytes>                             the whole bundle
#   project        <project's short name>
#   run            <run name>
#   mode           local-auto | github-auto | github-manual
#   part           <records|logs|conversations|docs> <file count>   one line a part written; docs are RUN.md,
#                                                      FINDINGS.md, findings/, MANIFEST.json and MANIFEST.md
#   redacted       <kind> <count>                      one line a kind found, the kinds as MANIFEST.json names them
#   left-out       <path or part> <why>                one line each: a clone, an object store, an earlier export, a
#                                                      binary, a link, a part left out at the user's request
#   missing        <session id> <why>                  a transcript named but not readable (conversations/MISSING.md)
#   split          <path> <parts>                      a file over the size limit, cut into <path>.part-000 …
#   scan           clean | found <count>
#   limit          <one line of plain words>           that a pattern catches only what it knows
#   caught-certain <one line>                          SHARE-SCRUB §5: what is caught for certain,
#   caught-by-rule <one line>                          what by rule (a value in another form passes),
#   not-caught     <one line>                          and what is not caught at all
#   review         .vid/shares/<run>.review <prompts> <data files>   the review page, beside the bundle, never in it
#
# 0.26.11.2 (SHARE-SCRUB): beside the bundle, never in it, readable by the user alone: <run>.known (the personal values and, by
# path alone, the dotenv files the scan reads again; never a secret value) and <run>.review (what the user typed in the main
# sessions and the product data files the conversations touched, read from the redacted bundle). A file that holds secrets by its
# name (.env, .env.*, *.env, .envrc, *.pem, *.key, *.p12, *.pfx, id_rsa, id_dsa, id_ecdsa, id_ed25519, .netrc, .pgpass,
# credentials, credentials.*) is never copied. A project name redaction changes becomes `project`, and a run name it changes is
# refused. pack's archive holds no user or group name.
set -eu
TAB=$(printf '\t')
usage() {
  echo 'ViD share: usage — sh checks/share.sh build [--run <name>] [--logs <folder>] [--session <path|id>]... [--redact-file <file>] [--leave-out conversations|logs]... | scan <folder> | pack <folder>' >&2
  exit 2
}
die() { echo "ViD share: $*" >&2; exit 1; }
SPLIT=${VID_SHARE_SPLIT_BYTES:-99614720}   # 95 MiB, under GitHub's 100 MiB push limit; the variable exists for the self-test
MNT=${VID_SHARE_MOUNT:-/mnt}               # where a Windows drive is mounted under WSL; the variable exists for the self-test
CFG=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
size() { wc -c < "$1" | tr -d ' '; }
# lo <path> <why>: a left-out row; ms <session> <why>: a missing row (the path, for MISSING.md, in a third field)
lo() { printf '%s\t%s\n' "$1" "$2" >> "$W/leftout"; }
ms() { printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >> "$W/missing"; }
# add <bundle path> <source file> <class>: one file to write; class rec, log, conv or doc decides its gzip
add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$W/list"; [ ! -f "$W/list.c" ] || printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$2" >> "$W/list.c"; }
# src <bundle path> <root name> <path from the root> <how>: a source row of the manifest
src() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$W/sources"; }

# the run's home, as checks/export.sh finds it: the top level, through .vid/home to the run's home
findhome() {
  TOP=$(git rev-parse --show-toplevel 2>/dev/null) || TOP=$(pwd -P)
  H=$TOP
  if [ ! -f "$TOP/.vid/RUN-STATE.md" ] && [ -f "$TOP/.vid/home" ]; then
    _h=$(sed -n 1p "$TOP/.vid/home"); if [ -n "$_h" ] && [ -f "$_h/.vid/RUN-STATE.md" ]; then H=$_h; fi
  fi
  H=$(cd "$H" && pwd -P)
  [ -d "$H/.vid" ] || die "refused — $H has no .vid/; nothing to share."
}

# walk <root> <bundle prefix> <class> <records|logs>: every file under root into the list, the leave-outs listed.
# Left out by name at any depth: .git, *.git, worktrees, node_modules, __pycache__, clones, blind, trees, checkout,
# runs/*/c, and any folder holding a .git (a clone or a worktree); in .vid/ also code, code.*, spec.git, spec-out (FB-3 B1), exports,
# shares and net.* (the plugin's marker); in the named logs folder (class log), in the two GitHub modes, also each folder named *-store, cache, .cache or
# *-cache, the dev side's package stores and caches (FB-8 E6). Links and special files are left out and listed.
walk() {
  _r=$1; _p=$2; _c=$3; _gm=yes; [ "$MODE" != local-auto ] || _gm=no
  # _pf <find's actions>: find over the root with the left-out names as one test
  if [ "$4" = records ]; then
    _pf() { find . \( -path ./code -o -path './code.*' -o -path ./spec.git -o -path ./spec-out -o -path ./exports -o -path ./shares -o -name 'net.*' \
      -o -name .git -o -name '*.git' -o -name worktrees -o -name node_modules -o -name __pycache__ -o -name clones -o -name blind \
      -o -name trees -o -name checkout -o -path './runs/*/c' \) "$@"; }
  elif [ "$_c:$_gm" = log:yes ]; then
    _pf() { find . \( -type d \( -name '*-store' -o -name cache -o -name .cache -o -name '*-cache' \) -o -name .git -o -name '*.git' -o -name worktrees -o -name node_modules -o -name __pycache__ -o -name clones -o -name blind \
      -o -name trees -o -name checkout -o -path './runs/*/c' \) "$@"; }
  else
    _pf() { find . \( -name .git -o -name '*.git' -o -name worktrees -o -name node_modules -o -name __pycache__ -o -name clones -o -name blind \
      -o -name trees -o -name checkout -o -path './runs/*/c' \) "$@"; }
  fi
  # the names left out, then each folder holding a .git (from the .git found inside it, one find; the root itself never; a .git link
  # to nowhere is no .git, one test a .git link): a path under
  # another left out is not listed again, as find never reached it before
  ( cd "$_r" && { _pf -prune -print; _pf ! -name .git -prune -o -name .git -prune \( ! -type l -o -exec test -e {} \; \) -print | sed -n '/^\.\/\.git$/d; s|/\.git$||p'; } ) | sed 's|^\./||' | LC_ALL=C sort -u |
    awk '{ P[++n] = $0; S[$0] = 1 } END { for (i = 1; i <= n; i++) { x = P[i]; u = 0; while ((k = match(x, /\/[^\/]*$/)) > 0) { x = substr(x, 1, k - 1); if (x in S) { u = 1; break } } if (!u) print P[i] } }' > "$W/pruned"
  awk -v R="$_r" '{ print R "/" $0 }' "$W/pruned" >> "$W/pruned.all"   # SHARE-SCRUB §4.1: their histories name people
  ( cd "$_r" && find . ! -type d -print ) | sed 's|^\./||' | LC_ALL=C sort | awk -v F="$W/pruned" '
    BEGIN { while ((getline l < F) > 0) P[++n] = l }
    { for (i = 1; i <= n; i++) if ($0 == P[i] || index($0, P[i] "/") == 1) next; print }' > "$W/found"
  while IFS= read -r x; do
    case "$_c:$_gm:$x" in log:yes:*-store|log:yes:cache|log:yes:*/cache|log:yes:.cache|log:yes:*/.cache|log:yes:*-cache) lo "$_p/$x" "the dev side's package store or a cache, not a record"; continue ;; esac   # FB-8 E6
    case "$x" in spec.git) why='the spec repository'"'"'s objects' ;; .git) why='a git folder, code' ;; *.git) why='a git object store, code' ;; code|code.*) why="DevAgent's code (a clone), its commits are in the code repository" ;;
      exports) why='earlier exports' ;; shares) why='the share'"'"'s own output' ;;
      *) why='a clone, a checkout or a copy of code, or a folder that is not a record' ;; esac
    lo "$_p/$x" "$why"
  done < "$W/pruned"
  while IFS= read -r x; do
    if [ -f "$_r/$x" ] && [ ! -h "$_r/$x" ]; then add "$_p/$x" "$_r/$x" "$_c"; else lo "$_p/$x" 'a link or a special file, not copied'; fi
  done < "$W/found"
}

# winpath <path>: a C:\… or C:/… path as WSL mounts it, else empty
winpath() {
  case "$1" in [A-Za-z]:[\\/]*) ;; *) return 0 ;; esac
  _d=$(printf '%s' "$1" | cut -c1 | tr 'A-Z' 'a-z'); _rest=$(printf '%s' "$1" | cut -c3- | tr '\\' '/')
  printf '%s/%s%s' "$MNT" "$_d" "$_rest"
}
# resolve <path>: the readable file a recorded transcript path names here, else empty
resolve() {
  if [ -f "$1" ] && [ -r "$1" ]; then printf '%s' "$1"; return 0; fi
  _w=$(winpath "$1"); if [ -n "$_w" ] && [ -f "$_w" ] && [ -r "$_w" ]; then printf '%s' "$_w"; fi
}
# trel <readable transcript path>: its path from the Claude projects folder it sits in, for the manifest
trel() {
  case "$1" in "$CFG/projects/"*) printf 'claude-projects\t%s' "${1#"$CFG/projects/"}"; return 0 ;; esac
  _t=$(printf '%s' "$1" | awk '{ n = split($0, a, "/"); for (i = n - 1; i >= 2; i--) if (a[i] == "projects" && a[i - 1] == ".claude") { s = a[i + 1]; for (j = i + 2; j <= n; j++) s = s "/" a[j]; print s; exit } }')
  if [ -n "$_t" ]; then printf 'claude-projects\t%s' "$_t"; else printf 'elsewhere\t%s' "$(basename "$1")"; fi
}

# sessions: the run's own (the events' session, agent-start and agent-stop transcript= paths) and the user's
sessions() {
  : > "$W/named"; EVF=$H/.vid/metrics-events   # read only
  if [ -f "$EVF" ]; then
    awk 'function val(k,   i, v) { i = index($0, " " k "="); if (!i) return ""; v = substr($0, i + length(k) + 2)
           if (substr(v, 1, 1) == "\"") { v = substr(v, 2); sub(/".*/, "", v) } else sub(/ .*/, "", v); return v }
      $1 == "session" { s = val("id"); t = val("transcript") }
      $1 == "agent-start" { s = val("session"); t = val("transcript") }
      $1 == "agent-stop" { s = val("session"); t = val("transcript"); if (match(t, /[\/\\]subagents[\/\\][^\/\\]*$/)) t = substr(t, 1, RSTART - 1) ".jsonl"; else t = "" }
      $1 == "session" || $1 == "agent-start" || $1 == "agent-stop" { if (s != "" && s != "-") { if (t == "-") t = ""; print s "\t" t "\tevents" } }' "$EVF" >> "$W/named"
  fi
  printf '%s' "$SESSIONS" | while IFS= read -r x; do
    [ -n "$x" ] || continue
    case "$x" in
      */*|*\\*) b=${x##*/}; b=${b##*\\}; printf '%s\t%s\tthe user\n' "${b%.jsonl}" "$x" ;;
      *) f=''; for c in "$CFG"/projects/*/"$x.jsonl"; do [ -f "$c" ] && { f=$c; break; }; done; printf '%s\t%s\tthe user\n' "$x" "$f" ;;
    esac
  done >> "$W/named"
  awk -F'\t' '!(($1 "\t" $2) in s) { s[$1 "\t" $2] = 1; print }' "$W/named" > "$W/named.u"
  : > "$W/took"; cut -f1 "$W/named.u" | awk '!s[$0]++' > "$W/sids"
  while IFS= read -r sid; do
    case "$sid" in *[!A-Za-z0-9._-]*|.*|'') ms "$sid" 'not a session id'; continue ;; esac
    got=''; tried=''; who=''
    while IFS="$TAB" read -r s p w; do
      [ "$s" = "$sid" ] || continue; who=${who:-$w}
      [ -n "$p" ] || continue; tried=$p
      got=$(resolve "$p"); [ -z "$got" ] || break
    done < "$W/named.u"
    if [ -z "$got" ]; then
      if [ -z "$tried" ]; then ms "$sid" "named by $who with no transcript path, and not found by its id"
      else case "$tried" in [A-Za-z]:[\\/]*) ms "$sid" "named by $who; not readable here, nor at its WSL mount" "$tried" ;; *) ms "$sid" "named by $who; not readable here" "$tried" ;; esac; fi
      continue
    fi
    printf '%s\t%s\n' "$sid" "$got" >> "$W/took"
    add "conversations/$sid/$sid.jsonl" "$got" conv
    src "conversations/$sid/" "$(trel "$got" | cut -f1)" "$(trel "$got" | cut -f2)" "the session's transcript and its folder (subagents, tool results), gzipped; named by $who"
    if [ -d "${got%.jsonl}" ]; then walk "${got%.jsonl}" "conversations/$sid" conv logs < /dev/null; fi
  done < "$W/sids"
}

# gzr <class> <bundle path> <bytes>: yes when the file is gzipped in the bundle (FORMAT's rule, as the owner's packer)
gzr() {
  case "$1" in
    rec) [ "$3" -gt 262144 ] ;;
    log) case "$2" in *.log|*/log|log|*timeline*) return 0 ;; esac; [ "$3" -gt 262144 ] ;;
    conv) case "$2" in *.jsonl) return 0 ;; esac; [ "$3" -gt 65536 ] ;;
    *) return 1 ;;
  esac
}

# The redactor (R3): one awk program for redaction and for the scan, so the scan reads exactly the kinds and forms redaction
# covers. ENVIRON: SHARE_MODE redact (replace, counts to SHARE_COUNTS), plain (replace, no counts) or scan (replace nothing,
# print `<kind>\t<n>` for every match left); SHARE_KNOWN, a file of `<kind>\t<value>` lines: name (a user name), email,
# account (an account or organisation id), host, literal-file (the user's file of literals, one a line). Each match becomes
# [REDACTED:<kind>]; an assignment keeps its name and separator. Every form: an unquoted value stops at a quote, a backslash or a space,
# so it is caught as plain text, inside a JSON string (\"key\": \"value\", a value ending at a literal \n) and doubly escaped
# (\\\"key\\\": \\\"value\\\"). A kind's match at a word's inside is skipped where a boundary is needed, by one rule for the
# tokens and the names alike (bnd): the text before the match is empty, or ends in a character not a letter, digit or _, or in
# \b \f \n \r \t, \u and 4 hex digits, \x and 2 hex digits, a colour code, or % and 2 hex digits. Its one named limit: an octal
# escape (\342) is not a boundary. No interval braces: repeats are spelled out (rp), for every awk.
# 0.26.11.2 (SHARE-SCRUB §4): the context rules run on the text as it came, then the known values, then the shapes; on a JSON line
# or a .json file's line a marker left as a bare value outside any string is quoted, so the line still parses. The kinds, in the
# order they apply:
#   private-key      from any BEGIN … PRIVATE KEY (or PRIVATE KEY BLOCK, PGP's) marker to its END marker, wherever on the line each sits, over lines
#                    and inside \n-escaped strings; with no END, to the JSON string's end, else to the file's end
#   literal          each line of the user's file
#   github-token     gh[pousr]_ and 20+ letters or digits; github_pat_ and 20+
#   anthropic-key    sk-ant- and 20+
#   openai-key       sk- or sk-proj- and 32+
#   stripe-key       sk_ or rk_, live_ or test_, and 10+
#   aws-key          AKIA or ASIA and 16 capitals or digits
#   slack-token      xox[baprs]- and 10+
#   google-key       AIza and 35
#   npm-token        npm_ and 36
#   jwt              eyJ….eyJ….… (three base64url parts)
#   bearer           Bearer and 16+ token characters (the word kept)
#   url-credentials  scheme://user:password@ (the scheme and @ kept)
#   token-header     x-…token: or = and 8+
#   auth-header      the value of an Authorization, Proxy-Authorization, Cookie or Set-Cookie header (the scheme word kept), to the
#                    close of a quote right before the name, else on a JSON line its string's end or a \n or \r escape, else the line's end
#   aws-secret-key   (aws_)secret_access_key or SecretAccessKey, any case, and 40 key characters
#   account-id       accountUuid, organizationUuid, account_id and the like, and an id; then each id found, anywhere
#   secret-assignment  a secret name — one that is or ends in token, secret, password, passwd, passphrase, credential(s), auth,
#                    cookie, _key or -key (each in any case), apikey, <word>Key, or _pass, -pass, <word>Pass, _pwd, -pwd, <word>Pwd
#                    — then = or :, then 1+ value characters, or a quoted value of any length to its closing quote (one escaped
#                    deeper is its own), spaces included; and <name>value</name>. Left: a marker, a whole variable reference
#                    ($NAME, ${…, $(…), a whole <placeholder>, all *, none, null, true, false, unset. After a quoted name an
#                    unquoted value (a JSON number) is written as a marker in the name's quote
#   secret-flag      - or -- and a secret name at a boundary, spaces, then the value (quoted to its close, else the run; an
#                    unquoted one starting - is the next flag); a secret name or IDENTIFIED BY, spaces and a quoted value; in
#                    each command (between ; & | $( ` and \n or \r escapes): -p glued or not beside a user flag whose value is a
#                    name (-u, -U, --user, --username), a port (digits, . and :) left; with no user flag, the closed list:
#                    sshpass -p, mysql mysqldump mysqladmin mariadb mariadb-dump -p glued, redis-cli -a, docker login, podman
#                    login and helm registry login -p; curl and wget -u user:<value>
#   personal-field   the value of a field named (any case, _ or - or nothing between words, after a prefix ending _ or -, or
#                    camel-cased) first/last/full/given/family/middle/maiden name, surname, birth date, date of birth, dob,
#                    birthday, phone, telephone, tel, mobile, fax, address, street, address line, postcode, post code, postal
#                    code, zip, zip code, ssn, national id, passport, tax id, iban, card number, cvv, cvc, email: quoted to its
#                    close, else to a quote, backslash , ; { } [ ] < > or the line's end; a container left; and of a name field
#                    (name, <x>_name, <x>Name, author, user, username, owner, contact, customer, sender, recipient, from, to)
#                    holding 2 to 4 capitalised words; and <name>value</name>
#   known-secret     each secret-named value of the environment and of the dotenv files .known lists, and every URL password
#                    in their values, 6+ characters, whole tokens in any case, as it is, JSON-escaped once and twice, unescaped
#                    and percent-encoded (a secret-name or stop word left)
#   card-number      13 to 19 digits, plain or in groups of 4, starting 4, 51-55, 22-27, 34, 37 or 6, passing Luhn
#   iban             two capitals, two digits, 11 to 30 letters or digits, plain or in groups of 4, passing mod 97
#   email            every address local@domain.tld (and the user's, as a literal); never starting on a JSON escape's letter
#   phone            + and a country code not 0 and 8 to 15 digits with single separators; (NNN) NNN-NNNN; NNN-NNN-NNNN
#   ip-address       IPv4 (each part 0-255, not in a longer dotted number, the first not 0 or 127); IPv6 in full or with ::
#                    and two hex groups, one of 3 or 4 characters, never ::1
#   token-like       a run of letters, digits, _ and - with 20+ letters and digits, upper and lower case and 2+ digits, at least
#                    half letters, 30 to 70% of them capitals; hex alone and Claude's ids (toolu_ srvtoolu_ msg_ req_ cse_
#                    file_ session_) left
#   host             the host name after @ (a prompt) or in a host or hostname field, never as a bare word
#   user-name        a user name after a home prefix: the Users or home folder after any number of slashes or backslashes
#                    (so a drive's, a WSL mount's and Git Bash's forms, and JSON's escaped ones), and its encoded form
#                    (every character not a letter or digit as -) after -Users- or -home-, as Claude's folder names hold it
#   person-name      every author, committer and Co-authored-by of two words or more in the home's and the left-out
#                    repositories' histories (no [bot], .invalid, noreply@anthropic.com or noreply@github.com), whole phrase
#                    in any case, and encoded (lower case, - for the rest)
REDLIB='function rp(c, n,   s) { s = ""; while (n-- > 0) s = s c; return s }
# bnd: the one boundary, the rule stated in the header, tested on the whole text t before a match (a colour code has no fixed length)
function bnd(t,   c, n, H) { n = length(t); if (n == 0) return 1; c = substr(t, n, 1); if (c !~ /[A-Za-z0-9_]/) return 1; H = "^[0-9A-Fa-f]+$"
  if (c ~ /[bfnrt]/ && substr(t, n - 1, 1) == "\\") return 1
  if (n >= 6 && substr(t, n - 5, 2) == "\\u" && substr(t, n - 3) ~ H) return 1
  if (n >= 4 && substr(t, n - 3, 2) == "\\x" && substr(t, n - 1) ~ H) return 1
  if (n >= 3 && substr(t, n - 2, 1) == "%" && substr(t, n - 1) ~ H) return 1
  return (c == "m" && t ~ SGR) }
# skipv: a value that is surely no secret (SHARE-SCRUB §4.3.4): a marker, a whole variable reference ($NAME, ${NAME}), a whole
# <placeholder>, all *, or none, null, true, false, unset
function skipv(v,   lv) { lv = tolower(v); if (v ~ /^[$][A-Za-z_][A-Za-z0-9_]*$/ || v ~ /^[$][{][A-Za-z_][A-Za-z0-9_]*[}]$/ || v ~ /^<[^<>]*>$/ || v ~ /^[*]+$/ || v ~ /^\[REDACTED:[a-z-]*\]$/) return 1
  return (lv == "none" || lv == "null" || lv == "true" || lv == "false" || lv == "unset") }
function mark(k) { C[k]++; return "[REDACTED:" k "]" }
# rep: every a in v replaced by b, as plain text (no awk’s replacement rules, which differ between awks)
function rep(v, a, b,   o, p) { o = ""; while ((p = index(v, a)) > 0) { o = o substr(v, 1, p - 1) b; v = substr(v, p + length(a)) } return o v }
function je(v) { return rep(rep(v, "\\", "\\\\"), "\"", "\\\"") }
function ju(v) { return rep(rep(v, "\\\"", "\""), "\\\\", "\\") }
function pe(v,   o, i, c) { o = ""; for (i = 1; i <= length(v); i++) { c = substr(v, i, 1); o = o (c ~ /[A-Za-z0-9._~-]/ ? c : sprintf("%%%02X", ORD[c])) } return o }
# 0.26.11.2 (SHARE-SCRUB §4.1): a known value is used in its byte forms (as it is, JSON-escaped once and twice, unescaped, percent-
# encoded), lower case, as om() matches it whole; not under 6 characters, a secret-name word, a stop word, a marker or all *
function aks(v) { if (length(v) < 6 || tolower(v) ~ /^(token|secrets?|password|passwd|passphrase|pass|pwd|credentials?|auth|cookie|key|apikey|pat|pw|sig|signature)$/ || (tolower(v) in STOP) || v ~ /^\[REDACTED:[a-z-]*\]$/ || v ~ /^[*]+$/) return
  ak1(v); ak1(je(v)); ak1(je(je(v))); if (index(v, "\\")) ak1(ju(v)); ak1(pe(v)) }
function ak1(v,   lv) { lv = tolower(v); if (lv in KSS) return; KSS[lv] = 1; KS[++nk] = lv }
# urlpw: the password of every URL with credentials in v, as a known value
function urlpw(v,   m, a) { while (match(v, URL)) { m = substr(v, RSTART, RLENGTH); v = substr(v, RSTART + RLENGTH); a = substr(m, index(m, "://") + 3); aks(substr(a, index(a, ":") + 1, length(a) - index(a, ":") - 1)) } }
# denv: a dotenv file read as a shell reads it (export dropped, the key to the first =, one pair of quotes removed, an unquoted
# value ending at " #"): each secret-named key’s value, and every value’s URL password
function denv(f,   x, e, key, val, q) {
  while ((getline x < f) > 0) { sub(/\r$/, "", x); sub(/^[ \t]*export[ \t]+/, "", x); e = index(x, "="); if (x ~ /^[ \t]*#/ || (!e && !index(x, ":"))) continue
    key = substr(x, 1, e - 1); if (key ~ /:/ && index(x, ":") < e) e = 0
    if (!e && (e = index(x, ":"))) key = substr(x, 1, e - 1)   # a KEY: value line (a .env.yml)
    gsub(/^[ \t]+|[ \t]+$/, "", key); val = substr(x, e + 1); sub(/^[ \t]+/, "", val)
    if (substr(val, 1, 1) == "\"") { val = substr(val, 2); q = endq(val); if (q) val = substr(val, 1, q - 1); val = rep(val, "\\\"", "\"") }
    else if (substr(val, 1, 1) == "\047") { val = substr(val, 2); sub(/\047.*/, "", val) }
    else { sub(/[ \t]+#.*/, "", val); sub(/[ \t]+$/, "", val) }
    if (key ~ SANW || key ~ SANUW) aks(val); urlpw(val) }
  close(f) }
function tok(s, k, re, b,   out, pre, m) { out = ""
  while (match(s, re)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (b && !bnd(out pre)) { out = out pre substr(m, 1, 1); s = substr(m, 2) s; continue }
    out = out pre mark(k) }
  return out s }
# asg: an assignment, name then separator then value. The value is the run of class vc characters (at least mn); after a
# separator ending in a quote (with its backslashes: ", \", \\\"), it is everything up to that quote again, spaces included;
# with qk, else the run. A separator ending in two quotes (an empty value) is left.
function asg(s, k, nre, vc, mn, qk,   out, pre, m, nl, r, sl, sp, post, v, p, q1, vx, p2) { out = ""
  while (match(s, nre SEP)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    match(m, "^" nre); nl = RLENGTH; r = substr(m, nl + 1); match(r, SOP); q1 = substr(r, 1, RSTART - 1); post = substr(r, RSTART + RLENGTH)
    v = ""; p = 0
    if ((JLN && post == "\"" && q1 !~ /"[ \t]*$/) || (q1 == "" && post != "" && substr(pre, length(pre) - length(post) + 1) == post)) { out = out pre m; continue }
    if (qk && post ~ /^\\*["\047]$/) { p = cq(s, post); if (p) v = substr(s, 1, p - 1) }
    if (!p) { if (post != "" && post !~ /^\\*["\047]$/) { out = out pre m; continue }
      # SHARE-SCRUB adversarial 1: after an unquoted name a plain value runs to a space, a quote or a backslash; after a quoted
      # name (a JSON value) as before; a ${…} whole
      vx = (vc == VW && q1 ~ /["\047][ \t]*$/) ? V6 : vc
      if (substr(s, 1, 2) == "${" && (p2 = index(s, "}"))) { v = substr(s, 1, p2); if (match(substr(s, p2 + 1), "^" vx "+")) v = v substr(s, p2 + 1, RLENGTH) }
      else if (match(s, "^" vx "+")) v = substr(s, 1, RLENGTH) }
    if (length(v) < (p ? 1 : mn) || skipv(v) || (!p && v ~ /^=/)) { out = out pre m; continue }   # a comparison (==) is no assignment
    # adversarial 2: name: Type = value (a typed declaration) takes the value after the =; a YAML block scalar (| or >) inside a
    # JSON string takes its next line
    if (!p && vc == VW && match(substr(s, length(v) + 1), /^[ \t]*=[ \t]*\\*["\047`]/) && substr(s, length(v) + 1) !~ /^[ \t]*==/) {
      p2 = substr(s, length(v) + 1, RLENGTH); r = substr(s, length(v) + RLENGTH + 1); match(p2, /\\*["\047`]$/); sl = substr(p2, RSTART)
      if ((sp = cq(r, sl)) > 1) { if (skipv(substr(r, 1, sp - 1))) { out = out pre m; continue } out = out pre m v p2 mark(k); s = substr(r, sp); continue } }
    if (!p && v ~ /^[|>][-+]?$/ && match(substr(s, 2 + (length(v) > 1)), /^[ \t]*\\n[ \t]+/)) {
      r = substr(s, length(v) + 1); p2 = substr(r, 1, RLENGTH); r = substr(r, RLENGTH + 1)
      if (match(r, /^[^\\"]+/)) { if (skipv(substr(r, 1, RLENGTH))) { out = out pre m; continue } out = out pre m v p2 mark(k); s = substr(r, RLENGTH + 1); continue } }
    # SHARE-SCRUB §4.3.4: an unquoted value right after a quoted name (a JSON number) becomes a marker in the name’s own quote
    gsub(/[ \t]/, "", q1); if (p || post != "" || q1 !~ /^\\*"$/) q1 = ""
    out = out pre m q1 mark(k) q1; s = substr(s, length(v) + 1) }
  return out s }
# 0.26.11.2 (SHARE-SCRUB). xel: <name>value</name> for a name nre matches, the value to the next <; on a JSON line (jl) not past
# an unescaped quote, the end of the JSON string it sits in
function xel(s, k, nre, jl, nf,   out, pre, m, v) { out = ""
  while (match(s, "<" nre ">")) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (match(s, /^[^<]+<\//)) { v = substr(s, 1, RLENGTH - 2); if (!skipv(v) && !(jl && endq(v)) && !(nf && !pname(v))) { out = out pre m mark(k); s = substr(s, length(v) + 1); continue } }
    out = out pre m }
  return out s }
# fv: the value at the start of r: a quoted one (its quote and backslashes in FQ, FQL long) to its closing quote, else the run of
# V6 characters; FV the value, FVL its length; 0 when there is none, it is empty, or skipv leaves it
function fv(r,   p) { FQ = ""; FQL = 0; FVL = 0; FV = ""
  if (match(r, /^\\*["\047]/)) { FQ = substr(r, 1, RLENGTH); FQL = RLENGTH; if (JLN && FQ == "\"") { FQ = ""; FQL = 0; return 0 } p = cq(substr(r, FQL + 1), FQ); if (!p) { FQ = ""; FQL = 0; return 0 } FV = substr(r, FQL + 1, p - 1) }
  else if (substr(r, 1, 2) == "${" && (p = index(r, "}"))) { FV = substr(r, 1, p); if (match(substr(r, p + 1), "^" VW "+")) FV = FV substr(r, p + 1, RLENGTH) }
  else if (match(r, "^" VW "+")) FV = substr(r, 1, RLENGTH); else return 0
  FVL = length(FV); return (FVL > 0 && !skipv(FV)) }
# flg (§4.3.2): a dash or two at a boundary, a secret name, spaces, then its value (an unquoted one starting - is the next flag);
# then a secret name or IDENTIFIED BY at a boundary, spaces and a quoted value (IDENTIFIED BY’s unquoted too)
function flg(s,   out, pre, m, r, id) { out = ""
  while (match(s, FLA)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre)) { out = out pre substr(m, 1, 1); s = substr(m, 2) s; continue }
    if (!fv(s) || (FQ == "" && substr(FV, 1, 1) == "-")) { out = out pre m; continue }
    out = out pre m FQ mark("secret-flag"); s = substr(s, FQL + FVL + 1) }
  s = out s; out = ""
  while (match(s, FLB)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre) || substr(pre, length(pre), 1) == "-") { out = out pre substr(m, 1, 1); s = substr(m, 2) s; continue }
    id = (m ~ "^" IDB); if (!fv(s) || (FQ == "" && !id)) { out = out pre m; continue }
    out = out pre m FQ mark("secret-flag"); s = substr(s, FQL + FVL + 1) }
  s = out s; out = ""
  # a .netrc printed (machine <host> login <user> password <v>, adversarial 2)
  if (tolower(s) ~ /machine[ \t]+[^ \t]+[ \t]+login[ \t]/) { while (match(s, /(^|[ \t])[Pp][Aa][Ss][Ss][Ww]([Oo][Rr])?[Dd][ \t]+/)) { pre = substr(s, 1, RSTART + RLENGTH - 1); s = substr(s, RSTART + RLENGTH)
      if (!fv(s)) { out = out pre; continue } out = out pre FQ mark("secret-flag"); s = substr(s, FQL + FVL + 1) }
    s = out s; out = "" }
  # -storepass, -keypass, -passin, -passout and their like, a pass: prefix kept (adversarial 1)
  while (match(s, FLP)) { pre = substr(s, 1, RSTART + RLENGTH - 1); s = substr(s, RSTART + RLENGTH)
    if (!fv(s) || (FQ == "" && substr(FV, 1, 1) == "-")) { out = out pre; continue }
    r = (FV ~ /^pass:./) ? "pass:" : ""; if (r != "" && skipv(substr(FV, 6))) { out = out pre; continue }
    out = out pre FQ r mark("secret-flag"); s = substr(s, FQL + FVL + 1) }
  return out s }
# cal (adversarial 2): a secret name given as a quoted argument or subscript, then its value (os.environ["DB_PASSWORD"] = "v",
# define("DB_PASSWORD", "v"), setenv("API_KEY", "v"), put("password", "v")); and a method named for a secret given a quoted
# value (setPassword("v"), with_password("v"))
function cal(s,   out, pre, m, e) { out = ""
  while (match(s, CAL1)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    match(m, /\\*["\047]$/); e = cq(s, substr(m, RSTART)); if (e < 2 || skipv(substr(s, 1, e - 1)) || substr(s, e, 16) ~ /^\\*["\047][ \t]*:/) { out = out pre m; continue }   # a JSON key after it is no value
    out = out pre m mark("secret-assignment"); s = substr(s, e) }
  s = out s; out = ""
  while (match(s, CAL2)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre)) { out = out pre substr(m, 1, 1); s = substr(m, 2) s; continue }
    match(m, /\\*["\047]$/); e = cq(s, substr(m, RSTART)); if (e < 2 || skipv(substr(s, 1, e - 1))) { out = out pre m; continue }
    out = out pre m mark("secret-assignment"); s = substr(s, e) }
  return out s }
# pvx (adversarial 2): flag f of a command cre names (sqlcmd -P, ldapsearch -w, plink -pw, zip -P, lftp -u user,pw, smbclient
# -U user%pw, httpie -a user:pw), the value, or with sep its part after sep
function pvx(s, f, cre, sep,   t, out, pre, r, gl, off, c) { out = ""; off = 0; t = s
  while (match(s, "(^|[ \t])" f)) { pre = substr(s, 1, RSTART + RLENGTH - 1); r = substr(s, RSTART + RLENGTH); cmd(t, off + RSTART)
    gl = (r !~ /^[ \t]/); if (!gl) { match(r, /^[ \t]+/); pre = pre substr(r, 1, RLENGTH); r = substr(r, RLENGTH + 1) }
    off += length(pre)
    if (r == "" || CMW !~ (CW "(" cre ")" CE) || !fv(r) || (!gl && FQ == "" && substr(FV, 1, 1) == "-")) { out = out pre; s = r; continue }
    c = (sep == "") ? 0 : index(FV, sep); if (sep != "" && (!c || c == FVL || skipv(substr(FV, c + 1)))) { out = out pre; s = r; continue }
    out = out pre FQ substr(FV, 1, c) mark("secret-flag"); s = substr(r, FQL + FVL + 1); off += FQL + FVL }
  return out s }
# awp: an AWS secret key given after its name and spaces (aws configure set aws_secret_access_key <v>)
function awp(s,   out, pre) { out = ""
  while (match(s, AWSN "[ \t]+")) { pre = substr(s, 1, RSTART + RLENGTH - 1); s = substr(s, RSTART + RLENGTH)
    if (match(s, /^[A-Za-z0-9\/+]+/) && RLENGTH >= 20) { out = out pre mark("aws-secret-key"); s = substr(s, RLENGTH + 1) } else out = out pre }
  return out s }
# nvp: a name or key that is a secret name, then its value (kubectl and HAR name/value pairs, .NET <add key= value=>); and the
# value written first, its name after it (adversarial 2)
function nvp(s,   out, pre, m, e) { out = ""
  while (match(s, NVR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!match(m, /\\*["\047]$/)) { out = out pre m; continue }
    e = cq(s, substr(m, RSTART)); if (e < 2 || skipv(substr(s, 1, e - 1))) { out = out pre m; continue }
    out = out pre m mark("secret-assignment"); s = substr(s, e) }
  s = out s; out = ""
  while (match(s, NVV)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!match(m, /\\*["\047]$/)) { out = out pre m; continue }
    e = cq(s, substr(m, RSTART)); if (e < 2 || skipv(substr(s, 1, e - 1)) || substr(s, e, 200) !~ NVN) { out = out pre m; continue }
    out = out pre m mark("secret-assignment"); s = substr(s, e) }
  return out s }
# pfl (§4.3.2): -p, redis-cli’s -a and curl’s -u user:pass, each read in its command: the text between the nearest command
# separators around the flag (; & | $( ` and \n or \r escapes), within 512 characters each way; the value read from the whole text,
# so a quoted value holding a separator is taken whole
function pfl(s,   out, p) { if (length(s) <= 8192) return pf1(s); out = ""
  # a long line in pieces cut after a \n or \r escape (a command separator), so each piece is read in linear time
  while (length(s) > 8192 && match(substr(s, 4097), /\\[nr]/)) { p = 4096 + RSTART + 1; out = out pf1(substr(s, 1, p)); s = substr(s, p + 1) }
  return out pf1(s) }
function pf1(s) { if (s !~ /(^|[ \t])-[pauPUw]/ && !index(s, "--user")) return s; s = pv(s, "-p", 0); s = pv(s, "-a", 1); s = cuu(s)
  if (s ~ /(^|[ \t])-[PwuUap]/) { s = pvx(s, "-P", "sqlcmd|bcp|zip", ""); s = pvx(s, "-w", "ldap[a-z]*", ""); s = pvx(s, "-pw", "plink|pscp|psftp", "")
    s = pvx(s, "-u", "lftp", ","); s = pvx(s, "-U", "smbclient", "\045"); s = pvx(s, "-a", "https?", ":") }
  return s }
# cmd: the command around position q of t, CMD, for the user flag; and CMW, the text back to a \n or \r escape (no ; & | inside a
# quote can cut it), for the closed list’s and curl’s command names
function cmd(t, q,   a, l, r, w) { a = q > 512 ? q - 512 : 1; l = substr(t, a, q - a); w = l
  while (match(l, PSEP)) l = substr(l, RSTART + RLENGTH)
  while (match(w, /\\[nr]/)) w = substr(w, RSTART + RLENGTH)
  r = substr(t, q, 512); if (match(r, PSEP)) r = substr(r, 1, RSTART - 1)
  CMD = l r; CMW = w r }
# pv: each flag f standing alone, glued to its value or before spaces and it: taken in the closed list’s commands (sshpass, the
# login commands, the mysql clients glued; with ra, redis-cli’s -a), else beside a user flag unless the value is a port (digits, . :)
function pv(s, f, ra,   t, out, pre, r, gl, off, cl) { out = ""; off = 0; t = s
  while (match(s, "(^|[ \t])" f)) { pre = substr(s, 1, RSTART + RLENGTH - 1); r = substr(s, RSTART + RLENGTH); cmd(t, off + RSTART)
    gl = (r !~ /^[ \t]/); if (!gl) { match(r, /^[ \t]+/); pre = pre substr(r, 1, RLENGTH); r = substr(r, RLENGTH + 1) }
    off += length(pre); cl = ra ? (CMW ~ CLR) : ((CMW ~ CLS) || (CMW ~ CLL) || ((CMW ~ CLM) && gl))
    if (r == "" || !fv(r) || (!gl && FQ == "" && substr(FV, 1, 1) == "-") || !(cl || (!ra && (CMD ~ UFL) && FV !~ /^[0-9.:]+$/))) { out = out pre; s = r; continue }
    out = out pre FQ mark("secret-flag"); s = substr(r, FQL + FVL + 1); off += FQL + FVL }
  return out s }
# cuu: curl’s and wget’s -u user:pass, the password after the first colon, quoted on its own or not
function cuu(s,   t, out, pre, r, c, off, u) { out = ""; off = 0; t = s
  while (match(s, /(^|[ \t])(-u|--user)([ \t]+|=)?/)) { pre = substr(s, 1, RSTART + RLENGTH - 1); r = substr(s, RSTART + RLENGTH); cmd(t, off + RSTART); off += length(pre)
    if (CMW !~ CLC || !fv(r) || !(c = index(FV, ":"))) { out = out pre; s = r; continue }
    if (FQ == "" && substr(r, c + 1) ~ /^\\*["\047]/) { u = substr(FV, 1, c); r = substr(r, c + 1); off += c; if (!fv(r)) { out = out pre u; s = r; continue } out = out pre u FQ mark("secret-flag"); s = substr(r, FQL + FVL + 1); off += FQL + FVL; continue }
    if (c == FVL || skipv(substr(FV, c + 1))) { out = out pre; s = r; continue }
    out = out pre FQ substr(FV, 1, c) mark("secret-flag"); s = substr(r, FQL + FVL + 1); off += FQL + FVL }
  return out s }
# ahd (§4.3.3): an Authorization, Proxy-Authorization, Cookie or Set-Cookie header’s value, the scheme word kept. It ends at the
# close of a quote standing right before the name, else on a JSON line at its JSON string’s end or a \n or \r escape, else at the line’s end
function ahd(s, jl,   out, pre, m, r, e, v, sc, x, ar, q) { out = ""
  while (match(s, AHR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); r = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre)) { out = out pre substr(m, 1, 1); s = substr(m, 2) r; continue }
    if (m ~ /:[ \t]*\\+$/) { out = out pre m; s = r; continue }
    if (jl && m ~ /[^"\047\\][ \t]*:[ \t]*"$/) { out = out pre m; s = r; continue }
    if (m ~ /["\047][ \t]*:[ \t]*$/ && r !~ /^\[/) { out = out pre m; s = r; continue }
    # a JSON array of strings as the value: its first string is the value
    ar = 0; if (match(r, /^\[[ \t]*\\*["\047]/)) { ar = 1; x = substr(r, 1, RLENGTH); m = m x; r = substr(r, RLENGTH + 1); match(x, /\\*["\047]$/); e = cq(r, substr(x, RSTART)); if (!e) { out = out pre m; s = r; continue } }
    else if (r ~ /^[[{]/) { out = out pre m; s = r; continue }
    else
    if (match(m, /\\*["\047]$/)) { e = cq(r, substr(m, RSTART)); if (!e) { out = out pre m; s = r; continue } }
    else if (match(pre, /\\*["\047]$/)) { e = cq(r, substr(pre, RSTART)); if (!e) e = length(r) + 1 }
    else if (jl) { e = endq(r); if (!e) e = length(r) + 1; if (match(substr(r, 1, e - 1), /\\[nr]/)) e = RSTART }
    else e = length(r) + 1
    v = substr(r, 1, e - 1); sc = ""
    if (tolower(m) ~ /auth/ && match(v, /^[A-Za-z][A-Za-z0-9_-]*[ \t]+/) && RLENGTH < length(v)) { sc = substr(v, 1, RLENGTH); v = substr(v, RLENGTH + 1) }
    x = v; sub(/[ \t]+$/, "", x)
    if (x == "" || skipv(x)) { if (!ar) { out = out pre m; s = r; continue } out = out pre m substr(r, 1, e - 1); s = substr(r, e) }
    else { out = out pre m sc mark("auth-header"); s = substr(r, e) }
    # an array: each further string of it too (adversarial 2), to its ]
    while (ar && match(s, /^\\*["\047][ \t]*,[ \t]*\\*["\047]/)) { x = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1); match(x, /\\*["\047]$/); q = substr(x, RSTART)
      e = cq(s, q); if (!e) { out = out x; break } v = substr(s, 1, e - 1); sc = ""
      if (tolower(m) ~ /auth/ && match(v, /^[A-Za-z][A-Za-z0-9_-]*[ \t]+/) && RLENGTH < length(v)) { sc = substr(v, 1, RLENGTH); v = substr(v, RLENGTH + 1) }
      out = out x (skipv(v) ? sc v : sc mark("auth-header")); s = substr(s, e) } }
  return out s }
# kv (§4.4.4): a personal field’s value, as an assignment is read (its name at a boundary): quoted to its close, else the run of VL
# characters, its trailing spaces kept out; a container ({ or [) left; with nf, only a name of 2 to 4 capitalised words
function kv(s, k, nre, nf,   out, pre, m, nl, r, post, v, p, q1) { out = ""
  while (match(s, nre SEP)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre)) { out = out pre substr(m, 1, 1); s = substr(m, 2) s; continue }
    match(m, "^" nre); nl = RLENGTH; r = substr(m, nl + 1); match(r, SOP); q1 = substr(r, 1, RSTART - 1); post = substr(r, RSTART + RLENGTH)
    v = ""; p = 0
    if ((JLN && post == "\"" && q1 !~ /"[ \t]*$/) || (q1 == "" && post != "" && substr(pre, length(pre) - length(post) + 1) == post)) { out = out pre m; continue }
    if (post ~ /^\\*["\047]$/) { p = cq(s, post); if (!p) { out = out pre m; continue } v = substr(s, 1, p - 1) }
    else if (post != "") { out = out pre m; continue }
    else if (match(s, "^" ((q1 ~ /["\047][ \t]*$/) ? VL : VLW) "+")) { v = substr(s, 1, RLENGTH); sub(/[ \t]+$/, "", v) }
    if (v == "" || skipv(v) || (nf && !pname(v))) { out = out pre m; continue }
    gsub(/[ \t]/, "", q1); if (p || q1 !~ /^\\*"$/) q1 = ""
    out = out pre m q1 mark(k) q1; s = substr(s, length(v) + 1) }
  return out s }
# pname: a person’s name: 2 to 6 words, each a capitalised name (an apostrophe, a hyphen, an inner capital), an initial (B.), a
# title (Mr, Mrs, Ms, Dr, Prof, Sir, Dame), a particle (van, von, de, der, da, di, du, le, la, del, bin, al) or a suffix (Jr, Sr,
# II, III, MD, PhD); at least one a capitalised name
function pname(v,   n, w, i, c) { n = split(v, w, " "); if (n < 2 || n > 6) return 0; c = 0
  for (i = 1; i <= n; i++) { if (w[i] ~ /^[A-Z][A-Za-z\200-\377\047-]*[a-z\200-\377][A-Za-z\200-\377\047-]*,?$/) { c++; continue }
    if (w[i] ~ /^[A-Z][.]$/ || w[i] ~ /^(Mr|Mrs|Ms|Miss|Dr|Prof|Sir|Dame)[.]?$/ || w[i] ~ /^(van|von|de|der|den|da|di|du|le|la|del|della|bin|al)$/ || w[i] ~ /^(Jr|Sr|II|III|IV|MD|PhD|Esq)[.]?$/) continue
    return 0 }
  return c >= 1 }
# esl: when a shape’s match starts on the letter of a JSON escape (\n, \t, …, \u and 4 hex), the number of characters to give back
function esl(pre, m) { if (substr(pre, length(pre), 1) != "\\") return 0; if (m ~ /^u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/) return 5; return (m ~ /^[bfnrt]/) }
function ema(s,   out, pre, m, e) { out = ""
  while (match(s, EMR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if ((e = esl(pre, m))) { pre = pre substr(m, 1, e); m = substr(m, e + 1); if (m !~ "^" EMR "$") { out = out pre m; continue } }
    out = out pre mark("email") }
  if (!index(s, "%40") && !index(out, "%40")) return out s
  s = out s; out = ""
  while (match(s, EMP)) { out = out substr(s, 1, RSTART - 1) mark("email"); s = substr(s, RSTART + RLENGTH) }   # adversarial 2: %40 for @
  return out s }
# phn (§4.4.2): + and a country code not 0, 8 to 15 digits with single separators; (NNN) NNN-NNNN; NNN-NNN-NNNN
function phn(s,   out, pre, m, t, d, c) { out = ""
  while (match(s, PHA)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    t = m; d = gsub(/[0-9]/, "", t)
    # more than 15 digits: the trailing groups after a space given back (a date, a count beside the number)
    while (d > 15 && match(m, / [0-9]+$/)) { s = substr(m, RSTART) s; m = substr(m, 1, RSTART - 1); t = m; d = gsub(/[0-9]/, "", t) }
    if (!bnd(out pre) || d < 8 || d > 15 || m ~ /  |--|[.][.]|[.-][.-]|[(][(]|[)][)]/) { out = out pre m; continue }
    out = out pre mark("phone") }
  s = out s; out = ""
  while (match(s, PHB)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH); c = substr(out pre, length(out pre), 1)
    if (!bnd(out pre) || c == "-" || c == "." || substr(s, 1, 1) ~ /[0-9-]/) { out = out pre m; continue }
    out = out pre mark("phone") }
  return out s }
# ip4, ip6 (§4.4.3)
function ip4(s,   out, pre, m, a, i, ok, c) { out = ""
  while (match(s, IP4)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH); c = substr(out pre, length(out pre), 1)
    split(m, a, "."); ok = (bnd(out pre) && c != "." && a[1] + 0 != 0 && a[1] + 0 != 127 && s !~ /^([.]?[0-9])/)
    for (i = 1; i <= 4 && ok; i++) if (length(a[i]) > 3 || a[i] + 0 > 255) ok = 0
    if (!ok) { out = out pre m; continue } out = out pre mark("ip-address") }
  return out s }
function ip6(s,   out, pre, m, a, n, i, g, dc, l3, bad, c) { out = ""
  while (match(s, IP6)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH); c = substr(out pre, length(out pre), 1)
    bad = (!bnd(out pre) || c == ":" || substr(s, 1, 1) ~ /[A-Za-z0-9_:]/ || m == "::1")
    dc = index(m, "::"); if (dc && index(substr(m, dc + 2), "::")) bad = 1
    n = split(m, a, ":"); g = 0; l3 = 0; for (i = 1; i <= n; i++) if (a[i] != "") { if (length(a[i]) > 4) bad = 1; g++; if (length(a[i]) >= 3) l3 = 1 }
    if (!bad && !(dc ? (g >= 2 && g <= 7 && l3) : (g == 8 && n == 8))) bad = 1
    if (bad) { out = out pre m; continue } out = out pre mark("ip-address") }
  return out s }
function luhn(d,   i, t, x, a) { t = 0; a = 0; for (i = length(d); i >= 1; i--) { x = substr(d, i, 1) + 0; if (a) { x *= 2; if (x > 9) x -= 9 } t += x; a = !a } return (t % 10 == 0) }
function m97(v,   w, i, c, r, t) { w = substr(v, 5) substr(v, 1, 4); r = 0
  for (i = 1; i <= length(w); i++) { c = substr(w, i, 1); t = (c ~ /[A-Z]/) ? index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c) + 9 : c + 0; r = (t >= 10) ? (r * 100 + t) % 97 : (r * 10 + t) % 97 }
  return r == 1 }
function crd(s,   out, pre, m, i, j, d, n, g, p, P0) { out = ""
  while (match(s, CRR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (length(m) < 13 || !bnd(out pre) || (out pre) ~ /[0-9][.]$/ || s ~ /^([.][0-9]|[eE][-+]?[0-9])/) { out = out pre m; continue }
    # every window of whole groups, from each group (a number before the card) to the longest that is 13 to 19 digits
    n = split(m, g, "[ -]"); p = 1; for (i = 1; i <= n; i++) { P0[i] = p; p += length(g[i]) + 1 }
    for (i = 1; i <= n; i++) { d = ""; for (j = i; j <= n && length(d g[j]) <= 19; j++) d = d g[j]; for (j--; j >= i; j--) {
        if (length(d) >= 13 && d ~ /^(4|5[1-5]|2[2-7]|3[47]|6)/ && luhn(d)) break; d = substr(d, 1, length(d) - length(g[j])) } if (j >= i) break }
    if (i > n) { out = out pre m; continue }
    out = out pre substr(m, 1, P0[i] - 1) mark("card-number"); s = substr(m, P0[j] + length(g[j])) s }
  return out s }
function iba(s,   out, pre, m, i, j, d, n, g, p, P0) { out = ""
  while (match(s, IBR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!bnd(out pre)) { out = out pre m; continue }
    # every window of whole groups, from each group, the longest that is 15 to 34 characters and passes first
    n = split(m, g, "[ ]"); p = 1; for (i = 1; i <= n; i++) { P0[i] = p; p += length(g[i]) + 1 }
    for (i = 1; i <= n; i++) { if (g[i] !~ /^[A-Z][A-Z][0-9][0-9]/) continue; d = ""; for (j = i; j <= n && length(d g[j]) <= 34; j++) d = d g[j]; for (j--; j >= i; j--) {
        if (length(d) >= 15 && d ~ /^[A-Z][A-Z][0-9][0-9][A-Z0-9]+$/ && m97(d) && !(j == n && s ~ /^[A-Za-z0-9]/)) break; d = substr(d, 1, length(d) - length(g[j])) } if (j >= i) break }
    if (i > n) { out = out pre m; continue }
    out = out pre substr(m, 1, P0[i] - 1) mark("iban"); s = substr(m, P0[j] + length(g[j])) s }
  return out s }
# tkl (§4.3.6): a mixed-case run with digits, the ids a share is made of left
function tkl(s,   out, pre, m, t, L, nu, nl, nd, u, e) { out = ""
  while (match(s, TKR)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if ((e = esl(pre, m))) { pre = pre substr(m, 1, e); m = substr(m, e + 1) }
    if (m ~ /^[0-9A-Fa-f_-]+$/ || m !~ /[A-Z]/ || m !~ /[a-z]/ || m ~ TKX) { out = out pre m; continue }
    t = m; gsub(/[-_]/, "", t); L = length(t)
    if (L < 20) { out = out pre m; continue }
    u = t; nu = gsub(/[A-Z]/, "", u); u = t; nl = gsub(/[a-z]/, "", u); u = t; nd = gsub(/[0-9]/, "", u)
    if (!nu || !nl || nd < 2 || (nu + nl) * 2 < L || nu * 10 < 3 * (nu + nl) || nu * 10 > 7 * (nu + nl)) { out = out pre m; continue }
    out = out pre mark("token-like") }
  return out s }
# tkb: a base64 blob (200 or more of A-Z a-z 0-9 + /, then =), mixed case with a digit, blanked whole in one match
function tkb(s,   out, pre, m, e) { out = ""
  while (match(s, TKB)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if ((e = esl(pre, m))) { pre = pre substr(m, 1, e); m = substr(m, e + 1) }
    out = out pre ((m ~ /[A-Z]/ && m ~ /[a-z]/ && m ~ /[0-9]/) ? mark("token-like") : m) }
  return out s }
# shp: the shape rules (§4.4, §4.3.6); shpc: over pieces of about 8 KB cut after a \n, \r or \t escape or a quote, which no shape
# holds, so a long line is read in linear time
function shp(s) {
  if (s ~ CRP) s = crd(s)
  if (s ~ /[A-Z][A-Z][0-9][0-9]/) s = iba(s)
  if (index(s, "@") || index(s, "%40")) s = ema(s)
  if (index(s, "+") || s ~ /[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]/) s = phn(s)
  if (s ~ /[0-9][.][0-9]+[.][0-9]+[.][0-9]/) s = ip4(s)
  if (index(s, "::") || s ~ /[0-9A-Fa-f]:[0-9A-Fa-f]+:[0-9A-Fa-f]+:[0-9A-Fa-f]+:/) s = ip6(s)
  return tkl(s) }
function shpc(s,   out, p) { if (length(s) <= 8192) return shp(s); out = ""
  while (length(s) > 8192 && match(substr(s, 4097), /\\[nrt]|"/)) { p = 4096 + RSTART + RLENGTH - 1; out = out shp(substr(s, 1, p)); s = substr(s, p + 1) }
  return out shp(s) }
# jfx (§4.3.5): on a JSON line or a .json file’s line, a marker standing as a bare value outside any string (after : [ or , and
# before , } ] or the end) is put in quotes, so the line still parses
function jfx(s,   out, p) { JODD = 0; JT = ""; if (length(s) <= 8192) return jf1(s); out = ""
  while (length(s) > 8192 && (p = cut8(s))) { out = out jf1(substr(s, 1, p)); s = substr(s, p + 1) }
  return out jf1(s) }
# jf1: one piece; JODD whether the piece starts inside a string, JT the last 64 characters before it
function jf1(s,   out, p, e, g, m, b, a, n, P, i, t) { out = ""
  while ((p = index(s, "[REDACTED:")) > 0 && (e = index(substr(s, p), "]")) > 0) {
    g = substr(s, 1, p - 1); m = substr(s, p, e); s = substr(s, p + e)
    n = split(g, P, "\""); for (i = 1; i < n; i++) { match(P[i], /\\*$/); if (RLENGTH % 2 == 0) JODD = !JODD }
    # a marker inside a JSON number (a sign before it, a fraction or an exponent after it) takes the whole number
    t = (length(g) >= 64) ? substr(g, length(g) - 63) : substr(JT out, length(JT out) - 63 + length(g)) g
    if (match(t, /[-+.0-9eE]+$/) && substr(t, 1, RSTART - 1) ~ /(:|\[|,)[ \t]*$/ && RLENGTH <= length(g)) { m = substr(g, length(g) - RLENGTH + 1) m; g = substr(g, 1, length(g) - RLENGTH); t = substr(t, 1, RSTART - 1) }
    if (match(s, /^[-+.0-9eE]+/) && substr(s, RLENGTH + 1, 64) ~ /^[ \t]*(,|}|\]|$)/) { m = m substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1) }
    b = t; sub(/[ \t]+$/, "", b); a = substr(s, 1, 64); sub(/^[ \t]+/, "", a)
    if (!JODD && b ~ /(:|\[|,)$/ && (a == "" || a ~ /^(,|}|\])/)) m = "\"" m "\""
    out = out g m }
  n = split(s, P, "\""); for (i = 1; i < n; i++) { match(P[i], /\\*$/); if (RLENGTH % 2 == 0) JODD = !JODD }
  out = out s; JT = substr(JT out, length(JT out) - 63); return out }
# people (§4.1): each committer’s name of two words or more, as written, with - . or _ between its words and as "last, first", as
# om() matches it; past 160 of these a line is first read for their first two words
function ppl(s,   ls, t, n, W, j, k, i, x) { ls = tolower(s)
  if (np <= 160) { for (i = 1; i <= np; i++) if (index(ls, PN[i])) { s = om(s, PN[i], "person-name", 1); ls = tolower(s) } return s }
  t = ls; gsub(/\\(u[0-9a-f][0-9a-f][0-9a-f][0-9a-f]|[bfnrt])/, " ", t); gsub(/[^a-z0-9\200-\377]+/, " ", t); n = split(t, W, " ")
  for (j = 1; j < n; j++) { k = W[j] SUBSEP W[j + 1]; if (k in BG) { x = split(BG[k], I2, " "); for (i = 1; i <= x; i++) s = om(s, PN[I2[i]], "person-name", 1) } }
  return s }
# closeq: where a quoted value opened by qd (a quote after n backslashes) closes in s: the first such quote after n backslashes and
# any number of escaped backslashes at that level (c mod 2(n+1) = n; with n 0, any even number), the start of its backslashes; a quote escaped deeper belongs to the value (0 for none)
function closeq(s, qd,   n, q, b, i, p, c, f1) { n = length(qd) - 1; q = substr(qd, n + 1, 1); b = 0; f1 = 0
  while ((i = index(substr(s, b + 1), q)) > 0) { p = b + i; c = 0; while (p - c - 1 > 0 && substr(s, p - c - 1, 1) == "\\") c++
    # a single-quoted value: in a shell a backslash is literal inside, so the next single quote closes it; in code a backslashed one is
    # escaped, at any depth of JSON. Both readings are covered: a later single quote with no backslash before it closes it if there is one,
    # else the last single quote on the line does, so a value is never cut short (the last such quote, not the first)
    if (q == "\047") { if (c == n) return p - n; if (c > n) f1 = p - n; b = p; continue }   # at the depth of the opener; deeper may escape it; shallower is inside
    if (c % (2 * (n + 1)) == n) return p - n; b = p }   # the integration: a quote after n backslashes, plus any number of escaped backslashes at its level (2(n+1) a pair), closes
  return f1 }
# cq: closeq, but on a JSON line (JLN) a value opened by any quote but a bare " never reads past the
# end of the JSON string it sits in (the first quote with an even number of backslashes before it)
function cq(s, qd,   e) { if (JLN && qd != "\"" && (e = endq(s))) return closeq(substr(s, 1, e - 1), qd); return closeq(s, qd) }
# endq: where a JSON string ends in r, the first quote with an even number of backslashes before it (0 for none)
function endq(r,   p, b, i) { b = 0
  while ((i = index(substr(r, b + 1), "\"")) > 0) { p = b + i; i = p - 1; while (i > 0 && substr(r, i, 1) == "\\") i--; if ((p - 1 - i) % 2 == 0) return p; b = p }
  return 0 }
# pk: a private key, from any BEGIN … PRIVATE KEY marker to its END marker, wherever each sits: on the line, or over lines
# (inkey). With no END on the line: inside a JSON string (a JSON line, or key text holding a \n escape) to the end of the string,
# its closing quote kept; else over the following lines, to the END marker or the end of the file.
function pk(s, js,   out, r, q) { out = ""
  while (1) {
    if (inkey) { if (match(s, PKE)) { s = substr(s, RSTART + RLENGTH); inkey = 0; continue } return out }
    if (!match(s, PKB)) return out s
    out = out substr(s, 1, RSTART - 1) mark("private-key"); r = substr(s, RSTART + RLENGTH)
    if (match(r, PKE)) { s = substr(r, RSTART + RLENGTH); continue }
    q = endq(r); if (q && (js || index(substr(r, 1, q), "\\n"))) { s = substr(r, q); continue }
    inkey = 1; return out } }
function url(s,   out, pre, m, a, r, p, pw) { out = ""
  while (match(s, URL)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    a = index(m, "://"); r = substr(m, a + 3); p = index(r, ":"); pw = substr(r, p + 1, length(r) - p - 1)
    if (skipv(pw)) { out = out pre m; continue }
    out = out pre substr(m, 1, a + 2) mark("url-credentials") "@" }
  return out s }
function bear(s,   out, pre, m) { out = ""
  while (match(s, BEARER)) { pre = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    out = out pre substr(m, 1, 6) " " mark("bearer") }
  return out s }
function lit(s, x, k,   out, p, L) { L = length(x); out = ""
  while ((p = index(s, x)) > 0) { out = out substr(s, 1, p - 1) mark(k); s = substr(s, p + L) }
  return out s }
# ctx: the known value x where what comes before it matches pre (a regex ending in $) and the next character is not in nx
function ctx(s, x, k, pre, nx,   out, p, L, b, t) { L = length(x); out = ""
  while ((p = index(s, x)) > 0) { b = substr(s, 1, p - 1); t = substr(out b, length(out b) - 39 > 0 ? length(out b) - 39 : 1)
    if (t ~ pre && substr(s, p + L, 1) !~ nx) out = out b mark(k); else out = out b x
    s = substr(s, p + L) }
  return out s }
function line(s,   i, ls, jl) { jl = ISJ || (s ~ JLR); JLN = jl
  for (i = 1; i <= nl; i++) if (index(s, LIT[i])) s = lit(s, LIT[i], "literal")
  if (index(s, "gh")) s = tok(s, "github-token", GH, 1)
  if (index(s, "github_pat_")) s = tok(s, "github-token", GHP, 1)
  if (index(s, "sk-ant-")) s = tok(s, "anthropic-key", ANT, 1)
  if (index(s, "sk-")) s = tok(s, "openai-key", OAI, 1)
  if (index(s, "k_live_") || index(s, "k_test_")) s = tok(s, "stripe-key", STRIPE, 1)
  if (index(s, "AKIA") || index(s, "ASIA")) s = tok(s, "aws-key", AWSK, 1)
  if (index(s, "xox")) s = tok(s, "slack-token", SLACK, 1)
  if (index(s, "AIza")) s = tok(s, "google-key", GOOG, 1)
  if (index(s, "npm_")) s = tok(s, "npm-token", NPM, 1)
  if (index(s, "eyJ")) s = tok(s, "jwt", JWT, 1)
  if (s ~ /[Bb][Ee][Aa][Rr][Ee][Rr]/) s = bear(s)
  # 0.26.11.2 (SHARE-SCRUB §4.3, §4.4): the context rules, then the known values, then the shapes, then the identities; a long line
  # in pieces (cut8), so every rule reads it in linear time
  s = chk(s, 1, jl)
  if (length(s) > 4096) s = tkb(s)
  s = shpc(s)
  s = chk(s, 2, jl)
  if (jl && index(s, "[REDACTED:")) s = jfx(s)
  return s }
# cut8: where to cut a long line s, after 4096 characters: after a \n or \r escape, else after the end of a JSON string at depth 0
# (a quote with no backslash before it) and its comma (no value of a rule crosses either); 0 when there is no such place
function cut8(s) { if (match(substr(s, 4097), /\\[nr]|[^\\]",/)) return 4096 + RSTART + RLENGTH - 1; return 0 }
function chk(s, w, jl,   out, p) { if (length(s) <= 8192) return stg(w, s, jl); out = ""
  while (length(s) > 8192 && (p = cut8(s))) { out = out stg(w, substr(s, 1, p), jl); s = substr(s, p + 1) }
  return out stg(w, s, jl) }
function stg(w, s, jl) { return w == 1 ? ctx1(s, jl) : id1(s) }
function ctx1(s, jl,   ls, i) {
  if (s ~ AHQ) s = ahd(s, jl)
  if (index(s, "://")) s = url(s)
  if (s ~ /[Tt][Oo][Kk][Ee][Nn]/) s = asg(s, "token-header", THN, V6, 8, 1)
  if (s ~ /[Aa][Cc][Cc][Ee][Ss][Ss]/) { s = asg(s, "aws-secret-key", AWSN, "[A-Za-z0-9/+]", 40, 0); s = awp(s) }
  if (s ~ /[Aa]ccount|[Oo]rgani[sz]ation|[Oo]rg_?[Ii]d/) s = asg(s, "account-id", ACN, "[0-9A-Fa-f-]", 8, 0)
  ls = tolower(s)
  if (ls ~ SAQ) s = asg(s, "secret-assignment", SAN, VW, 1, 1)
  if (s ~ SANUQ) s = asg(s, "secret-assignment", SANU, VW, 1, 1)
  if (ls ~ PSQ) s = kv(s, "secret-assignment", PSN, 0)
  ls = tolower(s)
  if (ls ~ /(name|key)[\\"\047]*[ \t]*[:=]/ && ls ~ /value/) s = nvp(s)
  if (index(s, "</")) s = xel(s, "secret-assignment", SAN, jl)
  if (ls ~ FLQ) s = flg(s)
  if (s ~ /(^|[ \t])-[pauPUw]/ || index(s, "--user")) s = pfl(s)
  if (ls ~ CLQ) s = cal(s)
  if (ls ~ PFQ) s = kv(s, "personal-field", PFN, 0)
  if (ls ~ NFQ) s = kv(s, "personal-field", NFN, 1)
  if (index(s, "</")) { s = xel(s, "personal-field", PFN, jl); s = xel(s, "personal-field", NFN, jl, 1) }
  if (nk) { ls = tolower(s); for (i = 1; i <= nk; i++) if (index(ls, KS[i])) { s = om(s, KS[i], "known-secret", 1); ls = tolower(s) } }
  return s }
function id1(s,   i, ls) {
  for (i = 1; i <= ne; i++) if (index(s, EM[i])) s = lit(s, EM[i], "email")
  for (i = 1; i <= na; i++) if (index(s, AC[i])) s = lit(s, AC[i], "account-id")
  for (i = 1; i <= nh; i++) if (index(s, HO[i])) s = ctx(s, HO[i], "host", HPRE, "[A-Za-z0-9_-]")
  for (i = 1; i <= nn; i++) { if (index(s, NM[i])) s = ctx(s, NM[i], "user-name", UPRE, "[A-Za-z0-9_]"); if (index(s, NE[i])) s = ctx(s, NE[i], "user-name", EPRE, "[A-Za-z0-9]") }
  for (i = 1; i <= no; i++) if (index(s, OR[i])) s = om(s, OR[i], "org-name", 0)
  if (nw) { ls = tolower(s); for (i = 1; i <= nw; i++) if (index(ls, BW[i])) { s = om(s, BW[i], BK[i], 1); ls = tolower(s) } }
  if (np) s = ppl(s)
  return s }
# 0.26.10.28.9 (S3). om: the value v replaced in the text outside the [REDACTED:…] markers, so a marker is never cut into; with bare,
# as a whole word in any case (bnd before it, a character not a letter, digit or _ after it)
function om(s, v, k, bare,   o, p, q) { o = ""
  while ((p = index(s, "[REDACTED:")) > 0 && (q = index(substr(s, p), "]")) > 0) { o = o rw(substr(s, 1, p - 1), v, k, bare) substr(s, p, q); s = substr(s, p + q) }
  return o rw(s, v, k, bare) }
function rw(s, v, k, bare,   o, ls, n, p, st, b, ok) { n = length(v); ls = bare ? tolower(s) : s; o = ""; st = 1
  while ((p = index(substr(ls, st), v)) > 0) { p += st - 1; ok = 1
    if (bare) { b = substr(s, p + n, 1)
      ok = bnd(substr(s, 1, p - 1)) && (b == "" || b !~ /[A-Za-z0-9_]/) }
    if (ok) { o = o substr(s, st, p - st) mark(k); st = p + n } else { o = o substr(s, st, p - st + 1); st = p + 1 } }
  return o substr(s, st) }
function ci(w,   o, i, c) { o = ""; for (i = 1; i <= length(w); i++) { c = substr(w, i, 1); o = o (c ~ /[a-z]/ ? "[" toupper(c) c "]" : c) } return o }
function srt(A, n,   i, j, t) { for (i = 2; i <= n; i++) { t = A[i]; for (j = i - 1; j >= 1 && length(A[j]) < length(t); j--) A[j + 1] = A[j]; A[j + 1] = t } }
BEGIN { MODE = ENVIRON["SHARE_MODE"]; SCAN = (MODE == "scan")
  W = "[A-Za-z0-9]"; B64 = "[A-Za-z0-9_-]"; Q = "[\\\\\"\047]*"
  SEP = Q "[ \t]*(:=|=>|[|][|]=|[?]=|[:=])[ \t]*" Q
  V6 = "[^][ \t\"\047\\\\,;{}()<>]"
  PKB = "-----BEGIN [A-Z ]*PRIVATE KEY( BLOCK)?-----"; PKE = "-----END [A-Z ]*PRIVATE KEY( BLOCK)?-----"
  GH = "gh[pousr]_" rp(W, 20) W "*"; GHP = "github_pat_" rp("[A-Za-z0-9_]", 20) "[A-Za-z0-9_]*"
  ANT = "sk-ant-" rp(B64, 20) B64 "*"; OAI = "sk-(proj-)?" rp(B64, 32) B64 "*"
  STRIPE = "[sr]k_(live|test)_" rp(W, 10) W "*"; AWSK = "(AKIA|ASIA)" rp("[0-9A-Z]", 16)
  SLACK = "xox[baprs]-" rp("[A-Za-z0-9-]", 10) "[A-Za-z0-9-]*"; GOOG = "AIza" rp(B64, 35); NPM = "npm_" rp(W, 36)
  JWT = "eyJ" rp(B64, 10) B64 "*[.]eyJ" rp(B64, 10) B64 "*[.]" rp(B64, 8) B64 "*"
  BEARER = "[Bb][Ee][Aa][Rr][Ee][Rr][ \t]+" rp("[A-Za-z0-9._~+/-]", 16) "[A-Za-z0-9._~+/-]*=*"
  URL = "[a-z][a-z0-9+.-]*://[^][ \t:/@\"\047\\\\<>]*:[^][ \t@/\"\047\\\\<>]+@"
  THN = "[Xx]-[A-Za-z-]*[Tt][Oo][Kk][Ee][Nn]"
  AWSN = "([Aa][Ww][Ss][_-]?)?[Ss][Ee][Cc][Rr][Ee][Tt][_-]?[Aa][Cc][Cc][Ee][Ss][Ss][_-]?[Kk][Ee][Yy]"
  ACN = "([Aa]ccount|[Oo]rgani[sz]ation|[Oo]rg)[_-]?([Uu][Uu][Ii][Dd]|[Ii][Dd])"
  # 0.26.11.2 (SHARE-SCRUB §4.3.1): the one list of secret names, wider
  SAN = "([A-Za-z_][A-Za-z0-9_-]*)?([Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|[Pp][Aa][Ss][Ss][Ww][Dd]|" \
    "[Pp][Aa][Ss][Ss][Pp][Hh][Rr][Aa][Ss][Ee]|[_-][Pp][Aa][Ss][Ss]|[a-z]Pass|[_-][Pp][Ww][Dd]|[a-z]Pwd|[Cc][Rr][Ee][Dd][Ee][Nn][Tt][Ii][Aa][Ll][Ss]?|" \
    "[Aa][Uu][Tt][Hh]|[Cc][Oo][Oo][Kk][Ii][Ee]|[_-][Kk][Ee][Yy]|[Aa][Pp][Ii][Kk][Ee][Yy]|[a-z]Key|" \
    "[Ss][Ee][Cc][Rr][Ee][Tt][Ss]|[_-][Pp][Aa][Tt]|[_-][Pp][Ww]|[Ss][Ii][Gg]|[Ss][Ii][Gg][Nn][Aa][Tt][Uu][Rr][Ee])"
  SANW = "^" SAN "$"; SOP = "(:=|=>|[|][|]=|[?]=|[:=])[ \t]*"; VW = "[^ \t\"\\\\]"
  SANU = "[A-Z0-9_]*(PASSWORD|PASSWD|PASSPHRASE|SECRET|TOKEN|CREDENTIALS?|AUTH|KEY|PASS|PWD|COOKIE)(_[A-Z0-9]+)+"; SANUQ = "(PASSWORD|PASSWD|PASSPHRASE|SECRET|TOKEN|CREDENTIALS?|AUTH|KEY|PASS|PWD|COOKIE)_[A-Z0-9]"; SANUW = "^" SANU "$"
  PSN = "([Pp]ass|[Pp]wd)"; FLP = "(^|[ \t])-[a-z]*pass(in|out)?[ \t]+"; SWQ = "pass|pwd|token|secret|key|auth|cookie|credential|identified"
  IDB = "[Ii][Dd][Ee][Nn][Tt][Ii][Ff][Ii][Ee][Dd][ \t]+[Bb][Yy]"
  FLA = "--?" SAN "[ \t]+"; FLB = "(" SAN "|" IDB ")[ \t]+"
  PSEP = "[;&|`]|[$][(]|\\\\[nr]"
  UFL = "(^|[ \t])(-u|-U|--user|--username)([ \t]+|=)?\\\\*[\"\047]?[A-Za-z0-9_.@][A-Za-z0-9_.@-]*"
  CW = "(^|[ \t\"\047/\\\\;&|(`])"; CE = "([ \t\"\047]|$)"
  CLS = CW "(sshpass|7z|7za)" CE; CLM = CW "(mysql|mysqldump|mysqladmin|mariadb|mariadb-dump)" CE
  CLL = CW "((docker|podman)[ \t]+login|helm[ \t]+registry[ \t]+login)" CE; CLR = CW "redis-cli" CE; CLC = CW "(curl|wget)" CE
  AHQ = "[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn]|[Cc][Oo][Oo][Kk][Ii][Ee]"
  AHR = "(([Pp][Rr][Oo][Xx][Yy]-)?[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn]|([Ss][Ee][Tt]-)?[Cc][Oo][Oo][Kk][Ii][Ee])" Q "[ \t]*:[ \t]*" Q
  NVR = "([Nn][Aa][Mm][Ee]|[Kk][Ee][Yy])" Q "[ \t]*[:=][ \t]*" Q "(" SAN "|" ci("authorization") ")" Q "[ \t]*,?[ \t]*" Q "[Vv][Aa][Ll][Uu][Ee]" Q "[ \t]*[:=][ \t]*" Q
  NVV = "[Vv][Aa][Ll][Uu][Ee]" Q "[ \t]*[:=][ \t]*" Q; NVN = "^" Q "[ \t]*,?[ \t]*" Q "([Nn][Aa][Mm][Ee]|[Kk][Ee][Yy])" Q "[ \t]*[:=][ \t]*" Q "(" SAN "|" ci("authorization") ")" Q
  # the personal field names (§4.4.4): any case, _ or - between their words or none, after a prefix ending _ or -, or camel-cased
  split("first,name last,name full,name given,name family,name middle,name maiden,name surname birth,date date,of,birth dob birthday " \
    "phone,no mobile,no passport,no contact,number cell msisdn national,insurance,number nino tax,number birth born " \
    "line1 line2 social,security,number account,number sort,code routing,number driver,license drivers,license license,number " \
    "phone phone,number telephone tel mobile mobile,number fax address street address,line postcode post,code postal,code zip zip,code ssn national,id passport passport,number " \
    "tax,id iban card,number cvv cvc email", PW, " ")
  PA = ""; PC = ""; for (i = 1; i in PW; i++) { nb = split(PW[i], PB, ","); a = ""; c = ""
    for (j = 1; j <= nb; j++) { a = a (j > 1 ? "[_-]?" : "") ci(PB[j]); c = c (j > 1 ? "[_-]?" : "") (j == 1 ? toupper(substr(PB[j], 1, 1)) ci(substr(PB[j], 2)) : ci(PB[j])) }
    if (PW[i] == "address,line" || PW[i] == "address") { a = a "[0-9]?"; c = c "[0-9]?" }
    PA = PA (PA == "" ? "" : "|") a; PC = PC (PC == "" ? "" : "|") c }
  PFN = "(([A-Za-z0-9_-]*[_-])?(" PA ")|[A-Za-z0-9_-]*[a-z](" PC "))"
  NFN = "(([A-Za-z0-9_-]*[_-])?" ci("name") "|[A-Za-z0-9_-]*[a-z]Name|" ci("author") "|" ci("user") "|" ci("username") "|" ci("owner") "|" ci("contact") "|" \
    ci("customer") "|" ci("sender") "|" ci("recipient") "|" ci("from") "|" ci("to") ")"
  # the gates: a field word right before a separator (any quote and spaces between), on the line in lower case
  # the gate: the endings of every personal field name above, on the line in lower case
  PFQ = "(name|birth|born|date|day|dob|phone|no|number|tel|mobile|cell|msisdn|fax|address[0-9]?|street|line[0-9]?|code|zip|ssn|nino|national[_-]?id|tax[_-]?id|passport|iban|cvv|cvc|email|licen[cs]e)" Q "[ \t]*(:|=|[?]=|[|][|]=)"
  # the gates of the secret rules, on the line in lower case: a secret word right before a separator; before spaces (a flag, a
  # quoted value, IDENTIFIED BY)
  SAQ = "(token|secrets?|password|passwd|passphrase|pass|pwd|credentials?|auth|cookie|key|pat|pw|sig|signature)" Q "[ \t]*(:|=|[?]=|[|][|]=)"
  PSQ = "(^|[^a-z0-9_])(pass|pwd)" Q "[ \t]*(:|=|[?]=|[|][|]=)"
  FLQ = "(token|secrets?|password|passwd|passphrase|pass|pwd|credentials?|auth|cookie|key|pat|pw|sig|signature|identified[ \t]+by)[ \t]+"
  CAL1 = "[[(, \t]\\\\*[\"\047]" SAN "\\\\*[\"\047][ \t]*(\\][ \t]*:?=|,)[ \t]*\\\\*[\"\047]"; CAL2 = "[A-Za-z_.]*" SAN "[ \t]*[(][ \t]*\\\\*[\"\047]"
  CLQ = "(token|secrets?|password|passwd|passphrase|pass|pwd|credentials?|auth|cookie|key|pat|pw|sig|signature)(\\\\*[\"\047][ \t]*(\\]|,)|[ \t]*[(])"
  NFQ = "(name|author|user|owner|contact|customer|sender|recipient|from|to)" Q "[ \t]*[:=]"
  VL = "[^][\"\047\\\\,;{}<>]"; VLW = "[^][\"\\\\;{}<>]"   # after a quoted name (a JSON value); after an unquoted one (YAML, ini: a name with an apostrophe, an address with commas)
  EMR = "[A-Za-z0-9._%+\200-\377-]+@[A-Za-z0-9\200-\377-]+([.][A-Za-z0-9\200-\377-]+)*[.][A-Za-z\200-\377][A-Za-z\200-\377]+"
  EMP = "[A-Za-z0-9._+\200-\377-]+%40[A-Za-z0-9\200-\377-]+([.][A-Za-z0-9\200-\377-]+)*[.][A-Za-z\200-\377][A-Za-z\200-\377]+"
  PHA = "[+][1-9][0-9 ().-]*[0-9]"; PHB = "([(][0-9][0-9][0-9][)] ?|[0-9][0-9][0-9]-)[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]"
  IP4 = "[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+"; IP6 = "[0-9A-Fa-f]*:[0-9A-Fa-f:]*:[0-9A-Fa-f]*"
  CRR = "[0-9]+([ -][0-9]+)*"; CRP = "[2-6][0-9][0-9][0-9][ -]?[0-9][0-9][0-9][0-9][0-9]?[0-9]?[ -]?[0-9][0-9][0-9][0-9]"   # 4, 4 to 6, 4 digits (4-4-4-4, 4-6-5, plain)
  IBR = "[A-Z][A-Z][0-9][0-9][A-Z0-9]*( [A-Z0-9]+)*"
  TKR = rp("[A-Za-z0-9_-]", 20) "[A-Za-z0-9_-]*"; TKX = "^(toolu_|srvtoolu_|msg_|req_|cse_|file_|session_)"; JLR = "^[ \t]*([{][ \t]*(\"|[}]|$)|\\[[ \t]*([[{\"]|\\]|$))"; TKB = rp("[A-Za-z0-9+/]", 200) "[A-Za-z0-9+/]*=*"
  for (i = 1; i < 256; i++) ORD[sprintf("%c", i)] = i
  HPRE = "(@|[Hh][Oo][Ss][Tt]([Nn][Aa][Mm][Ee])?" Q "[ \t]*[:=\t][ \t]*" Q ")$"
  UPRE = "[/\\\\]+([Uu]sers|home)[/\\\\]+$"; EPRE = "-([Uu]sers|home)-$"
  KF = ENVIRON["SHARE_KNOWN"]; SGR = "(\\\\u001[bB]|\\\\x1[bB]|" sprintf("%c", 27) ")\\[[0-9;]*m$"
  # the words a transcript, a marker or the folders of the bundle are made of, never taken as a bare name or an organisation (S3)
  n = split("vid records logs conversations subagents findings user assistant system tool human type role content text message name home root admin redacted literal github token anthropic key openai stripe aws slack google npm jwt bearer url secret assignment header account email host org author password private", X, " ")
  for (i = 1; i <= n; i++) STOP[X[i]] = 1
  STOP["claude"] = 1
  if (KF != "") while ((getline l < KF) > 0) { t = index(l, "\t"); if (!t) continue; k = substr(l, 1, t - 1); v = substr(l, t + 1); if (v == "") continue
    if (k == "name") { NM[++nn] = v; e = v; gsub(/[\200-\277]/, "", e); gsub(/[^A-Za-z0-9]/, "-", e); NE[nn] = e }
    else if (k == "email" && length(v) >= 5) { EM[++ne] = v; if (pe(v) != v) EM[++ne] = pe(v) }
    else if (k == "account" && length(v) >= 8) AC[++na] = v
    else if (k == "host" && length(v) >= 2) HO[++nh] = v
    else if (k == "literal-file") while ((getline x < v) > 0) { sub(/\r$/, "", x); if (length(x) >= 3) LIT[++nl] = x }
    else if (k == "secret-file") denv(v)
    else if (k == "person" && (x = split(v, X2, " ")) >= 2) { lv = tolower(v); if (!(lv in PNS)) { PNS[lv] = 1
        # the name as written, with - . or _ between its words, and as "last, first" (adversarial 1)
        e = lv; gsub(/[^a-z0-9\200-\377]+/, " ", e); split(e, X3, " "); y = tolower(X2[x]) ", " tolower(X2[1]); for (j = 2; j < x; j++) y = y " " tolower(X2[j])
        PV[1] = lv; PV[2] = rep(e, " ", "-"); PV[3] = rep(e, " ", "."); PV[4] = rep(e, " ", "_"); PV[5] = y
        for (j = 1; j <= 5; j++) if (!(PV[j] in PNV)) { PNV[PV[j]] = 1; PN[++np] = PV[j]; z = PV[j]; gsub(/[^a-z0-9\200-\377]+/, " ", z); split(z, X4, " "); BG[X4[1] SUBSEP X4[2]] = BG[X4[1] SUBSEP X4[2]] " " np } } }
    else if (k == "org" && !(tolower(v) in STOP)) { if (length(v) >= 3) OR[++no] = v; else BS[tolower(v)] = "org-name" }
    if ((k == "name" || k == "author") && length(v) >= 3 && !(tolower(v) in STOP)) { lv = tolower(v); if (!(lv in BS) || (k == "author" && BS[lv] != "org-name")) BS[lv] = (k == "author" ? "author-name" : "user-name") } }
  for (lv in BS) { BW[++nw] = lv; BK[nw] = BS[lv] }
  for (i = 2; i <= nw; i++) { t = BW[i]; u = BK[i]; for (j = i - 1; j >= 1 && (length(BW[j]) < length(t) || (length(BW[j]) == length(t) && BW[j] > t)); j--) { BW[j + 1] = BW[j]; BK[j + 1] = BK[j] } BW[j + 1] = t; BK[j + 1] = u }
  # SHARE-SCRUB §4.1: the environment’s secret-named values and every value’s URL password; the known values longest first
  for (k in ENVIRON) { if (k ~ SANW || k ~ SANUW) aks(ENVIRON[k]); if (index(ENVIRON[k], "://")) urlpw(ENVIRON[k]) }
  srt(KS, nk)
  srt(LIT, nl); srt(OR, no); srt(EM, ne); srt(AC, na); srt(HO, nh)
  for (i = 2; i <= nn; i++) { t = NM[i]; u = NE[i]; for (j = i - 1; j >= 1 && length(NM[j]) < length(t); j--) { NM[j + 1] = NM[j]; NE[j + 1] = NE[j] } NM[j + 1] = t; NE[j + 1] = u } }
'
REDONE='FNR == 1 { ISJ = (FILENAME ~ /[.]json$/) }
{ s = $0; w = inkey; if (inkey || index(s, "PRIVATE KEY")) s = pk(s, ($0 ~ /^[ \t]*[[{]/)); if (w && s == "") next
  s = line(s); if (!SCAN) print s }
END { if (SCAN) { for (k in C) printf "%s\t%d\n", k, C[k] } else if (MODE == "redact" && ENVIRON["SHARE_COUNTS"] != "") { for (k in C) printf "%s\t%d\n", k, C[k] > ENVIRON["SHARE_COUNTS"] } }'
# 0.26.10.28.9 (S1): the same redactor over many files in one awk. ENVIRON SHARE_MAP: `<input>\t<output>\t<name>` lines, the output
# the file it writes in redact mode, the name its counts carry; SHARE_COUNTS gets `<name>\t<kind>\t<n>`, a file's kinds in order. At each
# file the last one's counts are written and cleared, inkey reset and its output closed, so no state crosses files (an empty file, never
# read, has none)
REDMANY='function fl(   n, i, j, t, K) { if (CUR == "") return; n = 0; for (t in C) K[++n] = t
    for (i = 2; i <= n; i++) { t = K[i]; for (j = i - 1; j >= 1 && K[j] > t; j--) K[j + 1] = K[j]; K[j + 1] = t }
    for (i = 1; i <= n; i++) printf "%s\t%s\t%d\n", CUR, K[i], C[K[i]] >> CF
    if (!SCAN) close(OUT); split("", C); inkey = 0; CUR = "" }
  BEGIN { CF = ENVIRON["SHARE_COUNTS"]; MF = ENVIRON["SHARE_MAP"]; while ((getline l < MF) > 0) { split(l, F, "\t"); MO[F[1]] = F[2]; MN[F[1]] = F[3] } }
  FNR == 1 { fl(); CUR = MN[FILENAME]; OUT = MO[FILENAME]; inkey = 0; ISJ = (CUR ~ /[.]json$/) }
  { s = $0; w = inkey; if (inkey || index(s, "PRIVATE KEY")) s = pk(s, ($0 ~ /^[ \t]*[[{]/)); if (w && s == "") next
    s = line(s); if (!SCAN) print s > OUT }
  END { fl() }'
RED="$REDLIB$REDONE"; REDM="$REDLIB$REDMANY"
# 0.26.10.28.9 (S1, S2): a few programs a pass, never one a file.
# xa <program and args>: the program over the file list on stdin, one a line, in as few runs as the system allows. An awk program
# run this way is read from a file (awkf), never passed on the command line, so the line's limit on Git Bash leaves room for files
xa() { tr '\n' '\0' | xargs -0 "$@"; }
awkf() { [ -f "$W/redm.awk" ] || { printf '%s\n' "$REDM" > "$W/redm.awk"; printf '%s\n' "$STATS" > "$W/stats.awk"; }; }
# snapshot: every listed source copied once, by one tar pipe that follows links, into $W/snap; the harvest, the binary test, the
# sizes and the redaction read that copy, so a file that grows during the build is taken as tar read it, never left out. Each source
# is named to tar as a plain absolute path: a Windows one (C:\…) in its POSIX form on Git Bash or Cygwin, a relative one from here,
# . taken out and a folder with .. found by the system; GNU tar is told not to read escapes in the names. $W/list.c is the list with each copy's path. A file tar
# reports changed is not fatal (GNU tar exits 1 for it): a copy that is not there is left out when it is read
snapshot() {
  mkdir -p "$W/snap"; _wd=$(pwd -P); _dp=''
  case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*) _dp=/ ;; CYGWIN*) _dp=/cygdrive/ ;; esac
  cut -f2 "$W/list" | awk -v WD="$_wd" -v DP="$_dp" '!s[$0]++ { p = $0
      if (DP != "" && p ~ /^[A-Za-z]:[\\\/]/) { p = DP tolower(substr(p, 1, 1)) substr(p, 3); gsub(/\\/, "/", p) } else if (substr(p, 1, 1) != "/") p = WD "/" p
      n = split(p, a, "/"); m = 0; for (i = 1; i <= n; i++) { if (a[i] == "" || a[i] == ".") continue; b[++m] = a[i] }
      q = ""; for (i = 1; i <= m; i++) q = q "/" b[i]; print $0 "\t" q }' > "$W/snapmap.0"
  # a path with .. in it has its folder found by the system (through any link), never by taking a name off the text
  while IFS="$TAB" read -r o q; do
    case "$q" in */../*|*/..) _d=$(cd -P "${q%/*}" 2>/dev/null && pwd -P) && q=$_d/${q##*/} ;; esac
    printf '%s\t%s\n' "$o" "$q"
  done < "$W/snapmap.0" > "$W/snapmap"
  cut -f2 "$W/snapmap" | sed 's|^/||' > "$W/srcs"
  awk -F'\t' -v SN="$W/snap" 'FILENAME == ARGV[1] { c[$1] = SN $2; next } { print $0 "\t" c[$2] }' "$W/snapmap" "$W/list" > "$W/list.c"
  _tf=''; if tar --version 2>/dev/null | grep -q 'GNU tar'; then _tf='--no-unquote --verbatim-files-from'; fi
  # shellcheck disable=SC2086
  [ ! -s "$W/srcs" ] || { tar -C / -c -h -f - $_tf -T "$W/srcs" 2> "$W/tar.err" | ( cd "$W/snap" && tar -x -f - 2>> "$W/tar.err" ); } || true
}
# sizes <list of files>: `<file>\t<bytes>\t<newlines>` for each, from one wc, its lines paired with the list by position (wc may
# print a name otherwise than it was given); a total line, from a run over more than one file, is skipped (every name is a path)
sizes() { [ -s "$1" ] || return 0; LC_ALL=C xa wc -l -c < "$1" | awk -v L="$1" '{ sub(/^[ \t]*/, ""); l = $1; sub(/^[0-9]+[ \t]+/, ""); n = $1; sub(/^[0-9]+[ \t]/, "")
    if ($0 != "total" && (getline f < L) > 0) print f "\t" n "\t" l }'; }

# put: every listed file written to the bundle at $NB, gzipped by its rule; a file that is not text is left out
put() { awkf
: > "$W/gz"; : > "$W/written"; : > "$W/in"; : > "$W/rmap"; : > "$W/rmap.r"; : > "$W/cnt"; : > "$W/empty"; mkdir -p "$W/gzi" "$W/gzo"
  # a path that holds a value redaction covers (a literal, a user name) is left out, listed by its redacted path
  cut -f1 "$W/list" | SHARE_MODE=plain SHARE_KNOWN=$W/known LC_ALL=C awk "$RED" > "$W/relred"
  # a source listed twice (a logs folder inside the records) is read once a row: the second row's copy is its own
  awk -F'\t' 'NR == FNR { r[FNR] = $0; next } { print r[FNR] "\t" $0 "\t" (($4 in s) ? "dup" : ""); s[$4] = 1 }' "$W/relred" "$W/list.c" > "$W/list.r"
  # the inputs: each source's copy, a gzipped one unzipped first (one program each)
  k=0; : > "$W/rows"
  # what put leaves out is listed in the list's order, as each row is reached: `<row>\t<path>\t<why>`, sorted at the end
  plo() { printf '%s\t%s\t%s\n' "$k" "$1" "$2" >> "$W/lo.p"; }; : > "$W/lo.p"
  while IFS="$TAB" read -r rr rel f cls c dup; do
    k=$((k + 1))
    if [ "$rr" != "$rel" ]; then plo "$rr" 'its path holds a value redaction covers, so it is not copied'; continue; fi
    if [ ! -f "$c" ]; then plo "$rel" 'it could not be copied (it went, or could not be read, during the build)'; continue; fi
    # SHARE-SCRUB §4.5.1: a file that exists to hold secrets is never copied, wherever it sits
    case "${rel##*/}" in .env|.env.*|.env-*|*.env|.envrc|*.pem|*.key|*.p12|*.pfx|id_rsa|id_dsa|id_ecdsa|id_ed25519|.netrc|.pgpass|credentials|credentials.*)
      plo "$rel" 'a file that holds secrets by its name, never copied'; continue ;; esac
    if [ "$dup" = dup ]; then cp "$c" "$W/gzi/$k.d"; c=$W/gzi/$k.d; fi
    isgz=no
    case "$rel" in *.gz) gzip -dc < "$c" > "$W/gzi/$k" 2>/dev/null || { plo "$rel" 'not a readable gzip, so it cannot be read for secrets'; continue; }; c=$W/gzi/$k; isgz=yes ;; esac
    printf '%s\n' "$c" >> "$W/in"; printf '%s\t%s\t%s\t%s\t%s\n' "$k" "$rel" "$c" "$cls" "$isgz" >> "$W/rows"
  done < "$W/list.r"
  # the binary test: one wc gives each file's size and newlines, one awk its lines and their bytes (each line's length and its newline).
  # A file is text when the awk read exactly its bytes: as many lines as newlines and that many bytes, or one line more (no final
  # newline) and one byte more; and no line holds a NUL where the awk keeps NULs. An awk that cuts a line at a NUL counts short
  sizes "$W/in" > "$W/insz"
  [ ! -s "$W/in" ] || LC_ALL=C xa awk 'BEGIN { Z = "\0"; zk = (length(Z) == 1) } FNR == 1 { if (f != "") print f "\t" b "\t" z "\t" r; f = FILENAME; b = 0; z = 0 }
    { b += length($0) + 1; r = FNR; if (zk && index($0, Z)) z = 1 } END { if (f != "") print f "\t" b "\t" z "\t" r }' < "$W/in" > "$W/inby"
  awk -F'\t' 'FILENAME == ARGV[1] { sz[$1] = $2; nl[$1] = $3; next } FILENAME == ARGV[2] { by[$1] = $2; zz[$1] = $3; nr[$1] = $4; next }
    { c = $3; n = (c in sz) ? sz[c] : -1; b = (c in by) ? by[c] : 0; r = (c in nr) ? nr[c] : 0
      t = (n >= 0 && !zz[c] && ((r == nl[c] && b == n) || (r == nl[c] + 1 && b == n + 1)))
      print $0 "\t" (t ? "text" : "binary") "\t" n }' "$W/insz" "$W/inby" "$W/rows" > "$W/rows.t"
  while IFS="$TAB" read -r k rel c cls isgz kind n; do
    if [ "$kind" != text ]; then plo "$rel" "binary: not text, so it cannot be read for secrets ($n bytes)"; continue; fi
    out=$NB/$rel
    if [ "$isgz" = yes ] || gzr "$cls" "$rel" "$n"; then case "$out" in *.gz) ;; *) out=$out.gz ;; esac; w=$W/gzo/$k; else w=$out; fi
    printf '%s\t%s\t%s\n' "$c" "$w" "${out#"$NB"/}" >> "$W/rmap"; printf '%s\t%s\t%s\t%s\t%s\n' "$k" "${out#"$NB"/}" "$w" "$cls" "$n" >> "$W/rmap.r"
    [ "$n" != 0 ] || printf '%s\n' "$w" >> "$W/empty"
  done < "$W/rows.t"
  LC_ALL=C sort -t "$TAB" -k1,1n -s "$W/lo.p" | cut -f2- >> "$W/leftout"
  [ -s "$W/rmap" ] || return 0
  # the redaction: one awk over every text file, each written to its own output; its counts per file
  awk -F'\t' -v NB="$NB" '{ d = NB "/" $2; sub(/\/[^\/]*$/, "", d); if (!s[d]++) print d }' "$W/rmap.r" | xa mkdir -p
  # an empty file is never read by the awk, so it is made here
  while IFS= read -r w; do : > "$w"; done < "$W/empty"
  cut -f1 "$W/rmap" | SHARE_MODE=redact SHARE_KNOWN=$W/known SHARE_MAP=$W/rmap SHARE_COUNTS=$W/cnt LC_ALL=C xa awk -f "$W/redm.awk"
  # gzipped by its rule (one program a gzipped file), then the rows the manifest and the summary read, in the list's order
  while IFS="$TAB" read -r k rel w cls n; do case "$w" in "$W/gzo/"*) gzip -9n < "$w" > "$NB/$rel" ;; esac; done < "$W/rmap.r"
  awk -F'\t' -v G="$W/gzo/" -v NB="$NB" 'index($3, G) == 1 { print $3; print NB "/" $2 }' "$W/rmap.r" > "$W/gzl"; sizes "$W/gzl" > "$W/gzsz"
  awk -F'\t' -v G="$W/gzo/" -v NB="$NB" -v W="$W" 'FILENAME == ARGV[1] { sz[$1] = $2; next }
    { print $2 "\t" $4 > (W "/written"); if (index($3, G) == 1) print $2 "\t" sz[$3] "\t" sz[NB "/" $2] > (W "/gz") }' "$W/gzsz" "$W/rmap.r"
  cat "$W/cnt" >> "$W/redactions"
}

# namecheck (SHARE-SCRUB §4.5.3): the project's and the run's names name the bundle's folder, the archive's members and the pushed
# folder and its commit message, which no scan reads: a project name redaction changes becomes project, and a run name it changes
# is refused (the default one made again from the new project name first)
namecheck() {
  _nc() { printf '%s\n' "$1" | SHARE_MODE=plain SHARE_KNOWN=$W/known LC_ALL=C awk "$RED"; }
  [ "$(_nc "$PROJ")" = "$PROJ" ] || { PROJ=project; [ -n "$RUNGIVEN" ] || RUN="$RUNPFX-$PROJ"; }
  [ "$(_nc "$RUN")" = "$RUN" ] || die "refused — the run name holds a value redaction covers; give another with --run <name>."
  B=$OUTROOT/$RUN
}

# dotenvs (SHARE-SCRUB §4.1): `secret-file\t<path>` for each dotenv file (not a template) under the home, the logs folder and each
# taken transcript's recorded cwd (never /, the user's home folder or a folder above it), outside .git and node_modules; read by
# the redactor, which takes their secret-named values and URL passwords. Never their values: .known holds paths alone
dotenvs() {
  _hh=$(cd "$HOME" 2>/dev/null && pwd -P || printf '%s' "$HOME")
  { printf '%s\n' "$H"; [ -z "$LOGS" ] || printf '%s\n' "$LOGS"
    [ ! -s "$W/convs" ] || xa grep -ohE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' < "$W/convs" 2>/dev/null | sed 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\/\\/g' || true
  } | awk '!s[$0]++' | while IFS= read -r d; do
    [ -n "$d" ] && [ -d "$d" ] || continue; d=$(cd "$d" 2>/dev/null && pwd -P) || continue
    [ "$d" != / ] || continue; case "$_hh/" in "$d"/*) continue ;; esac
    find "$d" \( -name .git -o -name node_modules \) -prune -o -type f \( -name .env -o -name '.env.*' -o -name '.env-*' -o -name '*.env' -o -name .envrc \) \
      ! -name '*.example' ! -name '*.sample' ! -name '*.template' ! -name '*.dist' -print 2>/dev/null
  done | awk '!s[$0]++ { print "secret-file\t" $0 }'
}

# people (SHARE-SCRUB §4.1): `person\t<name>` and `email\t<address>` for every author, committer and Co-authored-by of the home's
# history and of each repository the walk left out; never a [bot], an address at .invalid, noreply@anthropic.com or noreply@github.com
people() {
  # the home, each left-out folder, and each repository inside one (a clone in logs/clones/<name>), as deep as 4
  { printf '%s\n' "$H"; cat "$W/pruned.all" 2>/dev/null
    while IFS= read -r d; do [ -d "$d" ] || continue; case "${d##*/}" in node_modules|__pycache__) continue ;; esac
      find "$d" -maxdepth 4 \( -name node_modules -prune \) -o -name .git -print 2>/dev/null | sed 's|/\.git$||'; done < "$W/pruned.all"
  } | awk '!s[$0]++' | while IFS= read -r d; do
    [ -e "$d/.git" ] || [ -f "$d/HEAD" ] || continue
    git -C "$d" log --all --format='%an%x09%ae%n%cn%x09%ce%n%(trailers:key=Co-authored-by,valueonly)' 2>/dev/null || true
  done | awk -F'\t' 'NF < 2 { if (!match($0, /<[^>]*>/)) next; e = substr($0, RSTART + 1, RLENGTH - 2); n = substr($0, 1, RSTART - 1) }
    NF >= 2 { n = $1; e = $2 } { sub(/^[ \t]+/, "", n); sub(/[ \t]+$/, "", n); le = tolower(e) }
    n == "" || n ~ /\[bot\]$/ || le ~ /[.]invalid$/ || le == "noreply@anthropic.com" || le == "noreply@github.com" { next }
    !s[n]++ { print "person\t" n } e != "" && !t[e]++ { print "email\t" e }'
}

# known: the personal values redaction looks for, one `<kind>\t<value>` a line in $W/known. User names: $HOME's, when it
# sits in a Users or home folder, and each name after a home prefix in the events file (whatever is left out) and every
# transcript path the events or the user named; emails: git config's, the session context's ("the user's email address
# is …") and an email field's; account and organisation ids from the transcripts' fields, JSON's spaces and escapes allowed;
# the host name (VID_SHARE_HOST stands in for it in the self-test) and its first label; the user's file of literals, by its path.
# 0.26.10.28.9 (S3): $USERNAME as a user name; git's author name and each word of it; Claude's orgName from the transcripts. The
# transcripts are read from the snapshot. The GitHub login is not harvested (a name equal to it is redacted all the same)
known() {
  { case "$(basename "$(dirname "$HOME")")" in [Uu]sers|home) printf 'name\t%s\n' "$(basename "$HOME")" ;; esac
    { [ ! -f "$EVF" ] || cat "$EVF"; cut -f2 "$W/named.u" 2>/dev/null; cut -f2 "$W/took" 2>/dev/null; printf '%s/\n' "$HOME"; } | LC_ALL=C awk '{ s = $0
      while (match(s, /[\/\\]+([Uu]sers|home)[\/\\]+[^\/\\"=]+[\/\\]/)) { m = substr(s, RSTART, RLENGTH - 1); s = substr(s, RSTART + RLENGTH - 1); sub(/^[\/\\]+([Uu]sers|home)[\/\\]+/, "", m); print "name\t" m } }'
    e=$(cd "$H" && git config user.email 2>/dev/null || true); [ -z "$e" ] || printf 'email\t%s\n' "$e"
    # the author (S3): git's user name, whole and each word of it
    a=$(cd "$H" && git config user.name 2>/dev/null || true); if [ -n "$a" ]; then printf 'author\t%s\n' "$a"; printf '%s\n' "$a" | tr -s ' \t' '\n\n' | sed 's/^/author	/'; fi
    [ -z "${USERNAME:-}" ] || printf 'name\t%s\n' "$USERNAME"
    # the transcripts' values, read from the snapshot, one grep a kind over them all
    awk -F'\t' '$3 == "conv" && !s[$4]++ { print $4 }' "$W/list.c" | while IFS= read -r c; do [ ! -f "$c" ] || printf '%s\n' "$c"; done > "$W/convs"
    if [ -s "$W/convs" ]; then
      xa grep -ohE '(email address is[[:space:]]+|(emailAddress|userEmail|email)[\\"]*[[:space:]]*:[[:space:]]*[\\"]*)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]+' < "$W/convs" 2>/dev/null | sed 's/.*[^A-Za-z0-9._%+-]\([A-Za-z0-9._%+-]*@\)/email	\1/' || true
      xa grep -ohE '(accountUuid|organizationUuid|account_uuid|organization_uuid)[\\"]*[[:space:]]*:[[:space:]]*[\\"]*[0-9a-fA-F-]{36}' < "$W/convs" 2>/dev/null | sed 's/.*[^0-9a-fA-F-]\([0-9a-fA-F-]\{36\}\)$/account	\1/' || true
      # Claude's organisation name (S3): the value runs to the first backslash or quote; its \u escapes are not decoded
      xa grep -ohE 'orgName[\\"]*[[:space:]]*:[[:space:]]*\\*"[^\\"]+' < "$W/convs" 2>/dev/null | sed 's/^orgName[\\"]*[[:space:]]*:[[:space:]]*\\*"[[:space:]]*//; s/[[:space:]]*$//; s/^/org	/' || true
    fi
    dotenvs; people
    h=${VID_SHARE_HOST:-$(hostname 2>/dev/null || uname -n)}; if [ -n "$h" ]; then printf 'host\t%s\n' "$h"; [ "${h%%.*}" = "$h" ] || printf 'host\t%s\n' "${h%%.*}"; fi
    [ -z "$LITFILE" ] || printf 'literal-file\t%s\n' "$(cd "$(dirname "$LITFILE")" && pwd -P)/$(basename "$LITFILE")"
  } | awk '!s[$0]++' > "$W/known"
}

# scanfolder <folder> <known file>: `<file>\t<kind>\t<n>` for every match left. Every file the folder holds is read back,
# whatever its name: a split file's parts rejoined from .part-000 and named by it; a part with no .part-000 read alone; a
# gzipped one unzipped, `unreadable` when it does not unzip. Every path is read too (`<kind> in the path`). Nothing printed
# means nothing left. Needs $W, a folder of its own.
scanfolder() { awkf
  ( cd "$1" && find . -type f -print ) | sed 's|^\./||' | LC_ALL=C sort > "$W/sf.files"
  # every path redacted first: a finding names a file by its redacted path, never a value its name holds
  SHARE_MODE=plain SHARE_KNOWN=$2 LC_ALL=C awk "$RED" "$W/sf.files" | awk 'NR == FNR { r[FNR] = $0; next } { print r[FNR] "\t" $0 }' - "$W/sf.files" > "$W/sf.pairs"
  awk -F'\t' '$1 != $2 { print $1 "\tvalue in the path\t1" }' "$W/sf.pairs"
  # each file, or a split file's parts, as one unit k: its input (unzipped or rejoined first, one program each, else the file
  # itself) for one awk over them all; `unreadable` rows keyed k 0 and the unit's findings k 1, so the output keeps the file order
  rm -rf "$W/sfu"; mkdir -p "$W/sfu"; : > "$W/sf.u"; : > "$W/sf.map"; : > "$W/sf.rf"; k=0
  while IFS="$TAB" read -r rf f; do
    b=$f; grp=no
    case "$f" in *.part-[0-9][0-9][0-9]) b=${f%.part-[0-9][0-9][0-9]}
      if [ -f "$1/$b.part-000" ]; then [ "$f" = "$b.part-000" ] || continue; grp=yes
      else case "$b" in *.gz) printf '%s\t0\t%s\tunreadable\t1\n' "$((k + 1))" "$rf" >> "$W/sf.u" ;; esac; b=$f; fi ;; esac
    k=$((k + 1)); u=$1/$f
    if [ "$grp" = yes ]; then u=$W/sfu/$k.raw; cat "$1/$b".part-[0-9][0-9][0-9] > "$u"; fi
    case "$b" in *.gz) if ! gzip -dc < "$u" > "$W/sfu/$k" 2>/dev/null; then printf '%s\t0\t%s\tunreadable\t1\n' "$k" "$rf" >> "$W/sf.u"; fi; u=$W/sfu/$k ;; esac
    printf '%s\t-\t%s\n' "$u" "$k" >> "$W/sf.map"; printf '%s\t%s\n' "$k" "$rf" >> "$W/sf.rf"
  done < "$W/sf.pairs"
  : > "$W/sf.c"
  [ ! -s "$W/sf.map" ] || cut -f1 "$W/sf.map" | SHARE_MODE=scan SHARE_KNOWN=$2 SHARE_MAP=$W/sf.map SHARE_COUNTS=$W/sf.c LC_ALL=C xa awk -f "$W/redm.awk"
  awk -F'\t' 'FILENAME == ARGV[1] { R[$1] = $2; next } FILENAME == ARGV[2] { print; next } { print $1 "\t1\t" R[$1] "\t" $2 "\t" $3 }' "$W/sf.rf" "$W/sf.u" "$W/sf.c" |
    LC_ALL=C sort -t "$TAB" -k1,1n -k2,2n -s | cut -f3-
}

# cut_big: a file over the limit cut into <file>.part-000 …, each under it
cut_big() {
  : > "$W/split"
  find "$NB" -type f -size +"${SPLIT}"c | LC_ALL=C sort | while IFS= read -r f; do
    sz=$(size "$f"); i=0; n=$(( (sz + SPLIT - 1) / SPLIT ))
    while [ "$i" -lt "$n" ]; do dd if="$f" of="$f.part-$(printf '%03d' "$i")" bs="$SPLIT" skip="$i" count=1 2>/dev/null; i=$((i + 1)); done
    rm -f "$f"; printf '%s\t%s\n' "${f#"$NB"/}" "$n" >> "$W/split"
  done
}

# SHARE-SCRUB §5: what is caught for certain, by rule, and not at all, in the summary, the manifest, the review page and the skill
LC1='every whole-token copy of the secret-named values of the environment and of the dotenv files read (6 characters or more), the URL passwords in them, your own names, user name, emails, ids and host, the committers of two words or more in the repositories, and the words of your file; every private key; every email address; binary files and secrets files left out'
LC2='secret-named flags, assignments, quoted values, headers and XML elements, URL credentials and Bearer tokens, a password given by the p flag beside a user flag, or to sshpass, the mysql and mariadb clients, redis-cli and docker, podman and helm registry login; the known token shapes and mixed-case tokens with digits; phone numbers, IP addresses, card numbers and IBANs; named personal fields (names, birth dates, addresses, postcodes, ids)'
LC3='a secret with no secret-named context or known shape (login admin <v>) or after -p elsewhere; a value caught in one place and bare in another; other people'"'"'s names in free text, CSV or SQL rows, one-word names; addresses, birth dates and ids in free text; GitHub logins; read the review page, and look before you send'

# js: a JSON string of $0's text
JS='function js(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); gsub(/\r/, "\\r", s); return "\"" s "\"" }'
# manifest: MANIFEST.json, every path in it relative to the bundle or to its source's root
manifest() {
  _rows() { awk -F'\t' -v N="$2" "$JS"' { printf "%s\n  [", (NR > 1 ? "," : ""); for (i = 1; i <= N; i++) printf "%s%s", (i > 1 ? ", " : ""), ($i ~ /^[0-9]+$/ ? $i : js($i)); printf "]" } END { if (NR) printf "\n " }' "$1"; }
  _at=$(utc); nf=$(find "$NB" -type f | grep -c . || true); nb=$(find "$NB" -type f -exec cat {} + | wc -c | tr -d ' ')
  {
    printf '{\n "format": "vid-share 1",\n "built_at": "%s",\n "vid": "%s",\n "records_version": "%s",\n "project": "%s",\n "run": "%s",\n "mode": "%s",\n' "$_at" "$VER" "${RV:-unknown}" "$PROJ" "$RUN" "$MODE"
    printf ' "sources": ['; _rows "$W/sources" 4; printf '],\n'
    printf ' "totals": {"files": %s, "bytes": %s, "gzipped": %s, "split": %s, "split_limit_bytes": %s},\n' "$nf" "$nb" "$(grep -c . "$W/gz" || true)" "$(grep -c . "$W/split" || true)" "$SPLIT"
    printf ' "gzipped": ['; _rows "$W/gz" 3; printf '],\n'
    printf ' "split": ['; _rows "$W/split" 2; printf '],\n'
    printf ' "left_out": ['; _rows "$W/leftout" 2; printf '],\n'
    printf ' "missing": ['; cut -f1,2 "$W/missing" > "$W/missing.2"; _rows "$W/missing.2" 2; printf '],\n'
    printf ' "redactions": ['; _rows "$W/redactions" 3; printf '],\n'
    awk -F'\t' '{ n[$2] += $3 } END { for (k in n) print k "\t" n[k] }' "$W/redactions" | LC_ALL=C sort > "$W/kinds"
    printf ' "redactions_by_kind": {'; awk -F'\t' '{ printf "%s\"%s\": %s", (NR > 1 ? ", " : ""), $1, $2 }' "$W/kinds"; printf '},\n'
    printf ' "scan": {"result": "%s", "found": [' "$(if [ -s "$W/scan" ]; then echo found; else echo clean; fi)"; _rows "$W/scan" 3; printf ']},\n'
    printf ' "limit": {"caught_certain": "%s", "caught_by_rule": "%s", "not_caught": "%s"}\n' "$LC1" "$LC2" "$LC3"
    printf '}\n'
  } > "$W/MANIFEST.json"
  # the manifest's own text redacted too (an encoded folder name in a source), its matches not counted
  SHARE_MODE=plain SHARE_KNOWN=$W/known LC_ALL=C awk "$RED" "$W/MANIFEST.json" > "$NB/MANIFEST.json"
  manifest_md "$_at"
}

# STATS: one transcript's line for INDEX.md, read by awk: `<start>\t<end>\t<models>\t<messages>\t<input>\t<cache read>\t
# <cache write>\t<output>`. Start and end are the least and greatest "timestamp" (to the minute); each message id's last
# usage counts once (record.sh's reading: the `"usage":{"input_tokens":` object, bounded by its braces); `<synthetic>`
# skipped; with MAIN=1 the side-chain lines are skipped (a session's main thread). Not read, so not in INDEX.md (R4's cut):
# a session's role, a subagent's tool uses (the parent's queue lines hold them escaped) and any money.
STATS='function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
  function fl(   k, x, a, b, c, o, md) { if (F == "") return; md = ""; a = b = c = o = 0
    for (k = 1; k <= n; k++) { x = ID[k]; a += IN[x]; b += CR[x]; c += CW[x]; o += OU[x]; if (MO[x] != "" && !(MO[x] in MS)) { MS[MO[x]] = 1; md = md (md == "" ? "" : ", ") MO[x] } }
    printf "%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\n", F, (t0 == "" ? "-" : t0), (t1 == "" ? "-" : t1), (md == "" ? "-" : md), n, a, b, c, o
    split("", ID); split("", IN); split("", CR); split("", CW); split("", OU); split("", MO); split("", MS); n = 0; t0 = t1 = "" }
  FNR == 1 { fl(); F = FILENAME }
  MAIN && index($0, "\"isSidechain\":true") { next }
  { s = $0; while (match(s, /"timestamp":"20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]/)) { t = substr(s, RSTART + 13, 16); s = substr(s, RSTART + RLENGTH); if (t0 == "" || t < t0) t0 = t; if (t > t1) t1 = t } }
  index($0, "\"type\":\"assistant\"") && index($0, "\"usage\":{\"input_tokens\":") {
    s = $0; u = 0; while ((i = index(s, "\"usage\":{\"input_tokens\":")) > 0) { u += i; s = substr(s, i + 1) }
    s = substr($0, u + 8); d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "{") d++; else if (c == "}" && --d == 0) break } s = substr(s, 1, i)
    m = ""; if (match($0, /"model":"[^"]*"/)) m = substr($0, RSTART + 9, RLENGTH - 10); if (m == "<synthetic>") next
    id = ""; if (match($0, /"id":"msg_[^"]*"/)) id = substr($0, RSTART, RLENGTH); if (id == "") id = "line" FNR
    if (!(id in IN)) ID[++n] = id; IN[id] = num(s, "input_tokens"); CR[id] = num(s, "cache_read_input_tokens"); CW[id] = num(s, "cache_creation_input_tokens"); OU[id] = num(s, "output_tokens"); MO[id] = m }
  END { fl() }'

# index_md: conversations/INDEX.md, one row a session and one a subagent, from the transcripts as found (before redaction;
# the page is redacted with the rest). Three awks: the sessions' statistics, the subagents' and the subagents' descriptions
index_md() { awkf
  : > "$W/tokens"; : > "$W/agents"; : > "$W/ags"
  while IFS="$TAB" read -r sid f; do
    for a in "${f%.jsonl}"/subagents/agent-*.jsonl; do [ ! -f "$a" ] || printf '%s\t%s\n' "$sid" "$a" >> "$W/ags"; done
  done < "$W/took"
  [ ! -s "$W/took" ] || cut -f2 "$W/took" | xa awk -v MAIN=1 -f "$W/stats.awk" > "$W/st.s"
  if [ -s "$W/ags" ]; then
    cut -f2 "$W/ags" | xa awk -v MAIN=0 -f "$W/stats.awk" > "$W/st.a"
    # each subagent's description, from its .meta.json beside it, the first one; | made /
    cut -f2 "$W/ags" | awk '{ sub(/\.jsonl$/, ".meta.json"); print }' | while IFS= read -r m; do [ ! -f "$m" ] || printf '%s\n' "$m"; done > "$W/metas"
    : > "$W/ds"; [ ! -s "$W/metas" ] || LC_ALL=C xa awk 'FNR == 1 { d = 0 } !d && match($0, /"description":"([^"\\]|\\.)*"/) { x = substr($0, RSTART + 15, RLENGTH - 16); gsub(/\|/, "/", x); print FILENAME "\t" x; d = 1 }' < "$W/metas" > "$W/ds"
    # cut to 120 characters as cut -c counts them here, one cut over them all
    cut -f1 "$W/ds" > "$W/ds.f"; cut -f2- "$W/ds" | cut -c1-120 > "$W/ds.c"
    awk -F'\t' -v W="$W" 'FILENAME == ARGV[1] { R[$1] = $0; next } FILENAME == ARGV[2] { M[FNR] = $0; next } FILENAME == ARGV[3] { m = M[FNR]; sub(/\.meta\.json$/, ".jsonl", m); D[m] = $0; next }
      { a = $2; id = a; sub(/.*\//, "", id); sub(/\.jsonl$/, "", id); sub(/^agent-/, "", id); r = (a in R) ? R[a] : "-\t-\t-\t-\t0\t0\t0\t0\t0"; sub(/^[^\t]*\t/, "", r)
        print r > (W "/tokens.a"); printf "%s\t%s\t%s\t%s\t%s\n", id, substr($1, 1, 8), (D[a] == "" ? "-" : D[a]), r, $1 }' "$W/st.a" "$W/ds.f" "$W/ds.c" "$W/ags" |
      awk -F'\t' '{ printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 "/subagents/agent-" $1 ".jsonl.gz" }' > "$W/agents"
  fi
  { echo "# Conversations · $PROJ / $RUN"; echo
    echo 'Every transcript in this share, redacted and gzipped. Tokens are summed over each message once; no money is given.'
    echo 'MISSING.md lists the transcripts this run named that are not here.'; echo
    if [ -s "$W/took" ]; then
      echo '## Sessions'; echo; echo '| Session | Start | End | Models | Messages | Input | Cache read | Cache write | Output | File |'; echo '|---|---|---|---|---|---|---|---|---|---|'
      awk -F'\t' -v W="$W" 'FILENAME == ARGV[1] { R[$1] = $0; next } { r = ($2 in R) ? R[$2] : "-\t-\t-\t-\t0\t0\t0\t0\t0"; sub(/^[^\t]*\t/, "", r); print r > (W "/tokens"); split(r, x, "\t")
        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", $1, x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8], $1 "/" $1 ".jsonl.gz" }' "$W/st.s" "$W/took"
      [ ! -f "$W/tokens.a" ] || cat "$W/tokens.a" >> "$W/tokens"
      if [ -s "$W/agents" ]; then echo; echo '## Subagents'; echo; echo '| Agent | Parent | Description | Start | End | Models | Messages | Input | Cache read | Cache write | Output | File |'; echo '|---|---|---|---|---|---|---|---|---|---|---|---|'; LC_ALL=C sort -t'|' -k5 "$W/agents"; fi
    else echo 'No transcript is in this share.'; fi
  } > "$W/gen/conversations/INDEX.md"
  add conversations/INDEX.md "$W/gen/conversations/INDEX.md" doc
}

# findings_md: FINDINGS.md and findings/F-NNN.md from the run's findings file, in either form the owner's tools read:
# `## F-<n> · <title>` with `- **Field:** value` bullets, or the queue's `## <step>: …` with `- seen:`, `- first:` and
# `- words:` (numbered in order; a heading beginning Note skipped). The form is read at each `## ` heading, so one file may
# hold both (0.26.11.1.4, R8). A field the records do not give is `unrated`. With no
# findings file, FINDINGS.md says so and the rest of the bundle is written all the same.
findings_md() {
  FF=''; for c in "$H/.vid/VID-FINDINGS.md" "$H/.vid/VID-UPSTREAM-FINDINGS.md"; do [ -f "$c" ] && { FF=$c; break; }; done
  NFIND=0; mkdir -p "$W/gen/findings"
  if [ -n "$FF" ]; then
    FREL=records/.vid/$(basename "$FF")
    awk -v D="$W/gen/findings" -v RID="$PROJ/$RUN" -v SRC="$FREL" -v RF="$W/gen/findings/rows" '
      function cell(s) { gsub(/\|/, "/", s); gsub(/\n/, " ", s); return (s == "" ? "unrated" : s) }
      function g(k) { return (k in F) ? F[k] : "" }
      function flush(   f, k, i, o) { if (!act) return; act = 0; f = sprintf("%s/F-%03d.md", D, n)
        o = "# F-" sprintf("%03d", n) " · " TT "\n\n| Field | Value |\n|---|---|\n| Run | " RID " |\n| Original id | F-" ON " in " SRC " |\n"
        o = o "| Seen | " cell(g("Seen")) " |\n| Class | unrated |\n| Severity | unrated |\n| Where | " cell(g("Where")) " |\n| Recurrence | unrated |\n"
        o = o "| Cost | " cell(g("Cost")) " |\n| Status | unrated |\n| Backlog | unrated |\n| Related | unrated |\n\n"
        o = o "## What happened\n\n" (g("What happened") == "" ? "unrated" : g("What happened")) "\n\n## Evidence\n\n" (g("Evidence") == "" ? "unrated" : g("Evidence")) "\n\n"
        for (i = 1; i <= nk; i++) { k = K[i]; if (k != "Seen" && k != "Where" && k != "Cost" && k != "What happened" && k != "Evidence" && k != "Local workaround" && k != "Ask") o = o "## " k "\n\n" F[k] "\n\n" }
        o = o "## Local workaround\n\n" (g("Local workaround") == "" ? "unrated" : g("Local workaround")) "\n\n## Ask\n\n" (g("Ask") == "" ? "unrated" : g("Ask")) "\n"
        printf "%s", o > f; close(f)
        printf "| %d | [F-%03d](findings/F-%03d.md) | %s | unrated | unrated | unrated | %s | unrated |\n", n, n, n, cell(TT), cell(g("Cost")) >> RF; close(RF)
        split("", F); split("", K); nk = 0; cur = "" }
      /^## F-[0-9]+ · / { flush(); FM = 1; st = 0; n++; act = 1; ON = $2; sub(/^F-/, "", ON); TT = $0; sub(/^## F-[0-9]+ · /, "", TT); cur = ""; next }
      /^## / { flush(); FM = 2; cur = ""; h = substr($0, 4); st = 1; next }
      FM == 1 && act && /^- \*\*[^*]+:\*\* / { k = $0; sub(/^- \*\*/, "", k); v = k; sub(/:\*\* .*/, "", k); sub(/^[^*]*:\*\* /, "", v); if (!(k in F)) K[++nk] = k; F[k] = v; cur = k; next }
      FM == 1 && act && cur != "" { F[cur] = F[cur] "\n" $0; next }
      FM == 2 && st == 1 && /^- seen: [0-9]+$/ { se = substr($0, 9); st = 2; next }
      FM == 2 && st == 2 && /^- first: / { fi = substr($0, 10); st = 3; next }
      FM == 2 && st == 3 && /^- words: / { if (tolower(substr(h, 1, 4)) == "note") { st = 0; next }
        n++; act = 1; ON = n; w = substr($0, 10); stp = h; sub(/:.*/, "", stp); TT = w; if (match(TT, /[a-z)][:.] /)) TT = substr(TT, 1, RSTART); TT = substr(TT, 1, 160)
        K[++nk] = "Seen"; F["Seen"] = fi " · " stp " · seen " se " time" (se == "1" ? "" : "s") " (queue.sh defect)"; K[++nk] = "What happened"; F["What happened"] = w; cur = "What happened"; st = 4; next }
      FM == 2 && st == 4 { F[cur] = F[cur] "\n" $0; next }
      FM == 2 { st = 0 }
      END { flush(); print n + 0 }' "$FF" > "$W/nfind"
    NFIND=$(cat "$W/nfind")
  fi
  { echo "# Findings · $PROJ / $RUN"; echo
    if [ -z "$FF" ]; then echo "No findings file in this run's records (.vid/VID-FINDINGS.md or .vid/VID-UPSTREAM-FINDINGS.md): the run recorded no ViD finding."
    elif [ "$NFIND" = 0 ]; then echo "The run's findings file ($FREL) holds no finding in either form the owner's tools read."
    else
      printf '%s ViD findings (F-001 to F-%03d; the run'"'"'s own numbers are in each file), in the order the run recorded them. Class, severity, recurrence and status are unrated: they are the reader'"'"'s to judge. Each id links to its file.\n\n' "$NFIND" "$NFIND"
      echo '| # | Id | Title | Class | Severity | Recurrence | Cost | Status |'; echo '|---|---|---|---|---|---|---|---|'; cat "$W/gen/findings/rows"
    fi
  } > "$W/gen/FINDINGS.md"
  rm -f "$W/gen/findings/rows"
  add FINDINGS.md "$W/gen/FINDINGS.md" doc
  for f in "$W"/gen/findings/F-*.md; do [ -f "$f" ] && add "findings/$(basename "$f")" "$f" doc; done
  return 0
}

# run_md: RUN.md, FORMAT's run card: its 12 fields in their order, each filled from the run's records or `unknown`; costs in
# time and tokens alone. 0.26.11.1.4 (R8): the version line names each vid= the session events carry and the time of the last
# session event, never a bare version; "Who and what" lists the events' sessions, then each transcript the share took
# that no event names, its model from the bundle's statistics. Role and machine stay unknown: no record holds them
run_md() {
  _kv() { sed -n "s/^$1:[[:space:]]*//p" "$2" 2>/dev/null | head -n 1; }
  REPO=$(_kv repo "$H/.vid/tw/settings"); SREPO=$(_kv spec-repo "$H/.vid/tw/settings")
  if [ "$MODE" = github-manual ] && [ "$(_kv layout "$H/.vid/tw/settings")" = one ]; then SREPO=$(_kv spec-path "$H/.vid/tw/settings"); SREPO="none: the spec is in the code repository's folder ${SREPO:-docs/specs}, ViD's export in the project"; fi   # FB-3 B2
  RID=$(sed -n 's/^id=//p' "$H/.vid/run" 2>/dev/null | head -n 1)
  RV=$(_kv records "$H/checks/records-version"); [ -n "$RV" ] || RV=$(_kv records "$(dirname "$0")/records-version")
  OUTC=$(_kv run "$H/.vid/RUN-STATE.md")
  [ -f "$EVF" ] || EVF=/dev/null
  awk 'function dn(y, m, d) { if (m <= 2) { y--; m += 12 } return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d }
    function ep(t) { return ((dn(substr(t, 1, 4) + 0, substr(t, 6, 2) + 0, substr(t, 9, 2) + 0) * 24 + substr(t, 12, 2)) * 60 + substr(t, 15, 2)) * 60 + substr(t, 18, 2) }
    function val(k,   i, v) { i = index($0, " " k "="); if (!i) return ""; v = substr($0, i + length(k) + 2); if (substr(v, 1, 1) == "\"") { v = substr(v, 2); sub(/".*/, "", v) } else sub(/ .*/, "", v); return v }
    { a = val("at"); if (a ~ /^20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) { if (t0 == "" || a < t0) t0 = a; if (a > t1) t1 = a } }
    $1 == "session" { s = val("id"); if (s != "" && !(s in S)) { S[s] = 1; o[++n] = s; md[s] = val("model") }; vat = a; v = val("vid"); if (v != "" && v != "-") { ver = v; if (!(v in V)) { V[v] = 1; vl = vl (vl == "" ? "" : ", ") v } } }
    END { print "start\t" (t0 == "" ? "unknown" : t0); print "end\t" (t1 == "" ? "unknown" : t1)
      if (t0 != "") { e = ep(t1) - ep(t0); printf "elapsed\t%dh %02dm\n", int(e / 3600), int((e % 3600) / 60) } else print "elapsed\tunknown"
      print "vid\t" (ver == "" ? "unknown" : ver); print "vids\t" vl; print "vidat\t" vat; for (i = 1; i <= n; i++) print "session\t" o[i] "\t" (md[o[i]] == "" || md[o[i]] == "-" ? "unknown" : md[o[i]]) }' "$EVF" > "$W/runfacts"
  rf() { awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$W/runfacts"; }
  VER=$(rf vid); if [ "$VER" = unknown ]; then _pj=$(dirname "$0")/../.claude-plugin/plugin.json; [ -f "$_pj" ] && VER=$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$_pj" | head -n 1); VER=${VER:-unknown}; fi
  if [ -n "$(rf vids)" ]; then VLINE="$(rf vids), as of the last session event, $(rf vidat)"
  elif [ "$VER" != unknown ]; then VLINE="$VER, the ViD that built this share (no session event names a version)"; else VLINE=unknown; fi
  [ -f "$W/st.s" ] || : > "$W/st.s"
  awk -F'\t' 'FILENAME == ARGV[1] { if ($1 == "session") { E[$2] = 1; printf "| %s | unknown | unknown | %s |\n", $2, $3 } next }
    FILENAME == ARGV[2] { M[$1] = $4; next } !($1 in E) && !($1 in G) { G[$1] = 1; m = M[$2]; printf "| %s | unknown | unknown | %s |\n", $1, (m == "" || m == "-" ? "unknown" : m) }' "$W/runfacts" "$W/st.s" "$W/took" > "$W/who"
  TOK=$(awk -F'\t' '{ a += $5; b += $6; c += $7; o += $8; n++ } END { if (n) printf "input %d, cache read %d, cache write %d, output %d, over %d transcripts here (measured, from conversations/INDEX.md)", a, b, c, o, n }' "$W/tokens")
  case $MODE in local-auto) MW='local auto (develop)' ;; github-auto) MW='GitHub auto (tickets, ViD'"'"'s DevAgent)' ;; *) MW='GitHub manual (tickets)' ;; esac
  {
    echo "# Run card · $PROJ / $RUN"; echo
    echo '## Project'; echo; echo "- **Name:** $PROJ"; echo "- **Code repository:** ${REPO:-unknown}"; echo "- **Spec repository:** ${SREPO:-unknown}"; echo
    echo '## Run'; echo; echo "- **Id:** ${RID:-unknown}"; echo "- **Mode:** $MW"; echo "- **ViD version:** $VLINE"; echo "- **Records version:** ${RV:-unknown}"; echo
    echo '## Dates'; echo; echo "- **Start:** $(rf start) (the first event)"; echo "- **End:** $(rf end) (the last event)"; echo "- **Elapsed:** $(rf elapsed)"; echo
    echo '## Who and what'; echo
    if [ -s "$W/who" ]; then echo '| Session | Role | Machine | Model |'; echo '|---|---|---|---|'; cat "$W/who"
    else echo 'unknown'; fi; echo
    echo '## Machines and tools'; echo; echo 'unknown'; echo
    echo '## Stand-ins'; echo; if [ "$MODE" = github-auto ]; then echo "- **The dev side:** ViD's DevAgent (the owner's GitHub mode answer at the plan's setup: auto)."; else echo 'unknown'; fi; echo
    echo '## Scope'; echo; echo 'unknown'; echo
    echo '## Outcome'; echo; if [ -n "$OUTC" ]; then echo "- **RUN-STATE:** run: $OUTC"; else echo 'unknown'; fi; echo
    echo '## Costs'; echo; echo "- **Time:** $(rf elapsed) (measured, from the events)"; echo "- **Tokens:** ${TOK:-unknown}"; echo
    echo '## Findings'; echo; if [ -n "$FF" ]; then echo "- $NFIND ViD findings, in [FINDINGS.md](FINDINGS.md)."; else echo 'unknown: no findings file in the records.'; fi; echo
    echo '## Open'; echo; echo 'unknown'; echo
    echo '## Links'; echo; if [ -n "$REPO" ]; then echo "- **Code repository:** https://github.com/$REPO"; else echo 'unknown'; fi
  } > "$W/gen/RUN.md"
  add RUN.md "$W/gen/RUN.md" doc
}

# manifest_md: MANIFEST.md, the manifest in plain words, from the same lists as MANIFEST.json
manifest_md() {
  {
    echo "# Manifest · $PROJ / $RUN"; echo
    echo "Built at $1 by ViD's share (ViD $VER), read-only on every source. Every path is relative: to this bundle, or to its source's root (home: the run's home; logs: the folder the user named; claude-projects: the Claude projects folder)."; echo
    echo '| Here | Root | From | How |'; echo '|---|---|---|---|'; awk -F'\t' '{ for (i = 1; i <= 4; i++) gsub(/\|/, "/", $i); printf "| %s | %s | %s | %s |\n", $1, $2, $3, $4 }' "$W/sources"; echo
    echo '**Totals:**'
    echo "- Files: $nf ($nb bytes)."
    awk -F'\t' '{ n++; r += $2; g += $3 } END { printf "- Gzipped: %d (%d KB raw, %d KB gzipped).\n", n, r / 1024, g / 1024 }' "$W/gz"
    echo "- Split: $(grep -c . "$W/split" || true), every file under $SPLIT bytes."
    echo "- Left out: $(grep -c . "$W/leftout" || true). Missing: $(grep -c . "$W/missing" || true)."; echo
    echo '## Redactions'; echo; echo 'Each match was replaced by `[REDACTED:<kind>]`. Counts by kind:'; echo
    if [ -s "$W/kinds" ]; then awk -F'\t' '{ printf "- %s: %s\n", $1, $2 }' "$W/kinds"; else echo '- none'; fi; echo
    if [ -s "$W/scan" ]; then echo "The scan after redaction found something left, so nothing may be sent:"; awk -F'\t' '{ printf "- %s: %s (%s)\n", $1, $2, $3 }' "$W/scan"
    else echo 'The scan after redaction read every file back, gzipped and split ones included, for every kind: nothing is left.'; fi; echo
    echo 'Files with the most redactions:'; echo
    awk -F'\t' '{ n[$1] += $3 } END { for (f in n) print n[f] "\t" f }' "$W/redactions" | LC_ALL=C sort -t"$TAB" -k1,1nr -k2 | head -n 15 | awk -F'\t' '{ printf "- %s: %s\n", $2, $1 }'; echo
    echo '## Split'; echo; if [ -s "$W/split" ]; then awk -F'\t' '{ printf "- %s: %s parts, %s.part-000 on\n", $1, $2, $1 }' "$W/split"; else echo '- none'; fi; echo
    echo '## Left out'; echo; if [ -s "$W/leftout" ]; then awk -F'\t' '{ printf "- %s: %s\n", $1, $2 }' "$W/leftout"; else echo '- none'; fi; echo
    echo '## Missing'; echo; if [ -s "$W/missing" ]; then awk -F'\t' '{ printf "- %s: %s\n", $1, $2 }' "$W/missing"; else echo '- none'; fi; echo
    echo '## The limit'; echo; echo 'A pattern catches only what it knows. Look at the bundle yourself before you send it.'; echo
    echo "- **Caught for certain:** $LC1."; echo "- **Caught by rule** (a value in another form passes): $LC2."; echo "- **Not caught:** $LC3."
  } > "$W/MANIFEST.md"
  SHARE_MODE=plain SHARE_KNOWN=$W/known LC_ALL=C awk "$RED" "$W/MANIFEST.md" > "$NB/MANIFEST.md"
}

# missing_md: conversations/MISSING.md, one row a transcript named but not here
missing_md() {
  mkdir -p "$W/gen/conversations"
  { echo "# Missing transcripts · $PROJ / $RUN"; echo
    echo 'Each transcript this run named (its events, or the user) that is not in conversations/, with why.'; echo
    if [ -s "$W/missing" ]; then echo '| Session | Why | Path as named |'; echo '|---|---|---|'
      awk -F'\t' '{ for (i = 1; i <= 3; i++) gsub(/\|/, "/", $i); printf "| %s | %s | %s |\n", $1, $2, ($3 == "" ? "-" : $3) }' "$W/missing"
    else echo 'None: every named transcript is here.'; fi
  } > "$W/gen/conversations/MISSING.md"
  add conversations/MISSING.md "$W/gen/conversations/MISSING.md" doc
}

# review_md (SHARE-SCRUB §4.5.4): .vid/shares/<run>.review, beside the bundle and never in it, readable by the user alone, read from
# the redacted files, so it shows what would be sent: every prompt and ! command of the run's main sessions (a user line that is no
# tool result, no meta, side-chain or compact summary, and of human origin when it names one), and each product data file the
# conversations read, wrote or edited (a file_path or notebook_path under fixture(s), seed(s), testdata, test-data, test_data,
# mock(s), factories or sample(s), or ending .csv, .tsv or .sql), with how many times. NPROMPT and NDATA count them
review_md() {
  _rv=$OUTROOT/$RUN.review; : > "$W/rv.list"
  [ ! -s "$W/rmap.r" ] || awk -F'\t' -v T="$W/took" 'BEGIN { while ((getline l < T) > 0) { split(l, a, "\t"); M["conversations/" a[1] "/" a[1] ".jsonl.gz"] = 1 } }
    $4 == "conv" { print (($2 in M) ? "main" : "any") "\t" $3 }' "$W/rmap.r" > "$W/rv.list"
  LC_ALL=C awk -v L="$W/rv.list" -v O="$W/rv.typed" -v D="$W/rv.data" '
    function endq(r,   p, b, i) { b = 0
      while ((i = index(substr(r, b + 1), "\"")) > 0) { p = b + i; i = p - 1; while (i > 0 && substr(r, i, 1) == "\\") i--; if ((p - 1 - i) % 2 == 0) return p; b = p }
      return 0 }
    function js(r,   q) { q = endq(r); return q ? substr(r, 1, q - 1) : r }
    function un(x,   o, i, c, n) { o = ""; n = length(x)
      for (i = 1; i <= n; i++) { c = substr(x, i, 1); if (c == "\\" && i < n) { i++; c = substr(x, i, 1); o = o (c == "n" ? "\n" : c == "t" ? "\t" : c == "r" ? "" : c) } else o = o c }
      return o }
    BEGIN { FS = "\t"; while ((getline e < L) > 0) { split(e, f, "\t")
        while ((getline l < f[2]) > 0) {
          if (f[1] == "main" && index(l, "\"type\":\"user\"") && !index(l, "\"tool_result\"") && !index(l, "\"isMeta\":true") && !index(l, "\"isSidechain\":true") && !index(l, "\"isCompactSummary\":true") && (!index(l, "\"origin\":{\"kind\":\"") || index(l, "\"origin\":{\"kind\":\"human\""))) {
            t = ""; p = index(l, "\"content\":\""); if (p) t = js(substr(l, p + 11))
            else { r = l; while ((p = index(r, "\"type\":\"text\",\"text\":\"")) > 0) { r = substr(r, p + 22); t = t (t == "" ? "" : "\n") js(r) } }
            ts = ""; if (match(l, /"timestamp":"[^"]*"/)) ts = substr(l, RSTART + 13, RLENGTH - 14)
            if (t != "") { np++; printf "### %d%s\n\n%s\n\n", np, (ts == "" ? "" : " · " ts), un(t) > O } }
          r = l; if (index(l, "_path\":\"")) while (match(r, /"(file_path|notebook_path)":"([^"\\]|\\.)*"/)) { x = substr(r, RSTART, RLENGTH); r = substr(r, RSTART + RLENGTH); sub(/^"[a-z_]*":"/, "", x); x = un(substr(x, 1, length(x) - 1))
            if (x ~ /(^|\/)(fixtures?|seeds?|testdata|test-data|test_data|mocks?|factories|samples?)(\/|$)/ || x ~ /[.](csv|tsv|sql)$/) { if (!(x in C)) K[++nk] = x; C[x]++ } } }
        close(f[2]) }
      for (i = 1; i <= nk; i++) printf "- %s: %d time%s\n", K[i], C[K[i]], (C[K[i]] == 1 ? "" : "s") > D
      printf "%d\t%d\n", np, nk }' < /dev/null > "$W/rv.n"
  NPROMPT=$(cut -f1 "$W/rv.n"); NDATA=$(cut -f2 "$W/rv.n")
  ( umask 077
    { echo "# Before you send · $PROJ / $RUN"; echo
      echo 'This page is not in the share and never leaves this machine. It is read from the redacted bundle, so it shows what would be sent. The rules catch only the forms they know: read what you typed, at least, before you say send.'; echo
      echo "## What you typed ($NPROMPT)"; echo
      if [ -s "$W/rv.typed" ]; then cat "$W/rv.typed"; else echo 'Nothing: no prompt of a main session is in the share.'; echo; fi
      echo "## The product's data files the conversations touched ($NDATA)"; echo
      echo 'Personal data typed into these files reached the conversations whenever a tool read or wrote them. It is caught only in the forms ViD knows: emails, phone numbers, IP addresses, card numbers, IBANs, and named fields such as name, phone, address or birth date.'; echo
      if [ -s "$W/rv.data" ]; then cat "$W/rv.data"; else echo '- none'; fi; echo
      echo '## What is caught, and what is not'; echo
      echo "- **Caught for certain:** $LC1."; echo "- **Caught by rule** (a value in another form passes): $LC2."; echo "- **Not caught:** $LC3."
    } > "$_rv.tmp" && mv "$_rv.tmp" "$_rv" )
}

summary() {
  _s=$OUTROOT/$RUN.summary
  nb=$(find "$B" -type f -exec cat {} + | wc -c | tr -d ' ')
  {
    printf 'summary\t1\nfolder\t%s\nsize\t%s\nproject\t%s\nrun\t%s\nmode\t%s\n' ".vid/shares/$RUN" "$nb" "$PROJ" "$RUN" "$MODE"   # the folder relative to the project, so no home path is in the summary (the integration, 0.26.10.28.7)
    for p in records logs conversations; do if [ -d "$B/$p" ]; then printf 'part\t%s\t%s\n' "$p" "$(find "$B/$p" -type f | grep -c . || true)"; fi; done
    n=$(find "$B" -type f ! -path "$B/records/*" ! -path "$B/logs/*" ! -path "$B/conversations/*" | grep -c . || true); printf 'part\tdocs\t%s\n' "$n"
    awk -F'\t' '{ printf "redacted\t%s\t%s\n", $1, $2 }' "$W/kinds"
    awk -F'\t' '{ printf "left-out\t%s\t%s\n", $1, $2 }' "$W/leftout"
    awk -F'\t' '{ printf "missing\t%s\t%s\n", $1, $2 }' "$W/missing"
    awk -F'\t' '{ printf "split\t%s\t%s\n", $1, $2 }' "$W/split"
    if [ -s "$W/scan" ]; then printf 'scan\tfound\t%s\n' "$(awk -F'\t' '{ n += $3 } END { print n + 0 }' "$W/scan")"; else printf 'scan\tclean\n'; fi
    printf 'limit\ta pattern catches only what it knows: look at the bundle yourself before you send it\n'
    printf 'caught-certain\t%s\ncaught-by-rule\t%s\nnot-caught\t%s\n' "$LC1" "$LC2" "$LC3"
    printf 'review\t%s\t%s\t%s\n' ".vid/shares/$RUN.review" "${NPROMPT:-0}" "${NDATA:-0}"
  } > "$_s.tmp"
  # every line redacted but the folder's: the user's own path on their own machine, which the verb needs as it is
  SHARE_MODE=plain SHARE_KNOWN=$W/known LC_ALL=C awk "$RED" "$_s.tmp" | awk -F'\t' 'NR == FNR { r[FNR] = $0; next } { print ($1 == "folder" ? $0 : r[FNR]) }' - "$_s.tmp" > "$_s.red"
  mv "$_s.red" "$_s"; rm -f "$_s.tmp"
}

# build [flags]: the bundle and its summary
build() {
  RUN=''; LOGS=''; SESSIONS=''; LITFILE=''; NOCONV=no; NOLOGS=no
  while [ $# -gt 0 ]; do
    case "$1" in
      --run) [ $# -ge 2 ] || usage; RUN=$2; shift 2 ;;
      --logs) [ $# -ge 2 ] || usage; LOGS=$2; shift 2 ;;
      --session) [ $# -ge 2 ] || usage; SESSIONS="$SESSIONS$2
"; shift 2 ;;
      --redact-file) [ $# -ge 2 ] || usage; LITFILE=$2; shift 2 ;;
      --leave-out) [ $# -ge 2 ] || usage; case "$2" in conversations) NOCONV=yes ;; logs) NOLOGS=yes ;; *) usage ;; esac; shift 2 ;;
      *) usage ;;
    esac
  done
  [ -z "$LOGS" ] || [ -d "$LOGS" ] || die "refused — the logs folder $LOGS is not a folder."
  [ -z "$LITFILE" ] || [ -f "$LITFILE" ] || die "refused — the redaction file $LITFILE is not a file."
  [ -z "$LOGS" ] || LOGS=$(cd "$LOGS" && pwd -P)
  findhome; EVF=$H/.vid/metrics-events
  # the mode: ticket mode is GitHub auto when the owner's recorded answer at the plan's setup says so (setup-answered key=github-mode
  # value="auto" in .vid/plan/setup, as checks/devagent-start.sh reads it), else GitHub manual (FB-1 C1); else local auto. The integration's final
  # review: the round's stand-in: switch, answering for an absent person, is no mode and is not read here
  MODE=local-auto
  if grep -q '^mode:[[:space:]]*tickets' "$H/.vid/RUN-STATE.md" 2>/dev/null; then
    if [ "$(sed -n 's/^setup-answered key=github-mode value="\([a-z]*\)".*/\1/p' "$H/.vid/plan/setup" 2>/dev/null | tail -n 1)" = auto ]; then MODE=github-auto; else MODE=github-manual; fi
  fi
  PROJ=$(basename "$H" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'); PROJ=${PROJ:-project}
  M=$(sed -n 's/.* at=\([0-9][0-9][0-9][0-9]-[0-9][0-9]\).*/\1/p' "$H/.vid/metrics-events" 2>/dev/null | head -n 1)
  RUNPFX="${M:-$(date -u '+%Y-%m')}-$MODE"; RUNGIVEN=$RUN
  [ -n "$RUN" ] || RUN="$RUNPFX-$PROJ"
  case "$RUN" in *[!A-Za-z0-9._-]*|.*|'') die "refused — the run name '$RUN' may hold only letters, digits, '.', '_' and '-'." ;; esac
  OUTROOT=$H/.vid/shares; B=$OUTROOT/$RUN
  mkdir -p "$OUTROOT"
  W=$(mktemp -d); NB=$OUTROOT/.share-$$.building; trap 'rm -rf "$W" "$NB"' EXIT   # SHARE-SCRUB: no run name on disk before namecheck
  rm -rf "$NB"; mkdir -p "$NB" "$W/gen"
  : > "$W/list"; : > "$W/leftout"; : > "$W/missing"; : > "$W/sources"; : > "$W/split"; : > "$W/gz"; : > "$W/redactions"; : > "$W/named.u"; : > "$W/took"; : > "$W/tokens"; : > "$W/pruned.all"
  # records/: the home's .vid/ and the root's extras
  walk "$H/.vid" records/.vid rec records
  src records/.vid/ home .vid 'the records, redacted; files over 256 KB gzipped; clones, object stores, worktrees, earlier exports and the share'"'"'s output left out'
  for x in round.log stood-in-answers.txt PLAN.md .round; do
    if [ -d "$H/$x" ]; then walk "$H/$x" "records/$x" rec logs; src "records/$x/" home "$x" 'redacted'
    elif [ -f "$H/$x" ]; then add "records/$x" "$H/$x" rec; src "records/$x" home "$x" 'redacted'; fi
  done
  # logs/: the folder the user named
  if [ "$NOLOGS" = yes ]; then lo logs/ 'left out at the user'"'"'s request'
  elif [ -n "$LOGS" ]; then walk "$LOGS" logs log logs; src logs/ logs . 'the folder the user named, redacted; logs, timelines and files over 256 KB gzipped; clones, blind copies, checkouts'"$([ "$MODE" = local-auto ] && echo ' and trees' || echo ', trees, package stores and caches')"' left out'
  elif [ "$MODE" = github-manual ]; then lo logs/ "out of reach: in GitHub manual the team's side is on its own machines; this share holds ViD's side alone"
  else lo logs/ 'no logs folder named'; fi
  # conversations/: the sessions the events name, and the user's
  if [ "$NOCONV" = yes ]; then lo conversations/ 'left out at the user'"'"'s request'
  else sessions; fi
  # SHARE-SCRUB §4.5.3: the copies and the known values first, so the project's and the run's names are checked before any page
  # is written with them; the pages made after the snapshot are their own copies (add)
  snapshot
  known
  namecheck
  [ "$NOCONV" = yes ] || { missing_md; index_md; }
  findings_md; run_md
  put
  cut_big
  # the scan: the bundle read back, then the manifest, which holds the first scan's result, read back too
  scanfolder "$NB" "$W/known" > "$W/scan"
  manifest
  for f in MANIFEST.json MANIFEST.md; do SHARE_MODE=scan SHARE_KNOWN=$W/known LC_ALL=C awk "$RED" "$NB/$f" | awk -F'\t' -v f="$f" '{ print f "\t" $1 "\t" $2 }' >> "$W/scan"; done
  # 0.26.10.29.3 (R9, F55): a folder a cloud drive syncs can refuse the rename while it syncs; then the bundle is copied
  # into place and the building folder removed, and the build says so
  rm -rf "$B"
  if ! mv "$NB" "$B" 2> "$W/mv.err"; then
    cp -R "$NB" "$B" || die "the bundle could not be moved or copied into place ($(head -n 1 "$W/mv.err"))"
    rm -rf "$NB"
    echo "ViD share: the rename into place failed ($(head -n 1 "$W/mv.err")); the bundle was copied into place and the building folder removed." >&2
  fi
  # the personal values the scan needs, beside the bundle and never in it, readable by the user alone
  ( umask 077; cp "$W/known" "$OUTROOT/$RUN.known" )
  review_md
  summary
  if [ -s "$W/scan" ]; then
    awk -F'\t' '{ printf "ViD share: left in %s: %s (%s)\n", $1, $2, $3 }' "$W/scan" >&2
    echo "ViD share: $B — the scan found something left; nothing may be sent. See $OUTROOT/$RUN.summary" >&2; exit 1
  fi
  echo "ViD share: $B — see $OUTROOT/$RUN.summary"
}

# scan <folder>: every kind, every file, nothing left
scan() {
  [ $# -eq 1 ] || usage
  [ -d "$1" ] && [ -f "$1/MANIFEST.json" ] || { echo "ViD share: refused — $1 is not a share bundle." >&2; exit 1; }
  _d=$(cd "$1" && pwd -P); _k=$_d.known
  [ -f "$_k" ] || { echo "ViD share: scan — refused: no $(basename "$_d").known beside the bundle, so the personal kinds (user names, emails, ids, the host) cannot be checked; build the share again where it was made." >&2; exit 1; }
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  scanfolder "$_d" "$_k" > "$W/scan"
  if [ -s "$W/scan" ]; then cat "$W/scan"; echo "ViD share: scan — something is left in $_d; nothing may be sent." >&2; exit 1; fi
  echo "ViD share: scan — clean: $_d"
}

# pack <folder>: one archive file beside the folder, after a clean scan
pack() {
  [ $# -eq 1 ] || usage
  [ -d "$1" ] && [ -f "$1/MANIFEST.json" ] || die "refused — $1 is not a share bundle."
  ( scan "$1" ) > /dev/null || die "refused — the scan found something left in $1; nothing is packed."
  _d=$(cd "$1" && pwd -P); _a=$_d.tar.gz
  # SHARE-SCRUB §4.5.2: no user or group name in the archive's headers (GNU tar and bsdtar both take --numeric-owner)
  ( cd "$(dirname "$_d")" && tar --numeric-owner -cf - "$(basename "$_d")" ) | gzip -9n > "$_a.tmp"
  mv "$_a.tmp" "$_a"
  printf '%s\n' "$_a"
}

[ $# -ge 1 ] || usage
cmd=$1; shift
case "$cmd" in build) build "$@" ;; scan) scan "$@" ;; pack) pack "$@" ;; *) usage ;; esac
