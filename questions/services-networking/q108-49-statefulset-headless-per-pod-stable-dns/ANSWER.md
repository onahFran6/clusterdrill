# q108-49-statefulset-headless-per-pod-stable-dns: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#stable-network-id

`serviceName` is immutable on an existing StatefulSet, and each pod's `spec.subdomain` (which the
StatefulSet controller sets from `serviceName` at pod-creation time) does not retroactively update
either - so simply patching the field is not enough; the StatefulSet (and its pods) must be
deleted and recreated.

```sh
# --cascade=foreground makes --wait actually block until the old pods (not
# just the StatefulSet object) are gone - the default background cascade
# returns as soon as the StatefulSet itself is deleted, which can race the
# very next `apply` into a 409 (a pod of the same name still terminating).
kubectl delete statefulset db-cluster -n q108-49-statefulset-headless-per-pod-stable-dns \
  --cascade=foreground --wait=true

kubectl apply -n q108-49-statefulset-headless-per-pod-stable-dns -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db-cluster
spec:
  serviceName: db-cluster
  replicas: 2
  selector:
    matchLabels:
      app: db-cluster
  template:
    metadata:
      labels:
        app: db-cluster
    spec:
      containers:
        - name: db-cluster
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
          ports:
            - containerPort: 5432
EOF

kubectl wait --for=condition=Ready pod/db-cluster-0 -n q108-49-statefulset-headless-per-pod-stable-dns --timeout=90s
kubectl wait --for=condition=Ready pod/db-cluster-1 -n q108-49-statefulset-headless-per-pod-stable-dns --timeout=90s

# CoreDNS may take a few seconds to pick up the freshly-recreated pod's
# record, so retry rather than trusting the first lookup.
RESOLVED_IP=""
for _ in $(seq 1 15); do
  RESOLVED_IP=$(kubectl exec db-cluster-1 -n q108-49-statefulset-headless-per-pod-stable-dns -- \
    sh -c "nslookup db-cluster-0.db-cluster.q108-49-statefulset-headless-per-pod-stable-dns.svc.cluster.local 2>/dev/null" \
    | awk '/^Name:/{found=1} found && /^Address/{print $2}' | tail -1)
  [ -n "$RESOLVED_IP" ] && break
  sleep 2
done

kubectl create configmap dns-check-result \
  -n q108-49-statefulset-headless-per-pod-stable-dns \
  --from-literal=resolved-ip="$RESOLVED_IP"
```
