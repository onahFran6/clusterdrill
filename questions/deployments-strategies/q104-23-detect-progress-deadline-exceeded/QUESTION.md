# q104-23-detect-progress-deadline-exceeded: Detect a rollout that exceeded its progress deadline

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-23-detect-progress-deadline-exceeded`

A Deployment named `report-generator` exists in the `q104-23-detect-progress-deadline-exceeded` namespace with `spec.progressDeadlineSeconds: 20` and 2 replicas. Its rolling update to a bad image tag has stalled: the new ReplicaSet's pods are stuck in `ImagePullBackOff`, and the deadline has already elapsed, so the Deployment's `Progressing` condition now reports `status: False` with `reason: ProgressDeadlineExceeded`.

Without changing the Deployment's image or any other field, inspect the Deployment to find this failing condition's reason, then create a throwaway Pod named `checker` in the same namespace (image `busybox:1.36`, `restartPolicy: Never`) whose container command writes that exact reason string to the file `/tmp/deadline-reason.txt` inside the pod and then sleeps (so the pod stays running long enough to be inspected). For example the container command could be `sh -c "echo ProgressDeadlineExceeded > /tmp/deadline-reason.txt; sleep 3600"`.

## Hint

Search kubernetes.io/docs for **"ProgressDeadlineExceeded"** - the Deployments concept page's "Failed Deployment" section shows how `kubectl describe deployment` / `kubectl get deployment -o jsonpath` surface a stalled rollout's `Progressing` condition reason, which you can then bake into a Pod's command.
