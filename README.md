# dotfiles

A place for my dotfiles to call home

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Git](https://git-scm.com/)

## Installation

```bash
git clone git@github.com:mannykoum/dotfiles.git
cd dotfiles
stow -t ~ *
```

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

```bash
cd dotfiles
stow -t ~ -D *
```
