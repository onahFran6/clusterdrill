# q118-17: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-17-timestamped-backups-no-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backups
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: 0 */6 * * *
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: data
              readOnly: true
          - name: backups
            persistentVolumeClaim:
              claimName: backups
          containers:
          - name: backup
            image: busybox:1.36
            command:
            - sh
            - -c
            - d=/backups/\$(date +%Y%m%d-%H%M%S); mkdir -p "\$d" && cp -a /data/. "\$d/" && echo saved "\$d"
            volumeMounts:
            - name: data
              mountPath: /data
              readOnly: true
            - name: backups
              mountPath: /backups
YAML
kubectl create job backup-1 -n "$NS" --from=cronjob/backup
kubectl wait -n "$NS" --for=condition=complete job/backup-1 --timeout=120s
sleep 2
kubectl create job backup-2 -n "$NS" --from=cronjob/backup
kubectl wait -n "$NS" --for=condition=complete job/backup-2 --timeout=120s
```

These ReadWriteOnce claims assume the single-node lab; multi-node setups need compatible shared storage or placement rules.
The grader creates and removes a reader Pod to inspect the claim.
A file copy is not a transactionally consistent database backup.
