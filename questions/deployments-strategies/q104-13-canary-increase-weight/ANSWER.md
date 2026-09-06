# q104-13: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/

```sh
kubectl scale deployment/payments-canary --replicas=5 -n q104-13-canary-increase-weight
kubectl scale deployment/payments-stable --replicas=5 -n q104-13-canary-increase-weight

kubectl rollout status deployment/payments-canary -n q104-13-canary-increase-weight --timeout=60s
kubectl rollout status deployment/payments-stable -n q104-13-canary-increase-weight --timeout=60s
```
