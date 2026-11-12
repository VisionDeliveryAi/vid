# JobDigest — DECISIONS

- **D-001** the mail provider is whichever the first deploy names; until then tests use a fake that records each message | why: no provider is chosen yet | enforced: convention
- **D-002** the first job feed is one partner feed, named at its step | why: the partner is chosen when its step is built | enforced: convention
- **D-003** S01 shows the saved state in one line below the form | why: short | enforced: convention
- **D-004** RULE-001 footers name the support address in plain words | why: plain words read the same in every mail client | enforced: convention
- **D-005** the confirmation email's Confirm link opens S02 in its active state, with no sign-in | why: ROW-004 needs the second screen | enforced: convention
