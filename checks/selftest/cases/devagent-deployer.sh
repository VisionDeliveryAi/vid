#!/bin/sh
# Purpose: selftest case — DevAgent's deployer, DP, a role of its own (0.26.11.1.1, R2). `dm.sh start deployer` starts a fresh agent on
# devagent/agents/deployer.md with a builder's tools, labelled DP. The role file names each of develop's steps by file, heading and lead words,
# and each of those headings stands in its file with its lead words under it, so a later rename fails here; no paragraph of the two skills
# (a run of 12 words) is copied into devagent/; it holds the nine differences and the refused rollback's question. The dev manager routes every
# deploy okay and each recovery to the deployer when the record has host: or the okay's hosting has a `> platform:` line, unless the job note
# says `deploy: local`, and then deploys as before and writes a stand-in seam: line a listed row; it says "nowhere but this machine" of
# `deploy: local` alone and takes `seed: production` for a hosted staging. The test author saves the real answers in captures/ and builds
# on them; setup.md lists the record's new lines; the README says the deploys go to the chosen host; the example job note documents
# `deploy: local`. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$(cd "$CHECKS/.." && pwd -P); [ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "devagent-deployer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
DPM=$R/devagent/agents/deployer.md; DM=$R/devagent/agents/dev-manager.md; SS=$R/skills/vid-staging-setup/SKILL.md; DE=$R/skills/vid-deploy/SKILL.md
[ -f "$DPM" ] || fail 'no devagent/agents/deployer.md'
head -n 1 "$DPM" | grep -q '^# .*DevAgent.*(DP)' || fail "the role file's heading: $(head -n 1 "$DPM")"
j() { tr -s '[:space:]' ' ' < "$1"; }   # a file joined, its spaces squeezed
has() { j "$1" | grep -qF -- "$2" || fail "$3 lacks: $2"; }
# dm.sh start deployer: the role file, a builder's tools, DP
mkdir -p "$T/bin" "$T/work/c1"; PATH=$T/bin:$PATH; DM_WORK=$T/work; FC_LOG=$T/fc; export PATH DM_WORK FC_LOG; : > "$FC_LOG"
DMS=$R/devagent/dev-manager/dm.sh; FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DMS"); export FC_MODEL0
cat > "$T/bin/claude" <<'C'
#!/bin/sh
printf '%s\n' "$*" >> "$FC_LOG"
printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_MODEL0"
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"deployed"}\n'
C
chmod +x "$T/bin/claude"
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$T/work" > "$T/work/dm-note.txt"
printf 'ticket: 4\nthe okay\n' > "$T/work/job"
A=$(sh "$DMS" start deployer "$T/work/job" "$T/work/c1" 2> "$T/out") || fail 'dm.sh start deployer refused'
grep -qF 'devagent/agents/deployer.md' "$FC_LOG" && grep -qF -- '--allowedTools Bash Read Edit Write Grep Glob' "$FC_LOG" || fail "the deployer's start: $(cat "$FC_LOG")"
sh "$DMS" wait "$A" > /dev/null 2>&1 || fail 'wait on the deployer'; [ "$(cut -f1,2 "$T/work/agents.txt")" = "DP	4" ] || fail "agents.txt: $(cat "$T/work/agents.txt")"
# the pointers: file, heading, lead words; each in the role file, and in its file under that heading
pt() { f=$1; h=$2; shift 2; has "$DPM" "$h" 'the role file'; grep -qxF -- "$h" "$f" || fail "${f##*/} has no heading: $h"
  u=$(awk -v h="$h" '$0 == h { on = 1; next } on && /^## / { exit } on' "$f" | tr -s '[:space:]' ' ')
  for l in "$@"; do has "$DPM" "$l" 'the role file'; printf '%s' "$u" | grep -qF -- "$l" || fail "${f##*/}'s $h has no: $l"; done; }
