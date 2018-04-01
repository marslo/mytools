#!/bin/bash
# shellcheck disable=SC2046,SC1117
# =============================================================================
#    FileName: belloUbuntuBuilder.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-02-06 14:16:22
#  LastChange: 2018-03-28 21:17:36
# =============================================================================
# USAGE:
#     please repace the ARTIFACTORYHOST to your own situation

SSHDFILE="/etc/ssh/sshd_config"
SLAVENAME="SlaveX"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")
ARTIFACTORYHOST="www.myartifactory.com"
ARTIFACTORYURL="http://${ARTIFACTORYHOST}/artifactory"

function setupEnv() {
  sudo sed -i -e "s:^\($(whoami).*$\):# \1:" /etc/sudoers
  sudo bash -c "echo \"$(whoami)   ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"

  sudo cp /etc/bash.bashrc{,.org}
  sudo cp ${SSHDFILE}{,.org}
  sudo chown -R "$(whoami)":admin /usr/local

  sudo chown -R "$(whoami)":"$(whoami)" /opt
  mkdir -p /opt/{maven,gradle,sonarqube,groovy,java}

  sudo hostname "devops-${SLAVENAME}"
  sudo bash -c "echo \"devops-${SLAVENAME}\" > /etc/hostname"
  sudo sed -i -e "s:^\\(127\\.0\\.1\\.1\\).*$:\\1\\tdevops-${SLAVENAME}:" /etc/hosts
  sudo hostnamectl set-hostname "devops-${SLAVENAME}"
  sudo systemctl restart systemd-resolved.service
  sudo systemd-resolve --flush-caches
  sudo systemd-resolve --statistics
  hostname -f
  sysctl kernel.hostname
  hostnamectl status

sudo bash -c 'cat >> /etc/bash.bashrc' << EOF

# Setup by script
[ -f /usr/bin/screenfetch ] && /usr/bin/screenfetch

GRADLE_HOME="/opt/gradle/gradle-3.5"
M2_HOME="/opt/maven/apache-maven-3.3.9"
M2=\$M2_HOME/bin
MAVEN_OPTS="-Xms512m -Xmx1G"
JAVA_HOME="/opt/java/jdk1.8.0_162"
CLASSPATH=".:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar"

PATH=\$JAVA_HOME/bin:\$M2:\$GRADLE_HOME/bin:\$PATH
export JAVA_HOME CLASSPATH GRADLE_HOME M2_HOME M2 MAVEN_OPTS PATH

export LANG=en_US.UTF-8
export LANGUAGE=\$LANG
export LC_COLLATE=\$LANG
export LC_CTYPE=\$LANG
export LC_MESSAGES=\$LANG
export LC_MONETARY=\$LANG
export LC_NUMERIC=\$LANG
export LC_TIME=\$LANG
export LC_ALL=\$LANG

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- +="pushd ."
alias -- -="popd"
alias ws="cd ~/workspace"
alias la="ls -Al"
alias wa="which -a"
EOF

cat > ~/.inputrc << EOF
set convert-meta on
set completion-ignore-case on
set show-all-if-ambiguous on
set show-all-if-unmodified on
set mark-symlinked-directories on
set print-completions-horizontally on
EOF

sudo cp ./addRoute.ubuntu.sh /usr/local/bin/add_route
sudo bash -c 'cat > /lib/systemd/system/add_route.service' << EOF
[Unit]
Description=Add static route for two interface

[Service]
ExecStart=/usr/local/bin/add_route

[Install]
WantedBy=multi-user.target
Alias=marslo_route.service
EOF

sudo systemctl enable add_route.service
route -n
sudo systemctl start add_route.service
route -n

sudo bash -c 'cat >> /etc/hosts ' << EOF
1.2.3.4 domainname
EOF

}

function setupRemoteDesktop() {
  gsettings set org.gnome.Vino enabled true
  gsettings set org.gnome.Vino prompt-enabled false
  gsettings set org.gnome.Vino require-encryption false

  sudo update-alternatives --install /usr/local/bin/vino-server vino-server /usr/lib/vino/vino-server 99
  sudo update-alternatives --auto vino-server
}


