# machine-journey — v0.9.3 3.2, 3.3 (§7 case 2): one feed boundary, two promised consequences
# the machine journey: actor (process), the stages as transitions, searchable and notified
exists ROW kind=journey row~[(]process[)] obligation~index obligation~notif|digest
exists ROW kind=journey row~[(]process[)] obligation~enter|pull|poll|arriv obligation~stor
# the trigger rows take actor (process)
exists ROW kind=behavior row~[(]process[)] obligation~trigger|registered|fires|scheduled
# the inline switch is a difference paid by the close run in the deployed profile
exists difference row~inline row~close.run row~profile=deployed
# and its gate-2 sibling carries the platform half only
exists ROW test~paid.by./vid.deploy.gate.2 obligation~platform obligation~worker|consum
# the fast-schedule setting is a difference that keeps staging
exists difference row~schedul row~staging row!~profile=deployed
# no journey or trigger row is deferred (a prerequisite) for want of the deployed shape — the
# gate-2 siblings are deploy-owed by design and are not deferrals (v2: v1 forbade them too)
absent ROW row~[(]process[)] test~^owed:.prerequisite.*(deployed|worker|profile|inline)
