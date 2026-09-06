# q102-43: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/#the-downward-api

```sh
kubectl delete pod sized-worker -n q102-43-resourcefieldref-memory-divisor --ignore-not-found --wait=true

kubectl apply -n q102-43-resourcefieldref-memory-divisor -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sized-worker
  labels:
    clusterdrill-question: q102-43-resourcefieldref-memory-divisor
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; echo \"\$MEM_LIMIT_MB\" > /data/mem_limit_mb.txt; while true; do sleep 3600; done"]
      env:
        - name: MEM_LIMIT_MB
          valueFrom:
            resourceFieldRef:
              resource: limits.memory
              divisor: 1Mi
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
    - name: validator
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