function setupSSH() {
  mkdir -p ~/.ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClCw0e6vrxNWNQehVIeemZ1UMrhVvV9FxVjUkA7AB2SW0kqtrIGxh8tNoPvL0MUm4ga3wgTbITDrVnXeTzh1LE4Wr7j+MRYLbXm6jDp+O5Ow61sBgZjOlX0/7wuDWwfpOafdscmdYKhdatFg6nTDxjiPP44G08N/UWPWuMHxkQNYWj6bt46N8llLOxLJGyTuMjT7TpL6Ubb9WeVo6PYvi+Gl7spHjSHoJ6ZlrcNKxUb7LGh9k1SfXdLeWB079YFCZMrvuVDBYUwwbq6OzrSZnSABdRtR4ylTaHshdQKRmYn3c1/iRybxAwrU5gNYhmikOmWL2Qt0fkINttRswtxKvr marslo@devops" >> ~/.ssh/authorized_keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7zRA6SKPw4uImacEY0ioLD6jgDnzpZFn8CYaTvXoUf+aio6fwnpG5rMdJf+hN6w7MBIk5tsJGZJxQgNPqJ2gHPTaQDhlAi0R/4vbgk+E1OHK1oXX9DI0qX1RzPFC9gmf9G+40becDxJw7Jp59JQRLsSZg+cq6B4vi/7t70dPBa0UP7zo8CiOjznnf75T674O777rzv4xsjXeWgM42rPctAdUf2YdMLUsv1tOfv2qmpGJDsP/lW9OnVVLYoALQBsWSA+vYtnfgj9N6f0plgxuj8cyee8hJrm2BzW4uqKYScw0vXGUKVYs8TkFUS8COZyoR06Uxkc5dThQDxIUw9jDh slave@devops" >> ~/.ssh/authorized_keys
  chmod 700 ~/.ssh
  chmod 644 ~/.ssh/authorized_keys
  restorecon -Rf ~/.ssh
}

function setupSSHD() {
  sudo bash -c 'sed -i -e "s:^\(UsePAM.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(PermitRootLogin.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(ChallengeResponseAuthentication.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(PasswordAuthentication.*$\):# \1:" ${SSHDFILE}'

sudo bash -c "cat >> ${SSHDFILE}" << EOF

# Add my marslo
PermitRootLogin no
UsePAM no
ChallengeResponseAuthentication no
PasswordAuthentication no
PrintMotd yes
Banner /etc/ssh/server.banner
EOF

  set +o histexpand
  sudo bash -c "figlet -f big \"Jenkins ${SLAVENAME} !\" > /etc/ssh/server.banner"
  set -H

  sudo systemctl restart ssh.service
}

function installAptApps() {
  APTSOURCEPATH="/etc/apt/sources.list.d"
  [ -f ${APTSOURCEPATH}/docker.list ] && mv ${APTSOURCEPATH}/docker.list{,bak.${TIMESTAMPE}}
  [ -f ${APTSOURCEPATH}/kubernetes.list ] && mv ${APTSOURCEPATH}/kubernetes.list{,bak.${TIMESTAMPE}}

sudo bash -c "${APTSOURCEPATH}/docker.list" << EOF
deb [arch=amd64] https://download.docker.com/linux/ubuntu artful edge
EOF

sudo bash -c "${APTSOURCEPATH}/kubernetes.list" << EOF
deb ${ARTIFACTORYURL}/debian-remote-kubernetes kubernetes-xenial main
deb ${ARTIFACTORYURL}/debian-remote-kubernetes kubernetes-xenial-unstable main
deb ${ARTIFACTORYURL}/debian-remote-kubernetes kubernetes-yakkety main
deb ${ARTIFACTORYURL}/debian-remote-kubernetes kubernetes-yakkety-unstable main
deb ${ARTIFACTORYURL}/debian-remote-kubernetes cloud-sdk-yakkety-unstable main
deb ${ARTIFACTORYURL}/debian-remote-kubernetes cloud-sdk-yakkety main
EOF

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3746C208A7317B0F

  sudo apt update

  sudo apt install -y bash-completion tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils curl git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute vim-gtk3 apt-transport-https ca-certificates software-properties-common figlet screenfetch dconf-editor
  sudo apt install -y sysstat
  sudo apt install -y libcurl4-gnutls-dev
  sudo apt install -y libcurl4-openssl-dev

  sudo apt upgrade
  sudo apt autoremove -y
  sudo apt-file update

}

function setupApps() {
  sudo chmod -x /etc/update-motd.d/00-header
  sudo chmod -x /etc/update-motd.d/10-help-text
  sudo chmod -x /etc/update-motd.d/50-motd-news

sudo bash -c 'cat > /etc/landscape/client.conf' << EOF
[sysinfo]
exclude_sysinfo_plugins = Temperature, LandscapeLink
EOF

  sudo run-parts /etc/update-motd.d/
  sudo /usr/lib/update-notifier/update-motd-updates-available --force
  sudo update-motd
}

function setupSlaveEnv() {
  setupEnv
  installAptApps
  setupRemoteDesktop
  setupApps
  setupSSH
  setupSSHD
}

setupSlaveEnv
