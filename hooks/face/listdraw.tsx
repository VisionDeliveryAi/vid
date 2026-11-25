import type { List, ListCard, ListMarks, ListStep, ListTodo } from './types'
import { STATES, ago, boxAlt, cardState, choicesOf, day, dayTime, holdLine, holdRow, keyPart, lineKey, links, many, openKey, since } from './list'

// FB-5 A1: the owner's list, drawn. The sections stand on par, all open, numbered; what is closed until pressed is My to do's lines
// but one, a line's numbers and links, what a wait holds, everything ViD holds and the counts, and a step's test ids. Words take
// the theme's named colours; lines and fills the either-theme ones, as the rest of the panel. No value in a drawing is named h: a
// tag is made by that name.

const LINE = '#8a887f33'
const FILL = '#8a887f12'
const TINT = { ask: '#3b82b01f', building: '#3b82b022', stuck: '#c08a3426', accepted: '#4f9c6c22' }
const INK = { accepted: '#4f9c6c', building: '#3b82b0', stuck: '#b5761f', none: '#8a887f' }
const FONT = 'font-family="-apple-system,system-ui,sans-serif"'

type Draw = any
// register.tsx's own: the surface's elements, the two calls the list makes, the width
export type Kit = { Box: Draw; Text: Draw; Button: Draw; Link: Draw; pic: (source: string, alt: string) => unknown; cols: number; px: number }
export type Presses = {
  open: (key: string) => Promise<void>
  pick: (t: ListTodo, ask: number, words: string) => Promise<void>
  off: (t: ListTodo) => Promise<void>
  explain: (t: ListTodo) => Promise<void>
  show: (key: string) => Promise<void>
  go: (n: number) => Promise<void>
}

// A step's box: filled by its pieces done, its letter where it holds others up.
export function boxSvg(s: ListStep, w = 26, h = 28): string {
  // the gap to the next box is in the picture
  const svg = (inner: string) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w + 5}" height="${h + 5}" viewBox="0 0 ${w + 5} ${h + 5}">${inner}</svg>`
  const rect = (fill: string, stroke: string, more = '') => `<rect x="1" y="1" width="${w - 2}" height="${h - 2}" rx="4" fill="${fill}" stroke="${stroke}" stroke-width="1.5"${more}/>`
  const letter = (color: string, more = '') =>
    s.flag ? `<text x="${w / 2}" y="${h / 2 + 4.2}" text-anchor="middle" ${FONT} font-size="12" font-weight="700" fill="${color}"${more}>${s.flag.replace(/[^A-Za-z0-9]/g, '')}</text>` : ''
  if (s.state === 'accepted') {
    const x = w / 2, y = h / 2
    return svg(rect(INK.accepted, INK.accepted) + `<path d="M${x - 5} ${y + 0.3} L${x - 1.5} ${y + 3.8} L${x + 5.2} ${y - 3.6}" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`)
  }
  if (s.state === 'building') {
    const part = Math.max(14, Math.min(100, s.fill)), fh = Math.round(((h - 2) * part) / 100)
    return svg(rect(TINT.building, INK.building) + `<rect x="1" y="${h - 1 - fh}" width="${w - 2}" height="${fh}" rx="3" fill="${INK.building}"/>` + letter('#12324a', ' stroke="#ffffff" stroke-width="3" stroke-linejoin="round" paint-order="stroke"'))
  }
  if (s.state === 'taken') return svg(rect('none', INK.building, ' stroke-opacity="1"').replace('1.5', '2.2') + letter(INK.building))
  if (s.state === 'nobody') return svg(rect(TINT.stuck, INK.stuck) + letter(INK.stuck))
  return svg(rect('none', INK.none, ' stroke-dasharray="3 2.5" stroke-opacity="0.8"') + letter(INK.none))
}

