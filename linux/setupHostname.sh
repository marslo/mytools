#!/bin/bash
# =============================================================================
#   FileName: setHostname.sh
#      Email: marslo.jiao@gmail.com
#    Created: 2019-03-14 19:29:24
# LastChange: 2019-03-14 19:29:47
# =============================================================================

MYHOSTNAME="wptester-l01"

sudo hostname "${MYHOSTNAME}"
sudo bash -c "echo \"${MYHOSTNAME}\" > /etc/hostname"
sudo sed -i -e "s:^\\(127\\.0\\.1\\.1\\).*$:\\1\\t${MYHOSTNAME}:" /etc/hosts
if sed -E "^127\.0\.0\.1.*${MYHOSTNAME}.*$" /etc/hosts; then
  sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
fi
sudo hostnamectl set-hostname "${MYHOSTNAME}"
sudo systemctl restart systemd-resolved.service
sudo systemd-resolve --flush-caches
sudo systemd-resolve --statistics
hostname -f
sysctl kernel.hostname
hostnamectl status

if grep -E "^127\.0\.0\.1.*${MYHOSTNAME}*$" /etc/hosts; then
  sudo sed -i  -r -e "s:^(127.0.0.1.*$):\1 $(hostname):" /etc/hosts
fi
