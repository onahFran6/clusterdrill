# q111-19: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

```sh
NS=q111-19-pending-nodeselector-and-cpu
NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

kubectl label node "$NODE" disktype=ssd
kubectl set resources deployment press -n "$NS" --requests=cpu=250m
kubectl rollout status deployment/press -n "$NS" --timeout=60s
```

`kubectl describe pod -l app=press` on a Pending pod lists every rejection reason at once: no
node matched `disktype=ssd`, *and* no node had 64 CPU cores free - either fault alone would have
left the pods Pending. The three layers worth remembering: a missing dependency like a
ServiceAccount fails at admission and leaves **no pod at all** (read the ReplicaSet); a
scheduling fault like this one leaves a **Pending** pod (read the pod's own events); a
container-start fault leaves a pod in an error state like `CreateContainerConfigError` or
`ImagePullBackOff`. A tainted control-plane node would never pick up a plain label fix like this
one - that only works because this cluster's one node is untainted and schedulable.
