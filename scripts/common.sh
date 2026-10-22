# Prepended to each command by default.nix.
parse_remote_args() {
  local usage="$1"
  shift
  remote_host=""
  command_args=()
  while (( $# )); do
    case "$1" in
      --remote)
        if (( $# < 2 )) || [[ -z "$2" || "$2" == -* || "$2" == *[[:space:]]* ]]; then
          echo "$usage" >&2
          return 2
        fi
        remote_host="$2"
        shift 2
        ;;
      --)
        command_args+=("$@")
        break
        ;;
      *)
        command_args+=("$1")
        shift
        ;;
    esac
  done
}

configure_remote_ssh() {
  export NIX_SSHOPTS="-o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 -o ServerAliveInterval=15 -o ServerAliveCountMax=2 ${NIX_SSHOPTS-}"
}

monitor_build() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == '@nix '* ]]; then
      { printf '%s\n' "$line"; cat; } | nom --json
      break
    fi
    printf '%s\n' "$line" >&2
  done
}
