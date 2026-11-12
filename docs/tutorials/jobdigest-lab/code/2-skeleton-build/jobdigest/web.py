"""The pages: S01, S02 and the unsubscribe answer."""
import logging

import requests
from flask import Flask, abort, render_template, request

from jobdigest import digest

log = logging.getLogger(__name__)

app = Flask(__name__)
digest.init_store()


@app.route("/", methods=["GET", "POST"])
def save_a_search():
    if request.method == "GET":
        return render_template("s01_default.html")
    try:
        # REQ-001, D-003: the saved state replaces the form, on the post's own answer
        words, address = digest.save_search(request.form.get("words", ""), request.form.get("email", ""))
    except ValueError:
        return render_template("s01_default.html"), 400
    except requests.RequestException as error:
        log.warning("the confirmation was not sent: %s", error)
        abort(503)
    return render_template("s01_saved.html", words=words, address=address)


@app.route("/confirm/<token>")
def confirm(token):
    found = digest.confirm(token)
    if found is None:
        abort(404)
    if found["status"] == "unsubscribed":
        return render_template("unsubscribed.html")
    return render_template("s02_active.html", words=found["words"], address=found["address"])


@app.route("/unsubscribe/<token>")
def unsubscribe(token):
    if not digest.unsubscribe(token):
        abort(404)
    return render_template("unsubscribed.html")
