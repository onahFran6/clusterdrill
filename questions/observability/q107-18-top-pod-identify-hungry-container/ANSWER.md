# q107-18: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

```sh
kubectl top pod -n q107-18-top-pod-identify-hungry-container

kubectl label pod burner role=cpu-hog -n q107-18-top-pod-identify-hungry-container
```
