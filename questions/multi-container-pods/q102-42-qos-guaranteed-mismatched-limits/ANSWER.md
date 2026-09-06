# q102-42: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/

```sh
kubectl delete pod guaranteed-app -n q102-42-qos-guaranteed-mismatched-limits --ignore-not-found --wait=true

kubectl apply -n q102-42-qos-guaranteed-mismatched-limits -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-app
  labels:
    clusterdrill-question: q102-42-qos-guaranteed-mismatched-limits
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 64Mi
    - name: cache
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 64Mi
EOF
```
