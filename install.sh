#!/usr/bin/env bash

set -e

DEBUG=${DEBUG:-0}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() { echo -e "${RED}ERROR: $1${NC}" >&2; }
print_success() { echo -e "${GREEN}$1${NC}" >&2; }
print_info() { echo -e "${BLUE}$1${NC}" >&2; }
print_warning() { echo -e "${YELLOW}WARNING: $1${NC}" >&2; }
print_debug() {
    [[ $DEBUG -eq 1 ]] && echo -e "${BLUE}[DEBUG] $1${NC}" >&2
    return 0
}
prompt_yes() {
    local prompt="$1" default="${2:-N}" answer
    read -p "$prompt" answer >&2 || return 1
    [[ "$default" == "Y" && -z "$answer" ]] || [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_input() {
    local __var="$1" prompt="$2"
    read -p "$prompt" "$__var" >&2 || {
        echo "" >&2
        print_error "No input received"
        exit 1
    }
}

print_banner() {
    cat << 'EOF'
                                                                                                                                     
         88                                                             d8'              ad88  88              88                    
  ,d     88                                                            d8'              d8"    88              88                    
  88     88                                                           ""                88     88              88                    
MM88MMM  88,dPPYba,    ,adPPYba,   8b,dPPYba,   ,adPPYba,  8b,dPPYba,   ,adPPYba,     MM88MMM  88  ,adPPYYba,  88   ,d8   ,adPPYba,  
  88     88P'    "8a  a8"     "8a  88P'   "Y8  a8P_____88  88P'   `"8a  I8[    ""       88     88  ""     `Y8  88 ,a8"   a8P_____88  
  88     88       88  8b       d8  88          8PP"""""""  88       88   `"Y8ba,        88     88  ,adPPPPP88  8888[     8PP"""""""  
  88,    88       88  "8a,   ,a8"  88          "8b,   ,aa  88       88  aa    ]8I       88     88  88,    ,88  88`"Yba,  "8b,   ,aa  
  "Y888  88       88   `"YbbdP"'   88           `"Ybbd8"'  88       88  `"YbbdP"'       88     88  `"8bbdP"Y8  88   `Y8a  `"Ybbd8"'  
                                                                                                                                     
                                                                                                                                     
EOF
}

get_available_hosts() {
    print_debug "Entering get_available_hosts()"
    if [[ ! -f "flake.nix" ]]; then
        print_error "flake.nix not found in current directory"
        exit 1
    fi
    print_debug "flake.nix found"
    
    print_debug "Parsing flake.nix..."
    local hosts
    hosts=$(awk '
        /nixosConfigurations[[:space:]]*=[[:space:]]*\{/ { in_block=1; next }
        in_block && /^[[:space:]]*\}/ { in_block=0; next }
        in_block && $1 ~ /^[a-zA-Z0-9_-]+$/ && $2 == "=" {
            hostname = $1
            comment_start = index($0, "#")
            if (comment_start > 0) {
                comment = substr($0, comment_start + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", comment)
                print hostname "|" comment
            } else {
                print hostname
            }
        }
    ' flake.nix)
    print_debug "Parsed hosts: $hosts"
    
    if [[ -z "$hosts" ]]; then
        print_error "Could not extract host configurations from flake.nix"
        exit 1
    fi
    
    echo "$hosts"
}

select_host() {
    print_debug "Entering select_host() with args: $*"
    local host_data=("$@")
    local num_hosts=${#host_data[@]}
    print_debug "Number of hosts: $num_hosts"
    print_debug "Hosts array contents: ${host_data[*]}"
    
    if [[ $num_hosts -eq 0 ]]; then
        print_error "No hosts found in configuration"
        exit 1
    fi
    
    local default_host=""
    local default_comment=""
    local other_hostnames=()
    local other_comments=()
    
    for entry in "${host_data[@]}"; do
        local hostname
        local comment=""
        
        [[ "$entry" == *"|"* ]] && { hostname="${entry%%|*}"; comment="${entry#*|}"; } || hostname="$entry"
        
        if [[ "$hostname" == "default" ]]; then
            default_host="$hostname"
            default_comment="$comment"
        else
            other_hostnames+=("$hostname")
            other_comments+=("$comment")
        fi
    done
    
    while true; do
        clear >&2
        print_banner >&2
        echo "" >&2
        echo "═══════════════════════════════════════════════════" >&2
        echo "  Thoren's NixOS Flake Installer" >&2
        echo "═══════════════════════════════════════════════════" >&2
        echo "" >&2
        echo "Select a configuration:" >&2
        echo "" >&2
        
        if [[ -n "$default_host" ]]; then
            local display="$default_host"
            [[ -n "$default_comment" ]] && display="$display ($default_comment)"
            echo "    [1]  $display" >&2
        fi
        
        if [[ ${#other_hostnames[@]} -gt 0 ]]; then
            echo "    [2]  Other pre-configured systems (for my specific hardware)" >&2
        fi
        
        echo "" >&2
        prompt_input main_selection "Select option (1-2): "
        
        case "$main_selection" in
            1)
                if [[ -n "$default_host" ]]; then
                    echo "$default_host"
                    return
                else
                    print_error "Invalid selection"
                    sleep 1.5
                fi
                ;;
            2)
                if [[ ${#other_hostnames[@]} -gt 0 ]]; then
                    while true; do
                        clear >&2
                        print_banner >&2
                        echo "" >&2
                        echo "═══════════════════════════════════════════════════" >&2
                        echo "  Pre-configured Systems" >&2
                        echo "═══════════════════════════════════════════════════" >&2
                        echo "" >&2
                        print_warning "These configurations are specific to my various devices. They are almost guaranteed to not work properly on your hardware without modification."
                        echo "" >&2
                        echo "Available pre-configured hosts:" >&2
                        echo "" >&2
                        echo "    [0]  Go back" >&2
                        
                        local count=1
                        for i in "${!other_hostnames[@]}"; do
                            local display="${other_hostnames[$i]}"
                            [[ -n "${other_comments[$i]}" ]] && display="$display (${other_comments[$i]})"
                            echo "    [$count]  $display" >&2
                            ((count++))
                        done
                        
                        echo "" >&2
                        
                        prompt_input sub_selection "Select option (0-${#other_hostnames[@]}): "
                        
                        if [[ "$sub_selection" == "0" ]]; then
                            break
                        elif [[ "$sub_selection" =~ ^[0-9]+$ ]] && [[ $sub_selection -ge 1 ]] && [[ $sub_selection -le ${#other_hostnames[@]} ]]; then
                            echo "${other_hostnames[$((sub_selection - 1))]}"
                            return
                        else
                            print_error "Invalid selection. Please enter a number between 0 and ${#other_hostnames[@]}."
                            sleep 1.5
                        fi
                    done
                else
                    print_error "Invalid selection"
                    sleep 1.5
                fi
                ;;
            *)
                print_error "Invalid selection. Please enter 1 or 2."
                sleep 1.5
                ;;
        esac
    done
}

ensure_correct_location() {
    local target_dir="$HOME/nixos"
    local current_dir="$(pwd)"
    
    if [[ "$current_dir" != "$target_dir" ]]; then
        print_warning "This configuration needs to be located at ~/nixos for proper compatibility"
        echo ""
        echo "Current location: $current_dir"
        echo "Target location:  $target_dir"
        echo ""
        prompt_input move_choice "Would you like to move/copy this configuration to ~/nixos? [y/N]: "
        
        if [[ "$move_choice" =~ ^[Yy]$ ]]; then
            if [[ -d "$target_dir" ]]; then
                print_warning "Directory ~/nixos already exists"
                if ! prompt_yes "Overwrite? [y/N]: "; then
                    print_error "Installation cancelled"
                    exit 1
                fi
                rm -rf "$target_dir"
            fi
            
            print_info "Copying configuration to ~/nixos..."
            mkdir -p "$(dirname "$target_dir")"
            cp -r "$current_dir" "$target_dir"
            cd "$target_dir"
            print_success "Configuration copied to ~/nixos"
            echo ""
        else
            print_warning "Continuing anyway, but some features may not work correctly"
            echo ""
            if ! prompt_yes "Continue? [y/N]: "; then
                print_error "Installation cancelled"
                exit 1
            fi
        fi
    else
        print_success "✓ Configuration is in the correct location (~/nixos)"
        echo ""
    fi
}

check_nixos_environment() {
    if [[ ! -f /etc/NIXOS ]]; then
        print_warning "This doesn't appear to be a NixOS system"
        prompt_yes "Continue anyway? [y/N]: " || exit 1
    fi
}

check_prerequisites() {
    local missing_deps=()
    
    for dep in nix awk findmnt lsblk; do
        command -v "$dep" &> /dev/null || missing_deps+=("$dep")
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

get_cache_config() {
    local cache_config_file="./modules/core/caches.conf"

    if [[ ! -f "$cache_config_file" ]]; then
        print_error "Cache config file not found: $cache_config_file"
        exit 1
    fi

    cat "$cache_config_file"
    printf '\nexperimental-features = nix-command flakes\n'
}

detect_current_boot_disk() {
    local root_source parent_disk
    root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    [[ "$root_source" != /dev/* ]] && return 0

    parent_disk="$(lsblk -no PKNAME "$root_source" 2>/dev/null | head -n 1 || true)"
    [[ -n "$parent_disk" ]] && { echo "/dev/$parent_disk"; return; }
    [[ "$(lsblk -no TYPE "$root_source" 2>/dev/null | head -n 1 || true)" == "disk" ]] && echo "$root_source"
    return 0
}

select_legacy_bootloader_device() {
    local detected_disk disk_selection disk_info
    detected_disk="$(detect_current_boot_disk)"

    if [[ -n "$detected_disk" && -b "$detected_disk" ]]; then
        echo "" >&2
        print_warning "This system appears to be booted in legacy BIOS mode."
        print_warning "Legacy GRUB is strongly recommended; without it, this install may not boot."
        print_info "Detected likely boot disk: $detected_disk"
        prompt_yes "Use recommended legacy GRUB install target $detected_disk? [Y/n]: " Y && { echo "$detected_disk"; return; }
    fi

    mapfile -t disks < <(lsblk -dnpo NAME,TYPE 2>/dev/null | awk '$2 == "disk" { print $1 }')

    if [[ ${#disks[@]} -eq 1 ]]; then
        echo "" >&2
        print_warning "This system appears to be booted in legacy BIOS mode."
        print_warning "Legacy GRUB is strongly recommended; without it, this install may not boot."
        print_info "Detected one installable disk: ${disks[0]}"
        prompt_yes "Use recommended legacy GRUB install target ${disks[0]}? [Y/n]: " Y && { echo "${disks[0]}"; return; }
    fi

    while true; do
        echo "" >&2
        print_warning "This system appears to be booted in legacy BIOS mode."
        print_warning "Legacy GRUB is strongly recommended; without it, this install may not boot."
        echo "Select the whole disk, not a partition." >&2
        echo "" >&2

        for i in "${!disks[@]}"; do
            disk_info="$(lsblk -dnpo NAME,SIZE,MODEL "${disks[$i]}" 2>/dev/null || echo "${disks[$i]}")"
            echo "    [$((i + 1))]  $disk_info" >&2
        done

        echo "" >&2
        prompt_input disk_selection "Select disk path or number: "

        if [[ "$disk_selection" =~ ^[0-9]+$ && "$disk_selection" -ge 1 && "$disk_selection" -le "${#disks[@]}" ]]; then
            echo "${disks[$((disk_selection - 1))]}"
            return
        fi

        [[ "$disk_selection" == /dev/* && -b "$disk_selection" ]] && { echo "$disk_selection"; return; }

        print_error "Invalid disk selection"
    done
}

update_default_bootloader_config() {
    local default_config="$1"
    local legacy_bootloader="$2"
    local grub_device="$3"
    local temp_config

    temp_config="$(mktemp)"

    if awk -v enabled="$legacy_bootloader" -v device="$grub_device" '
        function print_legacy_bootloader() {
            print "  legacyBootloader = {"
            print "    enable = " enabled ";"
            print "    device = \"" device "\";"
            print "  };"
        }

        /^[[:space:]]*legacyBootloader = \{/ {
            print_legacy_bootloader()
            in_legacy_bootloader = 1
            updated = 1
            next
        }

        in_legacy_bootloader && /^[[:space:]]*};/ {
            in_legacy_bootloader = 0
            next
        }

        in_legacy_bootloader {
            next
        }

        /^[[:space:]]*legacyBootloader\.enable = (true|false);/ {
            print_legacy_bootloader()
            updated = 1
            next
        }

        {
            print
        }

        END {
            if (!updated) {
                exit 1
            }
        }
    ' "$default_config" > "$temp_config"; then
        mv "$temp_config" "$default_config"
    else
        rm -f "$temp_config"
        return 1
    fi
}

configure_default_bootloader() {
    local default_config="./hosts/default/configuration.nix"
    local legacy_bootloader="false"
    local grub_device="nodev"

    if [[ ! -f "$default_config" ]]; then
        print_warning "Default host configuration not found: $default_config"
        return
    fi

    if [[ ! -d /sys/firmware/efi ]]; then
        echo "" >&2
        print_warning "No EFI firmware interface was detected."
        print_warning "The installer will enable legacyBootloader because this is the safest choice for this machine."
        legacy_bootloader="true"
        grub_device="$(select_legacy_bootloader_device)"
    fi

    print_info "Detected boot mode: $([[ "$legacy_bootloader" == "true" ]] && echo "legacy BIOS" || echo "UEFI")"
    print_info "Setting legacyBootloader for default host..."

    if update_default_bootloader_config "$default_config" "$legacy_bootloader" "$grub_device"; then
        print_success "✓ Bootloader compatibility configured"
        echo ""
    else
        print_warning "Failed to update legacyBootloader.enable in $default_config"
    fi
}

run_wallpaper_post_command() {
    local cache_config="$1"
    local colors_path="$(pwd)/modules/home/waypaper/defaultcolors.jpg"
    local wallust_config="$(pwd)/modules/home/wallust/config.toml"
    local wallust_templates="$(pwd)/modules/home/wallust/templates"

    if [[ ! -f "$colors_path" ]]; then
        print_warning "Default color source not found at $colors_path"
        return
    fi

    if [[ ! -f "$wallust_config" || ! -d "$wallust_templates" ]]; then
        print_warning "Wallust config/templates not found in repo"
        return
    fi

    echo ""
    print_info "Generating initial theme assets and setting wallpaper..."
    echo ""

    if NIX_CONFIG="$cache_config" nix shell \
        nixpkgs#wallust \
        nixpkgs#librsvg \
        --command bash -lc '
            set -e
            colors_path="$1"
            wallust_config="$2"
            wallust_templates="$3"

            wallust run "$colors_path" --config-file "$wallust_config" --templates-dir "$wallust_templates"
            rsvg-convert -a -w 1080 -h 1080 "$HOME/.cache/wallust/colors-nixoslogo.svg" -o "$HOME/.cache/wallust/colors-nixoslogo.png"
        ' bash "$colors_path" "$wallust_config" "$wallust_templates"; then
        print_success "✓ Initial theme assets generated"
    else
        print_warning "Failed to generate initial theme assets automatically"
    fi

    echo ""
}

perform_rebuild() {
    local hostname="$1"
    local cache_config="$2"
    
    echo ""
    print_info "═══════════════════════════════════════════════════"
    print_info "  System Build"
    print_info "═══════════════════════════════════════════════════"
    echo ""
    echo "  Host configuration: $hostname"
    echo "  Configuration path: $(pwd)"
    echo ""
    
    print_info "Building system configuration..."
    echo ""
    
    sudo NIX_CONFIG="$cache_config" nixos-rebuild boot --flake ".#$hostname"
    
    if [[ $? -eq 0 ]]; then
        run_wallpaper_post_command "$cache_config"

        echo ""
        print_success "═══════════════════════════════════════════════════"
        print_success "  System built successfully!"
        print_success "═══════════════════════════════════════════════════"
        echo ""
        print_info "Changes will take effect on next boot"
        echo ""
        
        print_warning "Rebooting in:"
        for i in 3 2 1; do
            echo "  $i..."
            sleep 1
        done
        echo ""
        print_info "Rebooting now!"
        sudo reboot
    else
        echo ""
        print_error "Build failed. Please check the error messages above."
        exit 1
    fi
}

main() {
    clear
    
    print_debug "Starting main()"

    print_banner
    
    print_debug "Checking prerequisites"
    check_prerequisites
    
    print_debug "Checking NixOS environment"
    check_nixos_environment
    
    print_debug "Ensuring correct location"
    ensure_correct_location
    
    print_info "Detecting available host configurations..."
    print_debug "Calling get_available_hosts()"
    mapfile -t available_hosts < <(get_available_hosts)
    print_debug "Hosts loaded: ${available_hosts[*]}"
    
    if [[ ${#available_hosts[@]} -eq 0 ]]; then
        print_error "No host configurations found"
        exit 1
    fi
    
    selected_host=$(select_host "${available_hosts[@]}")
    
    if [[ "$selected_host" == "default" ]]; then
        echo "" >&2
        print_info "Generating hardware configuration for default host..."
        
        local hw_config="./hosts/default/hardware-configuration.nix"
        if sudo nixos-generate-config --show-hardware-config > "$hw_config" 2>&1; then
            print_success "✓ Hardware configuration generated successfully"
            echo "" >&2
        else
            print_error "Failed to generate hardware configuration"
            echo "" >&2
            if ! prompt_yes "Continue anyway? [y/N]: "; then
                print_error "Installation cancelled"
                exit 1
            fi
        fi

        configure_default_bootloader
    fi
    
    echo "" >&2
    echo "You are about to build and install the '$selected_host' configuration." >&2
    echo "The system will reboot automatically after a successful build." >&2
    echo "" >&2
    if ! prompt_yes "Continue? [Y/n]: " Y; then
        echo "" >&2
        print_error "Installation cancelled"
        exit 0
    fi
    
    current_user="$USER"
    print_debug "Current user: $current_user"
    
    if [[ -f "flake.nix" ]]; then
        print_info "Updating username in flake.nix to match current user ($current_user)..."
        cp flake.nix flake.nix.bak
        sed -i "s/username = \"[^\"]*\";/username = \"$current_user\";/" flake.nix
        
        if [[ $? -eq 0 ]]; then
            print_success "✓ Username updated in flake.nix"
            rm flake.nix.bak
            echo ""
        else
            print_warning "Failed to update username, restoring backup..."
            mv flake.nix.bak flake.nix
        fi
    fi
    
    cache_config="$(get_cache_config)"
    perform_rebuild "$selected_host" "$cache_config"
}

main "$@"
