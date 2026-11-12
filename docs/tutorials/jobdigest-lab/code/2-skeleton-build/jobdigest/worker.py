"""The worker line of the Procfile. RULE-005: the morning digest run is taken up here."""
import logging
import os
import time

from jobdigest import digest

MORNING_HOUR_UTC = 7
# Often enough that a restart inside the morning hour still runs; the digest's own one-a-day check stops a repeat.
MORNING_TICK_SECONDS = 600

log = logging.getLogger(__name__)


def is_due(every_seconds):
    return every_seconds is not None or digest.now().hour == MORNING_HOUR_UTC


def main():
    logging.basicConfig(level=logging.INFO)
    every = os.environ.get("DIGEST_EVERY_SECONDS")
    every = int(every) if every else None
    digest.init_store()
    while True:
        if is_due(every):
            try:
                digest.run()
            except Exception:
                # a worker that ended would take the web process down with it (the Procfile's one container)
                log.exception("digest run failed")
        time.sleep(every or MORNING_TICK_SECONDS)


if __name__ == "__main__":
    main()
