#!/bin/bash

echo "# From user_setup.sh https://raw.githubusercontent.com/TheNathanSpace/TheNathanSpace/refs/heads/main/user_setup.sh
alias cls='clear'
alias la='ls -al'

alias logs='docker logs -f'
alias dps='docker ps'

alias bashrc='vim ~/.bash_aliases; source ~/.bashrc'
alias disk-usage='sudo du -sh ./* | sort -hr'

function denter() {
    if [[ -z \"$1\" ]]; then
        echo \"Usage: denter <container-id>\"
        return 1
    fi
    docker exec -it \"$1\" bash
}

function denter_sh() {
    if [[ -z \"$1\" ]]; then
        echo \"Usage: denter <container-id>\"
        return 1
    fi
    docker exec -it \"$1\" sh
}" > ~/.bash_aliases

su - -c "apt install sudo; adduser nathan sudo && apt install vim && apt install openssh-server && apt install curl && apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1);"

curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo sh get-docker.sh

source ~/.bashrc
