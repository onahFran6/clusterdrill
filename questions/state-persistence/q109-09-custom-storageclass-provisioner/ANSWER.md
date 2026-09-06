# q109-09: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/

```sh
NS=q109-09-custom-storageclass-provisioner

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ephemeral
  labels:
    clusterdrill-question: $NS
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
```
