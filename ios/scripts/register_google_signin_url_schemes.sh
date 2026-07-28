#!/bin/sh
# One-time helper: register 558349 iOS OAuth reversed URL schemes in Info.plist.
# Run after filling CLIENT_ID in Runner/Firebase/GoogleSignIn.{local,dev}.plist:
#   /bin/sh ios/scripts/register_google_signin_url_schemes.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="${ROOT}/Runner/Info.plist"
FIREBASE_DIR="${ROOT}/Runner/Firebase"

reversed_from_client_id() {
  case "$1" in
    *.apps.googleusercontent.com)
      local prefix="${1%.apps.googleusercontent.com}"
      printf 'com.googleusercontent.apps.%s' "$prefix"
      ;;
    *)
      return 1
      ;;
  esac
}

scheme_registered() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes" "$INFO_PLIST" 2>/dev/null \
    | rg -F "$1" >/dev/null
}

add_scheme() {
  local scheme="$1"
  if scheme_registered "$scheme"; then
    echo "Info.plist already has URL scheme: ${scheme}"
    return 0
  fi
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes: string ${scheme}" "$INFO_PLIST"
  echo "Added URL scheme to Info.plist: ${scheme}"
}

added=0
for env in local dev; do
  plist="${FIREBASE_DIR}/GoogleSignIn.${env}.plist"
  if [ ! -f "$plist" ]; then
    continue
  fi
  client_id="$(plutil -extract CLIENT_ID raw -o - "$plist" 2>/dev/null || true)"
  if [ -z "$client_id" ]; then
    echo "skip ${env}: CLIENT_ID empty in ${plist}" >&2
    continue
  fi
  reversed="$(reversed_from_client_id "$client_id")"
  add_scheme "$reversed"
  added=$((added + 1))
done

if [ "$added" -eq 0 ]; then
  echo "No GoogleSignIn CLIENT_ID found. Create iOS OAuth clients in GCP project 558349443875" >&2
  echo "for kr.sudatalk.app.local / .dev, then fill GoogleSignIn.*.plist and re-run." >&2
  exit 1
fi
