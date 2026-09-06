# q107-17-logs-since-time-window: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs

```sh
mkdir -p "$HOME/practice-work/q107-17-logs-since-time-window"
kubectl logs ticker -n q107-17-logs-since-time-window --tail=5 \
  > "$HOME/practice-work/q107-17-logs-since-time-window/ticker-tail.txt"
```
