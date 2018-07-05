#!/bin/bash
# shellcheck disable=SC2046,SC1117,SC2009,SC2224,SC1078,SC1079
# =============================================================================
#    FileName: belloMyUbuntu.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-05-25 23:37:30
#  LastChange: 2018-07-04 19:32:19
# =============================================================================
# USAGE:
#     please repace the ARTIFACTORYHOST to your own situation

MYHOME="/home/$(whoami)/myubuntu"
GITHOME="${MYHOME}/tools/git"
SSHDFILE="/etc/ssh/sshd_config"
JAVADIR="/opt/java"
JAVAHOME="${JAVADIR}/jdk1.8.0_171"
MAVENDIR="/opt/maven"
GRADLEDIR="/opt/gradle"
GROOVYDIR="/opt/groovy"
APTSOURCEPATH="/etc/apt/sources.list.d"

MYHOSTNAME="iMarslo18"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")

ARTIFACTORYNAME="my.artifactory.com"
ARTIFACTORYHOME="http://${ARTIFACTORYNAME}:8081/artifactory"
SOCKSPORT=1880
SOCKSSERVER="45.35.34.44"
SOCKSPROXY="socks5://127.0.0.1:${SOCKSPORT}"

CURL="/usr/bin/curl"
WGET="/usr/bin/wget"
GREP="/bin/grep"

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function systemEnv() {
  sudo sed -i -e "s:^\($(whoami).*$\):# \1:" /etc/sudoers
  sudo bash -c "echo \"$(whoami)   ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"

  sudo cp "/etc/bash.bashrc{,.org.${TIMESTAMPE}}"
  sudo cp "${SSHDFILE}{,.org.${TIMESTAMPE}}"
  sudo chown -R "$(whoami)":admin /usr/local

  sudo chown -R "$(whoami)":"$(whoami)" /opt
  mkdir -p /opt/{maven,gradle,sonarqube,groovy,java}
  [ ! -d ~/.marslo/ss ] && mkdir -p ~/.marslo/ss

  sudo hostname "${MYHOSTNAME}"
  sudo bash -c "echo \"${MYHOSTNAME}\" > /etc/hostname"
  sudo sed -i -e "s:^\\(127\\.0\\.1\\.1\\).*$:\\1\\t${MYHOSTNAME}:" /etc/hosts
  if ${GREP} -E "^127\.0\.0\.1.*${MYHOSTNAME}.*$" /etc/hosts; then
    sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
  fi
  sudo hostnamectl set-hostname "${MYHOSTNAME}"
  sudo systemctl restart systemd-resolved.service
  sudo systemd-resolve --flush-caches
  sudo systemd-resolve --statistics
  hostname -f
  sysctl kernel.hostname
  hostnamectl status

  if ${GREP} -E "^127\.0\.0\.1.*${MYHOSTNAME}*$" /etc/hosts; then
    sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
  fi

  sudo ufw disable
  sudo swapoff -a
  sudo bash -c "sed -i -e 's:^\\(.*swap.*\\)$:# \\1:' /etc/fstab"

  [ -f /etc/sysctl.conf ] && sudo cp /etc/sysctl.conf{,.bak.${TIMESTAMPE}}
  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  sudo sysctl net.bridge.bridge-nf-call-ip6tables=1

sudo bash -c "cat >> /etc/sysctl.conf" << EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

sudo sed -r 's:(^GRUB_TIMEOUT=).*$:\12:' -i /etc/default/grub
sudo update-grub

sudo bash -c 'cat >> /etc/bash.bashrc' << EOF
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
alias ws="cd ~/dev-slave/workspace"
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
alias systemctl="sudo systemctl"

myproxy=""
all_proxy=\$myproxy
http_proxy=\$myproxy
https_proxy=\$myproxy
ftp_proxy=\$myproxy
socks_proxy=\$myproxy

ALL_PROXY=\$myproxy
HTTP_PROXY=\$myproxy
HTTPS_PROXY=\$myproxy
FTP_PROXY=\$myproxy
SOCKS_PROXY=\$myproxy

no_proxy=localhost,127.0.0.1,130.147.0.0/16,130.145.0.0/16,pww.*.cdi.philips.com,130.*.*.*,161.*.*.*,pww.artifactory.cdi.philips.com,130.147.219.19,healthyliving.cn-132.lan.philips.com,*.cn-132.lan.philips.com,130.147.183.165,161.85.30.130,pww.sonar.cdi.philips.com,130.147.219.20,pww.gitlab.cdi.philips.com,130.147.219.15,pww.slave01.cdi.philips.com,130.147.219.24,pww.confluence.cdi.philips.com,130.147.219.18,pww.jira.cdi.philips.com,130.147.219.16,161.*.*.*,162.*.*.*,130.*.*.*,bdhub.pic.philips.com,161.85.30.130,tfsemea1.ta.philips.com,130.147.219.23,pww.jenkins.cdi.philips.com,blackduck.philips.com,fortify.philips.com,161.85.30.130
NO_PROXY=\$no_proxy

# export all_proxy ALL_PROXY http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
export socks_proxy SOCKS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
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

[ ! -d "$HOME/.marslo/ss" ] && mkdir -p "$HOME/.marslo/ss"
if [ ! -f "$HOME/.marslo/ss/ssmarslo.json" ]; then
cat > "$HOME/.marslo/ss/ssmarslo.json" << EOF
{
    "server":"${SOCKSSERVER}",
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

  sudo locale-gen en_US.UTF-8
  sudo locale-gen zh_CN.UTF-8
  sudo locale-gen zh_CN.GBK
  [ -f "/etc/default/locale" ] && sudo cp "/etc/default/locale{,.bak.${TIMESTAMPE}}"
sudo bash -c "cat > /etc/default/locale" << EOF
#  File generated by update-locale
LANG=en_US.UTF-8
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
EOF
  sudo update-locale LANG=en_US.UTF-8
}

function systemSSH() {
  mkdir -p ~/.ssh
  [ -f "$HOME/.ssh/config" ] && mv "$HOME/.ssh/config.org.${TIMESTAMPE}"

  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClCw0e6vrxNWNQehVIeemZ1UMrhVvV9FxVjUkA7AB2SW0kqtrIGxh8tNoPvL0MUm4ga3wgTbITDrVnXeTzh1LE4Wr7j+MRYLbXm6jDp+O5Ow61sBgZjOlX0/7wuDWwfpOafdscmdYKhdatFg6nTDxjiPP44G08N/UWPWuMHxkQNYWj6bt46N8llLOxLJGyTuMjT7TpL6Ubb9WeVo6PYvi+Gl7spHjSHoJ6ZlrcNKxUb7LGh9k1SfXdLeWB079YFCZMrvuVDBYUwwbq6OzrSZnSABdRtR4ylTaHshdQKRmYn3c1/iRybxAwrU5gNYhmikOmWL2Qt0fkINttRswtxKvr marslo@devops" >> ~/.ssh/authorized_keys
  echo "HOST  *" > $HOME/.ssh/config
  echo "GSSAPIAuthentication no" >> $HOME/.ssh/config
  echo "StrictHostKeyChecking no" >> $HOME/.ssh/config

  chmod 700 ~/.ssh
  chmod 644 ~/.ssh/authorized_keys
  restorecon -Rf ~/.ssh

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
  sudo bash -c "figlet -w 1000 -f big \"${MYHOSTNAME} !\" > /etc/ssh/server.banner"
  set -H

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
  sudo systemctl restart ssh.service
}

function systemX11() {
  [ -f /etc/gdm3/custom.conf ] && sudo cp "/etc/gdm3/custom.conf{,.bak.${TIMESTAMPE}}"
  /bin/sed -r -e 's:^#(WaylandEnable.*false.*$):\1:' -i /etc/gdm3/custom.conf
  /bin/sed -r -e 's:^#.*(AutomaticLoginEnable.*$):\1:' -i /etc/gdm3/custom.conf
  /bin/sed -r -e "s:^#.*(AutomaticLogin[^Enable]*=).*$:\1 $(whoami):" -i /etc/gdm3/custom.conf

  gsettings set org.gnome.Vino enabled true
  gsettings set org.gnome.Vino prompt-enabled false
  gsettings set org.gnome.Vino require-encryption false

  sudo update-alternatives --install /usr/local/bin/vino-server vino-server /usr/lib/vino/vino-server 99
  sudo update-alternatives --auto vino-server
}

function systemNetwork() {
sudo bash -c "cat >> /etc/default/grub" << EOF
# disable ipv6
GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1"
GRUB_CMDLINE_LINUX="ipv6.disable=1"
EOF

  [ -f /etc/sysctl.conf ] && sudo cp /etc/sysctl.conf{,.bak.${TIMESTAMPE}}
sudo bash -c "cat >> /etc/sysctl.conf" << EOF
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF

sudo update-grub
}

function systemDualNetwork() {
# sudo cp ./addRoute.ubuntu.sh /usr/local/bin/addr
sudo bash -c 'cat > /lib/systemd/system/marsloRoute.service' << EOF
[Unit]
Description=Add static route for two interface
After=syslog.target network.target network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/addr

[Install]
WantedBy=multi-user.target
Alias=marsloRoute.service
EOF

  sudo systemctl disable marsloRoute.service
  sudo systemctl enable marsloRoute.service
  route -n
  sudo systemctl start marsloRoute.service
  route -n
  sudo systemctl -l | ${GREP} -i marsloroute
  systemctl list-dependencies --reverse marsloRoute.service
}

function systemSSProxy() {
  [ ! -d /etc/systemd/system/docker.service.d ] && sudo mkdir -p /etc/systemd/system/docker.service.d

  sudo apt install -y python python-pip m2crypto
  if ! sudo systemctl -l | ${GREP} marsloProxy; then
    if ! sudo -H pip list --format=columns | ${GREP} shadowsocks 2> /dev/null; then
      sudo -H pip install git+https://github.com/shadowsocks/shadowsocks.git@master
    fi

    [ ! -d ~/.marslo/ss/logs ] && mkdir -p ~/.marslo/ss/logs
    [ ! -f ~/.marslo/ss/logs/ssmarslo.log ] && touch ~/.marslo/ss/logs/ssmarslo.log
    [ ! -f ~/.marslo/ss/ssmarslo.pid ] && touch ~/.marslo/ss/ssmarslo.pid
  fi
  sudo chown -R $(whoami):$(whoami) ~/.marslo
}

function systemProxyService(){
bash -c "cat > /usr/local/bin/ssmarslo" << EOF
#!/bin/bash

/usr/local/bin/sslocal -c /home/$(whoami)/.marslo/ss/ssmarslo.json \\
                       -d start \\
                       --pid-file=/home/$(whoami)/.marslo/ss/ssmarslo.pid \\
                       --log-file=/home/$(whoami)/.marslo/ss/logs/ssmarslo.log
EOF
sudo chmod +x /usr/local/bin/ssmarslo

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
  sudo systemctl -l | ${GREP} marsloProxy
  ps auxf | ${GREP} sslocal

sudo bash -c "cat > /etc/systemd/system/docker.service.d/socks5-proxy.conf" << EOF
[Service]
Environment="ALL_PROXY=${SOCKSPROXY}"
Environment="NO_PROXY=localhost,127.0.0.1,pww.artifactory.cdi.philips.com,130.147.0.0/16,130.145.0.0/16"
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker.service

  curl -x ${SOCKSPROXY} -l https://k8s.gcr.io/v1/_ping
  curl -x ${SOCKSPORT} -fsSL https://dl.k8s.io/release/stable-1.10.txt
  # docker pull k8s.gcr.io/kube-apiserver-amd64:v1.10.1
}


function systemAPTIntranet() {
  [ -f /etc/apt/sources.list ] && sudo cp /etc/apt/sources.list{,.org.${TIMESTAMPE}}
  [ -f ${APTSOURCEPATH}/docker.list ] && sudo mv "${APTSOURCEPATH}/docker.list{,bak.${TIMESTAMPE}}"
  [ -f ${APTSOURCEPATH}/kubernetes.list ] && sudo mv "${APTSOURCEPATH}/kubernetes.list{,bak.${TIMESTAMPE}}"

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

sudo bash -c "cat > ${APTSOURCEPATH}/webupd8team-ubuntu-y-ppa-manager-bionic.list " << EOF
deb ${ARTIFACTORYHOME}/debian-remote-launchpad bionic main
# deb http://ppa.launchpad.net/webupd8team/y-ppa-manager/ubuntu bionic main
# deb-src http://ppa.launchpad.net/webupd8team/y-ppa-manager/ubuntu bionic main
EOF

  ${CURL} -fsSL ${ARTIFACTORYHOME}/debian-remote-google/doc/apt-key.gpg | sudo apt-key add
  ${CURL} -fsSL ${ARTIFACTORYHOME}/debian-remote-docker/gpg | sudo apt-key add

  sudo apt-key fingerprint 0EBFCD88
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3746C208A7317B0F
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6DA746A05F00FA99
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6A030B21BA07F4FB
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 0x6DA746A05F00FA99

  sudo add-apt-repository -y "deb http://ppa.launchpad.net/hzwhuang/ss-qt5/ubuntu artful main"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 0x6DA746A05F00FA99
}

function systemAPTInternet() {
  ${CURL} -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) edge"
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"
  sudo add-apt-repository -y ppa:hzwhuang/ss-qt5
  sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager
  sudo add-apt-repository -y "deb http://ppa.launchpad.net/hzwhuang/ss-qt5/ubuntu artful main"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3746C208A7317B0F
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6DA746A05F00FA99
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 0x6DA746A05F00FA99
  sudo apt-key fingerprint 0EBFCD88
}

