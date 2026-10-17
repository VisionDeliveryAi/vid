#!/bin/sh
# Purpose: the toy worker process — consumes routed items from the transport and indexes them.
mkdir -p /transport /db
while true; do
  for f in /transport/*.item; do [ -f "$f" ] || continue; b=$(basename "$f" .item); echo indexed > "/db/$b.indexed"; rm -f "$f"; done
  sleep 0.3
done
