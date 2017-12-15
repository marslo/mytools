#!/bin/bash -x

CURRENTUSER=$(whoami)
APPHOME=/home/${CURRENTUSER}
MARSLOHOME=${CURRENTHOME}/.marslo

DEVOPSHOME=/home/devops
SYNCSER=appadmin@161.91.26.175 #slave

CURRENTHOME=${DEVOPSHOME}

pushd $PWD

cd ${CURRENTHOME}

usermod -a -G sudo ${CURRENTUSER}
usermod -a -G adm ${CURRENTUSER}
usermod -a -G root ${CURRENTUSER}

sed -i '/^appadmin/d' /etc/sudoers
echo "${CURRENTUSER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

cp /etc/ssh/sshd_config{,.org}
sed -i 's/PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
sed -i 's/UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
echo "Banner /etc/ssh/server.banner" >> /etc/ssh/sshd_config

rsync -avzrlpgoD --delete --exclude=.vim/view --exclude=.vim/vimsrc --exclude=.vim/cache --exclude=.vim/.netrwhist --exclude=.ssh/known_hosts -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ' $SYNCSER:~/.vim $APPHOME/
rsync -avzrlpgoD --delete --exclude=.marslo/Tools $SYNCSER:~/.marslo $APPHOME/
rsync -avzrlpgoD $SYNCSER:~/.tmux.conf $APPHOME/.tmux.conf
rsync -avzrlpgoD $SYNCSER:~/.vimrc $APPHOME/.vimrc
# rsync -avzrlpgoD --exclude=.ssh/known_hosts appadmin@161.91.26.175:~/.ssh .

cat << 'EOF' > ${CURRENTHOME}/.inputrc
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
ln -sf /root/.ssh/tools@cdi /root/.ssh/id_rsa

mkdir -p /root/.vim/cache
mkdir ${CURRENTHOME}/.vim/cache
touch ${CURRENTHOME}/.vim_mru_files
ln -sf ${CURRENTHOME}/.vimrc /root/.vimrc
ln -sf ${CURRENTHOME}/.inputrc /root/.inputrc
ln -sf ${CURRENTHOME}/.tmux.conf /root/.tmux.conf
ln -sf ${CURRENTHOME}/.vim/bundle /root/.vim/bundle
chown -R ${CURRENTUSER}:${CURRENTUSER} ${CURRENTHOME}/.vim/cache
chown -R ${CURRENTUSER}:${CURRENTUSER} ${CURRENTHOME}/.vim_mru_files

# Network configuration
cp /etc/rc.local{,.org}
sed -i 's/exit.*//' /etc/rc.local

cat << 'EOF' >> /etc/rc.local
echo "search CODE1.EMI.PHILIPS.COM" >> /etc/resolv.conf
echo "nameserver 130.147.159.139" >> /etc/resolv.conf
echo "nameserver 161.92.35.78" >> /etc/resolv.conf

exit 0
EOF

cp /etc/resolv.conf{,.org}
cat << 'EOF' >> /etc/resolv.conf
echo "search CODE1.EMI.PHILIPS.COM" >> /etc/resolv.conf
echo "nameserver 130.147.159.139" >> /etc/resolv.conf
echo "nameserver 161.92.35.78" >> /etc/resolv.conf
EOF

cp /etc/hosts{,.org}
cat << 'EOF' >> /etc/hosts
161.91.26.140 pww.gitlab.cdi.philips.com Gitlab gitlab
161.91.26.166 pww.jira.cdi.philips.com JIRA jira
161.91.26.168 pww.confluence.cdi.philips.com Confluence confluence
161.91.26.171 pww.artifactory.cdi.philips.com Artifactory artifactory
161.91.26.173 pww.sonar.cdi.philips.com Sonar sonar
161.91.26.174 pww.jenkins.cdi.philips.com Jenkins jenkins
161.91.26.175 pww.slave01.cdi.philips.com slave slave
EOF

# Package management
cat << 'EOF' > /etc/apt/apt.conf
Acquire::http::Proxy "http://161.91.27.236:8080";
Acquire::https::Proxy "http://161.91.27.236:8080";
Acquire::ftp::Proxy "http://161.91.27.236:8080";
EOF

cat << 'EOF' > /etc/apt/apt.conf.d/99ignoresave
Dir::Ignore-Files-Silently:: "(.save|.distupgrade)$";
Dir::Ignore-Files-Silently:: "\.gz$";
Dir::Ignore-Files-Silently:: "\.save$";
Dir::Ignore-Files-Silently:: "\.distUpgrade$";
Dir::Ignore-Files-Silently:: "\.list_$";
EOF

