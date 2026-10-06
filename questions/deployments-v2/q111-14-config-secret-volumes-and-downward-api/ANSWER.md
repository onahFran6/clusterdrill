# q111-14: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/

```sh
kubectl patch deployment gateway -n q111-14-config-secret-volumes-and-downward-api --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [
      { "name": "conf", "configMap": { "name": "gateway-conf" } },
      { "name": "key", "secret": { "secretName": "gateway-key", "defaultMode": 256 } }
    ]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env",
    "value": [
      { "name": "POD_NAME", "valueFrom": { "fieldRef": { "fieldPath": "metadata.name" } } },
      { "name": "NODE_NAME", "valueFrom": { "fieldRef": { "fieldPath": "spec.nodeName" } } }
    ]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [
      { "name": "conf", "mountPath": "/etc/nginx/conf.d" },
      { "name": "key", "mountPath": "/etc/gateway", "readOnly": true }
    ]
  }
]'

kubectl rollout status deployment/gateway -n q111-14-config-secret-volumes-and-downward-api --timeout=60s
```

`0400` in YAML/JSON is the decimal integer `256` - Kubernetes stores `defaultMode` as a plain
int32, so the API always reports `256` back, never the octal literal. Mounting a volume on a
directory hides whatever the image shipped there; that's fine for a whole-`conf.d` mount like
this one, but for a directory with other files you'd use `subPath` for just one file - at the
cost of losing the live ConfigMap-update behavior a whole-directory mount still gets. `POD_NAME`
and `NODE_NAME` come from the Downward API's `fieldRef`, resolved by kubelet at pod start - a
different mechanism from `configMapKeyRef`/`secretKeyRef`, which read external objects instead
of the pod's own metadata.
