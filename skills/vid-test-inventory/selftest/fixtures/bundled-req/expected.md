# D-4 — a bundled requirement yields one row per independently breakable promise;
# the both-feeds-once promise lives in the statement, outside the Fail-if.
# (values carry no spaces — a regex uses . for a space)
count ROW kind=behavior derived-from~REQ-001 obligation!~trigger >= 3
exists ROW derived-from~REQ-001 obligation~once|duplicate|twice|both.feeds
exists ROW derived-from~REQ-001 obligation~new|since.the.last|after.the.search
exists ROW derived-from~REQ-001 obligation~one.digest|per.day|two.digests|per.search|second.digest
