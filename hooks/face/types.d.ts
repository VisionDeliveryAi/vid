// ViD's face (0.26.10.29): the panel's data, as checks/face.sh writes it,
// and the values the panel keeps. Every field is always set (no undefined:
// the desktop app refuses a drawing that hands one on).

// usability (P7): a seventh kind, `alone`: each item one question asked on its own
export type Kind = 'text' | 'questions' | 'list' | 'objections' | 'decided' | 'figures' | 'alone'
export type Act = { id: string; label: string; words: boolean }
// usability (P1, P7): preset is the answer an item starts at (`choose:<choice>`, `<act>` or `<act>:<words>`, "" for
// none), presetBy who set it (`vid`: ViD's recommendation for the item; `standing`: its section's standing act);
// alone, asked on its own; norecommend, ViD said it has none
// usability (P10): about, the <section>/<item> a finding is about, or ""
// 0.26.10.29.6 (S10): look, why ViD points to the item (one of three), or ""; the pointed items come first in their section
export type FaceItem = { id: string; text: string; detail: string[]; recommend: string; choices: string[]; value: string; preset: string; presetBy: string; alone: boolean; norecommend: boolean; about: string; look: string }
export type FaceSection = { id: string; kind: Kind; title: string; source: string; empty: boolean; why: string; acts: Act[]; items: FaceItem[] }
export type Sitting = {
  format: number
  sitting: string
  stop: number
  session: string
  written: string
  state: string
  ended: string
  title: string
  send: string
  closing: string
  // usability (P12): the short phrase for when it waits
  ready: string
  sections: FaceSection[]
}
// usability (P11): agreed, the line of what was agreed at a done stop ("Done" with none), "" for a stop not done
export type Stop = { n: number; name: string; state: string; sitting: boolean; agreed: string }
// usability (P6): the wait's parts, each done, now or to come (FB-3 D2: or stopped), and what ViD is doing; FB-3 D2: stop,
// what a call that stopped needs, "" for none; written, when the parts were last written (UTC), "" where not said
export type WaitPart = { name: string; state: string }
export type Wait = { parts: WaitPart[]; now: string; stop: string; written: string }
// FB-3 D1: an item of the owner's list, its empty fields ""; the list, null outside ticket mode: the open items in order,
// the newest done and how many are done
export type BacklogItem = { id: string; state: string; who: string; words: string; next: string; note: string }
export type Backlog = { items: BacklogItem[]; done: BacklogItem[]; doneCount: number }
// usability (P9): a page of the pages script's index: its id, title, file's full path, link ("" for none), the stops due
export type Page = { id: string; title: string; file: string; link: string; stops: number[] }
export type Standing = { format: number; written: string; current: number; turn: string; sitting: string; session: string; next: string; wait: Wait; backlog: Backlog | null; pages: Page[]; stops: Stop[] }
// usability (P4): .vid/face/run.<session id>, as the hooks and the recorder write it
export type Run = { state: string; since: string; last: string }

// What the person has marked on one sitting, not yet sent; then what was sent. A mark is keyed by its
// section and item (`<section>/<item>`): one item may be in two sections.
export type Marks = {
  a: Record<string, string>
  w: Record<string, string>
  note: Record<string, string>
  open: Record<string, boolean>
  noteOpen: Record<string, boolean>
  only: Record<string, boolean>
  sentAt: string
  sentText: string
  sentHow: string
  raw: boolean
  ids: boolean
  refused: string
  // FB-5 A1: the part on show of a section too long to draw whole, from 0
  part?: Record<string, number>
}

// FB-5 A1: the owner's list, .vid/face/list.json as the list's writer makes it from the last sort, the plan and the read. state:
// sorted, stale (something came or changed since) or none (never sorted). A line's ids are the backlog's; its number means it
// until the next sort. choose is the number of the choice ViD would take, 0 for none.
export type ListAsk = { ask: string; about: string; choose: number; why: string; choices: string[]; message: string }
export type ListTodo = { n: string; ids: string[]; title: string; do: string; isNew: boolean; new: string; what: string; asks: ListAsk[]; then: string; details: string }
export type ListWait = { who: string; what: string; since: string; details: string }
export type ListRest = {
  vid: string[]
  later: { when: string; what: string }[]
  team: string[]
  suggested: string[]
  leftOut: string[]
  holds: { id: string; words: string; where: string }[]
  counts: { n: number; words: string }[]
}
// a step's state: accepted, building, taken, nobody or unsent; fill, its pieces done, 0 to 100; flag, its letter in what
// holds the rest up, the same on its row, its box and its card, "" for none
export type ListStep = { id: string; name: string; state: string; fill: number; flag: string }
export type ListRelease = { n: number; name: string; accepted: number; steps: ListStep[]; say: string; stuck: string; words: string }
export type ListHold = { flag: string; id: string; name: string; who: string; done: number; pieces: number; state: string; days: number; by: number }
export type ListCard = {
  id: string
  name: string
  flag: string
  state: string
  ticket: number
  url: string
  done: number
  pieces: number
  who: string
  ready: number
  drafts: number
  pulls: { n: number; url: string; draft: boolean }[]
  sent: string
  days: number
  buildsOn: string[]
  holdsUp: number
  tests: number
  testIds: string[]
  notes: string[]
}
export type ListTeam = { name: string; kind: string; area: string; words: string; releases: { n: number; name: string; words: string; tracks: { name: string; cards: ListCard[] }[] }[] }
export type List = {
  format: number
  written: string
  title: string
  state: string
  sortedAt: string
  unsorted: number
  todo: ListTodo[]
  waiting: ListWait[]
  changed: string[]
  rest: ListRest
  plan: { releases: ListRelease[]; hold: { open: number; others: number; built: number; rows: ListHold[] } }
  teams: ListTeam[]
}
// FB-5 A1: what the owner pressed on the list. A line is known by the sort's time and its ids: sent holds the answers given, asked
// the lines put as a question, both kept in the store for every conversation; picks, refused, open, shut and shown are the
// panel's alone (open "" the first line not sent; shut, all closed by the owner; shown, what is folded out).
export type Said = { at: string; how: string; words: string }
export type ListMarks = {
  sent: Record<string, Said>
  asked: Record<string, Said>
  picks: Record<string, Record<string, string>>
  refused: Record<string, string>
  open: string
  shut: boolean
  shown: Record<string, boolean>
}

// What the panel read last: its files, or why it cannot show them; and the minute it read them in.
export type View = {
  standing: Standing | null
  sitting: Sitting | null
  run: Run | null
  // FB-7 B6: this conversation's run in GitHub auto is on, by RUN-STATE
  active: boolean
  // FB-5 A1: the owner's list, null for none, and why it cannot be drawn, "" for nothing wrong
  list: List | null
  listProblem: string
  problem: string
  project: boolean
  here: string
  version: string
  opened: string
  // FB-3 D1: the conversation it opened by itself in for the backlog, "" for none
  ranOpen: string
  minute: number
  // usability (P5): when it was read, in ms, by the engine's clock
  now: number
  // usability (P11): the stop the map last moved on from and to, and when (ms); to 0 for none
  moved: { from: number; to: number; at: number }
}

declare module 'claude-code' {
  interface PluginState {
    vid: {
      view: Shaped<View>
      marks: Shaped<Record<string, Marks>>
      list: Shaped<ListMarks>
    }
  }
}
