# q107-36-kubectl-top-nodes-basic: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#top

```sh
mkdir -p "$HOME/practice-work/q107-36-kubectl-top-nodes-basic"

# metrics-server can return empty/errors for a few seconds after load
ok=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if kubectl top nodes > "$HOME/practice-work/q107-36-kubectl-top-nodes-basic/node-usage.txt" \
      && [ -s "$HOME/practice-work/q107-36-kubectl-top-nodes-basic/node-usage.txt" ]; then
    ok=1
    break
  fi
  sleep 5
done
[ "$ok" = 1 ]
```