function aptInstall() {
  sudo apt remove -y libreoffice-common unity-webapps-common thunderbird totem rhythmbox empathy brasero simple-scan onboard deja-dup
  echo 'Hidden=true' | cat /usr/share/applications/ubuntu-amazon-default.desktop - > ~/.local/share/applications/ubuntu-amazon-default.desktop

  sudo apt update
  sudo apt update -y --fix-missing

  sudo apt install -y curl openssh-server net-tools wireless-tools
  sudo apt install -y apt-transport-https ca-certificates software-properties-common
  sudo ubuntu-drivers autoinstall

  # for mac mini wifi adapter
  if sudo dmidecode -s system-product-name | grep -i macmini; then
    sudo apt install -y bcmwl-kernel-source broadcom-sta-common broadcom-sta-source b43-fwcutter firmware-b43-installer firmware-b43-installer
  fi

  sudo apt install -y menu debian-keyring g++-multilib g++-7-multilib gcc-7-doc libstdc++6-7-dbg gcc-multilib autoconf automake libtool flex bison gcc-doc gcc-7-multilib gcc-7-locales libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan4-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx2-dbg libquadmath0-dbg glibc-doc libstdc++-7-doc make-doc libvdpau-va-gl1 libappindicator1 libindicator7
  sudo apt install -y libnvidia-cfg1-390 libnvidia-common-390 libnvidia-compute-390 libnvidia-decode-390 libnvidia-encode-390 libnvidia-fbc1-390 libnvidia-gl-390 libnvidia-ifr1-390 nvidia-compute-utils-390 nvidia-dkms-390 nvidia-driver-390 nvidia-kernel-common-390 nvidia-kernel-source-390 nvidia-prime nvidia-settings nvidia-utils-390 xserver-xorg-video-nvidia-390

  sudo apt install -y ubuntu-restricted-extras
  sudo apt install -y bash-completion tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute vim-gtk3 figlet screenfetch dconf-editor m2crypto ctags ntp nautilus-admin libgnome2-bin tmux screen gnome-tweaks gnome-tweak-tool nmap git vim-gtk3 xscreensaver xscreensaver-gl-extra xscreensaver-data-extra xscreensaver* tig guake shellcheck dconf-editor exfat-fuse exfat-utils inxi plymouth-x11
  sudo apt install -y sysstat
  sudo apt install -y gir1.2-gtop-2.0 gir1.2-networkmanager-1.0  gir1.2-clutter-1.0 chrome-gnome-shell
  sudo apt install -y glibc-doc:i386 locales:i386
  sudo apt install -y shadowsocks-qt5
  sudo apt install -y docker-ce="$(apt-cache madison docker-ce | /bin/grep 17.03 | head -1 | awk '{print $3}')"

  # install chinese
  sudo apt install -y fonts-arphic-uming language-pack-gnome-zh-hans-base language-pack-zh-hans-base language-pack-zh-hans language-pack-gnome-zh-hans firefox-locale-zh-hans fonts-arphic-ukai fonts-noto-cjk-extra gnome-user-docs-zh-hans hunspell-en-au hunspell-en-ca hunspell-en-gb hunspell-en-za hyphen-en-ca hyhpen-en-gb libpinyin-data libpinyin13 ibus-libpinyin ibus-table-wubi libreoffice-l10n-en-gb libreoffice-help-en-gb libreoffice-l10n-zh-cn libreoffice-help-zh-cn libreoffice-l10n-en-za mythes-en-au thunderbird-locale-en-gb

  # for launchy
  # sudo apt install -y launchy launchy-plugins launchy-skins libmng2 libqt4-dbus libqt4-declarative libqt4-network libqt4-script libqt4-sql libqt4-sql-mysql libqt4-xmlpatterns libqtgui4 qt-at-spi

  sudo apt remove -y ttf-mscorefonts-installer
  wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
  sudo dpkg -i ttf-mscorefonts-installer_3.6_all.deb
  sudo apt --fix-broken install

  sudo apt install y-ppa-manager -y
  sudo apt upgrade -y
  sudo apt autoremove -y
  sudo apt-file update

  sudo chown -R "$(whoami)" /sbin/plymouthd
  sudo dpkg-reconfigure Plymouth
  sudo usermod -a -G docker "$(whoami)"
  sudo apt-mark hold docker-ce
}

