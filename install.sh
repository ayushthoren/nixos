#!/usr/bin/env bash

set -e

# Debug mode - set to 1 to enable verbose logging
DEBUG=${DEBUG:-0}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}" >&2
}

print_info() {
    echo -e "${BLUE}$1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" >&2
}

print_debug() {
    if [[ $DEBUG -eq 1 ]]; then
        echo -e "${BLUE}[DEBUG] $1${NC}" >&2
    fi
}

# Function to print NixOS installer banner
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

# Function to extract host configurations from flake.nix
get_available_hosts() {
    print_debug "Entering get_available_hosts()"
    if [[ ! -f "flake.nix" ]]; then
        print_error "flake.nix not found in current directory"
        exit 1
    fi
    print_debug "flake.nix found"
    
    # Extract host names and comments from nixosConfigurations by parsing the flake.nix file
    # Format: hostname|comment (or just hostname if no comment)
    print_debug "Parsing flake.nix..."
    local hosts
    hosts=$(awk '
        /nixosConfigurations[[:space:]]*=[[:space:]]*\{/ { in_block=1; next }
        in_block && /^[[:space:]]*\}/ { in_block=0; next }
        in_block && $1 ~ /^[a-zA-Z0-9_-]+$/ && $2 == "=" { 
            hostname = $1
            # Extract comment after #
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

# Function to display numbered menu and get user selection
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
    
    # Parse hostnames and comments
    local hostnames=()
    local comments=()
    local default_host=""
    local default_comment=""
    local other_hostnames=()
    local other_comments=()
    
    for entry in "${host_data[@]}"; do
        local hostname
        local comment=""
        
        if [[ "$entry" == *"|"* ]]; then
            hostname="${entry%%|*}"
            comment="${entry#*|}"
        else
            hostname="$entry"
        fi
        
        if [[ "$hostname" == "default" ]]; then
            default_host="$hostname"
            default_comment="$comment"
        else
            other_hostnames+=("$hostname")
            other_comments+=("$comment")
        fi
    done
    
    # Main menu
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
        read -p "Select option (1-2): " main_selection >&2
        
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
                    # Show submenu
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
                            if [[ -n "${other_comments[$i]}" ]]; then
                                display="$display (${other_comments[$i]})"
                            fi
                            echo "    [$count]  $display" >&2
                            ((count++))
                        done
                        
                        echo "" >&2
                        
                        read -p "Select option (0-${#other_hostnames[@]}): " sub_selection >&2
                        
                        if [[ "$sub_selection" == "0" ]]; then
                            break  # Go back to main menu
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

# Function to ensure we're in ~/nixos
ensure_correct_location() {
    local target_dir="$HOME/nixos"
    local current_dir="$(pwd)"
    
    if [[ "$current_dir" != "$target_dir" ]]; then
        print_warning "This configuration needs to be located at ~/nixos for proper compatibility"
        echo ""
        echo "Current location: $current_dir"
        echo "Target location:  $target_dir"
        echo ""
        read -p "Would you like to move/copy this configuration to ~/nixos? [y/N]: " move_choice
        
        if [[ "$move_choice" =~ ^[Yy]$ ]]; then
            if [[ -d "$target_dir" ]]; then
                print_warning "Directory ~/nixos already exists"
                read -p "Overwrite? [y/N]: " overwrite_choice
                if [[ ! "$overwrite_choice" =~ ^[Yy]$ ]]; then
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
            read -p "Continue? [y/N]: " continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled"
                exit 1
            fi
        fi
    else
        print_success "✓ Configuration is in the correct location (~/nixos)"
        echo ""
    fi
}

# Function to check if running in a NixOS live environment
check_nixos_environment() {
    if [[ ! -f /etc/NIXOS ]]; then
        print_warning "This doesn't appear to be a NixOS system"
        read -p "Continue anyway? [y/N]: " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    local missing_deps=()
    
    if ! command -v nix &> /dev/null; then
        missing_deps+=("nix")
    fi
    
    if ! command -v awk &> /dev/null; then
        missing_deps+=("awk")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Function to perform a rebuild
perform_rebuild() {
    local hostname="$1"
    
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
    
    sudo nixos-rebuild boot --flake ".#$hostname"
    
    if [[ $? -eq 0 ]]; then
        echo ""
        print_success "═══════════════════════════════════════════════════"
        print_success "  System built successfully!"
        print_success "═══════════════════════════════════════════════════"
        echo ""
        print_info "Changes will take effect on next boot"
        echo ""
        
        # Countdown to reboot
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

# Main script
main() {
    clear
    
    print_debug "Starting main()"

    # Print banner
    print_banner
    
    # Check prerequisites
    print_debug "Checking prerequisites"
    check_prerequisites
    
    # Check environment
    print_debug "Checking NixOS environment"
    check_nixos_environment
    
    # Ensure correct location
    print_debug "Ensuring correct location"
    ensure_correct_location
    
    # Get available hosts
    print_info "Detecting available host configurations..."
    print_debug "Calling get_available_hosts()"
    mapfile -t available_hosts < <(get_available_hosts)
    print_debug "Hosts loaded: ${available_hosts[*]}"
    
    if [[ ${#available_hosts[@]} -eq 0 ]]; then
        print_error "No host configurations found"
        exit 1
    fi
    
    # Let user select a host
    selected_host=$(select_host "${available_hosts[@]}")
    
    # If default host selected, generate hardware configuration
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
            read -p "Continue anyway? [y/N]: " continue_hw >&2
            if [[ ! "$continue_hw" =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled"
                exit 1
            fi
        fi
    fi
    
    # Confirm before building
    echo "" >&2
    echo "You are about to build and install the '$selected_host' configuration." >&2
    echo "The system will reboot automatically after a successful build." >&2
    echo "" >&2
    read -p "Continue? [Y/n]: " confirm >&2
    
    # Default to yes if empty
    if [[ -n "$confirm" ]] && [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "" >&2
        print_error "Installation cancelled"
        exit 0
    fi
    
    # Update username in flake.nix to match current user
    current_user="$USER"
    print_debug "Current user: $current_user"
    
    if [[ -f "flake.nix" ]]; then
        print_info "Updating username in flake.nix to match current user ($current_user)..."
        # Create backup
        cp flake.nix flake.nix.bak
        # Replace the username line
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
    
    # Perform the rebuild
    perform_rebuild "$selected_host"
}

# Run main function
main "$@"
