# q111-12: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl patch deployment docs -n q111-12-init-container-builds-content --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [{ "name": "html", "emptyDir": {} }]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/initContainers",
    "value": [
      {
        "name": "build",
        "image": "busybox:1.36",
        "command": ["sh", "-c", "echo built by init on $(hostname) > /work/index.html"],
        "volumeMounts": [{ "name": "html", "mountPath": "/work" }]
      }
    ]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [{ "name": "html", "mountPath": "/usr/share/nginx/html" }]
  }
]'

kubectl rollout status deployment/docs -n q111-12-init-container-builds-content --timeout=60s
```

`emptyDir` is created fresh with the pod and deleted with it - exactly the "pod-lifetime" volume
the task needs; both containers mount it, at different paths. An init container must exit
successfully before any app container starts, so by the time nginx starts, `index.html` is
already in place at the directory nginx serves by default. If the init container ever fails, the
pod shows `Init:Error` or `Init:CrashLoopBackOff`, and `kubectl logs <pod> -c build` explains why.
