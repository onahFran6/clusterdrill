# q107-20: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pod-replication-controller/#debugging-init-containers

```sh
# Investigate (read-only, informational):
#   kubectl describe pod report-gen -n q107-20-init-container-blocking-app
#   kubectl logs report-gen -n q107-20-init-container-blocking-app -c wait-for-config

kubectl label pod report-gen -n q107-20-init-container-blocking-app app=report-gen --overwrite

kubectl apply -n q107-20-init-container-blocking-app -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: config-svc
  labels:
    clusterdrill-question: q107-20-init-container-blocking-app
spec:
  type: ClusterIP
  selector:
    app: report-gen
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Ready pod/report-gen -n q107-20-init-container-blocking-app --timeout=120s
```