function devEnvGetPackage(){
  cp "${GITHOME}/marslo/myvim/Configurations/vimrc_ubuntu" "$HOME/.vimrc"
  cp "${GITHOME}/marslo/mylinux/Configs/HOME/Git/.gitconfig" "$HOME/.gitconfig"
  cp "${GITHOME}/marslo/mylinux/Configs/HOME/.marslo/.marslorc" "$HOME/.marslo/.marslorc"
  cp "${GITHOME}/marslo/mylinux/Configs/HOME/.marslo/.bello_ubuntu" "$HOME/.marslo/.bello_ubuntu"
  cp "${GITHOME}/marslo/mylinux/Configs/HOME/.marslo/.bye_marslo" "$HOME/.marslo/.bye_marslo"
  echo "source /home/marslo/.marslo/.marslorc" >> ~/.bashrc

  ${CURL} -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.tar.gz --create-dirs -o ${JAVADIR}/jdk-8u171-linux-x64.tar.gz

  # ${CURL} http://apache.mirrors.pair.com/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz --create-dirs -o ${MAVENDIR}/apache-maven-3.5.3-bin.tar.gz
  # tar xvzf ${MAVENDIR}/apache-maven-3.5.3-bin.tar.gz -C ${MAVENDIR}
  ${CURL} ${ARTIFACTORYHOME}/devops/common/maven/apache-maven-3.5.0-bin.tar.gz --create-dirs -o ${MAVENDIR}/apache-maven-3.5.0-bin.tar.gz

  # ${CURL} https://services.gradle.org/distributions/gradle-4.7-all.zip --create-dirs -o ${GRADLEDIR}/gradle-4.7-all.zip
  ${CURL} ${ARTIFACTORYHOME}/devops/common/gradle/gradle-3.5-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.5-all.zip
  # ${WGET} https://services.gradle.org/distributions/gradle-4.8-all.zip -P ${GRADLEDIR}
  ${CURL} http://pww.artifactory.cdi.philips.com:8081/artifactory/devops/common/gradle/gradle-4.8-all.zip --create-dirs -o ${GRADLEDIR}/gradle-4.8-all.zip

  # ${CURL} https://dl.bintray.com/groovy/maven/apache-groovy-binary-3.0.0-alpha-2.zip --create-dirs -o ${GROOVYDIR}/apache-groovy-binary-3.0.0-alpha-2.zip
  ${WGET} --no-check-certificate -c https://dl.bintray.com/groovy/maven/apache-groovy-binary-3.0.0-alpha-2.zip -P ${GROOVYDIR}

  wget ${ARTIFACTORYHOME}/devops/ubuntu/tools/chrome/google-chrome-unstable_current_amd64.deb
  sudo dpkg -i google-chrome-unstable_current_amd64.deb
}

