#!/bin/sh

echo "# From user_setup.sh
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
}" >> ~/.bash_aliases

su - -c "apt install sudo; adduser nathan sudo; apt install vim; apt install openssh-server;"
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

echo "# From https://docs.docker.com/engine/install/debian/
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo \"$VERSION_CODENAME\")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
getent group somegroupname || groupadd somegroupname
sudo usermod -a -G docker nathan" > install_docker.sh
chmod +x install_docker.sh
./install_docker.sh
