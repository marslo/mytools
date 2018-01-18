#!/bin/bash -x

CURRENTUSER=$(whoami)
APPHOME=/home/${CURRENTUSER}
MARSLOHOME=${CURRENTHOME}/.marslo

DEVOPSHOME=/home/devops
SYNCSER=appadmin@161.91.26.175 #slave

CURRENTHOME=${DEVOPSHOME}
if [ ! -d "${CURRENTHOME}" ]; then
  echo "${CURRENTHOME} cannot be found. EXIT.";
  exit 1;
fi

pushd $PWD
cd ${CURRENTHOME}

sudo usermod -a -G sudo ${CURRENTUSER}
sudo usermod -a -G adm ${CURRENTUSER}
sudo usermod -a -G root ${CURRENTUSER}
sudo usermod -a -G docker ${CURRENTUSER}

sudo bash -c "sed -i \"/^appadmin/d\" /etc/sudoers"
sudo bash -c "echo \"${CURRENTUSER} ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"

sudo bash -c "cp /etc/ssh/sshd_config{,.org}"
sudo bash -c "sed -i 's/PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config"
sudo bash -c "sed -i 's/UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config"
sudo bash -c "echo \"Banner /etc/ssh/server.banner\" >> /etc/ssh/sshd_config"

rsync -avzrlpgoD --delete --exclude=.vim/view --exclude=.vim/vimsrc --exclude=.vim/cache --exclude=.vim/.netrwhist --exclude=.ssh/known_hosts -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ' $SYNCSER:~/.vim $APPHOME/
rsync -avzrlpgoD --delete --exclude=.marslo/Tools $SYNCSER:~/.marslo $APPHOME/
rsync -avzrlpgoD $SYNCSER:~/.tmux.conf $APPHOME/.tmux.conf
rsync -avzrlpgoD $SYNCSER:~/.vimrc $APPHOME/.vimrc
# rsync -avzrlpgoD --exclude=.ssh/known_hosts appadmin@161.91.26.175:~/.ssh .

cat > ${CURRENTHOME}/.inputrc << 'EOF'
set convert-meta on
set completion-ignore-case on
set show-all-if-ambiguous on
set show-all-if-unmodified on
set mark-symlinked-directories on
set print-completions-horizontally on
EOF
chown ${CURRENTUSER}:${CURRENTUSER} ${CURRENTHOME}/.inputrc

# rsync -avzrlpgoD $SYNCSER:~/.inputrc $APPHOME/.inputrc
# mkdir -p $MARSLOHOME/Tools
# cd !$
# git clone https://github.com/Marslo/LinuxStuff.git
# git clone https://github.com/Marslo/VimConfig.git

# cp $MARSLOHOME/Tools/VimConfig/Configurations/vimrc_terminal ${CURRENTHOME}/.vimrc
# cp $MARSLOHOME/Tools/LinuxStuff/Configs/HOME/.marslo/.marslorc $MARSLOHOME
# cp $MARSLOHOME/Tools/LinuxStuff/Configs/HOME/.marslo/.bye_marslo $MARSLOHOME
# cp $MARSLOHOME/Tools/LinuxStuff/Configs/HOME/.marslo/.bello_marslo $MARSLOHOME
# cp -r ${CURRENTHOME}/.marslo/Tools/LinuxStuff/Configs/HOME/.marslo/.devops $MARSLOHOME

cp ${CURRENTHOME}/.ssh/tools@cdi* /root/.ssh
sudo ln -sf /root/.ssh/tools@cdi /root/.ssh/id_rsa

sudo mkdir -p /root/.vim/cache
mkdir ${CURRENTHOME}/.vim/cache
touch ${CURRENTHOME}/.vim_mru_files
ln -sf ${CURRENTHOME}/.vimrc /root/.vimrc
ln -sf ${CURRENTHOME}/.inputrc /root/.inputrc
ln -sf ${CURRENTHOME}/.tmux.conf /root/.tmux.conf
ln -sf ${CURRENTHOME}/.vim/bundle /root/.vim/bundle
chown -R ${CURRENTUSER}:${CURRENTUSER} ${CURRENTHOME}/.vim/cache
chown -R ${CURRENTUSER}:${CURRENTUSER} ${CURRENTHOME}/.vim_mru_files