cp /etc/apt/sources.list{,.org}
cat << 'EOF' > /etc/apt/sources.list
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

apt update -y
apt install -y bash-completion sysv-rc-conf tree dos2unix iptables-persistent mailutils policycoreutils build-essential gcc g++ make cmake liblxc1 lxc-common lxcfs landscape-common update-motd update-notifier-common apt-file netfilter-persistent ncurses-doc binutils cpp cpp-5 dpkg-dev fakeroot g++-5 gcc gcc-5 libasan2 libatomic1 libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libexpat1-dev libfakeroot libisl15 libitm1 liblsan0 libmpc3 libmpx0 libquadmath0 libstdc++-5-dev libtsan0 libubsan0 linux-libc-dev manpages-dev libssl-dev jq htop dstat ifstat libncurses5-dev libncursesw5-dev libpython-all-dev python-pip binutils-doc cpp-doc gcc-5-locales debian-keyring g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg gcc-multilib autoconf automake libtool flex bison gdb gcc-doc gcc-5-multilib libgcc1-dbg libgomp1-dbg libitm1-dbg libatomic1-dbg libasan2-dbg liblsan0-dbg libtsan0-dbg libubsan0-dbg libcilkrts5-dbg libmpx0-dbg libquadmath0-dbg libstdc++-5-doc python-setuptools-doc libpython2.7 dlocate python-docutils curl git m4 ruby texinfo libbz2-dev libexpat-dev libncurses-dev zlib1g-dev iftop libsensors4 sysstat traceroute
apt install -y sysstat
apt install -y libcurl4-gnutls-dev
apt install -y libcurl4-openssl-dev

# Install Chinese Language Pack
apt install language-pack-zh-hans
/usr/share/locales/install-language-pack zh_CN

apt upgrade -y
apt autoremove -y
apt-file update

# Disable apt-get upgrade
cp /etc/update-manager/release-upgrades{,.org}
sudo sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades

# IP table settings
iptables -F
iptables -L -n
iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
iptables -L -n
netfilter-persistent save
iptables-save > /etc/iptables/rules.v4

# MOTD Settings
cat << 'EOF' > /etc/landscape/client.conf
[sysinfo]
exclude_sysinfo_plugins = Temperature, LandscapeLink
EOF

mv /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/org.91-release-upgrade.org
mv /etc/update-motd.d/90-updates-available /etc/update-motd.d/org.90-updates-available.org
mv /etc/update-motd.d/10-help-text /etc/update-motd.d/org.10-help-text.org
cp /etc/update-motd.d/00-header /etc/update-motd.d/org.00-header.org
sed -i 's/printf.*/#&/' /etc/update-motd.d/00-header

# or
# chmod -x /etc/update-motd.d/91-release-upgrade
# chmod -x /etc/update-motd.d/90-updates-available
# chmod -x /etc/update-motd.d/10-help-text
# chmod -x /etc/update-motd.d/00-header

# Auto Upgrade Disable
sed -i 's/"1"/"0"/' /etc/apt/apt.conf.d/10periodic
sed -i 's/"1"/"0"/' /etc/apt/apt.conf.d/20auto-upgrades

run-parts /etc/update-motd.d/
/usr/lib/update-notifier/update-motd-updates-available --force
update-motd
dpkg-reconfigure tzdata

echo "export http_proxy=http://161.91.27.236:8080" >> /etc/profile
echo "export https_proxy=http://161.91.27.236:8080" >> /etc/profile
echo "export no_proxy=localhost,127.0.0.1,*.cdi.philips.com,*.*.cdi.philips.com,161.91.26.*,pww.jira.cdi.philips.com,161.91.26.166,pww.confluence.cdi.philips.com,161.91.26.168,pww.jenkins.cdi.philips.com,161.91.26.174,pww.sonar.cdi.philips.com,161.91.26.173,pww.artifactory.cdi.philips.com,161.91.26.171,pww.slave01.cdi.philips.com,161.91.26.175,pww.gitlab.cdi.philips.com,161.91.26.140" >> /etc/profile
echo "source ${CURRENTHOME}/.marslo/.marslorc" >> /etc/bash.bashrc
echo "export PATH=${CURRENTHOME}/.marslo/myprograms/vim80/bin:$PATH" >> /etc/bash.bashrc

vim +GetVundle +qa
vim +BundleInstall +qa
