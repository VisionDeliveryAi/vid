// FB-5 A1: the owner's list in the panel, its pure part: it reads .vid/face/list.json and words what is drawn and what a press
// says. No engine call here: register.tsx reads and sends, listdraw.tsx draws.

import type { List, ListAsk, ListCard, ListHold, ListMarks, ListStep, ListTodo, Said } from './types'
import type { Parsed } from './model'

export const LIST_FORMAT = 1

export function blankList(): ListMarks {
  return { sent: {}, asked: {}, picks: {}, refused: {}, open: '', shut: false, shown: {} }
}

const str = (v: unknown): string => (typeof v === 'string' ? v : typeof v === 'number' ? String(v) : '')
const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0)
const arr = (v: unknown): unknown[] => (Array.isArray(v) ? v : [])
const strs = (v: unknown): string[] => arr(v).map(str).filter(t => t !== '')
const obj = (v: unknown): Record<string, unknown> => (v !== null && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {})
const rows = <T>(v: unknown, fn: (o: Record<string, unknown>) => T): T[] => arr(v).map(x => fn(obj(x)))

const card = (c: Record<string, unknown>): ListCard => ({
  id: str(c.id),
  name: str(c.name),
  flag: str(c.flag),
  state: str(c.state),
  ticket: num(c.ticket),
  url: str(c.url),
  done: num(c.done),
  pieces: num(c.pieces),
  who: str(c.who),
  ready: num(c.ready),
  drafts: num(c.drafts),
  pulls: rows(c.pulls, p => ({ n: num(p.n), url: str(p.url), draft: p.draft === true })),
  sent: str(c.sent),
  days: num(c.days),
  buildsOn: strs(c.buildsOn),
  holdsUp: num(c.holdsUp),
  tests: num(c.tests),
  testIds: strs(c.testIds),
  notes: strs(c.notes),
})

export function parseList(text: string): Parsed<List> {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    return { value: null, problem: 'Your list could not be read: it is not whole JSON.' }
  }
  const o = obj(raw)
  if (typeof o.format !== 'number') return { value: null, problem: 'Your list is not in a form this panel reads.' }
  if (o.format > LIST_FORMAT) return { value: null, problem: 'Your list was written by a newer ViD than this panel can read.' }
  const rest = obj(o.rest), plan = obj(o.plan), hold = obj(plan.hold)
  const ask = (a: Record<string, unknown>): ListAsk => ({ ask: str(a.ask), about: str(a.about), choose: num(a.choose), why: str(a.why), choices: strs(a.choices), message: str(a.message) })
  return {
    problem: '',
    value: {
      format: o.format,
      written: str(o.written),
      title: str(o.title),
      state: str(o.state),
      sortedAt: str(o.sortedAt),
      unsorted: num(o.unsorted),
      todo: rows(o.todo, t => ({ n: str(t.n), ids: strs(t.ids), title: str(t.title), do: str(t.do), isNew: t.isNew === true, new: str(t.new), what: str(t.what), asks: rows(t.asks, ask), then: str(t.then), details: str(t.details) })),
      waiting: rows(o.waiting, w => ({ who: str(w.who), what: str(w.what), since: str(w.since), details: str(w.details) })),
      changed: strs(o.changed),
      rest: {
        vid: strs(rest.vid),
        later: rows(rest.later, l => ({ when: str(l.when), what: str(l.what) })),
        team: strs(rest.team),
        suggested: strs(rest.suggested),
        leftOut: strs(rest.leftOut),
        holds: rows(rest.holds, h => ({ id: str(h.id), words: str(h.words), where: str(h.where) })),
        counts: rows(rest.counts, c => ({ n: num(c.n), words: str(c.words) })),
      },
      plan: {
        releases: rows(plan.releases, r => ({
          n: num(r.n),
          name: str(r.name),
          accepted: num(r.accepted),
          steps: rows(r.steps, s => ({ id: str(s.id), name: str(s.name), state: str(s.state), fill: num(s.fill), flag: str(s.flag) })),
          say: str(r.say),
          stuck: str(r.stuck),
          words: str(r.words),
        })),
        hold: {
          open: num(hold.open),
          others: num(hold.others),
          built: num(hold.built),
          rows: rows(hold.rows, h => ({ flag: str(h.flag), id: str(h.id), name: str(h.name), who: str(h.who), done: num(h.done), pieces: num(h.pieces), state: str(h.state), days: num(h.days), by: num(h.by) })),
        },
      },
      teams: rows(o.teams, t => ({
        name: str(t.name),
        kind: str(t.kind) === 'other' ? 'other' : 'team',
        area: str(t.area),
        words: str(t.words),
        releases: rows(t.releases, r => ({ n: num(r.n), name: str(r.name), words: str(r.words), tracks: rows(r.tracks, k => ({ name: str(k.name), cards: rows(k.cards, card) })) })),
      })),
    },
  }
}

// A line is the sort's: the same ids sorted again are a new line. Its number is never what names it.
export const lineKey = (l: List, t: ListTodo): string => `${l.sortedAt}|${t.ids.join(',')}`
export const keyPart = (t: ListTodo): string => t.ids.join('-')
export const ofSort = (l: List, key: string): boolean => key.startsWith(l.sortedAt + '|')

