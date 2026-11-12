# JobDigest: the prepared answers

Each sitting below gives ViD's question in its own words, cut where long, and the answer typed in the walk this lab was made from. Your interview will not be word for word the same: the questions are a model's. Where a question matches, give the answer here. Where ViD asks something this file does not hold, choose the smaller of what it offers, or accept its recommendation when nothing is smaller.

---

## 1. The opening question

> **What do you want to build?** Describe it however you like: a paragraph, a rough brain-dump, or an existing document you can paste or point me to. …
> If you hand me an existing document, also tell me whether it's **your demand** (what you want built) or **background evidence** …

**Answer:**

> Here is my brief. It is a seed, and I have no other document.
>
> (then the paragraph from `seed.md`)

---

## 2. The interview batch

ViD asked eleven questions in three groups, each with a recommendation, and a boundary challenge naming what the first version could ship without.

| # | ViD asked (cut) | Its recommendation (cut) | Answer |
|---|---|---|---|
| 1 | **What does a saved search contain?** | keywords plus an optional location | Keywords only, no location: a job matches when every keyword appears in its title, upper or lower case alike. |
| 2 | **What happens when an address that already has a search saves another one?** | one search per address; the new one replaces the old once confirmed | As recommended. |
| 3 | **Which jobs count as "new" in a day's email?** | jobs the feed shows for the first time since the previous email | As recommended. |
| 4 | **What happens on a day with no new matches?** | send nothing | As recommended. |
| 5 | **When does the daily email go out?** | once a day at 07:00 UTC for everyone | As recommended. |
| 6 | **What if a day has a lot of matches?** | at most 50 jobs, newest first, "and N more matched today" | As recommended. |
| 7 | **What happens to someone's data when they unsubscribe?** | delete the address and search immediately; unconfirmed sign-ups deleted after 7 days | As recommended. |
| 8 | **Who are your visitors, and in what language?** | English only, EU privacy law as the floor | As recommended. |
| 9 | **Who reads the support address, and what do you promise?** | you read it yourself, with no promised response time | As recommended. |
| 10 | **Which job feed?** | name it, or say it isn't chosen | Not chosen yet. Build against one feed that gives each job a title, an employer, a location and a link to the job's own posting; I will point it at a real board later. |
| 11 | **What would tell you, after a few weeks, that this works?** | count sign-ups, confirmations and unsubscribes; no click or open tracking | As recommended. |
| | **Boundary challenge:** the confirmation email, the support address, the location in the search | keep, keep, your call | Keep the confirmation, keep the support address, cut the location. |

Typed as one message:

> All recommended, except these:
>
> 1. Keywords only, no location: a job matches when every keyword appears in its title, upper or lower case alike.
> 10. Not chosen yet. Build against one feed that gives each job a title, an employer, a location and a link to the job's own posting; I will point it at a real board later.
>
> Boundary challenge: keep the confirmation, keep the support address, cut the location.

Question 9 matters later: the correction you make after the build changes this answer.

---

## 3. The first approval: thesis, contract and features

ViD showed two red-team questions that block the sitting (F-01, F-02), the thesis with three goals, a contract of 23 areas the requirements must cover (4 it recommends striking), seven features, and 18 decisions it took itself, numbered.

| What ViD asked (cut) | Answer |
|---|---|
| **F-01. Can mail scanners unsubscribe people?** Recommendation: the email's link opens a page with one Unsubscribe button, plus the mail standard's own unsubscribe header. Alternative: keep a true single click. | The alternative: a true single click. |
| **F-02. Should old jobs flood the first email after a board switch?** Recommendation: the first read of a feed only records its jobs as already seen. | As recommended. |
| The 4 contract areas to strike | Strike them. |
| Its decisions 5 (flood limit on confirmation emails), 6 (bounces and spam complaints), 14 (sending rules), 15 (backups and alerts), 16 (speed and uptime), 17 (accessibility) | Later, not in this version. |
| Its other decisions | Stand. |

