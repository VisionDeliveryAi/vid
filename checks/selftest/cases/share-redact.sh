#!/bin/sh
# Purpose: selftest case — every secret kind redacted in every form (0.26.10.28.7, stage 3 R3). A value of every kind redaction
# covers (private-key, literal, github-token, anthropic-key, openai-key, stripe-key, aws-key, slack-token, google-key, npm-token,
# jwt, bearer, url-credentials, token-header, aws-secret-key, account-id, secret-assignment in upper and lower case) is planted
# in a record, a log and a transcript (gzipped in the bundle), each as plain text, inside a JSON string (escaped quotes, the
# value ending at a literal \n) and doubly escaped inside a request payload, every value distinct and made up here. Convicts
# unless each becomes [REDACTED:<kind>], the manifest counts each kind per file (three forms each, six for the two assignments),
# the summary names every kind, and no planted value is anywhere: the bundle (gzipped files read back), the summary, the
# manifest, or the build's own output. The five kinds the owner's packer misses (DJANGO_SECRET_KEY=…, api_key: "…", an AWS
# secret key, a JWT, a Stripe key) are named among them. The values are built from pieces at run time, never written whole
# here. Bare names (password, secret, token, PASSWORD) and quoted values with spaces, in every form and place,
# are redacted to their end and prose with those words stays; private keys whose BEGIN is not alone on its line (a quoted .env
# value over lines, line-numbered output, CRLF lines, a JSON string cut before its END) are redacted, the lines after them kept.
# an escaped quote or a marker inside a quoted value, mixed-case bare names, short quoted values and a PGP
# private key block are redacted whole, in every form and place. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-redact: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E"
rep() { awk -v c="$1" -v n="$2" 'BEGIN { for (i = 0; i < n; i++) printf "%s", c }'; }
esc() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
jn() { esc | awk '{ printf "%s%s", (NR > 1 ? "\\n" : ""), $0 }'; }
: > "$T/values"; : > "$T/lits"
v() { printf '%s\n' "$1" >> "$T/values"; printf '%s' "$1"; }
# plants <tag>: the plain lines of one place and form, every value carrying the tag
plants() { t=$1
  echo "the token is $(v "gh""p_$t$(rep a 24)") here"
  echo "key $(v "sk-""ant-api03-$t$(rep b 24)")"
  echo "key $(v "sk-""proj-$t$(rep c 34)")"
  echo "stripe $(v "sk""_live_$t$(rep d 16)")"
  echo "aws id $(v "AK""IA$t$(rep Z 14)")"
  echo "slack $(v "xo""xb-$t$(rep 1 12)")"
  echo "google $(v "AI""za$t$(rep e 33)")"
  echo "npm $(v "np""m_$t$(rep f 34)")"
  echo "jwt $(v "ey""J$t$(rep g 12).ey""J$(rep h 12).$(rep i 12)")"
  echo "Authorization: Bearer $(v "$(rep j 18)$t")"
  echo "DATABASE_URL=postgres://app:$(v "pw$t$(rep k 8)")@db:5432/x"
  echo "X-Auth-Token: $(v "$t$(rep m 10)")"
  echo "aws_secret_access_key = $(v "$t$(rep n 38)")"
  d=$(printf '%s' "$t" | tr 'RLC' '123' | tr -d -c '0-9'); echo "accountUuid: $(v "${d}aaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")"
  echo "DJANGO_SECRET_KEY=$(v "dj$t$(rep o 10)")"
  echo "{\"api_key\": \"$(v "ak$t$(rep p 10)")\"}"
  l="lit$t-Zq9"; printf '%s\n' "$l" >> "$T/lits"; v "$l" > /dev/null; echo "the literal $l here"
}
key() { printf -- '-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----\n' "$(v "MIIB$1$(rep q 20)")"; }
# place <file> <letter>: form 1 plain, form 2 inside a JSON string, form 3 doubly escaped in a request payload
place() {
  { plants "${2}1"; key "${2}1"
    plants "${2}2" | while IFS= read -r l; do printf '{"type":"user","content":"%s\\nmore"}\n' "$(printf '%s' "$l" | esc)"; done
    printf '{"type":"user","content":"%s"}\n' "$(key "${2}2" | jn)"
    plants "${2}3" | while IFS= read -r l; do j=$(printf '{"content":"%s\\nmore"}' "$(printf '%s' "$l" | esc)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"; done
    j=$(printf '{"content":"%s"}' "$(key "${2}3" | jn)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"
  } > "$1"
}
place .vid/notes/plants.txt R; place "$T/dev/plants.txt" L; place "$PR/$E/S-plant.jsonl" C
grep -qF '\\\"api_key\\\": \\\"akR3' .vid/notes/plants.txt || fail 'the fixture has no doubly escaped form'
grep -qF 'PRIVATE KEY-----\\nMIIBR3' .vid/notes/plants.txt || fail 'the fixture has no doubly escaped key'
[ "$(grep -c . "$T/values")" = 162 ] || fail "the fixture planted $(grep -c . "$T/values") values, not 162"
# bare secret names, quoted values with spaces, private keys whose BEGIN is not alone on its line
# (a quoted .env value over lines, line-numbered tool output, CRLF lines, a JSON string cut before its END), each in every form
p1() { t=$1
  echo "password=$(v "pw1$t$(rep r 6)")"; echo "password: $(v "pw2$t$(rep r 6)")"; echo "{\"password\":\"$(v "pw3$t$(rep r 6)")\"}"
  echo "secret: $(v "se1$t$(rep r 6)")"; echo "token=$(v "to1$t$(rep r 6)")"; echo "PASSWORD=$(v "pw4$t$(rep r 6)")"
  echo "DB_PASSWORD=\"correct horse $(v "hb$t$(rep s 6)") staple\""; echo "{\"db_password\": \"tall $(v "tw$t$(rep s 6)") wall\"}"
  echo "the password is long and the token here is not set: prose stays $t"
}
k1() { t=$1; cr=$(printf '\r')
  case $2 in
    a) printf 'PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----"\n' "$(v "MIIa$t$(rep u 20)")" ;;
    b) printf '    12\342\206\222-----BEGIN OPENSSH PRIVATE KEY-----\n    13\342\206\222%s\n    14\342\206\222-----END OPENSSH PRIVATE KEY-----\n' "$(v "b3Bb$t$(rep u 20)")" ;;
    c) printf -- '-----BEGIN RSA PRIVATE KEY-----%s\n%s%s\n-----END RSA PRIVATE KEY-----%s\n' "$cr" "$(v "MIIc$t$(rep u 20)")" "$cr" "$cr" ;;
  esac; }
