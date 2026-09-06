# q104-42-blue-green-secret-config-cutover: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
kubectl patch deployment billing-green -n q104-42-blue-green-secret-config-cutover --type=json -p '
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/envFrom/0/secretRef/name",
    "value": "app-config-green"
  }
]
'

kubectl rollout status deployment/billing-green -n q104-42-blue-green-secret-config-cutover --timeout=60s

kubectl patch service billing-svc -n q104-42-blue-green-secret-config-cutover --type=merge -p '
{
  "spec": {
    "selector": {
      "app": "billing",
      "version": "green"
    }
  }
}
'
```
