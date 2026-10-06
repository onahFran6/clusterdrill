# q112-06: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

```sh
NS=q112-06-persistent-data-survives-pod-deletion

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q112-06-static-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual-q112-06
  hostPath:
    path: /mnt/q112-06-data
    type: DirectoryOrCreate
EOF

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: triton-pvc
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual-q112-06
  resources:
    requests:
      storage: 500Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: triton-pvc
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "echo saved-by-writer > /data/proof.txt; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/writer -n "$NS" --timeout=60s
kubectl delete pod writer -n "$NS" --force --grace-period=0

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: reader
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: triton-pvc
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "cat /data/proof.txt; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/reader -n "$NS" --timeout=60s
```

A claim binds to a whole PV, so once bound it reports the PV's actual size (`1Gi`), not the
request (`500Mi`). On a multi-node cluster, `hostPath` only exists on whichever node `writer`
happened to land on, so `reader` would need `spec.nodeName` pinned to that same node to see the
file - this single-node cluster doesn't need that, but it is the real-world gotcha a static
`hostPath` PV always carries. With the PV's `Retain` reclaim policy, deleting the PVC later leaves
the PV `Released` rather than immediately reusable.
