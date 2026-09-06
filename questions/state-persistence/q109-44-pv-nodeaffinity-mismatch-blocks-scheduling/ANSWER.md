# q109-44-pv-nodeaffinity-mismatch-blocks-scheduling: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#local

`nodeAffinity` cannot be patched on an existing PersistentVolume - delete and recreate it. The
already-`Pending` PVC and Pod need no changes: the scheduler retries automatically once a
viable PV exists.

```sh
NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}')"

kubectl delete pv metrics-local-pv --wait=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: metrics-local-pv
  labels:
    clusterdrill-question: q109-44-pv-nodeaffinity-mismatch-blocks-scheduling
spec:
  capacity:
    storage: 100Mi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage-q109-44
  local:
    path: /mnt/q109-44-metrics
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - $NODE_NAME
EOF

kubectl wait --for=condition=Ready pod/metrics-collector \
  -n q109-44-pv-nodeaffinity-mismatch-blocks-scheduling --timeout=60s
```
