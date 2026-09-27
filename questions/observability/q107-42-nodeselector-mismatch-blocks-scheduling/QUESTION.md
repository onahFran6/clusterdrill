# q107-42: Diagnose a Pod stuck Pending due to an unsatisfiable nodeSelector

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-42-nodeselector-mismatch-blocks-scheduling`

A Pod named `report-worker` (image `nginx:1.25-alpine`) already exists and is stuck `Pending`.

Get it to `Running` without labeling or otherwise modifying any Node. This lab's node is shared
across questions and is not reset between them. Change only the Pod, and keep its image.

## Hint

Search kubernetes.io/docs for **"nodeSelector"** - the assigning pods to nodes concept page
explains that a Pod with a `nodeSelector` value no node carries stays unschedulable, and that
`kubectl describe pod` surfaces this as a `FailedScheduling` event naming the unmatched selector.
This Pod sets `nodeSelector: {disktype: ssd}`. `kubectl get nodes --show-labels` shows no node
has that label. Remove or correct the selector; do not label the node.
