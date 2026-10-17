# engineering-choice (10c, 10e): the record is explicitly silent on an
# ordinary implementation choice — code generation, the store, and
# whether the click count is written in the request or afterwards
# (A-011, "you pick", within the stated outcome constraints). No pass
# reports it: a choice that preserves the intended outcome is the
# builder's. Everything else is the clean set, so the block is empty.
absent finding evidence~(generator|storage|store|database|queue).*(invent|unspecified|undecided|left.open|must.decide|has.to.choose)
count finding = 0
