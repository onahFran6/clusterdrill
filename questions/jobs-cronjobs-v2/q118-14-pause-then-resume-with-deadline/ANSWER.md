# q118-14: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#schedule-suspension)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-14-pause-then-resume-with-deadline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl patch cronjob billing -n "$NS" --type=merge -p '{"spec":{"suspend":true}}'
kubectl get jobs -n "$NS"
sleep 120
kubectl get jobs -n "$NS"
kubectl patch cronjob billing -n "$NS" --type=merge -p '{"spec":{"startingDeadlineSeconds":30,"suspend":false}}'
```

Suspension stops new scheduled Jobs, not Jobs already running.
Final grading observes the resumed configuration; the pause interval is a practice observation.
