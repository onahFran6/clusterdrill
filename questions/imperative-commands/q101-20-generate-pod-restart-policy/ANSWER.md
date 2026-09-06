# q101-20: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy

```sh
kubectl run one-shot-task --image=busybox:1.36 \
  -n q101-20-generate-pod-restart-policy \
  --dry-run=client -o yaml \
  -- echo done > /tmp/one-shot-task.yaml

sed -i.bak 's/restartPolicy: Always/restartPolicy: Never/' /tmp/one-shot-task.yaml

kubectl apply -f /tmp/one-shot-task.yaml
```
