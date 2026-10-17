---
name: vid-view
description: Make the project viewer — self-contained HTML snapshots of a ViD project (now, and one for each milestone not yet made, with an index), read from git and ViD's records, each one file that opens offline by double-click. Read-only on the project; writes only into its own folder outside it. Use when the owner says "vid view", asks to see the project, its progress, its evidence or how it changed, or wants a snapshot to share.
---

# /vid view

The project viewer (v0.9.7.4). It shows one ViD project — what is being
built, how far it has got, the evidence behind it, and how all of that
changed — as snapshots, one HTML file each, that open by double-click and
work offline. It changes nothing in the project, commits nothing and asks
the owner nothing.

## Run it

```
sh "${CLAUDE_PLUGIN_ROOT}/viewer/view.sh" <project> [--out <dir>] [--at <commit|UTC time>]
```

- **The project:** the folder the owner names, or the current one. It must
  hold `PRD.md`.
- **Where it writes:** `--out`, else `~/ViD Viewer/<project folder name>/`:
  `index.html`, `now.html`, one `<UTC>-<milestone>.html` per snapshot, and
  `.cache/`. It refuses a folder inside the project.
- **`--at`:** one extra snapshot at a commit or a UTC time
  (`YYYY-MM-DDTHH:MM:SSZ`), marked "requested" in the index and kept by
  later runs.

Run it at the lowest priority on a shared machine (`nice -n 19`). It runs
no tests and starts nothing; it is safe beside a live run.

## What to tell the owner

Relay what it prints, in plain words:
- before it starts, how many snapshots it will compute and, from the
  previous run, an estimate of the time — say it is an estimate;
- at the end, what it made, the time taken and the index's full path, so
  it opens with a click;
- "nothing new" when nothing changed since the last run.

Point the owner at `index.html` (every snapshot, and the change log across
them) and `now.html` (the latest). Nothing pops up.

## What it reads, and what it does not show

- Test states come from the plugin's own evidence reader, run for each
  moment in a sealed copy of the project's records as they stood then. A
  project whose own `checks/` is older may read some rows differently; the
  snapshot's footer names the rule used.
- A past snapshot shows the moment as recorded. What the records do not
  time — review prose, the wording of a question, the agents working — is
  shown in the latest snapshot only, and the page says so.
- Decisions taken for the owner are listed under what needs the owner,
  from the delegated marks vid-develop records (`metrics.sh delegated`).
- Counts only, never percentages.

## When it fails

It stops with one line saying why (no `PRD.md`, no commit, a folder inside
the project, a moment the evidence reader could not read). Relay that
line; do not retry with other arguments unless the owner asks.