function devEnvInstall() {
  # docker certificate for artifactory
  ${WGET} -L ${ARTIFACTORYHOME}/devops/docker/${ARTIFACTORYNAME}-ca.crt
  sudo cp ${ARTIFACTORYNAME}-ca.crt /usr/local/share/ca-certificates/
  ls -Altrh !$
  sudo update-ca-certificates
  sudo systemctl restart docker.service

  tar xvzf ${JAVADIR}/jdk-8u171-linux-x64.tar.gz -C ${JAVADIR}
  sudo update-alternatives --install /usr/local/bin/java    java    ${JAVAHOME}/bin/java    99
  sudo update-alternatives --install /usr/local/bin/javac   javac   ${JAVAHOME}/bin/javac   99
  sudo update-alternatives --install /usr/local/bin/javah   javah   ${JAVAHOME}/bin/javah   99
  sudo update-alternatives --install /usr/local/bin/javap   javap   ${JAVAHOME}/bin/javap   99
  sudo update-alternatives --install /usr/local/bin/javadoc javadoc ${JAVAHOME}/bin/javadoc 99
  sudo update-alternatives --auto java
  sudo update-alternatives --auto javac
  sudo update-alternatives --auto javah
  sudo update-alternatives --auto javap
  sudo update-alternatives --auto javadoc

  tar xvzf ${MAVENDIR}/apache-maven-3.5.0-bin.tar.gz -C ${MAVENDIR}
  sudo update-alternatives --install /usr/local/bin/mvn mvn ${MAVENDIR}/apache-maven-3.5.0/bin/mvn 99
  sudo update-alternatives --auto mvn

  unzip ${GRADLEDIR}/gradle-3.5-all.zip -d ${GRADLEDIR}
  unzip ${GRADLEDIR}/gradle-4.8-all.zip -d ${GRADLEDIR}
  sudo update-alternatives --install /usr/local/bin/gradle gradle ${GRADLEDIR}/gradle-4.8/bin/gradle 99
  sudo update-alternatives --auto gradle

  unzip ${GROOVYDIR}/apache-groovy-binary-3.0.0-alpha-2.zip -d ${GROOVYDIR}
  sudo update-alternatives --install /usr/local/bin/groovy groovy ${GROOVYDIR}/groovy-3.0.0-alpha-2/bin/groovy 99
  sudo update-alternatives --auto groovy

  echo -e """\\033[33mUPDATE ENVIRONMENT\\033[0m
  JAVA_HOME=\"${JAVAHOME}\"
  M2_HOME=\"${MAVENDIR}/apache-maven-3.5.3\"
  M2=\"\$M2_HOME/bin\"
  GRADLE_HOME=\"${GRADLEDIR}/gradle-4.7\"
  GROOVY_HOME=\"${GROOVYDIR}/groovy-3.0.0-alpha-2\"

  PATH=\$JAVA_HOME/bin:\$M2:\$GRADLE_HOME/bin:\$GROOVY_HOME/bin:\$PATH
  export JAVA_HOME M2_HOME M2 GRADLE_HOME GROOVY_HOME PATH
  """
}

