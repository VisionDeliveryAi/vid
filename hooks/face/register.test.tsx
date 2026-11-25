import { expect, mock, test } from 'claude-code/testing'

import { goTo } from './go'
import { DRAFT, DRAFT_STANDING, ENDED, INTERVIEW, INTERVIEW_F1, INTERVIEW_STANDING, PAUSE1_47, PAUSE1_STANDING, PAUSE2, PAUSE2_STANDING, DESIGN_STANDING, WORKING_STANDING, LIST_DATA } from './samples'

// ViD's face (0.26.10.29): the panel drawn as the desktop app draws it. Each
// hook here stands for the engine: the project's files, the session, the
// prompt. Every test names the requirement it proves.

const ROOT = '/project'
type World = { clock?: boolean; standing?: string; sitting?: string; run?: string; list?: string; panes?: { id: string; title: string }[]; session?: string; surfaces?: string[]; version?: string; vid?: boolean; drop?: string; unfilled?: boolean }
type Log = { submits: string[]; asUser: boolean[]; fills: string[]; modes: string[]; opens: any[]; writes: { path: string; text: string }[]; files: Record<string, string>; notices: string[] }

function world(on: any, w: World, log: Log) {
  const files = log.files
  const sess = w.session ?? 'sess-A'
  if (w.standing !== undefined) files[`${ROOT}/.vid/face/standing.json`] = w.standing
  if (w.sitting !== undefined) files[`${ROOT}/.vid/face/sitting.json`] = w.sitting
  if (w.run !== undefined) files[`${ROOT}/.vid/face/run.${sess}`] = w.run
  if (w.list !== undefined) files[`${ROOT}/.vid/face/list.json`] = w.list
  const vid = w.vid !== false
  on('session.root', () => ({ value: ROOT }))
  on('session.id', () => ({ value: sess }))
  on('session.surfaces', () => ({ value: w.surfaces ?? ['desktop'] }))
  on('session.version', () => ({ value: { version: w.version ?? '2.1.321', base: w.version ?? '2.1.321' } }))
  on('fs.exists', (_: any, e: any) => ({ value: e.path in files || (vid && e.path === `${ROOT}/.vid`) }))
  on('fs.read', (_: any, e: any) => (e.path in files ? { value: files[e.path] } : { error: 'ENOENT' }))
  on('fs.write', (_: any, e: any) => {
    files[e.path] = e.text
    log.writes.push({ path: e.path, text: e.text })
    return { value: undefined }
  })
  on('command.register', () => ({ value: { command: 'vid-panel' } }))
  // usability (P5): a test that moves the clock uses the kit's mocked clock in place of these two
  if (!w.clock) {
    on('clock.every', () => ({ value: undefined }))
    on('clock.now', () => ({ value: Date.now() }))
  }
  const panes = w.panes ?? []
  on('ui.open', (_: any, e: any) => {
    log.opens.push(e)
    const p = panes.find(x => x.id === e.id)
    if (p) p.title = e.title ?? e.id
    else panes.push({ id: e.id, title: e.title ?? e.id })
    return { value: { isPlaced: true } }
  })
  on('ui.panes', () => ({ value: panes.map(p => ({ ...p, isShown: true, isFocused: false, isPlaced: true })) }))
  on('ui.toast', (_: any, e: any) => {
    log.notices.push(String(e.text ?? e))
    return { value: undefined }
  })
  on('prompt.submit', (_: any, e: any) => {
    log.submits.push(e.text)
    log.asUser.push(e.asUser === true || e.origin?.asUser === true)
    return w.drop ? { drop: w.drop } : { text: e.text }
  })
  on('prompt.fill', (_: any, e: any) => {
    log.fills.push(e.text)
    log.modes.push(e.mode)
    return { isFilled: !w.unfilled }
  })
  on('turn.complete', (_: any, e: any) => ({ text: e.answer }))
  on('session.start', (_: any, e: any) => ({ cwd: e.cwd }))
}

const PANE = (surface: 'desktop' | 'terminal' | 'vscode' | 'mobile', columns = 60) =>
  ({
    plugin: 'vid',
    component: 'Pane',
    requestId: 'vid',
    surface,
    props: { title: 'ViD', isFocused: false, bodyColumns: columns, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
  }) as const

const newLog = (): Log => ({ submits: [], asUser: [], fills: [], modes: [], opens: [], writes: [], files: {}, notices: [] })

async function start($: any, on: any, w: World, store: Record<string, unknown> = {}) {
  const log = newLog()
  world(on, w, log)
  mock.store(on, store)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  return log
}

const texts = async (ui: any): Promise<string[]> => (await ui.findAll({ type: 'Text' })).map((t: any) => t.text ?? '')

// usability (P4, P5): a run file, its times this many minutes ago (-1: no last step)
const utc = (minsAgo: number): string => new Date(Date.now() - minsAgo * 60000 - 10000).toISOString().replace(/\.\d+Z$/, 'Z')
const RUN = (state: string, since: number, last = -1): string => `${state} ${utc(since)} ${last < 0 ? '-' : utc(last)}\n`
const RUNNING = RUN('running', 5, 2)
const STOPPED = RUN('stopped', 1, 3)

// a sitting changed for one test: fn edits the parsed sitting
const edited = (text: string, fn: (s: any) => void): string => {
  const s = JSON.parse(text)
  fn(s)
  return JSON.stringify(s)
}
const sec = (s: any, id: string) => s.sections.find((x: any) => x.id === id)

test('R8 the map: done, here, to come, and the next stop', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2 })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await ui.find({ type: 'Text', text: 'Answer the gaps' }))?.text).toBe('Answer the gaps')
  expect((await ui.find({ type: 'Text', text: /^Step 4 of 9/ }))?.text).toBe('Step 4 of 9 · Your turn · Next: The final wording')
  const svg = await ui.find({ type: 'Svg' })
  expect(svg).toBeDefined()
  await ui.unmount()
})

test('R9 every item drawn once, under its sitting, in ViD order', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2 })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  const s = JSON.parse(PAUSE2)
  let at = -1
  for (const sec of s.sections) {
    for (const it of sec.items) {
      const shown = sec.kind === 'figures' ? it.text.charAt(0).toUpperCase() + it.text.slice(1) : it.text
      const hits = all.filter(t => t === shown)
      expect(hits.length).toBe(1)
      const i = all.indexOf(shown)
      expect(i).toBeGreaterThan(at)
      at = i
    }
  }
  await ui.unmount()
})

test('R10 the acts offered are exactly the sitting’s, and every list has a field for own words', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const s = JSON.parse(PAUSE1_47)
  const buttons = (await ui.findAll({ type: 'Button' })).map((b: any) => b.key ?? '')
  for (const sec of s.sections) {
    if (sec.kind !== 'list' && sec.kind !== 'objections') continue
    for (const it of sec.items) {
      const keys = buttons.filter((k: string) => k.startsWith(`${sec.id}/${it.id}-`))
      expect(keys.sort()).toEqual(sec.acts.map((a: any) => `${sec.id}/${it.id}-${a.id}`).sort())
    }
    expect(await ui.find({ type: 'Button', key: `${sec.id}-note` })).toBeDefined()
  }
  await ui.unmount()
})

test('R11 one message, sent only on send, plain words naming each item by id', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.press({ key: 'challenge/C1-keep' })
  await ui.press({ key: 'questions/Q2-pick' })
  expect(log.submits).toHaveLength(0)
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(1)
  const m = log.submits[0]!
  expect(m).toMatch(/^The interview: my answers, from ViD's panel\./)
  expect(m).toContain('Q1 Who is the digest for?: Recruiters.')
  expect(m).toContain('Q2 How often does it go out?: You pick.')
  expect(m).toContain('C1 Synonym-aware search: Keep.')
  expect(m).not.toMatch(/[{}"]/)
  await ui.unmount()
})

test('R12 after sending the panel shows what was sent and takes no second answer', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.press({ key: 'send' })
  expect(await ui.find({ type: 'Text', text: /^Sent to ViD at / })).toBeDefined()
  expect((await ui.find({ type: 'Text', text: 'Recruiters' }))?.text).toBe('Recruiters')
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeUndefined()
  expect(await ui.find({ type: 'Button', key: 'questions/Q1-c0' })).toBeUndefined()
  expect(log.submits).toHaveLength(1)
  await ui.unmount()
})

test('R13 a mark and its counts show in the same drawing, the row keeping its buttons', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const before = (await ui.findAll({ type: 'Button' })).filter((b: any) => (b.key ?? '').startsWith('contract/DIM-q01-')).length
  await ui.press({ key: 'contract/DIM-q01-out' })
  expect((await ui.find({ type: 'Text', text: /^Doesn't need it 1$/ }))?.text).toBe("Doesn't need it 1")
  expect((await ui.find({ type: 'Text', text: /^Needs it 46$/ }))?.text).toBe('Needs it 46')
  expect((await ui.find({ type: 'Text', text: /^Not marked 0$/ }))?.text).toBe('Not marked 0')
  expect((await ui.find({ type: 'Text', text: /^47 of 47 marked$/ }))?.text).toBe('47 of 47 marked')
  expect((await ui.findAll({ type: 'Button' })).filter((b: any) => (b.key ?? '').startsWith('contract/DIM-q01-')).length).toBe(before)
  await ui.unmount()
})

test('R14 marks not sent survive a restart, and never appear on another sitting', async ($, on) => {
  const kept: Record<string, unknown> = {}
  const log = newLog()
  world(on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW }, log)
  on('store.get', (_: any, e: any) => ({ value: kept[e.key] }))
  on('store.set', (_: any, e: any) => {
    kept[e.key] = JSON.parse(JSON.stringify(e.value))
    return { value: undefined }
  })
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.unmount()
  const k = Object.keys(kept.marks as object)
  expect(k).toHaveLength(1)
  expect(JSON.stringify(kept.marks)).toContain('choose:Recruiters')
})

test('R14 a restarted panel takes the marks back from the store', async ($, on) => {
  const s = JSON.parse(INTERVIEW)
  const key = `${s.sitting}|${s.session}|${s.written}`
  const m = { a: { 'questions/Q1': 'choose:Recruiters' }, w: {}, note: {}, open: {}, noteOpen: {}, only: {}, sentAt: '', sentText: '', sentHow: '', raw: false, ids: false, refused: '' }
  await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW }, { marks: { [key]: m, 'pause-1|sess-A|old': m } })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await ui.find({ type: 'Text', text: /^1 of 2 answered$/ }))?.text).toBe('1 of 2 answered')
  await ui.unmount()
})

test('R15 a sitting another conversation presented is never sent: the words go to the message box', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, session: 'sess-B' })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(0)
  expect(log.fills).toHaveLength(1)
  expect(log.fills[0]).toContain('Q1 Who is the digest for?: Recruiters.')
  expect(await ui.find({ type: 'Text', text: /^Put in your message box at / })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /not the one where ViD asked/ })).toBeDefined()
  await ui.unmount()
})

test('R16 P4 a stop outside the sittings shows the map; stopped there, the panel says so', async ($, on) => {
  await start($, on, { standing: DESIGN_STANDING, sitting: ENDED, run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await ui.find({ type: 'Text', text: 'The design' }))?.text).toBe('The design')
  expect(await ui.find({ type: 'Text', text: 'ViD has stopped. Look at the chat.' })).toBeDefined()
  expect(await ui.find({ type: 'Svg' })).toBeDefined()
  await ui.unmount()
})

test('R17 a format it does not know, a file it cannot read, another Claude Code: one plain line', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2.replace('"format":2', '"format":3') })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: "This panel can't show this sitting" })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'It was written by a newer ViD than this panel can read.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /format/ })).toBeUndefined()
  await ui.unmount()
})

test('R17 a half-read file is said, never drawn half', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2.slice(0, 200) })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: /not whole JSON/ })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeUndefined()
  await ui.unmount()
})

