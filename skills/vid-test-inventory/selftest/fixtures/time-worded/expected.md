# D-1 — a time-worded Fail-if yields a trigger-existence row, marker or not
# REQ-001 carries derives: trigger-row; REQ-013 carries no marker but says "seven consecutive days".
exists ROW kind=behavior subject=REQ-001 obligation~trigger|operator|fires|registered
exists ROW kind=behavior subject=REQ-013 obligation~trigger|operator|fires|registered
exists ROW kind=behavior derived-from~REQ-013 obligation!~trigger
# the ordinary behaviour rows still exist
exists ROW kind=behavior derived-from~REQ-001 obligation!~trigger
