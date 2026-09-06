# q107-04: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command

```sh
kubectl delete pod file-watcher -n q107-04-exec-liveness-probe --ignore-not-found

kubectl apply -n q107-04-exec-liveness-probe -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: file-watcher
  labels:
    app: file-watcher
    clusterdrill-question: q107-04-exec-liveness-probe
spec:
  containers:
    - name: file-watcher
      image: busybox:1.36
      command: ["sh", "-c", "touch /tmp/healthy && sleep 3600"]
      livenessProbe:
        exec:
          command: ["cat", "/tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 10
EOF

kubectl wait --for=condition=Ready pod/file-watcher -n q107-04-exec-liveness-probe --timeout=60s
```
