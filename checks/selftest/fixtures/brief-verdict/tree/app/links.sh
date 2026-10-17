#!/bin/sh
# Purpose: Linkling — the link store: create, resolve, expire, delete (REQ-001, REQ-002, REQ-003, REQ-004).
# A TOY product for the brief fixture (v0.9.3 3.1), never installed. State lives
# in one file per link under $LINKLING_STORE: target, created (epoch seconds),
# deletion token.
: "${LINKLING_STORE:=$(mktemp -d)}"
THIRTY_DAYS=2592000

# REQ-002: only web targets are accepted.
_scheme_ok() {
  case "$1" in
    javascript:*|data:*|vbscript:*) return 1 ;;
  esac
  return 0
}

# REQ-001: create a link → prints its code and its deletion token.
link_create() { # $1=target [$2=now]
  _scheme_ok "$1" || { echo "refused: scheme not allowed"; return 1; }
  now=${2:-$(date +%s)}
  code=$(printf '%s%s' "$1" "$now" | cksum | cut -c1-6)
  token=$(printf 'tok%s' "$code" | cksum | cut -c1-8)
  printf '%s\n%s\n%s\n' "$1" "$now" "$token" > "$LINKLING_STORE/$code"
  echo "$code $token"
}

# REQ-001, REQ-003: resolve a code → "302 <target>", "410 gone" after thirty days, "404".
link_resolve() { # $1=code [$2=now]
  f="$LINKLING_STORE/$1"
  [ -f "$f" ] || { echo 404; return 0; }
  now=${2:-$(date +%s)}
  created=$(sed -n 2p "$f")
  if [ $((now - created)) -gt "$THIRTY_DAYS" ]; then echo '410 gone'; return 0; fi
  echo "302 $(sed -n 1p "$f")"
}

# REQ-004: delete with the link's token; a wrong token is refused and the link stays.
link_delete() { # $1=code $2=token
  f="$LINKLING_STORE/$1"
  [ -f "$f" ] || { echo 404; return 0; }
  [ "$2" = "$(sed -n 3p "$f")" ] || { echo '403 wrong token'; return 0; }
  rm -f "$f"; echo '204 deleted'
}
