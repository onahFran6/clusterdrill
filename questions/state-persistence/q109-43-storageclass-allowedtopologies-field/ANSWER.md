# q109-43-storageclass-allowedtopologies-field: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#allowed-topologies

```sh
NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}')"

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: zone-restricted-storage
  labels:
    clusterdrill-question: q109-43-storageclass-allowedtopologies-field
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
  - matchLabelExpressions:
      - key: kubernetes.io/hostname
        values:
          - $NODE_NAME
EOF
```
