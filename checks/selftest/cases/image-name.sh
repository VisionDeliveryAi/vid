#!/bin/sh
# Purpose: selftest case — a run's names from its folder's name (v0.9.7.0.8
# T1). Inside the gate, the compose project vid-s<k>-<name> and the image
# vid-s<k>-<name>:run come from the folder's name. Seven real folders, each
# a toy repository whose run goes through the recording compose stub (no
# Docker): a trailing space, `my_ project`, `a _b`, `x___y`, `!!!`, 250
# letters (a folder name is at most 255 bytes) and a plain name. Convicts
# unless every compose project matches Compose's `^[a-z0-9][a-z0-9_-]*$`,
# every image matches the image reference grammar (lowercase letters and
# digits joined by `.`, `_`, `__` or a run of `-`) plus `:run` in at most
# 255 characters, `!!!` gives vid-s1-project and the plain name
# vid-s1-plain. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "image-name: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the image each run's override gives its processes, then the fixture's stub
cat > "$T/img.sh" <<'STUB'
#!/bin/sh
for a in "$@"; do case "$a" in *override.yml) sed -n 's/^    image: //p' "$a" | head -n 1 >> "$IMG_LOG" ;; esac; done
exec "$STUB_INNER" "$@"
STUB
chmod +x "$T/img.sh"
export STUB_INNER="$T/stub.sh" IMG_LOG="$T/img.log" VID_COMPOSE="$T/img.sh" VID_REQUEST=selftest-direct
LONG=$(awk 'BEGIN { while (n++ < 250) printf "a" }')
i=0
printf 'My App 0.9.7 Copy \nmy_ project\na _b\nx___y\n!!!\n%s\nplain\n' "$LONG" > "$T/names"
while IFS= read -r NM; do
  i=$((i + 1)); mkdir -p "$T/f$i"
  ( gated_repo "$T/f$i/$NM"; gate_on
    : > "$STUB_LOG"; : > "$IMG_LOG"
    RC=0; sh checks/test.sh --role builder -- x > "$T/out" 2>&1 || RC=$?
    P=$(awk -F'|' '$2 != "" { print $2; exit }' "$STUB_LOG"); I=$(tail -n 1 "$IMG_LOG")
    [ -n "$P" ] && [ -n "$I" ] || fail "no compose project or image recorded for '$NM'"
    printf '%s\n' "$P" | grep -qE '^[a-z0-9][a-z0-9_-]*$' || fail "'$NM': compose project '$P' is not a valid Compose project name"
    printf '%s\n' "$I" | grep -qE '^[a-z0-9]+(([.]|_|__|-+)[a-z0-9]+)*:run$' || fail "'$NM': image '$I' breaks the image reference grammar"
    [ "${#I}" -le 255 ] || fail "'$NM': image '$I' is ${#I} characters, over 255"
    case "$NM" in
      '!!!') [ "$P" = vid-s1-project ] || fail "'!!!' gave '$P', not vid-s1-project" ;;
      plain) [ "$P" = vid-s1-plain ] && [ "$I" = vid-s1-plain:run ] || fail "the plain name gave '$P' and '$I'" ;;
    esac
    [ "$RC" -eq 0 ] || fail "the run in '$NM' exited $RC" )
done < "$T/names"
[ "$i" -eq 7 ] || fail "ran $i folders, not 7"
exit 0
