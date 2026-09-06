# q104-19: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_autoscale/

```sh
kubectl autoscale deployment checkout-api \
  --min=4 --max=12 --cpu-percent=75 \
  -n q104-19-autoscale-deployment-cpu
```
