# q107-25-cascading-liveness-failure-dependent-service: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

```sh
NS=q107-25-cascading-liveness-failure-dependent-service

# Diagnose: kubectl describe pod's Events show
#   Error: couldn't find key LISTEN_PORT in ConfigMap q107-25-cascading-liveness-failure-dependent-service/orders-config
# i.e. a CreateContainerConfigError, not an OOMKill or a probe failure - the
# container never starts, so the tcpSocket livenessProbe never even runs.
kubectl describe pod orders-api -n "$NS" || true

# Pod env is immutable, so fix it by recreating the pod with the same spec
# except the ConfigMap key the env var references, corrected from
# LISTEN_PORT (does not exist) to PORT (the key orders-config actually has).
kubectl delete pod orders-api -n "$NS" --ignore-not-found

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: orders-api
  labels:
    app: orders-api
    clusterdrill-question: $NS
spec:
  containers:
    - name: orders-api
      image: busybox:1.36
      command:
        - sh
        - -c
        - 'PORT=\${LISTEN_PORT:-0}; if [ "\$PORT" = "0" ]; then exit 1; fi; httpd -f -p \$PORT -h /tmp 2>&1'
      env:
        - name: LISTEN_PORT
          valueFrom:
            configMapKeyRef:
              name: orders-config
              key: PORT
      livenessProbe:
        tcpSocket:
          port: 8080
        initialDelaySeconds: 3
        periodSeconds: 5
EOF

kubectl wait --for=condition=Ready pod/orders-api -n "$NS" --timeout=60s
```
