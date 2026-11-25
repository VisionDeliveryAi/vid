---
name: vid-triggers
description: A ViD call's lines in ticket mode, in both GitHub modes: what is not yet with the team, counted once by kind; the team's changes to published tickets; the re-plan triggers in their tiers, with their evidence; the warnings and the moves. Invoked by /vid next, and by /vid run after a step that printed something new, which re-plans from its lines through the vid-replan skill; the owner's command `/vid:vid-triggers` shows them at any time. Use when the owner says "vid triggers" or asks what may call for a re-plan.
---

# /vid:vid-triggers

One job: `sh checks/next.sh triggers --short`, and show its lines as it prints them: one line a kind, with its count, every
subject and its evidence in it (FB-3 C5; the full lines, one each, are `sh checks/next.sh triggers`). The count, the tiers, the
warnings and the moves are its own; a publish's warnings are `plan.sh warnings`' lines, after the moves (GM-4 K9). This skill adds
none and drops none. It reads ViD's records and `.vid/round/read` (vid-read's), and writes nothing. Its lines name their evidence: say them
in plain words, keeping each number as printed. A `context folder` line (FB-4 B1) says the folder the team reads the spec in does not hold the
applied version's: say which commit's it holds and the command it names; the owner judges which is right. A `context publish #<n> <words>` line (FB-5 C2) says
what stands on an open pull request of the owner's own, or on a publish's: say it as it is; a review there is the owner's to answer. In GitHub auto the round prints it, `publish #<n> <words>`, for the spec's publish alone, once a
change: say it to the owner in one line; it stops nothing.

**Called by the owner** as `/vid:vid-triggers`, in either GitHub mode: inside /vid run's own conversation it uses the run's lock and
leaves it held; anywhere else the vid-connect skill's start first and its end after, however the call ends (GM-4 S0). The vid-read skill's read
comes first, so the lines judge what GitHub holds now.

**In /vid run** (GM-4 K9), after a step that printed something new: its lines, said once each; a trigger among them is a line that
may call for a re-plan, which the vid-replan skill's GitHub auto paragraph makes.
