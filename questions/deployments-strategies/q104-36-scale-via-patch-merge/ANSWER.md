# q104-36-scale-via-patch-merge: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#patch

```sh
kubectl patch deployment session-store -n q104-36-scale-via-patch-merge --type=merge -p '
{
  "spec": {
    "replicas": 6
  }
}
'

kubectl rollout status deployment/session-store -n q104-36-scale-via-patch-merge --timeout=60s
```
