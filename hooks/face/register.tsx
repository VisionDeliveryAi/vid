import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { FaceItem, FaceSection, Marks, Run, Sitting, Standing, View } from './types'
import { aloneLine, answerable, asRecommended, atStart, besides, blankMarks, compose, filterList, footLine, isAlone, keyOf, marked, merged, mk, modeOf, needsAnswer, parseRun, parseSitting, parseStanding, presetMarks, restorable, running, sendable, shown, startOf, tally, versionNote, waitLines } from './model'
import { recordStop } from './recorder'

// ViD's face, step 1a (0.26.10.29): the panel in the Claude desktop app for
// the map of the nine stops and the four PRD sittings. It reads the two
// files checks/face.sh writes (.vid/face/), keeps marks not yet sent in the
// store Claude Code gives it, and sends the person's words; it writes no
// file and runs no program. Its look is the panel's design (ViD's own repository),
// drawn with the desktop panel's own elements only: the fast "Client" part
// draws with a terminal's elements, so it is used for nothing. The panel
// cannot learn the theme: words use the theme's named colours; tints, lines
// and fills the design's "either theme" colours; drawings mid colours.

const PANE = 'vid'
const TITLE = 'ViD'
const DIR = '.vid/face'

// From the design's vid-tokens.css, the either-theme values.
const LINE = '#8a887f33'
const FILL = '#8a887f12'
const TINT = { claude: '#d0734f22', success: '#4f9c6c22' }
const INK = { claude: '#d0734f', success: '#4f9c6c', warning: '#c08a34', subtle: '#8a887f' }
const SHORT = ['Describe', 'Interview', 'Summary', 'Gaps', 'Final wording', 'Tech hints', 'Design', 'Test list', 'Releases']
const TONE: Record<string, string> = { keep: 'success', ok: 'success', in: 'success', fix: 'success', accept: 'success', apart: 'success', cut: 'error', out: 'warning', decline: 'warning', overrule: 'warning', merge: 'suggestion', change: 'suggestion', answer: 'suggestion' }

// usability (P4, P5): the view holds its conversation's run file and the minute it was read, so the wait is redrawn
// when the minute changes
const blankView: View = { standing: null, sitting: null, run: null, problem: '', project: false, here: '', version: '', opened: '', minute: 0, now: 0, moved: { from: 0, to: 0, at: 0 } }
const view = atom({ plugin: 'vid', key: 'view' } as const, blankView, { shape: 'face-view-4' })
// usability (P11): how long a new stretch of the map's line is drawn moving after the stop moved on
const MOVING_MS = 4000
const marks = atom({ plugin: 'vid', key: 'marks' } as const, {}, { shape: 'face-marks-1' })

async function exists($: EngineInterface, path: string): Promise<boolean> {
  try {
    return await $.fs.exists(path)
  } catch {
    return false
  }
}

// Reads the three files. A missing file is "nothing yet"; one that cannot be
// read is said in one line, never drawn half. usability (P4): with no run file for its conversation the session
// is taken as stopped.
async function refresh($: EngineInterface): Promise<View> {
  const root = await $.session.root()
  const dir = `${root}/${DIR}`
  const project = (await exists($, `${root}/.vid`)) || (await exists($, `${root}/PRD.md`))
  let standing: Standing | null = null
  let sitting: Sitting | null = null
  let problem = ''
  if (await exists($, `${dir}/standing.json`)) {
    try {
      const p = parseStanding(String(await $.fs.read(`${dir}/standing.json`)))
      standing = p.value
      problem = p.problem
    } catch {
      problem = 'The standing file could not be read.'
    }
  }
  if (!problem && (await exists($, `${dir}/sitting.json`))) {
    try {
      const p = parseSitting(String(await $.fs.read(`${dir}/sitting.json`)))
      sitting = p.value
      problem = p.problem
    } catch {
      problem = 'The sitting file could not be read.'
    }
  }
  let here = ''
  let version = ''
  try {
    here = await $.session.id()
  } catch {
    here = ''
  }
  try {
    version = (await $.session.version()).base ?? ''
  } catch {
    version = ''
  }
  let run: Run | null = null
  if (/^[A-Za-z0-9_-]+$/.test(here) && (await exists($, `${dir}/run.${here}`))) {
    try {
      run = parseRun(String(await $.fs.read(`${dir}/run.${here}`)))
    } catch {
      run = null
    }
  }
  // usability (P5): the time from the engine's clock, so a test's clock moves it
  let nowMs = Date.now()
  try {
    nowMs = await $.clock.now()
  } catch {
    nowMs = Date.now()
  }
  const before = await read($, view)
  // usability (P11): the stop moved on since the panel last read the standing
  const moved = before.standing && standing && standing.current > before.standing.current ? { from: before.standing.current, to: standing.current, at: nowMs } : before.moved
  const next: View = { standing, sitting, run, problem, project, here, version, opened: before.opened, minute: Math.floor(nowMs / 60000), now: nowMs, moved }
  await update($, view, () => next)
  // marks made on one sitting never appear on another: a new sitting drops the rest
  if (sitting) {
    const key = keyOf(sitting)
    const all = await read($, marks)
    if (Object.keys(all).some(k => k !== key)) {
      const kept: Record<string, Marks> = all[key] ? { [key]: all[key] } : {}
      await update($, marks, () => kept)
      await save($, kept)
    }
  }
  return next
}

// The store is shared by every conversation in the project: a send any of them
// recorded is kept, never overwritten by another's unsent marks.
async function stored($: EngineInterface): Promise<Record<string, Marks>> {
  try {
    const kept = await $.store.get('marks')
    return kept && typeof kept === 'object' ? (kept as Record<string, Marks>) : {}
  } catch {
    return {}
  }
}

