# q105-31-downward-api-resource-fields-mismatch: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/#the-downward-api

```sh
kubectl delete pod sidecar-metrics -n q105-31-downward-api-resource-fields-mismatch

kubectl apply -n q105-31-downward-api-resource-fields-mismatch -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-metrics
  labels:
    app: sidecar-metrics
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "echo main starting; sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 200Mi
    - name: metrics
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          echo "\${CONTAINER_MEM_LIMIT}" > /tmp/limit
          echo "metrics starting, wrote \${CONTAINER_MEM_LIMIT} to /tmp/limit"
          sleep 3600
      env:
        - name: CONTAINER_MEM_LIMIT
          valueFrom:
            resourceFieldRef:
              containerName: metrics
              resource: limits.memory
              divisor: 1Mi
        - name: METRICS_MEM_LIMIT
          valueFrom:
            resourceFieldRef:
              containerName: metrics
              resource: limits.memory
              divisor: 1Mi
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      readinessProbe:
        exec:
          command:
            - sh
            - -c
            - test "\$(cat /tmp/limit 2>/dev/null)" = "\$METRICS_MEM_LIMIT"
        initialDelaySeconds: 2
        periodSeconds: 3
        failureThreshold: 3
EOF

kubectl wait --for=condition=Ready pod/sidecar-metrics -n q105-31-downward-api-resource-fields-mismatch --timeout=60s
```
