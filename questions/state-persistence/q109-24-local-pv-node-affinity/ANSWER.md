# q109-24: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#local

```sh
NS=q109-24-local-pv-node-affinity

# Discover the node name, as the candidate is expected to do.
NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  labels:
    clusterdrill-question: $NS
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-data-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 100Mi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /mnt/ckad-local-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - $NODE_NAME
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-data-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 100Mi
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: local-consumer
spec:
  containers:
    - name: local-consumer
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: local-data-claim
EOF

kubectl wait --for=condition=Ready pod/local-consumer -n "$NS" --timeout=60s
```