test('R17 a Claude Code it was not written for is said in one line', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2, version: '2.1.400' })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: /^Written for Claude Code 2\.1\.321; this is 2\.1\.400\./ })).toBeDefined()
  await ui.unmount()
})

test('R18 nothing of the panel appears outside the desktop app', async ($, on) => {
  on('ui.render', ($2: any, e: any) => {
    const { Text } = $2.ui.resolve(e)
    return <Text>engine</Text>
  })
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, surfaces: ['terminal'] })
  expect(log.opens).toHaveLength(0)
  for (const surface of ['terminal', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount(PANE(surface))
    expect((await ui.find({ type: 'Text' }))?.text).toBe('engine')
    expect(await ui.find({ type: 'Button', key: 'send' })).toBeUndefined()
    await ui.unmount()
  }
  const r = await $.command.run({ command: 'vid-panel', args: '' })
  expect(JSON.stringify(r)).toContain('desktop app only')
  expect(log.opens).toHaveLength(0)
})

test('R19 it opens by itself when a sitting waits, never with the keys, and by the command', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW })
  expect(log.opens).toHaveLength(1)
  expect(log.opens[0].focus).toBeUndefined()
  await $.command.run({ command: 'vid-panel', args: '' })
  expect(log.opens).toHaveLength(2)
})

test('R19 it does not open by itself in a folder that is not a ViD project, nor when nothing waits', async ($, on) => {
  const log = await start($, on, { vid: false })
  expect(log.opens).toHaveLength(0)
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'No ViD project here' })).toBeDefined()
  await ui.unmount()
})

test('R19 nothing waits: no open', async ($, on) => {
  const log = await start($, on, { standing: WORKING_STANDING, sitting: ENDED })
  expect(log.opens).toHaveLength(0)
})

test('R21 R22 what waits stands first; the send keys; R23 47 items: count, filter, send at the foot', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all.indexOf('Waits on you')).toBeGreaterThanOrEqual(0)
  expect(all.indexOf('Product summary')).toBeGreaterThanOrEqual(0)
  expect(all.indexOf('Waits on you')).toBeLessThan(all.indexOf('Product summary'))
  expect(all.indexOf('Waits on you')).toBeLessThan(all.indexOf('The qualities it must have'))
  const send = await ui.find({ type: 'Button', key: 'send' })
  expect(send?.props?.hotkey).toBe('s')
  const only = await ui.find({ type: 'Button', key: 'contract-only' })
  expect(only?.props?.hotkey).toBe('u')
  expect(await ui.find({ type: 'Button', key: 'contract-send' })).toBeDefined()
  await ui.press({ key: 'contract/DIM-q02-in' })
  await ui.press({ key: 'contract-only' })
  expect(await ui.find({ type: 'Button', key: 'contract/DIM-q02-in' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'contract/DIM-q03-in' })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: 'Show all 47' })).toBeDefined()
  await ui.unmount()
})

test('R25 P4 P5 ViD is working: the stop, the time and the last step', async ($, on) => {
  await start($, on, { standing: WORKING_STANDING, sitting: ENDED, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: /^ViD is working on the final wording$/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Working for 5 min' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Last step 2 min ago' })).toBeDefined()
  for (const t of await texts(ui)) expect(t).not.toMatch(/%/)
  expect(await ui.find({ type: 'Progress' })).toBeUndefined()
  await ui.unmount()
})

test('R27 no id or line format on a card unless asked', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2 })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  for (const t of all) {
    expect(t).not.toMatch(/\b(REQ|INV|OQ|DIM|FEAT|A|F)-[A-Za-z0-9]/)
    expect(t).not.toMatch(/ \| /)
  }
  await ui.press({ key: 'ids' })
  expect((await texts(ui)).some(t => /\bOQ-3\b/.test(t))).toBe(true)
  await ui.unmount()
})

test('every surface the plugin draws on is handed no undefined field', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  for (const cols of [44, 120]) {
    const ui = await $.ui.mount(PANE('desktop', cols))
    const tree = await ui.drawn()
    expect(tree).toBeDefined()
    await ui.unmount()
  }
})

// a rule in two sections, one key, a refused send, a send from another conversation
const withFeatures = (n: number): string => {
  const s = JSON.parse(PAUSE1_47)
  const f = s.sections.find((x: any) => x.id === 'features')
  while (f.items.length < n) f.items.push({ ...f.items[0], id: `FEAT-9${f.items.length}`, text: `Feature ${f.items.length}` })
  return JSON.stringify(s)
}

test('R24 U is one key: on the longest list only, however many lists have four items or more', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: withFeatures(4) })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const u = (await ui.findAll({ type: 'Button' })).filter((b: any) => b.props?.hotkey === 'u').map((b: any) => b.key)
  expect(u).toEqual(['contract-only'])
  await ui.unmount()
})

test('R27 feature rows and decisions show no goal, tier or grounding codes', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  for (const t of await texts(ui)) {
    expect(t).not.toMatch(/\bT[0-2]\b|\bG[0-9]+\b|grounds /)
  }
  await ui.unmount()
})

test('R12 an answer the engine refused is not shown as sent, and can be sent again', async ($, on) => {
  const kept: Record<string, unknown> = {}
  on('store.get', (_: any, e: any) => ({ value: kept[e.key] }))
  on('store.set', (_: any, e: any) => {
    kept[e.key] = JSON.parse(JSON.stringify(e.value))
    return { value: undefined }
  })
  const log = newLog()
  world(on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, drop: 'the session is busy' }, log)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(1)
  expect(await ui.find({ type: 'Text', text: /^Sent to ViD at / })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /the session is busy/ })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeDefined()
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(2)
  await ui.unmount()
})

test('R11 R12 a sitting another conversation already sent is shown sent, and not sent again', async ($, on) => {
  const s = JSON.parse(INTERVIEW)
  const key = `${s.sitting}|${s.session}|${s.written}`
  const sent = { a: { 'questions/Q1': 'choose:Job seekers' }, w: {}, note: {}, open: {}, noteOpen: {}, only: {}, sentAt: '14:02', sentText: 'x', sentHow: 'sent', raw: false, ids: false, refused: '' }
  const kept: Record<string, unknown> = { marks: {} }
  const log = newLog()
  world(on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW }, log)
  on('store.get', (_: any, e: any) => ({ value: kept[e.key] }))
  on('store.set', (_: any, e: any) => {
    kept[e.key] = JSON.parse(JSON.stringify(e.value))
    return { value: undefined }
  })
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  kept.marks = { [key]: sent }
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(0)
  expect(JSON.stringify(kept.marks)).toContain('"sentAt":"14:02"')
  expect(await ui.find({ type: 'Text', text: /Job seekers/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Recruiters/ })).toBeUndefined()
  await ui.unmount()
})

// a refused fill, plain lines kept
test('R12 R15 words the app did not put in the message box are not shown as put there', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, session: 'sess-B', unfilled: true })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-c1' })
  await ui.press({ key: 'send' })
  expect(log.fills).toHaveLength(1)
  expect(await ui.find({ type: 'Text', text: /^Put in your message box at / })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /^Not sent: / })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeDefined()
  await ui.unmount()
})

test('R27 a line of plain words that mentions grounds or a goal is drawn', async ($, on) => {
  const text = edited(PAUSE1_47, s => {
    sec(s, 'findings').items[0].detail = ['Overrule it on the grounds that the archive is public, as for T2 and G1 before.']
  })
  await start($, on, { standing: PAUSE1_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Text', text: /on the grounds that the archive is public/ })).toBeDefined()
  await ui.unmount()
})

// the look, against the design
test('polish: "To read" stands after the last thing to answer; empty sections in one line; scorecard labels as words', async ($, on) => {
  await start($, on, { standing: PAUSE2_STANDING, sitting: PAUSE2 })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  expect(all.lastIndexOf('To read')).toBeGreaterThan(all.indexOf('Each rule in plain words'))
  expect(all.filter(t => t === 'None at this pause.')).toHaveLength(0)
  expect(all.some(t => /^Nothing at this pause: /.test(t))).toBe(true)
  expect(all).toContain('Faithful')
  expect(all.indexOf('Waits on you')).toBeGreaterThanOrEqual(0)
  await ui.unmount()
})

test('polish: ViD suggests, the version line at the foot', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47, version: '2.1.400' })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all).toContain('ViD suggests fix it: within one day')
  expect(all.findIndex(t => t.startsWith('Written for Claude Code'))).toBeGreaterThan(all.indexOf("The critic's findings"))
  await ui.unmount()
})

test('polish: the own answer sits in an outlined box', async ($, on) => {
  await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q1-write' })
  await ui.input({ key: 'questions/Q1-words', text: 'Graduates' })
  const boxes = (await ui.findAll({ type: 'Box' })).filter((b: any) => b.props?.borderColor === 'claude')
  expect(boxes.length).toBeGreaterThan(0)
  await ui.unmount()
})

// --- usability, release A ------------------------------------------------------------------------------------

test('P1 every item starts at its preset, said beside it; the foot counts what was changed and what needs an answer', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  // 47 qualities, 3 features, 1 finding: every one at a preset; the summary and the empty decisions are not counted
  expect((await texts(ui)).filter(t => t === "ViD's recommendation")).toHaveLength(51)
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 51. 0 need your answer.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Needs your answer' })).toBeUndefined()
  await ui.press({ key: 'findings/F-01-fix' })
  await ui.press({ key: 'contract/DIM-q05-out' })
  expect((await texts(ui)).filter(t => t === 'You changed 2 of 51. 1 needs your answer.').length).toBeGreaterThan(0)
  expect((await texts(ui)).filter(t => t === 'Needs your answer')).toHaveLength(1)
  expect((await texts(ui)).filter(t => t === "ViD's recommendation")).toHaveLength(49)
  await ui.unmount()
})

test('P1 an item with no preset, or with no recommendation said outright, starts unanswered', async ($, on) => {
  const text = edited(INTERVIEW, s => {
    sec(s, 'challenge').items.push({ id: 'C2', text: 'The archive', detail: [], recommend: '', choices: [], value: '', preset: '', presetBy: '', alone: false, norecommend: true })
  })
  await start($, on, { standing: INTERVIEW_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await texts(ui)).filter(t => t === 'Needs your answer')).toHaveLength(2)
  expect(await ui.find({ type: 'Text', text: 'ViD has no recommendation' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 4. 2 need your answer.' })).toBeDefined()
  await ui.unmount()
})

test('P1 the message: the changes, then as ViD recommended, left as ViD wrote them, not answered', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'contract/DIM-q01-out' })
  await ui.press({ key: 'findings/F-01-fix' })
  await ui.press({ key: 'send' })
  const m = log.submits[0]!
  const lines = m.split('\n')
  const at = (l: string) => lines.indexOf(l)
  expect(at("DIM-q01 Quality number 1 holds for every subscriber: Doesn't need it.")).toBeGreaterThan(at('The qualities it must have:'))
  const left = lines.find(l => l.startsWith('Left as ViD wrote them: DIM-q02, DIM-q03'))!
  expect(left).toBeDefined()
  expect(left).not.toContain('DIM-q01')
  expect(at(left)).toBeGreaterThan(at("DIM-q01 Quality number 1 holds for every subscriber: Doesn't need it."))
  expect(lines).toContain('Left as ViD wrote them: FEAT-01, FEAT-02, FEAT-03.')
  expect(at('Not answered: F-01.')).toBeGreaterThan(at("The critic's findings:"))
  expect(m).not.toContain('As ViD recommended: F-01')
  await ui.unmount()
})

test('P1 an answer never touched is sent as ViD recommended, apart from the person’s own', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'questions/Q2-c0' })
  await ui.press({ key: 'send' })
  const m = log.submits[0]!
  expect(m).toContain('Q2 How often does it go out?: Daily.')
  expect(m).toContain('As ViD recommended: Q1 (Job seekers).')
  expect(m).toContain('As ViD recommended: C1 (Cut).')
  expect(m).not.toContain('Q1 Who is the digest for?: Job seekers.')
  expect(m).not.toContain('Not answered')
  await ui.unmount()
})

