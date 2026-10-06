# q114-06: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#local

```sh
NS=q114-06-storageclass-for-local-disks
NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: q114-06-local-disk
  labels:
    clusterdrill-question: $NS
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q114-06-local-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: q114-06-local-disk
  local:
    path: /mnt/q114-06-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values: ["$NODE_NAME"]
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: thames-claim
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: q114-06-local-disk
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
EOF

kubectl get pvc thames-claim -n "$NS" -o jsonpath='{.status.phase}'; echo   # Pending

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: thames-app
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: thames-claim
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/thames-app -n "$NS" --timeout=60s
kubectl get pvc thames-claim -n "$NS" -o jsonpath='{.status.phase}'; echo   # Bound
```

With `WaitForFirstConsumer`, a `Pending` claim is the healthy state until a Pod needs it - the
scheduler then picks a node that satisfies both the Pod and the PV's `nodeAffinity`. Unlike a
`hostPath` volume, a `local` volume genuinely pins its Pod to that one node.
