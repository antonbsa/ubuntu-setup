# keybinding to remove entire previous word by CTRL+Backspace
bindkey '^H' backward-kill-word

# Codex variables for using vscode as external editor
export VISUAL="code --wait"
export EDITOR="code --wait"
export GIT_EDITOR=nano
export PATH="$HOME/.local/bin:$PATH"

# Display hostname on SSH connections
[[ -n $SSH_CONNECTION ]] && PROMPT='%B%F{green}%n@desktop%f%b:%B%F{blue}%~%f%b%(!.#.$) '