has "$DPM" 'skills/vid-staging-setup/SKILL.md' 'the role file'; has "$DPM" 'skills/vid-deploy/SKILL.md' 'the role file'
pt "$SS" '## Part 2 — "Build the test site": from the block' '1. **The log-in.**' '2. **Both environments,**' '3. **Every outside service ARCHITECTURE.md names,**' '4. **The sending domain.**' '5. **DEPLOYMENT.md,**'
pt "$DE" '## Three failure classes, three gates' '**Gate 2 — STAGING (same platform, real providers).**' '**The deploy-owed rows.**' 'Infrastructure-only obligations'
pt "$DE" '## Staging anti-rot' 'Staging runs the same config-as-code as prod'
pt "$DE" '## Provider cutover — per provider, gradual' 'Each real-service adapter is'
pt "$DE" '## Every deploy after' '- **Production:**' 'back up prod' 'smoke' 'Rollback is chosen from the failure' '**application rollback keeping a compatible database**' '**restoration from the snapshot**'
pt "$DE" '## The credential boundary (hard law)' 'The OWNER authenticates; the AGENT operates.'
# no paragraph of SS or DE copied into devagent/: no run of 12 words of theirs in any devagent file
find "$R/devagent" -type f | LC_ALL=C sort | xargs cat | tr -s '[:space:]' ' ' > "$T/dev"; cat "$SS" "$DE" | tr -s '[:space:]' ' ' > "$T/src"
awk -v n=12 'FNR == 1 { f++ } { k = split($0, w, " "); for (i = 1; i + n - 1 <= k; i++) { s = w[i]; for (x = 1; x < n; x++) s = s " " w[i + x]; if (f == 1) D[s] = 1; else if (s in D) { print s; exit 1 } } }' "$T/dev" "$T/src" > "$T/out" || fail 'a devagent file copies a passage of the staging-setup or deploy skill'
# the nine differences, and the refused rollback
for l in '../../templates/DEPLOYMENT.md' 'never in the code repository' 'no event, gate or answer script' 'DECISIONS.md' '`decision: <what> | why: <why>` line' '"The stack and hosting"' 'BASELINE' \
  'a missing host tool' '`Question:` comment' 'blocked label' '`--product-change yes`' '`differs:` line, never a stop' 'asks no production yes' 'pushes no tag' '`captures/`' 'never committed' \
  '`host:`' '`duty:`' '`seam:`' 'as it stands when the deploy starts' 'deploy.sh deploy' '--seed production' '--lose-writes' 'nothing before it'; do has "$DPM" "$l" 'the role file'; done
# the dev manager's routing, and its local deploys
for l in 'sh dm.sh start deployer' '`host:`' '`> platform:`' '`deploy: local`' '`seam: <row> stand-in — a local copy`' '`seed: production`' '`outside-service rows:`' '`vid: recovered`'; do has "$DM" "$l" "the dev manager's file"; done
grep -n 'nowhere but this machine' "$DM" | grep -vF 'deploy: local' > "$T/out" && fail 'the dev manager says nowhere but this machine without deploy: local' || true
grep -q 'nowhere but this machine' "$DM" || fail "the dev manager no longer says what deploy: local deploys"
# the test author's two sentences; setup.md's record lines; the README; the example job note
has "$R/devagent/agents/test-author.md" "saves the real answer it gets on staging in the work folder's \`captures/\`" "the test author's file"
has "$R/devagent/agents/test-author.md" 'build on the saved answers' "the test author's file"
for k in host staging-address production-address host-login deploy production-logs duty seam kept; do grep -q "^$k: " "$R/devagent/test-manager/setup.md" || fail "setup.md does not list $k:"; done
! grep -q 'later release' "$R/devagent/README.md" || fail 'the README still says a later release'; has "$R/devagent/README.md" "the project's chosen host" 'the README'
# with deploy: local, a record holding host: is a stop, never a deploy; every listed row's seam: line replaced by the stand-in one
has "$DM" 'and a `host:` line in the dev setup record, deploy nothing' "the dev manager's file"
awk '/and a `host:` line in the dev setup record, deploy nothing/ { on = 1 } on { printf "%s ", $0 } on && /^1\. / { exit }' "$DM" | grep -qF 'then the blocked label' || fail "the dev manager's deploy: local stop does not add the blocked label"
has "$DM" 'replacing any earlier `seam:` line for that row' "the dev manager's file"
! grep -qF 'that has no `seam:` line yet' "$DM" || fail 'the dev manager keeps an earlier seam: line on a local copy'
grep -q '^# deploy: local' "$R/devagent/job-note.example" || fail 'the example job note does not document deploy: local'
echo 'devagent-deployer: ok'
