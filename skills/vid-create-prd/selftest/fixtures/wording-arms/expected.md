# wording-arms (v0.9.1 3.5): REQ-018's fail-if is three clauses worded as a
# mechanism's absence (a missing check, an absent guard, a comparison that
# is not constant-time). The wording lens returns one rewording for it,
# harm-worded, whose arms: carries three entries and loses none — retained
# or strengthened; a withdrawal needs a ruling that exists, and the record
# has none. The rest of the set is harm-worded; a rewording elsewhere is
# neither pinned nor forbidden (counts never scores).
exists rewording id=REQ-018
count rewording id=REQ-018 = 1
exists rewording id=REQ-018 arms~^1.(retained|strengthened),.2.(retained|strengthened),.3.(retained|strengthened)$
absent rewording id=REQ-018 arms~withdrawn|moved
absent rewording id=REQ-018 fail-if~(check|guard|comparison|validation).{0,24}(missing|absent|does.not.exist|is.not.present|not.constant)