test('P1 a decision is never counted, never said to need an answer, and stands', async ($, on) => {
  const text = edited(PAUSE1_47, s => {
    const d = sec(s, 'decisions')
    d.empty = false
    d.why = ''
    d.items = [{ id: 'A-005', text: 'Digests go out at seven', detail: [], recommend: '', choices: [], value: '', preset: '', presetBy: '', alone: false, norecommend: false }]
  })
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 51. 0 need your answer.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Needs your answer' })).toBeUndefined()
  await ui.press({ key: 'send' })
  expect(log.submits[0]!).not.toMatch(/Not answered: A-005/)
  await ui.unmount()
})

test('P1 a format-1 sitting is still drawn', async ($, on) => {
  await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW_F1 })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'Who is the digest for?' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: "This panel can't show this sitting" })).toBeUndefined()
  expect((await texts(ui)).filter(t => t === 'Needs your answer')).toHaveLength(3)
  await ui.unmount()
})

test('P2 "As recommended": on a section with a change, for the whole sitting with A, never sending', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Button', key: 'contract-as-recommended' })).toBeUndefined()
  expect(await ui.find({ type: 'Button', key: 'as-recommended' })).toBeUndefined()
  await ui.press({ key: 'contract/DIM-q01-out' })
  await ui.press({ key: 'features/FEAT-01-change' })
  expect(await ui.find({ type: 'Button', key: 'contract-as-recommended' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'findings-as-recommended' })).toBeUndefined()
  await ui.press({ key: 'contract-as-recommended' })
  expect(await ui.find({ type: 'Text', text: 'You changed 1 of 51. 0 need your answer.' })).toBeDefined()
  const all = await ui.find({ type: 'Button', key: 'as-recommended' })
  expect(all?.props?.hotkey).toBe('a')
  await ui.press({ key: 'contract/DIM-q02-in' })
  await ui.press({ key: 'as-recommended' })
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 51. 0 need your answer.' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'as-recommended' })).toBeUndefined()
  expect(log.submits).toHaveLength(0)
  await ui.unmount()
})

test('P3 plain choices: Needs it and Doesn’t need it, Fix it and Leave it; the ruling kept on record', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all).toContain('Needs it')
  expect(all).toContain("Doesn't need it")
  expect(all).toContain('Leave it')
  for (const w of ['Strike', 'In', 'Out', 'Overrule']) expect(all).not.toContain(w)
  await ui.press({ key: 'contract/DIM-q03-out' })
  await ui.press({ key: 'send' })
  expect(log.submits[0]!).toContain("The qualities I marked 'Doesn't need it' are out; keep my ruling on record.")
  await ui.unmount()
})

test('P3 no quality marked Doesn’t need it: no ruling sentence', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'send' })
  expect(log.submits[0]!).not.toContain("Doesn't need it")
  await ui.unmount()
})

test('P4 running, at a stop with no sittings: working, and its questions come in the chat', async ($, on) => {
  await start($, on, { standing: DESIGN_STANDING, sitting: ENDED, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'ViD is working on the design' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: "This stop's questions come in the chat, not here." })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Working for 5 min' })).toBeDefined()
  await ui.unmount()
})

test('P4 stopped, at a stop with sittings: ViD has stopped, never working', async ($, on) => {
  await start($, on, { standing: WORKING_STANDING, sitting: ENDED, run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'ViD has stopped. Look at the chat.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'If it asked you something, the question is there. The next sitting shows here when ViD writes it.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /^ViD is working/ })).toBeUndefined()
  await ui.unmount()
})

test('P4 no file for its conversation: the session is taken as stopped', async ($, on) => {
  await start($, on, { standing: WORKING_STANDING, sitting: ENDED })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'ViD has stopped. Look at the chat.' })).toBeDefined()
  await ui.unmount()
})

test('P4 after a send: stopped while the sitting still waits, one line under the receipt; running, none', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, run: STOPPED })
  let ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(1)
  expect(await ui.find({ type: 'Text', text: /^Sent to ViD at / })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'ViD has stopped. Look at the chat.' })).toBeDefined()
  await ui.unmount()
})

test('P4 after a send while running: no stopped line', async ($, on) => {
  await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'send' })
  expect(await ui.find({ type: 'Text', text: 'ViD has stopped. Look at the chat.' })).toBeUndefined()
  await ui.unmount()
})

test('P4 a waiting sitting is drawn over a standing one stop behind', async ($, on) => {
  const behind = edited(PAUSE1_STANDING, s => {
    s.turn = 'vid'
    s.sitting = ''
    s.session = ''
  })
  await start($, on, { standing: behind, sitting: PAUSE2 })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'Waits on you' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeDefined()
  await ui.unmount()
})

test('P4 the recorder: a turn that ends, and one interrupted, write the file stopped, keeping the last step', async ($, on) => {
  const last = '2026-11-15T10:00:00Z'
  const log = await start($, on, { standing: WORKING_STANDING, sitting: ENDED, run: `running 2026-11-15T09:50:00Z ${last}\n` })
  await $.turn.complete({ answer: 'done', durationMs: 5, isAborted: false, turnId: 't1', reason: 'answer' })
  const mine = () => log.writes.filter(w => w.path === `${ROOT}/.vid/face/run.sess-A`)
  expect(mine()).toHaveLength(1)
  expect(mine()[0]!.text).toMatch(new RegExp(`^stopped \\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\dZ ${last}\\n$`))
  await $.turn.complete({ answer: '', durationMs: 5, isAborted: true, turnId: 't2', reason: 'aborted' })
  expect(mine()).toHaveLength(2)
  expect(mine()[1]!.text).toMatch(/^stopped /)
  expect(mine()[1]!.text).toContain(last)
  // a helper's turn is not the session's
  await $.turn.complete({ answer: '', durationMs: 5, isAborted: false, turnId: 't3', reason: 'answer', agentId: 'a1' })
  expect(mine()).toHaveLength(2)
})

test('P4 the recorder writes nothing where no standing is', async ($, on) => {
  const log = await start($, on, { sitting: ENDED })
  await $.turn.complete({ answer: '', durationMs: 5, isAborted: true, turnId: 't1', reason: 'aborted' })
  expect(log.writes).toHaveLength(0)
})

test('P5 before the first step of a turn there is no last-step line', async ($, on) => {
  await start($, on, { standing: WORKING_STANDING, sitting: ENDED, run: RUN('running', 3) })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'Working for 3 min' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /^Last step/ })).toBeUndefined()
  await ui.unmount()
})

test('P5 a last step under a minute ago is said so', async ($, on) => {
  await start($, on, { standing: WORKING_STANDING, sitting: ENDED, run: `running ${utc(4)} ${new Date().toISOString().replace(/\.\d+Z$/, 'Z')}\n` })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'Last step under a minute ago' })).toBeDefined()
  await ui.unmount()
})

test('P6 a wait of four parts with the second running', async ($, on) => {
  const st = edited(WORKING_STANDING, s => {
    s.wait = { parts: [{ name: 'Read the PRD', state: 'done' }, { name: 'Write the plain sentences', state: 'now' }, { name: 'Check them', state: 'to come' }, { name: 'Show you', state: 'to come' }], now: 'Writing the plain sentences for 11 rules' }
  })
  await start($, on, { standing: st, sitting: ENDED, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  expect(at('✓ Read the PRD')).toBeGreaterThan(at('Working for 5 min'))
  expect(at('● Write the plain sentences')).toBeGreaterThan(at('✓ Read the PRD'))
  expect(at('○ Check them')).toBeGreaterThan(at('● Write the plain sentences'))
  expect(at('○ Show you')).toBeGreaterThan(at('○ Check them'))
  expect(all).toContain('Now: Writing the plain sentences for 11 rules')
  await ui.unmount()
})

const aloneSitting = (): string =>
  edited(PAUSE1_47, s => {
    const f = sec(s, 'findings').items[0]
    f.alone = true
    f.preset = ''
    f.presetBy = ''
    const w = sec(s, 'withdrawn')
    w.empty = false
    w.why = ''
    w.items = [{ id: 'REQ-002~2', text: 'Every digest carries a working one-click unsubscribe', detail: ['stops all digests within one day', "arm 2 of REQ-002 withdrawn under ViD's draft A-005"], recommend: '', choices: ['Keep the check', 'Remove it'], value: '', preset: '', presetBy: '', alone: true, norecommend: false }]
  })

test('P7 asked on its own: never marked, never reached by As recommended; send only once each is answered', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: aloneSitting() })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect((await texts(ui)).filter(t => t === 'Asked on its own')).toHaveLength(2)
  expect(await ui.find({ type: 'Text', text: 'ViD suggests: Fix it: within one day' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeUndefined()
  expect(await ui.find({ type: 'Button', key: 'contract-send' })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: '2 questions asked on their own still need your answer.' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 50. 2 need your answer.' })).toBeDefined()
  await ui.press({ key: 'contract/DIM-q01-out' })
  await ui.press({ key: 'as-recommended' })
  expect(await ui.find({ type: 'Text', text: 'You changed 0 of 50. 2 need your answer.' })).toBeDefined()
  await ui.press({ key: 'withdrawn/REQ-002~2-c0' })
  expect(await ui.find({ type: 'Text', text: '1 question asked on its own still needs your answer.' })).toBeDefined()
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeUndefined()
  await ui.press({ key: 'findings/F-01-fix' })
  expect(await ui.find({ type: 'Button', key: 'send' })).toBeDefined()
  await ui.press({ key: 'send' })
  const m = log.submits[0]!
  expect(m).toContain('F-01 The unsubscribe has no time bound: Fix it.')
  expect(m).not.toContain('As ViD recommended: F-01')
  const lines = m.split('\n')
  expect(lines.indexOf('REQ-002~2 Every digest carries a working one-click unsubscribe: Keep the check.')).toBeGreaterThan(lines.indexOf('Asked on their own:'))
  await ui.unmount()
})

test('P14 words leave with their button: Change with words, then Fine, sends no words', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'features/FEAT-02-change' })
  await ui.input({ key: 'features/FEAT-02-words', text: 'Split it in two' })
  await ui.press({ key: 'features/FEAT-02-ok' })
  await ui.press({ key: 'send' })
  expect(log.submits[0]!).not.toContain('Split it in two')
  await ui.unmount()
})

test('P14 words stay with a button that takes them', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'features/FEAT-02-change' })
  await ui.input({ key: 'features/FEAT-02-words', text: 'Split it in two' })
  await ui.press({ key: 'send' })
  expect(log.submits[0]!).toContain('FEAT-02 synonym-aware search: Change: Split it in two.')
  await ui.unmount()
})

// --- usability, release C -------------------------------------------------------------------------------------

const critic = (): string =>
  edited(PAUSE1_47, s => {
    const f = sec(s, 'findings')
    const base = f.items[0]
    f.items = [
      { ...base, id: 'F-01', text: 'The daily digest has no time bound', about: 'features/FEAT-01' },
      { ...base, id: 'F-02', text: 'A quality the sitting does not show', about: 'contract/DIM-none', recommend: '', preset: '', presetBy: '' },
      { ...base, id: 'F-03', text: 'The unsubscribe is not tested', about: '', recommend: '', preset: '', presetBy: '' },
    ]
  })

