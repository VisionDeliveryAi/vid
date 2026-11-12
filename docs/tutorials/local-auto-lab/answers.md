# JobDigest search: the prepared answers

Each sitting below gives ViD's question in its own words, cut where long, and the answer typed in the walk this lab was made from. Your interview will not be word for word the same: the questions are a model's. Where a question matches, give the answer here. Where ViD asks something this file does not hold, choose the smaller of what it offers; when nothing is smaller, accept its recommendation.

---

## 1. Starting

**Typed:**

> /vid:vid-init

ViD checked the folder was empty and asked you to describe the product: "**To start, please describe the product in your own words.** … If you have an existing document, … say which it is: **My demand:** your own brief, which outranks everything else. **Evidence:** background material …"

**Answer:**

> Here is my brief. It is my demand, and I have no other document.
>
> (then the paragraph from `seed.md`)

---

## 2. The interview batch

ViD asked eight questions, each with its recommendation, and a scope check of the brief's parts.

| # | ViD asked (cut) | Its recommendation (cut) | Answer |
|---|---|---|---|
| 1 | **What counts as a "word"?** Job titles are messy: "Front-End Developer", "C++ Engineer", … | spaces, hyphens, slashes, commas, brackets and "&" separate words; + and # stay part of the word | (c): only spaces separate words. |
| 2 | **Accents.** Should "cafe" find "Café Manager"? | no: only upper and lower case are treated alike | As recommended. |
| 3 | **The page before any search, or after submitting a blank box.** | just the search box and a short hint | As recommended. |
| 4 | **Order of results.** | the order of the shipped list | As recommended. |
| 5 | **How many results.** | every match on one page, no paging, plus a count ("12 jobs") | Every match on one page, no paging, and no count for now. The list will be about 50 jobs. |
| 6 | **What "nothing stored about the visitor" covers.** … Should results also be shareable as a link? | no cookies, nothing saved in the browser, no analytics, the words never sent to or logged by a server; shareable links yes | No cookies, nothing saved in the browser, no analytics or trackers, and the words a visitor types are never stored or logged. Shareable links: later. |
| 7 | **The job list itself.** … Do you already have the real list? | it changes only with a new version; every job has all four fields and a working link, or the list is refused; ViD writes a sample of about 50 jobs | As recommended. I have no real list yet: use your sample of about 50 jobs. |
| 8 | **Language.** | English only | As recommended. |
| | **Scope check:** several words at once, employer, location, "no matches" message, link | keep all | Keep everything, as you recommend. |

Typed as one message:

> 1. (c): only spaces separate words.
> 2. As recommended.
> 3. As recommended.
> 4. As recommended.
> 5. Every match on one page, no paging, and no count for now. The list will be about 50 jobs.
> 6. No cookies, nothing saved in the browser, no analytics or trackers, and the words a visitor types are never stored or logged. Shareable links: later.
> 7. As recommended. I have no real list yet: use your sample of about 50 jobs.
> 8. As recommended.
> Scope check: keep everything, as you recommend.

Where the answer chose less than the recommendation (1, 5, 6), it is on purpose: each would have been one more thing to specify, test and build.

---

## 3. The first approval: thesis, topics and features

ViD showed the thesis (four goals: matching, results, privacy, the job list), five features, the topics the requirements must cover (6 kept from its standard checklist, 11 struck, 2 ruled out, 6 added by its reviewers), six red-team findings with one question for you, and eight decisions of its own.

| ViD asked (cut) | Answer |
|---|---|
| **F-03: do the host's standard request logs (visitor address, time, browser) count as "storing something about the visitor"?** (a) yes, only hosting without such logs qualifies (its recommendation); (b) no, as long as they never contain the typed words | (b) |
| With only spaces separating words, "Manager (Night Shift)" is found by "shift)" but not by "night". Keep, or also separate at brackets and commas? | Keep. |
| The topic list | Accepted. |
| Its decisions, among them A-013 (accessibility to the common legal standard) and A-014 (speed targets on a phone) | A-013 and A-014 later; the rest stand. |
| The thesis | Approved. |

This is where you set the size: there are no requirements yet at this sitting, so the limit is given for the ones ViD writes next.

Typed as one message:

> 1. F-03: (b). Ordinary host logs are acceptable, as long as they never contain the typed words.
> 2. Keep: only spaces separate words.
> 3. The topic list is accepted.
> 4. A-013 and A-014 are later, not in this version. Your other decisions stand.
> 5. Thesis approved.
>
> And the size: this is a first version, so write at most 3 requirements. Move anything else out of this version.

