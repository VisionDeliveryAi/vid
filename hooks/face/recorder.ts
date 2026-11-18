import type { EngineInterface } from 'claude-code'

// usability (P4): ViD's face, the recorder. Not the panel: it draws nothing and acts on one event, the end of a turn
// on the main loop, which also comes when the person interrupts one (the Stop hook does not run then). Where the
// project holds .vid/face/standing.json it writes .vid/face/run.<session id> as stopped, begun now, keeping the last
// step hooks/face-standing.sh wrote: `stopped <UTC> <last step, UTC|->`. That one file is its one write, whole in
// one call (the engine's file noun has no rename). The engine loads one module a plugin and takes one turn.complete
// hook a module, so the panel's hook calls recordStop and nothing else of it; recordStop reaches nothing of the panel.

const DIR = '.vid/face'
const utc = (): string => new Date().toISOString().replace(/\.\d+Z$/, 'Z')

export async function recordStop($: EngineInterface, e: { agentId?: string }): Promise<void> {
  if (e.agentId !== undefined) return
  try {
    const root = await $.session.root()
    if (!(await $.fs.exists(`${root}/${DIR}/standing.json`))) return
    const id = await $.session.id()
    if (!/^[A-Za-z0-9_-]+$/.test(id)) return
    const path = `${root}/${DIR}/run.${id}`
    let last = '-'
    if (await $.fs.exists(path)) {
      try {
        const was = String(await $.fs.read(path)).trim().split(/\s+/)
        if (was.length === 3 && was[2]) last = was[2]
      } catch {
        // unreadable: no last step
      }
    }
    await $.fs.write(path, `stopped ${utc()} ${last}\n`)
  } catch {
    // the next turn's hooks write it again
  }
}
