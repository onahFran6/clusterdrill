# q104-31-fix-canary-selector-leak-wrong-traffic-split: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors

```sh
kubectl delete deployment recs-debug-leftover \
  -n q104-31-fix-canary-selector-leak-wrong-traffic-split --wait=true
```
