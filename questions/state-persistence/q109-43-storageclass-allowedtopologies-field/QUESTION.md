# q109-43-storageclass-allowedtopologies-field: Author a StorageClass restricted to one topology zone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-43-storageclass-allowedtopologies-field`

`setup.sh` created namespace `q109-43-storageclass-allowedtopologies-field` but no resources
yet.

Find this cluster's node and its hostname label:

```sh
kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}'
```

Create a StorageClass named `zone-restricted-storage` that:

- uses provisioner `k8s.io/minikube-hostpath` (the same provisioner backing this cluster's
  built-in default StorageClass)
- sets `volumeBindingMode` to `WaitForFirstConsumer` (required for `allowedTopologies` to have
  any effect - see the hint)
- sets `spec.allowedTopologies` to a single topology entry whose `matchLabelExpressions` has
  key `kubernetes.io/hostname`, `values` set to the node hostname you discovered above

## Hint

Search kubernetes.io/docs for **"storageclass allowedTopologies"** - the Storage Classes
concept page's Allowed Topologies section explains that this field restricts which node
topologies a class's volumes may be provisioned in, and that it is only honored when
`volumeBindingMode` is `WaitForFirstConsumer` (with `Immediate` binding, provisioning happens
before a topology is even known).
