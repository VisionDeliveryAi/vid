#!/bin/sh
# Starts every line of the product's Procfile in one container. The checkout is mounted read-only at /app.
set -eu
cd /app
[ -f Procfile ] || { echo "setup: the checkout has no Procfile, so there is no product to start"; exit 1; }
if [ -f requirements.txt ]; then
  pip install --no-index --root-user-action=ignore -q -r requirements.txt \
    || { echo "setup: requirements.txt names a package the product image does not hold"; exit 1; }
fi
exec honcho start -f Procfile
