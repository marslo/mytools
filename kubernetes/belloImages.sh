#!/bin/bash

privateReg='my.private.com'
officialReg='k8s.gcr.io'
k8sVer='v1.15.3'

kubeadm config images pull --config image.yaml

for pkg in "kube-proxy:${k8sVer}" \
           "kube-apiserver:${k8sVer}" \
           "kube-scheduler:${k8sVer}" \
           "kube-controller-manager:${k8sVer}" \
           "coredns:1.3.1" \
           "pause:3.1"; do
  docker tag ${privateReg}/${pkg} ${officialReg}/${pkg}
  docker rmi ${privateReg}/${pkg}
done
