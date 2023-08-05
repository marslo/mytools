#!/bin/bash
# shellcheck disable=SC1078,SC1079,SC2164
# =============================================================================
#   FileName: renewHAKubeCluster.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2020-09-22 10.23.48
# LastChange: 2020-09-26 01:29:30
#  more info: https://marslo.github.io/ibook/kubernetes/certificates.html
# =============================================================================

# potentail issue:
# - https://github.com/kubernetes/kubernetes/issues/77850

timestampe=$(date +"%Y%m%d%H%M%S")
major='1.2.3.4'
pki='/etc/kubernetes/pki'
etcd='/etc/etcd/ssl'
kubeadmConfig="$HOME/.marslo/kubeadm-conf.yaml"
backup="$HOME/k8s-cert-expired.${timestampe}"
prefix="orig.${timestampe}"


usage="""USAGE:
\n\t$0 [help] [independent function name]
\n\nINDEPENDENT FUNCTION NAME:
"""

function help() # show list of functions
{
  echo -e "${usage}"
  # ${GREP} '^function' $0 | sed -re "s:^function([^(.]*).*$:\t\1:g"
  declare -F -p | sed -re "s:^.*-f(.*)$:\t\1:g"
}

function showInfo() {
  echo '~~> check info'
  if [ -d "${pki}" ]; then
    echo "    ~~> check cert for ${pki}:"
    find "${pki}" -type f -name "*.crt" -print \
           | grep -Ev 'ca.crt$' \
           | xargs -L 1 -t -i bash -c 'openssl x509 -noout -text -in {} | grep After'
  else
    echo "WARN: ${pki} folder cannot be found"
  fi

  if [ -d "${etcd}" ]; then
    echo "    ~~> check pem in ${etcd}:"
    find "${etcd}" -type f -name '*.pem' \
           | grep -Ev '-key.pem$' \
           | xargs -L 1 -t  -i bash -c 'openssl x509 -enddate -noout -in {}'
  else
    echo "WARN: ${etcd} folder cannot be found"
  fi
}

function backup() {
  mkdir "${backup}"
  sudo cp --parents -r /etc/kubernetes/pki "${backup}"
  sudo cp --parents -r /etc/kubernetes/*.conf "${backup}"
  sudo cp --parents -r /var/lib/kubelet/pki "${backup}"
  sudo cp /var/lib/kubelet/config.yaml{,."${prefix}"}
}

function clean() {
  echo '~~~> clean expired certs:'
  for i in apiserver apiserver-kubelet-client front-proxy-client; do
    sudo mv ${pki}/${i}.key{,."${prefix}"}
    sudo cp ${pki}/${i}.crt{,."${prefix}"}
  done
  for i in admin kubelet controller-manager scheduler; do
    sudo mv /etc/kubernetes/${i}.conf{,."${prefix}"};
  done
}

function renewCert() {
  echo '~~~> renew cert in Major Kubernetes:'
  for i in apiserver apiserver-kubelet-client front-proxy-client; do
    sudo kubeadm --config "${kubeadmConfig}" alpha certs renew ${i}
  done
}

function syncCert() {
  echo '~~~> sync cert from major master:'
  for pkg in '*.key' '*.crt' '*.pub'; do
    sudo rsync -avzrlpgoDP \
               --rsync-path='sudo rsync' \
               root@${major}:"${pki}/${pkg}" \
               "${pki}/"
    done
}

function renewKubeConfig() {
  echo '~~~> renew kubeconfig:'
  sudo kubeadm --config "${kubeadmConfig}" init phase kubeconfig all

  sudo cp /etc/kubernetes/admin.conf ~/.kube/config
  sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
  sudo chmod 644 "$HOME/.kube/config"
}

function rebootKubelet() {
  echo '~~> reboot kubelet'
  [ -z $(/usr/sbin/pidof kube-apiserver)          ] || sudo kill -s SIGHUP $(/usr/sbin/pidof kube-apiserver)
  [ -z $(/usr/sbin/pidof kube-controller-manager) ] || sudo kill -s SIGHUP $(/usr/sbin/pidof kube-controller-manager)
  [ -z $(/usr/sbin/pidof kube-scheduler)          ] || sudo kill -s SIGHUP $(/usr/sbin/pidof kube-scheduler)

  sudo rm -rf /var/lib/kubelet/pki/*
  sudo systemctl restart kubelet
}

function renewMajor(){
  backup
  showInfo
  clean
  renewCert
  renewKubeConfig
  rebootKubelet
}

function renewPeers() {
  backup
  showInfo
  clean
  syncCert
  renewKubeConfig
  rebootKubelet
}

if [ "$1" = "help" ]; then
  help
else
  # if no parameters, only show information
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
