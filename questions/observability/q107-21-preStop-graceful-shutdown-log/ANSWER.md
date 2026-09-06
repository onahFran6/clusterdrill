# q107-21-preStop-graceful-shutdown-log: reference solution

Doc: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/

```sh
kubectl delete pod session-worker -n q107-21-prestop-graceful-shutdown-log --ignore-not-found

kubectl apply -n q107-21-prestop-graceful-shutdown-log -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: session-worker
  labels:
    app: session-worker
    clusterdrill-question: q107-21-prestop-graceful-shutdown-log
spec:
  terminationGracePeriodSeconds: 10
  containers:
    - name: session-worker
      image: busybox:1.36
      command: ["sh", "-c", "trap : TERM; while true; do sleep 1; done"]
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "echo shutting down > /tmp/shutdown.log; sleep 2"]
EOF

kubectl wait --for=condition=Ready pod/session-worker -n q107-21-prestop-graceful-shutdown-log --timeout=60s
```
