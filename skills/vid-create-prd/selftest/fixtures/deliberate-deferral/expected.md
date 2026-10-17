# deliberate-deferral (10b, 10e): creator-side deletion is asked for by the
# seed and DEFERRED by owner ruling A-002 — named in Explicitly not MVP,
# NG-003 and the receipt's support-address path. The audit must not
# report the loop's missing "undo" as a core-loop omission, and no pass
# may rediscover the deferral as missing scope. Everything else is the
# clean set, so the block is empty.
absent finding target~DIM-core-loop-continuity
absent finding evidence~(creator|editor).{0,40}(delet|remov|withdraw)
count finding = 0
