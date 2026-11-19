# Purpose: selftest fixture — the frozen second reviewer's file less 0.26.11.1.3 R3's `prove it real` (its table row, the `note it` row's
# narrowed third column, and the paragraph after the table). Applied to devagent/agents/second-reviewer.md, it gives back aa6e610's
# blob, so the cases that pin the frozen file still refuse any change but those.
/^| yes | yes | no: it happens only outside the test environment | `prove it real` |$/d
s/^| yes | yes | no, for any other reason | `note it` |$/| yes | yes | no | `note it` |/
/^`prove it real` (0.26.11.1.3, R3) is for /{
N
d
}