// A send the app refused clears its receipt in the store too, as it stands.
async function unsend($: EngineInterface, key: string, refused: string): Promise<void> {
  let mine = blankMarks()
  await update($, marks, cur => {
    mine = { ...(cur[key] ?? blankMarks()), sentAt: '', sentText: '', sentHow: '', refused }
    return { ...cur, [key]: mine }
  })
  try {
    const before = await stored($)
    await $.store.set('marks', { ...before, [key]: mine })
  } catch {
    // the store refused: the panel still shows the sitting unsent
  }
}

async function save($: EngineInterface, all: Record<string, Marks>): Promise<void> {
  try {
    const before = await stored($)
    const out: Record<string, Marks> = {}
    for (const [k, m] of Object.entries(all)) out[k] = merged(before[k], m)
    await $.store.set('marks', out)
  } catch {
    // the store refused (over its size): the marks stay for this session
  }
}

async function restore($: EngineInterface): Promise<void> {
  const now = await read($, marks)
  if (Object.keys(now).length) return
  try {
    const kept = await $.store.get('marks')
    if (kept && typeof kept === 'object') await update($, marks, () => kept as Record<string, Marks>)
  } catch {
    // nothing kept
  }
}

async function onDesktop($: EngineInterface): Promise<boolean> {
  try {
    return (await $.session.surfaces()).includes('desktop')
  } catch {
    return false
  }
}

// Opens the panel by itself once per sitting that waits; never with the keys.
async function openIfWaiting($: EngineInterface, v: View): Promise<void> {
  if (!v.sitting || !v.standing || v.problem) return
  if (modeOf(v.standing, v.sitting, blankMarks(), '', v.project, v.run) !== 'sitting') return
  const key = keyOf(v.sitting)
  if (v.opened === key || !(await onDesktop($))) return
  await update($, view, cur => ({ ...cur, opened: key }))
  // usability (P12): the sitting's phrase as the pane's title; the same phrase is the panel's first line
  await $.ui.open({ id: PANE, title: v.sitting.ready || TITLE })
}

// usability (P12): when no sitting waits on the person (none written, or this one sent), an open pane is titled ViD
async function retitle($: EngineInterface, v: View): Promise<void> {
  try {
    const m = v.sitting ? marksOf(v.sitting, (await read($, marks))[keyOf(v.sitting)]) : blankMarks()
    if (modeOf(v.standing, v.sitting, m, v.problem, v.project, v.run) === 'sitting') return
    const pane = (await $.ui.panes()).find(x => x.id === PANE)
    if (pane && pane.title !== TITLE) await $.ui.open({ id: PANE, title: TITLE })
  } catch {
    // the next read titles it
  }
}

// A read after a tool call or a turn never fails what it follows.
// The working state's foot: when the person's answers went, else when the sitting ended, in local time.
function lastWent(s: Sitting | null, all: Record<string, Marks>): string {
  if (!s || s.state !== 'ended') return ''
  const sent = all[keyOf(s)]?.sentAt
  if (sent) return `Your answers to ${s.title.charAt(0).toLowerCase() + s.title.slice(1)} went at ${sent}.`
  const t = new Date(s.ended)
  if (Number.isNaN(t.getTime())) return ''
  return `The last sitting ended at ${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}.`
}

async function settle($: EngineInterface): Promise<void> {
  try {
    const v = await refresh($)
    await openIfWaiting($, v)
    await retitle($, v)
  } catch {
    // the next event reads again
  }
}

// usability (P1): a sitting with no marks yet starts at its presets
const marksOf = (s: Sitting, kept: Marks | undefined): Marks => kept ?? presetMarks(s)

async function mutate($: EngineInterface, s: Sitting, fn: (m: Marks) => Marks): Promise<void> {
  const key = keyOf(s)
  let saved: Record<string, Marks> = {}
  await update($, marks, all => {
    saved = { ...all, [key]: fn(marksOf(s, all[key])) }
    return saved
  })
  await save($, saved)
}

async function sendIt($: EngineInterface): Promise<void> {
  const v = await read($, view)
  const s = v.sitting
  if (!s) return
  const key = keyOf(s)
  const all = await read($, marks)
  const m = merged((await stored($))[key], marksOf(s, all[key]))
  if (m.sentAt) {
    await update($, marks, cur => ({ ...cur, [key]: m }))
    return
  }
  // usability (P7): never while a question asked on its own has no answer
  if (tally(s, m).alone > 0) return
  const { text } = compose(s, m)
  const t = new Date()
  const at = String(t.getHours()).padStart(2, '0') + ':' + String(t.getMinutes()).padStart(2, '0')
  const can = sendable(s, v.here)
  await mutate($, s, cur => ({ ...cur, sentAt: at, sentText: text, sentHow: can.ok ? 'sent' : 'filled', refused: '' }))
  let refused = ''
  try {
    const r = can.ok ? await $.prompt.submit({ text, asUser: true }) : await $.prompt.fill({ text, mode: 'replace' })
    if (r && typeof r === 'object' && 'drop' in r) refused = String((r as { drop: unknown }).drop || 'the app did not take it')
    else if (r && typeof r === 'object' && 'isFilled' in r && (r as { isFilled: unknown }).isFilled === false) refused = 'the message box could not take the words just now'
  } catch (err) {
    refused = err instanceof Error ? err.message : 'the app did not take it'
  }
  // a send the app refused is not a send: the sitting takes an answer again
  if (refused) await unsend($, key, refused)
  else await retitle($, await read($, view))
}

