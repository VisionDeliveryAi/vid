#!/bin/sh
# Purpose: selftest case — the census never judges the memory reader (v0.9.4
# fix). checks/extractors/memory.sh is the observer's reader (v0.9.3 3.9;
# seed/extractors/README.md): one line, `free-mb <n>` or `inactive <reason>`,
# read by checks/observe.sh alone. A toy project with the reader printing
# `free-mb 4096` beside one ordinary class extractor: the census acquits and
# counts the class census; polarity — an orphan in that class extractor,
# beside the same reader, still convicts. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: memory reader (fixture)\necho "free-mb 4096"\n' > checks/extractors/memory.sh
printf '#!/bin/sh\n# Purpose: dead-path extractor (fixture)\necho "ok field:email"\n' > checks/extractors/dead-path.fields.sh
sh "$CHECKS/census.sh" >out.txt 2>&1 || { echo 'census-memory: the memory reader was judged as a census' >&2; cat out.txt >&2; exit 1; }
grep -q '^census dead-path.fields: population=1 ok=1 orphans=0 ' out.txt || exit 1
printf '#!/bin/sh\n# Purpose: dead-path extractor (fixture)\necho "ok field:email"\necho "orphan field:phone never-read"\n' > checks/extractors/dead-path.fields.sh
if sh "$CHECKS/census.sh" >out.txt 2>&1; then echo 'census-memory: an orphan beside the memory reader passed' >&2; exit 1; fi
grep -q '^FAIL  dead-path.fields  field:phone  never-read$' out.txt || exit 1
exit 0
