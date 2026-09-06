# q105-04: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
kubectl create secret generic billing-secret \
  --from-literal=DB_PASSWORD=s3cr3t-pass \
  -n q105-04-secret-generic-env-var

kubectl delete pod billing-app -n q105-04-secret-generic-env-var

kubectl apply -n q105-04-secret-generic-env-var -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: billing-app
  labels:
    app: billing-app
spec:
  containers:
    - name: billing-app
      image: nginx:1.25-alpine
      env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: billing-secret
              key: DB_PASSWORD
EOF

kubectl wait --for=condition=Ready pod/billing-app -n q105-04-secret-generic-env-var --timeout=60s
```
