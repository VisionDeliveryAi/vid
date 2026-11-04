#!/bin/sh
# Purpose: selftest fixture — the ticket writer's toy (v0.26.10.12.3). Sourced by the
# tw-* cases and plan-admit-tickets. `tw_toy <dir>` builds on stage 1's planner toy (planner-toy.sh: JobDigest, five
# modules, RUN-STATE in a plan session with its plan block recorded: S01 the skeleton of stage 0, S02–S04 stage 1, S05
# stage 2) and enters it, a git repository: a stand-in BASELINE.md (its ## Stack), ARCHITECTURE.md's vid-hosting
# block, a DECISIONS.md of four lines, all committed; the plan reviewed (none), paged and ratified in the words "Yes,
# publish it", with its publish-approved event; TW's settings (.vid/tw/settings: repo owner/code, spec-repo
# owner/code-spec, an empty labels-prefix:, open-tickets 2); the code repository, a local bare one at $T/code.git with
# one commit on main; the fake gh (tickets.sh's gh_fake) serving it. Helpers: `tw_hand <line>` adds a handed line,
# labelled a stand-in; `tw_ratify <words>` reviews, pages and ratifies the plan again with its publish-approved event;
# `tw_start <step>` admits a step (plan.sh start); `tw_close <n>` closes issue n in the fake gh; `tw_post <write
# args…>` writes a ticket and posts it, `amend <n>` in place (its file in $TW_F, its number in $TW_N); `tw_skel`, the
# skeleton's round (below). Reads only files under checks/. Env: CHECKS, T.
. "$CHECKS/selftest/fixtures/planner-toy.sh"
. "$CHECKS/selftest/fixtures/tickets.sh"
tw_toy() {
  pt_toy "$1"; git init -q
  printf '# JobDigest — BASELINE (a stand-in for the self-test)\n\n## Stack\n\n| Layer | Choice | FORBIDDEN alternatives (named) |\n|---|---|---|\n| web | one small web framework, server-rendered pages | a single-page app |\n| data | one relational database | a document store |\n\n## Other\n\nnothing\n' > BASELINE.md
  printf '\n```vid-hosting\nplatform: one small hosting platform\nstaging: the platform'"'"'s own address\nproduction: the platform'"'"'s own address\n```\n' >> ARCHITECTURE.md
  printf '# JobDigest — DECISIONS\n\n- **D-001** the mail provider is the one the owner named | why: one provider | enforced: convention\n- **D-002** REQ-002 unsubscribes in one click | why: the law | enforced: convention\n- **D-003** S01 shows the saved state in one line | why: short | enforced: convention\n- **D-004** RULE-001 footers name the support address in plain words | why: trust | enforced: convention\n' > DECISIONS.md
  printf '.vid/\n' > .gitignore
  g add -A && g commit -qm 'the toy'
  mkdir -p .vid/tw; printf 'repo: owner/code\nspec-repo: owner/code-spec\nlabels-prefix:\nopen-tickets: 2\n' > .vid/tw/settings
  tw_ratify 'Yes, publish it'
  git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
  git clone -q "$T/code.git" "$T/dev" 2>/dev/null; ( cd "$T/dev" && git checkout -q -b main 2>/dev/null; g commit -q --allow-empty -m 'Initial commit' && git push -q origin main 2>/dev/null )
  gh_fake
}
tw_ratify() { printf 'none\n' > "$T/none"; sh "$CHECKS/planner.sh" review --in "$T/none" > /dev/null && sh "$CHECKS/planner.sh" page > /dev/null 2>&1 && sh "$CHECKS/planner.sh" ratify --words "$1" > /dev/null || return 1
  printf 'publish-approved words="%s" at=%s\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
tw_hand() { mkdir -p .vid/tw; printf '%s | stand-in: the self-test\n' "$1" >> .vid/tw/handed; }
tw_start() { sh "$CHECKS/plan.sh" start "$1" > "$T/start" 2>&1; }
tw_close() { echo CLOSED > "$T/gh/issues/$1/state"; }
tw_post() { TW_F=$(sh "$CHECKS/writer.sh" write "$@" 2> "$T/werr") || return 1; _a=''; [ "$1" != amend ] || _a="--amend $2"
  sh "$CHECKS/github.sh" tw-post $_a "$TW_F" > "$T/post" 2>&1 || return 1; TW_N=$(sed -n 's/^ViD github: [a-z]* ticket #\([0-9]*\).*/\1/p' "$T/post"); }
# tw_skel: the skeleton round done — spec-setup, tw-sync, S01 admitted, its ticket written and posted (#1), then the
# stand-in's records (two engines, S01's rows accepted, S01 closed, stage 0's candidate) and #1 closed, synced
tw_skel() { sh "$CHECKS/github.sh" spec-setup > "$T/sk" 2>&1 && sh "$CHECKS/github.sh" tw-sync >> "$T/sk" 2>&1 && tw_start S01 && tw_post skeleton || return 1
  tw_hand 'engines chromium firefox'; tw_hand 'row ROW-003 accepted'; tw_hand 'row ROW-004 accepted'; tw_hand 'closed S01'; tw_hand 'candidate 0'
  tw_close "$TW_N"; sh "$CHECKS/github.sh" tw-sync >> "$T/sk" 2>&1; }