---

## 4. The second approval: the requirements

ViD came back with exactly 3 requirements: R1 matching, R2 results, and R3 "no trace", the one rule that must never break. Each has its fail-if: the concrete ways a wrong build would fail it. It asked four questions from its completeness review, and proposed six topics to mark "not in this version".

| ViD asked (cut) | Its recommendation | Answer |
|---|---|---|
| 1. R3 says the page loads nothing from any other site; that was ViD's decision. Confirm it? | confirm | Confirmed. |
| 2. Following a posting: same tab or a new one? | a new tab, so the results stay | Same tab for now. |
| 3. Unsafe links in the list: (a) only http/https links are clickable; (b) trust the list | (a) | (b) |
| 4. A one-line privacy note on the page? | later | Later. |
| The six topics proposed "not in this version" | not in this version | Not in this version. |

**The fail-if made stronger, on purpose.** Read each requirement's sentence, then its fail-if, and ask: could the product break the sentence while the fail-if stays false? In the walk, R2 promised each job's own employer, location and link, but its fail-if only failed when one was missing, not when it was another job's.

Typed as one message:

> 1. Confirmed: the page loads nothing from any other site.
> 2. No: postings open in the same tab for now.
> 3. (b): trust the list as written; I own its correctness.
> 4. Later, as you recommend.
> The topics you propose, posting-link safety included, are not in this version.
>
> Requirements approved, with one change. REQ-002's fail-if is too weak: it fails if a shown job lacks its employer, location or link, but not if it shows another job's. Add: a shown job's employer, location or posting link is not the one the shipped list gives for that job.

---

## 5. The third approval: final

ViD's whole-set review added three clauses inside the existing requirements (spaces around words are ignored; the browser's autofill must not keep the typed words; postings open in the same tab), so there were still three requirements. It asked three questions:

| ViD asked (cut) | Its recommendation | Answer |
|---|---|---|
| 1. A job in the list with a missing field: R1 says show it when it matches, R2 fails if it is shown with a field missing. No build can satisfy both. | show each job's fields exactly as the list gives them | As recommended. |
| 2. Confirm its decision that extra spaces are ignored and a repeated word counts once | | Confirmed. |
| 3. Confirm its decision that the typed words never appear in the address bar, any request, or the referrer | | Confirmed. |

Typed as one message:

> 1. As recommended: show each job's fields exactly as the list gives them.
> 2. Confirmed.
> 3. Confirmed.
> Final approved.

Question 1 is a contradiction your own earlier answer made ("trust the list as written"); the review found it before anything was built.

---

## 6. The technical questions

Right after the final approval ViD asked two optional hints and four questions on where the product will run. The building happens on your machine; the finished product will be hosted. Nothing about hosting is chosen yet, and that is a fine answer. ViD said what it was not asking: there is no email, no outside service and no database.

| ViD asked (cut) | Answer |
|---|---|
| 1. "Any directional hints on design?" | The page is plain and text-like. I am not bringing a design, and I am not asking for one now. |
| 2. "Any directional hints on architecture and technical stack?" | You pick. |
| 3. Hosting platform and region (it suggested a static-page host near your visitors) | It will be hosted, but I have not chosen the host or the region yet. Your default where you have one. |
| 4. Web addresses for the test site and the live site | Not chosen yet; the platform's own addresses are fine when the time comes. |
| 5. Monthly spend cap | Not chosen yet. |
| 6. How ViD gets access to the host (never a password or a token: the log-in, or the name of a variable) | No account and no access exist yet. |

There was no design sitting. ViD recorded the hint word for word and said: "Step 3, design, is skipped because you deferred it." A design can be run later.

---

## 7. The test inventory

ViD derived every test the project will have from the three requirements: 59 rows (22 for matching, 17 for results, 20 for "no trace"), 6 rules checked across all the code, 6 hostile attempts (each tries a forbidden thing with its guard switched off and must be seen to fail), and 15 questions for the reviewers who grade the result. Expert reviewers (privacy, text matching, abuse, a first-day visitor, the host) proposed rows over three rounds; a counterexample reviewer then looked for a wrong product that would pass the whole table. It asked two questions.

| ViD asked (cut) | Its recommendation | Answer |
|---|---|---|
| 1. Which characters count as a space between words? Pasted text and phones produce tabs, non-breaking spaces and line breaks that look like spaces. (a) every space-like character; (b) only the ordinary space | (a) | (b) |
| 2. Should a typed `'` find a title written with `’`, and `-` find `–`? (a) no, they stay different; (b) yes | (a) | (a) |