function systemMadCatzMouse() {
  DEVNAME=$(xinput | ${GREP} 'Mad Catz' | awk -F'id=' '{print $1}' | sed -re "s:.*(Mad Catz.*$):\1:" | sed 's/[[:blank:]]*$//')
  [ -f "/usr/share/X11/xorg.conf" ] && sudo mv "/usr/share/X11/xorg.conf{,.bak.${TIMESTAMPE}}"
  [ ! -d "/usr/share/X11/xorg.conf.d" ] && sudo mkdir -p /usr/share/X11/xorg.conf.d

sudo bash -c "cat > /usr/share/X11/xorg.conf" << EOF
Section "InputClass"
  Identifier "Mouse Remap"
  MatchProduct "${DEVNAME}"
  MatchIsPointer "true"
  MatchDevicePath "/dev/input/event*"
  Option "Buttons" "24"
  Option "ButtonMapping" "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24"
  Option "AutoReleaseButtons" "13 14 15"
  Option "ZAxisMapping" "4 5 6 7"
EndSection
EOF
  sudo cp /usr/share/X11/xorg.conf /usr/share/X11/xorg.conf.d/90-rat.conf
}

function systemDconf() {
  # ScreenSharing
  dconf write /org/gnome/desktop/remote-access/enabled true
  gsettings set org.gnome.Vino require-encryption false
  gsettings set org.gnome.Vino authentication-methods "['vnc']"
  gsettings set org.gnome.Vino lock-screen-on-disconnect false
  gsettings set org.gnome.Vino alternative-port 5900
  gsettings set org.gnome.Vino prompt-enabled false
  gsettings set org.gnome.Vino view-only false
  gsettings set org.gnome.Vino vnc-password "bWFyc2xv"
  # sudo service lightdm restart

  # increase font size
  dconf write /org/gnome/desktop/interface/text-scaling-factor 1.25
  dconf write /org/gnome/desktop/a11y/always-show-universal-access-status true

  # monitor
  dconf write /org/gnome/shell/extensions/system-monitor/compact-display true
  dconf write /org/gnome/shell/extensions/system-monitor/move-clock true
  dconf write /org/gnome/shell/extensions/system-monitor/center-display false
  dconf write /org/gnome/shell/extensions/system-monitor/icon-display false
  dconf write /org/gnome/shell/extensions/system-monitor/cpu-graph-width 66
  dconf write /org/gnome/shell/extensions/system-monitor/cpu-show-text false
  dconf write /org/gnome/shell/extensions/system-monitor/memory-graph-width 66
  dconf write /org/gnome/shell/extensions/system-monitor/memory-show-text false
  dconf write /org/gnome/shell/extensions/system-monitor/net-graph-width 66
  dconf write /org/gnome/shell/extensions/system-monitor/net-show-text false
  dconf write /org/gnome/shell/extensions/system-monitor/net-up-color "'#cc0000ff'"
  dconf write /org/gnome/shell/extensions/system-monitor/net-down-color "'#73d216ff'"
  dconf write /org/gnome/shell/extensions/system-monitor/net-uperrors-color "'#e0006eff'"

  # Theme
  dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
  dconf write /org/gnome/desktop/interface/cursor-theme "'handhelds'"
  dconf write /org/gnome/shell/enabled-extensions "['system-monitor@paradoxxx.zero.gmail.com', 'ubuntu-appindicators@ubuntu.com']"
  dconf write /org/gnome/shell/enabled-extensions "['system-monitor@paradoxxx.zero.gmail.com', 'ubuntu-appindicators@ubuntu.com', 'ubuntu-dock@ubuntu.com']"
  dconf write /org/gnome/desktop/interface/show-battery-percentage true
  dconf write /org/gnome/shell/enable-hot-corners true
  dconf write /org/gnome/desktop/interface/clock-show-date true
  dconf write /org/gnome/desktop/interface/clock-show-seconds true
  dconf write /org/gnome/desktop/calendar/show-weekdate true
  dconf write /org/gnome/desktop/wm/preferences/resize-with-right-button true

  # system
  dconf write /org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock true
  # gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
  dconf write /org/gnome/shell/extensions/dash-to-dock/click-action "'minimize'"
  dconf write /org/gnome/desktop/peripherals/touchpad/two-finger-scrolling-enabled true
  dconf write /org/gnome/desktop/peripherals/touchpad/speed 0.66
  dconf write /org/gnome/desktop/peripherals/mouse/speed 0.66
  dconf write /org/gnome/desktop/session/idle-delay "uint32 0"
  dconf write /org/gnome/settings-daemon/plugins/power/power-button-action "'interactive'"
  dconf write /org/gnome/shell/favorite-apps "['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']"
  dconf write /org/gnome/settings-daemon/plugins/sharing/vino-server/enabled-connections "['60948f78-0c53-4b83-a270-c358cf3e79ff']"

  # guake
  dconf write /apps/guake/style/background/transparency 88
  dconf write /apps/guake/keybindings/global/show-hide "'<Shift>space'"
  dconf write /apps/guake/general/use-trayicon false
  dconf write /apps/guake/general/window-losefocus true
  dconf write /apps/guake/general/window-refocus true
  dconf write /apps/guake/general/use-scrollbar true
  dconf write /apps/guake/general/infinite-history true
  dconf write /apps/guake/keybindings/local/previous-tab "'<Primary><Shift>h'"
  dconf write /apps/guake/keybindings/local/next-tab "'<Primary><Shift>l'"
  dconf write /apps/guake/keybindings/local/move-tab-left "'<Primary><Shift>Left'"
  dconf write /apps/guake/keybindings/local/move-tab-right "'<Primary><Shift>Right'"
  dconf write /apps/guake/style/font/palette-name "'Solarized Dark'"
  dconf write /apps/guake/general/use-default-font false
  dconf write /apps/guake/style/font/style "'Monospace 16'"
  dconf write /apps/guake/style/cursor-shape 2
  dconf write /apps/guake/keybindings/local/new-tab "'<Super>t'"
  dconf write /apps/guake/general/use-trayicon true
  dconf write /apps/guake/general/window-tabbar false
  dconf write /apps/guake/general/tab-ontop true

  # gnome-terminal
  dconf write /org/gnome/terminal/legacy/keybindings/prev-tab "'<Primary><Shift>l'"
  dconf write /org/gnome/terminal/legacy/keybindings/next-tab "'<Primary><Shift>h'"
  dconf write /org/gnome/terminal/legacy/keybindings/find-previous "'<Primary><Shift>F3'"
  dconf write /org/gnome/terminal/legacy/keybindings/find-clear "'disabled'"
  dconf write o/org/gnome/terminal/legacy/theme-variant "'dark'"

  # imarslo theme
  # dconf read /org/gnome/terminal/legacy/profiles:/list
  GNOMETERMPRO="9af0c771-9c5b-4001-bba5-7fe26d54d2e7"
  dconf write /org/gnome/terminal/legacy/profiles:/list "['23c2d5ac-3c62-4506-a998-ac22f430dcdf', '${GNOMETERMPRO}']"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/visible-name "'imarslo'"
  dconf write /org/gnome/terminal/legacy/profiles:/default "'${GNOMETERMPRO}'"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/default-size-columns 96
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/default-size-rows 28
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/use-system-font false
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/font "'Monospace 16'"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/cursor-shape "'underline'"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/use-theme-colors false
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/foreground-color "'rgb(131,148,150)'"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/background-color "'rgb(0,43,54)'"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/use-theme-transparency false
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/use-transparent-background true
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/background-transparency-percent 7
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/palette "['rgb(7,54,66)', 'rgb(220,50,47)', 'rgb(133,153,0)', 'rgb(181,137,0)', 'rgb(38,139,210)', 'rgb(211,54,130)', 'rgb(42,161,152)', 'rgb(238,232,213)', 'rgb(0,43,54)', 'rgb(203,75,22)', 'rgb(88,110,117)', 'rgb(101,123,131)', 'rgb(131,148,150)', 'rgb(108,113,196)', 'rgb(147,161,161)', 'rgb(253,246,227)']"
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/scrollback-unlimited true
  dconf write /org/gnome/terminal/legacy/profiles:/:${GNOMETERMPRO}/scroll-on-output true
}

