# q107-29: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap

```sh
NS=q107-29-cronjob-failed-runs-log-forensics

# Investigate first: find the failed Job's pod(s) and read their logs.
kubectl get jobs -n "$NS"
kubectl get pods -n "$NS" --show-labels
FAILED_POD=$(kubectl get pods -n "$NS" -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$FAILED_POD" -n "$NS"
# -> starting cleanup
# -> cat: can't open '/data/manifest.txt': No such file or directory
# -> (container exits non-zero, no "done" line)

# Fix: mount the existing 'cleanup-manifest' ConfigMap at /data.
kubectl patch cronjob nightly-cleanup -n "$NS" --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/jobTemplate/spec/template/spec/volumes",
    "value": [
      {
        "name": "data",
        "configMap": {
          "name": "cleanup-manifest"
        }
      }
    ]
  },
  {
    "op": "add",
    "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts",
    "value": [
      {
        "name": "data",
        "mountPath": "/data"
      }
    ]
  }
]'

# Verify: trigger a fresh run and confirm it completes successfully.
kubectl delete job nightly-cleanup-verify -n "$NS" --ignore-not-found --wait=true
kubectl create job nightly-cleanup-verify --from=cronjob/nightly-cleanup -n "$NS"
kubectl wait --for=condition=Complete job/nightly-cleanup-verify -n "$NS" --timeout=60s
```
