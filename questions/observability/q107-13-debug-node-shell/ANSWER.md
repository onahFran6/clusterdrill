# q107-13: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-cluster/kubectl-node-debug/

```sh
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

kubectl debug "node/$NODE_NAME" \
  -it \
  --image=busybox:1.36 \
  -n q107-13-debug-node-shell \
  -- chroot /host sh -c "echo host-debug-ok"
```