This is also where the product manager sets the size. There are no requirements yet at this sitting, so the limit is given for the ones ViD writes next.

Typed as one message:

> F-01: the alternative. The unsubscribe link in the email stays a true single click; I accept that scanners will cause some false unsubscribes.
> F-02: as recommended.
> Strike the 4 contract areas.
> The thesis and the features stand.
>
> Your decisions: 5, 6, 14, 15, 16 and 17 are later, not in this version. The rest stand.
>
> And one instruction for the requirements you write next: this is a first version, so keep it to at most 10 requirements. What must be in them: saving a search with an address, confirming it from the email, the daily email of new matches, the one-click unsubscribe, the support address, and reading the one feed. Move anything else out of this version.

Your decision numbers will differ: say "later" to each one the seed does not ask for.

---

## 4. The second approval: gap answers

ViD came back with exactly 10 requirements (9 behaviours and 1 must-never-break rule), six questions from its completeness audit, and one plain sentence per requirement.

| ViD asked (cut) | Its recommendation (cut) | Answer |
|---|---|---|
| 1. Is "Ann@Example.com" the same address as "ann@example.com"? | trim spaces and ignore case | As recommended. |
| 2. A job with a title and link but no employer or location: does it appear? | list it and show "Not stated" | As recommended. |
| 3. Basic protections on the public form: the keywords as plain text in the confirmation email; HTTPS; data encrypted at rest | put them into the requirements | The alternative: leave both to the builder. |
| 4. A privacy notice on the sign-up page | a short notice | Out of this version; we add the notice before the first real subscriber. |
| 5. Where do you read the counts for your four-week review? | a daily email of the previous day's totals | The alternative: I query the data myself, and no daily counts email. |
| 6. Are typed keywords split like titles ("front-end")? | split them the same way; refuse a sign-up with no keyword | As recommended. |

**The fail-if made stronger, on purpose.** Read each requirement's sentence, then its fail-if, and ask: could the product break the sentence while the fail-if stays false? In the walk, the daily email's rule promised 07:00 UTC, and its fail-if said nothing about the hour.

Typed as one message:

> 1. As recommended.
> 2. As recommended.
> 3. The alternative: leave both to the builder.
> 4. Out of this version; we add the notice before the first real subscriber.
> 5. The alternative: I query the data myself, and no daily counts email.
> 6. As recommended.
>
> The 10 sentences are approved, with one change. REQ-005's fail-if is too weak: its rule promises the email goes out at 07:00 UTC, but nothing in the fail-if fails if it goes out at 15:00. Add: a daily email from a run that did not fail is sent before 07:00 UTC or more than one hour after it.

Your requirement numbers will differ: find the one about the daily send.

---

## 5. The third approval: the final sign-off

ViD's whole-set review left four questions, each a contradiction between two clauses that only the product manager may settle, and showed two fail-ifs its wording lens had made stronger.

| ViD asked (cut) | Its recommendation (cut) |
|---|---|
| 1. Jobs past the 50-job cap: dropped or carried over? | dropped, counted in the "N more" line |
| 2. A former subscriber signs up again: does the unsubscribe rule block the confirmation email? | the rule means daily emails |
| 3. The feed is down at 07:00 but back at 10:00 | an unreadable feed makes the run a failed run, retried the same day |
| 4. An unsubscribe link in an email from before an earlier unsubscribe | it unsubscribes whatever the address holds now |

**Answer:**

> All recommended. The PRD is ratified.

From here the PRD is frozen. Every later change is an append to it, never an edit.

---

## 6. The technical questions

Right after the final approval, in the same answer, ViD asked init's own questions: two on direction, and seven on where the product runs. The building happens on your machine; the finished product will be hosted. Nothing about hosting is chosen yet, and that is a fine answer: ViD records it and asks again when a deploy needs it.

