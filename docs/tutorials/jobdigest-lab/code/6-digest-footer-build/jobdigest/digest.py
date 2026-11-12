"""The morning digest: the saved searches it owns, their confirmation and exit, and the digest run."""
import html
import logging
import os
import re
import secrets
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from urllib.parse import urlsplit

import requests

from jobdigest import mail

log = logging.getLogger(__name__)

FEED_TIMEOUT_SECONDS = 10
BUSY_TIMEOUT_SECONDS = 30
ADDRESS = re.compile(r"[^@\s]+@[^@\s]+\.[^@\s]+")
ADDRESS_MAX = 254
WORDS_MAX = 200
SUPPORT_ADDRESS = "support@jobdigest.example"

# REQ-005: a saved search keeps its words, its owning address (by its subscription) and its last digest's time.
# RULE-003 and REQ-005's fail-if land here as triggers, and address identity as a CHECK: stored lower-cased.
SCHEMA = """
CREATE TABLE IF NOT EXISTS subscriptions (
    id INTEGER PRIMARY KEY,
    address TEXT NOT NULL UNIQUE CHECK (address = lower(address)),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'unsubscribed')),
    unsubscribe_token TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS saved_searches (
    id INTEGER PRIMARY KEY,
    subscription_id INTEGER NOT NULL REFERENCES subscriptions (id),
    words TEXT NOT NULL CHECK (words <> ''),
    confirm_token TEXT NOT NULL UNIQUE,
    confirmed_at TEXT,
    last_digest_at TEXT,
    UNIQUE (subscription_id, words)
);
CREATE TABLE IF NOT EXISTS delivered_jobs (
    search_id INTEGER NOT NULL REFERENCES saved_searches (id),
    job_id TEXT NOT NULL,
    PRIMARY KEY (search_id, job_id)
);
CREATE TRIGGER IF NOT EXISTS subscription_status_moves BEFORE UPDATE OF status ON subscriptions
WHEN NOT (
    (OLD.status = 'pending' AND NEW.status = 'active')
    OR (OLD.status = 'active' AND NEW.status = 'unsubscribed')
)
BEGIN
    SELECT RAISE(ABORT, 'subscription.status: pending>active active>unsubscribed');
END;
CREATE TRIGGER IF NOT EXISTS last_digest_moves_forward BEFORE UPDATE OF last_digest_at ON saved_searches
WHEN OLD.last_digest_at IS NOT NULL AND (NEW.last_digest_at IS NULL OR NEW.last_digest_at < OLD.last_digest_at)
BEGIN
    SELECT RAISE(ABORT, 'last_digest_at never resets or moves backward');
END;
"""


@contextmanager
def store():
    connection = sqlite3.connect(os.environ["DATABASE_PATH"], timeout=BUSY_TIMEOUT_SECONDS)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    try:
        with connection:
            yield connection
    finally:
        connection.close()


def init_store():
    with store() as db:
        db.executescript(SCHEMA)


def link(path):
    return os.environ["BASE_URL"].rstrip("/") + path


def terms(text):
    return set(re.findall(r"\w+", text.casefold()))


def clean(words, address):
    """The stored forms, or ValueError. RULE-004: the words must hold a term to match on, the address must be mailable."""
    words = " ".join(words.split())
    address = address.strip().lower()
    if not terms(words) or len(words) > WORDS_MAX:
        raise ValueError("search words")
    if len(address) > ADDRESS_MAX or not ADDRESS.fullmatch(address):
        raise ValueError("email address")
    return words, address


def send_confirmation(address, words, token):
    url = link(f"/confirm/{token}")
    mail.send(
        address,
        f"Confirm your JobDigest search: {words}",
        f"Confirm your search for {words}: {url}",
        f'<p>Your search: {html.escape(words)}</p><p><a href="{html.escape(url)}">Confirm</a></p>',
    )


def save_search(words, address):
    """REQ-001, REQ-005: stores the search and mails its Confirm link; saving again mails the same link.

    Returns the stored forms. An unsubscribed address gets no mail and no search: RULE-003 has no way back from there.
    """
    words, address = clean(words, address)
    with store() as db:
        db.execute(
            "INSERT INTO subscriptions (address, unsubscribe_token) VALUES (?, ?) ON CONFLICT (address) DO NOTHING",
            (address, secrets.token_urlsafe(32)),
        )
        subscription = db.execute("SELECT id, status FROM subscriptions WHERE address = ?", (address,)).fetchone()
        if subscription["status"] == "unsubscribed":
            return words, address
        db.execute(
            "INSERT INTO saved_searches (subscription_id, words, confirm_token) VALUES (?, ?, ?)"
            " ON CONFLICT (subscription_id, words) DO NOTHING",
            (subscription["id"], words, secrets.token_urlsafe(32)),
        )
        token = db.execute(
            "SELECT confirm_token FROM saved_searches WHERE subscription_id = ? AND words = ?",
            (subscription["id"], words),
        ).fetchone()["confirm_token"]
    send_confirmation(address, words, token)
    return words, address


