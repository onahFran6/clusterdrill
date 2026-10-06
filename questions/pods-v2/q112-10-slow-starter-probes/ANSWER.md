# q112-10: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
NS=q112-10-slow-starter-probes

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: slowboot
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 20; touch /tmp/started /tmp/healthy /tmp/ready; sleep 3600"]
      startupProbe:
        exec:
          command: ["cat", "/tmp/started"]
        periodSeconds: 2
        failureThreshold: 30
      livenessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        periodSeconds: 5
      readinessProbe:
        exec:
          command: ["cat", "/tmp/ready"]
        periodSeconds: 3
EOF

kubectl wait --for=condition=Ready pod/slowboot -n "$NS" --timeout=60s
kubectl exec slowboot -n "$NS" -- rm /tmp/ready
```

Liveness and readiness probes never run until the startup probe succeeds - without it, the
default liveness settings (3 failures, 10s apart) would kill this container around the 30s mark,
every single time, before it ever finished its 20s boot. A failing readiness probe only pulls the
Pod out of any Service's endpoints; it never restarts the container, which is exactly why
`restartCount` stays at `0` even after `/tmp/ready` is gone and `READY` drops to `0/1`.
