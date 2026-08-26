#!/usr/bin/env bash
# Corporate website guard.
#
# AAK RRSS is the private administration panel for AAK Developer's social accounts.
# It must never be advertised, described or linked from this public site: any such
# reference hands the public a visible path towards the admin panel.
#
# Run locally:      ./scripts/verify-no-rrss.sh
# Run against prod: ./scripts/verify-no-rrss.sh --remote
set -euo pipefail
cd "$(dirname "$0")/.."

PATTERN='aak[ _-]?rrss|rrss\.aakdeveloper\.com|aak-rrss-logo'
status=0

echo "== Repositorio =="
if hits=$(grep -rniE "$PATTERN" . --exclude-dir=.git --exclude-dir=scripts 2>/dev/null); then
  echo "FALLO: se han encontrado referencias a AAK RRSS:"
  echo "$hits"
  status=1
else
  echo "OK: 0 referencias a AAK RRSS en el repositorio."
fi

if [ "${1:-}" = "--remote" ]; then
  echo
  echo "== Producción (https://www.aakdeveloper.com) =="
  checked=0
  for f in $(git ls-files '*.html'); do
    url="https://www.aakdeveloper.com/${f%index.html}"
    url="${url%/}"; [ "$f" = "index.html" ] && url="https://www.aakdeveloper.com/"
    # A page that could not be fetched is NOT a page that passed. Retry, then fail
    # loudly — a guard that reports OK on a failed request is worse than no guard.
    if ! body=$(curl -fsS --retry 3 --retry-delay 2 --retry-all-errors "$url"); then
      echo "FALLO: no se pudo comprobar $url"; status=1; continue
    fi
    checked=$((checked+1))
    n=$(printf '%s' "$body" | grep -ciE "$PATTERN" || true)
    if [ "$n" != "0" ]; then echo "FALLO: $url → $n coincidencias"; status=1; fi
  done
  echo "Páginas comprobadas: $checked"
  [ "$status" = "0" ] && echo "OK: 0 referencias a AAK RRSS en las $checked páginas publicadas."
fi

echo
if [ "$status" = "0" ]; then echo "✓ Sin exposición pública de AAK RRSS."; else echo "✗ Exposición pública detectada."; fi
exit $status
