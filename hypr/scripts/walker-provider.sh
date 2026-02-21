#!/usr/bin/env bash
set -euo pipefail

provider="${1:-}"
placeholder="${2:-${provider^}}"

if [ -z "$provider" ]; then
  echo "usage: walker-provider.sh <provider> [placeholder]"
  exit 1
fi

if ! command -v walker >/dev/null 2>&1; then
  echo "walker is not installed"
  exit 1
fi

if ! command -v elephant >/dev/null 2>&1; then
  echo "elephant is not installed"
  exit 1
fi

if ! systemctl --user is-active --quiet elephant.service; then
  systemctl --user start elephant.service >/dev/null 2>&1 || true
fi

if ! elephant listproviders 2>/dev/null | cut -d ';' -f2 | grep -Fxq "$provider"; then
  msg="Elephant provider '$provider' is not installed/enabled."
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Walker" "$msg"
  else
    echo "$msg"
  fi
  exit 1
fi

exec walker --provider "$provider" --placeholder "$placeholder"
