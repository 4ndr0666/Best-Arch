#!/usr/bin/env bash
# Author: 4ndr0666
iatest=$(expr index "$-" i)
# ========================== // BASHRC ROOT //


## Kill if non-interactive

[[ $- != *i* ]] && return

## Path

if [ -d "/home/git/clone/scr" ] ;
then PATH="$PATH:$(find /home/git/clone/scr -type d | paste -sd ':' -)$PATH"
fi

export PATH=$PATH:"$HOME/.local/bin:$HOME/.cargo/bin:/var/lib/flatpak/exports/bin:/.local/share/flatpak/exports/bin"









## Fast fetch if non-interactive

if command -v fastfetch &> /dev/null; then
    if [[ $- == *i* ]]; then
        fastfetch
    fi

## Source global definitions

if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
[[ -f /home/andro/.config/shell/functions/functionsrc ]] || source "/home/andro/.config/shell/functions/functionsrc" 2>/dev/null/
[[ -f /home/andro/.config/shell/aliasrc ]] || source "/home/andro/.config/shell/aliasrc"

## Bash completion

if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

## Colors

export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

## Prompt

PS1='[\u@\h \W]\$💀 '
alias 00='cat $USER/.bashrc'
alias 0f='cat $USER/.zshrc'

## Disable the bell

if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi



## History

export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T" # add timestamp to history
export HISTCONTROL=erasedups:ignoredups:ignorespace
shopt -s checkwinsize
shopt -s histappend
PROMPT_COMMAND='history -a'

### Search command line history

alias h="history | grep "

## XDG

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"


shopt -s cdspell
complete -cf 
shopt -s autocd
shopt -s checkwinsize

## History widget
### ctrl+s for history nav (with ctrl-R)
[[ $- == *i* ]] && stty -ixon

## Autocompletion
### Ignore case
if [[ $iatest -gt 0 ]]; then bind "set completion-ignore-case on"; fi

### Show list without double tap
if [[ $iatest -gt 0 ]]; then bind "set show-all-if-ambiguous On"; fi
## Ripgrep


if command -v rg &> /dev/null; then
    ### Alias grep to rg if ripgrep is installed
    alias grep='rg'
else
    ### Alias grep to /usr/bin/grep with GREP_OPTIONS if ripgrep is not installed
    alias grep="/usr/bin/grep $GREP_OPTIONS"
fi
unset GREP_OPTIONS




## COLOR_TERM

if [ "$TERM" = "linux" ]; then
	printf %b '\e]P01E1E2E' # set background color to "Base"
	printf %b '\e]P8585B70' # set bright black to "Surface2"

	printf %b '\e]P7BAC2DE' # set text color to "Text"
	printf %b '\e]PFA6ADC8' # set bright white to "Subtext0"

	printf %b '\e]P1F38BA8' # set red to "Red"
	printf %b '\e]P9F38BA8' # set bright red to "Red"

	printf %b '\e]P2A6E3A1' # set green to "Green"
	printf %b '\e]PAA6E3A1' # set bright green to "Green"

	printf %b '\e]P3F9E2AF' # set yellow to "Yellow"
	printf %b '\e]PBF9E2AF' # set bright yellow to "Yellow"

	printf %b '\e]P489B4FA' # set blue to "Blue"
	printf %b '\e]PC89B4FA' # set bright blue to "Blue"

	printf %b '\e]P5F5C2E7' # set magenta to "Pink"
	printf %b '\e]PDF5C2E7' # set bright magenta to "Pink"

	printf %b '\e]P694E2D5' # set cyan to "Teal"
	printf %b '\e]PE94E2D5' # set bright cyan to "Teal"

	clear
fi

## Autoset $DISPLAY

if [ -z "$DISPLAY" ]; then
	if which loginctl &>/dev/null; then
		LOGINCTL_SESSION=$(loginctl show-user $USER -p Display 2>/dev/null | cut -d= -f2)
		if [ -n "$LOGINCTL_SESSION" ]; then
			export DISPLAY=$(loginctl show-session $LOGINCTL_SESSION -p Display | cut -d= -f2)
		fi
	fi
	if which ck-list-sessions &>/dev/null; then
		eval `ck-list-sessions | awk "/^Session/{right=0} /unix-user = '$UID'/{right=1} /x11-display = '(.+)'/{ if(right == 1) printf(\"DISPLAY=%s\n\", \\\$3); }";`
	fi
