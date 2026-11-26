#!/bin/sh
# Purpose: selftest case — values the machine knows to be secret or personal are redacted wherever they appear, in any form
# (SHARE-SCRUB §4.1, §4.5.1). Made up here: a secret-named environment variable, and secret-named keys in a dotenv file of the home
# and of the logs folder (one a URL with a password); each value then appears in a transcript where no rule sees it (`login admin
# <v>`), raw, JSON-escaped (it holds a quote) and percent-encoded. A committer and a Co-authored-by name in the home's history,
# named in a transcript and a log; a [bot] committer and ViD's own identity, whose names stay. A .env, an id_rsa and an x.pem in
# the logs folder. Convicts unless each value is gone (known-secret, person-name), the kept names stay, the three files are left
# out and listed by name, no secret value is in .known, the summary, the review page or any other file under .vid/shares/, and
# `scan` on the bundle with a dotenv value put back exits 1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-known-values: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; PR=$CLAUDE_CONFIG_DIR/projects
P=$T/proj; mkdir -p "$P/checks" "$P/.vid" "$P/app" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q; P=$(pwd -P)
git config user.name 'Wren Toy'; git config user.email wren@example.test
printf 'run: active\n' > .vid/RUN-STATE.md
t=$(date +%s | cksum | cut -c1-5)
EV="ev$t"'"Qx9'; DV="dv${t}Zk3m"; DV2="Dl${t}Pq8w"; LV="lv${t}Wq2p"; UV="up${t}Ty7r"; QV="qv${t}Hn4w"; CV="cv${t}Rb8e"
export FENWICK_API_TOKEN="$EV"; UK="uk${t}Jw5z"; export _FENWICK_KEY="$UK"   # the line check: a name starting _
printf 'PORT=3000\nNODE_ENV=development\nSTRIPE_SECRET=%s\nDATABASE_URL=postgres://app:%s@db:5432/x\nAPI_TOKEN="%s"\nAPP_PASSWORD=%s # the dev one\nAPP_TOKEN='\''$%s'\''\n' "$DV" "$UV" "$QV" "$CV" "$DV2" > app/.env
printf 'export LOG_PASSWORD="%s"\nADMIN_PASSWORD=Sup%sSecret\nDB_PASSWORD_PROD=Sx%sProd9\n' "$LV" "$t" "$t" > "$T/dev/.env.local"   # a suffixed name; a value ending in a secret word
printf 'DB_PASSWORD=password\nAPI_KEY=placeholder-key-1\n' > app/.env.example
WV="wv${t}Jc5x"; mkdir -p "$T/side"; printf 'SIDE_SECRET=%s\n' "$WV" > "$T/side/.env"
mkdir -p "$T/dev/clones/app"; ( cd "$T/dev/clones/app" && git init -q && echo x > a && git add a && GIT_AUTHOR_NAME='Ilse Marrow-Venn' GIT_AUTHOR_EMAIL=imv@corp-mail.test git -c user.name='Ilse Marrow-Venn' -c user.email=imv@corp-mail.test commit -qm one )   # the line check: a clone inside a left-out folder
printf 'k\n' > "$T/dev/id_rsa"; printf 'k\n' > "$T/dev/x.pem"; printf 'plain\n' > "$T/dev/notes.txt"
# the history: a committer, a co-author, a bot and ViD's own identity
git add -A app 2>/dev/null || true; echo a > a.txt; git add a.txt
GIT_AUTHOR_NAME='Orla Quenby' GIT_AUTHOR_EMAIL=orla.q@corp-mail.test GIT_COMMITTER_NAME='Teodor Vasquez-Lind' GIT_COMMITTER_EMAIL=tvl@corp-mail.test git commit -qm "one

Co-authored-by: Pim Vantongeren <pim.v@corp-mail.test>"
echo e > e.txt; git add e.txt; { echo many; echo; i=1; while [ $i -le 33 ]; do printf 'Co-authored-by: Pers%s Namq%s <p%s@corp-mail.test>\n' $(echo $i | tr 0-9 a-j) $(echo $i | tr 0-9 k-t) $i; i=$((i + 1)); done; } > "$T/msg"; git commit -qF "$T/msg"   # past 32 people
echo d > d.txt; git add d.txt; GIT_AUTHOR_NAME='Sabine Okonkwo-Hale' GIT_AUTHOR_EMAIL=4242+sabhale@users.noreply.github.com git commit -qm four
echo b > b.txt; git add b.txt; GIT_AUTHOR_NAME='renovate[bot]' GIT_AUTHOR_EMAIL=bot@users.example.test git commit -qm two
echo c > c.txt; git add c.txt; GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid git commit -qm three
pct() { printf '%s' "$1" | LC_ALL=C awk 'BEGIN { for (i = 1; i < 256; i++) O[sprintf("%c", i)] = i } { for (i = 1; i <= length($0); i++) { c = substr($0, i, 1); printf "%s", (c ~ /[A-Za-z0-9._~-]/ ? c : sprintf("%%%02X", O[c])) } }'; }   # as a URL encodes it
EVJ=$(printf '%s' "$EV" | sed 's/"/\\"/g')
{ echo "login admin $DV"; echo "GET /u?login=orla.q%40corp-mail.test 200 https://x.test/u/orla.quenby by Quenby, Orla"; echo "and Sup${t}Secret and Sx${t}Prod9"; echo "key $UK and Ilse Marrow-Venn"; echo "and \$$DV2 too"; echo "then $LV and $UV"; echo "also $QV and $CV"; echo "Sabine Okonkwo-Hale reviewed, Teodor Vasquez-Lind merged"; echo "orla said: Orla Quenby fixed it, with Pim Vantongeren"
  echo "renovate[bot] and ViD stay"; echo "keep --password-file /p and the password is wrong"; echo "url $(pct "$EV")"; } > "$T/dev/run.log"
