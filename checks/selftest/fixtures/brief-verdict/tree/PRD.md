# Linkling — PRD

grammar: 0.9.1

## Thesis

A short link is a promise about where it goes. Linkling earns trust by
refusing anything but web addresses, by expiring links on a fixed clock,
and by letting only the person who made a link remove it.

## Items

```vid-prd
REQ-001 | functional | T1 | A person pastes a web address and receives a short code that redirects to that address. | fail-if: a created code resolves to anything but the pasted address, or does not resolve at all | serves: the core loop | phase: pilot
REQ-002 | functional | T0 | Only web addresses are accepted as targets. | fail-if: a target whose scheme is not http or https is accepted | serves: trust — a short link never hides a script or a local file | phase: pilot
REQ-003 | functional | T1 | A link expires thirty days after it is created. | fail-if: a link older than thirty days answers a redirect instead of 410 gone | serves: a fixed, stated lifetime | phase: pilot
REQ-004 | functional | T0 | Only the holder of a link's deletion token can delete it. | fail-if: a wrong token deletes the link, or a refused deletion leaves the link unresolvable | serves: ownership without accounts | phase: pilot
REQ-005 | functional | T2 | Codes are six characters from a safe alphabet. | fail-if: a code carries an ambiguous character | serves: the promise stated in the thesis | phase: pilot
REQ-006 | functional | T2 | A link page shows the target before redirecting when the person asks for a preview. | fail-if: a preview redirects | serves: the promise stated in the thesis | phase: pilot
REQ-007 | functional | T2 | The service answers a missing code with 404. | fail-if: a missing code answers anything else | serves: the promise stated in the thesis | phase: pilot
REQ-008 | functional | T2 | Creation is rate-limited per address to sixty links an hour. | fail-if: a sixty-first link in an hour is accepted | serves: the promise stated in the thesis | phase: pilot
REQ-009 | functional | T2 | Deleted links never resolve again. | fail-if: a deleted code resolves | serves: the promise stated in the thesis | phase: pilot
REQ-010 | functional | T2 | The home page states the thirty-day lifetime. | fail-if: the lifetime is not stated | serves: the promise stated in the thesis | phase: pilot
REQ-011 | functional | T2 | A person can copy the short link with one control. | fail-if: copying needs more than one control | serves: the promise stated in the thesis | phase: pilot
REQ-012 | functional | T2 | Targets longer than two thousand characters are refused. | fail-if: a longer target is accepted | serves: the promise stated in the thesis | phase: pilot
REQ-013 | functional | T2 | The deletion token is shown once, at creation. | fail-if: the token is shown again later | serves: the promise stated in the thesis | phase: pilot
REQ-014 | functional | T2 | Links are case-sensitive. | fail-if: two codes differing only in case resolve to one link | serves: the promise stated in the thesis | phase: pilot
REQ-015 | functional | T2 | Abuse reports are accepted for any code. | fail-if: a report for an existing code is refused | serves: the promise stated in the thesis | phase: pilot
REQ-016 | functional | T2 | A reported link keeps resolving until an operator acts. | fail-if: a report alone stops a link | serves: the promise stated in the thesis | phase: pilot
REQ-017 | functional | T2 | An operator can disable a link. | fail-if: a disabled link resolves | serves: the promise stated in the thesis | phase: pilot
REQ-018 | functional | T2 | The service keeps no record of who clicked. | fail-if: a click stores the visitor | serves: the promise stated in the thesis | phase: pilot
REQ-019 | functional | T2 | Health checks answer without touching the store. | fail-if: a health check reads the store | serves: the promise stated in the thesis | phase: pilot
REQ-020 | functional | T2 | Every error page names what went wrong in plain words. | fail-if: an error page shows a code alone | serves: the promise stated in the thesis | phase: pilot
REQ-021 | functional | T2 | A link created at 23:59 UTC expires thirty days later to the second. | fail-if: expiry drifts by a day at a boundary | serves: the promise stated in the thesis | phase: pilot
REQ-022 | functional | T2 | Targets with spaces are refused with a reason. | fail-if: a target with a space is accepted | serves: the promise stated in the thesis | phase: pilot
REQ-023 | functional | T2 | The API mirrors the page: create, resolve, delete. | fail-if: the API lacks one of the three | serves: the promise stated in the thesis | phase: pilot
REQ-024 | functional | T2 | Nothing is written to the store before the target is validated. | fail-if: a refused target leaves a file behind | serves: the promise stated in the thesis | phase: pilot
NG-001 | non_goal | - | Accounts, sign-in or saved link lists. | serves: scope
NG-002 | non_goal | - | Click analytics of any kind. | serves: scope
```

## Appends
