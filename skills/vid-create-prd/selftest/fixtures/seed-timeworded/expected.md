# Expected — seed-timeworded (spec §12.2 case 9: time-worded flagging)

The demand item carrying the daily-post promise ("every weekday morning
at nine") must be authored **`derives: trigger-row`** — a Fail-if with
a schedule in it needs an operator, and the downstream derivation must
see that mechanically (the measured class: a scheduled refresh was a
REQ, the logic was tested, no scheduler existed).

The court must accept the row; the run must not ship the scheduled
promise as an unflagged functional item.