Typed as one message:

> 1. (b): only the ordinary space.
> 2. (a): they stay different.
> No rows to strike. Inventory approved.

---

## 8. Two housekeeping questions before the spec is committed

ViD rewrote the PRD as its effective content, moving your brief word for word to a file of its own and the history to another, and showed what changed: 3 requirements unchanged, 12 out-of-scope items labelled "this version", nothing dropped or weakened. It also asked to set a compaction point for this project only, so a long build session summarises itself before its context grows large.

**Answer:**

> Consolidation approved. And yes to the compaction point.

---

## 9. The stage cut

ViD looked for a cut into smaller releases, each usable on its own and safe to put live, and found none finer than one stage: search without results gives a visitor nothing; search and results without the no-trace rule are not safe to release; the rule alone has no page. It showed the one stage's card (all three requirements, all 59 rows, effort "S") and said it did not recommend a technical stage 0 for a product with no outside service.

**Answer:**

> One stage, no stage 0. And no: do not set up the test site or put anything on it on your own.

The second sentence answers a question ViD asks once in most walks: whether it may set up the test site and put each finished stage on it by itself. Going live always waits for you either way.

---

## 10. Starting the build

**Typed:**

> /vid:vid-develop

The build runs on its own from here, in the same session: it writes the tests first and sees each one fail, then builds until they pass, and has fresh reviewers judge each part against its fail-if. Keep the session open.

To ask where it stands, at any time:

> Where does the build stand?

In the walk the answer came in seconds, while the build was waiting on its own agents.

---

## 11. Questions the build asked

| # | Whose | ViD asked (cut) | Answer |
|---|---|---|---|
| Q1 | The product | "**row 27, the not-found page.** Unknown addresses already get a plain "not found" page … But addresses naming the site's own folders, like `/jobs/`, … get the web server's "403 Forbidden" page … (a) Yes … **I recommend this** … (b) Grade it again … (c) Record it as a known limit" | Q1: (c), record it as a known limit. |
| Q2 | ViD's housekeeping | "In ViD's own counting script, one line reads its input wrongly. … **May ViD fix that one line?** … **I recommend yes.**" | Q2: yes, fix that line. |

Q1 did not stop the build; it showed in the build's running notes and waited for an answer. Recording a limit has a consequence: the build then ends "not complete", with that one row unmet, until you change the ruling.

---

## 12. What came back

At the end the build printed its completion report: how many tests pass and how many a reviewer kept (49 of 60 in the walk; 10 more can only be checked on a real host), one line per requirement (PASS or PARTIAL), and a table of findings from its own final grade.

**Trying it.** Typed:

> Before I rule: how do I try the product myself, as a visitor, in my own browser on this machine?

ViD gave one command to start it, the address to open (`http://localhost:8080`), how to stop it, and a list of things worth trying. The command is typed in a terminal; if you do not use one, ask ViD to run it for you.

**The project viewer.** Typed:

> /vid:vid-view

It made a set of pages in a folder of its own outside the project and gave the path of the two to open first.

---

## 13. Ruling on the final grade

The grade found 15 things, from one high (in older browsers the typed words reach the address bar) to several low ones (the keyboard stays up on a phone; the link is a small tap target). For each one say **fix**, **dispute** or **defer**. Fix what breaks a promise you made; defer what you never asked for in this version; dispute what is not a fault.

**Typed:**

> Q3, my rulings:
> G-1: fix. The no-trace promise must hold in every browser that can use the page.
> G-8: dispute. A numbered list is fine; it is not the count I ruled out.
> G-2, G-3, G-4, G-5, G-6, G-7, G-9, G-10, G-11, G-12, G-13, G-14, G-15: defer.
> The folder-address limit stays as I ruled it.
> Apply the fix.

ViD recorded the rulings in the PRD and started the fix itself: a test that shows the leak, seen failing, then the change. Its review of your ruling raised one more product question, about browsers that do not run the page's script:

> **Q4. In a browser that doesn't run the page script, what should a visitor see?** (a) A plain line saying the search needs the page's script. **I recommend this** … (b) Leave it silent …

The walk's time ran out here, so Q4 was left unanswered and the build was paused with ViD's own word:

> pause

ViD finished the step under way and stopped: "Say "continue" and I'll pick up from here." To carry on, answer Q4 and type `continue`.
