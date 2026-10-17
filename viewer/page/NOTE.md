# VID Viewer — design note

## Navigation
- **One tree, one address per thing.** Product › capability › requirement › promise. Every node is a plain `#<id>` anchor (`#FEAT-10`, `#REQ-049`, `#ROW-037`, `#S08`, `#A-131`, `#D-101`), so any link or search result lands in the same place.
- **Keeping your place.** The breadcrumb remembers the route you took: a promise that serves three capabilities shows the capability and requirement you came from, and lists the others ("Serves 3 capabilities — counted under each of them").
- **Same summary at every level.** Tests (passing of total), Reviews (kept, broken, not reviewed) and Open gaps (by state), plus one bar of counts. Product, capability, requirement and step all use it, rolled up from promises.
- **Tests and reviews apart.** On a promise, the test result (result file, commit, failed checks) and the review history (each judgment in order, who was at fault, the prose) are two panels. Tests are marked with filled dots; reviews with outlined squares.
- **Delivery** is a second way in: built, tested and reviewed as three separate counts, needs-you, agents now, steps over time and recent changes. Every item opens its node in the tree.
- **Search** from anywhere: `/` or ⌘/Ctrl-K. It accepts ids loosely (`row-37`, `s8`) or words; Enter goes to the first match.
- **Time.** The header always shows the moment, Live or Replayed, and the previous and next snapshots. A replayed snapshot also gets a banner.

## How the change log handles scale
1,762 changes are never shown as one list:
1. **Narrow first:** a range between two moments, capability, kind (each kind chip shows its count), and free text.
2. **Group with counts:** by kind, then by what changed. Promise states group by transition (e.g. Never run → Passing · 512); reviews group into Broken and Kept.
3. **Show a few:** 8 items per group, with "Show 25 more · N not shown".
4. **Commits** start as a count. The list opens one click later.

## States (Tweaks)
- `mode`: snapshot or index (index opens on Snapshots).
- `replayed`: shows the replayed banner.
- `dataset: empty`: the first-snapshot, nothing-recorded state.
- `theme`: auto, light or dark.

Search with no results and filters with no results both have their own empty messages.

## Sample caveats
- Canvases are null in the sample. The S01–S06 states point at the one example canvas (`S Platform staff`), so those open at their marker. Other states are marked as having no embedded design.
- The sample doesn't include review prose, so each judgment says the notes aren't in this snapshot.
- Delivery: dataset is split into `viewer-data.js` and `canvases.js` for editing; bundle to one offline file for distribution.
