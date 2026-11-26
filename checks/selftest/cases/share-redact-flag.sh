#!/bin/sh
# Purpose: selftest case — a secret given by flag, header, quoted word or element is redacted in every form (SHARE-SCRUB §4.3,
# B-7). A toy project's share with a log and a transcript (each line also inside a JSON string, escaped quotes) holding made-up
# values after: --password "…", --password '…', --password …, --token "…", --secret …, --api-key …, -p … and -p glued on a line
# with a user flag, {"password":<number>} (a quoted marker after it), password=example…!, a quoted value that starts with a dash, a quoted value with a space, a 3-character
# value, PASSWORD '…', IDENTIFIED BY '…', curl -u user:…, DB_PASS=…, dbPwd: …, passphrase=…, Authorization: Basic …,
# Authorization: Token …, Cookie: …, Set-Cookie: …, <password>…</password>; and an assignment (PGPASSWORD=…). Convicts unless no
# value is in the bundle or the build's output, each is its kind where planted, the manifest counts secret-flag and auth-header,
# and the lines that hold no secret stay byte for byte (--password-file, --token-limit, --password --verbose, gcc -pthread
# -pedantic, find -print, ssh -P, mkdir -p build, date -u; mkdir -p .vid/tw, docker compose -p, tsc -p, mkdir -p "$D/x", docker run -p 8080:80, -p 5432:5432, bypass=on, PWD=/x,
# OLDPWD=/y, prose, mysql -p shopdb, redis-cli -n 2, docker push -p x); the closed list (sshpass -p, mysql/mysqldump/mariadb
# -p glued, redis-cli -a and --pass, docker/podman/helm registry login -p) taken with no user flag, a digits-only value too; and unless `share.sh scan` on the bundle with one value put back exits 1 naming the file and the kind,
# without the value. Values built at run time. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-redact-flag: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; HN=fenwick; export HOME="$T/h/$U/$HN"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md
t=$(date +%s | cksum | cut -c1-5); : > "$T/values"
v() { printf '%s%s' "$1" "$t" | tee -a "$T/values"; echo >> "$T/values"; }
jsonok() { python3 -I -c 'import json,sys
for n, l in enumerate(open(sys.argv[1], encoding="utf-8", errors="surrogateescape"), 1):
    try: json.loads(l)
    except Exception: print(n); sys.exit(1)' "$1"; }
esc() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
# the planted lines: <expected line, the value replaced by its marker> is computed below by the same table
plant() {
  echo "a --password \"$(v dq)q horse\" --name admin"
  echo "b --password '$(v sq)'"
  echo "c --password $(v bare) --verbose"
  echo "d --token \"$(v tok)\""
  echo "e --secret $(v sec)"
  echo "f --api-key $(v api)"
  echo "g docker login -u bot -p $(v pp)"
  echo "h mysql -uroot -p$(v gl)"
  echo "i {\"password\":9$(v num)}"
  echo "j --password \"-q7$(v dash)\""
  echo "k --password 'a b$(v spc)'"
  echo "l --secret a$(printf '%s' "$t" | cut -c1-2)"
  echo "m PASSWORD '$(v sqlp)'"
  echo "n CREATE USER app IDENTIFIED BY '$(v ident)'"
  echo "o curl -u admin:$(v curl) https://x.test/"
  echo "p DB_PASS=$(v dbp)"
  echo "q dbPwd: $(v dbpwd)"
  echo "r passphrase=$(v phr)"
  echo "s Authorization: Basic $(v basic)"
  echo "t Authorization: Token $(v tokh)"
  echo "u Cookie: sid=$(v ck); theme=dark"
  echo "u2 Cookie: sid=\"$(v ckq)\""
  echo "v Set-Cookie: sid=$(v sck); Path=/"
  echo "w <password>$(v xml)</password>"
  echo "x PGPASSWORD=$(v asg) psql"
  echo "y password=example$(v exr)!"
  echo "z password=$(printf '%s' "$t" | cut -c1-3)"
  echo "L1 sshpass -p $(v ssp) ssh host"
  echo "L2 sshpass -p$(v ssg) ssh host"
  echo "L3 mysql -p$(v myq) shop"
  echo "L4 /usr/bin/mysqldump -p$(v mdq) shop"
  echo "L5 sudo mariadb -p$(v mrq)"
  echo "L6 redis-cli -a $(v rda) ping"
  echo "L7 redis-cli --pass $(v rdp) ping"
  echo "L8 docker login -p $(v dlp) registry.test"
  echo "L9 podman login -p $(v plp) registry.test"
  echo "L10 helm registry login -p $(v hlp) registry.test"
  echo "L11 sshpass -p 9$(printf '%s' "$t" | cut -c1-4) ssh host"
  # a separator inside a quoted value, a JSON-escaped quoted user, curl's password quoted alone, XML with a quote,
  # Authorization as a JSON or dict key
  echo "R1 sshpass -p \"s;$(v sps)\" ssh host"
  echo "R2 mysql -uroot -p'm|$(v myp)' shop"
  echo "R3 mongo -u \"admin\" -p \"$(v mgo)\" db"
  echo "R4 curl -u admin:'$(v cuq)' https://x.test"
  echo "R5 <password>x\"$(v xq)</password>"
  echo "R6 {\"headers\":{\"Authorization\":\"Basic $(v ahj)\"}}"
  echo "R7 h = {'Authorization': 'Token $(v ahd)'}"
  # a command right after a separator, a literal after a variable reference
  echo "S1 true;curl -u alice:$(v cus) https://x.test"
  echo "S2 true;redis-cli -a $(v rds) ping"
  echo "S3 cli --password '\${PREFIX}$(v pfx)'"
  # a ; inside a quoted header before curl -u, a Redis URL with no user, an
  # Authorization array, a log line starting [, a shell default after ${
  echo "A1 curl -H 'Accept: text/html;q=0.9' -u admin:$(v cuh) https://x.test/"
  echo "A2 connect redis://:$(v rdu)@localhost:6379/0"
  echo "A3 {\"headers\":{\"Authorization\":[\"Basic $(v aha)\"]}}"
  echo "A4 [2026-11-26 10:00:01] export DB_PASSWORD=\"$(v lgp)\""
  echo "A5 password=\"\${X:-$(v dfl)}\""
  # other operators, an unquoted default, a value holding ' or , or {, name/value pairs, a
  # secret word inside a name, pass and Pwd keys, -storepass and -passout, a positional AWS secret key
  echo "B1 apiToken := \"$(v op1)\""
  echo "B2 'password' => '$(v op2)',"
  echo "B3 password ||= '$(v op3)'"
  echo "B4 export DB_PASS=\${DB_PW:-$(v op4)} && run"
  echo "B5 password: it's-$(v op5)"
  echo "B6 --password p@ss,$(v op6)"
  echo "B7 {\"name\": \"DB_PASSWORD\", \"value\": \"$(v nv1)\"}"
  echo "B8 <add key=\"DbPassword\" value=\"$(v nv2)\"/>"
  echo "B9 DB_PASSWORD_PROD=$(v sw1)"
  echo "B10 {\"user\":\"admin\",\"pass\":\"$(v ps1)\"}"
  echo "B11 Uid=sa;Pwd=$(v ps2);"
  echo "B12 keytool -storepass $(v ks1) -keypass $(v ks2)"
  echo "B13 openssl x -passout pass:$(v ks3)"
  echo "B14 aws configure set aws_secret_access_key wJalr$(v aw1)EXAMPLEKEYabcdefgh"
  # every string of a header array, a value written before its name, PASSPHRASE inside a name
  echo "C1 {\"Set-Cookie\":[\"sid=$(v ck1); Secure\",\"refresh=$(v ck2); Secure\"]}"
  echo "C2 {\"value\":\"$(v vn1)\",\"name\":\"DB_PASSWORD\"}"
  echo "C3 DB_PASSPHRASE_PROD=$(v pp1)"
  # a typed declaration, a name as an argument or subscript, a setter, other clients' flags, a
  # .netrc printed, a block scalar, a signature in a query
  echo "D1 const password: string = \"$(v td1)\";"
  echo "D2 os.environ[\"DB_PASSWORD\"] = \"$(v sb1)\""
  echo "D3 x.withPassword(\"$(v st1)\")"
  echo "D4 sqlcmd -S h -U SA -P \"$(v sq1)\""
  echo "D5 ldapsearch -x -w $(v ld1)"
  echo "D6 plink -pw $(v pl1) host"
  echo "D7 smbclient //h/s -U bob%$(v sm1)"
  echo "D8 machine api.test login bob password $(v nr1)"
  echo "D9 https://a.test/c?sv=1&sig=$(v sg1)"
  # the second line check: a header array whose first item is a Bearer token, a signature flag and setter
  echo "E1 {\"Authorization\":[\"Bearer abcdefghijklmnop$(v be1)\",\"Basic $(v be2)\"]}"
  echo "E2 cmd --signature $(v si1)"
  echo "E3 setSignature(\"$(v si2)\")"
}
KEEP='keep --password-file /some/path --token-limit 50 --password --verbose
gcc -pthread -pedantic -o x main.c
find . -name x -print
ssh -P 2222 host
mkdir -p build
mkdir -p "$D/x"
date -u; mkdir -p .vid/tw
sort -u x; mkdir -p tests/inv
docker compose -p app-$ID up
tsc -p tsconfig.json
zip -r out.zip dir
if a == b: x = 1
docker run -p 8080:80 img
docker run -u 1000 -p 8080:80 img
date -u '+%Y-%m-%dT%H:%M:%SZ'
mkdir -p "$D/$(date -u +%Y%m%d)"
docker run -u www-data:www-data img
mysql -p shopdb
redis-cli -n 2 ping
docker push -p x
grep -n "email=" a.py; cd "/tmp/a"
-  auth:
docker run -p 5432:5432 db
bypass=on
PWD=/x/y
OLDPWD=/y/z
the password is wrong and the token expired'
KEEP="$KEEP
$(printf 'grep -rn \047password=\047 src; echo it\047s here')"
{ plant; printf '%s\n' "$KEEP"; } > "$T/dev/run.log"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E"
while IFS= read -r l; do printf '{"type":"assistant","message":{"content":[{"type":"tool_use","input":{"command":"%s"}}]}}\n' "$(printf '%s' "$l" | esc)"; done < "$T/dev/run.log" > "$PR/$E/S-a.jsonl"
printf 'session id=S-a source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-a.jsonl" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-f --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-f
{ cat "$T/out" "$B.summary"; find "$B" -type f ! -name '*.gz' -exec cat {} +; find "$B" -type f -name '*.gz' -exec sh -c 'gzip -dc "$1"' _ {} \; ; } > "$T/all"
while IFS= read -r x; do [ -n "$x" ] || continue
  if grep -qF -- "$x" "$T/all"; then fail "a value is in the bundle, the summary or the output (planted as $(printf '%s' "$x" | cut -c1-3)…)"; fi
done < "$T/values"
G=$B/logs/run.log.gz; [ -f "$G" ] || fail 'the log is not in the bundle as logs/run.log.gz'
gzip -dc "$G" > "$T/log"; L=$T/log
for w in 'a --password "[REDACTED:secret-flag]" --name admin' "b --password '[REDACTED:secret-flag]'" 'c --password [REDACTED:secret-flag] --verbose' \
  'd --token "[REDACTED:secret-flag]"' 'e --secret [REDACTED:secret-flag]' 'f --api-key [REDACTED:secret-flag]' \
  'g docker login -u bot -p [REDACTED:secret-flag]' 'h mysql -uroot -p[REDACTED:secret-flag]' 'i {"password":"[REDACTED:secret-assignment]"}' \
  'j --password "[REDACTED:secret-flag]"' "k --password '[REDACTED:secret-flag]'" 'l --secret [REDACTED:secret-flag]' \
  "m PASSWORD '[REDACTED:secret-flag]'" "n CREATE USER app IDENTIFIED BY '[REDACTED:secret-flag]'" 'o curl -u admin:[REDACTED:secret-flag] https://x.test/' \
  'p DB_PASS=[REDACTED:secret-assignment]' 'q dbPwd: [REDACTED:secret-assignment]' 'r passphrase=[REDACTED:secret-assignment]' \
  's Authorization: Basic [REDACTED:auth-header]' 't Authorization: Token [REDACTED:auth-header]' 'u Cookie: [REDACTED:auth-header]' 'u2 Cookie: [REDACTED:auth-header]' \
  'v Set-Cookie: [REDACTED:auth-header]' 'w <password>[REDACTED:secret-assignment]</password>' 'x PGPASSWORD=[REDACTED:secret-assignment] psql' \
  'y password=[REDACTED:secret-assignment]' 'z password=[REDACTED:secret-assignment]' \
  'L1 sshpass -p [REDACTED:secret-flag] ssh host' 'L2 sshpass -p[REDACTED:secret-flag] ssh host' 'L3 mysql -p[REDACTED:secret-flag] shop' \
  'L4 /usr/bin/mysqldump -p[REDACTED:secret-flag] shop' 'L5 sudo mariadb -p[REDACTED:secret-flag]' 'L6 redis-cli -a [REDACTED:secret-flag] ping' \
  'L7 redis-cli --pass [REDACTED:secret-flag] ping' 'L8 docker login -p [REDACTED:secret-flag] registry.test' \
  'L9 podman login -p [REDACTED:secret-flag] registry.test' 'L10 helm registry login -p [REDACTED:secret-flag] registry.test' \
  'L11 sshpass -p [REDACTED:secret-flag] ssh host' 'R1 sshpass -p "[REDACTED:secret-flag]" ssh host' "R2 mysql -uroot -p'[REDACTED:secret-flag]' shop" \
  'R3 mongo -u "admin" -p "[REDACTED:secret-flag]" db' "R4 curl -u admin:'[REDACTED:secret-flag]' https://x.test" 'R5 <password>[REDACTED:secret-assignment]</password>' \
  'R6 {"headers":{"Authorization":"Basic [REDACTED:auth-header]"}}' "R7 h = {'Authorization': 'Token [REDACTED:auth-header]'}" \
  'S1 true;curl -u alice:[REDACTED:secret-flag] https://x.test' 'S2 true;redis-cli -a [REDACTED:secret-flag] ping' "S3 cli --password '[REDACTED:secret-flag]'" \
  "A1 curl -H 'Accept: text/html;q=0.9' -u admin:[REDACTED:secret-flag] https://x.test/" 'A2 connect redis://[REDACTED:url-credentials]@localhost:6379/0' \
  'A3 {"headers":{"Authorization":["Basic [REDACTED:auth-header]"]}}' 'A4 [2026-11-26 10:00:01] export DB_PASSWORD="[REDACTED:secret-assignment]"' \
  'A5 password="[REDACTED:secret-assignment]"' 'B1 apiToken := "[REDACTED:secret-assignment]"' "B2 'password' => '[REDACTED:secret-assignment]'," \
  "B3 password ||= '[REDACTED:secret-assignment]'" 'B4 export DB_PASS=[REDACTED:secret-assignment] && run' 'B5 password: [REDACTED:secret-assignment]' \
  'B6 --password [REDACTED:secret-flag]' 'B7 {"name": "DB_PASSWORD", "value": "[REDACTED:secret-assignment]"}' 'B8 <add key="DbPassword" value="[REDACTED:secret-assignment]"/>' \
  'B9 DB_PASSWORD_PROD=[REDACTED:secret-assignment]' 'B10 {"user":"admin","pass":"[REDACTED:secret-assignment]"}' 'B11 Uid=sa;Pwd=[REDACTED:secret-assignment];' \
  'B12 keytool -storepass [REDACTED:secret-flag] -keypass [REDACTED:secret-flag]' 'B13 openssl x -passout pass:[REDACTED:secret-assignment]' \
  'B14 aws configure set aws_secret_access_key [REDACTED:aws-secret-key]' 'C1 {"Set-Cookie":["[REDACTED:auth-header]","[REDACTED:auth-header]"]}' \
  'C2 {"value":"[REDACTED:secret-assignment]","name":"DB_PASSWORD"}' 'C3 DB_PASSPHRASE_PROD=[REDACTED:secret-assignment]' \
  'D1 const password: string = "[REDACTED:secret-assignment]";' 'D2 os.environ["DB_PASSWORD"] = "[REDACTED:secret-assignment]"' 'D3 x.withPassword("[REDACTED:secret-assignment]")' \
  'D4 sqlcmd -S h -U SA -P "[REDACTED:secret-flag]"' 'D5 ldapsearch -x -w [REDACTED:secret-flag]' 'D6 plink -pw [REDACTED:secret-flag] host' \
  'D7 smbclient //h/s -U bob%[REDACTED:secret-flag]' 'D8 machine api.test login bob password [REDACTED:secret-flag]' 'D9 https://a.test/c?sv=1&sig=[REDACTED:secret-assignment]' \
  'E1 {"Authorization":["Bearer [REDACTED:bearer]","Basic [REDACTED:auth-header]"]}' 'E2 cmd --signature [REDACTED:secret-flag]' 'E3 setSignature("[REDACTED:secret-assignment]")'; do
  grep -qxF -- "$w" "$L" || fail "not redacted as it should be: $(printf '%s' "$w" | cut -c1-14)… — got: $(grep -F -- "$(printf '%s' "$w" | cut -c1-2)" "$L" | head -n 1 | sed 's/[A-Za-z0-9]\{5,\}/…/g')"
done
printf '%s\n' "$KEEP" | while IFS= read -r k; do grep -qxF -- "$k" "$L" || { echo "share-redact-flag: a line with no secret changed: $k" >&2; exit 1; }; done
# the transcript: the same lines inside a JSON string, each one still a JSON line with its escapes intact
gzip -dc "$B/conversations/S-a/S-a.jsonl.gz" > "$T/conv"
grep -qF 'a --password \"[REDACTED:secret-flag]\" --name admin' "$T/conv" || fail 'the JSON-escaped quoted flag value is not redacted in its place'
grep -qF 'mkdir -p \"$D/x\"' "$T/conv" || fail 'mkdir -p "$D/x" changed inside the JSON string'
jsonok "$T/conv" > "$T/bad" || fail "transcript line $(cat "$T/bad") no longer parses as JSON"
for k in secret-flag auth-header secret-assignment; do grep -qx "redacted	$k	[0-9]*" "$B.summary" || fail "the summary does not count $k"; done
# a value put back by hand: the scan names the file and the kind, never the value
V3=$(sed -n 3p "$T/values"); { cat "$L"; echo "again --password $V3"; } | gzip > "$G"
if sh checks/share.sh scan "$B" > "$T/scan" 2>&1; then fail 'the scan passed a flag secret put back'; fi
grep -q 'logs/run.log.gz.*secret-flag' "$T/scan" || fail "the scan does not name the file and secret-flag: $(cat "$T/scan")"
! grep -qF -- "$V3" "$T/scan" || fail 'the scan printed the value'
echo 'share-redact-flag: ok'
