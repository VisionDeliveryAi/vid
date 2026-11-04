#!/bin/sh
# Purpose: selftest case — a ticket on GitHub, in parts (v0.26.10.9 spec R20; §5 ticket-parts). A ticket brief over
# 60,000 characters (the brief writer's toy, its test file grown past 130,000): `ticket.sh body` gives parts within the
# limit, each opening with its vid-ticket header (part 1 with rows: and run:); `fetch` rebuilds the brief byte for byte
# from the parts saved as an issue body and its comments (with CRLF line ends and an unrelated comment among them); a
# missing part, a doubled part, a wrong hash= and a changed written: stamp are each refused; after a rewrite (a new
# body and new comment parts beside the old ones) the new writing is joined and the old parts named as skipped.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ticket-parts: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/vid"; bw_builder; cp "$CHECKS/ticket.sh" checks/
awk 'BEGIN { for (i = 1; i <= 2600; i++) printf "# filler line %04d: the toy ledger keeps its long comment to grow the ticket past one part\n", i }' >> tests/invariants/links.sh
g add -A && g commit -qm 'a long test file and the ticket reader'
tk_ticket_mode; tk_code
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 --ticket || { cat "$T/wout" >&2; fail 'write --ticket was refused'; }
B=$(bw_out); [ "$(wc -c < "$B")" -gt 120000 ] || fail "the brief is only $(wc -c < "$B") bytes"
sh checks/ticket.sh body "$B" --issue 15 --out "$T/parts" > "$T/out" 2>&1 || fail 'body failed'
NP=$(grep -c . "$T/out"); [ "$NP" -ge 3 ] || fail "$NP parts for a brief of $(wc -c < "$B") bytes"
for p in "$T"/parts/part-*.md; do
  [ "$(wc -c < "$p")" -le 60000 ] || fail "$p is over 60,000 bytes"
  head -n 1 "$p" | grep -qx '```vid-ticket' || fail "$p does not open with its header"
  sed -n 2p "$p" | grep -q "^issue=15 step=S1 stage=1 kind=feature part=[0-9]*/$NP hash=[0-9a-f]* base=[0-9a-f]* branch=vid/15$" || fail "$p's header line is wrong: $(sed -n 2p "$p")"
done
sed -n 3,4p "$T/parts/part-1.md" | grep -q '^rows: ROW-101 ROW-102$' && sed -n 4p "$T/parts/part-1.md" | grep -q '^run: tests/invariants$' || fail 'part 1 lacks rows: or run:'
sed -n 3p "$T/parts/part-2.md" | grep -qx '```' || fail 'a later part carries rows: or run:'
save() { rm -rf "$T/raw"; mkdir -p "$T/raw"; k=0; for p in "$T"/parts/part-*.md; do k=$((k + 1)); [ "$k" = 1 ] && n=body.md || n=comment-$k.md; sed 's/$/\r/' "$p" > "$T/raw/$n"; done
  printf 'vid: return block incomplete — rows: ROW-101\n' > "$T/raw/comment-0.md"; }
save; sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1 || fail 'fetch refused the whole set'
cmp -s "$B" "$T/raw/ticket.md" || fail 'fetch did not rebuild the brief byte for byte'
save; rm -f "$T/raw/comment-2.md"; if sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1; then fail 'a missing part was accepted'; fi; grep -q 'part 2 of .* is missing' "$T/out" || fail 'the missing part is not named'
save; cp "$T/raw/comment-2.md" "$T/raw/comment-9.md"; if sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1; then fail 'a doubled part was accepted'; fi; grep -q 'appears twice' "$T/out" || fail 'the doubled part is not named'
save; sed 's/ hash=[0-9a-f]* / hash=0000000000000000000000000000000000000000 /' "$T/raw/comment-2.md" > "$T/x" && mv "$T/x" "$T/raw/comment-2.md"
if sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1; then fail 'a wrong hash= was accepted'; fi; grep -q 'part 2 of .* is missing (skipped as an earlier writing.*comment-2.md' "$T/out" || fail 'the part with a wrong hash= is not named'
save; mv "$T/raw/body.md" "$T/raw/part-1.md"; sed 's/ hash=[0-9a-f]* / hash=0000000000000000000000000000000000000000 /' "$T/raw/comment-3.md" > "$T/x" && mv "$T/x" "$T/raw/comment-3.md"
if sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1; then fail 'a wrong hash= among parts with no body was accepted'; fi; grep -q 'disagree on hash=' "$T/out" || fail 'the differing hash= is not named'
# a rewrite: a new body and new comment parts after the old ones — the new writing is joined, the old parts skipped
save; for p in "$T"/raw/comment-*.md; do mv "$p" "$T/raw/old-${p##*/}"; done
printf 'the run manager: a rewrite\n' > "$T/notes"
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 --ticket --notes "$T/notes" || fail 'the rewrite was refused'
B2=$(bw_out); sh checks/ticket.sh body "$B2" --issue 15 --out "$T/parts2" > "$T/out" 2>&1 || fail 'body of the rewrite failed'
k=0; for p in "$T"/parts2/part-*.md; do k=$((k + 1)); [ "$k" = 1 ] && n=body.md || n=comment-new-$k.md; cp "$p" "$T/raw/$n"; done
sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1 || fail 'fetch refused a rewritten ticket'
cmp -s "$B2" "$T/raw/ticket.md" || fail 'fetch did not join the rewrite'
grep -q 'skipped as an earlier writing: .*old-comment-2.md' "$T/out" || fail "the earlier writing's parts are not named as skipped"
save; sed 's/^written: brief\.sh write [0-9a-f]*/written: brief.sh write 1111111111111111111111111111111111111111/' "$T/raw/body.md" > "$T/x" && mv "$T/x" "$T/raw/body.md"
if sh checks/ticket.sh fetch 15 --from "$T/raw" > "$T/out" 2>&1; then fail 'a changed written: stamp was accepted'; fi; grep -q "written: stamp" "$T/out" || fail 'the changed stamp is not named'
exit 0
