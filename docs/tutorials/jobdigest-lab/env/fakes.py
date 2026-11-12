#!/usr/bin/env python3
# The outside services' fakes, standard library only, state in memory so it dies with the run.
#   fakes.py mail <port>    POST /send records a message; GET /messages[?to=<address>] reads them
#   fakes.py feed <port>    GET /feed.json lists jobs; POST /jobs adds one; POST /jobs/batch adds a list in one step;
#   fakes.py feed2 <port>   GET /jobs/<id> is its source page; GET /requests lists what was asked of /feed.json;
#                           POST /outage {"down": true|false} makes /feed.json answer 503, still recorded. feed2 starts empty
#   fakes.py clock <port>   GET /now is the real time plus the offset; POST /advance {"days": n} adds to the offset
#   fakes.py backup <port>  POST /backups records a backup's size, its body being the backup; GET /backups lists them
import json
import sys
import threading
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

ROLE, PORT = sys.argv[1], int(sys.argv[2])
IS_FEED = ROLE in ("feed", "feed2")
LOCK = threading.Lock()
MESSAGES = []
REQUESTS = []
BACKUPS = []
DOWN = False
OFFSET_DAYS = 0
JOBS = []
if ROLE == "feed":
    # The seed job. Must not change: tests may rely on this one job being listed.
    JOBS.append({"id": "job-1", "title": "Pipe Fitter", "company": "Acme Mechanical", "location": "Leeds",
                 "url": f"http://feed:{PORT}/jobs/job-1", "posted_at": "2026-11-04T00:00:00Z"})


def stamp(moment=None):
    return (moment or datetime.now(timezone.utc)).strftime("%Y-%m-%dT%H:%M:%SZ")


def clock_now():
    return {"now": stamp(datetime.now(timezone.utc) + timedelta(days=OFFSET_DAYS))}


def add_job(job):
    job["id"] = job.get("id", f"job-{len(JOBS) + 1}")
    job.setdefault("url", f"http://{ROLE}:{PORT}/jobs/{job['id']}")
    job.setdefault("posted_at", stamp())
    JOBS.append(job)
    return job


class Fake(BaseHTTPRequestHandler):
    def reply(self, status, body, kind="application/json"):
        data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def read_body(self):
        return self.rfile.read(int(self.headers.get("Content-Length", 0)))

    def read_json(self):
        return json.loads(self.read_body() or b"{}")

    def do_GET(self):
        url = urlsplit(self.path)
        if url.path == "/healthz":
            return self.reply(200, {"ok": True})
        if IS_FEED and url.path == "/feed.json":
            # replied to outside the lock: at 10,000 jobs a slow reader must not hold up the fake's other doors
            with LOCK:
                REQUESTS.append({"path": self.path, "headers": dict(self.headers)})
                jobs, down = list(JOBS), DOWN
            return self.reply(503, {"error": "feed down"}) if down else self.reply(200, jobs)
        with LOCK:
            if ROLE == "mail" and url.path == "/messages":
                to = parse_qs(url.query).get("to", [None])[0]
                return self.reply(200, [m for m in MESSAGES if to in (None, m.get("to"))])
            if IS_FEED and url.path == "/requests":
                return self.reply(200, REQUESTS)
            if IS_FEED and url.path.startswith("/jobs/"):
                for job in JOBS:
                    if job["id"] == url.path.removeprefix("/jobs/"):
                        return self.reply(200, f"<!doctype html><title>{job['title']}</title><h1 id='job'>{job['id']}: "
                                               f"{job['title']}</h1>", "text/html")
            if ROLE == "clock" and url.path == "/now":
                return self.reply(200, clock_now())
            if ROLE == "backup" and url.path == "/backups":
                return self.reply(200, BACKUPS)
        self.reply(404, {"error": "no such path"})

    def do_POST(self):
        global DOWN, OFFSET_DAYS
        if ROLE == "mail" and self.path == "/send":
            message = self.read_json()
            with LOCK:
                MESSAGES.append(message)
            return self.reply(202, {"recorded": True})
        if IS_FEED and self.path == "/jobs":
            job = self.read_json()
            with LOCK:
                job = add_job(job)
            return self.reply(201, job)
        if IS_FEED and self.path == "/jobs/batch":
            jobs = self.read_json()
            with LOCK:
                jobs = [add_job(job) for job in jobs]
            return self.reply(201, jobs)
        if IS_FEED and self.path == "/outage":
            body = self.read_json()
            with LOCK:
                DOWN = body["down"]
            return self.reply(200, {"down": body["down"]})
        if ROLE == "clock" and self.path == "/advance":
            days = self.read_json()["days"]
            if days <= 0:
                return self.reply(400, {"error": "the clock only moves forward"})
            with LOCK:
                OFFSET_DAYS += days
                return self.reply(200, clock_now())
        if ROLE == "backup" and self.path == "/backups":
            backup = {"at": stamp(), "bytes": len(self.read_body())}
            with LOCK:
                BACKUPS.append(backup)
            return self.reply(201, backup)
        self.reply(404, {"error": "no such path"})

    def log_message(self, form, *args):
        if self.path != "/healthz":
            print(f"{self.log_date_time_string()} {ROLE} {form % args}", flush=True)


ThreadingHTTPServer(("0.0.0.0", PORT), Fake).serve_forever()
