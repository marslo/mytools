#!/bin/bash

# CURRENTUSER=$(whoami)
CURRENTUSER=devops
# MARSLOHOME="${CURRENTHOME}/.marslo"

CURRENTHOME="/home/${CURRENTUSER}"
if [ ! -d "${CURRENTHOME}" ]; then
  echo "${CURRENTHOME} cannot be found. EXIT.";
  exit 1;
fi

pushd $PWD
cd "${CURRENTHOME}"

sudo bash -c 'cat >> /etc/hosts' << EOF

192.168.1.107     docker1 docker-1.artifactory docker-local-1.artifactory docker-remote-1.artifactory my.docker-1.com
192.168.1.106     docker2 docker-2.artifactory docker-local-2.artifactory docker-remote-2.artifactory my.docker-2.com
EOF

# cat << EOF | tee -a /etc/bash.bashrc
sudo bash -c 'cat >> /etc/bash.bashrc ' << EOF

export LANG=en_US.UTF-8
export LANGUAGE=\$LANG
export LC_COLLATE=\$LANG
export LC_CTYPE=\$LANG
export LC_MESSAGES=\$LANG
export LC_MONETARY=\$LANG
export LC_NUMERIC=\$LANG
export LC_TIME=\$LANG
export LC_ALL=\$LANG
EOF
source /etc/bash.bashrc


cat << 'EOF' > ${CURRENTHOME}/.inputrc
set convert-meta on
set completion-ignore-case on
set show-all-if-ambiguous on
set show-all-if-unmodified on
set mark-symlinked-directories on
set print-completions-horizontally on
EOF
chown "${CURRENTUSER}":"${CURRENTUSER}" "${CURRENTHOME}/.inputrc"

sudo apt update
sudo apt install -y bash-completion tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils curl git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute vim-gtk3 apt-transport-https ca-certificates software-properties-common
sudo apt install -y sysstat
sudo apt install -y libcurl4-gnutls-dev
sudo apt install -y libcurl4-openssl-dev

sudo apt upgrade
sudo apt autoremove -y
sudo apt-file update

sudo chmod -x /etc/update-motd.d/00-header
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news

sudo bash -c 'cat > /etc/landscape/client.conf' << 'EOF' 
[sysinfo]
exclude_sysinfo_plugins = Temperature, LandscapeLink
EOF

sudo run-parts /etc/update-motd.d/
sudo /usr/lib/update-notifier/update-motd-updates-available --force
sudo update-motd

# For docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) edge"

sudo curl -fsSL get.docker.com -o get-docker.sh
sudo sh -x get-docker.sh
sudo chown "${CURRENTUSER}":"${CURRENTUSER}" get-docker.sh

# for artifactory
curl -L https://jfrog.bintray.com/run/art-compose/5.7.2/art-compose > art-compose
chmod +x art-compose
sudo chown "${CURRENTUSER}":"${CURRENTUSER}" art-compose

dconf load /org/gnome/terminal/ <ubuntu1710_terminal_font18_backup.bak
