# q107-42-nodeselector-mismatch-blocks-scheduling: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector

Diagnose first:

```sh
kubectl describe pod report-worker -n q107-42-nodeselector-mismatch-blocks-scheduling
kubectl get nodes --show-labels
```

`nodeSelector` is set at Pod creation time and cannot be patched onto a running/pending Pod -
delete and recreate it without the unsatisfiable selector (this lab's single-node cluster has no
`disktype` label at all, so the fix removes the requirement rather than labeling the node - the
node is shared with every other question and isn't reset between them).

```sh
kubectl delete pod report-worker -n q107-42-nodeselector-mismatch-blocks-scheduling --wait=true

kubectl apply -n q107-42-nodeselector-mismatch-blocks-scheduling -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-worker
  labels:
    app: report-worker
spec:
  containers:
    - name: report-worker
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/report-worker -n q107-42-nodeselector-mismatch-blocks-scheduling --timeout=60s
```