fi

# --- // IBUS_SETTINGS_(enter $ibus-setup in term):
#export GTK_IM_MODULE=ibus
#export XMODIFIERS=@im=dbus
#export QT_IM_MODULE=ibus

## ESCALATE_COMMANDS:
for cmd in pacman-key ufw mount umount pacman updatedb su systemctl useradd userdel groupadd groupdel chown chmod btrfs ip netstat modprobe; do
    alias $cmd="sudo $cmd && echo 'Executed $cmd on \$(date)' >> /var/log/user_commands.log"
done

## Ls Configs

alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -ltcrh'              # sort by change time
alias lu='ls -lturh'              # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              # alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | egrep '^d'"   # directories only
alias lla='ls -Al'                # List and Hidden Files
alias las='ls -A'                 # Hidden Files
alias lls='ls -l'                 # List
alias lf="lfub" 
#alias ls='ls --color=auto'
#alias la='ls -a'
#alias ll='ls -alFh'
#alias l='ls'
#alias l.="ls -A | egrep '^\.'"
#alias listdir="ls -d */ > list"

## Eza version

#alias ls='exa -al --color=always --group-directories-first --icons' # preferred listing
#alias la='exa -a --color=always --group-directories-first --icons'  # all files and dirs
#alias ll='exa -l --color=always --group-directories-first --icons'  # long format
#alias lt='exa -aT --color=always --group-directories-first --icons' # tree listing
#alias l.='exa -ald --color=always --group-directories-first --icons .*' # show only dotfiles

## System info

### Search files in the current folder

alias f="find . | grep "

### To see if a command is aliased, a file, or a built-in command

alias checkcommand="type -t"

### Show open ports

alias openports='netstat -nape --inet'

## FORCE_NEOVIM

if command -v nvim > /dev/null 2>&1; then
    alias vim="nvim"
    alias vimdiff="nvim -d"
else
    echo "nvim not found, falling back to vim if available"
    command -v vim > /dev/null 2>&1 || { echo "vim also not found. Please install a text editor."; return 1; }
fi

alias svim="sudo nvim"

alias vim="nvim"

## 4ndr0edit

alias valias='nvim /home/andro/.config/shell/aliasrc'
alias vfunc='nvim /home/andro/.config/shell/functions/functionsrc'
alias vpac='nvim /etc/pacman.conf'
alias vgrub='nvim /etc/default/grub'
alias vgrubc='nvim /boot/grub/grub.cfg'
alias vmkinit='nvim /etc/mkinitcpio.conf'
alias vmirror='nvim /etc/pacman.d/mirrorlist'
alias vchaotic='nvim /etc/pacman.d/chaotic-mirrorlist'
alias vfstab='nvim /etc/fstab'
alias vnsswitch='nvim /etc/nsswitch.conf'
alias vsmb='nvim /etc/samba/smb.conf'
alias vgpg='nvim /etc/pacman.d/gnupg/gpg.conf'
alias vhosts='nvim /etc/hosts'
alias vhostname='nvim /etc/hostname'
alias vb='nvim ~/.bashrc'
alias vz='nvim ~/.zshrc'
alias vf='nvim ~/.config/fish/config.fish'
alias vmvp='nvim /home/andro/.config/mpv/mpv.conf'

## 4ndr0nav 

goto() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        cd "$dir"
    else
        echo "Directory not found: $dir"
    fi
}

###//$User

alias dc='goto ~/Documents'
alias dl='goto ~/Downloads'
alias conf='goto ~/.config'
alias ob='goto ~/.config/openbox'
alias obt='goto ~/.config/openbox/themes'
alias hyp='goto ~/.config/hypr'
alias lbin='goto ~/.local'
alias lshare='goto ~/.local/share/'

###//23.1

alias 23='goto /23.1'
alias cloud='goto /23.1/Thecloud'

