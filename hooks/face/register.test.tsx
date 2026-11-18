import { expect, mock, test } from 'claude-code/testing'

import { DRAFT, DRAFT_STANDING, ENDED, INTERVIEW, INTERVIEW_F1, INTERVIEW_STANDING, PAUSE1_47, PAUSE1_STANDING, PAUSE2, PAUSE2_STANDING, DESIGN_STANDING, WORKING_STANDING } from './samples'

// ViD's face (0.26.10.29): the panel drawn as the desktop app draws it. Each
// hook here stands for the engine: the project's files, the session, the
// prompt. Every test names the requirement it proves.

const ROOT = '/project'
type World = { clock?: boolean; standing?: string; sitting?: string; run?: string; panes?: { id: string; title: string }[]; session?: string; surfaces?: string[]; version?: string; vid?: boolean; drop?: string; unfilled?: boolean }
type Log = { submits: string[]; fills: string[]; opens: any[]; writes: { path: string; text: string }[]; files: Record<string, string>; notices: string[] }

function world(on: any, w: World, log: Log) {
  const files = log.files
  const sess = w.session ?? 'sess-A'
  if (w.standing !== undefined) files[`${ROOT}/.vid/face/standing.json`] = w.standing
  if (w.sitting !== undefined) files[`${ROOT}/.vid/face/sitting.json`] = w.sitting
  if (w.run !== undefined) files[`${ROOT}/.vid/face/run.${sess}`] = w.run
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
    return w.drop ? { drop: w.drop } : { text: e.text }
  })
  on('prompt.fill', (_: any, e: any) => {
    log.fills.push(e.text)
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

const newLog = (): Log => ({ submits: [], fills: [], opens: [], writes: [], files: {}, notices: [] })

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
