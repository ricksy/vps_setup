#!/bin/bash


host="$1:example.com"
name="$2:schwarz"
namespace() {
		setup1 () {
		# General update and install needed packages
		apt update
		apt upgrade -y
		apt install -y zsh fail2ban mc
		#apt install -y boybu ufw
		apt autoremove
		#https://www.cyberciti.biz/faq/how-to-disable-ssh-password-login-on-linux/
		useradd -m -s /bin/zsh name
		passwd name $2
		usermod -aG sudo name
		# https://www.vps-mart.com/blog/how-to-configure-firewall-with-ufw-on-ubuntu
		ufw allow 80,443,22/tcp
		ufw allow 53/udp
		ufw logging on
		ufw enable
		cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
		sed -re 's/^(enabled)([[:space:]]+)(=)([[:space:]]+)(false)/\1\2\3\4true/' -i.`date -I` /etc/fail2ban/jail.local
		sed -re 's/^(backend)([[:space:]]+)(=)([[:space:]]+)(auto)/\1\2\3\4systemd/' -i.`date -I` /etc/fail2ban/jail.local
		systemctl enable fail2ban
		systemctl start fail2ban
		#$ Generate locales
        ## https://mkyong.com/linux/cannot-set-lc_ctype-to-default-locale-no-such-file-or-directory
		locale-gen "en_US.UTF-8"
		## Install shaarli
		# https://shaarli.readthedocs.io/en/master/Docker.html
		# remove old docker 
		apt-get remove docker docker-engine docker.io containerd runc
		## Install new docker
		apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
		# https://docs.docker.com/engine/install/ubuntu/
		sudo apt-get install ca-certificates curl
		sudo install -m 0755 -d /etc/apt/keyrings
		sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
		sudo chmod a+r /etc/apt/keyrings/docker.asc
		# Add the repository to Apt sources:
		echo \
  		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  		apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  		usermod -aG docker name

		## Later install sshl
		# https://github.com/yrutschle/sslh/blob/master/doc/config.md
		## Later install algo 
		# https://github.com/trailofbits/algo

		# Setting for the new UTF-8 terminal support in Lion
		#LC_CTYPE=en_US.UTF-8
		#LC_ALL=en_US.UTF-8
		#get docker-compose
		curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		chmod +x /usr/local/bin/docker-compose

	}
}

setup2() {
    #https://superuser.com/questions/759481/ssh-how-to-change-value-in-config-file-in-one-command
	sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i.`date -I` /etc/ssh/sshd_config
	sed -re 's/^(\#?)(ChallengeResponseAuthentication)([[:space:]]+)no/\1\2yes/' -i.`date -I` /etc/ssh/sshd_config
	sed -re 's/^(\#?)(UsePAM)([[:space:]]+)no/\2\3no/' -i.`date -I` /etc/ssh/sshd_config
	sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)yes/\2\3no/' -i.`date -I` /etc/ssh/sshd_config

}
func="namespace"
ssh root@host "$(declare -f $func;); $func"
ssh-copy-id -i ~/.ssh/id_rsa faraskur.com
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -re 's/^(ZSH_THEME=)("robbyrussell")/\1\powerlevel10k\/powerlevel10k/' -i.`date -I` ~/.zshrc
# download the 'latest' image from GitHub Container Registry
docker pull ghcr.io/shaarli/shaarli
# create persistent data volumes/directories on the host
docker volume create shaarli-data
docker volume create shaarli-cache
# create a new container using the Shaarli image
# --detach: run the container in background
# --name: name of the created container/instance
# --publish: map the host's :8000 port to the container's :80 port
# --rm: automatically remove the container when it exits
# --volume: mount persistent volumes in the container ($volume_name:$volume_mountpoint)
#docker run --detach \
#           --name myshaarli \
#           --publish 8000:80 \
#           --rm \
#           --volume shaarli-data:/var/www/shaarli/data \
#           --volume shaarli-cache:/var/www/shaarli/cache \
#           ghcr.io/shaarli/shaarli:latest

# create a new directory to store the configuration:

cd ~ && mkdir shaarli && cd shaarli
# Download the latest version of Shaarli's docker-compose.yml
curl -L https://raw.githubusercontent.com/shaarli/Shaarli/latest/docker-compose.yml -o docker-compose.yml
# Create the .env file and fill in your VPS and domain information
# (replace <shaarli.mydomain.org>, <admin@mydomain.org> and <latest> with your actual information)
echo 'SHAARLI_VIRTUAL_HOST=shaarli.faraskur.com' > .env
echo 'SHAARLI_LETSENCRYPT_EMAIL=admin@faraskur.com' >> .env
# Available Docker tags can be found at https://github.com/shaarli/Shaarli/pkgs/container/shaarli/versions?filters%5Bversion_type%5D=tagged
echo 'SHAARLI_DOCKER_TAG=latest' >> .env
# Pull the Docker images
docker-compose pull
# Run!
docker-compose up -d


