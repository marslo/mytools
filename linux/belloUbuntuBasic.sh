#!/bin/bash
# shellcheck disable=SC2046,SC1117,SC2009
# =============================================================================
#    FileName: belloUbuntuBasic.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-02-06 14:16:22
#  LastChange: 2018-05-23 11:04:48
# =============================================================================
# USAGE:
#     please repace the ARTIFACTORYHOST to your own situation

SSHDFILE="/etc/ssh/sshd_config"
SLAVENAME="SlaveX"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")

ARTIFACTORYNAME="my.artifactory.com"
ARTIFACTORYHOME="http://${ARTIFACTORYNAME}/artifactory"

SOCKSPORT=1880
SOCKSPROXY="socks5://127.0.0.1:${SOCKSPORT}"

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function setupEnv() {
  sudo sed -i -e "s:^\($(whoami).*$\):# \1:" /etc/sudoers
  sudo bash -c "echo \"$(whoami)   ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"

  sudo cp /etc/bash.bashrc{,.org}
  sudo cp ${SSHDFILE}{,.org}
  sudo chown -R "$(whoami)":admin /usr/local

  sudo chown -R "$(whoami)":"$(whoami)" /opt
  mkdir -p /opt/{maven,gradle,sonarqube,groovy,java}
  [ ! -d ~/.marslo ] && mkdir -p ~/.marslo

  sudo hostname "devops-${SLAVENAME}"
  sudo bash -c "echo \"devops-${SLAVENAME}\" > /etc/hostname"
  sudo sed -i -e "s:^\\(127\\.0\\.1\\.1\\).*$:\\1\\tdevops-${SLAVENAME}:" /etc/hosts
  if grep -E "^127\.0\.0\.1.*devops-kubernetes-master.*$" /etc/hosts; then
    sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
  fi
  sudo hostnamectl set-hostname "devops-${SLAVENAME}"
  sudo systemctl restart systemd-resolved.service
  sudo systemd-resolve --flush-caches
  sudo systemd-resolve --statistics
  hostname -f
  sysctl kernel.hostname
  hostnamectl status

  if grep -E "^127\.0\.0\.1.*devops-kubernetes-master.*$" /etc/hosts; then
    sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
  fi

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
alias kc='kubectl --namespace=kube-system'
alias ka='kubeadm --namespace=kube-system'
alias kl='kubelet --namespace=kube-system'

alias sstart="sudo systemctl start"
alias sstop="sudo systemctl stop"
alias sstatus="sudo systemctl status"
alias srestart="sudo systemctl restart"

alias open="nautilus"

myproxy=""
all_proxy=\$myproxy
http_proxy=\$myproxy
https_proxy=\$myproxy
ftp_proxy=\$myproxy
socks_proxy=\$myproxy

myproxy=\$myproxy
HTTP_PROXY=\$myproxy
HTTPS_PROXY=\$myproxy
FTP_PROXY=\$myproxy
SOCKS_PROXY=\$myproxy

no_proxy=localhost,127.0.0.1,130.147.0.0/16,130.145.0.0/16,www.*.mysite.mycompany.com,130.*.*.*,161.*.*.*,www.artifactory.mysite.mycompany.com,130.147.219.19,healthyliving.cn-132.lan.mycompany.com,*.cn-132.lan.mycompany.com,130.147.183.165,161.85.30.130,www.sonar.mysite.mycompany.com,130.147.219.20,www.gitlab.mysite.mycompany.com,130.147.219.15,www.slave01.mysite.mycompany.com,130.147.219.24,www.confluence.mysite.mycompany.com,130.147.219.18,www.jira.mysite.mycompany.com,130.147.219.16,161.*.*.*,162.*.*.*,130.*.*.*,bdhub.pic.mycompany.com,161.85.30.130,tfsemea1.ta.mycompany.com,130.147.219.23,www.jenkins.mysite.mycompany.com,blackduck.mycompany.com,fortify.mycompany.com,161.85.30.130
NO_PROXY=\$no_proxy

export all_proxy ALL_PROXY http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
export SYSTEMD_LESS=FRXMK
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
sudo bash -c 'cat > /lib/systemd/system/marsloRoute.service' << EOF
[Unit]
Description=Add static route for two interface

[Service]
ExecStart=/usr/local/bin/add_route

[Install]
WantedBy=multi-user.target
Alias=marsloRoute.service
EOF

sudo systemctl enable /lib/systemd/system/marsloRoute.service
route -n
sudo systemctl start marsloRoute.service
route -n
sudo systemctl -l | grep -i marsloroute

sudo bash -c 'cat >> /etc/hosts ' << EOF
1.2.3.4 domainname
EOF

  wget -L ${ARTIFACTORYHOME}/devops/docker/${ARTIFACTORYNAME}-ca.crt
  sudo cp ${ARTIFACTORYNAME}-ca.crt /usr/local/share/ca-certificates/
  ls -Altrh !$
  sudo update-ca-certificates
  sudo systemctl restart docker.service
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
  sudo bash -c "figlet -w 1000 -f big \"${SLAVENAME} !\" > /etc/ssh/server.banner"
  set -H

  sudo systemctl restart ssh.service
}

