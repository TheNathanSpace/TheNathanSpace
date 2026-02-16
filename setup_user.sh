#!/bin/bash

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

echo -e "${YELLOW}Here we go!${NC}"

echo -e "${YELLOW}Do you want to install Docker? (y/n): ${NC}"
read -p "(y/n): " response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    install_docker=true
else
    install_docker=false
fi

echo -e "${YELLOW}Setting up Bash aliases...${NC}"

echo '# From user_setup.sh https://raw.githubusercontent.com/TheNathanSpace/TheNathanSpace/refs/heads/main/user_setup.sh
if [ -f ~/.debian_bash ]; then
    . ~/.debian_bash
fi

export RED='\''\033[0;31m'\''
export GREEN='\''\033[0;32m'\''
export YELLOW='\''\033[0;33m'\''
export BLUE='\''\033[0;34m'\''
export NC='\''\033[0m'\'' # No Color

alias cls='\''clear'\''
alias la='\''ls -al'\''

alias logs='\''docker logs -f'\''
alias dps='\''docker ps'\''

alias bashrc='\''vim ~/.bash_aliases; source ~/.bashrc'\''

shopt -s dotglob
if command -v sudo > /dev/null 2>&1; then
    alias disk-usage='\''sudo du -sh ./* | sort -hr'\''
else
    alias disk-usage='\''du -sh ./* | sort -hr'\''
fi

function denter() {
    if [[ -z "$1" ]]; then
        echo "Usage: denter <container-id>"
        return 1
    fi
    docker exec -it "$1" bash
}

function denter_sh() {
    if [[ -z "$1" ]]; then
        echo "Usage: denter <container-id>"
        return 1
    fi
    docker exec -it "$1" sh
}

alias nginx='\''cd /home/nathan/swag/config/nginx/proxy-confs'\''
alias nginx-logs='\''cd /home/nathan/swag/config/log/nginx'\''
alias bans='\''grep "ban " /home/nathan/swag/config/log/fail2ban/fail2ban.log --ignore-case'\''
alias unban='\''docker exec swag fail2ban-client unban'\''
alias fail2ban='\''cat /home/nathan/swag/config/log/fail2ban/fail2ban.log'\''' > ~/.bash_aliases

echo '# From Debian .bashrc
# If not running interactively, don'\''t do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don'\''t put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don'\''t overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize


# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it'\''s compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='\''${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '\''
else
    PS1='\''${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '\''
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='\''ls --color=auto'\''
    alias dir='\''dir --color=auto'\''
    alias vdir='\''vdir --color=auto'\''

    alias grep='\''grep --color=auto'\''
    alias fgrep='\''fgrep --color=auto'\''
    alias egrep='\''egrep --color=auto'\''
fi

# colored GCC warnings and errors
export GCC_COLORS='\''error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'\''

# enable programmable completion features (you don'\''t need to enable
# this, if it'\''s already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
' > ~/.debian_bash

echo '
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
' >> ~/.bashrc

echo -e "${YELLOW}Adding user nathan and installing sudo...${NC}"
echo -e "${YELLOW}First, you will be prompted for the root password.${NC}"
su - -c 'id -u nathan &>/dev/null || (useradd -m -d /home/nathan nathan && echo -e "\033[0;33mThen, you will be prompted for a new password for nathan.\033[0m" && passwd nathan); apt install sudo && (getent group sudo | grep -q nathan || adduser nathan sudo)'

echo -e "${YELLOW}Switching to the nathan user. You will be prompted for the user password.${NC}"
su - nathan

echo -e "${YELLOW}Installing other programs...${NC}"
sudo apt install vim
sudo apt install openssh-server
sudo apt install curl
sudo apt install avahi-daemon

if [ $install_docker ]
then
    echo -e "${YELLOW}Installing Docker...${NC}"
    sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
    curl -fsSL https://get.docker.com -o get-docker.sh
    chmod +x get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
else
    echo -e "${YELLOW}Skipping Docker install...${NC}"
fi

source ~/.bashrc
echo -e "${YELLOW}All done!${NC}"
