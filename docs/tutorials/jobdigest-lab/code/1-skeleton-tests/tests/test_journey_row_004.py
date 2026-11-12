"""ROW-004, the new subscriber: one journey, its cases in the transitions' order, each taking what the last one left.

Each case has its own browser context, so no cookie of the save reaches the confirmation or the digest: no sign-in.
Run the whole file: a case reached without its predecessor fails on its assertion, by name.
"""
import time
from types import SimpleNamespace

import pytest

from harness import NAVIGATION_MS, fresh, fresh_address, link_names, open_s01, submit_search

# More than two of the worker's ticks here (DIGEST_EVERY_SECONDS=2). A window for what must not arrive, not a readiness wait.
QUIET_SECONDS = 5


@pytest.fixture(scope="module")
def journey():
    return SimpleNamespace(
        words=fresh("fitter"),
        address=fresh_address(),
        neighbour=fresh_address(),
        confirmation=None,
        listed=None,
        unlisted=None,
        digest=None,
    )


def reached(value, row, needs):
    if value is None:
        pytest.fail(f"{row}: not reached, it needs {needs}")
    return value


def has_confirm_link(message):
    return any("confirm" in name for name in link_names(message["html"]))


def body(message):
    return message["html"] + message.get("text", "")


def open_message(page, message):
    """The message as its reader sees it, its links the real controls, each opening in this page."""
    page.set_content(message["html"])
    page.evaluate("document.querySelectorAll('a[target]').forEach(link => link.removeAttribute('target'))")


# cases: ROW-004 target=test_ROW_004_T3_open_the_listed_job[chromium] control=test_ROW_003_control_S01_form_reached[chromium]
# ROW-004-T1 promise: saving from S01 reaches S01/saved and sends a confirmation email; authority REQ-001, REQ-005, and
# ROW-004-T1 promise: the row's transition 1.
# ROW-004-T1 wrong product: shows the saved state and sends nothing, or mails the neighbour.
# ROW-004-T1 given: a fresh address with no mail; a neighbour saving the same words first, who is never confirmed.
# ROW-004-T1 when: the real form is submitted. then: the saved state names this search, and exactly one message, with a
# ROW-004-T1 then: Confirm link, reached this address.
# ROW-004-T1 controls: S01's form is reached, the mailbox read empty before the action.
# ROW-004-T1 technique: a fake checked against the record's contract, as the mail provider is external (D-001).
# cases: ROW-004-T1 target=test_ROW_004_T1_save_sends_confirmation[chromium] control=test_ROW_003_control_S01_form_reached[chromium]
def test_ROW_004_T1_save_sends_confirmation(product_url, mail, journey, page):
    open_s01(page, product_url, "ROW-004-T1")
    submit_search(page, journey.words, journey.neighbour)

    assert mail.messages(journey.address) == [], "ROW-004-T1: a fresh address has mail before saving"
    open_s01(page, product_url, "ROW-004-T1")
    submit_search(page, journey.words, journey.address)

    assert page.locator("#saved-search").inner_text().strip() == journey.words, "ROW-004-T1: S01/saved lacks the search"
    assert page.locator("#saved-address").inner_text().strip() == journey.address, "ROW-004-T1: S01/saved lacks the address"
    message = mail.wait_for(journey.address, has_confirm_link)
    assert message is not None, "ROW-004-T1: no message with a Confirm link reached the address"
    assert len(mail.messages(journey.address)) == 1, "ROW-004-T1: more than one message on saving"
    journey.confirmation = message


# ROW-004-T2 promise: the email's Confirm link opens S02/active, showing the saved search as active, with no sign-in;
# ROW-004-T2 promise: authority the row's transition 2 and D-005.
# ROW-004-T2 wrong product: a link that opens a generic page, or the neighbour's search, or asks to sign in.
# ROW-004-T2 given: this address's own confirmation mail, a browser context that never saved anything, and the jobs put
# ROW-004-T2 given: in the feed now, after the save and before the confirmation, so they are new on any reading of "new"
# ROW-004-T2 given: and no digest can have gone out without them.
# ROW-004-T2 when: the Confirm link is clicked in the browser. then: S02/active, this search, this address, Active.
# ROW-004-T2 controls: the one link is found, and the address holds no digest before the click.
# ROW-004-T2 technique: one exact place per value, as the design gives each its id.
# cases: ROW-004-T2 target=test_ROW_004_T2_confirm_opens_active[chromium] control=test_ROW_004_T1_save_sends_confirmation[chromium]
def test_ROW_004_T2_confirm_opens_active(product_url, mail, feed, journey, page):
    reached(journey.confirmation, "ROW-004-T2", "T1's confirmation email")
    journey.listed = [feed.add_job(f"Lead {journey.words} {fresh('crew')}") for _ in range(2)]
    journey.unlisted = feed.add_job(f"Lead {fresh('glazier')}")

    assert len(mail.messages(journey.address)) == 1, "ROW-004-T2: mail arrived before the address was confirmed"
    open_message(page, journey.confirmation)
    confirm = page.get_by_role("link", name="Confirm")
    assert confirm.count() == 1, f"ROW-004-T2: {confirm.count()} Confirm links in the email"
    with page.expect_navigation(timeout=NAVIGATION_MS) as opened:
        confirm.click()

    assert opened.value.status == 200, f"ROW-004-T2: the Confirm link answered {opened.value.status}"
    assert page.locator("#s02-active").count() == 1, "ROW-004-T2: the Confirm link does not open S02/active"
    assert page.locator("#active-search").inner_text().strip() == journey.words, "ROW-004-T2: S02 is not this search"
    assert page.locator("#active-address").inner_text().strip() == journey.address, "ROW-004-T2: S02 is not this address"
    assert page.locator("#active-status").inner_text().strip() == "Active", "ROW-004-T2: the search does not show as active"


