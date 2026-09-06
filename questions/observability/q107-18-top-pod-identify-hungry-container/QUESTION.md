# q107-18: Use kubectl top to identify the highest CPU-consuming pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-18-top-pod-identify-hungry-container`

`setup.sh` created three pods in namespace `q107-18-top-pod-identify-hungry-container`:
`quiet-a`, `quiet-b`, and `burner`. Two of them idle; one runs a tight busy-loop that
consumes far more CPU than the others. metrics-server has already collected at least one
sample for all three pods.

Run `kubectl top pod -n q107-18-top-pod-identify-hungry-container` to find the pod with the
highest CPU usage, then label that pod (and only that pod) to mark it:

```sh
kubectl label pod <pod-name> role=cpu-hog -n q107-18-top-pod-identify-hungry-container
```

Do not add the `role=cpu-hog` label to either of the other two pods.

## Hint

Search kubernetes.io/docs for **"kubectl top pod"** - the Resource metrics pipeline docs
show how `kubectl top` surfaces per-pod CPU/memory usage collected by metrics-server.
