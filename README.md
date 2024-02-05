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

## Uninstallation
```bash
cd dotfiles
stow -t ~ -D *
```
