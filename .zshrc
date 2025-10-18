# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

export EDITOR="nvim"
export VISUAL="nvim"

export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

alias cat='bat'
alias cd="z"
alias ls="eza --icons=always"
alias v="nvim"
alias g="lazygit"

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export SDKROOT=$(xcrun --show-sdk-path)
export DEVELOPER_DIR="/Library/Developer/CommandLineTools"
export PATH="/Library/Developer/CommandLineTools/usr/bin:$PATH"
export CPPFLAGS="-I$SDKROOT/usr/include/c++/v1 -I$SDKROOT/usr/include"
export LDFLAGS="-L$SDKROOT/usr/lib -L/Library/Developer/CommandLineTools/usr/lib"
export PKG_CONFIG_PATH="$SDKROOT/usr/lib/pkgconfig:/Library/Developer/CommandLineTools/usr/lib/pkgconfig"
export LIBRARY_PATH="$SDKROOT/usr/lib:/Library/Developer/CommandLineTools/usr/lib"
export C_INCLUDE_PATH="$SDKROOT/usr/include"
export CPLUS_INCLUDE_PATH="$SDKROOT/usr/include/c++/v1:$SDKROOT/usr/include"

export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

SPACESHIP_PROMPT_ASYNC=true

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
