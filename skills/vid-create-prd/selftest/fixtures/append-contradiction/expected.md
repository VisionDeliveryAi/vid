# append-contradiction (v0.9.1 3.2): the whole-set review in mode delta
# over the one append under ## Appends (2026-09-22) against the effective
# set. Two defects and nothing else. (1) REQ-018, cited to A-016, lets a
# link's expiry move thirty days later — incompatible with REQ-004
# (expiry is creation plus thirty days at most; a window outside one to
# thirty days is its failing case), with A-001 and the thesis ("thirty
# days at most"), and with its own grounding answer, which says the
# expiry rule does not change and REQ-004 stands: a contradiction the
# record settles, triage fix_from_record, naming both ids (REQ-004 in the
# target or in the evidence). (2) A-016 names
# REQ-005 and REQ-006; the append amends REQ-005 only, and REQ-006 is
# neither AMENDED nor named in unchanged: — the propagation finding,
# naming REQ-006, triage fix_from_record. The remainder (A-016's ruling,
# REQ-005 AMENDED, unchanged: REQ-004 and REQ-014) is coherent and draws
# nothing: exactly two findings.
count finding = 2
exists finding target~REQ-018 row~REQ-004 triage=fix_from_record
count finding target~REQ-018 = 1
exists finding target~REQ-006 target!~REQ-018 triage=fix_from_record
count finding target~REQ-006 target!~REQ-018 = 1
absent finding target!~REQ-018|REQ-004|REQ-006|REQ-005|A-016
