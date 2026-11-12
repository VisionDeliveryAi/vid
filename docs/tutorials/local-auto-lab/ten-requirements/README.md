# The local auto lab: JobDigest, the larger example with ten requirements

This folder holds what you bring to the hands-on tutorial for ViD's local auto mode, where ViD's own agents write and test the code on your machine, with no GitHub. You play the product manager. You never write code and never read it.

## What is here

| File | What it is for |
|---|---|
| `seed.md` | The paragraph you paste when ViD asks what you want to build. It also says why the seed is this small. |
| `answers.md` | The answer typed at every sitting in the walk this lab was made from, in order, each under ViD's own question: the interview, the three approvals of the requirements, the technical questions, the design, the test inventory, the stage cut, the questions the build asked, and the two looks at what came back. |
| `design/` | Two ready-made screens and their colours and spacing, to bring back when ViD asks for your design: `screens/S01-save-a-search.html` (the sign-up page, blank and after Save), `screens/S02-saved-search.html` (the confirmed search), `tokens.css`, and a `README.md` naming each screen's states. |

There is no code here. In this mode ViD writes it.

## Before you start

- Claude Code, signed in, with ViD installed.
- Docker Desktop, installed and running: ViD runs every test inside Docker.
- An empty folder, and a Claude Code session started in it.
- Time. In the walk the requirements took about an hour of ViD's work and a dozen short answers. The walking skeleton, the first thin path end to end, took a little over four hours with no help from you beyond four short answers.

## How to use the answers

ViD's questions are a model's, so yours will not be word for word the same. Where a question matches one in `answers.md`, give that answer. Where ViD asks something the file does not hold, choose the smaller of what it offers; when nothing is smaller, accept its recommendation.

The answers keep the product small on purpose. A first try of this lab with a three-sentence seed and "as you recommend" at every question grew to 64 requirements before it was stopped. The seed in `seed.md` names what is out as plainly as what is in, and the answers choose less wherever a question offers more.

## The design pack

The screens carry no markers saying which of ViD's screens and states each drawing is. ViD's import will say so and offer to add them; say "Add them". The states your two screens do not draw (the confirmation page, the unsubscribe pages, the emails) can be marked "owed": the builder makes them plain, using only your colours and spacing.
