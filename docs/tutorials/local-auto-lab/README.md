# The local auto lab: JobDigest search

This folder holds what you bring to the hands-on tutorial for ViD's local auto mode, where ViD's own agents write and test the code on your machine, with no GitHub. You play the product manager. You never write code and never read it.

The product is the smallest useful one: a single page where a visitor types words and sees the jobs whose titles contain them all. It is small on purpose, so that the whole thing, from the first question to a built product judged by fresh reviewers, fits in one long afternoon.

## What is here

| File | What it is for |
|---|---|
| `seed.md` | The paragraph you paste when ViD asks what you want to build, and why it is this small. |
| `answers.md` | The answer typed at every sitting in the walk this lab was made from, in order, each under ViD's own question: the interview, the three approvals, the technical questions, the test inventory, the stage cut, the questions the build asked, and the ruling on the final grade. |
| `ten-requirements/` | A larger version of the same idea (saved searches, a confirmation email, a daily email), with its own seed, answers and a two-screen design pack. Read it to see how fast a product grows; it is not needed for the tutorial. |

There is no code here and no design. In this mode ViD writes the code; for this product you tell it you bring no design, and it builds the page plain.

## Before you start

- Claude Code, signed in, with ViD installed.
- Docker Desktop, installed and running: ViD runs every test inside Docker.
- An empty folder, and a Claude Code session started in it. Keep that one session open for the whole afternoon: the build runs inside it.

## How long it took in the walk

| Part | Time |
|---|---|
| The interview to an approved spec: three requirements, 59 tests planned | about 1 hour, of which about 10 short answers are yours |
| The build, to its completion report and its own final grade | about 2 hours 20 minutes, with two short answers from you |
| Trying the product, the project viewer, reading the grade and ruling on it | about 20 minutes |
| Applying the one finding you accept | it had run 12 minutes, not finished, when the walk's time ran out |

## How to use the answers

ViD's questions are a model's, so yours will not be word for word the same. Where a question matches one in `answers.md`, give that answer. Where ViD asks something the file does not hold, choose the smaller of what it offers; when nothing is smaller, accept its recommendation.

Choosing less has costs, and the walk met them: "only spaces separate words" means "night" does not find "Manager (Night Shift)"; "postings open in the same tab" means retyping the search after each one. The final grade names such things. Deciding which to fix now and which later is your part.
