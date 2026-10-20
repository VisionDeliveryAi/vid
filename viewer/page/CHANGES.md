# The page's changes

`viewer/page/` is the owner's design from the release's design pack (kept in the
repository's docs/, not shipped; Claude Design), used as the page's code: since
v0.26.10.6 its `VID Viewer v4.dc.html` (2026-10-20), which is v3 (2026-10-19)
with the Execution and Economics sections added; v3 was v2 (2026-10-13) with
the Architecture section added. The build changes it only in three
kinds (spec §3.10): **1** one offline file, **2** reading the real data, **3**
copy true of ViD and of the data; and, from v0.26.10.8 (its R12, the owner's
decision 5), **4** a panel added in the page's own look — its markup copied
from a panel already there, its reader and its place in the view, with no new
navigation. Layout, look and navigation never change otherwise.
Every change is one entry below: its kind, where it is and why. The changes
of kinds 2 and 3 are made in `viewer/page/ViD Viewer v4.dc.html`; each carries
the design's text and the page's, and the case `view-page-diff` applies them,
in order, to the design and requires the page byte for byte — any difference
this file does not list fails it. C-01 to C-58 were written for v2 and apply
to v3 as they are, each old text found once (v0.26.10.2 §12); C-59 to C-62
are v3's own; C-01 to C-62 apply to v4 as they are (v0.26.10.6 §11); C-63
onward are v4's own. `NOTE.md` is v4's pack's; `screenshots/exec-*` and
`econ-*` are v4's pack's, beside v3's `arch-module-*` and v2's;
`support.js` is v2's pack's, since neither v3's nor v4's pack returned one
(their notes: unchanged). All are unchanged.

## Kind 1 — one offline file (made when each snapshot is assembled, `viewer/view.sh`)

- **K1-1 · the page's runtime line** (`<script src="./support.js"></script>`
  in `<head>`) is replaced, in each snapshot, by inline scripts in this
  order: `window.__resources={};` (the runtime then never re-reads its own
  page, `support.js:158-163`); the vendored UI library's two files
  (`viewer/vendor/`, so the runtime never fetches them, `support.js:1838-1846`);
  `window.VID_DATA=<the snapshot's data>`; `window.VID_CANVASES=<its
  canvases, each once>`; the runtime itself. *(v0.9.8.1 R23)* The canvases
  themselves are local script assets, `canvases/<key>.js` beside the
  snapshots, each written once and loaded by `<script src>` just before
  that line, which maps each canvas name to its asset.
- **K1-2 · the data and canvas lines** (`<script src="./viewer-data.js"></script><script
  src="./canvases.js"></script>` in `<helmet>`) are removed: their content
  is inline above.
- **K1-3 · each canvas** in `window.VID_CANVASES` is the project's canvas
  file at the moment's commit with each relative script and stylesheet it
  names that the pack holds inlined, the same library and `window.__resources={};`
  before its first script, so a canvas opens offline too.

No in-browser compiler is loaded: the runtime loads one only for `.jsx`
imports, and the page has none.

## Kind 2 — reading the real data

### C-01 · kind 2 · the script: `ORDER`

The reader emits a `later` state (every REQ a row proves is phase: later); it joins the state tables, summaries and filters.

~~~old
const ORDER=['pass','red','stale','never','owed','deploy-owed','held'];
~~~
~~~new
const ORDER=['pass','red','stale','never','owed','deploy-owed','held','later'];
~~~

### C-02 · kind 2 · the script: `ST`, its last entry

`later` gets its label, "Later phase"; and a change log's `new` and `removed` (a criterion that appears or goes between two snapshots) get theirs, so a transition never prints a raw key.

~~~old
held:{l:'Held for you',c:'var(--c-held)',h:'Waiting on the product owner.'}};
~~~
~~~new
held:{l:'Held for you',c:'var(--c-held)',h:'Waiting on the product owner.'},later:{l:'Later phase',c:'var(--line2)',h:'Every requirement it proves is for a later phase, so it is not tested yet.'},new:{l:'Not yet a criterion',c:'var(--line2)',h:''},removed:{l:'No longer a criterion',c:'var(--line2)',h:''}};
~~~

### C-03 · kind 2 · the script: `SHORT`

The `later` state's short legend.

~~~old
held:'waiting on your decision'};
~~~
~~~new
held:'waiting on your decision',later:'for a later phase'};
~~~

### C-04 · kind 2 · the script: a method `mode()`, after `applyTheme`

The page reads `meta.mode` first (index or snapshot), with the design's setting as the fallback; `ownFile()` finds this snapshot's own file in `meta.snapshots` (its moment), the key to its change window.