test('P10 a finding about an item is drawn under it, once; the rest stay in the findings', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: critic() })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  expect(all.filter(t => t === 'The daily digest has no time bound')).toHaveLength(1)
  expect(at('The daily digest has no time bound')).toBeGreaterThan(at('the daily digest'))
  expect(at('The daily digest has no time bound')).toBeLessThan(at('synonym-aware search'))
  expect(all.filter(t => t === "ViD's critic:")).toHaveLength(1)
  expect(at("The critic's findings: 2 here, 1 beside what they are about.")).toBeGreaterThan(at('synonym-aware search'))
  expect(at('A quality the sitting does not show')).toBeGreaterThan(at("The critic's findings: 2 here, 1 beside what they are about."))
  expect(at('The unsubscribe is not tested')).toBeGreaterThan(at("The critic's findings: 2 here, 1 beside what they are about."))
  expect((await ui.findAll({ type: 'Button' })).filter((b: any) => (b.key ?? '').startsWith('findings/F-01-'))).toHaveLength(2)
  await ui.press({ key: 'findings/F-01-fix' })
  await ui.press({ key: 'send' })
  const m = log.submits[0]!
  expect(m.split('\n').indexOf('Not answered: F-01, F-02, F-03.')).toBeGreaterThan(m.split('\n').indexOf("The critic's findings:"))
  await ui.unmount()
})

test('P10 with no finding placed the title is as before', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Text', text: "The critic's findings" })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: "ViD's critic:" })).toBeUndefined()
  await ui.unmount()
})

test('P11 a done stop holds what was agreed there, shown on hover; a stop not done holds none', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all.filter(t => /^The interview: 3 items, agreed \d+ [A-Z][a-z]{2}$/.test(t))).toHaveLength(1)
  expect(all.filter(t => t === 'Done')).toHaveLength(1)
  expect(all.some(t => /^Agree the summary: /.test(t))).toBe(false)
  // hidden until hovered (the kit hands back no hover prop; the look item checks the reveal)
  const tip = (await ui.findAll({ type: 'Box' })).filter((b: any) => b.props?.position === 'absolute' && b.props?.display === 'none')
  expect(tip).toHaveLength(2)
  await ui.unmount()
})

test('P11 the new stretch of line is drawn moving once the stop moves on, and not on a first drawing', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW })
  let ui = await $.ui.mount(PANE('desktop', 120))
  const svgs = async () => (await ui.findAll({ type: 'Svg' })).map((x: any) => String(x.props?.source ?? '')).join('')
  expect(await svgs()).not.toContain('class="grow"')
  await ui.unmount()
  log.files[`${ROOT}/.vid/face/standing.json`] = PAUSE1_STANDING
  log.files[`${ROOT}/.vid/face/sitting.json`] = PAUSE1_47
  await $.turn.complete({ answer: '', durationMs: 5, isAborted: false, turnId: 't1', reason: 'answer' })
  ui = await $.ui.mount(PANE('desktop', 120))
  const src = await svgs()
  expect(src).toContain('class="grow"')
  expect(src).toContain('prefers-reduced-motion')
  await ui.unmount()
})

test('P12 a waiting sitting asks for its phrase as the title, and draws it first; nothing pops up', async ($, on) => {
  const log = await start($, on, { standing: INTERVIEW_STANDING, sitting: INTERVIEW, run: RUNNING })
  expect(log.opens).toHaveLength(1)
  expect(log.opens[0].title).toBe('Your questions are ready')
  expect(log.opens[0].focus).toBeUndefined()
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await texts(ui))[0]).toBe('Your questions are ready')
  await ui.press({ key: 'send' })
  expect(log.opens[log.opens.length - 1].title).toBe('ViD')
  expect(await ui.find({ type: 'Text', text: 'Your questions are ready' })).toBeUndefined()
  expect(log.notices).toHaveLength(0)
  await ui.unmount()
})

test('P12 when no sitting waits, an open pane is titled ViD', async ($, on) => {
  const log = await start($, on, { standing: WORKING_STANDING, sitting: ENDED, panes: [{ id: 'vid', title: 'Your summary is ready' }] })
  expect(log.opens.map(o => o.title)).toEqual(['ViD'])
  await $.turn.complete({ answer: '', durationMs: 5, isAborted: false, turnId: 't1', reason: 'answer' })
  expect(log.opens).toHaveLength(1)
})

test('P13 a drafting sitting: its cards under "Still changing", no button, no send, never waiting on the person', async ($, on) => {
  const log = await start($, on, { standing: DRAFT_STANDING, sitting: DRAFT, run: RUNNING })
  expect(log.opens).toHaveLength(0)
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  expect(at('ViD is drafting agree the summary. Still changing.')).toBeGreaterThan(at('Working for 5 min'))
  expect(at('Quality number 1 holds for every subscriber')).toBeGreaterThan(at('ViD is drafting agree the summary. Still changing.'))
  expect(all).toContain('Product summary')
  expect((await ui.findAll({ type: 'Button' })).filter((b: any) => /\//.test(b.key ?? '') || b.key === 'send')).toHaveLength(0)
  expect(all.some(t => /Your turn/.test(t))).toBe(false)
  await ui.unmount()
})

test('P13 the same sitting written: its cards get their buttons', async ($, on) => {
  const waiting = edited(DRAFT, s => {
    s.state = 'waiting'
  })
  await start($, on, { standing: DRAFT_STANDING, sitting: waiting, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Button', key: 'contract/DIM-q01-in' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Still changing/ })).toBeUndefined()
  await ui.unmount()
})

// --- usability, release A's review -------------------------------------------------------------------------------

test('P3 with a note on the qualities, the ruling sentence still ends the section', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'contract/DIM-q03-out' })
  await ui.press({ key: 'contract-note' })
  await ui.input({ key: 'contract-note-text', text: 'Merge 4 and 5' })
  await ui.press({ key: 'send' })
  const lines = log.submits[0]!.split('\n')
  const head = lines.indexOf('The qualities it must have:')
  const end = lines.indexOf('', head)
  expect(lines[end - 1]).toBe("The qualities I marked 'Doesn't need it' are out; keep my ruling on record.")
  expect(lines.slice(head, end)).toContain('Note: Merge 4 and 5')
  await ui.unmount()
})

test('P7 two withdrawn clauses of one rule are told apart on their cards', async ($, on) => {
  const text = edited(PAUSE1_47, s => {
    const w = sec(s, 'withdrawn')
    w.empty = false
    w.why = ''
    const item = (n: number) => ({ id: `REQ-002~${n}`, text: 'Every digest carries a working one-click unsubscribe', detail: [`arm ${n} of REQ-002 withdrawn under ViD's draft A-005`], recommend: '', choices: ['Keep the check', 'Remove it'], value: '', preset: '', presetBy: '', alone: true, norecommend: false, about: '' })
    w.items = [item(2), item(3)]
  })
  await start($, on, { standing: PAUSE1_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all).toContain('Clause 2 of this rule')
  expect(all).toContain('Clause 3 of this rule')
  await ui.unmount()
})

test('P5 the wait redraws as the clock moves on', async ($, on) => {
  const T0 = Date.parse('2026-11-15T10:00:00Z')
  const clock = mock.clock(on, { now: T0 })
  await start($, on, { clock: true, standing: WORKING_STANDING, sitting: ENDED, run: 'running 2026-11-15T09:55:00Z 2026-11-15T09:58:00Z\n' })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Text', text: 'Working for 5 min' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Last step 2 min ago' })).toBeDefined()
  await clock.advance(3 * 60000)
  expect(await ui.find({ type: 'Text', text: 'Working for 8 min' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Last step 5 min ago' })).toBeDefined()
  await ui.unmount()
})

// --- usability, release B -------------------------------------------------------------------------------------

const withPages = (text: string): string =>
  edited(text, s => {
    s.pages = [
      { id: 'prd', title: 'The PRD', file: '/project/.vid/pages/PRD.html', link: 'https://claude.ai/artifact/abc', stops: [3, 4, 5] },
      { id: 'foundation', title: 'The technical foundation', file: '/project/.vid/pages/FOUNDATION.html', link: '', stops: [6, 7] },
    ]
  })

test('P9 every page of the index is named under the map, a link where it has one, its file where not', async ($, on) => {
  await start($, on, { standing: withPages(WORKING_STANDING), sitting: ENDED, run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  expect(all).toContain('To read:')
  const link = await ui.find({ type: 'Link' })
  expect(link?.props?.href).toBe('https://claude.ai/artifact/abc')
  expect(link?.props?.label).toBe('The PRD')
  expect(all).toContain('The technical foundation: /project/.vid/pages/FOUNDATION.html')
  // each page's row is keyed (a Link and a Text carry no key of their own, so the row is a keyed Box)
  expect(await ui.find({ type: 'Box', key: 'page-prd' })).toBeDefined()
  expect(await ui.find({ type: 'Box', key: 'page-foundation' })).toBeDefined()
  expect(all.indexOf('To read:')).toBeLessThan(all.indexOf('ViD is working on the final wording'))
  await ui.unmount()
})

test('P9 a waiting sitting first names the pages due at its stop, to read whole', async ($, on) => {
  await start($, on, { standing: withPages(PAUSE1_STANDING), sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all).toContain('Read it whole first: The PRD')
  expect(all.indexOf('Read it whole first: The PRD')).toBeLessThan(all.indexOf('Waits on you'))
  await ui.unmount()
})

test('P9 no index: nothing to read is drawn', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  expect(all).not.toContain('To read:')
  expect(all.some(t => t.startsWith('Read it whole first'))).toBe(false)
  await ui.unmount()
})

// --- usability, release C's review ------------------------------------------------------------------------------

const aboutOne = (about: string, patch: Record<string, unknown> = {}): string =>
  edited(PAUSE1_47, s => {
    const f = sec(s, 'findings')
    f.items = [{ ...f.items[0], id: 'F-09', text: 'The summary promises a daily digest', about, recommend: '', preset: '', presetBy: '', ...patch }]
  })

test('P10 a finding about an item that draws no notes (text) stays in its section, drawn once', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: aboutOne('thesis/T1') })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect((await texts(ui)).filter(t => t === 'The summary promises a daily digest')).toHaveLength(1)
  expect(await ui.find({ type: 'Text', text: "The critic's findings" })).toBeDefined()
  await ui.unmount()
})

test('P10 an alone finding about a text item can still be answered and sent', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: aboutOne('thesis/T1', { alone: true }) })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'findings/F-09-fix' })
  await ui.press({ key: 'send' })
  expect(log.submits).toHaveLength(1)
  await ui.unmount()
})

test('P10 a finding still to answer is never hidden with the item it sits under', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: aboutOne('contract/DIM-q01') })
  const ui = await $.ui.mount(PANE('desktop', 120))
  await ui.press({ key: 'contract-only' })
  expect((await texts(ui)).filter(t => t === 'The summary promises a daily digest')).toHaveLength(1)
  await ui.unmount()
})

// 0.26.10.29.6 (S10): the headings ViD's pointing draws
test('S10 where to look: one heading above the pointed items, each with its why, one above the rest; order kept, none hidden', async ($, on) => {
  const text = edited(PAUSE1_47, s => {
    const c = sec(s, 'contract')
    c.items[0].look = 'An open finding'
    c.items[1].look = 'No recommendation'
  })
  await start($, on, { standing: PAUSE1_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  const q = (n: number) => `Quality number ${n} holds for every subscriber`
  expect(all.filter(t => t === 'Look here first')).toHaveLength(1)
  expect(all.filter(t => t === 'The rest, as recommended')).toHaveLength(1)
  expect(at('Look here first')).toBeLessThan(at(q(1)))
  expect(at('An open finding')).toBeGreaterThan(at(q(1)))
  expect(at('No recommendation')).toBeGreaterThan(at(q(2)))
  expect(at('The rest, as recommended')).toBeGreaterThan(at(q(2)))
  expect(at('The rest, as recommended')).toBeLessThan(at(q(3)))
  for (let n = 1; n <= 47; n++) expect(all.filter(t => t === q(n))).toHaveLength(1)
  for (let n = 1; n < 47; n++) expect(at(q(n))).toBeLessThan(at(q(n + 1)))
  await ui.unmount()
})

test('S10 a pointed finding about another item stays first in its own section, not beside its target', async ($, on) => {
  const text = edited(PAUSE1_47, s => {
    const f = sec(s, 'findings')
    const base = f.items[0]
    f.items = [
      { ...base, id: 'F-11', text: 'A pointed finding about a quality', about: 'contract/DIM-q01', look: 'An open finding' },
      { ...base, id: 'F-12', text: 'An ordinary finding', about: '', look: '' },
    ]
  })
  await start($, on, { standing: PAUSE1_STANDING, sitting: text })
  const ui = await $.ui.mount(PANE('desktop', 120))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  expect(all.filter(t => t === 'A pointed finding about a quality')).toHaveLength(1)
  expect(all.filter(t => t === "ViD's critic:")).toHaveLength(0)
  expect(at('A pointed finding about a quality')).toBeGreaterThan(at('Look here first'))
  expect(at('A pointed finding about a quality')).toBeLessThan(at('The rest, as recommended'))
  expect(at('An ordinary finding')).toBeGreaterThan(at('The rest, as recommended'))
  await ui.unmount()
})

test('S10 a section with no pointed item draws neither heading', async ($, on) => {
  await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  const ui = await $.ui.mount(PANE('desktop', 120))
  expect(await ui.find({ type: 'Text', text: 'Look here first' })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: 'The rest, as recommended' })).toBeUndefined()
  await ui.unmount()
})

