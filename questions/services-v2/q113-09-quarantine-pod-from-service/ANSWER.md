# q113-09-quarantine-pod-from-service: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#how-a-replicaset-works

```sh
QUESTION_ID=q113-09-quarantine-pod-from-service

P=$(kubectl get pods -n "$QUESTION_ID" -l app=menu -o jsonpath='{.items[0].metadata.name}')
kubectl label pod "$P" -n "$QUESTION_ID" app=menu-debug --overwrite
```

Both the Service and the ReplicaSet find their pods purely by label selector - neither owns the
pod itself. The moment `$P` stops matching `app=menu`, the ReplicaSet notices it's short one pod
and creates a replacement, and the Service's endpoints drop it, while `$P` itself keeps running
untouched: you can still `kubectl exec`/`kubectl logs` into it for as long as you need, and delete
it yourself when you're done investigating. A failing readiness probe would only have removed it
from the Service - the ReplicaSet would still have counted it as one of its 3.