###//Nas

alias nas='goto /Nas/'
alias nbin='goto /Nas/Build/git/syncing/scr'
alias nnas='goto /Nas/Build/git/syncing/nas'
alias ngpt='goto /Nas/Build/git/syncing/gpt'
alias ngc='goto /Nas/Build/git/clone'
alias ngl='goto /Nas/Build/git/local'
alias npkg='goto /Nas/Build/pkgs'
alias npro='goto /Nas/Build/projects'
alias ndot='goto /Nas/Build/git/clone/dotfiles'

###//System

alias et='goto /etc'
alias ske='goto /etc/skel'
alias bin='goto /usr/local/bin'
alias loc='goto ~/.local'
alias roo='goto /root/'
alias shellzsh='goto ~/.config/shellz'
alias shellbash='goto ~/.config/shell'

## General

alias cd='cd -P'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias p='pacman'
alias cp='cp -i'
alias mv='mv -i'
if command -v trash &> /dev/null; then
    alias rm='trash -v'
else
    alias rm='rm -i'  # fallback to interactive remove
fi
alias mkdir='mkdir -p'


alias rg="rg --sort path"
alias diff='diff --color=auto'
alias rmdir='rm -vI --preserve root'
alias ln='ln -iv'
alias bc='bc -ql'

alias wget="wget --hsts-file='$XDG_DATA_HOME/wget-hsts'"
alias curl="curl --user-agent 'noleak'"
alias df='df -h --exclude-type=squashfs --exclude-type=tmpfs --exclude-type=devtmpfs'
alias cat='bat --number --style snip --style changes --style header'
alias rsync='rsync -vrPlu'
alias grub-mkconfig='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
#alias ccat='highlight --out-format=ansi'
alias ip='ip -color=auto'
alias c='clear; echo; echo; seq 1 $(tput cols) | sort -R | spark | lolcat; echo; echo'
alias hw='hwinfo --short'
alias psa='ps auxf | less'
alias free='free -mt'
alias jctl='journalctl -p 3 -xb'
alias g='git'
alias gstat='git status'
alias grh="git reset --hard"
alias gfs="git-lfs"
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'
alias cpu="cpuid -i | grep uarch | head -n 1"
# ======================================================== // UNIQUE_ALIASES //
alias kernel="ls /usr/lib/modules"
alias kernels="ls /usr/lib/modules"
alias bls="betterlockscreen -u /usr/share/backgrounds/"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias burnit='echo "sudo dd bs=4M if=path/to/.iso of=/dev/sdX status=progress oflag=sync"'
alias list="xclip -o | tr '\n' ' ' | sed 's/ $/\n/' | xclip -selection c"
alias splitlist="xclip -o | tr ',' '\n'"
alias dir5='du -cksh * | sort -hr | head -5'
alias dir10='du -cksh * | sort -hr | head -10'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias reload="source ~/.bashrc"
alias magic='sudo /usr/local/bin/magic.sh'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'
alias bd='cd "$OLDPWD"'

alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl"
alias gitpkg="pacman -Q | grep -i '\-git' | wc -l"
alias pkgbysize="expac -Q '%m - %n %v' | sort -n -r"
alias mkpkglist='bat /tmp/pacui-ls'
alias cleanpacman="sudo find /var/cache/pacman/pkg/ -iname '*.part' -delete"
alias jctl="journalctl -p 3 -xb"
alias fix-keyserver="[ -d ~/.gnupg ] || mkdir ~/.gnupg ; cp /etc/pacman.d/gnupg/gpg.conf ~/.gnupg/ ; echo 'done'"
alias fix-permissions="sudo chown -R $USER:$USER ~/.config ~/.local"
alias toboot="sudo /usr/local/bin/arcolinux-toboot"
alias togrub="sudo /usr/local/bin/arcolinux-togrub"
alias tolightdm="sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm --needed ; sudo systemctl enable lightdm.service -f ; echo 'Lightm is active - reboot now'"
alias tosddm="sudo pacman -S sddm --noconfirm --needed ; sudo systemctl enable sddm.service -f ; echo 'Sddm is active - reboot now'"
alias toly="sudo pacman -S ly --noconfirm --needed ; sudo systemctl enable ly.service -f ; echo 'Ly is active - reboot now'"
alias togdm="sudo pacman -S gdm --noconfirm --needed ; sudo systemctl enable gdm.service -f ; echo 'Gdm is active - reboot now'"
alias tolxdm="sudo pacman -S lxdm --noconfirm --needed ; sudo systemctl enable lxdm.service -f ; echo 'Lxdm is active - reboot now'"
alias back='cd "$OLDPWD"'
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias watch='watch '
alias lock='sudo chattr +i '
alias unlock='sudo chattr -i '

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"