place1() {
  { p1 "${2}1"; for b in a b c; do k1 "${2}1" $b; echo "after block $b stays ${2}1"; done
    p1 "${2}2" | while IFS= read -r l; do printf '{"type":"user","content":"%s\\nmore"}\n' "$(printf '%s' "$l" | esc)"; done
    for b in a b c; do printf '{"type":"user","content":"%s"}\n' "$(k1 "${2}2" $b | jn)"; done
    printf '{"type":"user","content":"-----BEGIN RSA PRIVATE KEY-----\\n%s\\nMIIcut"}\n' "$(v "MIId$2$(rep u 20)")"; echo "after the cut key stays ${2}2"
    p1 "${2}3" | while IFS= read -r l; do j=$(printf '{"content":"%s\\nmore"}' "$(printf '%s' "$l" | esc)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"; done
    for b in a b c; do j=$(printf '{"content":"%s"}' "$(k1 "${2}3" $b | jn)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"; done
  } > "$1"
}
place1 .vid/notes/extra.txt R; place1 "$T/dev/extra.txt" L; place1 "$PR/$E/S-extra.jsonl" C
grep -q "$(printf '\r')$" .vid/notes/extra.txt || fail 'the fixture has no CRLF line'
# an escaped quote inside a quoted value, a marker inside one, mixed-case bare names, short quoted values,
# a PGP private key block; each in every form and place
p2() { t=$1
  echo "{\"db_password\":\"prefix$t\\\"$(v "Surv1$t$(rep w 4)") rest\"}"; echo "{\"password\":\"ab\\\"$(v "cd$t$(rep w 4)") ijk\"}"
  echo "DB_PASSWORD=\"gh""p_$(rep w 30) $(v "Surv2$t$(rep w 4)") rest\""
  echo "pAsSwOrD=$(v "mc1$t$(rep w 6)")"; echo "sEcReT=$(v "mc2$t$(rep w 6)")"; echo "tOkEn=$(v "mc3$t$(rep w 6)")"
  echo "password=\"$(v "x$t")\""; echo "{\"password\":\"$(v "P5$t")\"}"; echo "DB_PASSWORD=\"$(v "h$t")\""
  printf '%s\n' "password=\"ab $(v "bs$t$(rep w 4)")\\\\\""   # the integration's final review: a value ending in escaped backslashes, in every form
  printf '%s\n' "password='ab $(v "sq$t$(rep w 4)")\\'"; printf '%s\n' "password=$(v "uq$t$(rep w 6)")\\"   # a single-quoted value ending in a backslash (literal in single quotes), and its unquoted twin
  printf '%s\n' "password='ab $(v "jq$t$(rep w 4)")\\'$(v "jr$t$(rep w 4)") cd'"   # and, as code reads it, a backslashed quote inside a single-quoted value: both halves go
  printf '%s\n' "password='ab\\'$(v "kq$t$(rep w 6)")\\\\'"   # and every quote after a backslash, as Python's 'ab\'<secret>\\': to the last quote
  printf '%s\n' "echo password=\\'ab'cd ef'gh$(v "dq$t$(rep w 6)")\\'"   # a value opened by \' closes at its own depth, never at a bare quote inside it
}
k2() { printf -- '-----BEGIN PGP PRIVATE KEY BLOCK-----\n\n%s\n-----END PGP PRIVATE KEY BLOCK-----\n' "$(v "lQOY$1$(rep w 20)")"; }
place2() {
  { p2 "${2}1"; k2 "${2}1"; echo "after the PGP block stays ${2}1"
    p2 "${2}2" | while IFS= read -r l; do printf '{"type":"user","content":"%s\\nmore"}\n' "$(printf '%s' "$l" | esc)"; done
    printf '{"type":"user","content":"%s"}\n' "$(k2 "${2}2" | jn)"
    p2 "${2}3" | while IFS= read -r l; do j=$(printf '{"content":"%s\\nmore"}' "$(printf '%s' "$l" | esc)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"; done
    j=$(printf '{"content":"%s"}' "$(k2 "${2}3" | jn)"); printf '{"type":"api-request","body":"%s"}\n' "$(printf '%s' "$j" | esc)"
  } > "$1"
}
place2 .vid/notes/extra2.txt R; place2 "$T/dev/extra2.txt" L; place2 "$PR/$E/S-extra2.jsonl" C
{ printf 'session id=S-plant source=startup transcript=%s at=2026-11-05T10:00:00Z\n' "$PR/$E/S-plant.jsonl"
  printf 'session id=S-extra source=startup transcript=%s at=2026-11-05T10:10:00Z\n' "$PR/$E/S-extra.jsonl"
  printf 'session id=S-extra2 source=startup transcript=%s at=2026-11-05T10:20:00Z\n' "$PR/$E/S-extra2.jsonl"; } > .vid/metrics-events
sh checks/share.sh build --run 2026-11-r --logs "$T/dev" --redact-file "$T/lits" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-r
# nothing planted is left anywhere
( cd "$B" && find . -type f | while IFS= read -r f; do case "$f" in *.gz) gzip -dc "$f" ;; *) cat "$f" ;; esac; done ) > "$T/all"
sh checks/share.sh scan "$B" > "$T/scan" 2>&1 || fail "the scan of the bundle failed"
cat "$B.summary" "$B/MANIFEST.json" "$T/out" "$T/scan" >> "$T/all"
N=$(grep -c -F -f "$T/values" "$T/all" || true); [ "$N" = 0 ] || fail "$N lines of the bundle, the summary, the manifest or the output hold a planted value"
# each kind redacted and counted, per file
for f in records/.vid/notes/plants.txt logs/plants.txt conversations/S-plant/S-plant.jsonl.gz; do
  for k in private-key literal github-token anthropic-key openai-key stripe-key aws-key slack-token google-key npm-token jwt bearer url-credentials token-header aws-secret-key account-id secret-assignment; do
    n=3; [ $k != secret-assignment ] || n=6
    grep -qF "[\"$f\", \"$k\", $n]" "$B/MANIFEST.json" || fail "$f: $k not counted $n times"
    grep -qx "redacted	$k	[0-9]*" "$B.summary" || fail "the summary does not name $k"
  done
done
gzip -dc "$B/conversations/S-plant/S-plant.jsonl.gz" | grep -qF '\\\"api_key\\\": \\\"[REDACTED:secret-assignment]\\\"' || fail 'the doubly escaped form is not redacted in its place'
grep -qF '{"type":"user","content":"DJANGO_SECRET_KEY=[REDACTED:secret-assignment]\nmore"}' "$B/records/.vid/notes/plants.txt" || fail 'the value ending at a literal \n is not redacted to it'
# the owner's packer's misses, by name
for s in 'DJANGO_SECRET_KEY=[REDACTED:secret-assignment]' '{"api_key": "[REDACTED:secret-assignment]"}' 'aws_secret_access_key = [REDACTED:aws-secret-key]' 'jwt [REDACTED:jwt]' 'stripe [REDACTED:stripe-key]'; do
  grep -qxF "$s" "$B/logs/plants.txt" || fail "not redacted: $s"; done
grep -qx 'scan	clean' "$B.summary" || fail 'the scan of the redacted bundle is not clean'
# the bare names, the quoted values and the keys, gone and counted; prose and the lines after each key stay
for f in records/.vid/notes/extra.txt logs/extra.txt conversations/S-extra/S-extra.jsonl.gz; do
  case $f in *.gz) gzip -dc "$B/$f" ;; *) cat "$B/$f" ;; esac > "$T/f"
  grep -q "\[\"$f\", \"secret-assignment\", 24\]" "$B/MANIFEST.json" || fail "$f: the bare names and quoted values are not counted 24 times"
  grep -q "\[\"$f\", \"private-key\", 10\]" "$B/MANIFEST.json" || fail "$f: the keys are not counted 10 times"
  for t in 1 2 3; do grep -q "the password is long and the token here is not set: prose stays .$t" "$T/f" || fail "$f: the prose of form $t did not stay"; done
  for b in a b c; do grep -q "^after block $b stays .1" "$T/f" || fail "$f: the line after key $b did not stay"; done
  grep -q '^after the cut key stays .2$' "$T/f" || fail "$f: the line after the cut key did not stay"
done
grep -qxF 'DB_PASSWORD="[REDACTED:secret-assignment]"' "$B/logs/extra.txt" && grep -qxF 'password=[REDACTED:secret-assignment]' "$B/logs/extra.txt" || fail 'a quoted value or a bare name is not redacted to its end'
# counted, the line after the PGP block kept, the escaped-quote value redacted whole
for f in records/.vid/notes/extra2.txt logs/extra2.txt conversations/S-extra2/S-extra2.jsonl.gz; do
  case $f in *.gz) gzip -dc "$B/$f" ;; *) cat "$B/$f" ;; esac > "$T/f"
  grep -q "\[\"$f\", \"secret-assignment\", 45\]" "$B/MANIFEST.json" || fail "$f: the review-2 values are not counted 45 times"
  grep -q "\[\"$f\", \"private-key\", 3\]" "$B/MANIFEST.json" || fail "$f: the PGP blocks are not counted 3 times"
  grep -q '^after the PGP block stays .1$' "$T/f" || fail "$f: the line after the PGP block did not stay"
done
grep -qxF '{"db_password":"[REDACTED:secret-assignment]"}' "$B/logs/extra2.txt" || fail 'the value with an escaped quote is not redacted whole'
echo 'share-redact: ok'
