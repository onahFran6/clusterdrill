# q107-31-kubectl-logs-since-duration: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs

```sh
mkdir -p "$HOME/practice-work/q107-31-kubectl-logs-since-duration"

kubectl logs heartbeat -n q107-31-kubectl-logs-since-duration --since=5s \
  > "$HOME/practice-work/q107-31-kubectl-logs-since-duration/heartbeat-recent.txt"
```
