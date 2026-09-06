# q107-40-cpu-throttling-diagnosis-via-top: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#if-you-do-not-specify-a-cpu-limit

Confirm the throttling first:

```sh
kubectl top pod number-cruncher -n q107-40-cpu-throttling-diagnosis-via-top
```

Usage sits pegged at (or just under) the 10m limit no matter how much CPU the loop wants - that
flat ceiling is the signature of throttling, not the workload being naturally light. CPU limits
are set at container creation time and cannot be patched onto a running Pod - delete and recreate
it with a realistic limit.

```sh
kubectl delete pod number-cruncher -n q107-40-cpu-throttling-diagnosis-via-top --wait=true

kubectl apply -n q107-40-cpu-throttling-diagnosis-via-top -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: number-cruncher
  labels:
    app: number-cruncher
spec:
  containers:
    - name: number-cruncher
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while true; do i=\$((i+1)); done"]
      resources:
        requests:
          cpu: 100m
          memory: 16Mi
        limits:
          cpu: 200m
          memory: 32Mi
EOF

kubectl wait --for=condition=Ready pod/number-cruncher -n q107-40-cpu-throttling-diagnosis-via-top --timeout=60s
```
