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
    export install_docker=true
else
    export install_docker=false
fi

echo -e "${YELLOW}Adding user nathan and installing sudo...${NC}"
echo -e "${YELLOW}First, you will be prompted for the root password.${NC}"
su - -c 'id -u nathan &>/dev/null || (useradd -m -d /home/nathan nathan && echo -e "\033[0;33mThen, you will be prompted for a new password for nathan.\033[0m" && passwd nathan); apt install -y sudo && (groupadd sudo; usermod -aG sudo nathan)'

echo -e "${YELLOW}Switching to the nathan user. You will be prompted for the user password.${NC}"

sudo -i -u nathan bash << 'EOF'
echo -e "${YELLOW}Installing other programs...${NC}"
sudo apt update 
sudo apt upgrade -y 
sudo apt install -y vim openssh-server curl avahi-daemon avahi-utils git ack cifs-utils tree jq rsync

# Install yq prettier - https://github.com/mikefarah/yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq

if [[ "${INSTALL_DOCKER}" == "true" ]]; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
	sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm /etc/apt/sources.list.d/docker.sources
    sudo rm /etc/apt/keyrings/docker.asc
    curl -fsSL https://get.docker.com -o get-docker.sh
    chmod +x get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
	sudo groupadd docker
	sudo usermod -aG docker nathan
else
    echo -e "${YELLOW}Skipping Docker install...${NC}"
fi

echo -e "${YELLOW}Setting up Bash aliases...${NC}"

cat << 'BASHALIAS' > /home/nathan/.bash_aliases
# From user_setup.sh https://raw.githubusercontent.com/TheNathanSpace/TheNathanSpace/refs/heads/main/user_setup.sh
if [ -f ~/.debian_bash ]; then
    . ~/.debian_bash
fi

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

export PATH="$PATH:/sbin:/home/nathan/bin"

alias cls='clear'
alias la='ls -al'
function cda() {
    if [[ -z "$1" ]]; then
        target=~
    else
        target="$1"
    fi
    cd "$target"
    la
}

alias logs='docker logs -f'
alias dps='docker ps'
alias dstopall='docker stop $(docker ps -a -q)'
alias dremoveall='docker rm $(docker ps -a -q); docker network prune -f'

alias ga='git status'
alias gb='git branch -a'
alias gl='git log --oneline'

alias bashrc='vim ~/.bash_aliases; source ~/.bashrc'

shopt -s dotglob
if command -v sudo > /dev/null 2>&1; then
    alias disk-usage='sudo du -sh ./* | sort -hr'
else
    alias disk-usage='du -sh ./* | sort -hr'
fi
alias interfaces='ip link show'

function find-file() {
    if [ -z "$1" ]; then
        echo "Usage: find-file <phrase> [directory]"
        return 1
    fi

    local search_dir="${2:-.}"
    find "$search_dir" -iname "*$1*"
}

function denter() {
    if [[ -z "$1" ]]; then
        echo "Usage: denter <container-id>"
        return 1
    fi
    docker exec -it "$1" /bin/bash
}
function denter_sh() {
    if [[ -z "$1" ]]; then
        echo "Usage: denter <container-id>"
        return 1
    fi
    docker exec -it "$1" /bin/sh
}
function dfind_process() {
    if [[ -z "$1" ]]; then
        echo "Usage: dfind_process <container-id>"
        return 1
    fi

    container_id=$(docker container ls | grep "$1" | awk '{print $1}')
    if [[ ! "$container_id" ]]; then
        echo "No container found for name '$1'"
        return 1
    fi

    pgrep -f "$container_id"
}

function format() {
    if [[ -z "$1" ]]; then
        echo "Usage: format <file>"
        return 1
    fi
    yq -i --indent 4 '.' "$1"
    awk '/^[a-zA-Z]/ && NR > 1 && prev !~ /^$/ {print ""} /^    [a-zA-Z]/ && prev !~ /^$/ && ++count > 2 {print ""} {print; prev=$0}' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

alias new-password='openssl rand -base64 32'

alias nginx='cd /home/nathan/swag/config/nginx/proxy-confs; la *.conf'
alias nginx-logs='cda /home/nathan/swag/config/log/nginx'
alias bans='grep "ban " /home/nathan/swag/config/log/fail2ban/fail2ban.log --ignore-case'
alias unban='docker exec swag fail2ban-client unban'
alias fail2ban='cat /home/nathan/swag/config/log/fail2ban/fail2ban.log'
BASHALIAS

cat << 'DEBIANBASH' > /home/nathan/.debian_bash
# From Debian .bashrc
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
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
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
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
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
DEBIANBASH

cat << 'BASHRC' >> /home/nathan/.bashrc
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
BASHRC

cat << 'VIMRC' >> /home/nathan/.vimrc
set shiftwidth=4 smarttab
set expandtab
set tabstop=8 softtabstop=0
syntax on
VIMRC

echo -e "${YELLOW}Setting up executables...${NC}"
mkdir /home/nathan/bin

cat << 'MOUNTNAS' >> /home/nathan/bin/mount-nas.sh
#!/bin/bash
sudo mount -t cifs //192.168.1.4/CHOOSE_SHARED_FOLDER /home/nathan/CHOOSE_MOUNT_LOCATION -o credentials=/home/nathan/.smbcredentials,uid=1000,gid=1000,vers=3.0
MOUNTNAS
chmod +x /home/nathan/bin/mount-nas.sh

cat << 'UNMOUNTNAS' >> /home/nathan/bin/unmount-nas.sh
#!/bin/bash
sudo umount /home/nathan/CHOOSE_MOUNT_LOCATION
UNMOUNTNAS
chmod +x /home/nathan/bin/unmount-nas.sh

echo -e "${YELLOW}You will want to change the NAS directories mounted in ~/bin/mount-nas.sh and ~/bin/unmount-nas.sh.${NC}"

source /home/nathan/.bashrc
echo -e "${YELLOW}All done!${NC}"
EOF

echo -e "${YELLOW}Copying SSH key from gaming-laptop.local to this machine...${NC}"
echo -e "${YELLOW}You will be prompted for nathan@gaming-laptop.local's password.${NC}"

MACHINE_A_IP=$(hostname -I | awk '{print $1}')

ssh -t root@gaming-laptop.local "ssh-copy-id nathan@${MACHINE_A_IP}"

echo -e "${GREEN}SSH key copied${NC}"

exec su nathan
