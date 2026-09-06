# q107-47-terminationmessagepolicy-fallback-to-logs: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/#customizing-the-termination-message

`terminationMessagePolicy` is set at container creation time and cannot be patched onto a running
Pod - delete and recreate it.

```sh
kubectl delete pod batch-runner -n q107-47-terminationmessagepolicy-fallback-to-logs --wait=true

kubectl apply -n q107-47-terminationmessagepolicy-fallback-to-logs -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-runner
  labels:
    app: batch-runner
spec:
  containers:
    - name: batch-runner
      image: busybox:1.36
      command: ["sh", "-c", "echo custom failure: disk quota exceeded >&2; exit 1"]
      terminationMessagePolicy: FallbackToLogsOnError
EOF
```

Wait a couple of restart cycles, then confirm:

```sh
kubectl get pod batch-runner -n q107-47-terminationmessagepolicy-fallback-to-logs \
  -o jsonpath='{.status.containerStatuses[0].lastState.terminated.message}'
```
