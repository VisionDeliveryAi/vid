#!/bin/sh
# Purpose: selftest case — personal data redacted by default (0.26.10.28.7, stage 3 R3). A made-up user: $HOME in a Users folder
# named `river`, a Windows Claude Code whose user name differs and holds a dot and a space (`jo q.doe`), read through its WSL
# mount (VID_SHARE_MOUNT), git config's email, the session context's email, an account and an organisation id, and the host
# name (VID_SHARE_HOST). Convicts unless: the Windows name is replaced in every home-path form (a drive's with one, two and four
# backslashes, a drive's with slashes, Git Bash's, the WSL mount's) and in its encoded form, in a record, a log and the
# transcript, in the events' transcript= lines and in the manifest's sources; $HOME's name is replaced after the Users and home
# prefixes and in its encoded forms; both emails and both ids are replaced wherever they appear; the host name is replaced after
# @ and in its host and hostname fields; the host name as a bare word stays. 0.26.10.28.9 (S3): the user names as whole words
# anywhere, in any case (`river`, and $USERNAME, here the GitHub login, so the login in a URL too), git's author name whole and
# each word of it, and Claude's orgName (plain, inside an escaped JSON string, and `<email>'s Organization`, whose email goes
# first, and a two-letter one as a whole word) are replaced; `user` and `"role":"user"` stay; a bare name planted in the bundle after its build is found by the scan.
# SHARE-SCRUB §4.4.4: an orgName field of capitalised words is a name field now (personal-field); the prose keeps org-name.
# Each is counted, and none of the replaced values is in the bundle, the summary, the manifest or the build's output. An id and
# an email harvested from fields with JSON spaces; with the conversations left
# out, a Windows name in the events still replaced; a non-ASCII $HOME name (Jose with an accent) replaced in its encoded form, one - a
# character. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-personal: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
U=Users; HM=home; HN=river; WN='jo q.doe'; WE=jo-q-doe; HOST=mybox-q7; LOGIN=octo-lyn; AN='Ada Morrow'; AW=Morrow; O1='Fenwick Labs'; O2='Tarn Works'
export USERNAME=$LOGIN
M1=jo.q@example.test; M2=wq@example.test; M3=r1.review@example.test; ID3=0c0c0c0c-1212-3434-5656-787878787878; ID1=0a1b2c3d-1111-2222-3333-444455556666; ID2=0f9e8d7c-7777-8888-9999-aaaabbbbcccc
export HOME="$T/h/$U/$HN"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
printf '[user]\n\temail = %s\n\tname = %s\n' "$M1" "$AN" > "$T/gitconfig"; export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
export VID_SHARE_HOST=$HOST VID_SHARE_MOUNT="$T/mnt"
P=$T/proj; mkdir -p "$P/checks" "$P/.vid/notes" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
# the text every place holds: each home-path form of both names, the emails, the ids, the host in its fields, the words that stay
forms() {
  printf 'cwd C:\\%s\\%s\\work and C:\\\\%s\\\\%s\\\\work and C:\\\\\\\\%s\\\\\\\\%s\\\\\\\\work\n' "$U" "$WN" "$U" "$WN" "$U" "$WN"
  printf 'path C:/%s/%s/work /c/%s/%s/work /mnt/c/%s/%s/work\n' "$U" "$WN" "$U" "$WN" "$U" "$WN"
  printf 'folder C--%s-%s-work and -mnt-c-%s-%s-work\n' "$U" "$WE" "$U" "$WE"
  printf 'home /%s/%s/x and /%s/%s/x and -%s-%s-proj and -%s-%s-proj\n' "$U" "$HN" "$HM" "$HN" "$U" "$HN" "$HM" "$HN"
  printf 'mail %s and %s\n' "$M1" "$M2"
  printf '{"accountUuid":"%s","organizationUuid":"%s"} and later %s\n' "$ID1" "$ID2" "$ID1"
  printf 'host\t%s\n{"hostname":"%s"} prompt %s@%s ~ %%\n' "$HOST" "$HOST" "$HN" "$HOST"
  printf 'the river flows; the box %s is named here as a word; pushed by %s to github.com/%s/app\n' "$HOST" "$LOGIN" "$LOGIN"
  printf 'by %s, then %s alone, at the RIVER; user and {"role":"user"} stay; orgs %s, %s and %s%ss Organization, team Zq, ada%%20Morrow\n' "$AN" "$AW" "$O1" "$O2" "$M1" "'"
}
forms > .vid/notes/text.txt; forms > "$T/dev/text.txt"; printf 'later %s and %s again\n' "$ID3" "$M3" >> .vid/notes/text.txt   # harvested with JSON spaces
WD="$T/mnt/c/$U/$WN/.claude/projects/C--$U-$WE-proj"; mkdir -p "$WD"
{ printf '{"type":"user","userEmail":"The user%ss email address is %s."}\n' "'" "$M2"; printf '{"accountUuid": "%s", "emailAddress" : "%s"}\n' "$ID3" "$M3"; forms
  printf '{"orgName":"%s"}\n{"content":"{\\"orgName\\":\\"%s\\"}"}\n{"orgName":"%s%ss Organization"}\n{"orgName":"Zq"}\n' "$O1" "$O2" "$M1" "'"; } > "$WD/S-win.jsonl"
