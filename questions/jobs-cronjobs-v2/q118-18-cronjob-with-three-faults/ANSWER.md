# q118-18: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#job-template)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-18-cronjob-with-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
WORK_DIR="$HOME/practice-work/q118-18-cronjob-with-three-faults/"
cat > "$WORK_DIR/report-cj.yaml" <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/5 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: report
            image: busybox:1.36
            command:
            - sh
            - -c
            - '[ -n "\$TOKEN" ] && echo report sent'
            env:
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: report-secret
                  key: token
YAML
kubectl apply -n "$NS" -f "$WORK_DIR/report-cj.yaml"
kubectl delete job report-now -n "$NS" --ignore-not-found
kubectl create job report-now -n "$NS" --from=cronjob/report
kubectl wait -n "$NS" --for=condition=complete job/report-now --timeout=120s
kubectl logs job/report-now -n "$NS"
```

The four-field schedule and restartPolicy Always are API validation errors.
The uppercase Secret key is a container startup error.
Fixing a CronJob template only affects future Jobs; delete and recreate an existing manual Job after correcting its template.
The local file is an input, and grading checks the applied live resources.
