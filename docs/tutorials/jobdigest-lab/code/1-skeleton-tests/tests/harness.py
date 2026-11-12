# Provenance: written by TA from the dev setup record's test author contract; holds no product data.
"""The public test helpers: fresh values, the fakes' doors, and S01's form, which two rows' tests both operate."""
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from html.parser import HTMLParser

# The ticket names no route. S01 is the product's first screen, so it is taken to stand at the root: this is the one place.
S01_ROUTE = "/"
NAVIGATION_MS = 10_000
MAIL_DEADLINE_SECONDS = 30


def env(name):
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"setup: {name} is empty, this run has no such service")
    return value


def fresh(word):
    return f"{word}{uuid.uuid4().hex[:12]}"


def fresh_address():
    return f"{fresh('ta-')}@example.com"


def _json(request):
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.load(response)
    except urllib.error.URLError as error:
        raise RuntimeError(f"setup: {request.full_url} did not answer: {error}") from error


class MailFake:
    def __init__(self, url):
        self.url = url

    def messages(self, address):
        return _json(urllib.request.Request(f"{self.url}/messages?to={urllib.parse.quote(address)}"))

    def wait_for(self, address, wanted):
        """The first message to the address that `wanted` accepts, or None at the deadline."""
        deadline = time.monotonic() + MAIL_DEADLINE_SECONDS
        while True:
            found = [message for message in self.messages(address) if wanted(message)]
            if found:
                return found[0]
            if time.monotonic() > deadline:
                return None
            time.sleep(0.2)


class FeedFake:
    def __init__(self, url):
        self.url = url

    def add_job(self, title):
        body = json.dumps({"title": title, "company": fresh("company-"), "location": fresh("town-")}).encode()
        return _json(
            urllib.request.Request(
                f"{self.url}/jobs", data=body, headers={"Content-Type": "application/json"}, method="POST"
            )
        )


class _Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.names = []
        self._open = False

    def handle_starttag(self, tag, attrs):
        if tag == "a" and dict(attrs).get("href"):
            self.names.append("")
            self._open = True

    def handle_endtag(self, tag):
        if tag == "a":
            self._open = False

    def handle_data(self, data):
        if self._open:
            self.names[-1] += data


def link_names(html):
    """The text of each link of a message, lower-cased."""
    parser = _Links()
    parser.feed(html)
    return [name.strip().lower() for name in parser.names]


def open_s01(page, product_url, row):
    """S01's default state, its form's elements present, or the row's assertion fails."""
    response = page.goto(product_url + S01_ROUTE)
    assert response.status == 200, f"{row}: S01 at {S01_ROUTE} answered {response.status}"
    for element in ("search-words", "email", "save-search"):
        assert page.locator(f"#{element}").count() == 1, f"{row}: S01 lacks #{element}"


def submit_search(page, words, address):
    page.fill("#search-words", words)
    page.fill("#email", address)
    with page.expect_navigation(timeout=NAVIGATION_MS):
        page.click("#save-search")
