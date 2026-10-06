# q114-17: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container

```sh
NS=q114-17-permission-denied-on-the-volume

kubectl logs deploy/uploader -n "$NS" --previous 2>/dev/null || kubectl logs deploy/uploader -n "$NS"
# sh: can't create /data/upload.txt: Permission denied

kubectl patch deployment uploader -n "$NS" --type=json -p='[
  {"op": "add", "path": "/spec/template/spec/initContainers", "value": [
    {
      "name": "fix-perms",
      "image": "busybox:1.36",
      "command": ["sh", "-c", "chown 1000:2000 /data && chmod 775 /data"],
      "securityContext": {"runAsUser": 0},
      "volumeMounts": [{"name": "d", "mountPath": "/data"}]
    }
  ]}
]'

kubectl rollout status deployment/uploader -n "$NS" --timeout=60s
kubectl exec deploy/uploader -n "$NS" -- stat -c %u /data
kubectl exec deploy/uploader -n "$NS" -- id
```

A container-level `runAsUser: 0` overrides the pod-level `1000` for the init container only, so
the app itself still runs as `1000`. `fsGroup` only works for volumes whose driver supports
ownership management - most CSI and block volumes do, `hostPath` never does.
