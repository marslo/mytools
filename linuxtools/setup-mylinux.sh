echo "source /home/marslo/.marslo/.marslorc" >> ~/.bashrc
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

mkdir ${HOME}/.ssh
chmod 700 ${HOME}/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA463JBUU7YqdFDilIcgcxub5jB4x16E0V6CVQ9Kk+nvrNWrHL5s7XAwQIQM++0MxfbYlLl3mko59kk6kXLpYNEK4xMLGO1PBa7SAQfr7cvA40WAU7o3NzY/LG8iqLfk4ZKQioFxrnFHB9R1xcaoiI3YbGvpRGsZsMFR0DxIdyWoFLqp9n+pSstqRoDaBuhjiQoUz/UN0OG7YcaxBgu++zstboIzMBe0i73BQFNEzu4EQlDinRIcHe4HN/t1kDpxg7V7ZuLzvU8yhVu4sGCmBsXbgKPyoS2mubgXCb8NVBLnTM4tNUnQZ/fN1+rQ0KnqGMbGuhQRyZl/ZenahaGwJH6w== Marslo@Appliance' >> ~/.ssh/authorized_keys
/usr/sbin/restorecon .ssh/ .ssh/authorized_keys

cat << 'EOF' > /etc/yum.repos.d/artifactory.repo
[Artifactory]
name=Artifactory
baseurl=http://artifactory-appliance.engba.symantec.com/artifactory/yum-build-tools/rhel66/
enabled=1
gpgcheck=0
EOF

cat << 'EOF' > /etc/yum.repos.d/rhel-local.repo
[rhel-local]
name=rhel-local
baseurl=http://10.220.141.218/rhel66_x64-ci
enabled=1
gpgcheck=0
EOF

cat << 'EOF' > /etc/yum.repos.d/centos7-local.repo
[centos7-local]
name=centos7-local
baseurl=http://10.220.141.218/centos7_x64/
enabled=1
gpgcheck=0
EOF

yum install htop libcurl expat gettext make openssl expat-devel docbook-style-xsl docbook2X xmlto perl-devel perl-CPAN net-tools wget jdk gcc gcc-c++ g++ rpm-build gifsicle cmake mkisofs sloccount parallel syslinux livecd-tools isomd5sum lsscsi ncftp kernel-devel glibc-devel.i686 libstdc++.i686 e2fsprogs-devel libuuid-devel glibc.i686 perl-XML-LibXML libxml2 libxml2-devel zlib zlib-devel curl-devel libcurl-devel pam-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel jq.x86_64 libudev-devel lapack lapack-devel blas blas-devel libpng-devel freetype-devel libtiff-devel libjpeg-devel tcl-devel tk-devel perl-HTML-Parser perl-Compress-Raw-Zlib perl-IO-Zlib perl-libxml-perl perl-XML-LibXML perl-Time-Duration perl-Number-Format perl-Config-IniFiles perl-DateTime perl-YAML perl-Devel-CheckLib perl-Crypt-SSLeay readline readline-devel libxslt libxslt-devel bc glibc-devel mlocate python-pip
yum groupinstall 'Development Tools'

wget http://ftp.wayne.edu/gnu/make/make-4.2.tar.gz
tar xf make-*.tar.gz
cd make-*
./configure && make
sudo make install

# Install docbook2X-texi
ln -s /usr/bin/db2x_docbook2texi /usr/bin/docbook2x-texi

# Install asciidoc
wget http://downloads.sourceforge.net/project/asciidoc/asciidoc/8.6.9/asciidoc-8.6.9.tar.gz
tar xf asciidoc-8.6.9.tar.gz
cd asciidoc-*
autoconfig
./configure
make
sudo make install

# Install Git
wget https://github.com/git/git/archive/master.zip
unzip master.zip
cd git-*
make prefix=${HOME}/.marslo/myprograms/git all doc info
sudo make prefix=${HOME}/.marslo/myprograms/git install install-doc install-html install-info

# Download repos from github
mkdir -p ~/.marslo/Marslo/Tools/Git
mkdir -p ~/.vim

cd ~/.marslo/Marslo/Tools/Git
git clone git@github.com:Marslo/LinuxStuff.git repo_marslo/LinuxStuff
git clone git@github.com:Marslo/VimConfig.git repo_marslo/VimConfig

git clone git@github.com:Marslo/LeetCode_Python.git repo_programming/LeetCode_Python
git clone git@github.com:jw2013/Leetcode-Py.git repo_programming/Leetcode-Py
git clone git@github.com:nataliehan23/LeetCode-Python.git repo_programming/LeetCode-Python
git clone git@github.com:haikentcode/top10algoritms.git repo_programming/top10algoritms

git clone git@github.com:git/git.git repo_tools/git
git clone git@github.com:tmux/tmux.git repo_tools/tmux
git clone git@github.com:jbarber/vmware-perl.git repo_tools/vmware-perl
git clone git@github.com:vim/vim-win32-installer.git repo_tools/vim-win32-installer

git clone git@github.com:chef-cookbooks/jenkins.git repo_jenkins/jenkins-cookbook
git clone https://github.com/vim/vim.git ~/.vim/vimsrc

# Install Python
wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tar.xz
tar xf Python-2.7.12.tar.xz
cd Python-2.7*
make clean distclean
./configure --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" --enable-unicode=ucs4 --with-cxx-main=g++ --with--ensurepip=install
make
sudo make altinstall install
sudo ln -sf /usr/local/bin/python2.7 /usr/local/bin/python

pip install pexpect
pip install autopep8
pip install flake8

cd .vim
mkdir cache
sh -x .upgrade_vim

./vmware-install.pl --prefix=/opt/vmwarecli EULA_AGREED=yes --default
cpan -i Class::MethodMaker
cpan -i Fatal
cpan -i JSON::PP
cpan -i XML::SAX
cpan -i XML::LibXML
cpan IO::Compress::Zlib::Extra
cpan -i GAAS/libwww-perl-5.837.tar.gz
