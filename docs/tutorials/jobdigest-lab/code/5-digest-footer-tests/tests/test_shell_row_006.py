# | row | marker | state | actor | route |
# |---|---|---|---|---|
# | ROW-006 | shell | n/a | anonymous | every page the cases below reach, each by the way a person reaches it |
#
# Provenance: written by TA from the step ticket's ROW-006, REQ-012, D-004 and the test values of its two questions. The design draws no shell, so no literal set is read from it.
import re

from harness import (
    ADDRESS,
    NAVIGATION_MS,
    SUPPORT_ADDRESS,
    fresh,
    fresh_address,
    follow_mail_link,
    link_names,
    reach_s01,
    submit_search,
    wait_for_mail,
)
from measure import SHELL

ROW = "ROW-006"
PRODUCT_NAME = "JobDigest"
HELP_ROUTE = "/help/unsubscribe"
HELP_LINK = re.compile(r"unsubscrib.*help|help.*unsubscrib", re.IGNORECASE)
OUTSIDE_THE_SHELL = """shell => {
  const copy = document.body.cloneNode(true);
  copy.querySelectorAll(shell).forEach(frame => frame.remove());
  return copy.textContent;
}"""


def standing_on(page, marker):
    if page.locator(f"#{marker}").count() != 1:
        raise RuntimeError(f"setup: the way to this page did not reach #{marker}")


def save_a_search(page, product_url, mail, words, address):
    """S01's real form, and the confirmation it mails."""
    reach_s01(page, product_url, ROW)
    submit_search(page, words, address)
    wanted = lambda message: any("confirm" in name for name in link_names(message["html"]))
    return wait_for_mail(mail, address, wanted, "a confirmation")


def assert_frame(page, product_url, where):
    """The header and footer on this page; gives the help link, and the frame's words to hold another page against."""
    header = page.get_by_role("banner")
    assert header.count() == 1, f"{ROW}: {where}: {header.count()} headers"
    assert re.search(rf"\b{PRODUCT_NAME}\b", header.inner_text()), f"{ROW}: {where}: the header lacks the product's name"

    footer = page.get_by_role("contentinfo")
    assert footer.count() == 1, f"{ROW}: {where}: {footer.count()} footers"
    addresses = set(ADDRESS.findall(footer.inner_text()))
    assert addresses == {SUPPORT_ADDRESS}, f"{ROW}: {where}: the footer names {sorted(addresses)}, not {SUPPORT_ADDRESS}"

    help_link = footer.get_by_role("link", name=HELP_LINK)
    assert help_link.count() == 1, f"{ROW}: {where}: {help_link.count()} unsubscribe help links in the footer"
    target = help_link.evaluate("link => link.href")
    assert target == product_url + HELP_ROUTE, f"{ROW}: {where}: the unsubscribe help link goes to {target}"
    return help_link, (header.inner_text(), footer.inner_text())


def assert_help_words(page, where):
    """Words on how to unsubscribe, outside the frame: the test value is that they name unsubscribing and the link it takes."""
    words = page.evaluate(OUTSIDE_THE_SHELL, SHELL).lower()
    assert "unsubscrib" in words and "link" in words, f"{ROW}: {where}: that page does not say how to unsubscribe"


def assert_shell(page, product_url, where):
    """The frame on this page, then its help link really opens, from this page's own address, the help page in the same frame."""
    help_link, frame = assert_frame(page, product_url, where)
    with page.expect_navigation(timeout=NAVIGATION_MS) as opened:
        help_link.click()

    assert opened.value.status == 200, f"{ROW}: {where}: the unsubscribe help link answered {opened.value.status}"
    assert page.url == product_url + HELP_ROUTE, f"{ROW}: {where}: the unsubscribe help link ended at {page.url}"
    assert_help_words(page, where)
    _, help_frame = assert_frame(page, product_url, f"the help page, from {where}")
    assert help_frame == frame, f"{ROW}: {where}: the help page's frame reads {help_frame}, this page's {frame}"


