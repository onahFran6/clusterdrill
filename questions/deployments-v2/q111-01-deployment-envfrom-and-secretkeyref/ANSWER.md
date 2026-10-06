# q111-01: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
cat <<'EOF' | kubectl apply -n q111-01-deployment-envfrom-and-secretkeyref -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    clusterdrill-question: q111-01-deployment-envfrom-and-secretkeyref
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        tier: backend
        clusterdrill-question: q111-01-deployment-envfrom-and-secretkeyref
    spec:
      containers:
        - name: api
          image: nginx:1.27
          envFrom:
            - configMapRef:
                name: api-config
          env:
            - name: APP_ENV
              value: staging
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: api-creds
                  key: DB_PASSWORD
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              memory: 128Mi
EOF

kubectl rollout status deployment/api -n q111-01-deployment-envfrom-and-secretkeyref --timeout=60s
```

`envFrom` with a `configMapRef` imports every key in `api-config` as an env var in one shot.
`envFrom` with a `secretRef` would do the same for the whole Secret - that would also leak
`DB_USER` and keep the original key name. Use `secretKeyRef` under `env` whenever only one key
should reach the container, optionally under a new name.
