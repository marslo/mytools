#!/bin/bash
# shellcheck disable=SC2224,SC1117,SC2009
# =============================================================================
#   FileName: belloHAKubeCluster.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2019-09-02 22:48:57
# LastChange: 2019-09-02 22:49:22
# =============================================================================

# Inspired by:
  # https://blog.csdn.net/chenleiking/article/details/80136449
  # https://k8smeetup.github.io/docs/setup/independent/high-availability/

# hardcode
master1IP='127.0.0.40'
master2IP='127.0.0.42'
master3IP='127.0.0.43'
master1Host='mytest-tst1'
master2Host='mytest-tst2'
master3Host='mytest-tst3'
virtual_ipaddress='127.0.0.50'
leadIP="${master1IP}"
leadHost="${master1Host}"

rtUrl='artifactory.my.com/artifactory'

# cfssl_url='https://pkg.cfssl.org/R1.2'
cfssl_artifactory_url="https://${rtUrl}/devops-local/k8s/R1.2/"
cfssl_download_url="${cfssl_artifactory_url}"

etcd_version='v3.3.15'
# etcd_google_download='https://storage.googleapis.com/etcd'
# etcd_github_download='https://github.com/etcd-io/etcd/releases/download'
etcd_artifactory_download="https://${rtUrl}/devops-local/k8s"
etcd_download_url="${etcd_artifactory_download}"

keepalive_version='2.0.18'
# keepalive_url='https://www.keepalived.org/software'
keepalive_artifactory_url="https://${rtUrl}/devops-local/k8s/software"
keepalive_download_url="${keepalive_artifactory_url}"

