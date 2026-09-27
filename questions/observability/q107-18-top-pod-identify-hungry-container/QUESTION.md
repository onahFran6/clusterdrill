# q107-18: Use kubectl top to identify the highest CPU-consuming pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-18-top-pod-identify-hungry-container`

Three pods already exist in namespace `q107-18-top-pod-identify-hungry-container`: `quiet-a`,
`quiet-b`, and `burner`. metrics-server has already collected at least one sample for all three.

Using `kubectl top pod` in this namespace, find the pod with the highest CPU usage and label only
that pod `role=cpu-hog`. Do not add the label to the other two.

## Hint

Search kubernetes.io/docs for **"kubectl top pod"** - the Resource metrics pipeline docs
show how `kubectl top` surfaces per-pod CPU/memory usage collected by metrics-server. Two of
these pods idle; one runs a tight busy-loop and uses far more CPU. The label is applied with
`kubectl label pod <pod-name> role=cpu-hog -n q107-18-top-pod-identify-hungry-container`.
