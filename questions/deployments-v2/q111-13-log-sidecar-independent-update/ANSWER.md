# q111-13: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
NS=q111-13-log-sidecar-independent-update

kubectl patch deployment orders -n "$NS" --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [{ "name": "logs", "emptyDir": {} }]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [{ "name": "logs", "mountPath": "/var/log/app" }]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/1",
    "value": {
      "name": "log-shipper",
      "image": "busybox:1.36",
      "command": ["sh", "-c", "tail -F /var/log/app/orders.log"],
      "volumeMounts": [{ "name": "logs", "mountPath": "/var/log/app" }]
    }
  }
]'
kubectl rollout status deployment/orders -n "$NS" --timeout=60s

kubectl set image deployment/orders log-shipper=busybox:1.37 -n "$NS"
kubectl rollout status deployment/orders -n "$NS" --timeout=60s
```

Changing one container's image still replaces the whole pod - any pod-template change produces a
new ReplicaSet - but `kubectl set image deploy/orders log-shipper=busybox:1.37` only touches the
sidecar's `image` field, leaving `app`'s own image exactly as it was. Since Kubernetes 1.29 a
sidecar can also be written as an init container with `restartPolicy: Always`, which starts
before and stops after the main container; use the plain second-container form shown here unless
a question specifically asks for that newer form.
