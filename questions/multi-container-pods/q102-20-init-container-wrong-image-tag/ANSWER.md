# q102-20: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl patch pod report-gen -n q102-20-init-container-wrong-image-tag --type strategic -p '
{
  "spec": {
    "initContainers": [
      {
        "name": "fetch-config",
        "image": "busybox:1.36"
      }
    ]
  }
}'

kubectl wait --for=condition=Ready pod/report-gen -n q102-20-init-container-wrong-image-tag --timeout=120s
```
