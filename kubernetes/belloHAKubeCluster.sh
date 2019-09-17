#!/bin/bash
# shellcheck disable=SC2224,SC1117,SC2009,SC1078,SC1079
# =============================================================================
#   FileName: belloHAKubeCluster.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2019-09-02 22:48:57
# LastChange: 2019-09-17 22:43:04
# =============================================================================

# Inspired by:
  # https://blog.csdn.net/chenleiking/article/details/80136449
  # https://k8smeetup.github.io/docs/setup/independent/high-availability/

# hardcode
master1Ip='127.0.0.40'
master2Ip='127.0.0.42'
master3Ip='127.0.0.43'
master1Name='mytest-tst1'
master2Name='mytest-tst2'
master3Name='mytest-tst3'
virtualIpAddr='127.0.0.50'
leadIP="${master1Ip}"
leadHost="${master1Name}"

k8sVer='v1.15.3'
rtUrl='artifactory.my.com/artifactory'
# etcdPath='/etc/kubernetes/pki'
etcdPath='/etc/etcd/ssl'

# cfsslofficialUrl='https://pkg.cfssl.org/R1.2'
cfsslRtUrl="https://${rtUrl}/devops-local/k8s/R1.2/"
cfsslDownloadUrl="${cfsslRtUrl}"

etcdVer='v3.3.15'
# etcdGoogleDownload='https://storage.googleapis.com/etcd'
# etcdGithubDownload='https://github.com/etcd-io/etcd/releases/download'
etcdRtDownload="https://${rtUrl}/devops-local/k8s"
etcdDownloadUrl="${etcdRtDownload}"
etcdInitialCluster="${master1Name}=https://${master1Ip}:2380,${master2Name}=https://${master2Ip}:2380,${master3Name}=https://${master3Ip}:2380"

keepaliveVer='2.0.18'
# keepaliveUrl='https://www.keepalived.org/software'
keepaliveRtUrl="https://${rtUrl}/devops-local/k8s/software"
keepaliveDownloadUrl="${keepaliveRtUrl}"

# interface=$(ip route get 13.250.177.223 | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p') # get the route to github
interface=$(netstat -nr | grep -E 'UG|UGSc' | grep -E '^0.0.0|default' | grep -E '[0-9.]{7,15}' | awk -F' ' '{print $NF}')
ipAddr=$(ip a s ${interface} | sed -rn 's|.*inet ([0-9\.]{7,15})/[0-9]{2} brd.*$|\1|p')
peerName=$(hostname)

usage="""USAGE:
\n\t$0 [help] [independent function name]

\n\nNOTICE:
\n\tReplace the master{1..3}IP and master{1..3}Name to your real situation
\n\tleadMaster should be executed first to setup certificate; And then execute the followerMaster.
\n\tMake sure all servers can be visit passwordless by ssh for common user and root.
\n
\nExample:
\n\tSetup HA Cluster
\n\t\t$0 leadMaster     # on master-1
\n\t\t$0 followerMaster # on master-2 and master-3
\n
\n\tShow current information:
\n\t\t$0 showInfo

\n\nINDEPENDENT FUNCTION NAME:
"""

info="""CURRENT SERVER INFORMATION:
\n\tcurrent network interface: \t${interface}
\n\tcurrent IP address: \t\t${ipAddr}
\n
\n\tIP \t\t\t Hostname
\n\t${master1Ip} \t~~>\t ${master1Name}
\n\t${master2Ip} \t~~>\t ${master2Name}
\n\t${master3Ip} \t~~>\t ${master3Name}
\n\t
\n\tvirtualIpAddr: \t\t${virtualIpAddr}
\n\tleadIP: \t\t${leadIP}
\n\tleadHost: \t\t${leadHost}
\n\tetcdInitialCluster: \t${etcdInitialCluster}
\n
\nTools:
\n\tKubernetes version: \t${k8sVer}
\n\tetcd vesion: \t\t${etcdVer}
\n\tKeep alived version: \t${keepaliveVer}
\n
"""

function help() # show list of functions
{
  echo -e ${usage}
  # ${GREP} '^function' $0 | sed -re "s:^function([^(.]*).*$:\t\1:g"
  declare -F -p | sed -re "s:^.*-f(.*)$:\t\1:g"
}

function showInfo() {
  echo -e ${info}
}

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function timeSync() {
  sudo date --set="$(ssh ${leadIP} 'date ')"
}

