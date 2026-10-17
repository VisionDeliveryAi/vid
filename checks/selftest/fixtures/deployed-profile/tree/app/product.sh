#!/bin/sh
# Purpose: the toy product — takes a feed item at its inbound boundary (/inbox).
# Inline (TOY_INLINE=1) it indexes the item itself; in the deployed shape it
# routes the item to the transport, where the worker process consumes it.
mkdir -p /inbox /transport /db; touch /db/product-up
while true; do
  for f in /inbox/*.item; do
    [ -f "$f" ] || continue; b=$(basename "$f" .item)
    if [ "${TOY_INLINE:-1}" = 1 ]; then echo indexed > "/db/$b.indexed"; rm -f "$f"; else mv "$f" "/transport/$b.item"; fi
  done
  sleep 0.3
done