printf 'session id=S-win source=startup transcript="C:\\%s\\%s\\.claude\\projects\\C--%s-%s-proj\\S-win.jsonl" at=2026-11-06T10:00:00Z\n' "$U" "$WN" "$U" "$WE" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-p --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-p; [ -f "$B/conversations/S-win/S-win.jsonl.gz" ] || fail 'the Windows transcript was not read through its mount'
for f in records/.vid/notes/text.txt logs/text.txt conversations/S-win/S-win.jsonl.gz; do
  case $f in *.gz) gzip -dc "$B/$f" ;; *) cat "$B/$f" ;; esac > "$T/f"
  grep -qF "C:\\$U\\[REDACTED:user-name]\\work and C:\\\\$U\\\\[REDACTED:user-name]\\\\work and C:\\\\\\\\$U\\\\\\\\[REDACTED:user-name]\\\\\\\\work" "$T/f" || fail "$f: a drive's backslash form is not replaced"
  grep -qF "path C:/$U/[REDACTED:user-name]/work /c/$U/[REDACTED:user-name]/work /mnt/c/$U/[REDACTED:user-name]/work" "$T/f" || fail "$f: a slash form is not replaced"
  grep -qF "folder C--$U-[REDACTED:user-name]-work and -mnt-c-$U-[REDACTED:user-name]-work" "$T/f" || fail "$f: the encoded Windows name is not replaced"
  grep -qF "home /$U/[REDACTED:user-name]/x and /$HM/[REDACTED:user-name]/x and -$U-[REDACTED:user-name]-proj and -$HM-[REDACTED:user-name]-proj" "$T/f" || fail "$f: the home name is not replaced"
  grep -qF 'mail [REDACTED:email] and [REDACTED:email]' "$T/f" || fail "$f: an email is not replaced"
  grep -qF '{"accountUuid":"[REDACTED:account-id]","organizationUuid":"[REDACTED:account-id]"} and later [REDACTED:account-id]' "$T/f" || fail "$f: an id is not replaced"
  grep -qxF 'host	[REDACTED:host]' "$T/f" && grep -qF "{\"hostname\":\"[REDACTED:host]\"} prompt [REDACTED:user-name]@[REDACTED:host] ~ %" "$T/f" || fail "$f: the host is not replaced in its fields"
  grep -qxF "the [REDACTED:user-name] flows; the box $HOST is named here as a word; pushed by [REDACTED:user-name] to github.com/[REDACTED:user-name]/app" "$T/f" || fail "$f: the bare name or the login-named user is not replaced, or the bare host did not stay"
  grep -qxF "by [REDACTED:author-name], then [REDACTED:author-name] alone, at the [REDACTED:user-name]; user and {\"role\":\"user\"} stay; orgs [REDACTED:org-name], [REDACTED:org-name] and [REDACTED:email]'s Organization, team [REDACTED:org-name], [REDACTED:author-name]%20[REDACTED:author-name]" "$T/f" || fail "$f: the author, a bare name or an organisation is not replaced, or user did not stay"
