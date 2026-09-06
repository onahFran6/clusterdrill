# q109-33-storageclass-level-reclaim-policy: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy

```sh
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: compliance-storage
  labels:
    clusterdrill-question: q109-33-storageclass-level-reclaim-policy
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Retain
volumeBindingMode: Immediate
EOF
```