# ROW-004-T3 promise: a job listed in the digest opens the job's source page, the job opened being the one listed;
# ROW-004-T3 promise: authority the row's transition 3 and REQ-001's "only new matches".
# ROW-004-T3 wrong product: every listing links to the first job, or the digest lists the whole feed.
# ROW-004-T3 given: two matching jobs and a job that does not match, all fresh; the feed's seed job does not match either.
# ROW-004-T3 when: the second job's link is clicked in the browser. then: the source page's #job reads that job's id and
# ROW-004-T3 then: title; the digest lists both matches and not the other.
# ROW-004-T3 controls: T2 reached active; #job is absent on the digest before the click.
# ROW-004-T3 technique: decoys, as the fault is the right link on the wrong item; the worker runs it, by the row's mark.
# cases: ROW-004-T3 target=test_ROW_004_T3_open_the_listed_job[chromium] control=test_ROW_004_T2_confirm_opens_active[chromium]
def test_ROW_004_T3_open_the_listed_job(product_url, mail, journey, page):
    listed = reached(journey.listed, "ROW-004-T3", "T2's confirmation")
    digest = mail.wait_for(journey.address, lambda message: any(job["title"] in message["html"] for job in listed))
    assert digest is not None, "ROW-004-T3: no digest listing the matching jobs arrived"
    journey.digest = digest
    for job in listed:
        assert job["title"] in digest["html"], f"ROW-004-T3: the digest lacks {job['title']}"
    assert journey.unlisted["title"] not in body(digest), "ROW-004-T3: the digest lists a job that does not match"
    assert "Pipe Fitter" not in body(digest), "ROW-004-T3: the digest lists the feed's seed job"

    open_message(page, digest)
    assert page.locator("#job").count() == 0, "ROW-004-T3: #job is there before opening"
    job = listed[1]
    link = page.get_by_role("link", name=job["title"])
    assert link.count() == 1, f"ROW-004-T3: {link.count()} links for the listed job"
    with page.expect_navigation(timeout=NAVIGATION_MS):
        link.click()

    expected = f"{job['id']}: {job['title']}"
    assert page.locator("#job").inner_text().strip() == expected, "ROW-004-T3: the job opened is not the one listed"


# ROW-004-T3 promise: one digest per search per day; authority REQ-001's and REQ-005's fail-ifs (two digests in one day; a
# ROW-004-T3 promise: re-poll resetting last-sent), and the pending>active of the confirmation that T2 only shows.
# ROW-004-T3 wrong product: a digest on every tick that has something new, or one to every saved search, confirmed or not.
# ROW-004-T3 given: the first digest arrived, a further matching job in the feed, several ticks and re-polls.
# ROW-004-T3 when: the worker ticks. then: this address still holds its two messages, the neighbour only its confirmation.
# ROW-004-T3 controls: the digest itself arrived, so the worker ran with the job in hand.
# ROW-004-T3 technique: the neighbour that must stay untouched; a window, as what is tested is that nothing arrives.
def test_ROW_004_T3_one_digest_and_none_unconfirmed(product_url, mail, feed, journey, page):
    reached(journey.digest, "ROW-004-T3", "the first digest")
    feed.add_job(f"Lead {journey.words} {fresh('crew')}")

    time.sleep(QUIET_SECONDS)

    assert len(mail.messages(journey.address)) == 2, "ROW-004-T3: a second digest for one search in one day"
    assert len(mail.messages(journey.neighbour)) == 1, "ROW-004-T3: a digest reached an unconfirmed address"


# ROW-004-T3 promise: every digest carries a one-click unsubscribe needing no sign-in; authority REQ-002's second arm.
# ROW-004-T3 wrong product: no link, or a link to a sign-in page.
# ROW-004-T3 given: the digest, in a browser context with no session. when: the link is clicked. then: it answers, with
# ROW-004-T3 then: no password to give. Whether digests then stop cannot be seen here: one a day sends no second one.
# ROW-004-T3 controls: the digest arrived. technique: a real click, last, as it ends the subscription.
def test_ROW_004_T3_unsubscribe_needs_no_sign_in(product_url, journey, page):
    open_message(page, reached(journey.digest, "ROW-004-T3", "the first digest"))
    link = page.get_by_role("link", name="unsubscribe")
    assert link.count() == 1, f"ROW-004-T3: {link.count()} unsubscribe links in the digest"
    with page.expect_navigation(timeout=NAVIGATION_MS) as opened:
        link.click()

    assert opened.value.status == 200, f"ROW-004-T3: the unsubscribe link answered {opened.value.status}"
    assert page.locator("input[type=password]").count() == 0, "ROW-004-T3: the unsubscribe link asks for a sign-in"
