# q102-28: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

```sh
QUESTION_ID=q102-28-shared-pid-namespace-signal-container

# shareProcessNamespace is immutable on a running Pod - delete and
# recreate it with the field set, keeping the same containers/commands.
kubectl delete pod config-reload-app -n "$QUESTION_ID" --ignore-not-found --wait=true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: config-reload-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  shareProcessNamespace: true
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "trap 'echo reload-\$(date +%s) >> /tmp/main-reload.log' HUP; i=0; while true; do i=\$((i+1)); echo tick \$i >> /tmp/main-tick.log; sleep 2; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: watcher
      image: busybox:1.36
      command: ["sh", "-c", "sleep 5; while true; do PID=\$(ps -o pid,args | grep main-reload.log | grep -v grep | awk '{print \$1}'); if [ -n \"\$PID\" ]; then kill -HUP \$PID; fi; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/config-reload-app -n "$QUESTION_ID" --timeout=60s

# Give watcher (5s initial sleep + up to 5s poll interval) time to find
# main's PID in the now-shared namespace and deliver SIGHUP at least once,
# polling instead of a single snapshot so this doesn't race the sidecar.
for i in $(seq 1 15); do
  if kubectl exec config-reload-app -c main -n "$QUESTION_ID" -- sh -c 'test -s /tmp/main-reload.log' 2>/dev/null; then
    break
  fi
  sleep 5
done
```
