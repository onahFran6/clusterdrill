# q114-13: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath-with-expanded-environment-variables

```sh
NS=q114-13-one-folder-per-replica

kubectl patch deployment logger -n "$NS" --type=json -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [
    {"name": "POD_NAME", "valueFrom": {"fieldRef": {"fieldPath": "metadata.name"}}}
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/volumeMounts/0", "value": {
    "name": "logs", "mountPath": "/logs", "subPathExpr": "$(POD_NAME)"
  }}
]'

kubectl rollout status deployment/logger -n "$NS" --timeout=60s
kubectl get pods -n "$NS" -l app=logger -o name

kubectl run look -n "$NS" --image=busybox:1.36 --restart=Never --rm -i \
  --overrides='{"spec":{"volumes":[{"name":"l","persistentVolumeClaim":{"claimName":"logs"}}],"containers":[{"name":"i","image":"busybox:1.36","command":["ls","/all"],"volumeMounts":[{"name":"l","mountPath":"/all"}]}]}}' \
  -- true
```

`subPath` and `subPathExpr` can't be used on the same mount - the fix replaces the mount entirely.
Pod names change on every rollout, so folders from earlier pods stay behind on the claim; that's
fine for logs, but a StatefulSet (q114-14) is the tool when a replica needs a genuinely *stable*
identity instead.
