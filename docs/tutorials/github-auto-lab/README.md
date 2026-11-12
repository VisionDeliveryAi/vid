# The GitHub auto lab: JobDigest search

This folder holds what you bring to the hands-on tutorial for ViD's GitHub auto mode, where ViD builds your product through GitHub and ViD's own DevAgent, the dev side that ships with ViD, works the tickets. You play the product's owner. You never write code and never read it.

The product is the smallest useful one, the same as in the local auto lab: a single page where a visitor types words and sees the jobs whose titles contain them all.

## What is here

| File | What it is for |
|---|---|
| `seed.md` | The paragraph you paste when ViD asks what you want to build, and why it is this small |
| `answers.md` | The answer for every sitting of the spec, in order, each under ViD's own question. They were recorded in a run of this product in local auto mode; the spec is written the same way in every mode. Its last section gives the form of the answers the rest of the tutorial needs |
| This file, below | The job note that ViD prints for the dev side when the run starts, read line by line. The same note ships with ViD as an example, `devagent/job-note.example` |

There is no code here and no design. In this mode ViD's dev side writes the code; for this product you tell ViD you bring no design, and the page is built plain.

## Before you start

- Claude Code, signed in, with ViD installed. The `claude` command must also be on your path and signed in: the dev side's agents are Claude Code sessions with no window.
- git, and the GitHub command line, `gh`, signed in to an account where you may create two private repositories.
- Docker, installed and running: the dev side will not start without it, and normally runs the tests in it.
- A browser installed on the machine, for the walk of the test site.
- On a PC: WSL2, with Docker Desktop's WSL2 integration switched on. Everything is done inside it.

## The job note, line by line

When the run starts, ViD prints the job note filled in for your project, says where to save it, and prints how to start the dev side. You save what ViD printed. A job note looks like this:

```
repo: your-account/jobdigest-search
labels-prefix:
work: /full/path/to/jobdigest-search-devagent
time-limit: 86400
agent-time-limit: 10800
agent-turn-limit: 500
model: claude-opus-5-5
```

| Line | Its key | What it is | Where its value comes from |
|---|---|---|---|
| 1 | `repo:` | The code repository the dev side works on, as account/name. The dev side needs write access to it | Your answer to the plan's setup |
| 2 | `labels-prefix:` | A prefix for the labels ViD puts on its issues. The line must be present; it may be empty | The plan's setup. Empty unless you gave a prefix |
| 3 | `work:` | The dev side's work folder, as a full path. It must not be inside the folder where ViD keeps the spec. You make it before the start | ViD proposes one, beside the project folder: the project's name with `-devagent` |
| 4 | `time-limit:` | The loop stops itself after this many seconds. 86400 is one day | A default, which ViD says you may change |
| 5 | `agent-time-limit:` | One agent is stopped after this many seconds. 10800 is three hours | A default, generous on purpose |
| 6 | `agent-turn-limit:` | One agent ends after this many turns | A default, which ViD says you may change |
| 7 | `model:` | The model every agent runs on, written exactly as an agent's first message shows it. A short name is refused | The dev side's own default |

The numbers here are the defaults ViD prints. An example that ships with ViD, `devagent/job-note.example`, has a comment on each line and smaller numbers. Lines that begin with `#` are comments, and the dev side reads only the lines of the form `key: value`.

**About the agent limit.** It is generous on purpose. An agent stopped at its limit is replaced once; if the second is stopped too, the dev side leaves the ticket and does not take it up again by itself. So a low limit costs a ticket, not a restart. What is recorded about the loop's own limit: in a recorded run a loop with a four-hour limit stopped at that limit with work still to do. When the loop stops, the stop is said on GitHub and in ViD's session, and the next start picks up from the records; a run that ViD asked for while the loop was down is not made until then.

## How to use the answers

ViD's questions are a model's, so yours will not be word for word the same. Where a question matches one in `answers.md`, give that answer. Where ViD asks something the file does not hold, choose the smaller of what it offers; when nothing is smaller, accept its recommendation.

## What this lab cannot give you

This lab was not walked. Nobody has yet taken this product through GitHub auto, so there are no prepared answers for the questions the dev side asks or for the findings, and no recorded time for the build. The tutorial says, stop by stop, which of its statements come from ViD's own scripts and which from recorded runs of other products.