// a release's boxes in one picture, n to a row
export function rowSvg(steps: ListStep[], n: number): string {
  const rows = Math.ceil(steps.length / n), w = Math.min(n, steps.length) * 31, h = rows * 33
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${steps.map((s, i) => boxSvg(s).replace('<svg ', `<svg x="${(i % n) * 31}" y="${Math.floor(i / n) * 33}" `)).join('')}</svg>`
}

// whole rows, at most a hundred boxes a picture: the app takes 131,072 characters of one
export function rowsOf(steps: ListStep[], per: number): ListStep[][] {
  const n = Math.max(1, Math.floor(100 / per)) * per
  return Array.from({ length: Math.ceil(steps.length / n) }, (_, i) => steps.slice(i * n, (i + 1) * n))
}

const ruleSvg = (px: number, strong: boolean) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="4" viewBox="0 0 ${px} 4"><line x1="0" y1="2" x2="${px}" y2="2" stroke="${INK.none}" stroke-opacity="${strong ? 0.9 : 0.3}" stroke-width="${strong ? 1.6 : 1}"/></svg>`

const barSvg = (px: number, done: number, pieces: number) => {
  const w = Math.max(60, Math.floor(px)), f = Math.max(0, Math.min(w, Math.round((w * done) / Math.max(1, pieces))))
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="5" viewBox="0 0 ${w} 5"><rect x="0" y="0" width="${w}" height="5" rx="2.5" fill="${INK.none}" fill-opacity="0.25"/><rect x="0" y="0" width="${f}" height="5" rx="2.5" fill="${INK.building}"/></svg>`
}

// The desktop app draws nothing of a panel past its bounds (2,000 pieces, an element or a text each one; 262,144 characters of texts and
// properties) and says only "nothing to show yet"; the engine's own bound on pieces is ten times that, and it cuts the texts of a drawing at
// 100,000 characters. What fits here leaves room for the panel's head and foot. WHOLE is the whole panel's.
export type Size = { pieces: number; chars: number; text: number }
export const MOST: Size = { pieces: 1800, chars: 220000, text: 90000 }
export const WHOLE: Size = { pieces: 1980, chars: 250000, text: 99000 }
export const sizeOf = (x: any): Size => {
  if (x === null || x === undefined || typeof x === 'boolean') return { pieces: 0, chars: 0, text: 0 }
  if (typeof x !== 'object') return { pieces: 1, chars: String(x).length, text: String(x).length }
  const all: Size = { pieces: 0, chars: 0, text: 0 }
  const add = (y: any) => {
    const s = sizeOf(y)
    all.pieces += s.pieces
    all.chars += s.chars
    all.text += s.text
  }
  if (Array.isArray(x)) {
    x.forEach(add)
    return all
  }
  all.pieces = 1
  const chars = (o: any): number =>
    Object.entries(o ?? {}).reduce((n, [k, v]) => (k === 'children' || typeof v === 'function' ? n : n + k.length + (typeof v === 'string' ? v.length : v !== null && typeof v === 'object' ? chars(v) : 0)), 0)
  // what hovers, and what is pressed, are the app's to count too
  all.chars += chars(x.props) + chars(x.hover) + (x.key ? String(x.key).length : 0)
  add(x.children ?? x.props?.children)
  return all
}
export const fits = (x: unknown, most: Size): boolean => {
  const s = sizeOf(x)
  return s.pieces <= most.pieces && s.chars <= most.chars && s.text <= most.text
}

// Drawn whole; past the bound it gives up, in this order and saying so: the names under the pointer, the accepted steps' cards, every
// card's rows, the steps. My to do, Waiting, Changed and The rest are whole at every size.
export function drawList(kit: Kit, l: List, m: ListMarks, on: Presses): unknown {
  let body: unknown = null
  for (let lean = 0; lean < 5; lean++) {
    body = drawAt(lean, kit, l, m, on)
    if (fits(body, MOST)) break
  }
  return body
}

function drawAt(lean: number, kit: Kit, l: List, m: ListMarks, on: Presses): unknown {
  const { Box, Text, Button, Link, pic, cols, px } = kit
  const wide = cols >= 60
  const small = (words: string) => (
    <Text size="footnote" color="subtle">
      {words}
    </Text>
  )
  const strong = (words: string) => <Text weight="semibold">{words}</Text>
  const press = (key: string, words: string, fn: () => Promise<void>) => (
    <Button key={key} plain onPress={fn}>
      <Text size="footnote" weight="medium" color="suggestion">
        {words}
      </Text>
    </Button>
  )
  const bullet = (key: string, words: unknown) => (
    <Box key={key} flexDirection="row" gap={1}>
      <Text color="subtle">•</Text>
      <Box flexDirection="column" flexGrow={1} flexShrink={1}>
        {words}
      </Box>
    </Box>
  )
  const group = (title: string, body: unknown[]) =>
    body.length ? (
      <Box key={`grp-${title}`} flexDirection="column">
        {strong(title)}
        {body}
      </Box>
    ) : null
  const unsorted = l.unsorted > 0 ? `${l.unsorted} not sorted yet` : l.state === 'sorted' ? '' : 'not sorted yet'
  const notSorted = unsorted ? (
    <Text size="footnote" weight="semibold" color="warning">
      {l.state === 'none' ? `${unsorted}. ViD sorts them at its next call.` : `${unsorted}: what came or changed since the last sort.`}
    </Text>
  ) : null

  // 1. My to do
  const left = l.todo.filter(t => !m.sent[lineKey(l, t)]).length
  const openAt = openKey(l, m)
  const line = (t: ListTodo) => {
    const key = lineKey(l, t), k = keyPart(t)
    const sent = m.sent[key]
    const number = (tone: string) => (
      <Box width={5} flexShrink={0}>
        <Text weight="bold" color={tone} tabular>
          {t.n}
        </Text>
      </Box>
    )
    if (sent) {
      return (
        <Box key={`todo-${k}`} flexDirection="column" gap={1}>
          <Box flexDirection="row">
            {number('success')}
            <Box flexDirection="column" flexGrow={1} flexShrink={1}>
              <Text color="subtle">{t.title}</Text>
              {small(sent.how === 'filled' ? `✓ in your message box, for you to send: ${sent.words}` : `✓ sent at ${sent.at}: ${sent.words}`)}
            </Box>
          </Box>
          {pic(ruleSvg(px, false), '')}
        </Box>
      )
    }
    const isOpen = key === openAt
    const fresh = t.isNew ? (
      <Text size="caption" weight="semibold" color="suggestion">
        {t.new ? `new: ${t.new}` : 'new'}
      </Text>
    ) : null
    const head = (
      <Box flexDirection="row">
        {number('suggestion')}
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          <Box flexDirection="row" flexWrap="wrap" justifyContent="space-between" columnGap={2}>
            <Button key={`line-${k}`} plain onPress={() => on.open(isOpen ? '' : key)}>
              <Text size={isOpen ? 'heading' : 'body'} weight="semibold">
                {t.title}
              </Text>
            </Button>
            {fresh}
          </Box>
          {isOpen ? null : <Text color="subtle">{t.do}</Text>}
        </Box>
      </Box>
    )
    if (!isOpen) {
      return (
        <Box key={`todo-${k}`} flexDirection="column" gap={1}>
          {head}
          {pic(ruleSvg(px, false), '')}
        </Box>
      )
    }
    const picks = m.picks[key] ?? {}
    return (
      <Box key={`todo-${k}`} flexDirection="column" gap={1} paddingX={2} paddingY={1} borderStyle="round" borderColor={LINE}>
        {head}
        {t.what ? <Text>{t.what}</Text> : null}
        {t.asks.map((a, i) => {
          const choices = choicesOf(a)
          const chosen = choices.find(c => c.pick)
          const picked = picks[String(i)] ?? ''
          return (
            <Box key={`ask-${k}-${i}`} flexDirection="column" gap={1} paddingX={2} paddingY={1} backgroundColor={TINT.ask}>
              {strong(a.ask)}
              {a.about ? <Text>{a.about}</Text> : null}
              {a.message ? (
                <Box paddingX={2} paddingY={1} backgroundColor={FILL} borderStyle="round" borderColor={LINE}>
                  <Text>{a.message}</Text>
                </Box>
              ) : null}
              {chosen ? (
                <Text>
                  <Text weight="semibold">{`ViD would choose “${chosen.words}”`}</Text>
                  {a.why ? `: ${a.why}` : ''}
                </Text>
              ) : null}
              <Box flexDirection="row" flexWrap="wrap" gap={1}>
                {choices.map(c => (
                  <Button key={`ans-${k}-${i}-${c.n}`} variant={(picked ? picked === c.words : c.pick) ? 'primary' : 'secondary'} onPress={() => on.pick(t, i, c.words)}>
                    {picked === c.words ? `✓ ${c.words}` : c.words}
                  </Button>
                ))}
              </Box>
            </Box>
          )
        })}
        {t.then ? (
          <Text>
            <Text weight="semibold">Then: </Text>
            {t.then}
          </Text>
        ) : null}
        {m.refused[key] ? (
          <Text size="footnote" color="warning">
            {`Not sent: ${m.refused[key]}. Press again when the chat is free.`}
          </Text>
        ) : null}
        <Box flexDirection="row" flexWrap="wrap" columnGap={2}>
          {press(`off-${k}`, 'Put it off', () => on.off(t))}
          {m.asked[key] ? small(m.asked[key].how === 'filled' ? '✓ in your message box, for you to send' : '✓ asked in the chat') : press(`explain-${k}`, 'Explain it', () => on.explain(t))}
          {t.details ? press(`details-${k}`, m.shown[`details-${key}`] ? 'Hide numbers and links' : 'Numbers and links', () => on.show(`details-${key}`)) : null}
        </Box>
        {t.details && m.shown[`details-${key}`] ? (
          <Box flexDirection="column">
            {small(t.details)}
            {links(t.details).map(u => (
              <Box key={`link-${k}-${u}`}>
                <Link href={u} label={u} />
              </Box>
            ))}
          </Box>
        ) : null}
      </Box>
    )
  }
  const nothing = l.todo.length === 0 && !unsorted
  const todo = [
    notSorted,
    nothing ? (
      <Text size="heading" weight="semibold">
        Nothing is yours now
      </Text>
    ) : null,
    ...l.todo.map(line),
  ]

  // 2. Waiting
  const waiting = [
    ...l.waiting.map((w, i) => (
      <Box key={`wait-${i}`} flexDirection={wide ? 'row' : 'column'} columnGap={2} paddingBottom={1}>
        <Box {...(wide ? { width: 18 } : {})} flexShrink={0}>
          {strong(w.who)}
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          <Text>{w.what}</Text>
          {w.since ? small(since(w.since)) : null}
        </Box>
      </Box>
    )),
    l.waiting.some(w => w.details) ? press('waiting-details', m.shown['waiting'] ? '▾ Details' : '▸ Details', () => on.show('waiting')) : null,
    ...(m.shown['waiting'] ? l.waiting.filter(w => w.details).map((w, i) => <Box key={`wait-d-${i}`}>{small(`${w.who}: ${w.details}`)}</Box>) : []),
    l.waiting.length ? null : small(l.state === 'none' ? 'Not sorted yet.' : 'You wait on nobody.'),
  ]

  // 3. Changed
  const changed = l.changed.length ? l.changed.map((c, i) => bullet(`chg-${i}`, <Text>{c}</Text>)) : [small(l.state === 'none' ? 'Not sorted yet.' : 'Nothing that needs telling.')]

  // 4. The rest
  const r = l.rest
  const held = m.shown['holds']
  const rest = [
    notSorted,
    group('ViD is on it; you are told when it is done', r.vid.map((x, i) => bullet(`vid-${i}`, <Text>{x}</Text>))),
    group(
      'Yours later',
      r.later.map((x, i) =>
        bullet(
          `later-${i}`,
          <Text>
            <Text weight="semibold">{x.when ? `${x.when}: ` : ''}</Text>
            {x.what}
          </Text>,
        ),
      ),
    ),
    group('Goes to the team by itself, when its time comes', r.team.map((x, i) => bullet(`team-${i}`, <Text>{x}</Text>))),
    r.suggested.length || r.leftOut.length ? (
      <Box key="grp-suggested" flexDirection="column">
        {strong('Suggested by ViD')}
        {r.suggested.length ? r.suggested.map((x, i) => bullet(`sug-${i}`, <Text>{x}</Text>)) : <Text>Nothing now.</Text>}
        {r.leftOut.length ? small(`Weighed and left out: ${r.leftOut.map(x => x.replace(/\.$/, '')).join('; ')}.`) : null}
      </Box>
    ) : null,
    r.holds.length || r.counts.length ? press('holds', `${held ? '▾' : '▸'} Everything ViD holds: ${many(r.holds.length, 'open item')}`, () => on.show('holds')) : null,
    held ? (
      <Box key="holds-list" flexDirection="column" paddingX={2} paddingY={1} backgroundColor={FILL}>
        {r.holds.map((x, i) => (
          <Box key={`hold-${i}`} flexDirection="column">
            <Text size="footnote">{`${x.id}  ${x.words}`}</Text>
            {small(x.where)}
          </Box>
        ))}
        {r.counts.map((c, i) => (
          <Box key={`count-${i}`}>{small(`${c.n} ${c.words}`)}</Box>
        ))}
      </Box>
    ) : null,
    r.vid.length || r.later.length || r.team.length || r.suggested.length || r.leftOut.length || r.holds.length || r.counts.length || unsorted ? null : small('Nothing else is open.'),
  ]
  const restCount = [r.vid.length ? `${r.vid.length} with ViD` : '', r.later.length ? `${r.later.length} yours later` : '', unsorted].filter(Boolean).join(', ')

  // 5. The plan
  const rels = l.plan.releases
  const steps = rels.flatMap(x => x.steps)
  const per = Math.max(1, Math.floor(px / 31))
  const box = (s: ListStep, i: number) => {
    const scope = `vid-box-${s.id}`
    const name = boxAlt(s)
    const at = i % per >= per / 2 ? { right: 0 } : { left: 0 }
    return (
      <Box key={`box-${s.id}`} position="relative" hover={{ scope }}>
        {pic(boxSvg(s), name)}
        {/* its name under the pointer */}
        <Box position="absolute" top={-2} {...at} width={Math.min(40, name.length + 4)} display="none" hover={{ scope, display: 'flex' }} paddingX={1} backgroundColor={FILL} borderStyle="round" borderColor={LINE}>
          <Text size="caption">{name}</Text>
        </Box>
      </Box>
    )
  }
  const flag = (f: string, stuck: boolean) =>
    f ? (
      <Box paddingX={1} backgroundColor={stuck ? TINT.stuck : TINT.building}>
        <Text weight="bold" {...(stuck ? { color: 'warning' } : {})}>
          {f}
        </Text>
      </Box>
    ) : null
  const hold = l.plan.hold
  const plan = [
    <Box key="legend" flexDirection="row" flexWrap="wrap" columnGap={2}>
      {STATES.filter(x => steps.some(s => s.state === x.state)).map(x => (
        <Box key={`leg-${x.state}`} flexDirection="row" gap={1} alignItems="center">
          {pic(boxSvg({ id: '', name: '', state: x.state, fill: 45, flag: '' }, 16, 17), '')}
          {small(`${steps.filter(s => s.state === x.state).length} ${x.legend}`)}
        </Box>
      ))}
    </Box>,
    ...rels.map(x => (
      <Box key={`rel-${x.n}`} flexDirection="column">
        {pic(ruleSvg(px, false), '')}
        <Box flexDirection="row" gap={1}>
          <Text color="subtle">{String(x.n)}</Text>
          {strong(x.name)}
        </Box>
        {small(`${x.accepted} of ${many(x.steps.length, 'step')} accepted`)}
        {lean > 3 ? (x.steps.length ? <Text size="footnote">Its steps are too many to draw here.</Text> : null) : lean > 0 && x.steps.length ? (
          <Box flexDirection="column" paddingTop={1}>
            {rowsOf(x.steps, per).map(some => pic(rowSvg(some, per), some.map(boxAlt).join('; ')))}
          </Box>
        ) : (
          <Box flexDirection="row" flexWrap="wrap" paddingTop={1}>
            {x.steps.map(box)}
          </Box>
        )}
        {x.say ? <Text>{x.say}</Text> : null}
        {x.stuck ? (
          <Text weight="semibold" color="warning">
            {x.stuck}
          </Text>
        ) : null}
        {x.words ? <Text>{x.words}</Text> : null}
      </Box>
    )),
    hold.rows.length ? (
      <Box key="hold" flexDirection="column" gap={1} paddingX={2} paddingY={1} borderStyle="round" borderColor={LINE}>
        <Text size="heading" weight="semibold">{`What holds the rest up: ${many(hold.rows.length, 'step')}`}</Text>
        {small(holdLine(hold))}
        {hold.rows.map((x, i) => {
          const w = holdRow(x)
          return (
            <Box key={`hr-${i}`} flexDirection="row" columnGap={2}>
              <Box width={4} flexShrink={0} alignItems="flex-start">
                {flag(x.flag, x.state === 'nobody')}
              </Box>
              <Box flexDirection={wide ? 'row' : 'column'} flexGrow={1} flexShrink={1} columnGap={2} justifyContent="space-between">
                <Box flexDirection="column" flexShrink={1}>
                  <Text>{x.name}</Text>
                  {w.words ? small(w.words) : null}
                  {w.stuck ? (
                    <Text size="footnote" weight="semibold" color="warning">
                      {w.stuck}
                    </Text>
                  ) : null}
                </Box>
                <Box flexShrink={0}>{small(`${x.by} ${x.by === 1 ? 'builds' : 'build'} on it`)}</Box>
              </Box>
            </Box>
          )
        })}
      </Box>
    ) : null,
  ]

  // 6. … the teams
  const three = cols >= 90
  const tw = Math.floor((cols - 4 - 4) / 3)
  const cardPx = (three ? tw : cols - 4) * 8 - 48
  const says = (words: string) => <Text size="footnote">{words}</Text>
  const EDGE: Record<string, string> = { accepted: INK.accepted, building: INK.building, taken: INK.building, nobody: INK.stuck }
  const PILL: Record<string, string> = { accepted: TINT.accepted, building: TINT.building, taken: TINT.building, nobody: TINT.stuck }
  const WORD: Record<string, string> = { accepted: 'success', nobody: 'warning' }
  const buildsOn = (c: ListCard) => `Builds on: ${c.buildsOn.join('; ') || 'nothing that is not accepted'}`
  const draw = (c: ListCard) => {
    const ref = c.ticket ? `#${c.ticket}` : ''
    const shown = m.shown[`tests-${c.id}`]
    // one text a card, a line a fact: a row of boxes a fact is what makes a panel too long to draw
    const facts = [
      c.who ? `Who: ${c.who}` : '',
      c.sent ? `Sent: ${day(c.sent)}, ${ago(c.days)}` : '',
      c.state === 'accepted' ? '' : buildsOn(c),
      c.holdsUp ? `Holds up: ${many(c.holdsUp, 'later step')}` : '',
      c.tests && !c.testIds.length ? `Tests: ${c.tests}` : '',
    ].filter(Boolean)
    const named = (
      <Text weight="semibold">
        {c.flag ? <Text weight="bold" backgroundColor={c.state === 'nobody' ? TINT.stuck : TINT.building} {...(c.state === 'nobody' ? { color: 'warning' } : {})}>{` ${c.flag} `}</Text> : null}
        {c.flag ? ` ${c.name}` : c.name}
      </Text>
    )
    return (
      <Box key={`card-${c.id}`} flexDirection="column" paddingX={2} paddingY={1} borderStyle="round" borderColor={EDGE[c.state] ?? LINE}>
        <Box flexDirection="row" flexWrap="wrap" justifyContent="space-between" columnGap={1}>
          <Box paddingX={1} backgroundColor={PILL[c.state] ?? FILL}>
            <Text size="caption" weight="semibold" {...(WORD[c.state] ? { color: WORD[c.state] } : {})}>
              {cardState(c.state)}
            </Text>
          </Box>
          {ref && c.url ? <Link href={c.url} label={`${ref} ${c.id}`} /> : small(ref ? `${ref} ${c.id}` : c.id)}
        </Box>
        {named}
        {c.pieces ? says(`${c.done} of ${c.pieces} pieces done`) : null}
        {c.pieces && c.state !== 'accepted' ? pic(barSvg(cardPx, c.done, c.pieces), '') : null}
        {facts.length ? says(facts.join('\n')) : null}
        {c.ready || c.drafts || c.pulls.length ? (
          <Box key={`pulls-${c.id}`} flexDirection="row" flexWrap="wrap" columnGap={1}>
            {says('Pull requests: ' + [c.ready ? `${c.ready} ready` : '', c.drafts ? many(c.drafts, 'draft') : ''].filter(Boolean).join(', ') + (c.pulls.length ? ':' : ''))}
            {c.pulls.map(p => (p.url ? <Link href={p.url} label={`#${p.n}`} /> : small(`#${p.n}`)))}
          </Box>
        ) : null}
        {c.testIds.length && c.tests ? press(`tests-${c.id}`, `${shown ? '▾' : '▸'} Tests: ${c.tests}`, () => on.show(`tests-${c.id}`)) : null}
        {shown ? small(c.testIds.join(' ')) : null}
        {c.notes.length ? says(c.notes.join('\n')) : null}
      </Box>
    )
  }
  // past the bound: a track's accepted steps in one line, then every step a line
  const cards = (all: ListCard[]) => {
    if (lean < 2) return all.map(draw)
    const done = all.filter(c => c.state === 'accepted')
    const open = all.filter(c => c.state !== 'accepted')
    return [
      done.length ? says(`${many(done.length, 'accepted step')}, closed to fit: ${done.map(c => c.name).join('; ')}`) : null,
      ...(lean < 3 ? open.map(draw) : open.map(c => <Box key={`card-${c.id}`}>{says(`${c.ticket ? `#${c.ticket} ` : ''}${c.name}: ${cardState(c.state).toLowerCase()}${c.who ? `, ${c.who}` : ''}`)}</Box>)),
    ]
  }
  const team = (t: List['teams'][number], ti: number) =>
    [
      t.area ? <Box key="area">{small(t.area)}</Box> : null,
      lean === 3 ? says('A line a step, closed to fit.') : null,
      ...(lean > 3 ? [] : t.releases).map((x, ri) => (
        <Box key={`tr-${ti}-${ri}`} flexDirection="column" gap={1}>
          <Box flexDirection="row" flexWrap="wrap" columnGap={1}>
            {x.n < 0 ? null : <Text color="subtle">{`Release ${x.n}`}</Text>}
            {strong(x.name)}
            {small(x.words)}
          </Box>
          {x.tracks
            .map((_, i) => i)
            .filter(i => i % 3 === 0)
            .map(i => (
              <Box key={`tracks-${ti + 1}-${ri}-${i / 3}`} flexDirection={three ? 'row' : 'column'} gap={2} alignItems={three ? 'flex-start' : 'stretch'}>
                {x.tracks.slice(i, i + 3).map((k, ki) => (
                  <Box key={`tk-${ki}`} flexDirection="column" gap={1} {...(three ? { width: tw, flexShrink: 1 } : {})}>
                    {small(k.name)}
                    {cards(k.cards)}
                  </Box>
                ))}
              </Box>
            ))}
        </Box>
      )),
    ]

  const planned = rels.length > 0 || l.teams.length > 0
  const sections: { title: string; count: string; body: unknown[]; gap: number }[] = [
    { title: 'My to do', count: left ? `${left}, only you can do, in order` : l.todo.length ? 'all sent' : '', body: todo, gap: 1 },
    { title: 'Waiting', count: l.waiting.length ? String(l.waiting.length) : '', body: waiting, gap: 0 },
    { title: 'Changed', count: l.changed.length ? `${l.changed.length}, nothing needed from you` : '', body: changed, gap: 0 },
    { title: 'The rest', count: restCount, body: rest, gap: 1 },
    ...(planned ? [{ title: 'The plan', count: `${many(rels.length, 'release')}, ${many(steps.length, 'step')}, ${many(l.teams.filter(t => t.kind === 'team').length, 'team')}`, body: plan, gap: 1 }] : []),
    ...(planned ? l.teams.map((t, i) => ({ title: t.kind === 'other' ? t.name : `Team ${t.name}`, count: t.words, body: lean > 3 ? [says('Its steps are too many to draw here. Ask in the chat for the ones you want.')] : team(t, i), gap: 2 })) : []),
  ]
  return (
    <Box flexDirection="column" gap={3}>
      <Box key="links" flexDirection="row" flexWrap="wrap" columnGap={2}>
        {sections.map((x, i) => press(`go-${i + 1}`, `${i + 1} ${x.title}`, () => on.go(i + 1)))}
      </Box>
      {sections.map((x, i) => (
        <Box key={`sec-${i + 1}`} flexDirection="column" gap={1}>
          <Box flexDirection="column">
            <Box flexDirection="row" flexWrap="wrap" columnGap={2} alignItems="center">
              {/* a button, which the app can scroll to: it tells the engine where its buttons stand, and of no box; pressed, back to the top */}
              <Button key={`top-${i + 1}`} plain onPress={() => on.go(0)}>
                <Text size="title" weight="bold" color="suggestion" tabular>
                  {String(i + 1)}
                </Text>{' '}
                <Text size="title" weight="semibold">
                  {x.title}
                </Text>
              </Button>
              {x.count ? small(x.count) : null}
            </Box>
            {pic(ruleSvg(px, true), '')}
          </Box>
          <Box flexDirection="column" gap={x.gap}>
            {x.body}
          </Box>
        </Box>
      ))}
      {l.written ? small(`Drawn from ViD's records of ${dayTime(l.written)}.`) : null}
    </Box>
  )
}
