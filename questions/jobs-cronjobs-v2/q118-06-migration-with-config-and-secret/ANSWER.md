# q118-06: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-06-migration-with-config-and-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo migrating \$DB_HOST to v\$TARGET_VERSION; [ -n "\$DB_PASSWORD" ] && echo password present
        envFrom:
        - configMapRef:
            name: migrate-config
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: password
YAML
kubectl wait -n "$NS" --for=condition=complete job/migrate --timeout=120s
kubectl logs job/migrate -n "$NS"
```