// --- FB-3 D1: the backlog; D2: the parts of a long call -------------------------------------------------------------

const item = (id: string, state: string, words: string, more: object = {}) => ({ id, state, who: 'you', words, next: '', note: '', since: '2026-11-20T09:00:00Z', ended: '', ...more })
const BACKLOG = {
  items: [
    item('Q4', 'to do', 'the move publish S03', { next: 'done "<words>"' }),
    item('B2', 'doing', 'push the branch', { next: 'run the release', note: 'half done' }),
    item('B3', 'waiting', 'the bank account', { who: 'Ann', note: 'asked on Monday' }),
    item('Q7', 'aside', 'the trigger step-slow S02'),
    item('B5', 'to do', 'decide the export'),
  ],
  done: [item('B1', 'done', 'read the terms', { note: 'read', ended: '2026-11-21T09:00:00Z' }), item('Q1', 'done', 'the old question', { note: 'no longer there', ended: '2026-11-20T09:00:00Z' })],
  doneCount: 14,
}
const withBacklog = (text: string, fn: (s: any) => void = () => undefined): string =>
  edited(text, s => {
    s.backlog = BACKLOG
    fn(s)
  })
const allDone = (s: any) => {
  s.current = 10
  s.next = ''
  for (const x of s.stops) x.state = 'done'
}
const PARTS = { parts: [{ name: 'Reading GitHub', state: 'done' }, { name: 'Working out what changed', state: 'now' }, { name: 'Saving the records', state: 'to come' }], now: 'ticket 7 of 21', stop: '', written: '' }

// FB-5 A1: the backlog's items are drawn from the owner's list alone, each in the line the sort gave it
const NOT_WRITTEN = 'Your list is not written yet. ViD writes it at its next call.'
test('FB-3 D1 the backlog with no list written yet: its counts, and no item drawn', async ($, on) => {
  await start($, on, { standing: withBacklog(WORKING_STANDING), run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  expect(all).toContain(NOT_WRITTEN)
  expect(all).toContain('2 to do · 1 in progress · 1 waiting · 1 set aside')
  expect(all.some(t => t.includes('push the branch'))).toBe(false)
  // never the map's step of a project past defining
  expect(all.some(t => /^Step \d of 9/.test(t))).toBe(false)
  await ui.unmount()
})

test('FB-3 D1 the mode run stands before done, idle, working and stopped; a waiting sitting stands before it', async ($, on) => {
  const log = await start($, on, { standing: withBacklog(WORKING_STANDING, allDone) })
  const ui = await $.ui.mount(PANE('desktop'))
  for (const [cur, run] of [[10, STOPPED], [1, STOPPED], [5, RUNNING], [5, STOPPED]] as const) {
    log.files[`${ROOT}/.vid/face/standing.json`] = withBacklog(WORKING_STANDING, s => {
      s.current = cur
    })
    log.files[`${ROOT}/.vid/face/run.sess-A`] = run
    await $.command.run({ command: 'vid-panel', args: '' })
    const all = await texts(ui)
    expect(all).toContain(NOT_WRITTEN)
    expect(all.some(t => /Every stop is done|Nothing waits on you here|ViD is working on|^ViD has stopped/.test(t))).toBe(false)
  }
  log.files[`${ROOT}/.vid/face/standing.json`] = withBacklog(PAUSE2_STANDING)
  log.files[`${ROOT}/.vid/face/sitting.json`] = PAUSE2
  await $.command.run({ command: 'vid-panel', args: '' })
  expect(await texts(ui)).not.toContain(NOT_WRITTEN)
  await ui.unmount()
})

test('FB-3 D1 no backlog, or an empty one with no parts: the panel as before', async ($, on) => {
  const log = await start($, on, { standing: edited(WORKING_STANDING, s => { s.backlog = { items: [], done: [], doneCount: 0 } }), run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await texts(ui)).toContain('ViD has stopped. Look at the chat.')
  expect(log.opens).toHaveLength(0)
  await ui.unmount()
})

test('FB-3 D1 it opens once a conversation for the backlog, never with the keys; not outside the desktop app', async ($, on) => {
  const log = await start($, on, { standing: withBacklog(WORKING_STANDING), run: STOPPED })
  expect(log.opens).toHaveLength(1)
  expect(log.opens[0].focus).toBeUndefined()
  expect(log.opens[0].title).toBe('ViD')
  await $.tool.call({ tool: 'Bash', input: {} } as any).catch(() => undefined)
  await $.turn.complete({ answer: 'done', stop: 'stop' } as any).catch(() => undefined)
  expect(log.opens).toHaveLength(1)
})

test('FB-3 D1 a project on the terminal alone: no open', async ($, on) => {
  const log = await start($, on, { standing: withBacklog(WORKING_STANDING), surfaces: ['terminal'] })
  expect(log.opens).toHaveLength(0)
})

test('FB-3 D1 long words are cut, and nothing undefined is drawn', async ($, on) => {
  const long = 'x'.repeat(900)
  await start($, on, { standing: withBacklog(WORKING_STANDING, s => { s.wait = { ...PARTS, stop: long } }), run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  expect(all.some(t => t.startsWith('It needs: xxx') && t.endsWith('…') && t.length < 320)).toBe(true)
  expect(all.some(t => /undefined/.test(t))).toBe(false)
  await ui.unmount()
})

test('FB-3 D2 the parts of a long call, drawn in the mode run while the session runs, with every stop done', async ($, on) => {
  await start($, on, { standing: withBacklog(WORKING_STANDING, s => { allDone(s); s.wait = PARTS }), run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  const all = await texts(ui)
  const at = (t: string) => all.indexOf(t)
  expect(at('✓ Reading GitHub')).toBeGreaterThan(-1)
  expect(at('● Working out what changed')).toBeGreaterThan(at('✓ Reading GitHub'))
  expect(at('○ Saving the records')).toBeGreaterThan(at('● Working out what changed'))
  expect(all).toContain('Now: ticket 7 of 21')
  expect(at(NOT_WRITTEN)).toBeGreaterThan(at('Now: ticket 7 of 21'))
  await ui.unmount()
})

test('FB-3 D2 a take-stock with no backlog yet draws its parts too', async ($, on) => {
  await start($, on, { standing: edited(WORKING_STANDING, s => { allDone(s); s.backlog = { items: [], done: [], doneCount: 0 }; s.wait = PARTS }), run: RUNNING })
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await texts(ui)).toContain('● Working out what changed')
  await ui.unmount()
})

test('FB-3 D2 a killed call leaves nothing hanging: no parts once the session has stopped, nor in a later turn', async ($, on) => {
  const log = await start($, on, { standing: withBacklog(WORKING_STANDING, s => { s.wait = PARTS }), run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await texts(ui)).some(t => /Reading GitHub|ticket 7 of 21/.test(t))).toBe(false)
  log.files[`${ROOT}/.vid/face/standing.json`] = withBacklog(WORKING_STANDING, s => { s.wait = { ...PARTS, written: utc(20) } })
  log.files[`${ROOT}/.vid/face/run.sess-A`] = RUNNING
  await $.command.run({ command: 'vid-panel', args: '' })
  expect((await texts(ui)).some(t => /Reading GitHub|ticket 7 of 21/.test(t))).toBe(false)
  await ui.unmount()
})

test('FB-3 D2 a stop is said in amber with Look at the chat, with the session stopped', async ($, on) => {
  const stopped = { parts: [{ name: 'Reading each ticket', state: 'done' }, { name: 'Checking the plan', state: 'stopped' }], now: 'your yes to the plan', stop: 'your yes to the plan', written: utc(3) }
  await start($, on, { standing: withBacklog(WORKING_STANDING, s => { s.wait = stopped }), run: STOPPED })
  const ui = await $.ui.mount(PANE('desktop'))
  const t = await ui.find({ type: 'Text', text: 'ViD stopped at: Checking the plan' })
  expect(t).toBeDefined()
  expect((t as any).props.color).toBe('warning')
  expect(await texts(ui)).toContain('It needs: your yes to the plan')
  expect(await texts(ui)).toContain('Look at the chat.')
  await ui.unmount()
})

// --- FB-5 A1: the owner's list --------------------------------------------------------------------------------------

const LIST = (fn: (l: any) => void = () => undefined): string => edited(JSON.stringify(LIST_DATA), fn)
const listed = (fn?: (l: any) => void, w: World = {}): World => ({ standing: withBacklog(WORKING_STANDING, allDone), run: STOPPED, list: LIST(fn), ...w })
const SECTIONS = ['My to do', 'Waiting', 'Changed', 'The rest', 'The plan', 'Team North', 'Team South', 'Team East', 'Tickets of no step in the plan']
// a drawn text, and where it stands among the drawn texts
const drawn = async (ui: any) => {
  const all = await texts(ui)
  return { all, at: (t: string) => all.findIndex(x => x === t), has: (t: string) => all.some(x => x.includes(t)) }
}
// a store the panel keeps across restarts
const keeping = (on: any, kept: Record<string, unknown>) => {
  on('store.get', (_: any, e: any) => ({ value: kept[e.key] }))
  on('store.set', (_: any, e: any) => {
    kept[e.key] = JSON.parse(JSON.stringify(e.value))
    return { value: undefined }
  })
}
const startKept = async ($: any, on: any, w: World, kept: Record<string, unknown>) => {
  const log = newLog()
  world(on, w, log)
  keeping(on, kept)
  await $.session.start({ cwd: ROOT, surface: 'desktop', isInteractive: true })
  return log
}
const reread = ($: any) => $.command.run({ command: 'vid-panel', args: '' })

test('FB-5 A1 the sections, numbered and in order, narrow and wide, with a link to each', async ($, on) => {
  await start($, on, listed())
  for (const cols of [44, 60, 120]) {
    const ui = await $.ui.mount(PANE('desktop', cols))
    const { all } = await drawn(ui)
    let last = -1
    for (const [i, t] of SECTIONS.entries()) {
      expect(await ui.find({ type: 'Button', key: `go-${i + 1}` })).toBeDefined()
      const box: any = await ui.find({ type: 'Box', key: `sec-${i + 1}` })
      expect(box).toBeDefined()
      const at = all.lastIndexOf(t)
      expect(at).toBeGreaterThan(last)
      expect(all[at - 1]).toBe(String(i + 1))
      last = at
    }
    expect(await ui.find({ type: 'Box', key: 'sec-10' })).toBeUndefined()
    expect(all.some(t => /undefined|NaN/.test(t))).toBe(false)
    await ui.unmount()
  }
})

test('FB-5 A1 the sections say their counts, all open', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop', 120))
  const { all, has } = await drawn(ui)
  for (const t of ['3, only you can do, in order', '1', '2, nothing needed from you', '1 with ViD, 1 yours later', '2 releases, 5 steps, 3 teams', '3 steps: 1 accepted, 1 being built, 1 nobody has', 'no step yet']) expect(all).toContain(t)
  expect(has('Branch library')).toBe(true)
  expect(has('20 November, 15:03 UTC')).toBe(true)
  for (const t of ['Cleo', 'Say which books go first.', 'since 18 Nov', 'The reading room closed two pieces.', 'Your tests were merged.', 'ViD is on it; you are told when it is done', 'Checks the two late answers.', 'Yours later', 'After the catalog', 'the order of the shelves.', 'Goes to the team by itself, when its time comes', 'One test reworded after its ticket went out.', 'Suggested by ViD', 'Weighed and left out: a new plan proposal, since nothing is accepted yet']) expect(has(t)).toBe(true)
  // the new mark, on the line that is new alone
  expect(all).toContain('new: Ann, 14:10')
  expect(all.filter(t => t.startsWith('new'))).toHaveLength(1)
  await ui.unmount()
})

test('FB-5 A1 My to do: the first line open, one open at a time, its number its own', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  let d = await drawn(ui)
  for (const t of ['1.1', '1.2', '1.4', 'How long a loan lasts', 'Two words for late books', 'Tell Bo the shelf is ready', 'Decide the fine, then the notice.']) expect(d.all).toContain(t)
  expect(d.all).toContain('Ann asks how long a member keeps a book.')
  expect(d.all).toContain('How long is a loan?')
  expect(d.all).not.toContain('The desk asks two things.')
  await ui.press({ key: 'line-Q14' })
  d = await drawn(ui)
  expect(d.all).toContain('The desk asks two things.')
  expect(d.all).not.toContain('Ann asks how long a member keeps a book.')
  await ui.press({ key: 'line-Q14' })
  d = await drawn(ui)
  expect(d.all).not.toContain('The desk asks two things.')
  expect(d.all).not.toContain('Ann asks how long a member keeps a book.')
  await ui.unmount()
})

test('FB-5 A1 the choice ViD would take first, with why; the others after it', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  const { has } = await drawn(ui)
  expect(has('ViD would choose “Three weeks”')).toBe(true)
  expect(has('most members read slowly')).toBe(true)
  const keys = (await ui.findAll({ type: 'Button' })).map((b: any) => b.key ?? b.props?.key ?? '').filter((k: string) => k.startsWith('ans-Q12-B3-0-'))
  expect(keys).toEqual(['ans-Q12-B3-0-2', 'ans-Q12-B3-0-1', 'ans-Q12-B3-0-3'])
  expect((await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-2' }) as any).props.variant).toBe('primary')
  expect((await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' }) as any).props.variant).not.toBe('primary')
  await ui.unmount()
})

test('FB-5 A1 a press says the number, the title, the answer and the ids, as the owner; the line is sent once and the next opens', async ($, on) => {
  const kept: Record<string, unknown> = {}
  const log = await startKept($, on, listed(), kept)
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'ans-Q12-B3-0-1' })
  expect(log.submits).toEqual(['1.1 · How long a loan lasts: Two weeks (Q12, B3)'])
  expect(log.asUser).toEqual([true])
  expect(log.fills).toHaveLength(0)
  let d = await drawn(ui)
  expect(d.has('sent at')).toBe(true)
  expect(d.has('Two weeks')).toBe(true)
  expect(d.all).toContain('The desk asks two things.')
  expect(d.all).toContain('2, only you can do, in order')
  for (const k of ['ans-Q12-B3-0-1', 'ans-Q12-B3-0-2', 'off-Q12-B3', 'explain-Q12-B3', 'line-Q12-B3']) expect(await ui.find({ type: 'Button', key: k })).toBeUndefined()
  // the same sort written again: still sent; the line's number gone to another line, it is told by its ids
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => {
    l.written = '2026-11-20T15:20:00Z'
    l.todo[1].n = '1.1'
  })
  await reread($)
  d = await drawn(ui)
  expect(d.has('sent at')).toBe(true)
  expect(await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' })).toBeUndefined()
  // another conversation's panel, from the store
  expect(JSON.stringify(kept)).toContain('Q12,B3')
  // the next sort: a line again
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => {
    l.sortedAt = '2026-11-21T09:00:00Z'
  })
  await reread($)
  expect(await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' })).toBeDefined()
  await ui.unmount()
})

test('FB-5 A1 a line another conversation sent, or this one before a restart, is drawn sent and not sent again', async ($, on) => {
  const kept: Record<string, unknown> = {}
  kept.list = { sent: { '2026-11-20T15:03:00Z|Q12,B3': { at: '15:10', how: 'sent', words: 'Two weeks' } }, asked: {} }
  const log = await startKept($, on, listed(), kept)
  const ui = await $.ui.mount(PANE('desktop'))
  const d = await drawn(ui)
  expect(d.has('sent at 15:10')).toBe(true)
  expect(await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' })).toBeUndefined()
  // sent by another conversation after this panel was drawn: the press sends nothing
  kept.list = { sent: { ...(kept.list as any).sent, '2026-11-20T15:03:00Z|Q20': { at: '15:11', how: 'sent', words: 'Sent' } }, asked: {} }
  await ui.press({ key: 'line-Q20' })
  if (await ui.find({ type: 'Button', key: 'ans-Q20-0-1' })) await ui.press({ key: 'ans-Q20-0-1' })
  expect(log.submits).toHaveLength(0)
  await ui.unmount()
})

test('FB-5 A1 two questions on one line: sent together, once both are answered', async ($, on) => {
  const log = await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'line-Q14' })
  await ui.press({ key: 'ans-Q14-1-2' })
  expect(log.submits).toHaveLength(0)
  expect((await ui.find({ type: 'Button', key: 'ans-Q14-1-2' }) as any).props.variant).toBe('primary')
  await ui.press({ key: 'ans-Q14-0-1' })
  expect(log.submits).toEqual(['1.2 · Two words for late books: A fine; ViD (Q14)'])
  await ui.unmount()
})

test('FB-5 A1 a message with no choice is drawn whole, and answered as sent', async ($, on) => {
  const log = await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'line-Q20' })
  expect((await drawn(ui)).all).toContain('Bo, the shelf is ready. Will you take it?')
  await ui.press({ key: 'ans-Q20-0-1' })
  expect(log.submits).toEqual(['1.4 · Tell Bo the shelf is ready: Sent (Q20)'])
  await ui.unmount()
})

test('FB-5 A1 a press the app refused goes into the message box; one it would not take either can be pressed again', async ($, on) => {
  const log = await start($, on, listed(undefined, { drop: 'the session is busy' }))
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'ans-Q12-B3-0-1' })
  expect(log.submits).toHaveLength(1)
  expect(log.fills.map(t => t.trim())).toEqual(['1.1 · How long a loan lasts: Two weeks (Q12, B3)'])
  expect((await drawn(ui)).has('in your message box')).toBe(true)
  expect(await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' })).toBeUndefined()
  // a second one keeps the first in the box
  await ui.press({ key: 'line-Q20' })
  await ui.press({ key: 'ans-Q20-0-1' })
  expect(log.modes).toEqual(['append', 'append'])
  await ui.unmount()
})

test('FB-5 A1 refused by the box too: not sent, said so, and pressed again', async ($, on) => {
  const kept: Record<string, unknown> = {}
  const log = await startKept($, on, listed(undefined, { drop: 'the session is busy', unfilled: true }), kept)
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'ans-Q12-B3-0-1' })
  expect((await drawn(ui)).has('Not sent: the session is busy')).toBe(true)
  expect(JSON.stringify(kept)).not.toContain('Q12,B3')
  expect(await ui.find({ type: 'Button', key: 'ans-Q12-B3-0-1' })).toBeDefined()
  await ui.press({ key: 'ans-Q12-B3-0-1' })
  expect(log.submits).toHaveLength(2)
  await ui.unmount()
})

