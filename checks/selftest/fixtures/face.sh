# Purpose: selftest fixture — ViD's face (0.26.10.29): a scratch ViD project for checks/face.sh. Sourced by a case
# after it has made and entered $T (Env: CHECKS, T). It copies the 0.9.4 known-good PRD (its Ratifications emptied, so
# no pause is recorded), makes .vid/, and writes one good lines file per sitting: lines.interview, lines.pause-1,
# lines.pause-2, lines.pause-3; 0.26.10.29.6 (S2): every quality, finding and rewording in them with a recommendation. fc_run <args…>: runs face.sh (no pages.sh beside it), its output in OUT, its exit in RC, the session sess-A.
# fc_json <python expression over d>: prints it, d the sitting (python3; a case without it exits 77).
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
git init -q . && git config user.email t@example.com && git config user.name t
awk '/^## Ratifications/ { print; print ""; skip = 1; next } skip && /^## / { skip = 0 } !skip' "$CHECKS/selftest/fixtures/prd-094-good.md" > PRD.md
mkdir -p .vid
cat > lines.interview <<'L'
section questions
item Q1 | Who is the digest for?
recommend | Job seekers
choice | Job seekers
choice | Recruiters
item Q2 | How often does it go out?
choice | Daily
choice | Weekly
section challenge
item C1 | Synonym-aware search
detail | Keeping it costs a word list to maintain
recommend | Cut
L
cat > lines.pause-1 <<'L'
section thesis
item T1 | Product summary
detail | A daily digest of new jobs for each saved search.
section contract
item DIM-mech-digest | One digest per saved search per day
recommend | Needs it
item DIM-nfr-privacy | A subscriber's address stays inside the product
recommend | Needs it
section findings
item F-01 | The unsubscribe has no time bound
recommend | Fix it: within one day
L
cat > lines.pause-2 <<'L'
section gaps
item G1 | Who may see the digest archive?
recommend | Only the subscriber
choice | Only the subscriber
choice | Any operator
judged product-level | product-level=9 (agree)
L
cat > lines.pause-3 <<'L'
section rewordings
item F-07 | Every digest carries a working unsubscribe, stopping all digests within one day
recommend | Accept
empty findings | none left
plain-changed REQ-002
L
# usability (P9): fc_run runs face.sh from a folder of links to every entry of checks/ but pages.sh, so a write or an
# end makes no pages; face-pages-index tests them with a pages script of its own
FC=$PWD/.face-checks; mkdir -p "$FC"
for f in "$CHECKS"/*; do [ "$(basename "$f")" = pages.sh ] || ln -s "$f" "$FC/"; done
fc_run() { set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh "$FC/face.sh" "$@" 2>&1); RC=$?; set -e; }
fc_json() { python3 -c "import json,sys; d=json.load(open('.vid/face/sitting.json')); print($1)"; }
fc_stand() { python3 -c "import json,sys; d=json.load(open('.vid/face/standing.json')); print($1)"; }
