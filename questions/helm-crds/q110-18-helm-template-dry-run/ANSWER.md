# q110-18: reference solution

Doc: https://helm.sh/docs/helm/helm_template/

```sh
CONTAINER_NAME=$(helm template preview questions/helm-crds/q110-18-helm-template-dry-run/chart \
  | grep -A1 'containers:' | grep 'name:' | head -1 | awk '{print $3}')
kubectl create configmap rendered-info -n q110-18-helm-template-dry-run \
  --from-literal=containerName="$CONTAINER_NAME"
```
