# q110-15: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#specifying-a-short-name

```sh
kubectl get cpn -n q110-15-crd-list-shortname
# spring-sale, flash-10, vip-20 -> 3 Coupon objects visible via short name

kubectl create configmap coupon-count -n q110-15-crd-list-shortname \
  --from-literal=total=3
```
