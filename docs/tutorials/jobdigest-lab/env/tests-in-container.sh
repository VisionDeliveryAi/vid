#!/bin/sh
# Runs the checkout's tests in one browser and writes /out/cases-<browser>.xml.
set -u
cd /checkout
set -- -p no:cacheprovider -o junit_logging=system-out --junitxml=/tmp/raw.xml \
  --browser "$ENGINE" --timeout "$CASE_LIMIT" -q tests
if [ -n "$SELECTION" ]; then set -- "$@" -k "$SELECTION"; fi
python -m pytest "$@"
status=$?
if [ -f /tmp/raw.xml ]; then
  python /env/finish_report.py /tmp/raw.xml "/out/cases-$ENGINE.xml"
else
  echo "setup: pytest wrote no report (exit $status)"
  exit 2
fi
exit $status
