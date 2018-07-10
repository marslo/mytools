## Usage

### admin-dashboard.yaml
```
$ kubectl apply -f admin-dashboard.yaml
```

Skip and anonymous will be admin by default

Inspired by the [CloudMan](https://www.cnblogs.com/CloudMan6/p/9097274.html)

### admin-user.yaml
```
$ kubectl apply -f admin-user.yaml
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
