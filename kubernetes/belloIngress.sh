#!/bin/bash
# shellcheck disable=SC2224,SC1117,SC2009,SC1078,SC1079,SC2016
# =============================================================================
#   FileName: belloIngressNginx.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2019-09-02 22:48:57
# LastChange: 2019-09-18 18:39:59
# =============================================================================

# Inspired by:
  # https://blog.csdn.net/chenleiking/article/details/80136449
  # ingress-nginx: https://github.com/kubernetes/ingress-nginx

# curlproxy='-x http://127.0.0.1:1087'
curlproxy=''
nodename='my-master-1'

usage="""USAGE:
\n\t$0 [help] [function name]

\n\nNOTICE:
\n\tNA
\n
\nExample:
\n\tNA
\n
\n\nINDEPENDENT FUNCTION NAME:
"""

function help() # show list of functions
{
  echo -e ${usage}
  # ${GREP} '^function' $0 | sed -re "s:^function([^(.]*).*$:\t\1:g"
  declare -F -p | sed -re "s:^.*-f(.*)$:\t\1:g"
}

function nsconf() {
  cat > ns.yaml <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    name: ingress-nginx
EOF
}

function configmap() {
  cat > udp-services-configmap.yaml <<EOF
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
EOF

  cat > tcp-services-configmap.yaml <<EOF
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
EOF

}

function defaultbackend() {
  cat > default-backend.yaml <<EOF
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-backend
  labels:
    app: default-backend
  namespace: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: default-backend
  template:
    metadata:
      labels:
        app: default-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-backend
        # Any image is permissible as long as:
        # 1. It serves a 404 page at /
        # 2. It serves 200 on a /healthz endpoint
        image: k8s.gcr.io/defaultbackend:1.4
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
---

apiVersion: v1
kind: Service
metadata:
  name: default-backend
  namespace: ingress-nginx
  labels:
    app: default-backend
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: default-backend
EOF

}

function rbac() {
  curl -O ${curlproxy} https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/rbac.yaml
  curl -fsSL curl -fsSL https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/with-rbac.yaml \
    | sed -re '/^.*replicas.*$/d' \
    | sed -re 's#(^kind:).*$#\1 DaemonSet#g' \
    | sed -re '/^.*serviceAccountName.*/a\      hostNetwork: true\n      nodeSelector:\n        edgenode: "true"' \
    | sed -re '/^.*- --configmap=.*/i\            - --default-backend-service=$(POD_NAMESPACE)/default-backend' \
    > with-rbac.yaml
}

function initIngressNginx() {
  nsconf
  configmap
  defaultbackend
  rbac

  kubectl label node ${nodename} edgenode=true
  kubectl get no --show-labels

  kubectl apply -f ns.yaml
  kubectl apply -f rbac.yaml
  kubectl apply -f tcp-services-configmap.yaml
  kubectl apply -f udp-services-configmap.yaml
  kubectl apply -f default-backend.yaml
  kubectl apply -f with-rbac.yaml
}

if [ "$1" = "help" ]; then
  help
else
  if [ $# -eq 0 ]; then
    help
  else
    for func do
      [ "$(type -t -- "$func")" = function ] && "$func"
    done
  fi
fi

