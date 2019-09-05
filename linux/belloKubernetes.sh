#!/bin/bash
# =============================================================================
#   FileName: belloKubernetes.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2018-11-08 17:58:12
# LastChange: 2019-09-05 11:54:57
# =============================================================================

CURL="/usr/bin/curl"
WGET="/usr/bin/wget"
GREP="/usr/bin/grep"
SED="/usr/bin/sed"

# Get Current Ip address
SERVERADDRESS=$(ip -4 a s "$(netstat -nr | grep UG | grep -E '^0.0.0' | awk -F' ' '{print $NF}')"| grep inet | awk -F' ' '{print $2}' | awk -F'/' '{print $1}')
# OR
# SERVERADDRESS=$(ip route get "$(nslookup apple.com | grep Address | tail -1 | awk -F':' '{print $NF}')" | head -1 | awk -F' ' '{print $NF}')

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
  exit 1
}

function setupEnv() {
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
  sudo systemctl mask firewalld
  sudo systemctl is-enabled firewalld
  sudo systemctl is-active firewalld
  sudo firewall-cmd --state

  sudo swapoff -a
  sudo bash -c "${SED} -e 's:^\\(.*swap.*\\)$:# \\1:' -i /etc/fstab"

  setenforce 0
  sudo bash -c "${SED} 's/^SELINUX=enforcing$/SELINUX=permissive/' -i /etc/selinux/config"
  sudo bash -c "cat >  /etc/sysctl.d/k8s.conf" << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
  sudo sysctl --system
}

function installApp() {
  sudo yum -y check-update
  sudo bash -c 'cat > /etc/yum.repos.d/kubernetes.repo' <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum-config-manager --enable docker-ce-edge
  sudo yum-config-manager --enable docker-ce-test
  sudo yum-config-manager --enable extras

  sudo yum check-update
  sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
  sudo yum install docker-ce-18.06.1.ce-3.el7
  sudo yum install -y kubectl-1.12.3-0.x86_64 kubelet-1.12.3-0.x86_64 kubeadm-1.12.3-0.x86_64 --disableexcludes=kubernetes
}

function setupDocker() {
  sudo usermod -a -G docker "$(whoami)"
  sudo systemctl start docker && sudo systemctl enable docker
}

function setupKubernetes() {
  sudo systemctl start kubelet && sudo systemctl enable kubelet
  sudo kubeadm init --ignore-preflight-errors=all --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${SERVERADDRESS}
  if [ $? -eq 0 ]; then
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
  else
    reportError "Kubernetes master initial failed"
  fi
}

function setupK8sMaster() {
  [ "" == "${SERVERADDRESS}" ] && reportError "SERVERADDRESS haven't been setup!"
  for cmd in ${GREP} ${CURL} ${SED} ${WGET}; do
    [ ! -f ${cmd} ] && reportError "Command ${cmd} cannot be found in system!"
  done

  setupEnv
  installApp
  setupDocker
  setupKubernetes
}

setupK8sMaster
