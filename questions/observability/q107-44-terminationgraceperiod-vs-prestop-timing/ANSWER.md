# q107-44-terminationgraceperiod-vs-prestop-timing: reference solution

Doc: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution

`terminationGracePeriodSeconds` is set at Pod creation time and cannot be patched onto a running
Pod - delete and recreate it.

```sh
kubectl delete pod connection-drainer -n q107-44-terminationgraceperiod-vs-prestop-timing --wait=true

kubectl apply -n q107-44-terminationgraceperiod-vs-prestop-timing -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: connection-drainer
  labels:
    app: connection-drainer
spec:
  terminationGracePeriodSeconds: 15
  containers:
    - name: connection-drainer
      image: nginx:1.25-alpine
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "sleep 8"]
EOF

kubectl wait --for=condition=Ready pod/connection-drainer -n q107-44-terminationgraceperiod-vs-prestop-timing --timeout=60s
```
