# JobDigest — design brief (fixture: harness-config, v0.9.2 3.13)

grammar: 0.9.2

One screen, two states, so the derivation carries surface rows beside the DIF row.

```vid-design-manifest
P01 | default | REQ-001,REQ-021 | pins: the digest header carries the brand colour and the sender name the operator entered; one unsubscribe link per digest
P01 | empty | REQ-001 | pins: the no-new-matches notice present; no listing drawn
C00 | shell-anonymous | REQ-002 | pins: the footer's support address; the unsubscribe link present
```
