# Purpose: selftest fixture — stub courts for the hook cases (v0.9.5 spec
# 3.7-3.9). Sourced after the case has made and entered its scratch
# directory: writes checks/<court>.sh for the nine courts the hook runs, each
# recording that it ran (.ran/<court>) and refusing when .fail/<court>
# exists; checks/hooks/pre-commit is the real hook. A repository whose root
# commit carries checks/, so the working-tree rule runs. Env: CHECKS.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q
mkdir -p checks/hooks .ran .fail app
for c in placement conformance imports seams inventory census design-cite prd harness; do
  printf '#!/bin/sh\n# Purpose: stub court %s\n: > .ran/%s\nif [ -f .fail/%s ]; then echo "%s refuses" >&2; exit 1; fi\necho "%s ok"\n' "$c" "$c" "$c" "$c" "$c" > "checks/$c.sh"
done
cp "$CHECKS/hooks/pre-commit" checks/hooks/pre-commit
printf '# stub lawfiles\n' > checks/lawfiles
printf '.ran/\n.fail/\n.vid/\n' > .gitignore
printf 'x\n' > app/x.txt
g add -A && g commit -qm root
stage() { printf '%s\n' "$1" >> app/x.txt; g add app/x.txt; }
