# q107-41-job-failed-pod-logs-forensics: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs

```sh
kubectl get pods -n q107-41-job-failed-pod-logs-forensics -l job-name=data-migration

mkdir -p "$HOME/practice-work/q107-41-job-failed-pod-logs-forensics"

kubectl logs -n q107-41-job-failed-pod-logs-forensics -l job-name=data-migration --tail=1 \
  > "$HOME/practice-work/q107-41-job-failed-pod-logs-forensics/failure-reason.txt"
```
