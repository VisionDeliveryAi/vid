# Provenance: written by TA from the step ticket's ROW-019, REQ-012, D-004 and the answer to the header-and-footer ticket's question 1; holds no product data.
"""ROW-019: the support address in a digest's footer, in each part of the message, as its reader reads that part."""
from harness import (
    ADDRESS,
    SUPPORT_ADDRESS,
    fresh,
    follow_mail_link,
    link_names,
    reach_s01,
    submit_search,
    wait_for_mail,
)

ROW = "ROW-019"
# A test value: no row or requirement sizes a digest. More than a screen of jobs, to reach a long digest's end.
MANY_JOBS = 12


def read_digest(product_url, mail, feed, page, jobs):
    """A digest of `jobs` fresh jobs, by S01's real form and the Confirm link. Gives the digest and the jobs' titles.

    The titles are made after the confirmation is sent, so only a message sent after that can carry one.
    The subscriber's address is a near miss of the support address, for a footer that echoes who it was sent to.
    """
    words, address = fresh("fitter"), f"{fresh('support-')}@jobdigest.example"
    reach_s01(page, product_url, ROW)
    submit_search(page, words, address)
    wanted = lambda message: any("confirm" in name for name in link_names(message["html"]))
    confirmation = wait_for_mail(mail, address, wanted, "a confirmation")
    titles = [feed.add_job(f"Lead {words} {fresh('crew')}")["title"] for _ in range(jobs)]
    follow_mail_link(page, confirmation, "Confirm")
    digest = wait_for_mail(mail, address, lambda message: any(title in message["html"] for title in titles), "a digest")
    return digest, titles


def rendered(page, message):
    """The HTML part as its reader sees it: a hidden element, a comment or a link's target is no words on the page."""
    page.set_content(message["html"])
    return page.locator("body").inner_text()


def footer(text, titles):
    """What follows the last job listed in this part of the message; all of it, if the part lists no job."""
    return text[max((text.rfind(title) + len(title) for title in titles if title in text), default=0) :]


def assert_support_address(text, titles, where):
    named = ADDRESS.findall(footer(text, titles))
    assert SUPPORT_ADDRESS in named, f"{ROW}: {where}: the footer names {named}, not {SUPPORT_ADDRESS}"


# ROW-019 promise: every digest's footer gives a support address that reaches a person; it fails if a digest's footer has no
# ROW-019 promise: support address. Authority REQ-012 and its fail-if's first arm, D-004 (the address in plain words) and the
# ROW-019 promise: the answer to the header-and-footer ticket's question 1 (the address, read by the support team). "Reaches a person", REQ-012's second
# ROW-019 promise: arm, mail to it bouncing, is DIF-003's, deliberately not tested: the mail fake delivers nothing.
# ROW-019 wrong product: the address at the top of the digest and not its foot; only behind a "contact us" link, or hidden; in
# ROW-019 wrong product: the HTML part and not the text part; dropped from a digest of one job or a long one; or the recipient's
# ROW-019 wrong product: address where the support address should stand.
# ROW-019 given: a fresh subscriber, whose address is a near miss of the support address, and fresh jobs made after the
# ROW-019 given: confirmation, so what carries them is the digest and no earlier mail.
# ROW-019 when: the subscriber saves and confirms by the real form and link, and the worker sends the digest.
# ROW-019 then: the support address, as one whole address, is in the words that follow the last job, in the rendered HTML part
# ROW-019 then: and in the text part. Other addresses may stand beside it: the row does not forbid them.
# ROW-019 test values, each a question in the hand-back, as the spec names none: a digest's footer is what follows its last job,
# ROW-019 test values: the design drawing no digest; the text part has a footer too; a long digest is 12 jobs.
# ROW-019 controls: test_ROW_019_control_digest_reached, the same way to a digest, listing its jobs, with no look at the footer.
# ROW-019 technique: one case per digest size and per part, a small property over "every", one exact place, the browser for the
# ROW-019 technique: HTML part as "plain words" is paint. Not seen: a later day's digest, as the product here has no later day.
# cases: ROW-019 target=test_ROW_019_footer_one_job[chromium] control=test_ROW_019_control_digest_reached[chromium]
def test_ROW_019_control_digest_reached(product_url, mail, feed, page):
    digest, titles = read_digest(product_url, mail, feed, page, 2)
    words = rendered(page, digest)
    for title in titles:
        assert title in words, f"{ROW}: control: the digest does not show {title}"


def test_ROW_019_footer_one_job(product_url, mail, feed, page):
    digest, titles = read_digest(product_url, mail, feed, page, 1)
    assert_support_address(rendered(page, digest), titles, "a digest of one job")


def test_ROW_019_footer_many_jobs(product_url, mail, feed, page):
    digest, titles = read_digest(product_url, mail, feed, page, MANY_JOBS)
    assert_support_address(rendered(page, digest), titles, f"a digest of {MANY_JOBS} jobs")


def test_ROW_019_footer_text_part(product_url, mail, feed, page):
    digest, titles = read_digest(product_url, mail, feed, page, 2)
    assert_support_address(digest["text"], titles, "a digest's text part")
