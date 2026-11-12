"""The one module that sends mail (BASELINE: mail sent from nowhere else). D-001: the provider is named at the first deploy."""
import os

import requests

TIMEOUT_SECONDS = 10


def send(to, subject, text, html):
    response = requests.post(
        os.environ["MAIL_URL"].rstrip("/") + "/send",
        json={"to": to, "subject": subject, "text": text, "html": html},
        timeout=TIMEOUT_SECONDS,
    )
    response.raise_for_status()
