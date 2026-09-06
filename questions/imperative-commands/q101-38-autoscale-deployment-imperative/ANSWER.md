# q101-38-autoscale-deployment-imperative: reference solution

Doc: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

```sh
kubectl autoscale deployment api-server \
  -n q101-38-autoscale-deployment-imperative \
  --min=2 --max=5 --cpu-percent=60
```