| ViD asked (cut) | Answer |
|---|---|
| 1. "Any directional hints on design?" | Plain and text-like. I have two ready-made screens of my own to bring for the design. |
| 2. "Any directional hints on architecture and technical stack?" | You pick. |
| 3. Hosting platform and region (it recommended one) | It will be hosted on a platform, but I have not chosen the platform or the region yet. |
| 4. Staging and production addresses | Not chosen yet. |
| 5. Sending address and its domain; the support address | Not chosen yet, and neither is the support address. |
| 6. Monthly spend cap | Not chosen yet. |
| 7. How ViD gets access to the platform (never a password or a token: the log-in, or the name of a variable) | No account and no access exist yet. |
| 8. Outside services: an email-sending service and the job feed: which have an account? | Neither has an account yet. |
| 9. Downtime tolerance for a release that changes the database | Your default. |

---

## 7. The design

ViD wrote a design brief listing every screen and state the product shows (a sign-up page, a confirmation page, an unsubscribe page, two emails, and the shared pieces), and asked for your screens.

**Answer 1, the screens:**

> My screens are in the folder `<where you put this lab's design folder>`: a README, tokens.css, and two screens in screens/. They carry no markers.
>
> - S01-save-a-search.html is the sign-up page: its section s01-default is the blank form, and its section s01-saved is the "check your email to confirm" answer.
> - S02-saved-search.html is the saved search once it is active: the confirmed state.

ViD's import check could not tell which drawing is which screen, because the files carry no markers, and it changes nothing in your files on its own. It proposed three marker lines, one per drawing, and listed the 13 states your two screens do not draw, recommending each be **owed**: the builder makes it plain, using only your colours and spacing, and the graders check it against your two screens.

**Answer 2:**

> Add them. And all 13 owed.

Then a fresh reader compared the screens' words with the requirements and found two disagreements and one rule the design embodies:

| ViD asked (cut) | Its recommendation |
|---|---|
| **D-01.** Your screen says "Check your inbox to confirm"; the requirement fixes "check your email to confirm" | design wins: the requirement takes your wording |
| **D-02.** Your confirmed screen says nothing about when emails arrive | PRD wins: one line is added to your screen ("emails arrive once a day at 07:00 UTC on days with new matches") |
| **R-01.** Your screen echoes back the address and search words just typed, which the no-sign-in rule as written forbids | keep the echo, and amend the rule |

**Answer 3:**

> All recommended.

---

## 8. The test inventory

ViD derived the whole list of what will be checked from the ten requirements and the design: one row per promise of each requirement, rows added by expert lenses (abuse, privacy, the operator of a daily batch, a first-day job seeker), journeys, rules counted everywhere, probes against the two must-never-break rules, and a list of matching cases ("nurse" does not match "Nursery", "C++" does not match "C"). Ten requirements made 114 rows. It asked nine decisions, each with its recommendation already written into the rows.

| ViD asked (cut) | Its recommendation (cut) | Answer |
|---|---|---|
| 1. Retries after 08:00 UTC when the feed is down at 07:00 | keep retrying until a run succeeds or the day ends | As recommended. |
| 2. A second email on the same day after a late confirmation | first email the next day | As recommended. |
| 3. The send timed out but may have been delivered | never resend that day | As recommended. |
| 4. Which link variations are the same job | http/https, host capitals, trailing slash are the same | As recommended. |
| 5. The confirmation email fails to send | keep retrying until accepted or 7 days pass | As recommended. |
| 6. A sign-up rate limit per visitor | later | As recommended: later. |
| 7. Confirming a replacement | the page shows the current keywords beside the new ones (one more drawn state) | No: the confirmation page stays as it is. |
| 8. Two pending sign-ups for one address | each link confirms only its own keywords | As recommended. |
| 9. The privacy notice before going live | a row that blocks the move to production until it exists | As recommended. |
| One more owed design state: an invalid address refused with a message | built plain after your screens | OK. |

**Answer:**

> All recommended, except 7: the confirmation page stays as it is, with no separate replace state. The owed state P01/invalid-address is OK. The table is ratified as it stands.

ViD's review then found that ruling 2 contradicted two older clauses of the daily-send rule, and asked to narrow them; and it asked to approve the amended sentence for the "new jobs" rule.

