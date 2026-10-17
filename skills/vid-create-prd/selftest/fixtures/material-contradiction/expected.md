# material-contradiction (10a, 10e): REQ-018 (every non-active code answers
# one identical not-found page) requires behaviour incompatible with
# REQ-004 (an expired code answers the expired page), REQ-006 (removed by
# its creator), REQ-008 (disabled) and owner answer A-001 in the same
# state — a reader following a stopped link. The whole-set review must
# report it, blocking, with a 10a-shaped evidence line: the situation
# (a stopped link), the affected actor (the reader), the incompatible
# passages by id. Every finding names the contradiction; no unrelated
# finding (the rest is the clean set). Two human rulings collide, so the
# contradiction's triage is needs_owner (a finding that would override an
# owner answer is a question) or fix_from_record; never fix_model_authority.
count finding >= 1
exists finding severity=blocking target~REQ-018
exists finding target~REQ-018 target~REQ-004|REQ-006|REQ-008
exists finding target~REQ-018 evidence~reader
exists finding target~REQ-018 evidence~expired|removed|disabled|stopped
exists finding target~REQ-018 evidence~REQ-004|REQ-006|REQ-008
exists finding target~REQ-018 triage~needs_owner|fix_from_record
absent finding target!~REQ-018
absent finding severity=blocking target~REQ-018 triage=fix_model_authority
