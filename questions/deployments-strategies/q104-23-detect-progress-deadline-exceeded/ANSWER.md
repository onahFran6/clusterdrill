# q104-23-detect-progress-deadline-exceeded: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment

```sh
QUESTION_ID="q104-23-detect-progress-deadline-exceeded"

# Inspect the Deployment's Progressing condition to find the failing reason
# (in this scenario it is "ProgressDeadlineExceeded").
REASON=$(kubectl get deployment report-generator -n "$QUESTION_ID" \
  -o jsonpath='{.status.conditions[?(@.type=="Progressing")].reason}')

echo "Detected reason: $REASON"

kubectl run checker \
  --image=busybox:1.36 \
  --restart=Never \
  -n "$QUESTION_ID" \
  --command -- sh -c "echo ${REASON} > /tmp/deadline-reason.txt; sleep 3600"

kubectl wait --for=condition=Ready pod/checker -n "$QUESTION_ID" --timeout=60s
```
