# q109-28-readwriteoncepod-exclusive-mount: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

```sh
NS=q109-28-readwriteoncepod-exclusive-mount

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: exclusive-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteOncePod
  storageClassName: ""
  hostPath:
    path: /tmp/ckad-exclusive-pv
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: exclusive-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOncePod
  storageClassName: ""
  resources:
    requests:
      storage: 50Mi
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: owner-pod
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: owner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: exclusive-storage
          mountPath: /data
  volumes:
    - name: exclusive-storage
      persistentVolumeClaim:
        claimName: exclusive-claim
EOF

kubectl wait --for=condition=Bound pvc/exclusive-claim -n "$NS" --timeout=60s
kubectl wait --for=condition=Ready pod/owner-pod -n "$NS" --timeout=60s
```
