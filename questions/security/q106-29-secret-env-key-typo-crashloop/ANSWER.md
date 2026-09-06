# q106-29-secret-env-key-typo-crashloop: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
# Diagnosis: kubectl describe pod billing-worker -n q106-29-secret-env-key-typo-crashloop
# shows an Event like:
#   Error: secret "db-creds" doesn't contain key "passwd" (CreateContainerConfigError)
# The container's env var DB_PASS references key "passwd", but db-creds only
# has "username" and "password". Pod spec.containers[].env is immutable, so
# fix it by recreating the Pod with the corrected key.

kubectl delete pod billing-worker -n q106-29-secret-env-key-typo-crashloop --ignore-not-found

kubectl apply -n q106-29-secret-env-key-typo-crashloop -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: billing-worker
  labels:
    app: billing-worker
    clusterdrill-question: q106-29-secret-env-key-typo-crashloop
spec:
  containers:
    - name: billing-worker
      image: busybox:1.36
      command: ["sh", "-c", "echo starting; sleep 3600"]
      env:
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: password
EOF

kubectl wait --for=condition=Ready pod/billing-worker -n q106-29-secret-env-key-typo-crashloop --timeout=60s
```
