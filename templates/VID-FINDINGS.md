<!-- .vid/VID-FINDINGS.md — ViD's own defect log (v0.26.10.3 R12, R13; RECORDS.md).
     Appended by the run managers of vid-init, vid-develop, vid-fix and
     vid-add when a ViD check, hook, skill or agent role misbehaves — it
     refuses legitimate work, crashes, contradicts itself or its
     documentation, or gives a wrong count — or when they use a workaround
     around one. A defect in the product being built is not a ViD finding.
     Created from this file at the first entry; newest last; entries are
     numbered in this file, F-1 first. Evidence names project paths, never
     pasted product content. Counts, never scores. Each entry is also an
     event: sh checks/event.sh 'vid-finding n=<n> area=check|hook|skill|agent
     file=<ViD path>', and one line to the owner. The export carries the
     whole .vid/, this file with it. -->

# ViD findings — {{PROJECT_NAME}}

## F-<n> · <title>

- **Seen:** <UTC date> · ViD <version> · records <n> · <verb>, <step>
- **Where:** <the ViD file>[:<line>, if known]
- **What happened:** <what ViD did, and what it should have done>
- **Evidence:** <project paths: .vid/…, commits, receipts, briefs>
- **Cost:** <counted minutes, re-runs or tokens lost> | not counted
- **Local workaround:** <what was done instead>[ (owner answer A-<n>)] | none
- **Ask:** <what ViD should change>
