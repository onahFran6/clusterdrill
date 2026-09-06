# q106-31-serviceaccount-token-projection-audience: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection

```sh
NS=q106-31-serviceaccount-token-projection-audience

kubectl delete pod secrets-agent -n "$NS" --wait=true

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secrets-agent
  labels:
    clusterdrill-question: $NS
spec:
  serviceAccountName: vault-client
  automountServiceAccountToken: false
  containers:
    - name: secrets-agent
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: vault-token
          mountPath: /var/run/secrets/tokens
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: vault-token
      projected:
        sources:
          - serviceAccountToken:
              audience: vault
              expirationSeconds: 600
              path: vault-token
EOF

kubectl wait --for=condition=Ready pod/secrets-agent -n "$NS" --timeout=60s
```