# Network configuration
sudo cp /etc/rc.local{,.org}
sudo bash -c "sed -i 's/exit.*//' /etc/rc.local"

sudo bash -c 'cat >> /etc/rc.local' << 'EOF'
search CODE1.EMI.PHILIPS.COM
nameserver 130.147.159.139
nameserver 161.92.35.78

exit 0
EOF

sudo cp /etc/resolv.conf{,.org}
sudo bash -c 'cat >> /etc/resolv.conf' << 'EOF'
search CODE1.EMI.PHILIPS.COM
nameserver 130.147.159.139
nameserver 161.92.35.78
EOF

cp /etc/hosts{,.org}
sudo bash -c 'cat >> /etc/hosts' << 'EOF'
130.147.219.15 pww.gitlab.cdi.philips.com Gitlab gitlab
130.147.219.16 pww.jira.cdi.philips.com JIRA jira
130.147.219.18 pww.confluence.cdi.philips.com Confluence confluence
130.147.219.19 pww.artifactory.cdi.philips.com Artifactory artifactory
130.147.219.20 pww.sonar.cdi.philips.com Sonar sonar
130.147.219.23 pww.jenkins.cdi.philips.com Jenkins jenkins
130.147.219.24 pww.slave01.cdi.philips.com Slave slave
EOF

# Package management
sudo bash -c 'cat > /etc/apt/apt.conf' << 'EOF'
Acquire::http::proxy "http://42.99.164.34:10015/";
Acquire::https::proxy "https://42.99.164.34:10015/";
Acquire::ftp::proxy "ftp://42.99.164.34:10015/";
Acquire::socks::proxy "socks://42.99.164.34:10015/";
EOF

sudo bash -c 'cat > /etc/apt/apt.conf.d/99ignoresave' << 'EOF'
Dir::Ignore-Files-Silently:: "(.save|.distupgrade)$";
Dir::Ignore-Files-Silently:: "\.gz$";
Dir::Ignore-Files-Silently:: "\.save$";
Dir::Ignore-Files-Silently:: "\.distUpgrade$";
Dir::Ignore-Files-Silently:: "\.list_$";
EOF

sudo cp /etc/apt/sources.list{,.org}
sudo bash -c 'cat > /etc/apt/sources.list' << 'EOF'
deb http://us.archive.ubuntu.com/ubuntu/ xenial main restricted
deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted
deb http://us.archive.ubuntu.com/ubuntu/ xenial universe
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial universe
deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe
deb http://us.archive.ubuntu.com/ubuntu/ xenial multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial multiverse
deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse
deb http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu xenial partner
deb-src http://archive.canonical.com/ubuntu xenial partner
deb http://security.ubuntu.com/ubuntu xenial-security main restricted
deb-src http://security.ubuntu.com/ubuntu xenial-security main restricted
deb http://security.ubuntu.com/ubuntu xenial-security universe
deb-src http://security.ubuntu.com/ubuntu xenial-security universe
deb http://security.ubuntu.com/ubuntu xenial-security multiverse
deb-src http://security.ubuntu.com/ubuntu xenial-security multiverse
EOF

sudo bash -c 'cat > /etc/apt/sources.list.d/cwchien-ubuntu-gradle-xenial.list' << 'EOF'
deb http://ppa.launchpad.net/cwchien/gradle/ubuntu xenial main
# deb-src http://ppa.launchpad.net/cwchien/gradle/ubuntu xenial main
EOF

sudo bash -c 'cat > /etc/apt/sources.list.d/git-core-ubuntu-ppa-xenial.list' << 'EOF'
deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
# deb-src http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
EOF

sudo bash -c 'cat > /etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-xenial.list' << 'EOF'
deb http://ppa.launchpad.net/webupd8team/y-ppa-manager/ubuntu xenial main
# deb-src http://ppa.launchpad.net/webupd8team/y-ppa-manager/ubuntu xenial main
EOF

