#!/usr/bin/env bash

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Function to display help
show_help() {
    echo "Usage: $0 [-h] [-v] [-u] package1 [package2 ...]"
    echo
    echo "Options:"
    echo "  -h        Display this help message and exit."
    echo "  -v        Enable verbose output."
    echo "  -u        Uninstall the specified dotfiles package(s)."
    echo
    echo "Arguments:"
    echo "  package   The name of the dotfiles package to install or uninstall. Can be 'zsh', 'bash', 'git', 'nvim', 'tmux', 'starship', 'foot', 'hypr', 'pi', or 'all'."
    echo
    echo "Example:"
    echo "  $0 -v -u all     Uninstall all dotfiles packages with verbose output."
}

# Variables
verbose=0
uninstall=0
packages=()

# Parse command-line options
while getopts "hvu" opt; do
    case ${opt} in
        h )
            show_help
            exit 0
            ;;
        v )
            verbose=1
            ;;
        u )
            uninstall=1
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Check if no package is specified
if [ $# -eq 0 ]; then
    echo "Error: No packages specified." >&2
    show_help
    exit 1
fi

# Initialize package submodules when installing from a non-recursive clone.
ensure_submodule() {
    local package=$1

    if [ "$uninstall" -eq 0 ] &&
       git -C "$DOTFILES_DIR" config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null |
           awk '{print $2}' | grep -Fqx -- "$package"; then
        git -C "$DOTFILES_DIR" submodule update --init --recursive -- "$package"
    fi
}

# Function to manage a package
manage_package() {
    local package=$1
    local target_dir=$2
    local action="stowing"
    local -a stow_cmd=(stow --dotfiles --dir "$DOTFILES_DIR")

    # Pi keeps credentials, sessions, and package caches beside linked config.
    # Prevent Stow from folding ~/.pi or ~/.agents into repository symlinks.
    if [ "$package" = "pi" ]; then
        stow_cmd+=(--no-folding)
    fi

    if [ "$uninstall" -eq 1 ]; then
        action="unstowing"
        stow_cmd+=(-D)
    else
        ensure_submodule "$package"
    fi

    if [ "$verbose" -eq 1 ]; then
        echo "$action $package into $target_dir"
        stow_cmd+=(-v)
    fi

    "${stow_cmd[@]}" --target "$target_dir" "$package"
}

# Main logic
for package in "$@"; do
    if [ "$package" = "all" ]; then
        manage_package "zsh" "$HOME"
        manage_package "bash" "$HOME"
        manage_package "git" "$HOME"
        manage_package "nvim" "$HOME/.config/nvim"
        manage_package "tmux" "$HOME/.config/tmux"
        manage_package "starship" "$HOME/.config"
        manage_package "foot" "$HOME/.config/foot"
        manage_package "hypr" "$HOME/.config/hypr"
        manage_package "waybar" "$HOME/.config/waybar"
        manage_package "himalaya" "$HOME/.config/himalaya"
        manage_package "aerc" "$HOME/.config/aerc"
        manage_package "pi" "$HOME"
        break
    else
        case $package in
            zsh | bash | git | pi )
                manage_package "$package" "$HOME"
                ;;
            nvim | tmux | himalaya | foot | aerc )
                manage_package "$package" "$HOME/.config/$package"
                ;;
            starship )
                manage_package "$package" "$HOME/.config"
                ;;
            hypr )
                manage_package "$package" "$HOME/.config/hypr"
                manage_package "waybar" "$HOME/.config/waybar"
                ;;
            * )
                echo "Unknown package: $package" >&2
                exit 1
                ;;
        esac
    fi
done
