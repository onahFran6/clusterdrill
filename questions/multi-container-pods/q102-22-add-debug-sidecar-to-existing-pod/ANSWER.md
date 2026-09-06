# q102-22: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl patch deployment billing-api -n q102-22-add-debug-sidecar-to-existing-pod --patch '
spec:
  template:
    spec:
      containers:
        - name: net-debug
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
'

kubectl rollout status deployment/billing-api -n q102-22-add-debug-sidecar-to-existing-pod --timeout=60s
```
