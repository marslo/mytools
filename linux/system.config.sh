#!/bin/bash
# set -x

# Usage
usage(){
cat << EOF
Usage: basic_env.sh <Option>
       Options:
          master  ===> Install host as master node
          slave   ===> Install host as slave node
          all     ===> Install host as both master and slave node
EOF
exit 1;
}

# Stop and disable SELINUX and firewall
disable_selinux_firewall(){
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
  /usr/sbin/setenforce 0
  systemctl disable firewalld && systemctl stop firewalld

}
# Install some dependecy tools
install_dependency_tools(){
  RPMS="ntpdate vim"
  /usr/bin/yum install -y $RPMS
}

sync_clock(){
  mv /etc/localtime /etc/localtime_bak
  ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  NTP_SERVER="cn.pool.ntp.org"
  /usr/sbin/ntpdate $NTP_SERVER
  (crontab -l 2>/dev/null; echo "0 6 * * * /usr/sbin/ntpdate $NTP_SERVER") | crontab -
}

# Adjust kernel parameters
update_sysconfig(){
cp -p /etc/sysctl.conf /etc/sysctl.conf_bak
cat >/etc/sysctl.conf<<EOF
fs.file-max = 9999999
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_wmem = 8192 131072 16777216
net.ipv4.tcp_rmem = 32768 131072 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.ip_local_port_range = 1024 65535
net.ip_conntrack_max = 65535
net.netfilter.ip_conntrack_max=65535
net.netfilter.ip_conntrack_tcp_timeout_established=180
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
EOF

modprobe nf_conntrack_ipv4
sysctl -p

cp -p /etc/security/limits.conf /etc/security/limits.conf_bak
cat >>/etc/security/limits.conf<<EOF
*  soft    nofile          65535
*  hard   nofile          65535
EOF

cat >>/etc/profile<<EOF
ulimit -HSn 65535
EOF

#sed -i '12aulimit -HSn 65535' /etc/rc.local
}

# Install docker-ce
install_docker(){
  echo "####################### Starting Install Docker ########################\n"
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager \
  --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce
  systemctl restart docker && systemctl enable docker
}

# Install Zookeeper, Mesos and Marathon
install_mesos_marathon(){
  /usr/bin/rpm -ivh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
  echo "Starting Install ZooKeeper, Mesos and Marathon ...\n"
  yum install -y mesos marathon mesosphere-zookeeper
}

install_mesos(){
  /usr/bin/rpm -ivh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
  echo "Starting Install Mesos ...\n"
  yum install -y mesos
}

# Config Mesos according to the role of this host
config_mesos(){
  if [ $1 == 'master' ]; then
    echo "Starting config Mesos master ...\n"
    echo 1 > /var/lib/zookeeper/myid
    echo "server.1=$LOCAL_IP:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
    echo "zk://$LOCAL_IP:2181/mesos" > /etc/mesos/zk
    echo "$LOCAL_IP" > /etc/mesos-master/ip
    echo 1 > /etc/mesos-master/quorum
    echo "$LOCAL_IP" > /etc/mesos-master/hostname
    echo manual | tee /etc/init/mesos-slave.override
    systemctl restart zookeeper
    systemctl restart mesos-master
    systemctl restart mesos-slave
  elif [ $1 == 'slave' ]; then
    echo 'Starting config Mesos slave ...\n'
    echo 'docker,mesos' > /etc/mesos-slave/containerizers
    echo '5mins' > /etc/mesos-slave/executor_registration_timeout
    echo '5mins' > /etc/mesos-slave/docker_remove_delay
    echo "$LOCAL_IP" >  /etc/mesos-slave/ip
    echo "$LOCAL_IP" >  /etc/mesos-slave/hostname
    echo manual | tee /etc/init/mesos-master.override
    echo manual | tee /etc/init/marathon.override
    systemctl restart mesos-slave
  elif [ $1 == 'all' ]; then
    echo 'Starting config both Mesos master and slave ...\n'
    echo 1 > /var/lib/zookeeper/myid
    echo "server.1=$LOCAL_IP:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
    echo "zk://$LOCAL_IP:2181/mesos" > /etc/mesos/zk
    echo "$LOCAL_IP" > /etc/mesos-master/ip
    echo "$LOCAL_IP" > /etc/mesos-master/hostname
    echo "$LOCAL_IP" >  /etc/mesos-slave/ip
    echo "$LOCAL_IP" >  /etc/mesos-slave/hostname
    echo 1 > /etc/mesos-master/quorum
    echo 'docker,mesos' > /etc/mesos-slave/containerizers
    echo '5mins' > /etc/mesos-slave/executor_registration_timeout
    echo '5mins' > /etc/mesos-slave/docker_remove_delay
    systemctl restart zookeeper
    systemctl restart mesos-master
    systemctl restart mesos-slave
  else
    usage
  fi
}

# Config Marathon according to the role of this host
config_marathon(){
    echo "Starting config Marathon ..."
    mkdir -p /etc/marathon/conf
    echo "$LOCAL_IP" > /etc/marathon/conf/hostname
    echo "zk://$LOCAL_IP:2181/marathon" > /etc/marathon/conf/zk
    sed -i 's|ExecStart=/usr/share/marathon/bin/marathon|ExecStart=/usr/share/marathon/bin/marathon --master zk://$LOCAL_IP:2181/mesos --hostname $LOCAL_IP|' /usr/lib/systemd/system/marathon.service
    systemctl daemon-reload
    systemctl restart marathon
}

# Main

# This is need to be executed by ROOT account
if [ $USER != 'root' ]; then
  echo "Please run as root ..."
  exit 1;
fi

if [ $# != 1 ]; then
  usage
fi
# Get IP address of this host and update hosts file
LOCAL_IP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'`
echo $LOCAL_IP `hostname` >> /etc/hosts

if [ $1 == 'master' ]||[ $1 == 'all' ]; then
  disable_selinux_firewall
  install_dependency_tools
  sync_clock
  update_sysconfig
  install_docker
  install_mesos_marathon
  config_marathon
  config_mesos $1
elif [ $1 == 'slave' ]; then
  disable_selinux_firewall
  install_dependency_tools
  sync_clock
  update_sysconfig
  install_docker
  install_mesos
  config_mesos $1
else
  echo "################################################"
  echo "[ERROR:] Only master, slave or all option is supported!"
  echo "################################################"
  echo ""
  usage
fi
