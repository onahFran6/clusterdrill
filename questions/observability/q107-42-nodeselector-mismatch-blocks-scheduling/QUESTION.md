# q107-42: Diagnose a Pod stuck Pending due to an unsatisfiable nodeSelector

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-42-nodeselector-mismatch-blocks-scheduling`

`setup.sh` already created a Pod named `report-worker` (image `nginx:1.25-alpine`) with
`nodeSelector: {disktype: ssd}`. It's stuck `Pending` - no node in this cluster carries that label.
Diagnose why using `kubectl describe pod` and `kubectl get nodes --show-labels`, then fix
`report-worker` so it schedules and reaches `Running`, **without** labeling or otherwise modifying
any actual Node (this lab's node is shared across every question and isn't reset between them -
only change the Pod).

## Hint

Search kubernetes.io/docs for **"nodeSelector"** - the assigning pods to nodes concept page
explains that a Pod with a `nodeSelector` value no node carries stays unschedulable, and that
`kubectl describe pod` surfaces this as a `FailedScheduling` event naming the unmatched selector.