~~~old
  ensure(){const ds=this.props.dataset??'full';
~~~
~~~new
  mode(){const m=window.VID_DATA&&window.VID_DATA.meta;return (m&&m.mode)||this.props.mode;}
  ownFile(){const m=this.ix.D.meta,sn=m.snapshots||[];const x=sn.find(y=>y.moment.commit===m.moment.commit&&y.moment.time===m.moment.time);return x?x.file:'';}
  ensure(){const ds=this.props.dataset??'full';
~~~

### C-05 · kind 2 · the script: `onHash`, the default route

The index opens on Snapshots by `meta.mode`.

~~~old
if(!h)h=(this.props.mode==='index')?'snapshots':'product';
~~~
~~~new
if(!h)h=(this.mode()==='index')?'snapshots':'product';
~~~

### C-06 · kind 2 · the script: `componentDidMount`, when the data is ready

The change log's default range is the file's own window — its previous moment to itself — or, in the index, the whole span.

~~~old
this._poll=setInterval(()=>{if(window.VID_DATA){clearInterval(this._poll);this.onHash();this.setState({ready:true});}},40);
~~~
~~~new
this._poll=setInterval(()=>{if(window.VID_DATA){clearInterval(this._poll);this.onHash();const ms=this.moments();this.setState({ready:true,chFrom:0,chTo:Math.max(1,ms.length-1)});}},40);
~~~

### C-07 · kind 2 · the script: the search index, a PRD answer's group

An answer is named by its tier (kind 3 below names the labels): an owner's ruling and a ViD decision are told apart.

~~~old
D.decisions.answers.forEach(a=>add(a.id,'Owner rulings',a.a));
~~~
~~~new
D.decisions.answers.forEach(a=>add(a.id,this.tierName(a)+'s',a.a));
~~~

### C-08 · kind 2 · the script: a method `tierName(a)`, before `stepState`

An answer's label from its tier: `human` an owner ruling, `model_proposed` a ViD decision (prd.sh's own reading), any other tier named as it is.

~~~old
  stepState(s){return s.closed?'closed':s.started?'underway':'not started';}
~~~
~~~new
  tierName(a){return a.tier==='human'?'Owner ruling':a.tier==='model_proposed'?'ViD decision':'Ruling ('+a.tier+')';}
  stepState(s){return s.closed?'closed':s.started?'underway':'not started';}
~~~

### C-09 · kind 2 · the script: `stepPass`

Built, tested and reviewed are counted each on its own, never one among another (§3.7.5): passing is not counted only among built rows, nor confirmed only among passing ones.

~~~old
const b=ps.filter(p=>p.built),t=b.filter(p=>p.state==='pass'),c=t.filter(p=>{
~~~
~~~new
const b=ps.filter(p=>p.built),t=ps.filter(p=>p.state==='pass'),c=ps.filter(p=>{
~~~

### C-10 · kind 2 · the script: the moments, `moments()`

Every window, not one: a snapshot's moment list is its previous moment and itself, the index lists every snapshot from `meta.snapshots`, each with its file; the design's own reading stays the fallback for data without `meta.snapshots`.

~~~old
  moments(){const m=this.ix.D.meta;const a=[];
~~~
~~~new
  moments(){const m=this.ix.D.meta,sn=m.snapshots||[];if(sn.length){const own=this.ownFile();const lab=x=>({label:x.label+' · '+fmtT(x.moment.time,true),time:x.moment.time,commit:x.moment.commit,name:x.label,file:x.file,requested:!!x.requested});let b;if(this.mode()==='index')b=sn.map(lab);else{const i=sn.findIndex(x=>x.file===own);b=(i>0?[sn[i-1],sn[i]]:i===0?[sn[0]]:[]).map(lab);}return b.map((x,i)=>({...x,i:String(i)}));}const a=[];
~~~

### C-11 · kind 2 · the script: `changesV`, the range

The range filters by each change's `window`: the changes of the snapshots after "from" up to "to".

~~~old
const win=to<ms.length&&from<to;
    const tx=st.chText.trim().toLowerCase(),cap=st.chCap;
    const base=win?ix.D.changes.filter(c=>(!cap||
~~~
~~~new
const win=to<ms.length&&from<to;const wins=new Set(ms.slice(from+1,to+1).map(x=>x.file));const inWin=ix.D.changes.filter(c=>!c.window||wins.has(c.window));
    const tx=st.chText.trim().toLowerCase(),cap=st.chCap;
    const base=win?inWin.filter(c=>(!cap||
~~~

### C-12 · kind 2 · the script: `changesV`, the window sentence

"Narrowed from" counts the chosen window's changes, not every window's.

~~~old
(filtered?', narrowed from '+N(ix.D.changes.length):'')
~~~
~~~new
(filtered?', narrowed from '+N(inWin.length):'')
~~~

### C-13 · kind 2 · the script: the header, `momentTag` and the neighbours

The tag reads `meta.mode`; previous and next open `meta.previous.file` and `meta.next.file` (their links below); kind 3: "Live" becomes "Latest" — the latest file is a snapshot made at one moment, not live.

~~~old
momentTag:(this.props.mode==='index')?'Index':replayed?'Replayed':'Live',
~~~
~~~new
momentTag:(this.mode()==='index')?'Index':replayed?'Replayed':'Latest',prevHref:m.previous&&m.previous.file?m.previous.file:'#snapshots',nextHref:m.next&&m.next.file?m.next.file:'#snapshots',
~~~

### C-14 · kind 2 · the template: the header's previous link

Previous opens its own file.

~~~old
<a href="#snapshots" aria-label="{{ prevAria }}"
~~~
~~~new
<a href="{{ prevHref }}" aria-label="{{ prevAria }}"
~~~

### C-15 · kind 2 · the template: the header's next link

Next opens its own file.

~~~old
<sc-if value="{{ hasNext }}" hint-placeholder-val="{{ false }}"><a href="#snapshots" style=
~~~
~~~new
<sc-if value="{{ hasNext }}" hint-placeholder-val="{{ false }}"><a href="{{ nextHref }}" style=
~~~

### C-16 · kind 2 · the script: the footer

The footer shows the records version, `meta.records` ("not recorded" when the project has none).

~~~old
footVid:'VID '+m.vid,
~~~
~~~new
footVid:'ViD '+m.vid+' · records '+(m.records==null?'not recorded':m.records),
~~~

### C-17 · kind 2 · the script: the product overview, the "since" line

The "since" line counts the file's own window (the index's is now's).

~~~old
const ch=D.changes.length,ny=D.needsYou;
~~~
~~~new
const own=this.ownFile(),ch=D.changes.filter(c=>!c.window||c.window===own).length,ny=D.needsYou;
~~~

### C-18 · kind 2 · the script: the goals' summary line

Counts, never percentages: a goal's passing criteria as a count of its criteria. The bar stays.

~~~old
(gs.total?Math.round(gs.pass/gs.total*100)+'% passing':'no criteria yet')
~~~
~~~new
(gs.total?N(gs.pass)+' of '+N(gs.total)+' passing':'no criteria yet')
~~~

### C-19 · kind 2 · the script: the capabilities' passing column

Counts, never percentages: a capability's passing criteria as a count. The bar stays.

~~~old
pass:cs.total?Math.round(cs.pass/cs.total*100)+'%':'—'
~~~
~~~new
pass:cs.total?N(cs.pass)+' of '+N(cs.total):'—'
~~~

### C-20 · kind 2 · the script: the promise's test result

The result file and commit come from the promise's `resultFile` and `resultCommit` (the data side reads the reader's detail in each form it prints), never from parsing the detail text here.

~~~old
let mm;if((mm=det.match(/passed at (\w+) \(([^)]+)\)/))){rows.push({k:'Ran on commit',v:mm[1],font:MONO});rows.push({k:'Result file',v:mm[2],font:MONO});}
      else if((mm=det.match(/last (?:current )?run:? ([^)]+)\)/))){const f=mm[1].trim();rows.push({k:'Last result file',v:f,font:MONO});const cm=f.match(/^([0-9a-f]{7,})\./);if(cm)rows.push({k:'Ran on commit',v:cm[1],font:MONO});}
~~~
~~~new
if(p.resultFile){if(p.state==='pass'){if(p.resultCommit)rows.push({k:'Ran on commit',v:p.resultCommit,font:MONO});rows.push({k:'Result file',v:p.resultFile,font:MONO});}
      else{rows.push({k:'Last result file',v:p.resultFile,font:MONO});if(p.resultCommit)rows.push({k:'Ran on commit',v:p.resultCommit,font:MONO});}}
~~~

### C-21 · kind 2 · the script: the promise's built line

A project whose records predate hand-back records says "not recorded" (R11).

~~~old
builtText:p.built?'Built: a builder handed back work that passed it':'Not built yet',
~~~
~~~new
builtText:(D.meta.notRecorded||[]).includes('built')?'Built: not recorded (this project\'s records predate hand-back records)':p.built?'Built: a builder handed back work that passed it':'No builder\'s hand-back passing it is recorded',
~~~

### C-22 · kind 2 · the script: a judgment's prose

A past snapshot says the prose is shown in the latest snapshot only (§3.4); the latest says when none was recorded.

~~~old
prose:j.prose||'The reviewer\'s notes are not included in this snapshot.'
~~~
~~~new
prose:j.prose||(D.meta.nowOnly?'The reviewer\'s notes are shown in the latest snapshot only.':'No notes were recorded for this judgment.')
~~~

### C-23 · kind 2 · the script: a ruling's heading, delegated

Delegated comes only from the `delegated` field; the fallback on the wording "Delegated by the owner" is removed. Kind 3: the answer is named by its tier.

~~~old
kicker:isA?('Owner ruling '+a.id+' · '+fmtT(a.date)+(a.delegated||/^Delegated by the owner/i.test(a.a||'')?
~~~
~~~new
kicker:isA?(this.tierName(a)+' '+a.id+' · '+fmtT(a.date)+(a.delegated?
~~~

### C-24 · kind 2 · the script: the delivery counts

Built, tested and reviewed are three counts, never merged (§3.7.5): passing and confirmed are counted over every criterion. Counts, never percentages: each stage is shown as a count of all.

~~~old
const fB=ps.filter(p=>p.built),fT=fB.filter(p=>p.state==='pass'),fC=fT.filter(isK);
~~~
~~~new
const fB=ps.filter(p=>p.built),fT=ps.filter(p=>p.state==='pass'),fC=ps.filter(isK);
~~~

### C-25 · kind 2 · the script: the delivery counts' labels

Counts, never percentages.

~~~old
ofT=x=>(ps.length?Math.round(x/ps.length*100):0)+'% of all';
~~~
~~~new
ofT=x=>'of '+N(ps.length);
~~~

### C-26 · kind 2 · the script: agents now

A past snapshot says agents are shown in the latest snapshot only (§3.4).

~~~old
agentsCount:String(D.activity.agentsOpen.length),
~~~
~~~new
agentsCount:String(D.activity.agentsOpen.length),agentsNone:D.meta.nowOnly?'Agents are shown in the latest snapshot only.':'No agent is working at this moment.',
~~~

### C-27 · kind 2 · the template: agents now, its empty line

The empty line comes from the data (above).

~~~old
color:var(--ink2)">No agent is working at this moment.</p>
~~~
~~~new
color:var(--ink2)">{{ dl.agentsNone }}</p>
~~~

### C-28 · kind 2 · the script: recent activity

A past snapshot says recent activity is shown in the latest snapshot only (§3.4).

~~~old
noActs:!fl.length,
~~~
~~~new
noActs:!fl.length,actNone:D.meta.nowOnly?'Recent activity is shown in the latest snapshot only.':'Nothing recorded.',
~~~

### C-29 · kind 2 · the template: recent activity, its empty line

The empty line comes from the data (above).

~~~old
<sc-if value="{{ dl.noActs }}"><p style="margin:0;padding:12px 14px;color:var(--ink2)">Nothing recorded.</p></sc-if>
~~~
~~~new
<sc-if value="{{ dl.noActs }}"><p style="margin:0;padding:12px 14px;color:var(--ink2)">{{ dl.actNone }}</p></sc-if>
~~~

### C-30 · kind 2 · the script: delegated rulings

A project whose records predate the delegated mark says "not recorded" instead of nothing (R11).

~~~old
dgNone:!dgGroups.length};}
~~~
~~~new
dgNone:!dgGroups.length,dgNoneText:(D.meta.notRecorded||[]).includes('delegated')?'Not recorded: this project\'s records predate the delegated mark.':'No rulings match.'};}
~~~

### C-31 · kind 2 · the template: delegated rulings, its empty line

The empty line comes from the data (above).

~~~old
font-size:13px;color:var(--ink2)">No rulings match.</p>
~~~
~~~new
font-size:13px;color:var(--ink2)">{{ dl.dgNoneText }}</p>
~~~

### C-32 · kind 2 · the script: delegated rulings, their section

Under R11 the section shows with its "not recorded" line even with no marks.

~~~old
hasDelegated:ny.delegated.length>0,
~~~
~~~new
hasDelegated:ny.delegated.length>0||(D.meta.notRecorded||[]).includes('delegated'),
~~~

### C-33 · kind 2 · the script: the Snapshots list

Every window: each row shows its own window's count, links to its file and marks a requested snapshot; "here" comes from `meta.moment`. Kind 3: the intro no longer speaks of a sample.

~~~old
v.sn={intro:'Every snapshot in this folder, oldest first. Each is a single file that opens offline. This sample carries '+PL(ms.length,'moment')+'; the full folder lists every one.',
        rows:ms.map((x,i)=>{const here=i===ms.length-1&&!replayed;return {label:x.name,time:fmtT(x.time),commit:x.commit,changes:i===0?(ms.length>1?'earlier changes are in its own file':'first snapshot'):PL(D.changes.length,'change')+' since the one before',
          here,away:!here,openText:'Open this snapshot',dot:here?'var(--ink)':'transparent',bg:here?'var(--sunk)':'transparent'};})};}
~~~
~~~new
const own=this.ownFile(),idx=this.mode()==='index';
      v.sn={intro:idx?'Every snapshot in this folder, oldest first. Each is a single file that opens offline.':'This snapshot and the one before it. The folder\'s index lists every snapshot, each a single file that opens offline.',
        rows:ms.map((x,i)=>{const here=!idx&&(x.file?x.file===own:i===ms.length-1&&!replayed);const n=D.changes.filter(c=>c.window===x.file).length;return {label:x.name+(x.requested?' · requested':''),time:fmtT(x.time),commit:x.commit,changes:i===0?(ms.length>1&&!idx?'its changes are in its own file':'first snapshot'):PL(n,'change')+' since the one before',
          here,away:!here,href:x.file||'#snapshots',openText:'Open this snapshot',dot:here?'var(--ink)':'transparent',bg:here?'var(--sunk)':'transparent'};})};}
~~~

### C-34 · kind 2 · the template: a Snapshots row's link

A row opens its own file.

~~~old
<sc-if value="{{ m.away }}"><span style="font-size:13px;color:var(--ink2)">Separate file in the folder</span></sc-if>
~~~
~~~new
<sc-if value="{{ m.away }}"><a href="{{ m.href }}" style="font-size:13px">Open this snapshot</a></sc-if>
~~~

## Kind 3 — copy true of ViD and of the data

### C-35 · kind 3 · the template: the summary's review column

ViD's reviewers read the code and the test results; they do not use the running product.

~~~old
A separate reviewer uses the running product and judges whether the criterion is met.
~~~
~~~new
A separate reviewer reads its code and test results and judges whether the criterion is met.
~~~

### C-36 · kind 3 · the template: how the product is defined

Not every criterion is reviewed (the case study: 359 of 1,171).

~~~old
because a criterion is the smallest thing that can be checked: once by an automatic test, and once by a reviewer.
~~~
~~~new
because a criterion is the smallest thing that can be checked: by an automatic test, and by a reviewer once one has judged it.
~~~

### C-37 · kind 3 · the template: approved screens' note

Real snapshots aren't samples.

~~~old
Dashed ones have no design embedded in this sample.
~~~
~~~new
Dashed ones have no design embedded in this snapshot.
~~~

### C-38 · kind 3 · the template: the review history's heading

Reviewers judge the code and its test, not the running product.

~~~old
a separate reader judging the product, oldest first
~~~
~~~new
a separate reader judging the code and its test, oldest first
~~~

### C-39 · kind 3 · the template: no review yet

Reviewers read the code and the test results.

~~~old
A review is recorded here when a reviewer checks this criterion against the product and confirms or rejects it.
~~~
~~~new
A review is recorded here when a reviewer reads this criterion's code and test results and confirms or rejects it.
~~~

### C-40 · kind 3 · the template: delivery's heading

Built, tested and reviewed are counted each on its own (kind 2 above), so no stage counts only what passed the one before.

~~~old
From built to confirmed</h2><span style="font-size:13px;color:var(--ink2)">Of all {{ dl.total }} acceptance criteria. Each stage only counts the criteria that also passed the stage before it.</span>
~~~
~~~new
Built, passing and confirmed</h2><span style="font-size:13px;color:var(--ink2)">Of all {{ dl.total }} acceptance criteria, each stage counted on its own: a criterion can pass its test before a builder hands it back.</span>
~~~

### C-41 · kind 3 · the script: `ST`, passing

Gated evidence credits a pass on an earlier commit.

~~~old
pass:{l:'Passing',c:'var(--c-pass)',h:'Its test passed on the latest run.'}
~~~
~~~new
pass:{l:'Passing',c:'var(--c-pass)',h:'Its test passed on the latest result counted for it, which may be on an earlier commit.'}
~~~

### C-42 · kind 3 · the script: `ST`, never run

Never means no eligible result is recorded, not that the test has not run.

~~~old
never:{l:'Never run',c:'var(--c-never)',h:'It has a test, but the test has not run yet.'}
~~~
~~~new
never:{l:'Never run',c:'var(--c-never)',h:'It has a test, but no result of it is recorded yet.'}
~~~

### C-43 · kind 3 · the script: `SHORT`, never run

Never means no eligible result is recorded.

~~~old
never:'test written, not run yet'
~~~
~~~new
never:'no result of its test recorded yet'
~~~

### C-44 · kind 3 · the script: the review legend

A broken judgment can blame the test or the harness, not only the product; a kept one is a reviewer's judgment on the code and its test.

~~~old
[['Confirmed',s.kept,'var(--c-pass)','reviewer confirmed it works'],['Rejected',s.broken,'var(--c-fail)','reviewer found it does not work']
~~~
~~~new
[['Confirmed',s.kept,'var(--c-pass)','a reviewer kept it'],['Rejected',s.broken,'var(--c-fail)','a reviewer found a fault: in the product, the test or the harness']
~~~

### C-45 · kind 3 · the script: a capability's summary line

Most criteria are not reviewed yet (the case study: 359 of 1,171).

~~~old
split into '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked twice: by an automatic test and by a reviewer.'
~~~
~~~new
split into '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked by an automatic test, and by a reviewer once one has judged it.'
~~~

### C-46 · kind 3 · the script: a requirement's summary line

Most criteria are not reviewed yet (the case study: 359 of 1,171).

~~~old
'This requirement is proven by '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked twice: by an automatic test and by a reviewer.'
~~~
~~~new
'This requirement is proven by '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked by an automatic test, and by a reviewer once one has judged it.'
~~~

### C-47 · kind 3 · the script: a step's summary line

Most criteria are not reviewed yet (the case study: 359 of 1,171).

~~~old
'This step took on '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked twice: by an automatic test and by a reviewer.'
~~~
~~~new
'This step took on '+PL(ps.length,'criterion','criteria')+'. Each criterion is checked by an automatic test, and by a reviewer once one has judged it.'
~~~

### C-48 · kind 3 · the script: a screen state with no canvas

Real snapshots aren't samples.

~~~old
' is embedded in this sample'
~~~
~~~new
' is embedded in this snapshot'
~~~

### C-49 · kind 3 · the script: a judgment's fault

A kept judgment does not check "against the product"; a broken one names whichever was at fault, the harness too.

~~~old
fault:j.class==='product'?(j.result==='broken'?'The product was at fault':'Checked against the product'):j.class==='test'?'The test was at fault':'',
~~~
~~~new
fault:j.result==='broken'?(j.class==='product'?'The product was at fault':j.class==='test'?'The test was at fault':j.class==='harness'?'The test harness was at fault':''):'',
~~~

### C-50 · kind 3 · the script: a change's title, a PRD answer

An answer is named by its tier, not always an owner ruling.

~~~old
case 'decision':title=c.ids[0].startsWith('A-')?'Owner ruling':'Technical decision';
~~~
~~~new
case 'decision':title=c.ids[0].startsWith('A-')?(ix.A.get(c.ids[0])?this.tierName(ix.A.get(c.ids[0])):'Ruling'):'Technical decision';
~~~

### C-51 · kind 3 · the script: delivery, passing

Gated evidence credits passes on earlier commits; the stages are counted on their own.

~~~old
{label:'…and passing its test',def:'Its automatic test passes on the latest code.'
~~~
~~~new
{label:'Passing its test',def:'Its test passes on the results recorded, which may be from an earlier commit.'
~~~

### C-52 · kind 3 · the script: delivery, confirmed

Reviewers read the code and the test results; the stages are counted on their own.

~~~old
{label:'…and confirmed by review',def:'A reviewer used the product and confirmed it.'
~~~
~~~new
{label:'Confirmed by review',def:'A reviewer read its code and test results and kept it.'
~~~

### C-53 · kind 3 · the script: delivery, passing without a hand-back

With the stages counted on their own, these criteria are no longer left out; they are named.

~~~old
offText:N(off)+' more criteria pass their test but have not been handed back by a builder yet, usually because they were carried over from earlier work. They are left out here until they are built.'
~~~
~~~new
offText:N(off)+' of the criteria passing their test have no builder\'s hand-back recorded, usually because they were carried over from earlier work.'
~~~

### C-54 · kind 2 · the script: needs you, the answered questions (v0.9.8.1 R22)

Every answer the records hold is shown under Needs you: the view model gains the answered list.

~~~old
hasQs:qs.length>0,qCount:String(qs.length),hasHeld:ny.held.length>0,heldCount:String(ny.held.length),...this.dgV(D),
~~~
~~~new
hasQs:qs.length>0,qCount:String(qs.length),hasHeld:ny.held.length>0,heldCount:String(ny.held.length),...this.dgV(D),...this.ansV(D),
~~~

### C-55 · kind 2 · the script: the answered list's reader (v0.9.8.1 R22)

Each answer of `needsYou.answered`, read from `decisions.answers`: its id, date, tier or delegated mark, the answer and the question; a field the records do not hold reads "not recorded".

~~~old
  actV(D){
~~~
~~~new
  ansV(D){const ix=this.ix,dg=new Set(D.needsYou.delegated||[]),NR='not recorded';const ids=D.needsYou.answered||[];
    const answered=ids.map(id=>{const a=ix.A.get(id)||{};return {id,href:'#'+id,date:a.date?fmtT(a.date):NR,mark:dg.has(id)?'Delegated':a.tier?this.tierName(a):NR,a:a.a?trunc(a.a,300):NR,q:a.q?trunc(a.q,300):NR};});
    return {answered,hasAnswered:answered.length>0,answeredTitle:PL(answered.length,'answered question')};}
  actV(D){
~~~

### C-56 · kind 2 · the markup: needs you, the answered questions (v0.9.8.1 R22)

The answered list, after the delegated rulings, in the delegated list's own rows and styles: the id, `A:` the answer, `Q:` the question, the date and the mark.

~~~old
<sc-if value="{{ dl.dgNone }}"><p style="margin:0;padding:14px 16px;font-size:13px;color:var(--ink2)">{{ dl.dgNoneText }}</p></sc-if>
</div>
</div>
</sc-if>
~~~
~~~new
<sc-if value="{{ dl.dgNone }}"><p style="margin:0;padding:14px 16px;font-size:13px;color:var(--ink2)">{{ dl.dgNoneText }}</p></sc-if>
</div>
</div>
</sc-if>
<sc-if value="{{ dl.hasAnswered }}">
<div style="display:flex;flex-direction:column;gap:8px">
<div style="font-size:11px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase;color:var(--ink2)">{{ dl.answeredTitle }} <span style="text-transform:none;letter-spacing:0;font-weight:400">· every answer the records hold, newest first</span></div>
<div style="border:1px solid var(--line);border-radius:10px;background:var(--panel);box-shadow:var(--shadow)">
<sc-for list="{{ dl.answered }}" as="d">
<a href="{{ d.href }}" style="display:grid;grid-template-columns:56px minmax(0,1fr) auto;gap:12px;padding:12px 16px;border-top:1px solid var(--line);margin-top:-1px;color:var(--ink)" style-hover="background:var(--sunk);text-decoration:none">
<span style="font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12px;color:var(--accent);padding-top:2px">{{ d.id }}</span>
<span style="display:flex;flex-direction:column;gap:4px;min-width:0"><span style="font-size:13px;text-wrap:pretty"><span style="font-weight:600">A:</span> {{ d.a }}</span><span style="font-size:13px;color:var(--ink2);text-wrap:pretty"><span style="font-weight:600">Q:</span> {{ d.q }}</span></span>
<span style="display:flex;flex-direction:column;gap:2px;align-items:flex-end;font-size:12px;color:var(--ink2);white-space:nowrap"><span>{{ d.date }}</span><span>{{ d.mark }}</span></span>
</a>
</sc-for>
</div>
</div>
</sc-if>
~~~

### C-57 · kind 3 · the page's title: the product's name (owner, 2026-10-17)

The product is renamed ViD (VisionDelivery.ai); the page's title says so.

~~~old
<helmet><title>VID Viewer</title>
~~~
~~~new
<helmet><title>ViD Viewer</title>
~~~

### C-58 · kind 3 · the markup: the header's name (owner, 2026-10-17)

The header names the product as renamed.

~~~old
<span style="font-size:12px;color:var(--ink2)">VID Viewer · what is being built, how far, and the evidence</span>
~~~
~~~new
<span style="font-size:12px;color:var(--ink2)">ViD Viewer · what is being built, how far, and the evidence</span>
~~~

### C-59 · kind 2 · the script: the project's name (v0.26.10.2 R11a)

v3 writes the sample's name where v2 read it from the data; the page names the snapshot's own project again.

~~~old
const v={...handlers,loading:false,replayed,project:'Sample Job Board',
~~~
~~~new
const v={...handlers,loading:false,replayed,project:m.project,
~~~

### C-60 · kind 2 · the script: the product definition's title (v0.26.10.2 R11a)

The same, on the product definition's page.

~~~old
title:'Sample Job Board',size:'32px'
~~~
~~~new
title:m.project,size:'32px'
~~~

### C-61 · kind 2 · the script: the design-only architecture previews (v0.26.10.2 R11b)

The design's `archSample` switch (and its `window.VID_ARCH_SAMPLE` hook) builds invented states for the design's own review: "edge states" adds a module, a decision label and interface changes no project recorded, and "past snapshot" fixes a moment. A snapshot shows only what is recorded, so the switch is held at "as recorded" and the hook is gone; a snapshot replayed from the past says so through its own data.

~~~old
as=window.VID_ARCH_SAMPLE||this.props.archSample||'as recorded';
~~~
~~~new
as='as recorded';
~~~

### C-62 · kind 3 · the script: the missing part's name, must-never-break (v0.26.10.2 R15)

The data names a missing Tier-0 table as the part `mustNeverBreak`; the notice gives it a name a reader knows, as it does the other parts.

~~~old
planOnly:'Plan module names',all:'Architecture'};
~~~
~~~new
planOnly:'Plan module names',mustNeverBreak:'Must-never-break rules',all:'Architecture'};
~~~

## v0.26.10.6 — the Execution and Economics sections (v4's own)

C-01 to C-62 apply to v4 as they are, each old text found once (v0.26.10.6
§11). The entries below are v4's own, each as small as it can be (spec R18).

### C-63 · kind 2 · the script: the design-only execution previews (v0.26.10.6 R18a)

The design's `execSample` switch (and its `window.VID_EXEC_SAMPLE` and `window.VID_EXEC_DATASET` hooks) builds invented states for the design's own review: "edge states" makes an agent die, a Codex job need recovery and two older totals turn into four kinds (`xEdge`), and "past snapshot" cuts the data at a fixed moment (`xCut`). A snapshot shows only what is recorded, so the switch is held at "as recorded" and both hooks are gone; a past snapshot's own data already holds only what was recorded by its moment.

~~~old
const ds=window.VID_EXEC_DATASET||this.props.dataset||'full',smp=window.VID_EXEC_SAMPLE||this.props.execSample||'as recorded';
~~~
~~~new
const ds=this.props.dataset||'full',smp='as recorded';
~~~

### C-64 · kind 2 · the script: `xPrice`, the 1-hour cache write (v0.26.10.6 R18b, R13)

Claude's cache writes are of two lifetimes, priced differently; a usage entry's `cacheWrite1h` is the part of `cacheWrite` written for one hour, priced at the table's 1-hour rate, and the rest at the 5-minute rate.

~~~old
(u.cacheWrite||0)*p.cacheWrite+
~~~
~~~new
((u.cacheWrite||0)-(u.cacheWrite1h||0))*p.cacheWrite+(u.cacheWrite1h||0)*p.cacheWrite1h+
~~~

### C-65 · kind 2 · the script: Cost per outcome's shared-work line, the run manager (v0.26.10.6 R18c)

A run manager's window recorded in the four kinds carries no older total; the line names the older records' total only for them, and shows the four-kind sums apart, never a total alone.

~~~old
mgr:'Run manager: '+PL(O.shared.managerRecords,'record')+', '+TK(mT)+' total (input and cache together; output not recorded).',
~~~
~~~new
mgr:'Run manager: '+PL(O.shared.managerRecords,'record')+(mg.length-mK?', '+PL(mg.length-mK,'older record')+' '+TK(mT)+' total (input and cache together; output not recorded)':'')+(mK?(mg.length-mK?';':',')+' '+PL(mK,'record')+' in four kinds, shown apart: input '+TK(mg.reduce((n,x)=>n+(x.input||0),0))+' · cache read '+TK(mg.reduce((n,x)=>n+(x.cacheRead||0),0))+' · cache write '+TK(mg.reduce((n,x)=>n+(x.cacheWrite||0),0))+' · output '+TK(mg.reduce((n,x)=>n+(x.output||0),0)):'')+'.',
~~~

### C-66 · kind 2 · the script: a group's lines, the reported total (v0.26.10.6 R18d)

A total the agent reported itself is shown on its own, labelled as such, never inside the older totals or the four kinds.

~~~old
if(o.nR)out.push({k:'Reported total ('+N(o.nR)+'):',v:TK(o.r)});
~~~
~~~new
if(o.nR)out.push({k:'Reported by the agent ('+N(o.nR)+'):',v:TK(o.r)+' (a total the agent reported itself)'});
~~~

### C-67 · kind 2 · the script: the older-totals card, the reported total (v0.26.10.6 R18d)

The cards counted a reported total nowhere; its sum is now said on its own, apart from the older totals.

~~~old
tSub:PL(S.nT,'agent')+' · total (input and cache together; output not recorded). No dollar figure is put on an older total.',
~~~
~~~new
tSub:PL(S.nT,'agent')+' · total (input and cache together; output not recorded). No dollar figure is put on an older total.'+(S.nR?' Reported by the agent, apart: '+TK(S.r)+' ('+PL(S.nR,'agent')+').':''),
~~~

### C-68 · kind 2 · the script: the grouped table, the reported total (v0.26.10.6 R18d)

A group's reported total is shown under its older total, labelled, never added to it.

~~~old
hasTN:o.nT>0,tN:PL(o.nT,'agent'),
~~~
~~~new
hasTN:o.nT>0||o.nR>0,tN:(o.nT?PL(o.nT,'agent'):'')+(o.nR?(o.nT?' · ':'')+'reported by the agent: '+TK(o.r)+' ('+PL(o.nR,'agent')+')':''),
~~~

### C-69 · kind 2 · the script: a try's short usage, the reported total (v0.26.10.6 R18d)

A reported total is not an older total; the short line says which it is.

~~~old
return {tok:TK(u.total)+' older total (input and cache together; output not recorded)',fg:'var(--ink)'};}
~~~
~~~new
return {tok:TK(u.total)+(u.kind==='reported'?' reported by the agent':' older total (input and cache together; output not recorded)'),fg:'var(--ink)'};}
~~~

### C-70 · kind 2 · the script: `XST`, the state `unaccepted` (v0.26.10.6 R18e, R1)

An agent with a hand-back and no acceptance recorded is neither returned nor without a hand-back; its state reads "handed back, no acceptance recorded" in the roster, the agent page and the copy-a-prompt state word.

~~~old
returned:{l:'Returned',w:'returned',c:'var(--c-pass)'},
~~~
~~~new
returned:{l:'Returned',w:'returned',c:'var(--c-pass)'},unaccepted:{l:'Handed back, no acceptance recorded',w:'handed back, no acceptance recorded',c:'var(--c-owed)'},
~~~

## Kind 4 — a panel added in the page's own look (v0.26.10.8)

### C-71 · kind 4 · the template: Delivery's Stages panel (v0.26.10.8 R12)

The Delivery overview gains a Stages panel under its cards, shown when the data lists a stage or records staging or production (`stages`, viewer-data 4): one line per stage (its number, its name, its state; stage 0 marked "technical, never released"), what staging was last verified at, a later failed attempt, and what production runs. Its look is the "Built, passing and confirmed" panel's: the same section, heading, list and footnote styles; no navigation is added.

~~~old
{{ c.cta }} →</span></a></sc-for></div>
~~~
~~~new
{{ c.cta }} →</span></a></sc-for></div>
<sc-if value="{{ dl.hasStages }}">
<section aria-labelledby="h-stages" style="display:flex;flex-direction:column;gap:12px;padding:20px;background:var(--panel);border:1px solid var(--line);border-radius:10px;box-shadow:var(--shadow)">
<div style="display:flex;flex-direction:column;gap:2px"><h2 id="h-stages" style="margin:0;font-size:17px">Stages</h2><span style="font-size:13px;color:var(--ink2)">The stages the build is cut into, and what staging and production run.</span></div>
<ol style="margin:0;padding:0;list-style:none;display:flex;flex-direction:column;gap:8px">
<sc-for list="{{ dl.stages }}" as="s">
<li style="display:flex;flex-wrap:wrap;gap:4px 12px;align-items:baseline"><strong style="font-size:14px">Stage {{ s.n }}</strong><span style="font-size:14px;flex:1 1 200px;min-width:0;text-wrap:pretty">{{ s.name }}<sc-if value="{{ s.technical }}"><span style="font-size:12px;color:var(--ink2)"> · technical, never released</span></sc-if></span><span style="font-size:12px;color:var(--ink2)">{{ s.state }}</span></li>
</sc-for>
</ol>
<sc-if value="{{ dl.hasStaging }}"><p style="margin:0;padding-top:12px;border-top:1px solid var(--line);font-size:13px;color:var(--ink2);text-wrap:pretty">{{ dl.stgText }}</p></sc-if>
<sc-if value="{{ dl.hasStgFail }}"><p style="margin:0;font-size:13px;color:var(--ink2);text-wrap:pretty">{{ dl.stgFail }}</p></sc-if>
<p style="margin:0;font-size:13px;color:var(--ink2);text-wrap:pretty">{{ dl.prText }}</p>
</section>
</sc-if>
~~~

### C-72 · kind 4 · the script: the Stages panel's reader, `stgV` (v0.26.10.8 R12)

The panel's lines, from `stages`: R12's wording, a commit shown by its first seven characters, a part with no record left out. A snapshot without `stages` reads as an empty part.

~~~old
  actV(D){
~~~
~~~new
  stgV(D){const S=D.stages||{list:[],staging:null,production:null},sg=S.staging,pr=S.production,c7=c=>String(c||'').slice(0,7);
    const SL={closed:'Closed',held:'Closed and held',building:'Building','not started':'Not started'};
    const stages=(S.list||[]).map(s=>({n:String(s.n),name:s.name,technical:!!s.technical,state:SL[s.state]||s.state}));
    const sp=sg?[sg.stage!=null?'stage '+sg.stage:'',sg.ahead!=null?PL(sg.ahead,'commit')+' past the last full pass':''].filter(Boolean).join(', '):'';
    const f=sg&&sg.lastFailure;const pp=pr?[pr.stage!=null?'stage '+pr.stage:'',pr.at?'since '+fmtT(pr.at):''].filter(Boolean).join(', '):'';
    return {hasStages:(S.list||[]).length>0||!!sg||!!pr,stages,hasStaging:!!sg,stgText:sg?'Staging last verified at '+c7(sg.commit)+(sp?': '+sp:''):'',
      hasStgFail:!!f,stgFail:f?'A later attempt failed '+fmtT(f.at)+(f.why?': '+f.why:'')+'; staging may run '+(f.candidate?c7(f.candidate):'a newer commit')+', unverified.':'',
      prText:pr?'Production runs '+c7(pr.commit)+(pp?': '+pp:''):'Nothing live yet'};}
  actV(D){
~~~

### C-73 · kind 4 · the script: the panel in Delivery's view (v0.26.10.8 R12)

The panel's values join Delivery's, beside the delegated rulings' and the answers'.

~~~old
...this.dgV(D),...this.ansV(D),
~~~
~~~new
...this.dgV(D),...this.ansV(D),...this.stgV(D),
~~~
