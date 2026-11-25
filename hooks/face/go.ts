import type { EngineInterface } from 'claude-code'

// FB-5 A1: a link of the panel's top row scrolls the panel to its section's title, a button: the app tells the engine where the buttons
// of a drawing stand, and of no other element, so a move to a box is denied. 0 is the top. Its own file, so the panel's tests can hand
// it an engine: the test kit takes no module's own scroll. A surface that refuses, or does not scroll, leaves the panel where it is: the
// section is there, further down.
export async function goTo($: EngineInterface, pane: string, n: number): Promise<void> {
  try {
    await $.ui.scroll(n > 0 ? { to: { key: `top-${n}` }, in: pane, block: 'start' } : { to: 'start', in: pane })
  } catch {
    // the panel stays where it is
  }
}
