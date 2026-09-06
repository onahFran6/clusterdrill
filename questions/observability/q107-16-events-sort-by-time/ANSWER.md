# q107-16-events-sort-by-time: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-cluster/monitor-node-health/

```sh
kubectl get events -n q107-16-events-sort-by-time --sort-by=.lastTimestamp
kubectl describe pod big-mem -n q107-16-events-sort-by-time

kubectl delete pod big-mem -n q107-16-events-sort-by-time --ignore-not-found

kubectl apply -n q107-16-events-sort-by-time -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: big-mem
  labels:
    app: big-mem
    clusterdrill-question: q107-16-events-sort-by-time
spec:
  containers:
    - name: big-mem
      image: nginx:1.25-alpine
      resources:
        requests:
          memory: "64Mi"
        limits:
          memory: "64Mi"
EOF

kubectl wait --for=condition=Ready pod/big-mem -n q107-16-events-sort-by-time --timeout=60s
```
