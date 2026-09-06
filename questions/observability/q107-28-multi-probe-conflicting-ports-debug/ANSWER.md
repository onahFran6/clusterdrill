# q107-28-multi-probe-conflicting-ports-debug: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
# Inspect the ConfigMap to confirm the real listen port is 8081:
kubectl get configmap nginx-conf -n q107-28-multi-probe-conflicting-ports-debug -o yaml

kubectl delete pod payments-gw -n q107-28-multi-probe-conflicting-ports-debug --ignore-not-found

kubectl apply -n q107-28-multi-probe-conflicting-ports-debug -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: payments-gw
  labels:
    app: payments-gw
    clusterdrill-question: q107-28-multi-probe-conflicting-ports-debug
spec:
  containers:
    - name: payments-gw
      image: nginx:1.25-alpine
      ports:
        - containerPort: 8081
      volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      startupProbe:
        httpGet:
          path: /
          port: 8081
        periodSeconds: 2
        failureThreshold: 5
      livenessProbe:
        httpGet:
          path: /
          port: 8081
        periodSeconds: 5
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /
          port: 8081
        periodSeconds: 5
        failureThreshold: 3
  volumes:
    - name: nginx-conf
      configMap:
        name: nginx-conf
EOF

kubectl wait --for=condition=Ready pod/payments-gw -n q107-28-multi-probe-conflicting-ports-debug --timeout=60s
```
