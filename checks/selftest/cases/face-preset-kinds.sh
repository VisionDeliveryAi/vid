#!/bin/sh
# Purpose: selftest case — usability (P1): every item starts at ViD's recommendation. checks/face.sh writes each
# item's preset, the answer it starts at, and who set it. Convicts unless: a question with a recommendation starts at
# choose:<it>, by ViD; a list or findings item whose recommendation starts with one of the section's buttons (any
# case, then the end, or a colon, a full stop, a comma, a semicolon or a dash (hyphen, en or em), spaces before it allowed; a space then a word is no match) starts at that act, its words after the colon where the act takes words, by ViD;
# an item ViD gave nothing, in a section with a standing act (the features, the qualities, the plain sentences),
# starts at that act, by the standing act; an item with no recommendation elsewhere, one whose words only begin like
# a button ("Cutting …"), one with `recommend | none`, one marked `alone`, and every decision start with no preset;
# and `recommend | none` is said in the item and adds no choice. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-preset-kinds: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
pre() { fc_json "[(i['preset'] + ' ' + i['presetBy']).strip() for x in d['sections'] if x['id']=='$1' for i in x['items'] if i['id']=='$2'][0]"; }
cat > L.interview <<'L'
section questions
item Q1 | Who is the digest for?
recommend | Job seekers
choice | Job seekers
choice | Recruiters
item Q2 | How often does it go out?
choice | Daily
choice | Weekly
item Q3 | Which feeds first?
recommend | none
choice | The two largest
choice | All of them
section challenge
item C1 | Synonym-aware search
recommend | Cut
item C2 | Saved filters
recommend | Cutting it saves a week
item C3 | The archive
recommend | keep
item C4 | Saved alerts
recommend | Cut.
item C5 | Email preview
recommend | Keep, it is cheap
item C6 | Shared searches
recommend | Cut — it costs a week
item C7 | The export
recommend | Keep nothing of it; cut the whole export
item C8 | The import
recommend | Keep; it is used
item C9 | The feed list
recommend | Keep – it is used
L
fc_run write interview L.interview; [ "$RC" = 0 ] || fail "the interview was refused: $OUT"
[ "$(pre questions Q1)" = 'choose:Job seekers vid' ] || fail "Q1 starts at '$(pre questions Q1)', not choose:Job seekers by ViD"
[ "$(pre questions Q2)" = '' ] || fail "Q2, with no recommendation, starts at '$(pre questions Q2)'"
[ "$(pre questions Q3)" = '' ] || fail "Q3, recommend none, starts at '$(pre questions Q3)'"
[ "$(fc_json "[i['norecommend'] for x in d['sections'] for i in x['items'] if i['id']=='Q3'][0]")" = True ] || fail 'recommend none is not said in the item'
[ "$(fc_json "[i['choices'] for x in d['sections'] for i in x['items'] if i['id']=='Q3'][0]")" = "['The two largest', 'All of them']" ] || fail 'recommend none added a choice'
[ "$(fc_json "[i['norecommend'] for x in d['sections'] for i in x['items'] if i['id']=='Q1'][0]")" = False ] || fail 'Q1 is said to have no recommendation'
[ "$(pre challenge C1)" = 'cut vid' ] || fail "C1 (recommend Cut) starts at '$(pre challenge C1)'"
[ "$(pre challenge C2)" = '' ] || fail "C2 ('Cutting it …') starts at '$(pre challenge C2)': a word that only begins like a button"
[ "$(pre challenge C3)" = 'keep vid' ] || fail "C3 (recommend keep, lower case) starts at '$(pre challenge C3)'"
[ "$(pre challenge C4)" = 'cut vid' ] || fail "C4 ('Cut.') starts at '$(pre challenge C4)'"
[ "$(pre challenge C5)" = 'keep vid' ] || fail "C5 ('Keep, it is cheap') starts at '$(pre challenge C5)'"
[ "$(pre challenge C6)" = 'cut vid' ] || fail "C6 ('Cut — it costs a week') starts at '$(pre challenge C6)'"
[ "$(pre challenge C7)" = '' ] || fail "C7 ('Keep nothing of it; …': a space, then a word) starts at '$(pre challenge C7)'"
[ "$(pre challenge C8)" = 'keep vid' ] || fail "C8 ('Keep; it is used') starts at '$(pre challenge C8)'"
[ "$(pre challenge C9)" = 'keep vid' ] || fail "C9 ('Keep – it is used', an en dash) starts at '$(pre challenge C9)'"
cat > L.pause-1 <<'L'
section thesis
item T1 | Product summary
detail | A daily digest of new jobs for each saved search.
section contract
item DIM-mech-digest | One digest per saved search per day
item DIM-nfr-privacy | A subscriber's address stays inside the product
recommend | Doesn't need it
item DIM-nfr-speed | Pages answer within a second
recommend | none
item DIM-nfr-audit | Every change is logged
recommend | Needs it: the owner asked for it
section findings
item F-01 | The unsubscribe has no time bound
recommend | Fix it: within one day
item F-02 | The archive is open to operators
recommend | leave it: operators need it for support
item F-03 | The digest hour is fixed
recommend | none
item F-04 | The failure clause on delivery is looser than written
recommend | Fix it
alone
L
fc_run write pause-1 L.pause-1; [ "$RC" = 0 ] || fail "pause-1 was refused: $OUT"
[ "$(pre contract DIM-mech-digest)" = 'in standing' ] || fail "a quality ViD gave nothing starts at '$(pre contract DIM-mech-digest)', not Needs it by the standing act"
[ "$(pre contract DIM-nfr-privacy)" = 'out vid' ] || fail "a quality recommended Doesn't need it starts at '$(pre contract DIM-nfr-privacy)'"
[ "$(pre contract DIM-nfr-speed)" = '' ] || fail "a quality with recommend none starts at '$(pre contract DIM-nfr-speed)'"
[ "$(pre contract DIM-nfr-audit)" = 'in vid' ] || fail "a quality recommended 'Needs it: …' starts at '$(pre contract DIM-nfr-audit)' (Needs it takes no words)"
[ "$(pre findings F-01)" = 'fix vid' ] || fail "F-01 (Fix it: within one day) starts at '$(pre findings F-01)'"
[ "$(pre findings F-02)" = 'overrule:operators need it for support vid' ] || fail "F-02 (leave it: words) starts at '$(pre findings F-02)', not Leave it with its words"
[ "$(pre findings F-03)" = '' ] || fail "a finding with no recommendation starts at '$(pre findings F-03)'"
[ "$(pre findings F-04)" = '' ] || fail "a finding marked alone starts at '$(pre findings F-04)'"
[ "$(fc_json "[i['alone'] for x in d['sections'] for i in x['items'] if i['id']=='F-04'][0]")" = True ] || fail 'the finding marked alone does not say so'
[ "$(fc_json "[i['alone'] for x in d['sections'] for i in x['items'] if i['id']=='F-01'][0]")" = False ] || fail 'a finding not marked alone says it is'
n=$(fc_json "len([i for x in d['sections'] if x['id']=='features' for i in x['items']])"); [ "$n" -ge 1 ] || fail 'the fixture prints no feature'
[ "$(fc_json "set((i['preset'], i['presetBy']) for x in d['sections'] if x['id']=='features' for i in x['items'])")" = "{('ok', 'standing')}" ] || fail "the features do not all start at Fine by the standing act: $(fc_json "[i['preset'] for x in d['sections'] if x['id']=='features' for i in x['items']]")"
[ "$(fc_json "[i['preset'] for x in d['sections'] if x['id']=='thesis' for i in x['items']]")" = "['']" ] || fail 'a text item has a preset'
# a decision nobody changes stands: no preset (one made visible, as face-r1-complete does)
sed 's/^\(A-005 | model_proposed | .*\) | shown: pause-1 [0-9]*$/\1/' PRD.md > X && mv X PRD.md
fc_run write pause-1 L.pause-1; [ "$RC" = 0 ] || fail "pause-1 with a decision was refused: $OUT"
[ "$(fc_json "len([i for x in d['sections'] if x['kind']=='decided' for i in x['items']])")" -ge 1 ] || fail 'the decision mutation gave no decision'
[ "$(fc_json "set(i['preset'] for x in d['sections'] if x['kind']=='decided' for i in x['items'])")" = "{''}" ] || fail 'a decision has a preset'
# pause 2: the plain sentences start at Agree, a gap with a recommendation at it, the figures at nothing
fc_run write pause-2 lines.pause-2; [ "$RC" = 0 ] || fail "pause-2 was refused: $OUT"
[ "$(pre gaps G1)" = 'choose:Only the subscriber vid' ] || fail "G1 starts at '$(pre gaps G1)'"
[ "$(fc_json "set((i['preset'], i['presetBy']) for x in d['sections'] if x['id']=='plain' for i in x['items'])")" = "{('ok', 'standing')}" ] || fail 'the plain sentences do not all start at Agree by the standing act'
[ "$(fc_json "set(i['preset'] for x in d['sections'] if x['kind']=='figures' for i in x['items'])")" = "{''}" ] || fail 'a figure has a preset'
# pause 3: a rewording starts at ViD's recommendation (0.26.10.29.6, S2: every rewording carries one); the changed plain sentences at Agree
fc_run write pause-3 lines.pause-3; [ "$RC" = 0 ] || fail "pause-3 was refused: $OUT"
[ "$(pre rewordings F-07)" = 'accept vid' ] || fail "a rewording recommended Accept starts at '$(pre rewordings F-07)'"
[ "$(pre plain REQ-002)" = 'ok standing' ] || fail "a changed plain sentence starts at '$(pre plain REQ-002)'"
# a button that takes words, named then a space and a word: no preset
grep -v '^empty findings' lines.pause-3 > L3; printf 'section findings\nitem F-08 | The archive has no bound\nrecommend | Answer it in the PRD\n' >> L3
fc_run write pause-3 L3; [ "$RC" = 0 ] || fail "pause-3 with a finding was refused: $OUT"
[ "$(pre findings F-08)" = '' ] || fail "F-08 ('Answer it in the PRD') starts at '$(pre findings F-08)'"
# `alone` sits under an item, and only in a section that takes an answer
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): the pause-3 sitting on disk would make pause 1 a passed stop
printf 'section thesis\nitem T1 | Summary\nalone\n' > B; grep -vE '^section thesis|^item T1|^detail' L.pause-1 >> B
fc_run write pause-1 B; [ "$RC" != 0 ] || fail 'alone on a text item was taken'
exit 0
