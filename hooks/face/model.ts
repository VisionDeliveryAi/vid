// ViD's face (0.26.10.29): the panel's pure part. It reads the three files
// checks/face.sh and the hooks write, and composes the one message a sitting
// sends. No engine call here: register.tsx reads and draws, this decides.

import type { Act, Backlog, BacklogItem, FaceItem, FaceSection, Kind, Marks, Page, Run, Sitting, Standing, Stop, Wait } from './types'

// usability (P1): format 2 carries each item's preset; format 1 is read too, with none
export const FORMAT = 2
export const FORMATS = [1, 2]
export const WRITTEN_FOR = '2.1.321'
const KINDS: Kind[] = ['text', 'questions', 'list', 'objections', 'decided', 'figures', 'alone']

export function blankMarks(): Marks {
  return { a: {}, w: {}, note: {}, open: {}, noteOpen: {}, only: {}, sentAt: '', sentText: '', sentHow: '', raw: false, ids: false, refused: '' }
}

// A mark's key: the item under its section (an item may be in two).
export function mk(sec: FaceSection, item: FaceItem): string {
  return `${sec.id}/${item.id}`
}

// One sitting is told apart from the next by who wrote it and when.
export function keyOf(s: Sitting): string {
  return `${s.sitting}|${s.session}|${s.written}`
}

const str = (v: unknown): string => (typeof v === 'string' ? v : typeof v === 'number' ? String(v) : '')
const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0)
const strs = (v: unknown): string[] => (Array.isArray(v) ? v.map(str) : [])
const obj = (v: unknown): Record<string, unknown> => (v !== null && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {})

export type Parsed<T> = { value: T | null; problem: string }

// A format this panel does not know is said, never guessed at.
function formatProblem(o: Record<string, unknown>, what: string): string {
  const f = o.format
  if (typeof f !== 'number') return `The ${what} is not in a form this panel reads.`
  if (f > FORMAT) return 'It was written by a newer ViD than this panel can read.'
  if (!FORMATS.includes(f)) return `The ${what} is in a form this panel does not read.`
  return ''
}

export function parseSitting(text: string): Parsed<Sitting> {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return { value: null, problem: 'The sitting file could not be read: it is not whole JSON.' }
  }
  const o = obj(raw)
  const p = formatProblem(o, 'sitting')
  if (p) return { value: null, problem: p }
  const sections: FaceSection[] = []
  for (const sv of Array.isArray(o.sections) ? o.sections : []) {
    const s = obj(sv)
    const kind = str(s.kind) as Kind
    if (!KINDS.includes(kind)) return { value: null, problem: `The sitting holds a section of a kind this panel does not know ("${str(s.kind)}").` }
    const acts: Act[] = (Array.isArray(s.acts) ? s.acts : []).map(av => {
      const a = obj(av)
      return { id: str(a.id), label: str(a.label), words: a.words === true }
    })
    const items: FaceItem[] = (Array.isArray(s.items) ? s.items : []).map(iv => {
      const i = obj(iv)
      return {
        id: str(i.id),
        text: str(i.text),
        detail: strs(i.detail),
        recommend: str(i.recommend),
        choices: strs(i.choices),
        value: str(i.value),
        preset: str(i.preset),
        presetBy: str(i.presetBy),
        alone: i.alone === true || kind === 'alone',
        norecommend: i.norecommend === true,
        about: str(i.about),
        // 0.26.10.29.6 (S10): where ViD points to look; a sitting written before it has none
        look: str(i.look),
      }
    })
    if (items.some(i => !i.id)) return { value: null, problem: 'The sitting holds an item with no id.' }
    sections.push({ id: str(s.id), kind, title: str(s.title), source: str(s.source), empty: s.empty === true, why: str(s.why), acts, items })
  }
  const value: Sitting = {
    format: num(o.format),
    sitting: str(o.sitting),
    stop: num(o.stop),
    session: str(o.session),
    written: str(o.written),
    state: str(o.state),
    ended: str(o.ended),
    title: str(o.title),
    send: str(o.send) || 'Send to ViD',
    closing: str(o.closing),
    ready: str(o.ready),
    sections,
  }
  return { value, problem: '' }
}