function marslorized() {
  # auto startup for gnome-session-properity
  [ ! -d $HOME/.config/autostart ] && mkdir -p $HOME/.config/autostart
cat > $HOME/.config/autostart/guake.desktop << EOF
[Desktop Entry]
Type=Application
Exec=/usr/bin/guake
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Guake
Name=Guake
Comment[en_US]=Guake Terminal
Comment=Guake Terminal
EOF

cat > $HOME/.config/autostart/gnome-terminal.desktop << EOF
[Desktop Entry]
Type=Application
Exec=/usr/bin/gnome-terminal
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=gnome-terminal
Name=gnome-terminal
Comment[en_US]=Gnome Terminal
Comment=Gnome Terminal
EOF

  # Git Repos
  [ ! -d "$HOME/.marslo" ] && mkdir -p "$HOME/.marslo"
  [ ! -d "${GITHOME}/marslo" ] && mkdir -p ${GITHOME}/marslo
  [ ! -d "${GITHOME}/tools" ] && mkdir -p ${GITHOME}/tools
  [ ! -d "$HOME/.local/share/gnome-shell/extensions" ] && mkdir -p "$HOME/.local/share/gnome-shell/extensions"

  git clone https://github.com/Marslo/mytools.git ${GITHOME}/marslo/mytools
  git clone https://github.com/Marslo/myvim.git ${GITHOME}/marslo/myvim
  git clone https://github.com/Marslo/mylinux.git ${GITHOME}/marslo/mylinux
  git clone https://github.com/Marslo/myblog.git ${GITHOME}/marslo/myblog
  # git clone git@github.com:paradoxxxzero/gnome-shell-system-monitor-applet.git ${GITHOME}/tools/gnome-shell-system-monitor-applet
  if git clone https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet.git ${GITHOME}/tools/gnome-shell-system-monitor-applet; then
    ln -sf "${GITHOME}/tools/gnome-shell-system-monitor-applet/system-monitor@paradoxxx.zero.gmail.com" "$HOME/.local/share/gnome-shell/extensions/system-monitor@paradoxxx.zero.gmail.com"
    gnome-shell-extension-tool --enable-extension=system-monitor@paradoxxx.zero.gmail.com
  fi

  vim +GetVundle +qa!
  vim +BundleInstall +qa!

  git clone git@github.com:vim/vim.git ${GITHOME}/tools/vim
  sudo updatedb
}

function systemSetup() {
  systemEnv
  systemX11
}

function personalSetup() {
  systemDualNetwork
  systemMadCatzMouse
}

function rockInRoll() {
  systemSetup
  personalSetup
  systemAPTIntranet
  aptInstall
  systemSSProxy
  systemProxyService
  devEnvGetPackage
  devEnvInstall
  systemSSH
  systemDconf
  marslorized
}

if [ "my.artifactory.com" == "${ARTIFACTORYNAME}" ]; then
  reportError "Artifactory Name haven't been setup!"
  exit 1
fi

if [ "45.35.34.44" == "${SOCKSSERVER}" ]; then
  reportError "ssmarslo.json haven't been setup!"
  exit 1
fi

rockInRoll
sudo /usr/share/update-notifier/notify-reboot-required