test('FB-5 A1 Put it off, Explain it, and the numbers and links, shown at a press', async ($, on) => {
  const log = await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).has('Ticket 31')).toBe(false)
  await ui.press({ key: 'details-Q12-B3' })
  expect((await drawn(ui)).has('Ticket 31')).toBe(true)
  expect((await ui.findAll({ type: 'Link' })).some((l: any) => l.props.href === 'https://example.com/31')).toBe(true)
  // a question is asked once, and the line still takes its answer
  await ui.press({ key: 'explain-Q12-B3' })
  expect(log.submits).toEqual(['1.1 · How long a loan lasts: Explain it (Q12, B3)'])
  expect((await drawn(ui)).has('asked in the chat')).toBe(true)
  expect(await ui.find({ type: 'Button', key: 'explain-Q12-B3' })).toBeUndefined()
  await ui.press({ key: 'off-Q12-B3' })
  expect(log.submits[1]).toBe('1.1 · How long a loan lasts: Put it off (Q12, B3)')
  expect(await ui.find({ type: 'Button', key: 'off-Q12-B3' })).toBeUndefined()
  // a line with no numbers has no button for them
  expect(await ui.find({ type: 'Button', key: 'details-Q14' })).toBeUndefined()
  await ui.unmount()
})

test('FB-5 A1 nothing for the owner: said only with no item unsorted; the last sort kept, with not sorted yet', async ($, on) => {
  const log = await start($, on, listed(l => { l.todo = [] }))
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).has('Nothing is yours now')).toBe(true)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { l.todo = []; l.unsorted = 2; l.state = 'stale' })
  await reread($)
  let d = await drawn(ui)
  expect(d.has('Nothing is yours now')).toBe(false)
  expect(d.has('2 not sorted yet')).toBe(true)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { l.unsorted = 1; l.state = 'stale' })
  await reread($)
  d = await drawn(ui)
  expect(d.all).toContain('How long a loan lasts')
  expect(d.has('1 not sorted yet')).toBe(true)
  // never sorted: the plan and the teams whole
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { l.state = 'none'; l.sortedAt = ''; l.unsorted = 4; l.todo = []; l.waiting = []; l.changed = []; l.rest = { ...l.rest, vid: [], later: [], team: [], suggested: [], leftOut: [] } })
  await reread($)
  d = await drawn(ui)
  expect(d.has('Nothing is yours now')).toBe(false)
  expect(d.has('4 not sorted yet')).toBe(true)
  expect(d.all).toContain('Loans')
  expect(await ui.find({ type: 'Button', key: 'holds' })).toBeDefined()
  await ui.unmount()
})

test('FB-5 A1 the rest ends with everything ViD holds and the counts, closed until pressed', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  let d = await drawn(ui)
  expect(d.has('the trigger step-slow')).toBe(false)
  expect(d.has('tests in steps not sent')).toBe(false)
  expect(await ui.find({ type: 'Button', key: 'holds' })).toBeDefined()
  await ui.press({ key: 'holds' })
  d = await drawn(ui)
  for (const t of ['Q12', 'the question loan-days', 'Q30', 'the trigger step-slow', 'The plan', '7 tests in steps not sent']) expect(d.has(t)).toBe(true)
  await ui.unmount()
})

test('FB-5 A1 what a wait holds is closed until pressed', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).has('Asked on ticket 40.')).toBe(false)
  await ui.press({ key: 'waiting-details' })
  expect((await drawn(ui)).has('Asked on ticket 40.')).toBe(true)
  await ui.unmount()
})

test('FB-5 A1 the plan: a box a step, filled by its pieces, what is stuck, and what holds the rest up', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop', 120))
  const { all, has } = await drawn(ui)
  const boxes = (await ui.findAll({ type: 'Svg' })).map((x: any) => x.props.alt)
  for (const t of ['Catalog: accepted', 'Loans: being built, 40% of its pieces done', 'Members: sent, nobody has it', 'Fines: taken', 'Notices: not sent yet']) expect(boxes.filter((b: string) => b === t)).toHaveLength(1)
  for (const t of ['1 accepted', '1 being built, filled by the pieces done', '1 taken, no pieces yet', '1 sent to the team, nobody has it', '1 not sent yet', '1 of 2 steps accepted', '0 of 3 steps accepted', '1 being built: Ann.', 'Ann first.', 'What holds the rest up: 2 steps', '4 steps are not accepted. These 2 wait on nothing; 1 of the other 2 builds on them, directly or through other steps.', 'Ann; 2 of 5 pieces done', 'Nobody has it, 9 days.', '1 builds on it', '2 build on it']) expect(has(t)).toBe(true)
  expect((await ui.find({ type: 'Text', text: 'Stuck: 1 nobody has.' }) as any).props.color).toBe('warning')
  expect(all.indexOf('What holds the rest up: 2 steps')).toBeLessThan(all.lastIndexOf('Team North'))
  await ui.unmount()
})