function installAptApps() {
  APTSOURCEPATH="/etc/apt/sources.list.d"
  [ -f /etc/apt/sources.list ] && sudo mv /etc/apt/sources.list{,.org.${TIMESTAMPE}}
  [ -f ${APTSOURCEPATH}/docker.list ] && sudo mv ${APTSOURCEPATH}/docker.list{,bak.${TIMESTAMPE}}
  [ -f ${APTSOURCEPATH}/kubernetes.list ] && sudo mv ${APTSOURCEPATH}/kubernetes.list{,bak.${TIMESTAMPE}}

sudo bash -c "cat > /etc/apt/sources.list" << EOF
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs) main restricted
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs)-updates main restricted
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs) universe
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs)-updates universe
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs) multiverse
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs)-updates multiverse
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu $(lsb_release -cs)-backports main restricted universe multiverse
deb ${ARTIFACTORYHOME}/debian-remote-canonical $(lsb_release -cs) partner
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu-security $(lsb_release -cs)-security main restricted
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu-security $(lsb_release -cs)-security universe
deb ${ARTIFACTORYHOME}/debian-remote-ubuntu-security $(lsb_release -cs)-security multiverse
EOF

  sudo apt update
  sudo apt install -y curl openssl-server net-tools

sudo bash -c "cat > ${APTSOURCEPATH}/docker.list" << EOF
deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker $(lsb_release -cs) edge
deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker $(lsb_release -cs) stable
deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker xenial edge
deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker xenial stable

# deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) edge
EOF

sudo bash -c "cat > ${APTSOURCEPATH}/kubernetes.list" << EOF
deb ${ARTIFACTORYHOME}/debian-remote-google kubernetes-xenial main

# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-xenial main
# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-xenial-unstable main
# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-yakkety main
# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-yakkety-unstable main
# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes cloud-sdk-yakkety-unstable main
# deb ${ARTIFACTORYHOME}/debian-remote-kubernetes cloud-sdk-yakkety main
EOF

  # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-docker/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-google/doc/apt-key.gpg | sudo apt-key add -
  # sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3746C208A7317B0F
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886

  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-google/doc/apt-key.gpg | sudo apt-key add
  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-docker/gpg | sudo apt-key add

  sudo apt update

  sudo apt install -y net-tools bash-completion tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils curl git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute vim-gtk3 apt-transport-https ca-certificates software-properties-common figlet screenfetch dconf-editor m2crypto ctags ntp nautilus-admin libgnome2-bin tmux screen exfat-fuse
  sudo apt install -y sysstat
  sudo apt install -y libcurl4-gnutls-dev
  sudo apt install -y libcurl4-openssl-dev

  sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
  sudo apt update
  sudo apt install y-ppa-manager -y

  sudo apt upgrade -y
  sudo apt autoremove -y
  sudo apt-file update
}

