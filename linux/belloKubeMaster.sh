#!/bin/bash
# shellcheck disable=SC2224,SC1117,SC2009
# =============================================================================
#   FileName: belloKubeMaster.sh
#     Author: marslo.jiao@philips.com
#    Created: 2018-04-13 16:51:09
# LastChange: 2018-04-19 19:32:39
# =============================================================================

sourceMain="/etc/apt/sources.list"
sourcePath="/etc/apt/sources.list.d"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")

ARTIFACTORYNAME="my.artifactory.com"
ARTIFACTORYHOME="http://${ARTIFACTORYNAME}/artifactory"

SOCKSPORT=1234
SOCKSPROXY="socks5://127.0.0.1:${SOCKSPORT}"

SSHOME="$HOME/.marslo/ss"
SSLOGHOME="${SSHOME}/logs"
SSLOGFILE="${SSLOGHOME}/ssmarslo.log"

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function preSetup() {
  sudo ufw disable
  sudo swapoff -a
  sudo bash -c "sed -i -e 's:^\\(.*swap.*\\)$:# \\1:' /etc/fstab"

  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

  sudo usermod -a -G root "$(whoami)"
  sudo usermod -a -G adm "$(whoami)"
  sudo usermod -a -G sudo "$(whoami)"
  sudo usermod -a -G docker "$(whoami)"

  [ -f /etc/sysctl.conf ] && mv /etc/sysctl.conf{,.bak.${TIMESTAMPE}}

sudo bash -c "cat >> /etc/sysctl.conf" << EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  if ! grep 1 /proc/sys/net/bridge/bridge-nf-call-iptables; then
    reportError "sysctl net.bridge.bridge-nf-call-iptables=1 set failed!"
  fi
  sudo sysctl -p

  if grep -E "^127\.0\.0\.1.*devops-kubernetes-master.*$" /etc/hosts; then
    sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
  fi
}

function setupAptRepo() {
  [ -f "${sourceMain}" ] && mv "${sourceMain}{,.bak.${TIMESTAMPE}}"
  [ -f "${sourcePath}/docker.list" ] && mv "${sourcePath}/docker.list{,.bak.${TIMESTAMPE}}"
  [ -f "${sourcePath}/kubernetes.list" ] && mv "${sourcePath}/kubernetes.list{,.bak.${TIMESTAMPE}}"
  mkdir -p "${sourcePath}/backups" && mv "${sourcePath}*.list.bak.*" "${sourcePath}/backups/"

  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-google/doc/apt-key.gpg | sudo apt-key add –
  curl -fsSL ${ARTIFACTORYHOME}/debian-remote-docker/gpg | sudo apt-key add -

  sudo bash -c "cat > ${sourceMain}" << EOF
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

  sudo bash -c "cat > ${sourcePath}/docker.list" << EOF
  deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker artful edge
  deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker artful stable
  deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker xenial edge
  deb [arch=amd64] ${ARTIFACTORYHOME}/debian-remote-docker xenial stable
  # deb [arch=amd64] https://download.docker.com/linux/ubuntu artful edge
  # deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial edge
EOF

  sudo bash -c "cat > ${sourcePath}/kubernetes.list" << EOF
  deb ${ARTIFACTORYHOME}/debian-remote-google kubernetes-xenial main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-xenial main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-xenial-unstable main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-yakkety main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes kubernetes-yakkety-unstable main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes cloud-sdk-yakkety-unstable main
  # deb ${ARTIFACTORYHOME}/debian-remote-kubernetes cloud-sdk-yakkety main
EOF
}

function appsInstall() {
  suod apt update
  sudo apt install -y docker-ce="$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')"
  # sudo apt install kubeadm=1.10.0-00 kubelet=1.10.0-00 kubectl=1.10.0-00
  sudo apt install -y kubelet kubeadm kubectl
  echo "docker-ce hold" | sudo dpkg --set-selections
  sudo apt-mark hold docker-ce
  sudo apt-mark hold kubeadm
  sudo apt-mark hold kubectl
  sudo apt-mark hold kubelet

  apt-mark showhold
  ls -altrh /etc/kubernetes /var/lib/kubelet /var/lib/etcd
}

function dockerEnvSetup() {
[ ! -d /etc/systemd/system/docker.service.d ] && sudo mkdir -p /etc/systemd/system/docker.service.d
sudo bash -c "cat > /etc/systemd/system/docker.service.d/socks5-proxy.conf" << EOF
[Service]
Environment="ALL_PROXY=${SOCKSPROXY}" "NO_PROXY=localhost,127.0.0.1,${ARTIFACTORYNAME},130.147.0.0/16,130.145.0.0/16"

EOF

  wget -L ${ARTIFACTORYHOME}/devops/docker/${ARTIFACTORYNAME}-ca.crt
  sudo cp ${ARTIFACTORYNAME}-ca.crt /usr/local/share/ca-certificates/
  ls -Altrh !$
  sudo update-ca-certificates
  sudo systemctl daemon-reload
  sudo systemctl restart docker.service
}

function kubeletConfig() {
  if docker info  | grep -i cgroup | grep cgroupfs > /dev/null; then
    [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ] && sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf{,.bak.${TIMESTAMPE}}
    sudo bash -c "sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
  fi
}

function setupProxy() {
  sudo chown -R "$(whoami)":"$(whoami)" /tmp
  [ ! -d ~/.marslo ] && mkdir -p ~/.marslo

if [ ! -f ~/.marslo/ssmarslo.json ]; then
cat > ~/.marslo/ssmarslo.json << EOF
{
    "server":"my.ss.ip",
    "server_port": myssport,
    "local_address": "0.0.0.0",
    "local_port":${SOCKSPORT},
    "password":"mysspassword",
    "timeout":300,
    "method":"myssmethod",
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

    [ ! -d "${SSLOGHOME}" ] && mkdir -p ${SSLOGHOME}
    [ ! -f "${SSLOGFILE}" ] && touch ${SSLOGFILE}

sudo bash -c "cat > /lib/systemd/system/marsloProxy.service" << EOF
[Unit]
Description=Start shadowsocks proxy locally

[Service]
ExecStart=/usr/local/bin/ssmarslo

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable marsloProxy.service
    sudo systemctl start marsloProxy.service
    sudo systemctl -l | grep marsloProxy
    ps auxfww | grep sslocal
  fi
}

function kubeinit() {
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
  sudo systemctl status kubelet

  sudo kubeadm init --ignore-preflight-errors=all --pod-network-cidr=10.244.0.0/16
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config

  # install flannel plugin
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
  # create weave for dns
  kubectl create -f https://git.io/weave-kube
  # deloy dashboard
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  kubectl proxy

  kubectl get nodes --namespace=kube-system
  kubectl get pods --namespace=kube-system
  kubectl get all --namespace=kube-system
}

function envTest() {
  curl -x ${SOCKSPROXY} -v -l https://k8s.gcr.io/v1/_ping
  docker pull k8s.gcr.io/kube-apiserver-amd64:v1.10.5
  env | grep proxy
}

setupRepo