test('FB-5 A1 the teams: every card open, tracks side by side from 90 columns, one under the other below', async ($, on) => {
  await start($, on, listed())
  for (const [cols, dir] of [[89, 'column'], [90, 'row'], [44, 'column']] as const) {
    const ui = await $.ui.mount(PANE('desktop', cols))
    const row: any = await ui.find({ type: 'Box', key: 'tracks-1-0-0' })
    expect(row?.props.flexDirection).toBe(dir)
    const { all, has } = await drawn(ui)
    for (const id of ['S01', 'S02', 'S03', 'S04', 'S05']) expect(await ui.findAll({ type: 'Box', key: `card-${id}` })).toHaveLength(1)
    for (const t of ['Release 0', 'First shelf', 'North, track 2', 'Being built', 'Nobody has it', 'Not sent yet', 'Taken', 'Accepted', '2 of 5 pieces done', 'Ann', '1 ready, 1 draft', '17 Nov, 3 days ago', '1 later step', 'Loans; Members', 'nothing that is not accepted', 'One test was reworded; the team is told later.']) expect(has(t)).toBe(true)
    expect(all.filter(t => t === '3 of 3 pieces done')).toHaveLength(1)
    // the tests' ids are folded
    expect(has('LIB-002')).toBe(false)
    await ui.press({ key: 'tests-S02' })
    expect((await drawn(ui)).has('LIB-002 LIB-003')).toBe(true)
    await ui.press({ key: 'tests-S02' })
    const links = (await ui.findAll({ type: 'Link' })).map((l: any) => `${l.props.label} ${l.props.href}`)
    for (const l of ['#12 S02 https://example.com/12', '#51 https://example.com/51', '#52 https://example.com/52']) expect(links).toContain(l)
    // the pull requests in one row that wraps, after how many there are
    expect(all).toContain('Pull requests: 1 ready, 1 draft:')
    const pulls: any = await ui.find({ type: 'Box', key: 'pulls-S02' })
    expect([pulls?.props.flexDirection, pulls?.props.flexWrap]).toEqual(['row', 'wrap'])
    expect(pulls.children.map((x: any) => x.type)).toEqual(['Text', 'Link', 'Link'])
    await ui.unmount()
  }
})

test('FB-5 A1 with no plan to draw (GitHub auto) the sections end at The rest', async ($, on) => {
  await start($, on, listed(l => { l.plan = { releases: [], hold: { open: 0, others: 0, built: 0, rows: [] } }; l.teams = [] }))
  const ui = await $.ui.mount(PANE('desktop'))
  expect(await ui.find({ type: 'Box', key: 'sec-4' })).toBeDefined()
  expect(await ui.find({ type: 'Box', key: 'sec-5' })).toBeUndefined()
  expect(await ui.find({ type: 'Button', key: 'go-5' })).toBeUndefined()
  await ui.unmount()
})

test('FB-5 A1 the list is the panel with nothing in the backlog too', async ($, on) => {
  await start($, on, { standing: edited(WORKING_STANDING, s => { s.backlog = { items: [], done: [], doneCount: 0 } }), run: STOPPED, list: LIST() })
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).all).toContain('How long a loan lasts')
  await ui.unmount()
})

test('FB-5 A1 a call’s parts stand above the list, and its stop', async ($, on) => {
  await start($, on, listed(undefined, { standing: withBacklog(WORKING_STANDING, s => { allDone(s); s.wait = PARTS }), run: RUNNING }))
  const ui = await $.ui.mount(PANE('desktop'))
  const { all } = await drawn(ui)
  expect(all.indexOf('● Working out what changed')).toBeGreaterThan(-1)
  expect(all.indexOf('● Working out what changed')).toBeLessThan(all.lastIndexOf('My to do'))
  await ui.unmount()
})

test('FB-5 A1 a list it cannot read, or of another form, is said in one line; none written yet, the counts', async ($, on) => {
  const log = await start($, on, listed(undefined, { list: '{"format":1,' }))
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).has('could not be read')).toBe(true)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { l.format = 2 })
  await reread($)
  expect((await drawn(ui)).has('written by a newer ViD')).toBe(true)
  delete log.files[`${ROOT}/.vid/face/list.json`]
  await reread($)
  const d = await drawn(ui)
  expect(d.has('2 to do · 1 in progress · 1 waiting · 1 set aside')).toBe(true)
  expect(d.has('not written yet')).toBe(true)
  await ui.unmount()
})

test('FB-5 A1 a field left out is drawn as none, and a long plan is drawn whole', async ($, on) => {
  const log = await start($, on, listed(undefined, { list: '{"format":1,"state":"sorted","todo":[{"n":"1.1","ids":["Q1"],"title":"A line"}],"plan":{"releases":[{"n":0,"steps":[{"id":"S01"}]}]},"teams":[{"name":"North","releases":[{"tracks":[{"cards":[{"id":"S01"}]}]}]}]}' }))
  const ui = await $.ui.mount(PANE('desktop', 120))
  let d = await drawn(ui)
  expect(d.all).toContain('A line')
  expect(d.all.some(t => /undefined|NaN/.test(t))).toBe(false)
  const ids = Array.from({ length: 40 }, (_, i) => `LIB-${i}`)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => {
    l.teams[0].releases = [{ n: 0, name: 'First shelf', words: '', tracks: [1, 2, 3].map(t => ({ name: `track ${t}`, cards: Array.from({ length: 40 }, (_, i) => ({ ...l.teams[1].releases[0].tracks[0].cards[0], id: `S${t}-${i}`, name: `Step ${t}-${i}`, tests: 40, testIds: ids })) })) }]
  })
  await reread($)
  d = await drawn(ui)
  expect(new Set(d.all.join('\n').match(/Step \d-\d+/g))).toHaveProperty('size', 120)
  await ui.unmount()
})

// What the desktop app draws of a panel at most: an element and a text are a piece each, 2,000 in all, 32 deep. Past it the app says
// "nothing to show yet" and no more; the kit's own engine draws ten times that.
const APP_DRAWS = { pieces: 2000, deep: 32, chars: 262144, text: 100000 }
const measure = (x: any, deep = 1): { pieces: number; deep: number; chars: number; text: number } => {
  if (typeof x === 'string') return { pieces: 1, deep, chars: x.length, text: x.length }
  const kids: any[] = x?.children ?? []
  const own = Object.entries({ ...(x?.props ?? {}), ...(x?.hover ?? {}) }).reduce((n, [k, v]) => n + k.length + (typeof v === 'string' ? v.length : 0), 0)
  return kids.map(k => measure(k, deep + 1)).reduce((a, b) => ({ pieces: a.pieces + b.pieces, deep: Math.max(a.deep, b.deep), chars: a.chars + b.chars, text: a.text + b.text }), { pieces: 1, deep, chars: own, text: 0 })
}
const inBounds = (x: any) => {
  const m = measure(x)
  return m.pieces < APP_DRAWS.pieces && m.deep <= APP_DRAWS.deep && m.chars < APP_DRAWS.chars && m.text < APP_DRAWS.text
}
const ofPlan = (l: any, nth: number, per: number) => {
  const card = l.teams[1].releases[0].tracks[0].cards[0]
  const ids = Array.from({ length: 40 }, (_, i) => `LIB-${i}`)
  const states = ['accepted', 'building', 'taken', 'nobody', 'unsent']
  const all = Array.from({ length: nth * per }, (_, i) => ({ ...card, id: `S${i}`, name: `Step ${i} done`, state: states[i % 5], flag: i % 4 ? '' : 'A', ticket: i + 1, url: `https://example.com/${i}`, who: 'Ann', pieces: 5, done: 2, ready: 1, drafts: 1, pulls: [{ n: 51, url: 'https://example.com/51' }], sent: '2026-11-17T09:00:00Z', buildsOn: ['Loans'], holdsUp: 2, tests: 40, testIds: ids, notes: ['One test was reworded.'] }))
  l.plan.releases = [{ ...l.plan.releases[0], steps: all.map(c => ({ id: c.id, name: c.name, state: c.state, fill: 40, flag: c.flag })) }]
  l.teams = [{ ...l.teams[0], releases: [{ n: 0, name: 'First shelf', words: '', tracks: Array.from({ length: nth }, (_, k) => ({ name: `track ${k}`, cards: all.slice(k * per, (k + 1) * per) })) }] }]
  l.rest.holds = Array.from({ length: 70 }, (_, i) => ({ id: `B${i}`, words: `What ViD holds ${i}`, where: 'in The rest' }))
}

test('FB-5 A1 the panel never holds more than the app draws, however long the plan', async ($, on) => {
  const log = await start($, on, listed())
  for (const [nth, per, whole] of [[3, 15, true], [3, 40, false], [3, 130, false]] as const) {
    log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => ofPlan(l, nth, per))
    await reread($)
    const links = await (async () => {
      const ui = await $.ui.mount(PANE('desktop', 120))
      const keys = (await ui.findAll({ type: 'Button' })).map((b: any) => b.props.key as string)
      await ui.unmount()
      return keys
    })()
    const go = links.filter(k => k.startsWith('go-')).map(k => k.slice(3))
    expect(go.length).toBeGreaterThan(4)
    for (const n of go) expect(links.filter(k => k === `top-${n}`)).toHaveLength(1)
    // everything ViD holds shut, then shown
    for (const held of [false, true]) {
      if (held) {
        const ui = await $.ui.mount(PANE('desktop', 120))
        await ui.press({ key: 'holds' })
        await ui.unmount()
      }
      for (const cols of [120, 56]) {
        expect([nth * per, held, cols, inBounds(await ($ as any).ui.render(PANE('desktop', cols) as any))]).toEqual([nth * per, held, cols, true])
      }
    }
    const ui = await $.ui.mount(PANE('desktop', 120))
    const { all } = await drawn(ui)
    // every step named in its team, whole or in a line; with room, every card whole
    const said = all.join('\n')
    for (let i = 0; i < nth * per; i++) expect(said.includes(`Step ${i} done`)).toBe(true)
    if (whole) for (let i = 0; i < nth * per; i++) expect(await ui.findAll({ type: 'Box', key: `card-S${i}` })).toHaveLength(1)
    // what is closed is said on the panel, never dropped in silence
    expect(said.includes('closed to fit')).toBe(!whole)
    expect(all).toContain('How long a loan lasts')
    await ui.press({ key: 'holds' })
    await ui.unmount()
  }
  // past even that: My to do is drawn, and the steps are said to be too many
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => ofPlan(l, 3, 700))
  await reread($)
  expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
  const { all, has } = await drawn(await $.ui.mount(PANE('desktop', 56)))
  expect(all).toContain('How long a loan lasts')
  expect(has('too many to draw here')).toBe(true)
})