interface=$(ip route get 127.0.0.55 | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p')
ipaddr=$(ip a s ${interface} | sed -rn 's|.*inet ([0-9\.]{11}).*$|\1|p')
peer_name=$(hostname)
etcd_initial_cluster="${master1Host}=https://${master1IP}:2380,${master2Host}=https://${master2IP}:2380,${master3Host}=https://${master3IP}:2380"

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function cfsslInstallation() {
  sudo bash -c "curl -o /usr/local/bin/cfssl ${cfssl_download_url}/cfssl_linux-amd64"
  sudo bash -c "curl -o /usr/local/bin/cfssljson ${cfssl_download_url}/cfssljson_linux-amd64"
  sudo chmod +x /usr/local/bin/cfssl*
}

function etcdInstallation() {
  curl -sSL ${etcd_download_url}/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz \
      | sudo tar -xzv --strip-components=1 -C /usr/local/bin/
}

function certCA() {
  sudo bash -c 'cat > /etc/kubernetes/pki/etcd/ca-config.json' << EOF
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

sudo bash -c 'cat > /etc/kubernetes/pki/etcd/ca-csr.json' << EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

  pushd .
  cd /etc/kubernetes/pki/etcd/
  sudo /usr/local/bin/cfssl gencert \
       -initca ca-csr.json \
       | sudo /usr/local/bin/cfssljson -bare ca -
  popd
}

function certClient() {
  sudo bash -c 'cat > /etc/kubernetes/pki/etcd/client.json' << EOF
{
  "CN": "client",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF
 
  pushd .
  cd /etc/kubernetes/pki/etcd/
  sudo /usr/local/bin/cfssl gencert \
       -ca=ca.pem \
       -ca-key=ca-key.pem \
       -config=ca-config.json \
       -profile=client client.json \
       | sudo /usr/local/bin/cfssljson -bare client
  popd
}

function certServerNPeer() {
  sudo bash -c '/usr/local/bin/cfssl print-defaults csr > /etc/kubernetes/pki/etcd/config.json'
  sudo sed -i '0,/CN/{s/example\.net/'"${peer_name}"'/}' /etc/kubernetes/pki/etcd/config.json
  sudo sed -i 's/www\.example\.net/'"${ipaddr}"'/' /etc/kubernetes/pki/etcd/config.json
  sudo sed -i 's/example\.net/'"${peer_name}"'/' /etc/kubernetes/pki/etcd/config.json

  pushd .
  cd /etc/kubernetes/pki/etcd/
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
               root@${leadHost}:/etc/kubernetes/pki/etcd/${pkg} \
               /etc/kubernetes/pki/etcd/
  done
}

function etcdService() {
  touch /etc/etcd.env
  echo "peer_name=${peer_name}" >> /etc/etcd.env
  echo "ipaddr=${ipaddr}" >> /etc/etcd.env

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
 
ExecStart=/usr/local/bin/etcd --name ${peer_name} \\
    --data-dir /var/lib/etcd \\
    --listen-client-urls https://${ipaddr}:2379 \\
    --advertise-client-urls https://${ipaddr}:2379 \\
    --listen-peer-urls https://${ipaddr}:2380 \\
    --initial-advertise-peer-urls https://${ipaddr}:2380 \\
    --cert-file=/etc/kubernetes/pki/etcd/server.pem \\
    --key-file=/etc/kubernetes/pki/etcd/server-key.pem \\
    --client-cert-auth \\
    --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \\
    --peer-cert-file=/etc/kubernetes/pki/etcd/peer.pem \\
    --peer-key-file=/etc/kubernetes/pki/etcd/peer-key.pem \\
    --peer-client-cert-auth \\
    --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \\
    --initial-cluster ${etcd_initial_cluster} \\
    --initial-cluster-token my-etcd-token \\
    --initial-cluster-state new
 
[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl start etcd.service
}

keepaliveSetup() {
  mkdir -p ~/temp
  sudo mkdir -p /etc/keepalived/

  curl -fsSL ${keepalive_download_url}/keepalived-${keepalive_version}.tar.gz \
       | tar xzf - -C ~/temp
  cd ~/temp/keepalived-${keepalive_version}
  ./configure
  make && sudo make install
  sudo cp keepalived/keepalived.service /etc/systemd/system/

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
    ${virtual_ipaddress}
  }
  track_script {
    check_apiserver
  }
}
EOF

  sudo bash -c 'cat > /etc/keepalived/check_apiserver.sh' <<EOF
#!/bin/sh
errorExit() {
  echo "*** \$\*" 1>&2
  exit 1
}
curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q ${virtual_ipaddress}; then
    curl --silent --max-time 2 --insecure https://${virtual_ipaddress}:6443/ -o /dev/null || errorExit "Error GET https://${virtual_ipaddress}:6443/"
fi
EOF

  sudo systemctl enable keepalived.service
  sudo systemctl start keepalived.service
}

function kubeadmConfig() {
  cat > kubeadm-conf.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.15.3
controlPlaneEndpoint: "${virtual_ipaddress}:6443"
etcd:
  external:
    endpoints:
      - https://${master1IP}:2379
      - https://${master2IP}:2379
      - https://${master3IP}:2379
    caFile: /etc/kubernetes/pki/etcd/ca.pem
    certFile: /etc/kubernetes/pki/etcd/client.pem
    keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
apiServer:
  certSANs:
    - ${virtual_ipaddress}
    - ${master1IP}
    - ${master1Host}
    - ${master2IP}
    - ${master2Host}
    - ${master3IP}
    - ${master3Host}
  extraArgs:
    etcd-cafile: /etc/kubernetes/pki/etcd/ca.pem
    etcd-certfile: /etc/kubernetes/pki/etcd/client.pem
    etcd-keyfile: /etc/kubernetes/pki/etcd/client-key.pem
  timeoutForControlPlane: 4m0s
imageRepository: k8s.gcr.io
clusterName: "dc5tst-cluster"
EOF
}

function initMaster() {
  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  sudo swap off
  sudo kubeadm init --config kubeadm-conf.yaml --ignore-preflight-errors=all
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

function setupLeadCertificates() {
  sudo mkdir -p '/etc/kubernetes/pki/etcd'
  certCA
  certClient
  certServerNPeer
  etcdService
  keepaliveSetup
  kubeadmConfig
  initMaster
  cniSetup
}

function setupFollowerCertificates() {
  sudo mkdir -p '/etc/kubernetes/pki/etcd'
  syncCert
  certServerNPeer
  etcdService
  keepaliveSetup
  kubeadmConfig
  syncPKI
  initMaster
  cniSetup
}
