#!/usr/bin/env bash
set -euo pipefail

usage='Usage: cache-kernels [--remote [user@]host] [flake-path]'
parse_remote_args "$usage" "$@"
set -- "${command_args[@]}"
if [[ "${1-}" == -- ]]; then shift; fi
if (( $# > 1 )) || [[ "${1-}" == --help || "${1-}" == -h ]]; then
  echo "$usage"
  echo 'Build custom kernels, then push to thoren.cachix.org.'
  echo 'Defaults to ~/nixos. Uses CACHIX_AUTH_TOKEN or /run/secrets/cachix_auth_token.'
  echo "--remote builds and uploads on the SSH host using this machine's current checkout."
  if (( $# > 1 )); then exit 2; fi
  exit 0
fi

flake_path=$(realpath -e -- "${1:-$HOME/nixos}")
if [[ ! -f "$flake_path/flake.nix" ]]; then
  echo "No flake.nix in local checkout: $flake_path" >&2
  exit 1
fi
echo "Using current local checkout: $flake_path" >&2
cache_url=https://thoren.cachix.org
cache_key=thoren.cachix.org-1:mytm0o2ZOjOeSN3E5wUNA2m/UEQ5t481+7Tnv/mWung=
token_file=/run/secrets/cachix_auth_token

work_dir=$(mktemp -d -t cache-kernels.XXXXXXXX)
trap 'rm -rf -- "$work_dir"' EXIT

build_args=()
remote_cachix_ready=false
if [[ -n "$remote_host" ]]; then
  configure_remote_ssh
  read -r -a ssh_options <<< "$NIX_SSHOPTS"
  remote_store="ssh-ng://$remote_host"
  build_args=(--store "$remote_store" --eval-store daemon --no-link)
fi

remote_upload=$(cat <<'BASH'
  set -euo pipefail
  IFS= read -r -d "" CACHIX_AUTH_TOKEN
  IFS= read -r -d "" signing_key
  export CACHIX_AUTH_TOKEN
  if [[ -n "$signing_key" ]]; then export CACHIX_SIGNING_KEY="$signing_key"; fi
  cachix_binary="$1"
  shift
  roots=$(mktemp -d -t cache-kernels-upload.XXXXXXXX)
  trap 'rm -rf -- "$roots"' EXIT
  i=0
  for output in "$@"; do
    nix-store --realise "$output" --add-root "$roots/$i" > /dev/null
    i=$((i + 1))
  done
  "$cachix_binary" push thoren "$@"
BASH
)

nix eval --no-update-lock-file --store daemon --json "$flake_path#nixosConfigurations.default" \
  --apply 'host: host.options.cachyosKernel.variant.type.functor.payload.values' \
  > "$work_dir/variants.json"
mapfile -t variants < <(jq -r '.[]' "$work_dir/variants.json")
if (( ${#variants[@]} == 0 )); then
  echo "No custom kernel variants defined in $flake_path." >&2
  exit 1
fi
kernel_expression='
  let
    host = (builtins.getFlake (builtins.getEnv "CACHYOS_KERNEL_FLAKE")).nixosConfigurations.default;
    kernel = (host.extendModules {
      modules = [ {
        cachyosKernel.enable = host.pkgs.lib.mkForce true;
        cachyosKernel.variant = host.pkgs.lib.mkForce (builtins.getEnv "CACHYOS_KERNEL_VARIANT");
      } ];
    }).config.boot.kernelPackages.kernel;
  in map (name: builtins.getAttr name kernel) kernel.outputs
'
export CACHYOS_KERNEL_FLAKE="$flake_path"
for variant in "${variants[@]}"; do
  export CACHYOS_KERNEL_VARIANT="$variant"
  kernel_args=(--impure --expr "$kernel_expression")
  echo "Checking $variant kernel and headers in $cache_url..." >&2
  nix eval --no-update-lock-file --store daemon --json "${kernel_args[@]}" \
    --apply 'outputs: map (output: output.outPath) outputs' \
    > "$work_dir/expected-outputs.json"
  mapfile -t expected_outputs < <(jq -r '.[]' "$work_dir/expected-outputs.json")
  if (( ${#expected_outputs[@]} == 0 )); then
    echo "No expected kernel outputs returned for $variant." >&2
    exit 1
  fi
  all_cached=true
  for output in "${expected_outputs[@]}"; do
    store_name="${output##*/}"
    store_hash="${store_name%%-*}"
    status=$(curl --silent --show-error --location --head \
      --connect-timeout 10 --max-time 30 --retry 2 \
      --output /dev/null --write-out '%{http_code}' \
      "$cache_url/$store_hash.narinfo")
    case "$status" in
      200) ;;
      404) all_cached=false ;;
      *)
        echo "Cache check failed for $output (HTTP $status); refusing to start a build." >&2
        exit 1
        ;;
    esac
  done
  if "$all_cached"; then
    echo "$variant kernel and headers are already cached; skipping." >&2
    continue
  fi
  if [[ -z "${CACHIX_AUTH_TOKEN:-}" && ! -r "$token_file" ]]; then
    echo "Missing Cachix credentials: provision $token_file or set CACHIX_AUTH_TOKEN." >&2
    exit 1
  fi
  if [[ -n "$remote_host" ]] && ! "$remote_cachix_ready"; then
    remote_cachix_binary=$(readlink -f -- "$(command -v cachix)")
    nix copy --to "$remote_store" "${remote_cachix_binary%/bin/*}"
    remote_cachix_ready=true
  fi

  echo "Building $variant kernel and headers..." >&2
  if [[ -z "$remote_host" ]]; then
    build_args=(--out-link "$work_dir/$variant")
  fi
  {
    nix build --no-update-lock-file -v -L --log-format internal-json --json \
      --extra-substituters "$cache_url" --extra-trusted-public-keys "$cache_key" \
      "${build_args[@]}" \
      "${kernel_args[@]}" \
      2>&1 1>&3 | monitor_build >&2
  } 3> "$work_dir/outputs.json"
  mapfile -t outputs < <(jq -r '.[].outputs[]' "$work_dir/outputs.json")
  if (( ${#outputs[@]} == 0 )); then
    echo "No kernel outputs returned for $variant." >&2
    exit 1
  fi

  if [[ -n "$remote_host" ]]; then
    echo "Pushing $variant to thoren.cachix.org from $remote_host..." >&2
    printf -v upload_command '%q ' bash -c "$remote_upload" -- "$remote_cachix_binary" "${outputs[@]}"
    printf '%s\0%s\0' "${CACHIX_AUTH_TOKEN:-$(cat "$token_file")}" "${CACHIX_SIGNING_KEY-}" \
      | ssh "${ssh_options[@]}" -T "$remote_host" "$upload_command"
  else
    echo "Pushing $variant to thoren.cachix.org..." >&2
    if [[ -n "${CACHIX_AUTH_TOKEN:-}" ]]; then
      cachix push thoren "${outputs[@]}"
    else
      CACHIX_AUTH_TOKEN="$(cat "$token_file")" cachix push thoren "${outputs[@]}"
    fi
  fi
done

echo 'All kernel variants are available in thoren.cachix.org.'
