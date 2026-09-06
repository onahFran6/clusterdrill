# q103-45: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax

```sh
NS=q103-45-cronjob-schedule-step-value-every-5-minutes

kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: metrics-poll
  labels:
    clusterdrill-question: $NS
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      template:
        metadata:
          labels:
            clusterdrill-question: $NS
        spec:
          restartPolicy: Never
          containers:
            - name: metrics-poll
              image: busybox:1.36
              command: ["echo", "polling"]
              resources:
                requests:
                  cpu: 25m
                  memory: 32Mi
                limits:
                  cpu: 50m
                  memory: 64Mi
EOF
```
