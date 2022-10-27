# source bash prompt
source ~/.bash/bash_prompt

# Source bash aliases
source ~/.bash/bash_aliases

# Source bash functions
source ~/.bash/bash_functions

# Source Command not found
source /usr/share/doc/pkgfile/command-not-found.bash

# Env
export TERM=xterm-256color
export EDITOR=vim
[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || export QT_QPA_PLATFORMTHEME="qt5ct"

#Drop into fish
#if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} ]]
#then
#	exec fish
#fi

#Go Path
export GOPATH=/home/andro/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GOROOT=/usr/lib/go/src

# Show system information at login
if [ -t 0 ]; then
    if type -p "fastfetch" > /dev/null; then
        fastfetch
    else
        echo "Warning: fastfetch was called, but it's not installed."
    fi
fi

# Don't add duplicate lines or lines beginning with a space to the history
HISTCONTROL=ignoreboth

# Set history format to include timestamps
HISTTIMEFORMAT="%Y-%m-%d %T "

# Correct simple errors while using cd
shopt -s cdspell

# complete command names and file names
complete -cf sudo

# Auto cd when just entering path
shopt -s autocd

#Line wrap on window resize
shopt -s checkwinsize

# Mimic zsh run-help ability
run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }
bind -m vi-insert -x '"\eh": run-help'
bind -m emacs -x     '"\eh": run-help'

# Add /home/$USER/bin to $PATH
case :$PATH: in
	*:/home/$USER/bin:*) ;;
	*) PATH=/home/$USER/bin:$PATH ;;
esac

# Add /home/$USER/.local/bin to $PATH
case :$PATH: in
	*:/home/$USER/.local/bin:*) ;;
	*) PATH=/home/$USER/.local/bin:$PATH ;;
esac

# Add /home/$USER/andro-env/bin to $PATH
case :$PATH: in
	*:/home/$USER/andro-env:*) ;;
	*) PATH=/home/$USER/andro-env:$PATH ;;
esac

# exports
export PATH="${HOME}/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:"
export PATH="${PATH}/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:"



# Enable tab completion for tmux
source /home/andro/.tmux/plugins/completion/tmux

# Add /home/$USER/.tmux/tmuxifier to $PATH
case :$PATH: in
	*:/home/$USER/.tmux/tmuxifier/bin:*) ;;
	*) PATH=/home/$USER/.tmux/tmuxifier/bin:$PATH ;;
esac

# Safetynets
# do not delete / or prompt if deleting more than 3 files at a time #
alias rm='rm -I --preserve-root'

# confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias magic='sudo /usr/local/bin/magic.sh'

# Parenting changing perms on / #
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# reload bash config
alias reload="source ~/.bashrc"