export function parseStanding(text: string): Parsed<Standing> {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return { value: null, problem: 'The standing file could not be read: it is not whole JSON.' }
  }
  const o = obj(raw)
  const p = formatProblem(o, 'standing')
  if (p) return { value: null, problem: p }
  const stops: Stop[] = (Array.isArray(o.stops) ? o.stops : []).map(sv => {
    const s = obj(sv)
    return { n: num(s.n), name: str(s.name), state: str(s.state), sitting: s.sitting === true, agreed: str(s.agreed) }
  })
  if (stops.length === 0) return { value: null, problem: 'The standing lists no stops.' }
  const w = obj(o.wait)
  const wait: Wait = {
    parts: (Array.isArray(w.parts) ? w.parts : []).map(pv => {
      const x = obj(pv)
      return { name: str(x.name), state: str(x.state) }
    }),
    now: str(w.now),
    stop: str(w.stop),
    written: str(w.written),
  }
  // FB-3 D1: the backlog, null where the standing carries none
  const items = (v: unknown): BacklogItem[] =>
    (Array.isArray(v) ? v : []).map(iv => {
      const x = obj(iv)
      return { id: str(x.id), state: str(x.state), who: str(x.who), words: str(x.words), next: str(x.next), note: str(x.note) }
    })
  const b = obj(o.backlog)
  const backlog: Backlog | null = Array.isArray(b.items) ? { items: items(b.items), done: items(b.done), doneCount: num(b.doneCount) } : null
  // usability (P9): the pages to read, in the index's order
  const pages: Page[] = (Array.isArray(o.pages) ? o.pages : []).map(pv => {
    const x = obj(pv)
    return { id: str(x.id), title: str(x.title), file: str(x.file), link: str(x.link), stops: (Array.isArray(x.stops) ? x.stops : []).map(num) }
  })
  return {
    value: { format: num(o.format), written: str(o.written), current: num(o.current), turn: str(o.turn), sitting: str(o.sitting), session: str(o.session), next: str(o.next), wait, backlog, pages, stops },
    problem: '',
  }
}

// usability (P4): `<running|stopped> <since> <last step|->`; anything else is no file
export function parseRun(text: string): Run | null {
  const f = text.trim().split(/\s+/)
  if (f.length !== 3 || (f[0] !== 'running' && f[0] !== 'stopped')) return null
  return { state: f[0]!, since: f[1]!, last: f[2] === '-' ? '' : f[2]! }
}

export const running = (r: Run | null): boolean => r !== null && r.state === 'running'

// What the panel shows: one of these, from the files and the marks.
export type Mode = 'sitting' | 'sent' | 'drafting' | 'run' | 'working' | 'stopped' | 'idle' | 'done' | 'problem' | 'none'

// usability (P4): a waiting sitting is drawn while the standing's current stop is its stop or an earlier one
export function waits(standing: Standing | null, sitting: Sitting | null): boolean {
  return standing !== null && sitting !== null && sitting.state === 'waiting' && standing.current <= sitting.stop
}

// FB-3 D1, D2: in ticket mode, the standing holds a backlog, or the parts or the stop of a call
export function runs(standing: Standing): boolean {
  const b = standing.backlog, w = standing.wait
  return b !== null && (b.items.length > 0 || b.doneCount > 0 || w.parts.length > 0 || w.stop !== '')
}

// FB-3 D2: a call's parts are live while the session runs and they were written in its turn: a killed call's are not
export function live(standing: Standing, run: Run | null): boolean {
  if (!running(run)) return false
  const written = Date.parse(standing.wait.written), since = Date.parse(run!.since)
  return Number.isNaN(written) || Number.isNaN(since) || written >= since
}

// FB-3 D1: the backlog's counts in one line
export function counts(b: Backlog): string {
  const of = (s: string) => b.items.filter(i => i.state === s).length
  const out = [
    [of('to do'), 'to do'],
    [of('doing'), 'in progress'],
    [of('waiting'), 'waiting'],
    [of('aside'), 'set aside'],
  ]
    .filter(([n]) => n)
    .map(([n, w]) => `${n} ${w}`)
    .join(' · ')
  return out || 'Nothing is open'
}
export const cut = (t: string): string => (t.length > 300 ? t.slice(0, 299).trimEnd() + '…' : t)

export function modeOf(standing: Standing | null, sitting: Sitting | null, marks: Marks, problem: string, project: boolean, run: Run | null, hasList = false): Mode {
  if (problem) return 'problem'
  if (!project) return 'none'
  if (!standing) return 'idle'
  if (waits(standing, sitting)) return marks.sentAt ? 'sent' : 'sitting'
  // usability (P13): a draft at the current stop or a later one is shown, never as waiting on the person
  if (sitting !== null && sitting.state === 'drafting' && standing.current <= sitting.stop) return 'drafting'
  // FB-3 D1, D2: a run: the owner's list, or a long call's parts or stop, whatever stop the map is at
  // FB-5 A1: the owner's list too, with nothing in the backlog
  if (runs(standing) || (hasList && standing.backlog !== null)) return 'run'
  if (standing.current > standing.stops.length) return 'done'
  if (standing.current <= 1) return 'idle'
  return running(run) ? 'working' : 'stopped'
}

