# Setup fzf
# ---------
if [[ ! "$PATH" == */home/manos/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/manos/.fzf/bin"
fi

source <(fzf --zsh)
