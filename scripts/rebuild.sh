#!/usr/bin/env bash
set -euo pipefail

case "${0##*/}" in
  rebuild-test) action="test" ;;
  rebuild-boot) action="boot" ;;
  *) action="switch" ;;
esac

remote_host=""
rebuild_args=()
while (( $# )); do
  case "$1" in
    --remote)
      if (( $# < 2 )) || [[ -z "$2" || "$2" == -* ]]; then
        echo 'Usage: rebuild[-test|-boot] [--remote [user@]host] [nixos-rebuild options]' >&2
        exit 2
      fi
      remote_host="$2"
      shift 2
      ;;
    *)
      rebuild_args+=("$1")
      shift
      ;;
  esac
done

: "${NIXOS_FLAKE_HOST:?NIXOS_FLAKE_HOST must name the local flake configuration}"

sudo -v
rebuild_command=(sudo nixos-rebuild "$action")

if [[ -n "$remote_host" ]]; then
  # Keep sudo available during long remote builds, and stop refreshing on exit.
  (
    sleep_pid=""
    trap '[[ -z "$sleep_pid" ]] || kill "$sleep_pid" 2>/dev/null || true' EXIT
    trap 'exit 0' INT TERM
    while sudo -n -v; do
      sleep 60 &
      sleep_pid=$!
      wait "$sleep_pid"
      sleep_pid=""
    done
  ) &
  sudo_keepalive_pid=$!
  trap 'kill "$sudo_keepalive_pid" 2>/dev/null || true; wait "$sudo_keepalive_pid" 2>/dev/null || true' EXIT
  export NIX_SUDOOPTS="-n ${NIX_SUDOOPTS-}"
  export NIX_SSHOPTS="-o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 -o ServerAliveInterval=15 -o ServerAliveCountMax=2 ${NIX_SSHOPTS-}"
  rebuild_command=(nixos-rebuild "$action" --sudo --build-host "$remote_host" --use-substitutes)
fi

# Evaluation can be silent for a while. Start nom only once Nix emits its
# structured log, while showing earlier rebuild messages immediately.
"${rebuild_command[@]}" -v -L --log-format internal-json \
  --flake "$HOME/nixos#$NIXOS_FLAKE_HOST" "${rebuild_args[@]}" 2>&1 | {
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == '@nix '* ]]; then
      { printf '%s\n' "$line"; cat; } | nom --json
      break
    fi
    printf '%s\n' "$line" >&2
  done
}
