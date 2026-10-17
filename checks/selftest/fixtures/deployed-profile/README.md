# deployed-profile — the toy harness for the deployed shape (v0.9.3 3.3, §7 case 12)

A fixture, never installed. `tree/` is a toy product: one image (a small
base image and two shell scripts), a product service that takes a feed item
at its inbound boundary and — inline — indexes it, or — in the deployed
shape — routes it to a transport a worker process consumes; named volumes
for the inbox, the transport and the store; a toy runner writing the results
reader's `case` lines. `run-real.sh` runs it through the plugin's
checks/test.sh with a real container engine — the half of case 12 the
recording stub cannot show (fresh volumes between passes; a `(process)` row
red in the profile with its consumer absent, green when wired). The suite's
`deployed-profile.sh` covers the wrapper's order with a stub and needs no
engine; this procedure is run by the builder and its output recorded in the
build notes.
