#!/bin/zsh

# Zsh script to install useful Rust-based command-line tools via cargo.
# It includes an interactive mode to confirm installation for each tool.

# --- Notes on Tool Selection ---
# The following tools from the user's list are NOT included for 'cargo install':
# - Fish: Shell, typically installed via system package managers.
# - Espanso: Text expander, 'cargo install' is generally not the recommended method for full functionality.
#
# Assumption:
# - "evil-helix" is assumed to be the Helix editor (package: "helix", command: "hx").
#
# Potential Issues:
# - ncspot: May require system dependencies for audio (e.g., libasound2-dev or pulseaudio-dev).
# - cargo-info: This is a cargo subcommand. The script checks for 'cargo help info'.

# --- Configuration: List of Rust Tool Packages ---
# Add or remove cargo package names from this list as needed.
rust_tool_packages=(
  "nu"            # Nushell
  "ripgrep"
  "fd-find"
  "bat"
  "eza"           # Modern replacement for 'ls'
  "zoxide"
  "xh"            # HTTP client (alternative to httpie)
  "zellij"        # Terminal multiplexer
  "gitui"         # Terminal UI for git
  "du-dust"       # More intuitive 'du'
  "dua-cli"       # Disk usage analyzer
  "starship"
  "yazi-fm"       # Terminal file manager
  "hyperfine"
  "helix"         # Modal text editor (assuming "evil-helix")
  "bacon"         # Background Rust code checker
  "cargo-info"    # Cargo subcommand to display info about a crate
  "fselect"       # Find files with SQL-like queries
  "ncspot"        # Ncurses Spotify client
  "rusty-man"     # Faster 'man'
  "git-delta"     # Syntax-highlighting pager for git/diff
  "ripgrep_all"   # Ripgrep for various file types (PDFs, docs, etc.)
  "tokei"         # Code statistics
  "wiki-tui"      # Wikipedia TUI
  "just"          # Command runner
  "mask"          # CLI task runner using markdown
  "mprocs"        # Run multiple commands in parallel
  "presenterm"    # Terminal slideshow tool
  "kondo"         # Project artifact cleaner
  "bob-nvim"      # Neovim version manager
  "rtx-cli"       # Polyglot version manager (now superseded by 'mise')
)

# --- Mapping: Cargo Package Name to Command Name (if different) ---
declare -A tool_command_map
tool_command_map=(
  [ripgrep]="rg"
  [fd-find]="fd"
  [du-dust]="dust"
  [dua-cli]="dua"
  [yazi-fm]="yazi"
  [helix]="hx"
  [git-delta]="delta"
  [ripgrep_all]="rga"
  [bob-nvim]="bob"
  [rtx-cli]="rtx"
)
# For 'bat', special handling for 'bat' vs 'batcat' is in check_and_install_tool.
# For 'cargo-info', special handling for 'cargo help info' is in check_and_install_tool.
# For others not in this map, package name is assumed to be the command name.

# --- Helper Functions ---

