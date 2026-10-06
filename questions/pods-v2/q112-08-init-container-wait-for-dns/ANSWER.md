# q112-08: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
NS=q112-08-init-container-wait-for-dns

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: api
  labels:
    clusterdrill-question: $NS
spec:
  initContainers:
    - name: wait-db
      image: busybox:1.36
      command: ["sh", "-c", "until nslookup db.$NS.svc.cluster.local; do echo waiting for db; sleep 2; done; echo db found"]
  containers:
    - name: api
      image: nginx:1.27
EOF

kubectl get pod api -n "$NS" --no-headers | awk '{print $3}'   # Init:0/1

kubectl create service clusterip db --tcp=5432:5432 -n "$NS"
kubectl label service db "clusterdrill-question=$NS" -n "$NS"

kubectl wait --for=condition=Ready pod/api -n "$NS" --timeout=60s
kubectl logs api -c wait-db -n "$NS" | tail -1          # db found
```

A ClusterIP Service gets its DNS record the moment it is created, whether or not it has any
endpoints - that is why `db found` appears as soon as the Service exists, with zero backing pods.
Init containers run in order and each must exit 0 before the next one (or the app containers)
starts, which is why `api`'s own container never starts while `wait-db` is still looping.