def confirm(token):
    """D-005: confirms with no sign-in. The search, or None for an unknown token; its status says if it was honoured."""
    with store() as db:
        found = db.execute(
            "SELECT saved_searches.id, words, address, status, subscription_id FROM saved_searches"
            " JOIN subscriptions ON subscriptions.id = subscription_id WHERE confirm_token = ?",
            (token,),
        ).fetchone()
        if found is None or found["status"] == "unsubscribed":
            return found
        db.execute(
            "UPDATE saved_searches SET confirmed_at = ? WHERE id = ? AND confirmed_at IS NULL",
            (now().isoformat(), found["id"]),
        )
        # RULE-003: pending>active, one of the two writes of subscription.status
        db.execute("UPDATE subscriptions SET status = 'active' WHERE id = ? AND status = 'pending'", (found["subscription_id"],))
    return found


def unsubscribe(token):
    """REQ-002: one click, no sign-in, stops every digest for the address. False for an unknown token."""
    with store() as db:
        found = db.execute("SELECT id FROM subscriptions WHERE unsubscribe_token = ?", (token,)).fetchone()
        if found is None:
            return False
        # RULE-003: active>unsubscribed, the other write of subscription.status
        db.execute("UPDATE subscriptions SET status = 'unsubscribed' WHERE id = ? AND status = 'active'", (found["id"],))
    return True


def now():
    return datetime.now(timezone.utc)


def read_feed():
    """D-006: S01 reads the one partner feed itself. It sends no address (INV-002). The feed is not trusted: an entry

    without a text id and title, or a web address to hand off to (NG-001), is left out.
    """
    response = requests.get(os.environ["FEED_URL"], timeout=FEED_TIMEOUT_SECONDS)
    response.raise_for_status()
    entries = response.json()
    jobs = {}
    for job in entries if isinstance(entries, list) else []:
        if not isinstance(job, dict) or not all(isinstance(job.get(key), str) for key in ("id", "title", "url")):
            continue
        if urlsplit(job["url"]).scheme in ("http", "https"):
            jobs[job["id"]] = job
    return list(jobs.values())


def due_searches(db, today):
    """REQ-001: confirmed searches of active addresses that have had no digest this UTC day."""
    return db.execute(
        "SELECT saved_searches.id, words, address, unsubscribe_token FROM saved_searches"
        " JOIN subscriptions ON subscriptions.id = subscription_id"
        " WHERE status = 'active' AND confirmed_at IS NOT NULL"
        " AND (last_digest_at IS NULL OR substr(last_digest_at, 1, 10) < ?)",
        (today,),
    ).fetchall()


def new_matches(db, search, jobs):
    """REQ-001: the jobs holding every search term in their title, less those already delivered for this search."""
    wanted = terms(search["words"])
    delivered = {row["job_id"] for row in db.execute("SELECT job_id FROM delivered_jobs WHERE search_id = ?", (search["id"],))}
    return [job for job in jobs if job["id"] not in delivered and wanted <= terms(job["title"])]


def send_digest(search, jobs):
    """REQ-002: every digest carries the one-click unsubscribe (RULE-002); NG-001: each job links to its source page.

    REQ-012, RULE-001, D-004: both parts' footers name the support address in plain words.
    """
    url = link(f"/unsubscribe/{search['unsubscribe_token']}")
    rows = "".join(f'<li><a href="{html.escape(job["url"])}">{html.escape(job["title"])}</a></li>' for job in jobs)
    mail.send(
        search["address"],
        f"JobDigest: {search['words']}",
        "\n".join(f"{job['title']}: {job['url']}" for job in jobs) + f"\n\nUnsubscribe: {url}\nSupport: {SUPPORT_ADDRESS}",
        f'<p>New for {html.escape(search["words"])}:</p><ul>{rows}</ul><p><a href="{html.escape(url)}">Unsubscribe</a></p>'
        f"<p>Support: {SUPPORT_ADDRESS}</p>",
    )


def run():
    """The digest run. REQ-001: one digest per search per UTC day, of new matches, none when there are none. REQ-005: a

    feed outage ends the run before it touches a search. A send that fails leaves its search due for the next run.
    """
    started = now()
    with store() as db:
        searches = due_searches(db, started.date().isoformat())
    if not searches:
        return
    try:
        jobs = read_feed()
    except (requests.RequestException, ValueError) as error:
        log.warning("digest run: the feed did not answer: %s", error)
        return
    for search in searches:
        with store() as db:
            matches = new_matches(db, search, jobs)
        if not matches:
            continue
        try:
            send_digest(search, matches)
        except requests.RequestException as error:
            log.warning("digest run: search %s not sent: %s", search["id"], error)
            continue
        with store() as db:
            db.executemany(
                "INSERT OR IGNORE INTO delivered_jobs (search_id, job_id) VALUES (?, ?)",
                [(search["id"], job["id"]) for job in matches],
            )
            db.execute("UPDATE saved_searches SET last_digest_at = ? WHERE id = ?", (started.isoformat(), search["id"]))
