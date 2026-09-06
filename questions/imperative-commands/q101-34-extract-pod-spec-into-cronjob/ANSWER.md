# q101-34: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_cronjob/

```sh
NS=q101-34-extract-pod-spec-into-cronjob

# 1. Extract the source pod's exact image, env vars, and command via
#    jsonpath - don't just eyeball the full YAML.
kubectl get pod legacy-report-gen -n "$NS" -o jsonpath='{.spec.containers[0].image}{"\n"}'
kubectl get pod legacy-report-gen -n "$NS" -o jsonpath='{range .spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
kubectl get pod legacy-report-gen -n "$NS" -o jsonpath='{.spec.containers[0].command[*]}{"\n"}'

# 2. Generate a starting CronJob manifest imperatively.
kubectl create cronjob report-job \
  --image=busybox:1.36 \
  --schedule="*/5 * * * *" \
  -n "$NS" \
  --dry-run=client -o yaml > /tmp/report-job.yaml

# 3. Edit in the env vars and command extracted in step 1 - same three env
#    var names/values, same three-element command array as
#    legacy-report-gen. (Shown here as a heredoc rewrite of the file; in
#    practice this is a manual edit in $EDITOR after step 2.)
cat > /tmp/report-job.yaml <<'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report-job
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: report-job
              image: busybox:1.36
              command: ["sh", "-c", "echo Report type=$REPORT_TYPE output=$OUTPUT_PATH retries=$RETRY_LIMIT && sleep 3600"]
              env:
                - name: REPORT_TYPE
                  value: "weekly"
                - name: OUTPUT_PATH
                  value: "/var/reports/output.txt"
                - name: RETRY_LIMIT
                  value: "5"
          restartPolicy: OnFailure
EOF

# 4. Apply the edited manifest.
kubectl apply -n "$NS" -f /tmp/report-job.yaml
```
