### Get rbac

    $ curl -O ${curlproxy} https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/rbac.yaml
    $ curl -fsSL https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/with-rbac.yaml \
        | sed -re '/^.*replicas.*$/d' \
        | sed -re 's#(^kind:).*$#\1 DaemonSet#g' \
        | sed -re '/^.*serviceAccountName.*/a\      hostNetwork: true\n      nodeSelector:\n        edgenode: "true"' \
        | sed -re '/^.*- --configmap=.*/i\            - --default-backend-service=$(POD_NAMESPACE)/default-backend' \
        > with-rbac.yaml
