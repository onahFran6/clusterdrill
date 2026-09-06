# q102-32: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables

```sh
kubectl delete pod token-reporter -n q102-32-sidecar-secret-env-typo --ignore-not-found --wait=true

kubectl apply -n q102-32-sidecar-secret-env-typo -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: token-reporter
  labels:
    clusterdrill-question: q102-32-sidecar-secret-env-typo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: reporter
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /report; while true; do echo \"\${API_TOKEN:-MISSING_TOKEN}\" > /report/status.txt; sleep 5; done"]
      envFrom:
        - secretRef:
            name: api-credentials
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
