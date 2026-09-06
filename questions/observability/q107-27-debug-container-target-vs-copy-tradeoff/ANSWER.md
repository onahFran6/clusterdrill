# q107-27-debug-container-target-vs-copy-tradeoff: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#copying-a-pod-while-adding-a-new-container

```sh
# Step 1: attach an ephemeral debug container to the existing pod, targeting
# the worker-proc container so the ephemeral container shares that one
# container's process namespace even though shareProcessNamespace is unset
# at the pod level.
kubectl debug -it worker-proc -n q107-27-debug-container-target-vs-copy-tradeoff \
  --image=busybox:1.36 --target=worker-proc -- sh -c "ps aux"

# Step 2: generalize the technique for pods with multiple app containers -
# create a full debug copy of the pod with process namespace sharing turned
# on for every container in the copy, and pin every container's image to
# busybox:1.36.
kubectl debug worker-proc -n q107-27-debug-container-target-vs-copy-tradeoff \
  --copy-to=worker-proc-debug \
  --set-image="*=busybox:1.36" \
  --share-processes
```
