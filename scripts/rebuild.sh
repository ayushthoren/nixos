#!/usr/bin/env bash
set -euo pipefail

case "${0##*/}" in
  rebuild-test) action="test" ;;
  rebuild-boot) action="boot" ;;
  *) action="switch" ;;
esac

parse_remote_args 'Usage: rebuild[-test|-boot] [--remote [user@]host] [nixos-rebuild options]' "$@"

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
  configure_remote_ssh
  rebuild_command=(nixos-rebuild "$action" --sudo --build-host "$remote_host" --use-substitutes)
fi

"${rebuild_command[@]}" -L --log-format internal-json \
  --flake "$HOME/nixos#$NIXOS_FLAKE_HOST" "${command_args[@]}" 2>&1 | monitor_build