// usability (P11): the map as a journey, one piece a stop, so a done stop can show what was agreed there on hover.
// A done stop is filled and the line runs on from it; the stretch into the current stop, just moved on to, is drawn
// moving once (a CSS animation, which reduced motion turns off).
function stopSvg(i: number, n: number, states: string[], width: number, wide: boolean, grow: 'left' | 'right' | ''): string {
  const W = Math.max(24, Math.floor(width)), H = wide ? 54 : 30, cy = 15, x = W / 2, k = i + 1
  const style = grow ? `<style>@keyframes vidgrow{from{stroke-dashoffset:${W}}to{stroke-dashoffset:0}}.grow{stroke-dasharray:${W};animation:vidgrow .5s ease-out both${grow === 'left' ? ' .5s' : ''}}@media (prefers-reduced-motion: reduce){.grow{animation:none;stroke-dasharray:none}}</style>` : ''
  let s = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${style}`
  const line = (x1: number, x2: number, on: boolean, cls: boolean) =>
    `<line${cls ? ' class="grow"' : ''} x1="${x1}" y1="${cy}" x2="${x2}" y2="${cy}" stroke="${INK.subtle}" stroke-opacity="${on ? 1 : 0.4}" stroke-width="1.5" stroke-linecap="round"/>`
  if (i > 0) s += line(0, x - 11, states[i - 1] === 'done', grow === 'left')
  if (i < n - 1) s += line(x + 11, W, states[i] === 'done', grow === 'right')
  if (states[i] === 'done') {
    s += `<circle cx="${x}" cy="${cy}" r="9" fill="${INK.subtle}"/><path d="M${x - 4} ${cy + 0.2} L${x - 1.2} ${cy + 3} L${x + 4.2} ${cy - 2.8}" fill="none" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>`
  } else if (states[i] === 'here') {
    s += `<circle cx="${x}" cy="${cy}" r="13.5" fill="${INK.claude}" fill-opacity="0.18"/><circle cx="${x}" cy="${cy}" r="9" fill="${INK.claude}"/><text x="${x}" y="${cy + 3.6}" text-anchor="middle" font-family="-apple-system,system-ui,sans-serif" font-size="10" font-weight="700" fill="#ffffff">${k}</text>`
  } else {
    s += `<circle cx="${x}" cy="${cy}" r="8.25" fill="none" stroke="${INK.subtle}" stroke-opacity="0.75" stroke-width="1.5"/><text x="${x}" y="${cy + 3.5}" text-anchor="middle" font-family="-apple-system,system-ui,sans-serif" font-size="10" font-weight="500" fill="${INK.subtle}">${k}</text>`
  }
  if (wide) {
    s += `<text x="${x}" y="47" text-anchor="middle" font-family="-apple-system,system-ui,sans-serif" font-size="11" font-weight="${states[i] === 'here' ? 600 : 400}" fill="${states[i] === 'here' ? INK.claude : INK.subtle}">${SHORT[i] ?? k}</text>`
  }
  return s + '</svg>'
}

const ICON = {
  sent: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><circle cx="10" cy="10" r="10" fill="${INK.success}"/><path d="M5.5 10.2 L8.6 13.2 L14.5 7" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  idle: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><circle cx="10" cy="10" r="9" fill="none" stroke="${INK.success}" stroke-width="1.8"/><path d="M6 10.2 L8.8 13 L14 7.4" fill="none" stroke="${INK.success}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  working: `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="20" viewBox="0 0 36 20">${[0, 1, 2].map(i => `<circle cx="${6 + i * 12}" cy="10" r="3.5" fill="${INK.claude}"><animate attributeName="opacity" values="1;0.25;1" dur="1.2s" repeatCount="indefinite" begin="${i * 0.2}s"/></circle>`).join('')}</svg>`,
  problem: `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><circle cx="10" cy="10" r="9" fill="none" stroke="${INK.warning}" stroke-width="1.8"/><path d="M10 5.5 L10 11" stroke="${INK.warning}" stroke-width="2" stroke-linecap="round"/><circle cx="10" cy="14.2" r="1.2" fill="${INK.warning}"/></svg>`,
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'vid-panel', description: "Open ViD's panel: the map of the nine stops and the sitting that waits on you" })
    await restore($)
    const v = await refresh($)
    await openIfWaiting($, v)
    await retitle($, v)
    void $.clock.every(5000, async () => {
      void settle($)
    })
    return next(e)
  })

  on('session.attach', async ($, e, next) => {
    const ran = await next(e)
    if (e.surface === 'desktop') void settle($)
    return ran
  })

  // face.sh runs as a tool call: read the files again as soon as it ends
  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    void settle($)
    return ran
  })

  // usability (P4): the end of every turn, an interrupted one too, goes to the recorder first
  on('turn.complete', async ($, e, next) => {
    const ran = await next(e)
    await recordStop($, e)
    void settle($)
    return ran
  })

  on('command.run', { command: 'vid-panel' }, async $ => {
    if (!(await onDesktop($))) return { text: "ViD's panel is in the Claude desktop app only. Here, everything ViD asks is in the chat." }
    const v = await refresh($)
    const waiting = v.sitting && modeOf(v.standing, v.sitting, marksOf(v.sitting, (await read($, marks))[keyOf(v.sitting)]), v.problem, v.project, v.run) === 'sitting'
    await $.ui.open({ id: PANE, title: waiting && v.sitting?.ready ? v.sitting.ready : TITLE })
    return { text: "ViD's panel opened." }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e, next) => {
    if (e.surface !== 'desktop') return next(e)
    const { Box, Text, Button, Input, Link } = $.ui.resolve(e)
    const Svg = $.ui.resolve(e).Svg as unknown as (p: { source: string; alt: string }) => unknown
    const pic = (source: string, alt: string) => <Svg source={source} alt={alt} />
    const v = await read($, view)
    const all = await read($, marks)
    const s = v.sitting
    const key = s ? keyOf(s) : ''
    const m: Marks = s ? marksOf(s, all[key]) : blankMarks()
    const mode = modeOf(v.standing, s, m, v.problem, v.project, v.run)
    const cols = e.props.bodyColumns ?? 44
    const wide = cols >= 90
    const px = Math.max(240, Math.min(848, (cols - 4) * 8))
    const set = (fn: (x: Marks) => Marks) => {
      if (s) void mutate($, s, fn)
    }
    const subtle = (words: string, size: 'footnote' | 'caption' = 'footnote') => (
      <Text size={size} color="subtle">
        {words}
      </Text>
    )
    const dot = (tone: string, filled = true) => <Text color={tone}>{filled ? '●' : '○'}</Text>

    const st = v.standing
    const stops = st ? st.stops : []
    const cur = st ? st.current : 1
    const here = stops[cur - 1]
    const movingNow = v.moved.to === cur && v.moved.to > 0 && v.now - v.moved.at < MOVING_MS
    const turn = mode === 'sitting' || (mode === 'sent' && m.sentHow === 'filled') ? (mode === 'sitting' ? 'Your turn' : 'Your turn, in the chat') : mode === 'stopped' ? 'ViD has stopped' : mode === 'idle' ? 'Your turn, in the chat' : mode === 'done' ? 'All done' : "ViD's turn"
    const head = st ? (
      <Box flexDirection="column" gap={1}>
        <Box flexDirection="row">
          {stops.map((x, i) => {
            const states = stops.map(y => y.state)
            const grow = movingNow ? (i === cur - 2 ? 'right' : i === cur - 1 ? 'left' : '') : ''
            return (
              // usability (P11): the hover sits on the visible piece; its hidden line joins the same scope
              <Box key={`stop-${x.n}`} position="relative" hover={{ scope: `vid-stop-${x.n}` }}>
                {pic(stopSvg(i, stops.length, states, px / stops.length, wide, grow), `Step ${x.n}, ${x.name}: ${x.state === 'done' ? 'done' : x.state === 'here' ? 'here' : 'to come'}`)}
                {x.state === 'done' && x.agreed ? (
                  <Box position="absolute" top={wide ? 4 : 2} left={0} display="none" hover={{ scope: `vid-stop-${x.n}`, display: 'flex' }} paddingX={1} backgroundColor={FILL} borderStyle="round" borderColor={LINE}>
                    <Text size="caption">
                      {x.agreed}
                    </Text>
                  </Box>
                ) : null}
              </Box>
            )
          })}
        </Box>
        {/* usability (P9): what there is to read, under the map and above everything else */}
        {st.pages.length ? (
          <Box flexDirection="column">
            <Text size="caption" weight="semibold" color="subtle">
              To read:
            </Text>
            {st.pages.map(p => (
              <Box key={`page-${p.id}`}>{p.link ? <Link href={p.link} label={p.title} /> : <Text size="footnote">{`${p.title}: ${p.file}`}</Text>}</Box>
            ))}
          </Box>
        ) : null}
        <Box flexDirection="column">
          <Text size="title" weight="semibold">
            {mode === 'done' ? 'Defining the project is done' : (here?.name ?? '')}
          </Text>
          <Text size="footnote" color="subtle" tabular>
            {mode === 'done' ? `All ${stops.length} steps done` : `Step ${cur} of ${stops.length} · ${turn}${st.next ? ` · Next: ${st.next}` : ''}`}
          </Text>
        </Box>
      </Box>
    ) : null
    const vnote = versionNote(v.version)

    const state = (icon: string, title: string, line: string, foot: string) => (
      <Box flexDirection="column" gap={1} padding={2} borderStyle="round" borderColor={LINE}>
        {pic(icon, title)}
        <Text size="heading" weight="semibold">
          {title}
        </Text>
        <Text color="subtle">{line}</Text>
        {foot ? subtle(foot) : null}
      </Box>
    )

    let body: unknown = null
    if (mode === 'problem') {
      body = state(ICON.problem, "This panel can't show this sitting", 'Carry on in the chat. ViD has asked the same things there, and nothing is lost.', v.problem)
    } else if (mode === 'none') {
      body = state(ICON.idle, 'No ViD project here', 'This panel shows a ViD project: the map of defining it and what waits on you. Start one in the chat with /vid init or /vid create-prd.', '')
    } else if (mode === 'idle') {
      body = state(ICON.idle, 'Nothing waits on you here', 'Describe the product in the chat, in your own words. When ViD has questions, this panel opens by itself.', '')
    }
    // usability (P5, P6): the wait's time, last step and parts, while the session runs
    const waitBits = () => {
      const parts = st ? st.wait.parts : []
      return [
        ...waitLines(v.run, v.now).map(l => (
          <Text size="footnote" color="subtle" tabular>
            {l}
          </Text>
        )),
        parts.length && running(v.run) ? (
          <Box flexDirection="column" paddingTop={1}>
            {parts.map(p => (
              <Text size="footnote" color={p.state === 'now' ? 'claude' : 'subtle'} weight={p.state === 'now' ? 'semibold' : 'regular'}>
                {`${p.state === 'done' ? '✓' : p.state === 'now' ? '●' : '○'} ${p.name}`}
              </Text>
            ))}
          </Box>
        ) : null,
        st && st.wait.now && running(v.run) ? <Text size="footnote">{`Now: ${st.wait.now}`}</Text> : null,
      ]
    }
    if (body !== null) {
      // drawn above
    } else if (mode === 'drafting' && s) {
      // usability (P13): what ViD has drafted so far, its cards with no button and no send
      body = (
        <Box flexDirection="column" gap={2}>
          <Box flexDirection="column" gap={1}>
            {waitBits()}
            <Text size="heading" weight="semibold">{`ViD is drafting ${s.title.charAt(0).toLowerCase() + s.title.slice(1)}. Still changing.`}</Text>
          </Box>
          {s.sections
            .filter(x => !x.empty && x.items.length)
            .map(x => (
              <Box key={`draft-${x.id}`} flexDirection="column" gap={1}>
                <Text size="heading" weight="semibold">
                  {x.title}
                </Text>
                <Box flexDirection="column" borderStyle="round" borderColor={LINE}>
                  {x.items.map(it => (
                    <Box flexDirection="column" paddingX={2} paddingY={1}>
                      {m.ids ? subtle(it.id, 'caption') : null}
                      <Text>{it.text}</Text>
                      {shown(it.detail, m.ids).map(d => subtle(d))}
                    </Box>
                  ))}
                </Box>
              </Box>
            ))}
        </Box>
      )
    } else if (mode === 'working') {
      // usability (P4, P5, P6): the stop, then the time, the last step and the wait's parts
      body = (
        <Box flexDirection="column" gap={1} padding={2} borderStyle="round" borderColor={LINE}>
          {pic(ICON.working, 'Working')}
          <Text size="heading" weight="semibold">
            {here ? `ViD is working on ${here.name.charAt(0).toLowerCase() + here.name.slice(1)}` : 'ViD is working'}
          </Text>
          {here && !here.sitting ? <Text color="subtle">This stop's questions come in the chat, not here.</Text> : <Text color="subtle">Nothing to do until it asks. You can keep talking in the chat.</Text>}
          {waitBits()}
          {lastWent(s, all) ? subtle(lastWent(s, all)) : null}
        </Box>
      )
    } else if (mode === 'stopped') {
      body = state(ICON.idle, 'ViD has stopped. Look at the chat.', 'If it asked you something, the question is there. The next sitting shows here when ViD writes it.', lastWent(s, all))
    } else if (mode === 'done') {
      body = state(ICON.sent, 'Every stop is done', 'The PRD, the technical foundation, the design, the test list and the releases are agreed. What comes next is in the chat.', '')
    } else if (mode === 'sent' && s) {
      const { groups } = compose(s, m)
      const filled = m.sentHow === 'filled'
      body = (
        <Box flexDirection="column" gap={2}>
          <Box flexDirection="row" gap={2} padding={2} backgroundColor={filled ? TINT.claude : TINT.success}>
            {pic(filled ? ICON.problem : ICON.sent, filled ? 'In the message box' : 'Sent')}
            <Box flexDirection="column" flexShrink={1}>
              <Text size="heading" weight="semibold">
                {filled ? `Put in your message box at ${m.sentAt}` : `Sent to ViD at ${m.sentAt}`}
              </Text>
              {subtle(filled ? sendable(s, v.here).why : 'ViD has your answers. This sitting takes no second answer; the panel moves on when ViD asks again.')}
            </Box>
          </Box>
          {/* usability (P4): the sitting still waits and the session has stopped */}
          {!running(v.run) ? <Text weight="semibold">ViD has stopped. Look at the chat.</Text> : null}
          <Text size="heading" weight="semibold">
            {filled ? 'What is in the message box' : 'What was sent'}
          </Text>
          {groups.map(g => (
            <Box flexDirection="column" borderStyle="round" borderColor={LINE}>
              <Box paddingX={2} paddingY={1} backgroundColor={FILL}>
                <Text size="caption" weight="semibold" color="subtle">
                  {g.title}
                </Text>
              </Box>
              {g.rows.map(r => (
                <Box flexDirection="column" paddingX={2} paddingY={1}>
                  {subtle(r.label)}
                  <Text weight="medium">{r.value}</Text>
                </Box>
              ))}
              {g.rest ? (
                <Box paddingX={2} paddingY={1}>
                  {subtle(g.rest)}
                </Box>
              ) : null}
            </Box>
          ))}
          {s.closing ? <Text>{s.closing}</Text> : null}
          <Button key="raw" plain onPress={() => set(x => ({ ...x, raw: !x.raw }))}>
            <Text color="suggestion" weight="medium">
              {m.raw ? 'Hide the message' : 'Show the message exactly as sent'}
            </Text>
          </Button>
          {m.raw ? (
            <Box padding={2} backgroundColor={FILL}>
              <Text size="footnote" mono>
                {m.sentText}
              </Text>
            </Box>
          ) : null}
        </Box>
      )
    } else if (mode === 'sitting' && s) {
      // usability (P1, P2, P7): the foot's counts, the way back to ViD's recommendations, the send held back
      const c = tally(s, m)
      const foot = footLine(c)
      const readSec = s.sections.find(x => x.kind === 'text' && !x.empty)
      const anyBack = s.sections.some(x => restorable(x, m))
      const can = sendable(s, v.here)
      const send = () => {
        void sendIt($)
      }
      const sendOr = (k: string) =>
        c.alone ? (
          <Text key={`${k}-held`} size="footnote" weight="semibold" color="claude">
            {aloneLine(c.alone)}
          </Text>
        ) : (
          <Button key={k} variant="primary" {...(k === 'send' ? { hotkey: 's' } : {})} onPress={send}>
            {s.send}
          </Button>
        )

      const waits = (
        <Box flexDirection="column" gap={1} padding={2} backgroundColor={TINT.claude}>
          <Box flexDirection="row" gap={1}>
            {dot('claude')}
            <Text size="caption" weight="semibold" color="claude">
              Waits on you
            </Text>
          </Box>
          <Text size="heading" weight="semibold" tabular>
            {foot}
          </Text>
          {readSec ? subtle(`Also to read, below: ${readSec.title.charAt(0).toLowerCase() + readSec.title.slice(1)}.`) : null}
          <Box flexDirection="row" gap={1} flexWrap="wrap" paddingTop={1}>
            {sendOr('send')}
            {anyBack ? (
              <Button key="as-recommended" hotkey="a" onPress={() => set(x => asRecommended(s, x))}>
                All as recommended
              </Button>
            ) : null}
          </Box>
          {m.refused ? (
            <Text size="footnote" color="warning">
              Not sent: {m.refused}. Press send again when the chat is free.
            </Text>
          ) : null}
          {subtle(can.ok ? 'Nothing is sent until you press send. Each answer starts at ViD’s recommendation; change any you disagree with.' : 'This is not the conversation where ViD asked: send puts your answers in the message box, for you to send.', 'caption')}
        </Box>
      )

      // usability (P1, P7): beside each item, where it stands against what it started at
      const where = (sec: FaceSection, it: FaceItem) => {
        const words: string[] = []
        if (isAlone(sec, it)) words.push('Asked on its own')
        else if (!m.a[mk(sec, it)]) words.push('Needs your answer')
        else if (startOf(sec, it).a && atStart(sec, it, m)) words.push("ViD's recommendation")
        if (it.norecommend) words.push('ViD has no recommendation')
        return words.map(w => (
          <Text size="caption" weight="semibold" color={w === 'Needs your answer' || w === 'Asked on its own' ? 'claude' : 'subtle'}>
            {w}
          </Text>
        ))
      }

      const drawQ = (sec: FaceSection, q: FaceItem) => {
        const k = mk(sec, q)
        const lone = isAlone(sec, q)
        const val = m.a[k] ?? ''
        const open = m.open[k] === true
        const has = (id: string) => sec.acts.some(a => a.id === id)
        return (
          <Box key={`q-${k}`} flexDirection="column" gap={1} padding={2} borderStyle="round" borderColor={LINE}>
            <Box flexDirection="row" gap={1}>
              {dot(val ? 'success' : 'claude')}
              <Box flexDirection="column" flexShrink={1}>
                {m.ids ? subtle(q.id, 'caption') : null}
                <Text weight="semibold">{q.text}</Text>
                {/* usability (P7): which clause of the rule, so two clauses of one rule are told apart with the ids hidden */}
                {sec.kind === 'alone' && /~[0-9]+$/.test(q.id) ? subtle(`Clause ${q.id.replace(/^.*~/, '')} of this rule`) : null}
                {shown(q.detail, m.ids).map(d => subtle(d))}
                {where(sec, q)}
                {lookWhy(q)}
              </Box>
            </Box>
            {critics(sec, q)}
            {has('choose') && q.choices.length ? (
              <Box flexDirection="column" gap={1}>
                {q.choices.map((ch, i) => {
                  const sel = val === 'choose:' + ch
                  return (
                    <Button key={`${k}-c${i}`} variant={sel ? 'primary' : 'secondary'} onPress={() => set(x => marked(x, sec, q, 'choose:' + ch))}>
                      {sel ? '◉' : '○'} {ch}
                      {ch === q.recommend && !lone ? (
                        <Text size="caption" weight="semibold" color={sel ? undefined : 'claude'}>
                          {'  '}Recommended
                        </Text>
                      ) : null}
                    </Button>
                  )
                })}
              </Box>
            ) : null}
            {q.recommend && (lone || !(has('choose') && q.choices.length)) ? (
              <Text size="footnote" color="claude">
                {lone ? `ViD suggests: ${q.recommend}` : `ViD recommends: ${q.recommend}`}
              </Text>
            ) : null}
            {val === 'own' && !open ? (
              <Box flexDirection="column" paddingX={1} paddingY={1} backgroundColor={TINT.claude} borderStyle="round" borderColor="claude">
                <Text size="caption" weight="semibold" color="claude">
                  ✓ Your answer
                </Text>
                <Text>{m.w[k] ?? ''}</Text>
              </Box>
            ) : null}
            {open ? (
              <Input
                key={`${k}-words`}
                rows={2}
                value={m.w[k] ?? ''}
                placeholder="Your answer, in your own words"
                submitLabel="Use this"
                onSubmit={val2 => {
                  if (val2.trim()) set(x => ({ ...x, a: { ...x.a, [k]: 'own' }, w: { ...x.w, [k]: val2 }, open: { ...x.open, [k]: false } }))
                }}
              />
            ) : null}
            <Box flexDirection="row" gap={2} flexWrap="wrap">
              {has('own') ? (
                <Button key={`${k}-write`} plain onPress={() => set(x => ({ ...x, open: { ...x.open, [k]: !x.open[k] } }))}>
                  <Text size="footnote" color="subtle">
                    {open ? 'Cancel' : val === 'own' ? 'Change my answer' : 'Write my own answer'}
                  </Text>
                </Button>
              ) : null}
              {sec.acts
                .filter(a => a.id === 'pick' || a.id === 'skip')
                .map(a => (
                  <Button key={`${k}-${a.id}`} plain onPress={() => set(x => marked(x, sec, q, a.id))}>
                    <Text size="footnote" color={val === a.id ? 'claude' : 'subtle'} weight={val === a.id ? 'semibold' : 'regular'}>
                      {val === a.id ? `✓ ${a.id === 'pick' ? 'ViD picks' : 'Skipped'}` : a.label}
                    </Text>
                  </Button>
                ))}
            </Box>
          </Box>
        )
      }

      // usability (P10): a finding about an item is drawn under it, as ViD's critic, with its own buttons
      const bes = besides(s)
      const critics = (sec: FaceSection, it: FaceItem) => (bes.at[mk(sec, it)] ?? []).map(f => drawRow(f.sec, f.item, true))
      const drawRow = (sec: FaceSection, x: FaceItem, note: boolean): unknown => {
                const xk = mk(sec, x)
                const val = m.a[xk] ?? ''
                const act = sec.acts.find(k => k.id === val)
                const struck = val === 'cut'
                return (
                  <Box key={`row-${xk}`} flexDirection="column" gap={1} paddingX={2} paddingY={1} backgroundColor={act ? FILL : undefined}>
                    <Box flexDirection="column">
                      {note ? <Text size="caption" weight="semibold" color="claude">ViD's critic:</Text> : null}
                      {m.ids ? subtle(x.id, 'caption') : null}
                      <Text strikethrough={struck} color={struck ? 'subtle' : undefined}>
                        {x.text}
                      </Text>
                      {shown(x.detail, m.ids).map(d => subtle(d))}
                      {x.recommend ? (
                        <Text size="caption" weight="medium" color="claude">
                          {isAlone(sec, x) ? `ViD suggests: ${x.recommend}` : `ViD suggests ${x.recommend.charAt(0).toLowerCase() + x.recommend.slice(1)}`}
                        </Text>
                      ) : null}
                      {sec.kind === 'decided' ? null : where(sec, x)}
                      {lookWhy(x)}
                    </Box>
                    <Box flexDirection="row" flexWrap="wrap" gap={1}>
                      {sec.acts.map(k => {
                        const sel = val === k.id
                        return (
                          <Button key={`${xk}-${k.id}`} onPress={() => set(y => marked(y, sec, x, k.id))}>
                            <Text color={sel ? (TONE[k.id] ?? 'suggestion') : 'inactive'}>{sel ? '●' : '○'}</Text> <Text weight={sel ? 'semibold' : 'regular'}>{k.label}</Text>
                          </Button>
                        )
                      })}
                    </Box>
                    {act?.words ? (
                      <Input key={`${xk}-words`} rows={2} value={m.w[xk] ?? ''} placeholder="In your own words" submitLabel="Use this" onSubmit={val2 => set(y => ({ ...y, w: { ...y.w, [xk]: val2 } }))} />
                    ) : null}
                    {note ? null : critics(sec, x)}
                  </Box>
                )
      }

      // 0.26.10.29.6 (S10): where ViD points, one heading above the pointed items and one above the rest; the sitting's
      // order is kept (the pointed items come first in it) and nothing is folded or hidden
      const pointed = (sec: FaceSection, items: FaceItem[], draw: (x: FaceItem) => unknown): unknown[] => {
        if (!sec.items.some(x => x.look)) return items.map(draw)
        const head = (t: string) => (
          <Box key={`${sec.id}-head-${t}`} paddingX={2} paddingTop={1}>
            <Text size="caption" weight="semibold" color={t === 'Look here first' ? 'claude' : 'subtle'}>
              {t}
            </Text>
          </Box>
        )
        const out: unknown[] = []
        let rest = false
        items.forEach((x, i) => {
          if (i === 0 && x.look) out.push(head('Look here first'))
          if (!x.look && !rest) {
            rest = true
            out.push(head('The rest, as recommended'))
          }
          out.push(draw(x))
        })
        return out
      }
      const lookWhy = (x: FaceItem) =>
        x.look ? (
          <Text size="caption" weight="semibold" color="claude">
            {x.look}
          </Text>
        ) : null

      const drawList = (sec: FaceSection) => {
        const n = sec.items.length
        const decided = sec.kind === 'decided'
        const left = n - sec.items.filter(x => m.a[mk(sec, x)]).length
        const only = m.only[sec.id] === true
        // usability (P10): "only unmarked" keeps an item whose critic's note still needs an answer
        const open = (x: FaceItem) => !m.a[mk(sec, x)] || (bes.at[mk(sec, x)] ?? []).some(f => !m.a[mk(f.sec, f.item)])
        const vis = sec.items.filter(x => !bes.placed.has(mk(sec, x)) && (!only || open(x)))
        const noteOpen = m.noteOpen[sec.id] === true
        return (
          <Box flexDirection="column" gap={1}>
            {!decided && n >= 4 ? (
              <Box flexDirection="row" flexWrap="wrap" gap={2} justifyContent="space-between">
                <Box flexDirection="row" flexWrap="wrap" gap={2}>
                  {sec.acts.map(a => (
                    <Box flexDirection="row" gap={1}>
                      {dot(TONE[a.id] ?? 'suggestion')}
                      <Text size="footnote" color="subtle" tabular>
                        {a.label} {sec.items.filter(i => m.a[mk(sec, i)] === a.id).length}
                      </Text>
                    </Box>
                  ))}
                  <Box flexDirection="row" gap={1}>
                    {dot('inactive', false)}
                    <Text size="footnote" color="subtle" tabular>
                      Not marked {left}
                    </Text>
                  </Box>
                </Box>
                <Button key={`${sec.id}-only`} plain {...(sec.id === filterList(s) ? { hotkey: 'u' } : {})} onPress={() => set(x => ({ ...x, only: { ...x.only, [sec.id]: !x.only[sec.id] } }))}>
                  <Text size="footnote" weight="medium" color="suggestion">
                    {only ? `Show all ${n}` : `Show only unmarked (${left})`}
                  </Text>
                </Button>
              </Box>
            ) : null}
            <Box flexDirection="column" borderStyle="round" borderColor={LINE}>
              {pointed(sec, vis, x => drawRow(sec, x, false))}
              {vis.length === 0 ? <Box padding={2}>{subtle('Every item is marked.')}</Box> : null}
              {n >= 10 ? (
                <Box flexDirection="row" flexWrap="wrap" justifyContent="space-between" gap={1} paddingX={2} paddingY={1} backgroundColor={FILL}>
                  <Text size="footnote" color="subtle" tabular>
                    {foot}
                  </Text>
                  {sendOr(`${sec.id}-send`)}
                </Box>
              ) : null}
            </Box>
            {!noteOpen ? (
              <Button key={`${sec.id}-note`} plain onPress={() => set(y => ({ ...y, noteOpen: { ...y.noteOpen, [sec.id]: true } }))}>
                <Text size="footnote" color="subtle">
                  {m.note[sec.id] ? `Your note: ${m.note[sec.id]}` : sec.id === 'contract' ? 'Merge two, add one, or say anything else about this list' : 'Add a note on this list, in your own words'}
                </Text>
              </Button>
            ) : (
              <Input key={`${sec.id}-note-text`} rows={2} value={m.note[sec.id] ?? ''} placeholder="In your own words" submitLabel="Keep this note" onSubmit={val2 => set(y => ({ ...y, note: { ...y.note, [sec.id]: val2 }, noteOpen: { ...y.noteOpen, [sec.id]: false } }))} />
            )}
          </Box>
        )
      }

      let readSeen = false
      const answers = (x: FaceSection) => answerable(x) || x.kind === 'decided'
      const lastAnswer = s.sections.reduce((at, x, i) => (answers(x) && !x.empty ? i : at), -1)
      const empties = s.sections.filter(x => x.empty)
      const drawSection = (sec: FaceSection, idx: number) => {
        if (sec.empty) return null
        let countLine = ''
        if (sec.kind === 'questions' || sec.kind === 'alone') countLine = `${sec.items.filter(q => m.a[mk(sec, q)]).length} of ${sec.items.length} answered`
        else if (sec.kind === 'decided') {
          const k = sec.items.filter(x => m.a[mk(sec, x)]).length
          countLine = k ? `${k} changed · the rest stand` : 'All stand unless you change one'
        } else if (needsAnswer(sec)) countLine = `${sec.items.filter(x => m.a[mk(sec, x)]).length} of ${sec.items.length} marked`
        // the "To read" line once, after the last thing to answer; a read-only section above it is captioned
        const readOnly = !answers(sec)
        const readStart = readOnly && idx > lastAnswer && !readSeen
        if (readStart) readSeen = true
        const readCaption = readOnly && idx < lastAnswer
        return (
          <Box key={`sec-${sec.id}`} flexDirection="column" gap={1}>
            {readStart ? (
              <Box flexDirection="row" gap={1} paddingBottom={1}>
                <Text size="caption" weight="semibold" color="subtle">
                  To read
                </Text>
                {pic(`<svg xmlns="http://www.w3.org/2000/svg" width="${Math.max(120, px - 80)}" height="12" viewBox="0 0 ${Math.max(120, px - 80)} 12"><line x1="0" y1="6.5" x2="${Math.max(120, px - 80)}" y2="6.5" stroke="${INK.subtle}" stroke-opacity="0.35"/></svg>`, '')}
              </Box>
            ) : null}
            {readCaption ? subtle('To read', 'caption') : null}
            <Box flexDirection="row" flexWrap="wrap" justifyContent="space-between" columnGap={2}>
              <Text size="heading" weight="semibold">
                {sec.kind === 'objections' && sec.items.some(x => bes.placed.has(mk(sec, x))) ? `${sec.title}: ${sec.items.filter(x => !bes.placed.has(mk(sec, x))).length} here, ${sec.items.filter(x => bes.placed.has(mk(sec, x))).length} beside what they are about.` : sec.title}
              </Text>
              {countLine && !sec.empty ? (
                <Text size="footnote" color="subtle" tabular>
                  {countLine}
                </Text>
              ) : null}
            </Box>
            {/* usability (P2): back to ViD's recommendations in one press, while one of them is changed */}
            {restorable(sec, m) ? (
              <Button key={`${sec.id}-as-recommended`} plain onPress={() => set(x => asRecommended(s, x, sec.id))}>
                <Text size="footnote" weight="medium" color="suggestion">
                  As recommended
                </Text>
              </Button>
            ) : null}
            {!sec.empty && (sec.kind === 'questions' || sec.kind === 'alone') ? <Box flexDirection="column" gap={1}>{pointed(sec, sec.items, q => drawQ(sec, q))}</Box> : null}
            {!sec.empty && (sec.kind === 'list' || sec.kind === 'objections' || sec.kind === 'decided') ? drawList(sec) : null}
            {!sec.empty && sec.kind === 'figures' ? (
              <Box flexDirection="column" gap={1} paddingX={2} paddingY={1} backgroundColor={FILL}>
                {sec.items.map(r => {
                  const label = r.text.charAt(0).toUpperCase() + r.text.slice(1)
                  // a short figure sits on the right; a long one reads under its label
                  return r.value.length <= 24 ? (
                    <Box flexDirection="row" justifyContent="space-between" gap={2}>
                      <Text size="footnote" color="subtle">
                        {label}
                      </Text>
                      <Text weight="semibold" tabular>
                        {r.value}
                      </Text>
                    </Box>
                  ) : (
                    <Box flexDirection="column">
                      <Text size="footnote" color="subtle">
                        {label}
                      </Text>
                      <Text size="footnote">{r.value}</Text>
                    </Box>
                  )
                })}
              </Box>
            ) : null}
            {!sec.empty && sec.kind === 'text' ? (
              <Box flexDirection="column" gap={1}>
                {sec.items.map(p => (
                  <Box flexDirection="column">
                    <Text size="caption" weight="semibold" color="subtle">
                      {p.text}
                    </Text>
                    {shown(p.detail, m.ids).map(d => (
                      <Text>{d}</Text>
                    ))}
                  </Box>
                ))}
              </Box>
            ) : null}
          </Box>
        )
      }

      // what waits on the person stands first (R21); the sections keep ViD's order (R9)
      body = (
        <Box flexDirection="column" gap={3}>
          {/* usability (P9): the pages due at this stop, named first */}
          {st && st.pages.some(p => p.stops.includes(s.stop)) ? (
            <Text weight="semibold">{`Read it whole first: ${st.pages.filter(p => p.stops.includes(s.stop)).map(p => p.title).join(', ')}`}</Text>
          ) : null}
          {waits}
          {s.sections.map((x, i) => drawSection(x, i))}
          {empties.length ? subtle(`Nothing at this ${s.sitting === 'interview' ? 'sitting' : 'pause'}: ${empties.map(x => x.title.charAt(0).toLowerCase() + x.title.slice(1)).join('; ')}.`) : null}
          <Button key="ids" plain onPress={() => set(x => ({ ...x, ids: !x.ids }))}>
            <Text size="footnote" color="subtle">
              {m.ids ? "Hide ViD's ids" : "Show ViD's ids"}
            </Text>
          </Button>
        </Box>
      )
    }

    return (
      <Box flexDirection="column" gap={3} padding={2}>
        {/* usability (P12): the sitting's phrase, the panel's first line while it waits */}
        {mode === 'sitting' && s && s.ready ? (
          <Text size="heading" weight="semibold" color="claude">
            {s.ready}
          </Text>
        ) : null}
        {head}
        {body}
        {vnote ? subtle(vnote, 'caption') : null}
      </Box>
    )
  })
}