### Count all files (recursively) in the current folder
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

#alias lsfiles='find $PWD -type f | wc -l'
#alias lsmount='mount |column -t'# Count or list files in the current directory
lsfiles() {
    if [[ "$1" == "-l" ]]; then
        echo "Files in $PWD:"
        find $PWD -type f
    else
        echo "Total files in $PWD: $(find $PWD -type f | wc -l)"
    fi
}

# Improved mount listing with optional filtering
lsmount() {
    if [[ -n "$1" ]]; then
        mount | column -t | grep "$1"
    else
        mount | column -t
    fi
}

alias fixkeyboard='sudo localectl set-x11-keymap us'
alias fixpacman='sudo unlink /var/lib/pacman/db.lck'
alias fixpacman2='sudo unlink /var/cache/pacman/pkg/cache.lck'
alias magic='sudo /usr/local/bin/magic.sh'
alias listusers='cut -d: -f1 /etc/passwd | sort'
alias unhblock='hblock -S none -D none'
alias audio="pactl info | grep 'Server Name'"
alias mapit="ifconfig -a | grep -Po '\b(?!255)(?:\d{1,3}\.){3}(?!255)\d{1,3}\b' | xargs nmap -A -p0-"
alias ports='netstat -tulanp'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias netspeed='ifstat -t -S -w'
alias iotop='sudo iotop -o'
alias netwatch='sudo nethogs'
alias mirrorsite='wget -m -k -K -E -e robots=off'
alias mirrors='sudo reflector --latest 10 --age 2 --fastest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorl
ist'
alias oint='foot -e "$@" &>/dev/null &'



# --- // EXPRESSVPN //
alias vpnc='expressvpn connect'
alias vpnd='expressvpn disconnect'
alias vpns='expressvpn status'
alias vpnr='expressvpn refresh'
alias vpna='autoconnect true'
alias vpnset='expressvpn preferences set '
alias vpnblock='expressvpn preferences set block_all false'  
alias vpnlight='expressvpn protocol lightway_udp'
alias vpnauto='expressvpn protocol auto'
alias vpnv6='expressvpn preferences set ipv6_protection false'
alias vpnlock='expressvpn preferences set network_lock strict'
alias vpncipher='expressvpn preferences set lightway_cipher auto'


# --- // DISPLAY //
alias xd='ls /usr/share/xsessions'
alias xdw="ls /usr/share/wayland-sessions"
alias xfix="echo 'DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xterm'"
alias xi='sudo xbps-install'
alias xr='sudo xbps-remove -R'
alias xq='xbps-query'
alias xmerge='xrdb -merge ~/.Xresources'
alias parupdate="paru -Syu --noconfirm"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixgrubefi='sudo grub-mkconfig -o /boot/grub/grub.cfg && sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi'
#get fastest mirrors in your neighborhood
alias mirrors="sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist"

# --- // YTDL:
alias ytt='yt --skip-download --write-thumbnail'
alias YT='youtube-viewer'
alias yta='yt -x -f bestaudio/best'
ytdl() {
  yt-dlp --add-metadata \
         --embed-metadata \
         --external-downloader aria2c \
         --external-downloader-args "-c -j 3 -x 3 -s 3 -k 1M" \
         -f "315/308/303/302/299/298/247/136/135/134+bestaudio[acodec^=opus]/best" \
         --merge-output-format mkv \
         --no-playlist \
         --no-mtime \
         "$@"
}
alias sdn="echo 'Shutting down...' | sudo tee -a /var/log/user_commands.log && sudo shutdown -h now"
alias ssr="echo 'Rebooting...' | sudo tee -a /var/log/user_commands.log && sudo reboot -h now"
alias fixdirmngr='sudo dirmngr </dev/null'

