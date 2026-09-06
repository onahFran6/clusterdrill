# q107-46-livenessprobe-exec-array-vs-shell-pipeline: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command

An `exec` probe's `command` array runs the program directly - there is no shell involved unless
you explicitly invoke one, so `|` (and other shell syntax) must be wrapped in `sh -c "..."` to
work as a pipeline.

Probe fields are set at container creation time and cannot be patched onto a running Pod - delete
and recreate it.

```sh
kubectl delete pod status-writer -n q107-46-livenessprobe-exec-array-vs-shell-pipeline --wait=true

kubectl apply -n q107-46-livenessprobe-exec-array-vs-shell-pipeline -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: status-writer
  labels:
    app: status-writer
spec:
  containers:
    - name: status-writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo ok > /tmp/status; sleep 1; done"]
      livenessProbe:
        exec:
          command: ["sh", "-c", "cat /tmp/status | grep ok"]
        initialDelaySeconds: 3
        periodSeconds: 2
        failureThreshold: 1
EOF

kubectl wait --for=condition=Ready pod/status-writer -n q107-46-livenessprobe-exec-array-vs-shell-pipeline --timeout=60s
```