E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$PR/$E"
{ printf '{"type": "user", "cwd": "%s", "message": {"content":"set it to %s now; then %s; side %s"}}\n' "$T/side" "$EVJ" "$DV" "$WV"
  printf '{"type":"user","message":{"content":"first line\\nPersbd Namqln called"}}\n'; } > "$PR/$E/S-k.jsonl"
printf 'session id=S-k source=startup transcript=%s at=2026-11-07T10:00:00Z\n' "$PR/$E/S-k.jsonl" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-k --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-k
{ cat "$T/out"; find "$B" -type f ! -name '*.gz' -exec cat {} +; find "$B" -type f -name '*.gz' -exec sh -c 'gzip -dc "$1"' _ {} \; ; } > "$T/all"
for x in "$EV" "$EVJ" "$(pct "$EV")" "$DV" "$LV" "$UV" "$QV" "$CV" "$WV" "\$$DV2" "$UK" "Sup${t}Secret" "Sx${t}Prod9" 'Ilse Marrow-Venn' 'Orla Quenby' 'Pim Vantongeren' 'Sabine Okonkwo-Hale' 'Teodor Vasquez-Lind' 'Persbd Namqln' 'orla.q%40corp' 'orla.quenby' 'Quenby, Orla'; do
  if grep -qF -- "$x" "$T/all"; then fail "a known value is in the bundle or the output: $(printf '%s' "$x" | cut -c1-3)…"; fi
done
gzip -dc "$B/logs/run.log.gz" > "$T/log"
grep -qxF 'login admin [REDACTED:known-secret]' "$T/log" || fail "the dotenv value is not known-secret: $(head -n 1 "$T/log" | cut -c1-20)"
grep -qF '[REDACTED:person-name] fixed it, with [REDACTED:person-name]' "$T/log" || fail 'a committer or a co-author is not person-name'
grep -qxF 'renovate[bot] and ViD stay' "$T/log" || fail 'a bot or ViD changed'
grep -qxF 'keep --password-file /p and the password is wrong' "$T/log" || fail 'a placeholder of a dotenv template was used as a known value'
for f in logs/.env.local logs/id_rsa logs/x.pem; do
  grep -qF "$f" "$B/MANIFEST.md" || fail "$f is not listed as left out"; [ ! -e "$B/$f" ] && [ ! -e "$B/$f.gz" ] || fail "$f is in the bundle"
done
[ -f "$B/logs/notes.txt" ] || fail 'a plain file of the logs folder is missing'
# no secret value on disk under .vid/shares (the .known lists files by path, never a value)
for x in "$EV" "$DV" "$LV" "$UV" "$QV" "$CV"; do
  if grep -rqF -- "$x" .vid/shares; then fail "a secret value is written under .vid/shares ($(grep -rlF -- "$x" .vid/shares | head -n 1 | sed 's|.*/||'))"; fi
done
# a dotenv value put back by hand: the scan finds it (it reads the dotenv file again)
{ cat "$T/log"; echo "again $DV"; } | gzip > "$B/logs/run.log.gz"
if sh checks/share.sh scan "$B" > "$T/scan" 2>&1; then fail 'the scan passed a known secret put back'; fi
grep -q 'logs/run.log.gz.*known-secret' "$T/scan" || fail "the scan does not name known-secret: $(cat "$T/scan")"
# the run's and the project's names: a run name holding the user name is refused; a project folder named after a person is renamed
if sh checks/share.sh build --run "2026-11-orla-quenby" > "$T/o2" 2>&1; then fail 'a run name holding a person'"'"'s name was taken'; fi
grep -q 'run name holds a value redaction covers' "$T/o2" || fail "the refusal does not say why: $(cat "$T/o2")"
! ls -a .vid/shares | grep -qi quenby || fail 'the refused run name was written under .vid/shares'   # the line check
Q=$T/Orla-Quenby-site; mkdir -p "$Q/checks" "$Q/.vid"; cp "$CHECKS/share.sh" "$Q/checks/"; ( cd "$Q" && git init -q && git config user.name 'Orla Quenby' && printf 'run: active\n' > .vid/RUN-STATE.md
  sh checks/share.sh build > "$T/o3" 2>&1 ) || { cat "$T/o3" >&2; fail 'the build of a project named after a person failed'; }
ls "$Q/.vid/shares" | grep -qi orla && fail "the default run name holds the person's name: $(ls "$Q/.vid/shares" | head -n 1)"
grep -qx 'project	project' "$Q/.vid/shares/"*.summary || fail 'the project name was not replaced by project'
echo 'share-known-values: ok'