print_message() {
  echo "----------------------------------------"
  echo "$1"
  echo "----------------------------------------"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

check_and_install_tool() {
  local tool_package_name="$1"
  # Derive the command name to check, using the map or defaulting to package name
  local tool_command_to_check="${tool_command_map[$tool_package_name]:-$tool_package_name}"
  local display_command_name="$tool_command_to_check" # For user messages

  # Special handling for command existence checks
  if [[ "$tool_package_name" == "cargo-info" ]]; then
    if cargo help info >/dev/null 2>&1; then # Check if 'cargo info' is a known subcommand
        print_message "'cargo info' (from package '$tool_package_name') seems to be available."
        return 0
    fi
    display_command_name="cargo info (subcommand)" # For display purposes
  elif [[ "$tool_package_name" == "bat" ]]; then
    if command_exists "bat"; then
        print_message "'bat' is already installed."
        return 0
    elif command_exists "batcat"; then # Check for batcat if bat isn't found
        print_message "'batcat' (often an alias for 'bat') is already installed."
        echo "You might want to add 'alias bat=batcat' to your .zshrc if not already done."
        return 0
    fi
    # If neither 'bat' nor 'batcat' exists, display_command_name remains 'bat' for the prompt
  elif command_exists "$tool_command_to_check"; then
    print_message "'$tool_command_to_check' (from package '$tool_package_name') is already installed."
    return 0
  fi

  # Ask for confirmation in interactive mode
  if [[ "$interactive_mode" == "true" ]]; then
    read -r -k1 "reply?Install '$tool_package_name' (provides: $display_command_name)? (y/N): "
    echo # Move to a new line after input
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      print_message "Skipping '$tool_package_name'."
      return 1 # Skipped
    fi
  fi

  print_message "Installing '$tool_package_name' (provides: $display_command_name)..."
  if cargo install "$tool_package_name" --locked; then
    print_message "'$tool_package_name' installed successfully."
    # Special instructions after install
    if [[ "$tool_package_name" == "starship" ]]; then
        echo "To use Starship, add the following to the end of your ~/.zshrc:"
        echo 'eval "$(starship init zsh)"'
    elif [[ "$tool_package_name" == "zoxide" ]]; then
        echo "To use zoxide, add the following to the end of your ~/.zshrc:"
        echo 'eval "$(zoxide init zsh)"'
    elif [[ "$tool_package_name" == "nu" ]]; then
        echo "Nushell (nu) is installed. You can start it by typing 'nu'."
    elif [[ "$tool_package_name" == "rtx-cli" ]]; then
        echo "rtx is installed. To activate it, you might need to add to your ~/.zshrc:"
        echo 'eval "$(rtx activate zsh)"'
        echo "Note: rtx has been succeeded by 'mise'. Consider checking out 'mise'."
    elif [[ "$tool_package_name" == "ncspot" ]]; then
        echo "ncspot installed. If you encounter audio issues, you may need to install system libraries"
        echo "such as libasound2-dev (for ALSA) or libpulse-dev (for PulseAudio)."
    elif [[ "$tool_package_name" == "bat" ]] && ! command_exists "bat" && command_exists "batcat"; then
        echo "Note: '$tool_package_name' was installed as 'batcat'. You may need to alias it in your ~/.zshrc:"
        echo "  alias bat='batcat'"
    fi
    if [[ "$tool_package_name" == "starship" || "$tool_package_name" == "zoxide" || "$tool_package_name" == "rtx-cli" ]]; then
        echo "Then, source your .zshrc (source ~/.zshrc) or open a new terminal."
    fi
  elif cargo install "$tool_package_name"; then
    print_message "'$tool_package_name' installed successfully."
  else
    print_message "Failed to install '$tool_package_name'. Check for errors."
    return 2 # Failed
  fi
  return 0 # Success
}

# --- Main Script ---

if ! command_exists "cargo"; then
  print_message "Cargo is not installed. Please install Rust and Cargo first."
  echo "Visit https://www.rust-lang.org/tools/install for instructions."
  exit 1
fi

interactive_mode="true"
if [[ "$1" == "--non-interactive" || "$1" == "-y" ]]; then
  interactive_mode="false"
  print_message "Running in non-interactive mode. Will attempt to install all configured tools."
fi

if [[ "$interactive_mode" == "true" ]]; then
    print_message "Rust Tool Installer (Interactive Mode)"
    echo "You will be prompted to install each tool."
    echo "Press 'y' to install, any other key (or Enter) to skip."
    echo "Tools listed as 'already installed' or 'available' will be skipped automatically."
    echo ""
fi

if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
  print_message "Warning: $HOME/.cargo/bin is not in your PATH."
  echo "You might need to add 'export PATH=\"\$HOME/.cargo/bin:\$PATH\"' to your ~/.zshrc"
  echo "Then, source your .zshrc or open a new terminal for installed tools to be found."
  if [[ "$interactive_mode" == "true" ]]; then
    read -r -k1 "reply_path?Continue anyway? (y/N): "
    echo
    if [[ ! "$reply_path" =~ ^[Yy]$ ]]; then
      print_message "Exiting."
      exit 1
    fi
  fi
fi

successful_installs=0
failed_installs=0
skipped_by_user=0 # Explicitly skipped by user in interactive mode
already_installed=0 # Found to be already installed

for tool_pkg in "${rust_tool_packages[@]}"; do
  # Store original status (does command exist before trying to install)
  # This is a bit complex because check_and_install_tool also prints "already installed"
  # The return codes will help differentiate: 0=success/already_installed, 1=skipped, 2=failed
  
  # Temporarily capture output of check for "already installed" to avoid double counting later
  # Simpler: check_and_install_tool handles printing "already installed" and returns 0.
  # If it returns 0 and we didn't prompt (or user said yes), it's a successful action (either new install or was present).
  # If it returns 1, it was skipped by user.
  # If it returns 2, it failed.

  # First, check if it's already installed without triggering the full function's interactivity for this specific count
  initial_command_name="${tool_command_map[$tool_pkg]:-$tool_pkg}"
  is_already_present=false
  if [[ "$tool_pkg" == "cargo-info" ]]; then
    if cargo help info >/dev/null 2>&1; then is_already_present=true; fi
  elif [[ "$tool_pkg" == "bat" ]]; then
    if command_exists "bat" || command_exists "batcat"; then is_already_present=true; fi
  elif command_exists "$initial_command_name"; then
    is_already_present=true
  fi

  if $is_already_present && [[ "$interactive_mode" == "true" ]]; then # If interactive and already there, just inform and count.
      display_name="$initial_command_name"
      if [[ "$tool_pkg" == "cargo-info" ]]; then display_name="cargo info"; fi
      if [[ "$tool_pkg" == "bat" ]] && ! command_exists "bat" && command_exists "batcat"; then display_name="bat (as batcat)"; fi
      print_message "'$display_name' (from package '$tool_pkg') is already installed."
      ((already_installed++))
      reply="" # Clear reply from previous tool
      continue # Move to next tool
  fi

  # If not already present or in non-interactive mode, proceed with check_and_install_tool
  check_and_install_tool "$tool_pkg"
  install_status=$?
  
  if [[ "$install_status" -eq 0 ]]; then # Success or was already present (and handled by function)
    # If it was already present and we got here, it means non-interactive mode.
    if $is_already_present; then
        ((already_installed++))
    else
        ((successful_installs++))
    fi
  elif [[ "$install_status" -eq 1 ]]; then # Skipped by user
    ((skipped_by_user++))
  elif [[ "$install_status" -eq 2 ]]; then # Failed
    ((failed_installs++))
  fi
  reply="" # Reset reply for the main loop's context if it was set inside function
  echo "" 
done

print_message "Installation Summary"
echo "New tools installed: $successful_installs"
echo "Already installed/available: $already_installed"
if [[ "$interactive_mode" == "true" ]]; then
  echo "Skipped by user: $skipped_by_user"
fi
echo "Failed to install: $failed_installs"

if (( failed_installs > 0 )); then
  echo "Some tools failed to install. Please check the output above for errors."
fi

print_message "Script finished."
echo "Remember to source your ~/.zshrc or open a new terminal if any tools required shell configuration (e.g., starship, zoxide, rtx)."

