# q105-26-diagnose-crashloop-missing-secret-key: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
# Diagnosis: kubectl describe pod -l app=gateway -n q105-26-diagnose-crashloop-missing-secret-key
# shows an Event like:
#   Error: secret "api-secret" doesn't contain key "APITOKEN" (CreateContainerConfigError)
# The container's env var API_TOKEN references secretKeyRef.key "APITOKEN",
# but api-secret only has the key "API_TOKEN". Fix the Deployment's
# secretKeyRef.key - do not touch the Secret itself.

kubectl patch deployment gateway -n q105-26-diagnose-crashloop-missing-secret-key --type strategic -p '
spec:
  template:
    spec:
      containers:
        - name: gateway
          env:
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: api-secret
                  key: API_TOKEN
'

kubectl rollout status deployment/gateway -n q105-26-diagnose-crashloop-missing-secret-key --timeout=60s
```
