# q105-19: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

```sh
kubectl delete pod notifier -n q105-19-configmap-override-individual-env

kubectl apply -n q105-19-configmap-override-individual-env -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: notifier
  labels:
    app: notifier
spec:
  containers:
    - name: notifier
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: service-defaults
      env:
        - name: TIMEOUT_SECONDS
          value: "90"
EOF

kubectl wait --for=condition=Ready pod/notifier -n q105-19-configmap-override-individual-env --timeout=60s
```
