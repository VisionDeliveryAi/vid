#!/bin/sh
# Purpose: selftest case — other people's personal data redacted by shape and by field (SHARE-SCRUB §4.4). A log and a transcript
# (each line also inside a JSON string) hold made-up: emails of others (one right after a JSON \n escape), phone numbers (+44 …,
# +1 (555) …, NNN-NNN-NNNN, a phone field), IPv4 and IPv6 addresses, a card number that passes the Luhn check and one that fails,
# an IBAN that passes mod 97 and one that fails, personal fields in JSON, YAML, = and XML (full_name, dob, street, postcode,
# passport, firstName), and a name field holding two capitalised words. Kept byte for byte: "name":"Bash", "name": "vid-share",
# 0.26.11.2 and 0.26.11.1.13, 127.0.0.1, ::1, an ISO date and time, 20261125143000, 1764067200000, a 40-hex commit id, a UUID, a
# card-shaped number that fails Luhn, an IBAN-shaped one that fails mod 97, std::vector. Convicts unless each planted value is
# gone from the bundle and the build's output, each where planted is its kind, the kept lines stay, every transcript line is
# still a JSON line whose \n escape before the email is intact, and the summary counts each new kind. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-redact-pii: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
printf 'run: active\n' > .vid/RUN-STATE.md
jsonok() { python3 -I -c 'import json,sys
for n, l in enumerate(open(sys.argv[1], encoding="utf-8", errors="surrogateescape"), 1):
    try: json.loads(l)
    except Exception: print(n); sys.exit(1)' "$1"; }
esc() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
# the planted values, each line: <value>\t<the line it sits in, VALUE where it goes>\t<kind>
cat > "$T/table" <<'EOF'
ann.quill@corp-mail.test	mail a VALUE here	email
b.tarn+x@sub.example.test	{"to":"VALUE"}	email
+44 20 7946 0958	call VALUE today	phone
+1 (555) 010-2345	ring VALUE	phone
555-010-7788	or VALUE then	phone
0201 445 778	phone: VALUE	personal-field
192.0.2.41	from VALUE port 22	ip-address
10.20.30.40	host=VALUE	ip-address
2001:db8::8a2e:370:7334	v6 VALUE ok	ip-address
fe80:0:0:0:200:f8ff:fe21:67cf	v6 VALUE full	ip-address
4111 1111 1111 1111	card VALUE end	card-number
5500005555555559	card VALUE end	card-number
GB82 WEST 1234 5698 7654 32	iban VALUE end	iban
DE89370400440532013000	iban VALUE end	iban
Ann Quill	{"full_name": "VALUE", "id": 3}	personal-field
1984-02-29	dob: VALUE	personal-field
14 Fenwick Row	street=VALUE	personal-field
ZZ9 9ZZ	<postcode>VALUE</postcode>	personal-field
X1234567	{"passport":"VALUE"}	personal-field
Brannoch	firstName: 'VALUE'	personal-field
Tavi Morrow	{"name": "VALUE", "role": "admin"}	personal-field
4012 8888 8888 1881	pay VALUE 12/34 cvc 123	card-number
5105105105105100	pay VALUE 0	card-number
GB33BUKB20201555555555	iban VALUE 2	iban
+447700900123	sms VALUE 1764067200000	phone
+44 20 7946 0123	call VALUE 2026 11 25	phone
9 Larch Close	{"customer_billing_address":"VALUE"}	personal-field
6011 0009 9013 9424	pay VALUE 2026	card-number
4000056655665556	use VALUE.	card-number
4917610000000000	attempt 2 VALUE declined	card-number
GB29 NWBK 6016 1331 9268 19	iban AB12 VALUE x	iban
Fennel Quenby	<name>VALUE</name>	personal-field
O'Brien-Hale	last_name: VALUE	personal-field
14 Harbour Row, Cobh P24 X2K8	address: VALUE	personal-field
zoë.brennan@example.test	sent to VALUE ok	email
9 Elm St	{"line1":"VALUE"}	personal-field
40001234	{"account_number":"VALUE"}	personal-field
Jean-Luc Ferrand	{"name":"VALUE"}	personal-field
Ann O'Neill	{"name":"VALUE"}	personal-field
fennel@例え.テスト	contact VALUE now	email
1986-09-17	{"birthdate":"VALUE"}	personal-field
1987-03-14	{"birthday":"VALUE"}	personal-field
020 7946 0952	{"phoneNo":"VALUE"}	personal-field
Mrs. Ann B. Lee	{"name":"VALUE"}	personal-field
ann.lee%40example.test	GET /reset?user=VALUE 500	email
3782 822463 10005	card VALUE declined	card-number
EOF
KEEP='{"type":"tool_use","name":"Bash"}
{"name": "vid-share"}
ViD 0.26.11.2 and 0.26.11.1.13
listen 127.0.0.1:8080 and [::1]:9
at 2026-11-25T14:32:00Z and 20261125143000 and 1764067200000
commit 3f6c2a1b9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a
session 0e4e3237-acd5-48a1-bad2-464b02fda817
card 4111111111111112 fails
iban GB82WEST12345698765433 fails
std::vector and a::b'
{ while IFS='	' read -r val line kind; do printf '%s\n' "$line" | awk -v v="$val" '{ i = index($0, "VALUE"); print substr($0, 1, i - 1) v substr($0, i + 5) }'; done < "$T/table"
  printf '%s\n' "$KEEP"; } > "$T/dev/run.log"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E"
{ while IFS= read -r l; do printf '{"type":"user","message":{"content":"%s"}}\n' "$(printf '%s' "$l" | esc)"; done < "$T/dev/run.log"
  printf '{"type":"user","message":{"content":"first line\\nzed.orr@corp-mail.test wrote"}}\n'
  printf '{"type":"num","a":-99614720,"b":99614720.5,"c":0.99614720}\n'
  printf '{"type":"cost","used":0.4111111111111111,"t":1,"ls":"src/authorization:\\nindex.ts","c":"Cookie:\\n  sent"}\n'   # kept, the line whole
  printf '{"type":"fx","phone_number":"0201 445 990","passportNumber":"Q7781234"}\n'
  printf '{"type":"user","message":{"content":"send it as Cookie:"},"uuid":"u1","c":{"cookie":12345,"n":1}}\n'   # parses still
  printf '{"type":"tool","address":{"street":"9 Wick Yard","city":"x"},"cc":5500005555555559,"n":[1,2]}\n'
  printf '{"type":"user","message":{"content":"a\\nstreet: 9 Quill Lane\\nphone: 0201 445 779\\nnext"}}\n'; } > "$PR/$E/S-p.jsonl"
printf 'session id=S-p source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-p.jsonl" > .vid/metrics-events
export APP_SECRET=99614720   # a known value equal to a number MANIFEST.json holds (the split limit), and signed and with a fraction in a transcript
sh checks/share.sh build --run 2026-11-p --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-p
{ cat "$T/out" "$B.summary"; find "$B" -type f ! -name '*.gz' -exec cat {} +; find "$B" -type f -name '*.gz' -exec sh -c 'gzip -dc "$1"' _ {} \; ; } > "$T/all"
cut -f1 "$T/table" | while IFS= read -r x; do
  if grep -qF -- "$x" "$T/all"; then echo "share-redact-pii: a value is in the bundle, the summary or the output: $(printf '%s' "$x" | cut -c1-4)…" >&2; exit 1; fi
done
grep -qF 'zed.orr@corp-mail.test' "$T/all" && fail 'the email after a JSON \n escape is in the bundle'
gzip -dc "$B/logs/run.log.gz" > "$T/log"
while IFS='	' read -r val line kind; do
  w=$(printf '%s\n' "$line" | awk -v k="$kind" '{ i = index($0, "VALUE"); print substr($0, 1, i - 1) "[REDACTED:" k "]" substr($0, i + 5) }')
  grep -qxF -- "$w" "$T/log" || fail "not redacted as it should be: $(printf '%s' "$w" | cut -c1-12)… (kind $kind)"
done < "$T/table"
printf '%s\n' "$KEEP" | while IFS= read -r k; do grep -qxF -- "$k" "$T/log" || { echo "share-redact-pii: a line with no personal data changed: $k" >&2; exit 1; }; done
gzip -dc "$B/conversations/S-p/S-p.jsonl.gz" > "$T/conv"
grep -qF '"content":"first line\n[REDACTED:email] wrote"' "$T/conv" || fail "the \\n escape before the email is not intact: $(tail -n 1 "$T/conv" | sed 's/[a-z]\{4,\}/…/g')"
grep -qF '"content":"a\nstreet: [REDACTED:personal-field]\nphone: [REDACTED:personal-field]\nnext"}}' "$T/conv" || fail 'a YAML field inside a JSON string ran past its escapes'
grep -qF 'Quill Lane' "$T/conv" && fail 'the street inside a JSON string is in the bundle'
python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$B/MANIFEST.json" || fail 'MANIFEST.json no longer parses as JSON'
grep -qF '{"type":"cost","used":0.4111111111111111,"t":1,"ls":"src/authorization:\nindex.ts","c":"Cookie:\n  sent"}' "$T/conv" || fail 'a float, or a header name before a \n escape, changed'
grep -qF '{"type":"fx","phone_number":"[REDACTED:personal-field]","passportNumber":"[REDACTED:personal-field]"}' "$T/conv" || fail 'phone_number or passportNumber is not a personal field'
jsonok "$T/conv" > "$T/bad" || fail "transcript line $(cat "$T/bad") no longer parses as JSON"
grep -qF '{"type":"tool","address":{"street":"[REDACTED:personal-field]","city":"x"},"cc":"[REDACTED:card-number]","n":[1,2]}' "$T/conv" || fail "the nested address or the JSON-number card is not as it should be: $(grep '"type":"tool"' "$T/conv" | sed 's/[A-Za-z]\{5,\}/…/g')"
for k in email phone ip-address card-number iban personal-field; do grep -qx "redacted	$k	[0-9]*" "$B.summary" || fail "the summary does not count $k"; done
echo 'share-redact-pii: ok'
