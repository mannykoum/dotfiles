# dotfiles

A place for my dotfiles to call home

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Git](https://git-scm.com/)

## Installation

Clone the repo:

```bash
git clone git@github.com:mannykoum/dotfiles.git
cd dotfiles
```

### Using the helper script (recommended)

Install all packages (zsh, bash, git, nvim, tmux, starship, foot):

```bash
./install.sh all
```

Install a specific package:

```bash
./install.sh git         # only ~/.gitconfig
./install.sh zsh         # ~/.zshrc, ~/.zsh_aliases, etc.
./install.sh nvim        # ~/.config/nvim
./install.sh tmux        # ~/.config/tmux
./install.sh starship    # ~/.config/starship.toml
./install.sh foot        # ~/.config/foot
```

Add `-v` for verbose output.

### Manual GNU Stow usage

If you prefer to run stow yourself, use the correct target per package:

```bash
# Home-dotfiles packages
stow --dotfiles -t "$HOME" zsh
stow --dotfiles -t "$HOME" bash
stow --dotfiles -t "$HOME" git

# XDG config packages
stow -t "$HOME/.config/nvim" nvim
stow -t "$HOME/.config/tmux" tmux
stow -t "$HOME/.config"      starship
stow -t "$HOME/.config/foot" foot
```

## Packages

- zsh: links `~/.zshrc`, `~/.zsh_aliases` into `$HOME`.
- bash: links `~/.bashrc`, `~/.bash_aliases`, `~/.bash_functions` into `$HOME`.
- git: links `~/.gitconfig` into `$HOME`.
- nvim: links Neovim config into `~/.config/nvim`.
- tmux: links `tmux.conf` and bundled plugins into `~/.config/tmux`.
- starship: links `starship.toml` into `~/.config`.
- foot: links `foot.ini` into `~/.config/foot`.

### oh-my-zsh installation

Follow the instructions on the [Oh My Zsh](https://ohmyz.sh/#basic-installation)
website.

### Pure theme installation

I've chosen to install the pure theme “Oh‑My‑Zsh‑style” via the custom themes
directory:

1. **Clone into Oh‑My‑Zsh’s custom themes** folder:

   ```bash
   git clone https://github.com/sindresorhus/pure.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/pure"
   ```

2. **Symlink the theme file** so OMZ can find it:

   ```bash
   ln -s "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/pure/pure.zsh" \
         "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/pure/pure.zsh-theme"
   ```

3. **Set it as your theme** in `~/.zshrc`:

   ```bash
   ZSH_THEME="pure/pure"
   ```

4. **Reload**:

   ```bash
   source ~/.zshrc
   ```

## Uninstallation

Using the helper script:

```bash
cd dotfiles
./install.sh -u all             # uninstall all
./install.sh -u git             # uninstall only git
```

Manual with GNU Stow:

```bash
stow -D --dotfiles -t "$HOME" zsh bash git
stow -D -t "$HOME/.config/nvim" nvim
stow -D -t "$HOME/.config/tmux" tmux
stow -D -t "$HOME/.config"      starship
stow -D -t "$HOME/.config/foot" foot
```