# ======================================================= // BASIC_FUNCTIONS //
# --- // Sudo:
#sudo_func() {
#    sudo -v
#    sudo "$@"
#}
gclone() {
    git clone --depth 1 "$@" && \
      cd -- "$(basename "$1" .git)" || exit
}

# --- // Git_add_all/commit_all/comment/pull/push:
gcomp() {
    git add .
    git commit -m "$*"
    git pull
    git push
}

# --- // Git_add_all/commit/comment:
gcom() {
    git add .
    git commit -m "$1" -a
}

## Permissions

alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

## Shell

if alias tobash &>/dev/null; then
    unalias tobash
fi

if alias tozsh &>/dev/null; then
    unalias tozsh
fi

if alias tofish &>/dev/null; then
    unalias tofish
fi

tobash() {
    sudo $chsh -s "$(which bash)" && echo 'Now log out.'
}

tozsh() {
    sudo $chsh -s "$(which zsh)" && echo 'Now log out.'
}

tofish() {
    sudo $chsh -s "$(which fish)" && echo 'Now log out.'
}

## Custom functions

### Searches for text in all files in the current folder
ftext() {
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

### Copy file with a progress bar
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

### Copy and go to the directory
cpg() {
	if [ -d "$2" ]; then
		cp "$1" "$2" && cd "$2"
	else
		cp "$1" "$2"
	fi
}

### Move and go to the directory
mvg() {
	if [ -d "$2" ]; then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

### Create and go to the directory
mkg() {
	mkdir -p "$1"
	cd "$1"
}

### Goes up a specified number of directories  (i.e. up 4)
up() {
	local d=""
	limit=$1
	for ((i = 1; i <= limit; i++)); do
		d=$d/..
	done
	d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd $d
}

### Automatically do an ls after each cd, z, or zoxide
#cd ()
#{
#	if [ -n "$1" ]; then
#		builtin cd "$@" && ls
#	else
#		builtin cd ~ && ls
#	fi
#}

### Returns the last 2 fields of the working directory
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

## Trim leading and trailing spaces (for scripts)

trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}

whatdependson()  {
    search=$(echo "$1")
    sudo pacman -Sii $search | grep "Required" | sed -e "s/Required By     : //g" | sed -e "s/  /\n/g"
    }

## Make_an_archived_backup
f() {
    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Please provide a file or directory to back up."
        return 1
    fi
    tar -czvf "${target##*/}_$(date -u "+%h-%d-%Y_%H.%M%p")_backup.tar.gz" "$target"
}

## Move_up_1_directory

up() { for _ in $(seq "${1:-1}"); do cd ..; done; }

## All_port80_connections

function con80() {
  {
    LANG= ss -nat || LANG= netstat -nat
  } | grep -E ":80[^0-9]" | wc -l
}

## Arhive aliases

alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

## Extract_Archives

#extract() {
#	for archive in "$@"; do
#		if [ -f "$archive" ]; then
#			case $archive in
#			*.tar.bz2) tar xvjf $archive ;;
#			*.tar.gz) tar xvzf $archive ;;
#			*.bz2) bunzip2 $archive ;;
#			*.rar) rar x $archive ;;
#			*.gz) gunzip $archive ;;
#			*.tar) tar xvf $archive ;;
#			*.tbz2) tar xvjf $archive ;;
#			*.tgz) tar xvzf $archive ;;
#			*.zip) unzip $archive ;;
#			*.Z) uncompress $archive ;;
#			*.7z) 7z x $archive ;;
#			*) echo "don't know how to extract '$archive'..." ;;
#			esac
#		else
#			echo "'$archive' is not a valid file!"
#		fi
#	done
#}

extract ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   tar xf $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#create a file called .bashrc-personal and put all your personal aliases
#in there. They will not be overwritten by skel.
#[[ -f ~/.bashrc-personal ]] && . ~/.bashrc-personal
