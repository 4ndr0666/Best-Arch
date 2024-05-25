#!/bin/bash
#File: /root/.bashrc
#Edited: 04-26-2024
#Author: 4ndr0666
#
# --- // /root/.bashrc // ========


# --- // KILL_IF_NONINTERACTIVE:
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$💀 '

# --- // PATH:
if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "/usr/local/bin" ] ;
then PATH="$PATH:$(find /usr/local/bin -type d | paste -sd ':' -)$PATH"
fi

export PATH="${HOME}/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:"
export PATH="${PATH}/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:"

# --- // ENV:
HISTCONTROL=ignoreboth
HISTTIMEFORMAT="%Y-%m-%d %T "
shopt -s cdspell
complete -cf sudo
shopt -s autocd
shopt -s checkwinsize
run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }
bind -m vi-insert -x '"\eh": run-help'
bind -m emacs -x     '"\eh": run-help'
[[ -f /home/andro/.config/shell/functions/functionsrc ]] || source "/home/andro/.config/shell/functions/functionsrc" 2>/dev/null/
alias 00='cat $USER/.bashrc'
alias 0f='cat $USER/.zshrc'

# --- // COLOR_TERM:
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

# --- // Autoset $DISPLAY:
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

# --- // ESCALATE_COMMANDS:
for cmd in pacman-key ufw mount umount pacman updatedb su systemctl useradd userdel groupadd groupdel chown chmod btrfs ip netstat modprobe; do
    alias $cmd="sudo $cmd && echo 'Executed $cmd on \$(date)' >> /var/log/user_commands.log"
done

# --- // LISTINGS:
alias lf="lfub" 
alias ls='ls --color=auto'
#alias la='ls -a'
#alias ll='ls -alFh'
#alias l='ls'
#alias l.="ls -A | egrep '^\.'"
alias listdir="ls -d */ > list"

# --- // REPLACE_WITH_EZA:
#alias ls='exa -al --color=always --group-directories-first --icons' # preferred listing
alias la='exa -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first --icons'  # long format
alias lt='exa -aT --color=always --group-directories-first --icons' # tree listing
alias l.='exa -ald --color=always --group-directories-first --icons .*' # show only dotfiles

# --- // TYPOS:
alias cd..='cd ..'
alias pdw='pwd'
alias sl='ls'
alias gerp='grep'
alias shudown='shutdown'
alias pdw='pwd'

# --- // FORCE_NEOVIM & PARU:
if command -v nvim > /dev/null 2>&1; then
    alias vim="nvim"
    alias vimdiff="nvim -d"
else
    echo "nvim not found, falling back to vim if available"
    command -v vim > /dev/null 2>&1 || { echo "vim also not found. Please install a text editor."; return 1; }
fi
alias svim="sudo nvim"
alias yay="paru"
alias vim="nvim"

# --- // EDIT_CONFIG_FILES:
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

# --- // DIRECTORY_SHORTCUTS:
goto() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        cd "$dir"
    else
        echo "Directory not found: $dir"
    fi
}

#//$User:
alias dc='goto ~/Documents'
alias dl='goto ~/Downloads'
alias conf='goto ~/.config'
alias ob='goto ~/.config/openbox'
alias obt='goto ~/.config/openbox/themes'
alias hyp='goto ~/.config/hypr'
alias lbin='goto ~/.local'
alias lshare='goto ~/.local/share/'

#//23.1: Navigation to various directories under /23.1
alias 23='goto /23.1'
alias 23dl='goto /23.1/Downloads'
alias rtg='goto /23.1/Video/RTG\ Gifs'
alias cloud='goto /23.1/Thecloud'
alias 23v='goto /23.1/video'
alias 23i='goto /23.1/Images'
alias 23jd='goto /23.1/JD'
alias 23p='goto /23.1/Pictures'
alias 23e='goto /23.1/Edits'
alias 23sr='goto /23.1/Screenrecorder'
alias 23ss='goto /23.1/Screenshots'
alias 23sync='goto /23.1/3sync'

#//Nas: Navigation to various directories under /Nas
alias nas='goto /Nas/'
alias nbin='goto /Nas/Build/git/syncing/scr'
alias nnas='goto /Nas/Build/git/syncing/nas'
alias ngpt='goto /Nas/Build/git/syncing/gpt'
alias ngc='goto /Nas/Build/git/clone'
alias ngl='goto /Nas/Build/git/local'
alias npkg='goto /Nas/Build/pkgs'
alias npro='goto /Nas/Build/projects'
alias ndot='goto /Nas/Build/git/clone/dotfiles'

#//System: Navigation to key system directories
alias et='goto /etc'
alias ske='goto /etc/skel'
alias bin='goto /usr/local/bin'
alias loc='goto ~/.local'
alias roo='goto /root/'
alias shellzsh='goto ~/.config/shellz'
alias shellbash='goto ~/.config/shell'

# ========================================================= // BASIC_ALIASES //
alias cd='cd -P'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias s='sudo'
alias p='pacman'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -vI'
alias rg="rg --sort path"
alias diff='diff --color=auto'
alias rmdir='rm -vI --preserve root'
alias ln='ln -iv'
alias bc='bc -ql'
alias mkdir='mkdir -pv'
alias wget="wget -c"
alias curl="curl --user-agent 'noleak'"
alias df='df -h --exclude-type=squashfs --exclude-type=tmpfs --exclude-type=devtmpfs'
alias cat='bat --number --style snip --style changes --style header'
alias rsync='rsync -vrPlu'
alias grub-mkconfig='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
alias grepc='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
#alias ccat='highlight --out-format=ansi'
alias ip='ip -color=auto'
alias c='clear; echo; echo; seq 1 $(tput cols) | sort -R | spark | lolcat; echo; echo'
alias hw='sudo hwinfo --short'
alias psa='ps auxf | less'
alias free='free -mt'
alias jctl='journalctl -p 3 -xb'
alias g='git'
alias gstat='git status'
alias grh="git reset --hard"
alias gfs="git-lfs"
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'
alias cpu="cpuid -i | grep uarch | head -n 1"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias dir5='du -cksh * | sort -hr | head -5'
alias dir10='du -cksh * | sort -hr | head -10'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias reload="source ~/.bashrc"
alias magic='sudo /usr/local/bin/magic.sh'


# ======================================================== // UNIQUE_ALIASES //
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
alias back='cd $OLDPWD'
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias watch='watch '
alias lock='sudo chattr +i '
alias unlock='sudo chattr -i '
alias kernel="ls /usr/lib/modules"
alias kernels="ls /usr/lib/modules"
alias burnit='echo "sudo dd bs=4M if=path/to/.iso of=/dev/sdX status=progress oflag=sync"'

# Count or list files in the current directory
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
alias vpnc='sudo expressvpn connect'
alias vpnd='sudo expressvpn disconnect'
alias vpns='sudo expressvpn status'
alias vpnr='sudo expressvpn refresh'
alias vpnauto='expressvpn autoconnect true'
alias vpnset='sudo expressvpn preferences set '

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
gclone() {
    git clone --depth 1 "$@" && \
      cd -- "$(basename "$1" .git)" || exit
}

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

# --- // Make_an_archived_backup:
# --- // Quick_archive_backup:
f() {
    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Please provide a file or directory to back up."
        return 1
    fi
    tar -czvf "${target##*/}_$(date -u "+%h-%d-%Y_%H.%M%p")_backup.tar.gz" "$target"
}