test('FB-5 A1 a sitting too long to draw whole is drawn in parts, every item reached, its marks kept; past that it says so, and is never blank', async ($, on) => {
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: PAUSE1_47 })
  expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
  const long = (n: number, sections = 1) => edited(PAUSE1_47, s => {
    s.sections = s.sections.filter((x: any) => x.kind === 'list' && x.items.length >= 4).slice(0, 1).flatMap((x: any) => Array.from({ length: sections }, (_, k) => ({ ...x, id: `${x.id}${k || ''}`, items: Array.from({ length: n }, (_, i) => ({ ...x.items[0], id: `X${i}`, text: `Rule ${i} holds`, look: '' })) })))
  })
  const ruled = (all: string[]) => all.filter(t => /^Rule \d+ holds$/.test(t))
  log.files[`${ROOT}/.vid/face/sitting.json`] = long(47)
  await reread($)
  const ui: any = await $.ui.mount(PANE('desktop', 56))
  expect(ruled((await drawn(ui)).all)).toHaveLength(47)
  expect(await ui.find({ type: 'Button', key: 'contract-later-top' })).toBeUndefined()
  log.files[`${ROOT}/.vid/face/sitting.json`] = long(200)
  await reread($)
  const seen = new Set<string>()
  for (let i = 0; i < 5; i++) {
    const { all, has } = await drawn(ui)
    expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
    expect(has(`${i * 40 + 1} to ${i * 40 + 40} of 200`)).toBe(true)
    for (const t of ruled(all)) seen.add(t)
    if (i < 4) await ui.press({ key: 'contract-later-top' })
  }
  expect(seen.size).toBe(200)
  expect(await ui.find({ type: 'Button', key: 'contract-later-top' })).toBeUndefined()
  // a mark of one part stands on the others
  await ui.press({ key: 'contract/X199-out' })
  await ui.press({ key: 'contract-earlier-foot' })
  expect((await drawn(ui)).has("Doesn't need it 1")).toBe(true)
  expect((await drawn(ui)).has('Send is for all of them')).toBe(true)
  // a part of another size skips no item: the first 40 so long that 20 are drawn, the rest 40 at a time
  log.files[`${ROOT}/.vid/face/sitting.json`] = edited(long(170), s => { s.sections[0].items.forEach((x: any, i: number) => { x.detail = i < 40 ? ['y'.repeat(7000)] : [] }) })
  await reread($)
  for (let i = 0; i < 12; i++) if (await ui.find({ type: 'Button', key: 'contract-earlier-top' })) await ui.press({ key: 'contract-earlier-top' })
  const got = new Set<string>()
  for (let i = 0; i < 12; i++) {
    for (const t of ruled((await drawn(ui)).all)) got.add(t)
    if (!(await ui.find({ type: 'Button', key: 'contract-later-top' }))) break
    await ui.press({ key: 'contract-later-top' })
  }
  expect(got.size).toBe(170)
  // many short sections are drawn in parts too
  log.files[`${ROOT}/.vid/face/sitting.json`] = long(9, 12)
  await reread($)
  expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
  expect((await drawn(ui)).all).not.toContain('This panel is too long for the app to draw')
  // past even that: said, with a way back, the marks kept
  log.files[`${ROOT}/.vid/face/sitting.json`] = long(200, 80)
  await reread($)
  expect((await drawn(ui)).all).toContain('This panel is too long for the app to draw')
  log.files[`${ROOT}/.vid/face/sitting.json`] = long(47)
  await reread($)
  expect((await drawn(ui)).has('Send is for all of them')).toBe(false)
  await ui.unmount()
})

test('FB-5 A1 what one press unfolds past the bound can be folded again: the marks kept', async ($, on) => {
  const log = await start($, on, listed(l => { ofPlan(l, 3, 15); l.rest.holds = Array.from({ length: 420 }, (_, i) => ({ id: `B${i}`, words: `What ViD holds ${i}`, where: 'in The rest' })) }))
  const ui: any = await $.ui.mount(PANE('desktop', 110))
  expect((await drawn(ui)).all).toContain('How long a loan lasts')
  await ui.press({ key: 'holds' })
  expect((await drawn(ui)).all).toContain('This panel is too long for the app to draw')
  await ui.press({ key: 'fold' })
  expect((await drawn(ui)).all).toContain('How long a loan lasts')
  await ui.unmount()
  void log
})

test('FB-5 A1 a press that makes a long list too long to draw whole leaves its item on show', async ($, on) => {
  const of = (n: number) => edited(PAUSE1_47, s => {
    const sec = s.sections.find((x: any) => x.kind === 'decided' && x.acts.some((a: any) => a.words))
    const item = s.sections.find((x: any) => x.items.length).items[0]
    s.sections = [{ ...sec, empty: '', items: Array.from({ length: n }, (_, i) => ({ ...item, recommend: '', id: `X${i}`, text: `Rule ${i} holds`, detail: [], look: '' })) }]
  })
  const sec = JSON.parse(of(1)).sections[0]
  const act = sec.acts.find((a: any) => a.words).id
  const log = await start($, on, { standing: PAUSE1_STANDING, sitting: of(60) })
  const ui: any = await $.ui.mount(PANE('desktop', 110))
  let n = 60
  while (!(await ui.find({ type: 'Button', key: `${sec.id}-later-top` }))) {
    log.files[`${ROOT}/.vid/face/sitting.json`] = of(++n)
    await reread($)
  }
  log.files[`${ROOT}/.vid/face/sitting.json`] = of(--n)
  await reread($)
  expect(await ui.find({ type: 'Button', key: `${sec.id}-later-top` })).toBeUndefined()
  for (let i = n - 1; i > n - 30; i--) {
    await ui.press({ key: `${sec.id}/X${i}-${act}` })
    expect(await ui.find({ type: 'Input', key: `${sec.id}/X${i}-words` })).toBeDefined()
    if (await ui.find({ type: 'Button', key: `${sec.id}-earlier-top` })) break
  }
  expect(await ui.find({ type: 'Button', key: `${sec.id}-earlier-top` })).toBeDefined()
  await ui.unmount()
})

test('FB-5 A1 a long draft is drawn in its first items, and says how many more; a plan with no team says its steps are left out', async ($, on) => {
  const log = await start($, on, { standing: DRAFT_STANDING, sitting: edited(DRAFT, s => {
    const sec = s.sections.find((x: any) => x.items.length)
    s.sections = [{ ...sec, items: Array.from({ length: 500 }, (_, i) => ({ ...sec.items[0], id: `D${i}`, text: `Draft ${i}`, detail: ['one', 'two'] })) }]
  }), run: RUNNING })
  const ui: any = await $.ui.mount(PANE('desktop', 110))
  const { has } = await drawn(ui)
  expect(has('Still changing')).toBe(true)
  expect(has('and 460 more, to see when ViD has finished')).toBe(true)
  await ui.unmount()
  void log
})

test('FB-5 A1 a plan given up says so in The plan, with no team too; long names that hover are counted', async ($, on) => {
  const log = await start($, on, listed(l => { ofPlan(l, 1, 1000); l.teams = [] }))
  const ui: any = await $.ui.mount(PANE('desktop', 56))
  expect((await drawn(ui)).has('Its steps are too many to draw here')).toBe(true)
  expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { ofPlan(l, 1, 3); l.teams = []; l.plan.releases[0].steps.forEach((x: any, i: number) => { x.id = 'X'.repeat(32000) + i }) })
  await reread($)
  expect(inBounds(await ($ as any).ui.render(PANE('desktop', 56) as any))).toBe(true)
  await ui.unmount()
})

test('FB-5 A1 a section that is no team is named as it stands, and steps in no release under no release', async ($, on) => {
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop', 110))
  const { all } = await drawn(ui)
  expect(all).toContain('Tickets of no step in the plan')
  expect(all).not.toContain('Team Tickets of no step in the plan')
  expect(all).toContain('Signs')
  expect(all.some((x: string) => x.startsWith('Release -1'))).toBe(false)
  await ui.unmount()
})

test('FB-5 A1 a link of the top row scrolls to its section; refused, the panel stays as it is', async ($, on) => {
  const asked: any[] = []
  const engine = (answer: () => unknown): any => ({ ui: { scroll: async (a: any) => (asked.push(a), answer()) } })
  await goTo(engine(() => ({})), 'vid', 5)
  await goTo(engine(() => ({ deny: 'another move came first' })), 'vid', 6)
  await goTo(engine(() => { throw new Error('no surface') }), 'vid', 7)
  await goTo(engine(() => ({})), 'vid', 0)
  expect(asked).toEqual([...[5, 6, 7].map(n => ({ to: { key: `top-${n}` }, in: 'vid', block: 'start' })), { to: 'start', in: 'vid' }])
  // in the panel: the kit refuses a module's own scroll, and the press breaks nothing
  await start($, on, listed())
  const ui = await $.ui.mount(PANE('desktop'))
  const before = (await drawn(ui)).all
  await ui.press({ key: 'go-5' })
  expect((await drawn(ui)).all).toEqual(before)
  // the app knows where a drawing's buttons stand and of no box: what a link moves to is a button, at every size, and pressed too it breaks nothing
  await ui.press({ key: 'top-5' })
  expect((await drawn(ui)).all).toEqual(before)
  await ui.unmount()
})

test('FB-5 A1 with a list and an empty backlog it opens by itself, once, never with the keys', async ($, on) => {
  const log = await start($, on, { standing: edited(WORKING_STANDING, s => { s.backlog = { items: [], done: [], doneCount: 0 } }), run: STOPPED, list: LIST() })
  expect(log.opens).toHaveLength(1)
  expect(log.opens[0].focus).toBeUndefined()
  await $.turn.complete({ answer: 'done', stop: 'stop' } as any).catch(() => undefined)
  expect(log.opens).toHaveLength(1)
})

test('FB-5 A1 the pages to read stand once, at the foot of the list', async ($, on) => {
  await start($, on, listed(undefined, { standing: withPages(withBacklog(WORKING_STANDING, allDone)) }))
  const ui = await $.ui.mount(PANE('desktop'))
  const { all } = await drawn(ui)
  expect(all.filter(t => t === 'To read:')).toHaveLength(1)
  expect(all.indexOf('To read:')).toBeGreaterThan(all.findIndex(t => t.startsWith('Drawn from')))
  expect(all.findIndex(t => t.startsWith('Drawn from'))).toBeGreaterThan(all.lastIndexOf('Team East'))
  expect(all.findIndex(t => t.startsWith('The technical foundation: '))).toBeGreaterThan(all.indexOf('To read:'))
  expect((await ui.findAll({ type: 'Link' })).filter((l: any) => l.props.label === 'The PRD')).toHaveLength(1)
  await ui.unmount()
})

test('FB-5 A1 a second answer in the message box starts on a new line; the first does not', async ($, on) => {
  const log = await start($, on, listed(undefined, { drop: 'the session is busy' }))
  const ui = await $.ui.mount(PANE('desktop'))
  await ui.press({ key: 'ans-Q12-B3-0-1' })
  await ui.press({ key: 'line-Q20' })
  await ui.press({ key: 'ans-Q20-0-1' })
  expect(log.fills).toEqual(['1.1 · How long a loan lasts: Two weeks (Q12, B3)', '\n1.4 · Tell Bo the shelf is ready: Sent (Q20)'])
  await ui.unmount()
})

test('FB-5 A1 a read of the same files draws nothing again; a list written again is drawn', async ($, on) => {
  mock.clock(on, { now: Date.parse('2026-11-20T16:00:00Z') })
  let sets = 0
  on('state.set', { plugin: 'vid', key: 'view' } as any, (_: any, e: any, next: any) => {
    sets++
    return next(e)
  })
  const log = await start($, on, listed(undefined, { clock: true }))
  const ui = await $.ui.mount(PANE('desktop'))
  expect(sets).toBeGreaterThan(0)
  sets = 0
  await reread($)
  await reread($)
  expect(sets).toBe(0)
  log.files[`${ROOT}/.vid/face/list.json`] = LIST(l => { l.written = '2026-11-20T16:00:00Z' })
  await reread($)
  expect(sets).toBe(1)
  await ui.unmount()
})

test('FB-5 A1 what was weighed and left out, with no stop before the next', async ($, on) => {
  await start($, on, listed(l => { l.rest.leftOut = ['a new plan, since nothing is accepted.', 'more steps', 'a fine.'] }))
  const ui = await $.ui.mount(PANE('desktop'))
  expect((await drawn(ui)).all).toContain('Weighed and left out: a new plan, since nothing is accepted; more steps; a fine.')
  await ui.unmount()
})