function dockerInstallation() {
  sudo yum remove -y docker \
                     docker-client \
                     docker-client-latest \
                     docker-common \
                     docker-latest \
                     docker-latest-logrotate \
                     docker-logrotate \
                     docker-selinux \
                     docker-engine-selinux \
                     docker-engine
  sudo yum install -y yum-utils \
                      device-mapper-persistent-data \
                      lvm2 \
                      bash-completion*
  sudo yum-config-manager \
       --add-repo \
       https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum-config-manager --disable docker-ce-edge
  sudo yum-config-manager --disable docker-ce-test
  sudo yum makecache

  sudo yum list docker-ce --showduplicates | sort -r | grep 18\.09
  sudo yum install -y \
           docker-ce-18.09.9-3.el7.x86_64 \
           docker-ce-cli-18.09.9-3.el7.x86_64 \
           containerd.io

  sudo systemctl enable --now docker
  sudo systemctl status docker
}

function k8sInstallation() {
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

  modprobe br_netfilter
  sudo bash -c 'cat > /etc/sysctl.d/k8s.conf' << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
  sysctl --system

  sudo bash -c 'cat > /etc/yum.repos.d/kubernetes.repo' << EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

  sudo yum makecache
  sudo yum list kubeadm --showduplicates | sort -r | grep 1\.15\.3
  sudo yum install -y \
           kubeadm-1.15.3-0.x86_64 \
           kubectl-1.15.3-0.x86_64 \
           kubelet-1.15.3-0.x86_64 \
           --disableexcludes=kubernetes

  sudo systemctl enable --now kubelet
  sudo systemctl status kubelet
}

function cfsslInstallation() {
  sudo bash -c "curl -o /usr/local/bin/cfssl ${cfsslDownloadUrl}/cfssl_linux-amd64"
  sudo bash -c "curl -o /usr/local/bin/cfssljson ${cfsslDownloadUrl}/cfssljson_linux-amd64"
  sudo chmod +x /usr/local/bin/cfssl*
}

function etcdInstallation() {
  curl -sSL ${etcdDownloadUrl}/${etcdVer}/etcd-${etcdVer}-linux-amd64.tar.gz \
      | sudo tar -xzv --strip-components=1 -C /usr/local/bin/
}

function certCA() {
  sudo bash -c "cat > ${etcdPath}/ca-config.json" << EOF
{
  "signing": {
    "default": {
      "expiry": "43800h"
    },
    "profiles": {
      "server": {
        "expiry": "43800h",
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ]
      },
      "client": {
        "expiry": "43800h",
        "usages": [
          "signing",
          "key encipherment",
          "client auth"
        ]
      },
      "peer": {
        "expiry": "43800h",
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ]
      }
    }
  }
}
EOF

  sudo bash -c "cat > ${etcdPath}/ca-csr.json" << EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

  pushd .
  cd ${etcdPath}
  sudo /usr/local/bin/cfssl gencert \
       -initca ca-csr.json \
       | sudo /usr/local/bin/cfssljson -bare ca -
  popd
}