// What a press says, as the owner's words.
export function sayLine(t: ListTodo, answers: string[]): string {
  return `${t.n} · ${t.title}: ${answers.join('; ')} (${t.ids.join(', ')})`
}

// A question's choices as drawn: ViD's own first; a message with none is answered as sent.
export function choicesOf(a: ListAsk): { n: number; words: string; pick: boolean }[] {
  const all = (a.choices.length ? a.choices : ['Sent']).map((words, i) => ({ n: i + 1, words, pick: a.choices.length > 0 && a.choose === i + 1 }))
  return [...all.filter(c => c.pick), ...all.filter(c => !c.pick)]
}

// A press on a choice: the answers to send once every question of the line has one, else none yet.
export function answersOf(t: ListTodo, picks: Record<string, string>): string[] | null {
  const out = t.asks.map((_, i) => picks[String(i)] ?? '')
  return out.length && out.every(x => x !== '') ? out : null
}

// The line drawn open: the one the owner opened, else the first not sent; none once they closed it.
export function openKey(l: List, m: ListMarks): string {
  const left = l.todo.filter(t => !m.sent[lineKey(l, t)]).map(t => lineKey(l, t))
  if (m.open && left.includes(m.open)) return m.open
  return m.shut ? '' : (left[0] ?? '')
}

// The receipts the store holds of this sort, with those this panel is sending now.
export function receipts(l: List, stored: Record<string, Said>, mine: Record<string, Said>): Record<string, Said> {
  const out: Record<string, Said> = {}
  for (const [k, s] of Object.entries(stored)) if (ofSort(l, k)) out[k] = s
  for (const [k, s] of Object.entries(mine)) if (ofSort(l, k) && s.how === 'sending') out[k] = s
  return out
}

export const many = (n: number, one: string, more = one + 's'): string => `${n} ${n === 1 ? one : more}`

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
// '2026-11-20T15:03:00Z' as '20 November, 15:03 UTC'; '2026-11-17' as '17 Nov'; anything else as it stands
export function dayTime(t: string): string {
  const m = /^\d{4}-(\d\d)-(\d\d)T(\d\d:\d\d)/.exec(t)
  return m ? `${Number(m[2])} ${MONTHS[Number(m[1]) - 1] ?? ''}, ${m[3]} UTC` : t
}
export function day(t: string): string {
  const m = /^\d{4}-(\d\d)-(\d\d)/.exec(t)
  return m ? `${Number(m[2])} ${(MONTHS[Number(m[1]) - 1] ?? '').slice(0, 3)}` : t
}
export const ago = (n: number): string => (n < 1 ? 'today' : `${many(n, 'day')} ago`)

// The states in the order of the legend; what each is called there, on a card, and on a box.
export const STATES: { state: string; legend: string; card: string; box: string }[] = [
  { state: 'accepted', legend: 'accepted', card: 'Accepted', box: 'accepted' },
  { state: 'building', legend: 'being built, filled by the pieces done', card: 'Being built', box: 'being built' },
  { state: 'taken', legend: 'taken, no pieces yet', card: 'Taken', box: 'taken' },
  { state: 'nobody', legend: 'sent to the team, nobody has it', card: 'Nobody has it', box: 'sent, nobody has it' },
  { state: 'unsent', legend: 'not sent yet', card: 'Not sent yet', box: 'not sent yet' },
]
export const cardState = (s: string): string => STATES.find(x => x.state === s)?.card ?? s
export function boxAlt(s: ListStep): string {
  const w = STATES.find(x => x.state === s.state)?.box ?? s.state
  return `${s.name || s.id}: ${w}${s.state === 'building' ? `, ${s.fill}% of its pieces done` : ''}`
}

export function holdLine(h: { open: number; others: number; built: number; rows: ListHold[] }): string {
  const n = h.rows.length
  const these = n === 1 ? 'This 1 waits on nothing' : `These ${n} wait on nothing`
  const rest = h.others ? `; ${h.built} of the other ${h.others} ${h.built === 1 ? 'builds' : 'build'} on ${n === 1 ? 'it' : 'them'}, directly or through other steps` : ''
  return `${many(h.open, 'step is', 'steps are')} not accepted. ${these}${rest}.`
}
// Who has a step that holds others up, and where it stands; stuck where nobody has it.
export function holdRow(h: ListHold): { words: string; stuck: string } {
  if (h.state === 'nobody') return { words: '', stuck: `Nobody has it, ${many(h.days, 'day')}.` }
  if (h.state === 'unsent') return { words: 'Not sent to the team yet', stuck: '' }
  const who = h.who || 'No name on it'
  return { words: h.pieces ? `${who}; ${h.done} of ${h.pieces} pieces done` : `${who}; no pieces yet`, stuck: '' }
}

export const since = (t: string): string => (!t ? '' : /^since\b/i.test(t) ? t : `since ${t}`)
// the web addresses in a line's numbers and links
export const links = (t: string): string[] => [...new Set((t.match(/https?:\/\/[^\s)>\]"”]+/g) ?? []).map(x => x.replace(/[.,;:]+$/, '')))]
