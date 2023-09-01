# profile zsh startup
# 加载zprof以后，使用`time  zsh -i -c exit` 来评估启动时间
# zmodload zsh/zprof

# powerlevel10k -- part1 {{{

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# }}}

# Shell Options {{{

setopt HIST_IGNORE_ALL_DUPS
setopt    appendhistory     #Append history to the history file (no overwriting)
setopt    sharehistory      #Share history across terminals
setopt    incappendhistory  #Immediately append to the history file, not just when a term is killed

# }}}

# Basic Environment Vars {{{

export ZSH_DISABLE_COMPFIX=true
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export EDITOR=nvim
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export RANGER_LOAD_DEFAULT_RC=false

# }}}

# Custom Configuration {{{

# rvm
[[ -s ~/.config/.zsh-utils/lazy-load-rvm.zsh ]] && source ~/.config/.zsh-utils/lazy-load-rvm.zsh

# yarn
export PATH="$PATH:$HOME/.yarn/bin"
export PATH="$PATH:$HOME/.config/yarn/global/node_modules/.bin"

# android
export JAVA_HOME="/Library/Java/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$JAVA_HOME/bin"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# pyenv
export PATH="$HOME/.pyenv/bin:$PATH"

# perl
PATH="/Users/andregeng/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/andregeng/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/andregeng/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/andregeng/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/andregeng/perl5"; export PERL_MM_OPT;

# fzf
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_R_OPTS='--reverse'

# stree
export PATH="$PATH:/Applications/SourceTree.app/Contents/Resources/stree"

# HomeBrew
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
# HomeBrew END
#
# nvm
NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# 添加ssh key到ssh-agent
ssh-add -A 1>/dev/null 2>&1

# }}}

# Custom Alias {{{

alias chrome="open -a 'Google Chrome'"
alias vi='nvim'
alias vim='nvim'
alias v='nvim .'
alias dvim=$'docker run -it -v $(pwd):/$(basename $(pwd)) andregeng/neovim /bin/bash -c "nvim -c \'cd /$(basename $(pwd))\' /$(basename $(pwd))"'
alias ovim='\vim'
alias mux='tmuxinator'
alias ctags="`brew --prefix`/bin/ctags"
alias proxy='export ALL_PROXY=http://127.0.0.1:1087'
alias unproxy='unset ALL_PROXY'
alias lg='lazygit'
alias work='mux work-local'
alias r='ranger'

# }}}

# zinit {{{

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-bin-gem-node

zinit ice svn multisrc"*.zsh" as"null"
zinit snippet OMZ::lib
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZ::plugins/vi-mode/vi-mode.plugin.zsh
zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh
zinit ice svn
zinit snippet OMZ::plugins/z
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit load zsh-users/zsh-syntax-highlighting
zinit load zsh-users/zsh-history-substring-search
zinit load wfxr/forgit
zinit load davidparsson/zsh-pyenv-lazy

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -e ~/fzf-addons/fzf-git.sh ]] && source ~/fzf-addons/fzf-git.sh

# binds Up and Down to a history search
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

### End of Zinit's installer chunk

# }}}

# Custom Plugin {{{

# z
unalias z 2> /dev/null
z() {
  [ $# -gt 0 ] && _z "$*" && return
  cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

# zsh-syntax-highlighting
# 颜色采用的是256色，@see https://jonasjacek.github.io/colors/
ZSH_HIGHLIGHT_STYLES[globbing]=fg=063

# zsh-syntax-highlighting
### Fix slowness of pastes with zsh-syntax-highlighting.zsh
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# }}}

# powerlevel10k -- part2 {{{

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# }}}

# zprof

# pnpm
export PNPM_HOME="/Users/admin/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end