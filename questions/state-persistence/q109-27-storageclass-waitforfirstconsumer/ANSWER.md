# q109-27: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode

```sh
NS=q109-27-storageclass-waitforfirstconsumer

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: delayed-binding
  labels:
    clusterdrill-question: $NS
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: delayed-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: delayed-binding
  resources:
    requests:
      storage: 100Mi
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: consumer
spec:
  containers:
    - name: consumer
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: delayed-claim
EOF

kubectl wait --for=condition=Ready pod/consumer -n "$NS" --timeout=60s
```
