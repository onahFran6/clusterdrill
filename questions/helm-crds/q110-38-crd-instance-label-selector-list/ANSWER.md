# q110-38-crd-instance-label-selector-list: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/

```sh
mkdir -p ~/practice-work/q110-38-crd-instance-label-selector-list

kubectl get fleetnodes -n q110-38-crd-instance-label-selector-list -l tier=edge \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
  | sort \
  > ~/practice-work/q110-38-crd-instance-label-selector-list/edge-nodes.txt
```