function certClient() {
  sudo bash -c "cat > ${etcdPath}/client.json" << EOF
{
  "CN": "client",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF

  pushd .
  cd ${etcdPath}/
  sudo /usr/local/bin/cfssl gencert \
       -ca=ca.pem \
       -ca-key=ca-key.pem \
       -config=ca-config.json \
       -profile=client client.json \
       | sudo /usr/local/bin/cfssljson -bare client
  popd
}

function certServerNPeer() {
  sudo bash -c "/usr/local/bin/cfssl print-defaults csr > ${etcdPath}/config.json"
  sudo sed -i '0,/CN/{s/example\.net/'"${peerName}"'/}' ${etcdPath}/config.json
  sudo sed -i 's/www\.example\.net/'"${ipAddr}"'/' ${etcdPath}/config.json
  sudo sed -i 's/example\.net/'"${peerName}"'/' ${etcdPath}/config.json

  pushd .
  cd ${etcdPath}/
  sudo /usr/local/bin/cfssl gencert \
       -ca=ca.pem \
       -ca-key=ca-key.pem \
       -config=ca-config.json \
       -profile=server config.json \
       | sudo /usr/local/bin/cfssljson -bare server

  sudo /usr/local/bin/cfssl gencert \
       -ca=ca.pem \
       -ca-key=ca-key.pem \
       -config=ca-config.json \
       -profile=peer config.json \
       | sudo /usr/local/bin/cfssljson -bare peer
  popd
}

function syncCert() {
  for pkg in ca-config.json  ca-key.pem  ca.pem  client-key.pem  client.pem; do
    sudo rsync -avzrlpgoDP \
               --rsync-path='sudo rsync' \
               root@${leadHost}:${etcdPath}/${pkg} \
               ${etcdPath}/
  done
}

function etcdService() {

  sudo bash -c 'cat >/etc/systemd/system/etcd.service' <<EOF
[Install]
WantedBy=multi-user.target

[Unit]
Description=Etcd Server
Documentation=https://github.com/Marslo/mytools
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
Restart=always
RestartSec=5s
EnvironmentFile=-/etc/etcd/etcd.conf

ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/local/bin/etcd"
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  sudo bash -c 'cat > /etc/etcd/etcd.conf' <<EOF
ETCD_NAME=${peerName}
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_WAL_DIR=""
#ETCD_SNAPSHOT_COUNT="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${ipAddr}:2380"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://
..."
ETCD_INITIAL_CLUSTER="${etcdInitialCluster}"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://${ipAddr}:2379"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#ETCD_STRICT_RECONFIG_CHECK="false"
#ETCD_AUTO_COMPACTION_RETENTION="0"
#
#[proxy]
#ETCD_PROXY="off"
#ETCD_PROXY_FAILURE_WAIT="5000"
#ETCD_PROXY_REFRESH_INTERVAL="30000"
#ETCD_PROXY_DIAL_TIMEOUT="1000"
#ETCD_PROXY_WRITE_TIMEOUT="5000"
#ETCD_PROXY_READ_TIMEOUT="0"
#
#[security]
ETCD_CERT_FILE="${etcdPath}/server.pem"
ETCD_KEY_FILE="${etcdPath}/server-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="${etcdPath}/ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="${etcdPath}/peer.pem"
ETCD_PEER_KEY_FILE="${etcdPath}/peer-key.pem"
#ETCD_PEER_CLIENT_CERT_AUTH="false"
ETCD_PEER_TRUSTED_CA_FILE="${etcdPath}/ca.pem"
ETCD_PEER_AUTO_TLS="true"
#
#[logging]
#ETCD_DEBUG="false"
# examples for -log-package-levels etcdserver=WARNING,security=DEBUG
#ETCD_LOG_PACKAGE_LEVELS=""
#[profiling]
#ETCD_ENABLE_PPROF="false"
#ETCD_METRICS="basic"
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now etcd
  sudo systemctl start etcd.service
}

function etcdObsoletService() {
  touch /etc/etcd.env
  echo "peerName=${peerName}" >> /etc/etcd.env
  echo "ipAddr=${ipAddr}" >> /etc/etcd.env

  sudo bash -c 'cat > /etc/systemd/system/etcd.service' <<EOF
[Unit]
Description=etcd
Documentation=https://ewiki.marvell.com/x/sTJIBg
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
EnvironmentFile=/etc/etcd.env
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name ${peerName} \\
    --data-dir /var/lib/etcd \\
    --listen-client-urls https://${ipAddr}:2379 \\
    --advertise-client-urls https://${ipAddr}:2379 \\
    --listen-peer-urls https://${ipAddr}:2380 \\
    --initial-advertise-peer-urls https://${ipAddr}:2380 \\
    --cert-file=${etcdPath}/server.pem \\
    --key-file=${etcdPath}/server-key.pem \\
    --client-cert-auth \\
    --trusted-ca-file=${etcdPath}/ca.pem \\
    --peer-cert-file=${etcdPath}/peer.pem \\
    --peer-key-file=${etcdPath}/peer-key.pem \\
    --peer-client-cert-auth \\
    --peer-trusted-ca-file=${etcdPath}/ca.pem \\
    --initial-cluster ${etcdInitialCluster} \\
    --initial-cluster-token my-etcd-token \\
    --initial-cluster-state new

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now etcd
  sudo systemctl start etcd.service
}

keepaliveSetup() {
  mkdir -p ~/temp
  sudo mkdir -p /etc/keepalived/

  curl -fsSL ${keepaliveDownloadUrl}/keepalived-${keepaliveVer}.tar.gz \
       | tar xzf - -C ~/temp
  pushd .
  cd ~/temp/keepalived-${keepaliveVer}
  ./configure && make
  sudo make install
  sudo cp keepalived/keepalived.service /etc/systemd/system/
  popd

  sudo bash -c 'cat > /etc/keepalived/keepalived.conf' <<EOF
! Configuration File for keepalived
global_defs {
  router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}
vrrp_instance VI_1 {
  state MASTER
  interface ${interface}
  virtual_router_id 51
  priority 101
  authentication {
    auth_type PASS
    auth_pass 4be37dc3b4c90194d1600c483e10ad1d
  }
  virtual_ipaddress {
    ${virtualIpAddr}
  }
  track_script {
    check_apiserver
  }
}
EOF

  sudo bash -c 'cat > /etc/keepalived/check_apiserver.sh' <<EOF
#!/bin/sh
errorExit() {
  echo "*** \$*" 1>&2
  exit 1
}
curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q ${virtualIpAddr}; then
    curl --silent --max-time 2 --insecure https://${virtualIpAddr}:6443/ -o /dev/null || errorExit "Error GET https://${virtualIpAddr}:6443/"
fi
EOF

  sudo systemctl enable keepalived.service
  sudo systemctl start keepalived.service
}

function kubeadmConfig() {
  cat > kubeadm-conf.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: ${k8sVer}
controlPlaneEndpoint: "${virtualIpAddr}:6443"
etcd:
  external:
    endpoints:
      - https://${master1Ip}:2379
      - https://${master2Ip}:2379
      - https://${master3Ip}:2379
    caFile: ${etcdPath}/ca.pem
    certFile: ${etcdPath}/client.pem
    keyFile: ${etcdPath}/client-key.pem
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
apiServer:
  certSANs:
    - ${virtualIpAddr}
    - ${master1Ip}
    - ${master1Name}
    - ${master2Ip}
    - ${master2Name}
    - ${master3Ip}
    - ${master3Name}
  extraArgs:
    etcd-cafile: ${etcdPath}/ca.pem
    etcd-certfile: ${etcdPath}/client.pem
    etcd-keyfile: ${etcdPath}/client-key.pem
  timeoutForControlPlane: 4m0s
imageRepository: k8s.gcr.io
clusterName: "dc5tst-cluster"
EOF
}

function initMaster() {
  sudo modprobe br_netfilter
  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
  sudo swapoff -a
  sudo bash -c "sed -e 's:^\\(.*swap.*\\)$:# \\1:' -i /etc/fstab"
  setenforce 0
  sudo bash -c "sed 's/^SELINUX=enforcing$/SELINUX=permissive/' -i /etc/selinux/config"
  sudo kubeadm init --config kubeadm-conf.yaml --ignore-preflight-errors=all
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown "$(id -u)":"$(id -g)" $HOME/.kube/config
}

function syncPKI() {
for pkg in '*.key' '*.crt' '*.pub'; do
  sudo rsync -avzrlpgoDP \
             --rsync-path='sudo rsync' \
             root@${leadIP}:/etc/kubernetes/pki/${pkg} \
             /etc/kubernetes/pki/
done
  sudo rm -rf /etc/kubernetes/pki/apiserver*
  # sudo cp -r /root/etcd* /etc/kubernetes/pki/
}

function cniSetup() {
  kubectl apply -f \
          https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
}

function teardown() {
  sudo kubeadm reset

  docker system prune -a -f
  sudo yum versionlock delete docker-ce
  sudo yum versionlock delete docker-ce-cli
  sudo yum versionlock delete kubeadm
  sudo yum versionlock delete kubelet
  sudo yum versionlock delete kubectl
  sudo yum versionlock delete kubernetes-cni

  sudo systemctrl disable docker.service
  sudo systemctrl disable kubectl.service

  sudo yum remove -y \
           docker-ce \
           docker-ce-cli \
           containerd.io \
           kubectl \
           kubeadm \
           kubelet \
           kubernetes-cni

  rm -rf /home/devops/.kube
  sudo rm -rf /var/log/pods/ \
              /var/log/containers/ \
              /etc/kubernetes/ \
              /var/lib/yum/repos/x86_64/7/kubernetes \
              /usr/libexec/kubernetes \
              /var/cache/yum/x86_64/7/kubernetes \
              /etc/systemd/system/multi-user.target.wants/kubelet.service  \
              /usr/lib/systemd/system/kubelet.service.d \
              /var/lib/kubelet \
              /usr/libexec/kubernetes

  sudo yum clean all
  sudo rm -rf /var/cache/yum
  sudo yum makecache
}

function pkgInstallation() {
  dockerInstallation
  k8sInstallation
  cfsslInstallation
  etcdInstallation
}

function leadMaster() {
  sudo mkdir -p "${etcdPath}"
  pkgInstallation
  certCA
  certClient
  certServerNPeer
  etcdService
  keepaliveSetup
  kubeadmConfig
  initMaster
  cniSetup
}

function followerMaster() {
  sudo mkdir -p "${etcdPath}"
  pkgInstallation
  timeSync
  syncCert
  certServerNPeer
  etcdService
  keepaliveSetup
  kubeadmConfig
  syncPKI
  initMaster
}

if [ "$1" = "help" ]; then
  help
else
  # if no parameters, then run all of default installation and configuration
  if [ $# -eq 0 ]; then
    showInfo
    echo '-----------------------'
    help
  # execute specified the functions
  else
    for func do
      [ "$(type -t -- "$func")" = function ] && "$func"
    done
  fi
fi