**Answer:**

> Yes to both.

---

## 9. The stage cut

ViD showed its ladder of cuts. For a product this small the finest cut is a single stage: every smaller first release failed one of its tests (sign-up without the daily email is not usable; daily emails without the one-click unsubscribe are not safe to release). It offered, and recommended, a technical stage 0 before it: a thin journey end to end (sign up, confirm, one job in from the feed, one daily email that lists it), never released. It then asked three questions.

| ViD asked | Answer |
|---|---|
| 1. One stage, or one stage plus the technical stage 0? (recommends with stage 0) | One stage plus the technical stage 0. |
| 2. "May ViD set up the test site and put each finished stage on it on its own? Going live always waits for you." | No. Do not set up the test site or put anything on it on your own; I will tell you when. |
| 3. May ViD set this project's compaction point, so the build session compacts before its context grows large? (written only into the project's own settings) | Yes. |

Typed as one message:

> 1. One stage plus the technical stage 0.
> 2. No. Do not set up the test site or put anything on it on your own; I will tell you when.
> 3. Yes.

---

## 10. Starting the build

**Typed:**

> /vid:vid-develop

Nothing else. The build runs on its own from here. It stops only to ask you something, at a stage's close, or when you say "pause".

If your machine or your sign-in drops while it runs, sign in again and type:

> continue

ViD picks the build up from its own records.

---

## 11. Questions the build asked

The skeleton stage asked four questions. Two were about the product; two were ViD asking leave to fix its own housekeeping, each with a recommendation of yes. Answer the product ones as a product manager; for the others, take ViD's recommendation.

| # | What it was about | ViD asked (cut) | Answer |
|---|---|---|---|
| Q1 | ViD's housekeeping | "**Q1 — may I rename the tests' function names from `row017` to `ROW_017`?** … I recommend yes." | Q1: yes, rename them. |
| Q2 | The product | "**Q2 — which form of the address does the confirmation email go to?** When someone types `Ana.Smith@Example.com`, the product saves the address and sends the email in lower case … **(a) Lower case is acceptable — my recommendation.** **(b) Exactly as typed.** **(c) Record it as a known limit.**" | Q2: (a), lower case is fine. |
| Q3 | The product | "a fresh grader found that the row's test can't tell the difference. … **Q3 — must the confirmation go to the lower-case form, or is lower case only allowed?** **(a) Required — my recommendation.** **(b) Only allowed.** **(c) Record it as a known limit.**" | Q3: (a), required. |
| Q4 | ViD's housekeeping | "a bug in ViD's own checking scripts stops it from counting the last row as checked. The product is fine. … **Q4: may I fix ViD's own row reader in this project (one line)?** Recommendation: yes." | Q4: yes, fix it in this project. |

Q2 and Q3 show what a reviewer does: the first asked what the promise meant, and the second found that the test could not tell the two meanings apart. Each answer became one line appended to the PRD, never an edit.

---

## 12. Asking where it stands

**Typed, while it runs:**

> Where does the build stand?

The answer comes when the build next finishes a turn, which can be many minutes later. At each question and at each stage's close it prints its status table without being asked.

---

## 13. Trying the skeleton yourself

At the skeleton's close the build stops and says: "When you're ready, say "deploy to staging", then "continue"." Before either, try what was built.

**Typed:**

> Before I decide on staging: how do I try stage 0 myself, as a visitor, in my own browser on this machine? I want to sign up, find the confirmation email, press Confirm, and see the daily email that lists a job.

ViD wrote a small helper and gave the steps: start the product, open it in the browser, read the captured confirmation email, press Confirm, add a job to the fake feed, move the clock to the next morning, read the daily email, stop. Every step but the browser ones is a command. If you do not use a terminal, ask ViD to run each command for you and show you what came back.

---

## 14. The project viewer

**Typed:**

> /vid:vid-view

ViD made a set of pages, one for now and one for each moment of the project so far, in a folder of their own outside the project, and gave the path of the two to open first. They open by double-click and work offline.
