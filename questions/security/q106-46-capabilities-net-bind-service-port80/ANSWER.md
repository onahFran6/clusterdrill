# q106-46-capabilities-net-bind-service-port80: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container

Capabilities are set at container creation time and cannot be patched onto a running Pod - delete
and recreate it.

```sh
kubectl delete pod privileged-port-listener -n q106-46-capabilities-net-bind-service-port80 --wait=true

kubectl apply -n q106-46-capabilities-net-bind-service-port80 -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-port-listener
  labels:
    app: privileged-port-listener
spec:
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  containers:
    - name: listener
      image: busybox:1.36
      command: ["sh", "-c", "while true; do nc -l -p 80 -e echo ok; done"]
      securityContext:
        capabilities:
          add: ["NET_BIND_SERVICE"]
          drop: ["ALL"]
      readinessProbe:
        tcpSocket:
          port: 80
        periodSeconds: 2
        failureThreshold: 1
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/privileged-port-listener -n q106-46-capabilities-net-bind-service-port80 --timeout=60s
```
