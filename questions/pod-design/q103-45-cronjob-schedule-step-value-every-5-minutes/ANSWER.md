# q103-45: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax

**Approach A - Fastest (exam default).** Generate it, then fix the one field the generator gets
wrong - less typing and less room for a schedule/command typo than a hand-written manifest:

```sh
NS=q103-45-cronjob-schedule-step-value-every-5-minutes

manifest="$(kubectl create cronjob metrics-poll -n "$NS" --image=busybox:1.36 \
  --schedule="*/5 * * * *" --dry-run=client -o yaml -- echo polling)"

# The generator defaults restartPolicy to OnFailure - fix it (portable bash
# substitution, not sed -i, which differs between BSD/macOS and GNU/Linux).
manifest="${manifest/restartPolicy: OnFailure/restartPolicy: Never}"

echo "$manifest" | kubectl apply -n "$NS" -f -
kubectl label cronjob metrics-poll -n "$NS" "clusterdrill-question=$NS" --overwrite
```

**Approach B - Alternative.** Write the whole manifest by hand - no generator quirk to remember,
but more typing and more surface for a syntax slip:

```text
kubectl apply -n q103-45-cronjob-schedule-step-value-every-5-minutes -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: metrics-poll
  labels:
    clusterdrill-question: q103-45-cronjob-schedule-step-value-every-5-minutes
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: metrics-poll
              image: busybox:1.36
              command: ["echo", "polling"]
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - generator + fix | low | low - only one field to check | high - the default "new object" reflex |
| B - hand-written YAML | high | medium - easy to typo nested fields | medium - only when you distrust the generator's defaults |
