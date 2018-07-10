<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Usage](#usage)
    - [admin-dashboard.yaml](#admin-dashboardyaml)
    - [admin-user.yaml](#admin-useryaml)
        - [Get Token:](#get-token)
        - [Start dashboard](#start-dashboard)
- [Expose the dashboard to service](#expose-the-dashboard-to-service)
    - [Original](#original)
    - [Change `type: ClusterIP` to `type: NodePort`](#change-type-clusterip-to-type-nodeport)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Usage

### admin-dashboard.yaml
```
$ kubectl apply -f admin-dashboard.yaml
```

Skip and anonymous will be admin by default

Inspired by the [CloudMan](https://www.cnblogs.com/CloudMan6/p/9097274.html)

### [admin-user.yaml](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)
```
$ kubectl apply -f admin-user.yaml
```

#### [Get Token](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user#bearer-token)
```
$ admName=$(kubectl -n kube-system get secret | grep admin | awk -F' ' '{print $1}')
$ echo $admName
admin-user-token-fdg6x

$ kubectl get secret $(kubectl -n kube-system get secret | grep admin | awk -F' ' '{print $1}') -n=kube-system
...
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLWZkZzZ4Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJhOWMxY2I1ZC01YTZiLTExZTgtOTU2Ni1iNGI1MmZjZGI3NGYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.RSDeP3k8BeTlywmyPwO3lfG5TWArpiRR8TzKtm-aa4zjUh9HhuhkKLvY9skDP6HbG4IMiQxDJH5vz9xVjf_R7lDASrljha2ungp2iWBEKey3oTjXIX2_Mv59W9RJ0D-BVifDjWZeMV4kYzrEhLsPmnosn13beGwyWZvDR2b9Oyhp2Z5tNiQcpNIywxgzwNnGBB3tlvz_xtoZMTRSkzbcgiTDT02yhhIVSWCFNXwQA01vYT7nbPyRT_b9_gBxZZKSw6mK7s6QxHlefsslfRB65pli3-PJTopV2wIeVjvs-50OZ6H2FOUSdnPZgYkjUyXZs1XKpoiN0j2LBtV1DJANCQ
```

#### Start dashboard
```
$ kubectl proxy --address="0.0.0.0" -p 8001 --accept-hosts='^*$'  --accept-paths='^.*'
Starting to serve on [::]:8001
```

Credit belongs to [kubernetes/dashboard Accessing Dashboard 1.7.x and above](https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above)


## [Expose the dashboard to service](https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above#nodeport)

### Original
```
$ alias kc="kubectl --namespace=kube-system"
$ kc get service
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
kube-dns               ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP   22h
kubernetes-dashboard   ClusterIP   10.104.201.101   <none>        443/TCP         22h
```

### Change `type: ClusterIP` to `type: NodePort`
```
$ kubectl -n kube-system edit service kubernetes-dashboard
...
28: type: NodePort
...

$ kc get services
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
kube-dns               ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP   23h
kubernetes-dashboard   NodePort    10.104.201.101   <none>        443:31351/TCP   22h

$ nc -zv localhost 31351
Connection to localhost 31351 port [tcp/*] succeeded!

$ sudo netstat -anpl | grep 31351
tcp6       0      0 :::31351                :::*                    LISTEN      9240/kube-proxy
```
![dashboard-type-nodeport](../others/images/dashboard-2.png)

<details><summary>Click to check original yaml</summary>
<pre><code># Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard","namespace":"kube-system"},"spec":{"ports":[{"port":443,"targetPort":8443}],"selector":{"k8s-app":"kubernetes-dashboard"}}}
  creationTimestamp: 2018-07-09T09:36:38Z
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
  resourceVersion: "1664"
  selfLink: /api/v1/namespaces/kube-system/services/kubernetes-dashboard
  uid: 944af636-835b-11e8-9039-30e1719519bc
spec:
  clusterIP: 10.104.201.101
  ports:
  - port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
</code></pre>
</details>

![dashboard-as-services](../others/images/dashboard-3.png)

### Alternative Login
Login by using **Endpoints**:
```
$ kc describe services kubernetes-dashboard
Name:                     kubernetes-dashboard
Namespace:                kube-system
Labels:                   k8s-app=kubernetes-dashboard
Annotations:              kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard","namespace":...
Selector:                 k8s-app=kubernetes-dashboard
Type:                     NodePort
IP:                       10.104.201.101
Port:                     <unset>  443/TCP
TargetPort:               8443/TCP
NodePort:                 <unset>  31351/TCP
Endpoints:                10.244.0.3:8443
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

$ nc -zv 10.244.0.3 8443
Connection to 10.244.0.3 8443 port [tcp/*] succeeded!
```

![dashboard-with-endpoints](../others/images/dashboard-4.png)
