# q107-05: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe

```sh
kubectl delete pod cache-node -n q107-05-tcpsocket-readiness-probe --ignore-not-found

kubectl apply -n q107-05-tcpsocket-readiness-probe -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cache-node
  labels:
    app: cache-node
    clusterdrill-question: q107-05-tcpsocket-readiness-probe
spec:
  containers:
    - name: cache-node
      image: redis:7-alpine
      ports:
        - containerPort: 6379
      readinessProbe:
        tcpSocket:
          port: 6379
        initialDelaySeconds: 5
        periodSeconds: 10
EOF

kubectl wait --for=condition=Ready pod/cache-node -n q107-05-tcpsocket-readiness-probe --timeout=60s
```
