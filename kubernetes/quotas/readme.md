### ns.yaml
#### apply
```bash
$ kubectl apply -f ns.yml -n <namespace>
```

#### copy from the other namespace
```bash
$ kubectl get quota <quota-name> -n <ns-copy-from> -o yaml --export | kubectl -n <ns-paste-to> -f -
```
