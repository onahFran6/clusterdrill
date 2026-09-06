# q108-46-ingress-missing-ingressclassname-fix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class

```sh
kubectl patch ingress reports-ingress -n q108-46-ingress-missing-ingressclassname-fix \
  --type merge -p '{"spec":{"ingressClassName":"nginx"}}'
```