// FB-7 B6: in a run, what the session is still on, when its last step, or its turn with none yet, is over 20 minutes old
export function stuckOn(standing: Standing, run: Run | null, nowMs: number): { on: string; since: string } | null {
  if (!running(run)) return null
  const t = Math.max(...[Date.parse(run!.since), Date.parse(run!.last)].filter(x => !Number.isNaN(x)))
  if (!Number.isFinite(t) || nowMs - t <= 20 * 60000) return null
  const w = live(standing, run) ? standing.wait : null
  return { on: w?.parts.find(p => p.state === 'now')?.name || w?.now || 'its last step', since: new Date(t).toISOString() }
}

// FB-7 B6: a run in GitHub auto is on: RUN-STATE.md says `run: active` and names no other conversation (connect.sh writes its
// session's id, or `connect-…` where it had none), its head alone, before its first part; and the setup's newest mode is not manual
export function active(text: string, setup: string, here: string): boolean {
  if ([...setup.matchAll(/^setup-answered key=github-mode value="([a-z]*)"/gm)].pop()?.[1] === 'manual') return false
  const head = text.split(/^## /m)[0]!
  const of = (k: string) => new RegExp(`^${k}:[ \\t]*(.*)$`, 'm').exec(head)?.[1]!.trim() ?? ''
  const s = of('session')
  return of('run') === 'active' && (s === '' || s.startsWith('connect-') || s === here)
}

// usability (P5): the wait in whole minutes, from the run file's times
export function waitLines(run: Run | null, nowMs: number): string[] {
  if (!run || run.state !== 'running') return []
  const since = Date.parse(run.since)
  if (Number.isNaN(since)) return []
  const mins = (t: number) => Math.max(0, Math.floor((nowMs - t) / 60000))
  const out = [mins(since) < 1 ? 'Working for under a minute' : `Working for ${mins(since)} min`]
  const last = Date.parse(run.last)
  if (!Number.isNaN(last) && last > since) out.push(mins(last) < 1 ? 'Last step under a minute ago' : `Last step ${mins(last)} min ago`)
  return out
}

// usability (P10): the findings drawn beside the item they are about, keyed by that item's mark key; a finding
// naming no item, an item the sitting does not hold, or its own section, or pointed to (look), stays in its section
export function besides(s: Sitting): { at: Record<string, { sec: FaceSection; item: FaceItem }[]>; placed: Set<string> } {
  // only items drawn as rows or questions carry notes; a finding about any other stays in its own section
  const keys = new Set<string>()
  for (const sec of s.sections) if (['questions', 'alone', 'list', 'objections', 'decided'].includes(sec.kind)) for (const it of sec.items) keys.add(mk(sec, it))
  const at: Record<string, { sec: FaceSection; item: FaceItem }[]> = {}
  const placed = new Set<string>()
  for (const sec of s.sections) {
    if (sec.kind !== 'objections') continue
    for (const it of sec.items) {
      // 0.26.10.29.6 (S10): a finding ViD points to stays under "Look here first" in its own section
      if (it.look || !it.about || !keys.has(it.about) || it.about.startsWith(sec.id + '/')) continue
      ;(at[it.about] ??= []).push({ sec, item: it })
      placed.add(mk(sec, it))
    }
  }
  return { at, placed }
}

// A section's items that wait on the person.
export function needsAnswer(sec: FaceSection): boolean {
  return sec.kind === 'questions' || ((sec.kind === 'list' || sec.kind === 'objections') && sec.acts.length > 0)
}
// usability (P7): asked on its own, in an alone section or marked so in another
export const answerable = (sec: FaceSection): boolean => needsAnswer(sec) || sec.kind === 'alone'
export const isAlone = (sec: FaceSection, item: FaceItem): boolean => sec.kind === 'alone' || item.alone

// usability (P1): the mark an item starts at, and its words
export function startOf(sec: FaceSection, item: FaceItem): { a: string; w: string } {
  const p = item.preset
  if (!p || isAlone(sec, item) || !needsAnswer(sec)) return { a: '', w: '' }
  if (p.startsWith('choose:')) return { a: p, w: '' }
  const i = p.indexOf(':')
  return i < 0 ? { a: p, w: '' } : { a: p.slice(0, i), w: p.slice(i + 1) }
}

const takesWords = (sec: FaceSection, value: string): boolean => (value === 'own' ? true : sec.acts.some(a => a.id === value && a.words))

// what the item holds now: its mark, and its words where the mark takes them
function nowOf(sec: FaceSection, item: FaceItem, m: Marks): { a: string; w: string } {
  const a = m.a[mk(sec, item)] ?? ''
  return { a, w: a && takesWords(sec, a) ? (m.w[mk(sec, item)] ?? '') : '' }
}

export function atStart(sec: FaceSection, item: FaceItem, m: Marks): boolean {
  const s = startOf(sec, item), n = nowOf(sec, item, m)
  return s.a === n.a && s.w === n.w
}

// The marks of a sitting nobody has touched: every item at its preset.
export function presetMarks(s: Sitting): Marks {
  const m = blankMarks()
  for (const sec of s.sections)
    for (const it of sec.items) {
      const st = startOf(sec, it)
      if (!st.a) continue
      m.a[mk(sec, it)] = st.a
      if (st.w) m.w[mk(sec, it)] = st.w
    }
  return m
}

// The counts of the foot (P1): M items of questions, lists and findings, not asked on their own; N of them changed;
// K of them with no mark, and every item asked on its own with no answer (A of those).
export function tally(s: Sitting, m: Marks): { n: number; m: number; k: number; alone: number } {
  let n = 0, total = 0, k = 0, alone = 0
  for (const sec of s.sections) {
    if (!answerable(sec)) continue
    for (const it of sec.items) {
      const marked = !!m.a[mk(sec, it)]
      if (isAlone(sec, it)) {
        if (!marked) {
          k++
          alone++
        }
        continue
      }
      total++
      if (!atStart(sec, it, m)) n++
      if (!marked) k++
    }
  }
  return { n, m: total, k, alone }
}

export function footLine(t: { n: number; m: number; k: number }): string {
  return `You changed ${t.n} of ${t.m}. ${t.k} ${t.k === 1 ? 'needs' : 'need'} your answer.`
}

export function aloneLine(left: number): string {
  return left === 1 ? '1 question asked on its own still needs your answer.' : `${left} questions asked on their own still need your answer.`
}

// Marking: one press sets a mark, the same press again clears it. usability (P14): words leave with their button.
export function marked(m: Marks, sec: FaceSection, item: FaceItem, value: string): Marks {
  const k = mk(sec, item)
  const a = { ...m.a }
  if (a[k] === value) delete a[k]
  else a[k] = value
  const w = { ...m.w }
  if (!a[k] || !takesWords(sec, a[k]!)) delete w[k]
  return { ...m, a, w }
}

// usability (P2): "As recommended" puts back every item with a preset, words and all; one asked on its own, never
export function restorable(sec: FaceSection, m: Marks): boolean {
  return answerable(sec) && sec.items.some(it => startOf(sec, it).a !== '' && !atStart(sec, it, m))
}
export function asRecommended(s: Sitting, m: Marks, only?: string): Marks {
  const a = { ...m.a }, w = { ...m.w }
  for (const sec of s.sections) {
    if (only !== undefined && sec.id !== only) continue
    for (const it of sec.items) {
      const st = startOf(sec, it)
      if (!st.a) continue
      const k = mk(sec, it)
      a[k] = st.a
      if (st.w) w[k] = st.w
      else delete w[k]
    }
  }
  return { ...m, a, w }
}

// A mark is an act id, or for a choice `choose:<the choice's words>`.
export function valueWords(sec: FaceSection, item: FaceItem, m: Marks): string {
  const v = m.a[mk(sec, item)]
  if (!v) return ''
  if (v.startsWith('choose:')) return v.slice(7)
  const act = sec.acts.find(x => x.id === v)
  const label = act ? act.label : v
  const words = m.w[mk(sec, item)] ?? ''
  if (sec.kind === 'questions' || sec.kind === 'alone') {
    if (v === 'own') return words
    return label
  }
  return words && act?.words ? `${label}: ${words}` : label
}

const short = (t: string): string => (t.length > 90 ? t.slice(0, 89).trimEnd() + '…' : t)
const stop = (t: string): string => (/[.?!…]$/.test(t) ? t : t + '.')
const RULING = "The qualities I marked 'Doesn't need it' are out; keep my ruling on record."

export type Group = { title: string; rows: { label: string; value: string }[]; rest: string }

// The one message: plain words a person could have typed, each item named
// by ViD's id; and the same, grouped without ids, for "what was sent".
// usability (P1): in each section of questions, lists or findings, the person's changes, then what stays as ViD
// recommended it, what stays as ViD wrote it, and what is not answered; P7: an alone section under its own head.
export function compose(s: Sitting, m: Marks): { text: string; groups: Group[] } {
  const out: string[] = [`${s.title}: my answers, from ViD's panel.`, '']
  const groups: Group[] = []
  const pl = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`
  for (const sec of s.sections) {
    const note = m.note[sec.id] ?? ''
    if (!answerable(sec) && sec.kind !== 'decided') continue
    if (!sec.items.length && !note) continue
    const rows: { label: string; value: string }[] = []
    const lines: string[] = []
    const line = (it: FaceItem, v: string) => {
      rows.push({ label: it.text, value: v })
      lines.push(`${it.id} ${stop(short(it.text)).replace(/\.$/, '')}: ${stop(v)}`)
    }
    const rest: string[] = []
    let ruled = false
    if (sec.kind === 'decided') {
      for (const it of sec.items) {
        const v = valueWords(sec, it, m)
        if (v) line(it, v)
      }
      if (!lines.length && !note) continue
      out.push(sec.title + ':', ...lines)
      if (lines.length < sec.items.length) {
        out.push('The rest stand.')
        rest.push('The rest stand.')
      }
    } else {
      const rec: string[] = [], recRows: string[] = [], wrote: string[] = [], none: string[] = []
      for (const it of sec.items) {
        const v = valueWords(sec, it, m)
        if (!v) none.push(it.id)
        else if (!isAlone(sec, it) && atStart(sec, it, m)) {
          if (it.presetBy === 'standing') wrote.push(it.id)
          else {
            rec.push(`${it.id} (${v})`)
            recRows.push(`${short(it.text)} (${v})`)
          }
        }
        else line(it, v)
      }
      out.push(sec.kind === 'alone' ? 'Asked on their own:' : sec.title + ':', ...lines)
      if (rec.length) out.push(`As ViD recommended: ${rec.join('; ')}.`)
      if (wrote.length) out.push(`Left as ViD wrote them: ${wrote.join(', ')}.`)
      if (none.length) out.push(`Not answered: ${none.join(', ')}.`)
      ruled = sec.items.some(it => m.a[mk(sec, it)] === 'out' && sec.acts.some(a => a.id === 'out' && a.label === "Doesn't need it"))
      if (rec.length) rest.push(`As ViD recommended: ${recRows.join('; ')}`)
      if (wrote.length) rest.push(`${pl(wrote.length, 'item', 'items')} left as ViD wrote them`)
      if (none.length) rest.push(`${pl(none.length, 'item', 'items')} not answered`)
    }
    if (note) {
      out.push(`Note: ${note}`)
      rows.push({ label: 'Your note on this list', value: note })
    }
    // usability (P3): the ruling sentence ends the section's lines, after its note
    if (ruled) out.push(RULING)
    out.push('')
    groups.push({ title: sec.kind === 'alone' ? `Asked on their own: ${sec.title.charAt(0).toLowerCase() + sec.title.slice(1)}` : sec.title, rows, rest: rest.length ? stop(rest.join(' · ')) : '' })
  }
  if (s.closing) out.push(s.closing)
  return { text: out.join('\n').trim(), groups }
}

// Whether this session may send: only into the one that presented it.
export function sendable(s: Sitting, here: string): { ok: boolean; why: string } {
  if (s.session && here && s.session === here) return { ok: true, why: '' }
  return { ok: false, why: 'This conversation is not the one where ViD asked, so the panel does not send. Your answers are in the message box: send them in that conversation, or here if you are sure.' }
}

// The engine's version against the one this panel was written for.
export function versionNote(version: string): string {
  if (!version || version === WRITTEN_FOR) return ''
  return `Written for Claude Code ${WRITTEN_FOR}; this is ${version}. If anything here looks wrong, carry on in the chat.`
}

// ViD's ids stay out of sight unless the person asks (a line that carries
// one is held back with them).
export const ID = /\b(?:REQ|INV|OQ|DIM|FEAT|A|F|RULE|ROW)-[A-Za-z0-9]|^grounds T0 [0-9]/
export function shown(lines: string[], ids: boolean): string[] {
  return ids ? lines : lines.filter(l => !ID.test(l))
}

// The list that carries the U key: the longest list to review with four items or more (one key, one list).
export function filterList(s: Sitting): string {
  let best = '', n = 3
  for (const sec of s.sections) if (needsAnswer(sec) && sec.kind !== 'questions' && !sec.empty && sec.items.length > n) { best = sec.id; n = sec.items.length }
  return best
}

// Two conversations share the store: a send recorded by either is kept, whole,
// with the answers it sent (never this conversation's unsent ones beside it).
export function merged(stored: Marks | undefined, mine: Marks): Marks {
  if (stored && stored.sentAt && !mine.sentAt) return { ...stored, raw: mine.raw, ids: mine.ids }
  return mine
}