sudo apt update
sudo apt install -y bash-completion tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils curl git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute vim-gtk3 apt-transport-https ca-certificates software-properties-common
sudo apt install -y sysstat
sudo apt install -y libcurl4-gnutls-dev
sudo apt install -y libcurl4-openssl-dev

# Install Chinese Language Pack
sudo apt install language-pack-zh-hans
sudo /usr/share/locales/install-language-pack zh_CN

sudo apt upgrade
sudo apt autoremove -y
sudo apt-file update

# Disable apt-get upgrade
sudo cp /etc/update-manager/release-upgrades{,.org}
sudo bash -c "sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades"

# IP table settings
sudo iptables -F
sudo iptables -L -n
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo iptables -L -n
sudo netfilter-persistent save
iptables-save > /etc/iptables/rules.v4

# MOTD Settings
sudo bash -c 'cat > /etc/landscape/client.conf' << 'EOF'
[sysinfo]
exclude_sysinfo_plugins = Temperature, LandscapeLink
EOF

sudo chmod -x /etc/update-motd.d/91-release-upgrade
sudo chmod -x /etc/update-motd.d/90-updates-available
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/00-header
# or
# mv /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/org.91-release-upgrade.org
# mv /etc/update-motd.d/90-updates-available /etc/update-motd.d/org.90-updates-available.org
# mv /etc/update-motd.d/10-help-text /etc/update-motd.d/org.10-help-text.org
# cp /etc/update-motd.d/00-header /etc/update-motd.d/org.00-header.org
# sed -i 's/printf.*/#&/' /etc/update-motd.d/00-header


# Auto Upgrade Disable
sed -i 's/"1"/"0"/' /etc/apt/apt.conf.d/10periodic
sed -i 's/"1"/"0"/' /etc/apt/apt.conf.d/20auto-upgrades

sudo run-parts /etc/update-motd.d/
sudo /usr/lib/update-notifier/update-motd-updates-available --force
sudo update-motd
sudo dpkg-reconfigure tzdata


sudo bash -c 'cat >> /etc/profile' << EOF

echo export http_proxy=http://42.99.164.34:10015
echo export https_proxy=\$http_proxy
echo export ftp_proxy=\$http_proxy
export no_proxy=localhost,127.0.0.1,pww.*.cdi.philips.com,130.*.*.*,161.*.*.*,pww.artifactory.cdi.philips.com,130.147.219.19,healthyliving.cn-132.lan.philips.com,*.cn-132.lan.philips.com,130.147.183.165,161.85.30.130,pww.sonar.cdi.philips.com,130.147.219.20,pww.gitlab.cdi.philips.com,130.147.219.15,pww.slave01.cdi.philips.com,130.147.219.24,pww.confluence.cdi.philips.com,130.147.219.18,pww.jira.cdi.philips.com,130.147.219.16,161.*.*.*,162.*.*.*,130.*.*.*,bdhub.pic.philips.com,161.85.30.130,tfsemea1.ta.philips.com,130.147.219.23,pww.jenkins.cdi.philips.com,blackduck.philips.com,fortify.philips.com,161.85.30.130
EOF

sudo bash -c 'cat >> /etc/bash.bashrc' << EOF
source /home/appadmin/.marslo/.marslorc"
export PATH=/home/appadmin/.marslo/myprograms/vim80/bin:$PATH"
EOF

vim +GetVundle +qa
vim +BundleInstall +qa

# For docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) edge"

sudo curl -fsSL get.docker.com -o get-docker.sh
sudo sh -x get-docker.sh
sudo chown ${CURRENTUSER}:${CURRENTUSER} get-docker.sh

# for artifactory
curl -L https://jfrog.bintray.com/run/art-compose/5.7.2/art-compose > art-compose
chmod +x art-compose
sudo chown ${CURRENTUSER}:${CURRENTUSER} art-compose

dconf load /org/gnome/terminal/ <ubuntu1710_terminal_font18_backup.bak