# ROW-006 promise: every page shows the header with the product's name, and the footer with the support address and the
# ROW-006 promise: unsubscribe help link; authority REQ-012 and its fail-if's first arm, read on the pages as the row reads it,
# ROW-006 promise: D-004, the address in plain words, and the ticket's two questions: the address is support@jobdigest.example, and the
# ROW-006 promise: link opens the product's own page at /help/unsubscribe, with the same header and footer and a few plain words
# ROW-006 promise: on how to unsubscribe. REQ-012's second arm, mail to it bouncing, is DIF-003's, not tested.
# ROW-006 wrong product: the shell in the two drawn screens' templates and not on the unsubscribe answer, a not-found page or the
# ROW-006 wrong product: help page; a footer with another address, or the subscriber's beside the right one; a help link written
# ROW-006 wrong product: relative, dead from a deep address; a help page that is a bare title with nothing on how.
# ROW-006 given: a fresh subscriber on each page that shows one, whose address must not stand beside the support address.
# ROW-006 when: each page is reached as a person reaches it, by form, mail link or typed address.
# ROW-006 then: one header with the name, one footer with the support address and no other, and one help link that opens
# ROW-006 then: /help/unsubscribe, 200, in the same frame word for word, with words on how to unsubscribe outside it.
# ROW-006 test values, each a question in the hand-back, as the spec names none: the header and footer are the page's banner
# ROW-006 test values: and contentinfo landmarks; "every page" holds the not-found page; the link's name has unsubscribe and
# ROW-006 test values: help; words on how to unsubscribe hold "unsubscrib" and "link".
# ROW-006 controls: ROW-003's S01 form control, and each case's way to its page, which errors `setup:` if it is not reached.
# ROW-006 technique: one case per page, as "every" is the promise and the export has no route table; a page not listed here
# ROW-006 technique: is not seen, the 503 answer among them, which has no door. The browser, as this is paint and operation.
# cases: ROW-006 target=test_ROW_006_S01_default[chromium] control=test_ROW_003_control_S01_form_reached[chromium]
def test_ROW_006_S01_default(product_url, page):
    reach_s01(page, product_url, ROW)
    assert_shell(page, product_url, "S01/default")


def test_ROW_006_S01_saved(product_url, page):
    words, address = fresh("electrician"), fresh_address()
    reach_s01(page, product_url, ROW)
    submit_search(page, words, address)
    standing_on(page, "s01-saved")
    assert_shell(page, product_url, "S01/saved")


def test_ROW_006_S02_active(product_url, mail, page):
    words, address = fresh("fitter"), fresh_address()
    confirmation = save_a_search(page, product_url, mail, words, address)
    follow_mail_link(page, confirmation, "Confirm")
    standing_on(page, "s02-active")
    assert_shell(page, product_url, "S02/active")


def test_ROW_006_unsubscribed(product_url, mail, feed, page):
    words, address = fresh("fitter"), fresh_address()
    confirmation = save_a_search(page, product_url, mail, words, address)
    job = feed.add_job(f"Lead {words} {fresh('crew')}")
    follow_mail_link(page, confirmation, "Confirm")
    digest = wait_for_mail(mail, address, lambda message: job["title"] in message["html"], "a digest")
    follow_mail_link(page, digest, "unsubscribe")
    assert_shell(page, product_url, "the unsubscribe answer")


def test_ROW_006_not_found(product_url, page):
    page.goto(f"{product_url}/{fresh('no-such-page')}")
    assert_shell(page, product_url, "the not-found page")


def test_ROW_006_help_page(product_url, page):
    response = page.goto(product_url + HELP_ROUTE)
    assert response.status == 200, f"{ROW}: {HELP_ROUTE} answered {response.status}"
    assert_help_words(page, HELP_ROUTE)
    assert_frame(page, product_url, HELP_ROUTE)
