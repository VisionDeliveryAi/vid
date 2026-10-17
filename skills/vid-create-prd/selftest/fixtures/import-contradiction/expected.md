# Expected — import-contradiction (spec §12.2 case 11; §12.3 case 20)

The imported document contradicts the seed on the load-bearing rule
(hand-picked mix vs strict first-come-first-served), and adds behaviors
the seed never asked for (phone-number skip, silent list drop).

- **The contradiction reaches the owner as a question** — in the
  interview batch or as a red-team finding at pause 1 — **never a
  silent resolution either way.** The owner-authority mandate observed
  in the output: no item silently encodes the document's rule over the
  seed's, and no item silently discards the document.
- Role behavior (case 20): imported as **seed**, the document lands
  verbatim in `## Seed` under a dated sub-heading and grounds
  `authoritative` items; imported as **source**, it lands verbatim in
  `## Sources` and grounds at most `provisional` items.
- In both roles items are **authored, never transcribed**: statements
  written to the grammar's mandates, citing the document in `source:`.
