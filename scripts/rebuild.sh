#!/usr/bin/env bash
set -euo pipefail

if ! declare -F parse_remote_args >/dev/null; then
  # shellcheck source=/dev/null
  source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

case "${0##*/}" in
  rebuild-test) action="test" ;;
  rebuild-boot) action="boot" ;;
  *) action="switch" ;;
esac

parse_remote_args 'Usage: rebuild[-test|-boot] [--remote [user@]host] [nixos-rebuild options]' "$@"

: "${NIXOS_FLAKE_HOST:?NIXOS_FLAKE_HOST must name the local flake configuration}"

flake="$HOME/nixos#$NIXOS_FLAKE_HOST"
evaluation_args=()
unset NIXOS_SECRETS_USE_GITHUB
if [[ ! -r /run/secrets/git_ssh_private_key ]] && github_token=$(gh auth token --hostname github.com 2>/dev/null); then
  export NIX_CONFIG="${NIX_CONFIG-}"$'\n'"extra-access-tokens = github.com=$github_token"
  unset github_token
  export NIXOS_SECRETS_USE_GITHUB=1
  evaluation_args+=(--impure)
fi

sudo -v
rebuild_command=(nixos-rebuild "$action" --sudo)

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

log_args=(-L)
if command -v nom >/dev/null; then
  log_args+=(--log-format internal-json)
fi
"${rebuild_command[@]}" "${log_args[@]}" \
  --flake "$flake" "${evaluation_args[@]}" "${command_args[@]}" 2>&1 | monitor_build
