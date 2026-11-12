# Provenance: written by TA from the dev setup record's test author contract; holds no product data.
"""The shared fixtures: the product's address and the two fakes, each a `setup:` error when the run lacks it."""
import pytest

from harness import FeedFake, MailFake, env


@pytest.fixture
def product_url():
    return env("PRODUCT_URL").rstrip("/")


@pytest.fixture
def mail():
    return MailFake(env("MAIL_URL").rstrip("/"))


@pytest.fixture
def feed():
    return FeedFake(env("FEED_URL").rstrip("/"))