function setupApps() {
  sudo chmod -x /etc/update-motd.d/00-header
  sudo chmod -x /etc/update-motd.d/10-help-text
  sudo chmod -x /etc/update-motd.d/50-motd-news
  sudo chmod -x /etc/update-motd.d/80-livepatch

sudo bash -c 'cat > /etc/landscape/client.conf' << EOF
[sysinfo]
exclude_sysinfo_plugins = Temperature, LandscapeLink
EOF

  sudo run-parts /etc/update-motd.d/
  sudo /usr/lib/update-notifier/update-motd-updates-available --force
  sudo update-motd
}

function setupProxy() {
  [ ! -d /etc/systemd/system/docker.service.d ] && sudo mkdir -p /etc/systemd/system/docker.service.d

if [ ! -f ~/.marslo/ss/ssmarslo.json ]; then
cat > ~/.marslo/ss/ssmarslo.json << EOF
{
    "server":"45.35.34.44",
    "server_port":8838,
    "local_address": "0.0.0.0",
    "local_port":${SOCKSPORT},
    "password":"himarslo",
    "timeout":600,
    "method":"aes-128-cfb",
    "obfs":"http_simple",
    "fast_open": false
}
EOF
fi

  if ! sudo systemctl -l | grep marsloproxy; then
    sudo apt install python-pip m2crypto
    if ! sudo -H pip list --format=columns | grep shadowsocks 2> /dev/null; then
      sudo -H pip install git+https://github.com/shadowsocks/shadowsocks.git@master
    fi

    [ ! -d ~/.marslo/logs ] && mkdir -p ~/.marslo/logs
    [ ! -f ~/.marslo/logs/ssmarslo.log ] && touch ~/.marslo/logs/ssmarslo.log

sudo bash -c "cat > /lib/systemd/system/marsloProxy.service" << EOF
[Unit]
Description=Start shadowsocks proxy locally

[Service]
ExecStart=/usr/local/bin/ssmarslo
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable marsloProxy.service
    sudo systemctl start marsloProxy.service
    sudo systemctl -l | grep marsloProxy
    ps auxf | grep sslocal
  fi

sudo bash -c "cat > /etc/systemd/system/docker.service.d/socks5-proxy.conf" << EOF
[Service]
Environment="ALL_PROXY=${SOCKSPROXY}" "NO_PROXY=localhost,127.0.0.1,www.artifactory.mysite.mycompany.com,130.147.0.0/16,130.145.0.0/16"
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker.service

  curl -x ${SOCKSPROXY} -l https://k8s.gcr.io/v1/_ping
  curl -x ${SOCKSPORT} -fsSL https://dl.k8s.io/release/stable-1.10.txt
  # docker pull k8s.gcr.io/kube-apiserver-amd64:v1.10.1
}


function advacnedSetup() {
  [ -f /etc/gdm3/custom.conf ] && sudo cp /etc/gdm3/custom.conf{,.bak.${TIMESTAMPE}}
  /bin/sed -r -e 's:^#(WaylandEnable.*false.*$):\1:' -i /etc/gdm3/custom.conf
  /bin/sed -r -e 's:^#.*(AutomaticLoginEnable.*$):\1:' -i /etc/gdm3/custom.conf
  /bin/sed -r -e "s:^#.*(AutomaticLogin[^Enable]*=).*$:\1 $(whoami):" -i /etc/gdm3/custom.conf
}

function screenSharing() {
  dconf write /org/gnome/desktop/remote-access/enabled true
  gsettings set org.gnome.Vino require-encryption false
  gsettings set org.gnome.Vino authentication-methods "['vnc']"
  gsettings set org.gnome.Vino lock-screen-on-disconnect false
  gsettings set org.gnome.Vino alternative-port 5900
  gsettings set org.gnome.Vino prompt-enabled false
  gsettings set org.gnome.Vino view-only false
  gsettings set org.gnome.Vino vnc-password "bWFyc2xv"
  # sudo service lightdm restart
}

function setupSlaveEnv() {
  setupEnv
  installAptApps
  setupRemoteDesktop
  setupApps
  setupSSH
  setupSSHD
  setupShadowsocks
}

setupSlaveEnv