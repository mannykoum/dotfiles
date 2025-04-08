#!/usr/bin/env bash

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
    echo "  package   The name of the dotfiles package to install or uninstall. Can be 'zsh', 'bash', 'nvim', 'tmux', or 'all'."
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

# Function to manage a package
manage_package() {
    local package=$1
    local target_dir=$2
    local action="stowing"
    local stow_cmd="stow --dotfiles"

    if [ $uninstall -eq 1 ]; then
        action="unstowing"
        stow_cmd="stow -D"
    fi

    if [ $verbose -eq 1 ]; then
        echo "$action $package into $target_dir"
    fi

    $stow_cmd ${verbose:+-v} -t "$target_dir" "$package"
}

# Main logic
for package in "$@"; do
    if [ "$package" = "all" ]; then
        manage_package "zsh" "$HOME"
        manage_package "bash" "$HOME"
        manage_package "nvim" "$HOME/.config/nvim"
        manage_package "tmux" "$HOME/.config/tmux"
        manage_package "starship" "$HOME/.config"
        break
    else
        case $package in
            zsh )
                manage_package "zsh" "$HOME"
                ;;
            bash )
                manage_package "bash" "$HOME"
                ;;
            nvim | tmux )
                manage_package "$package" "$HOME/.config/$package"
                ;;
            starship )
                manage_package "$package" "$HOME/.config"
                ;;
            * )
                echo "Unknown package: $package" >&2
                exit 1
                ;;
        esac
    fi
done