done
L=$(gzip -dc "$B/conversations/S-win/S-win.jsonl.gz" | head -n 1); [ "$L" = '{"type":"user","userEmail":"[REDACTED:personal-field]"}' ] || fail 'the session context email is not replaced'   # SHARE-SCRUB §4.4.4: userEmail is a personal field, its whole value goes
grep -qF "transcript=\"C:\\$U\\[REDACTED:user-name]\\.claude\\projects\\C--$U-[REDACTED:user-name]-proj\\S-win.jsonl\"" "$B/records/.vid/metrics-events" || fail "the events' transcript= line still names the user"
grep -qF "\"C--$U-[REDACTED:user-name]-proj/S-win.jsonl\"" "$B/MANIFEST.json" || fail "the manifest's source still names the user"
gzip -dc "$B/conversations/S-win/S-win.jsonl.gz" | tail -n 4 > "$T/o"; printf '{"orgName":"[REDACTED:personal-field]"}\n{"content":"{\\"orgName\\":\\"[REDACTED:personal-field]\\"}"}\n{"orgName":"[REDACTED:email]%ss Organization"}\n{"orgName":"[REDACTED:org-name]"}\n' "'" | cmp -s - "$T/o" || fail "the transcript's orgName is not replaced: $(cat "$T/o")"
for k in user-name email account-id host author-name org-name; do grep -q "\"$k\", [1-9]" "$B/MANIFEST.json" || fail "$k is not counted"; grep -q "^redacted	$k	[1-9]" "$B.summary" || fail "the summary does not count $k"; done
( cd "$B" && find . -type f | while IFS= read -r f; do case "$f" in *.gz) gzip -dc "$f" ;; *) cat "$f" ;; esac; done ) > "$T/all"
cat "$B.summary" "$B/MANIFEST.json" "$T/out" >> "$T/all"
for x in "$WN" "$WE" "/$U/$HN" "/$HM/$HN" "-$U-$HN-" "-$HM-$HN-" "$M1" "$M2" "$ID1" "$ID2" "$ID3" "$M3" "@$HOST" "host	$HOST" "\"$HOST\"" "$AW" Ada "$O1" "$O2" "$LOGIN"; do
  N=$(grep -cF -- "$x" "$T/all" || true); [ "$N" = 0 ] || fail "a replaced value is left on $N lines"; done
N=$(grep -ciw -- "$HN" "$T/all" || true); [ "$N" = 0 ] || fail "the bare name is left on $N lines"
grep -qx 'scan	clean' "$B.summary" || fail 'the scan is not clean'
# a bare name planted after the build: the scan finds it, by kind
printf 'planted River here\n' >> "$B/records/.vid/notes/text.txt"
if sh checks/share.sh scan "$B" > "$T/sc" 2>&1; then fail 'the scan found nothing after a bare name was planted'; fi
grep -q 'records/.vid/notes/text.txt	user-name	1' "$T/sc" || fail "the scan does not name the planted bare name: $(cat "$T/sc")"
# with the conversations left out, the events' Windows name is still found; a non-ASCII $HOME name's encoded
# form has one - per character (an accented e is two bytes, one -)
JN=$(printf 'Jos\303\251'); RN=Win.Reviewer; RE=Win-Reviewer
export HOME="$T/h2/$U/$JN"; mkdir -p "$HOME"; P2=$T/proj2; mkdir -p "$P2/checks" "$P2/.vid/notes"; cp "$CHECKS/share.sh" "$P2/checks/"; cd "$P2"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
printf 'session id=S-r source=startup transcript="C:\\%s\\%s\\.claude\\projects\\C--%s-%s-app\\S-r.jsonl" at=2026-11-06T10:00:00Z\n' "$U" "$RN" "$U" "$RE" > .vid/metrics-events
printf 'from /%s/%s/app and folder -%s-Jos--app and C:\\%s\\%s\\app and C--%s-%s-app\n' "$U" "$JN" "$U" "$U" "$RN" "$U" "$RE" > .vid/notes/n.txt
sh checks/share.sh build --run 2026-11-q --leave-out conversations > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the second build failed'; }
B=.vid/shares/2026-11-q
grep -qxF "from /$U/[REDACTED:user-name]/app and folder -$U-[REDACTED:user-name]-app and C:\\$U\\[REDACTED:user-name]\\app and C--$U-[REDACTED:user-name]-app" "$B/records/.vid/notes/n.txt" || fail 'a non-ASCII or a Windows name from the events is not replaced'
( cd "$B" && find . -type f | while IFS= read -r f; do case "$f" in *.gz) gzip -dc "$f" ;; *) cat "$f" ;; esac; done ) > "$T/all"
cat "$B.summary" "$B/MANIFEST.json" "$T/out" >> "$T/all"
for x in "$JN" "-$U-Jos-" "$RN" "$RE"; do N=$(grep -cF -- "$x" "$T/all" || true); [ "$N" = 0 ] || fail "a replaced name is left on $N lines"; done
echo 'share-personal: ok'
