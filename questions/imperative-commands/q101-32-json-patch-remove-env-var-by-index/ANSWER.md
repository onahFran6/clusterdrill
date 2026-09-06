# q101-32-json-patch-remove-env-var-by-index: reference solution

Doc: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/#use-a-json-patch-to-selectively-update-a-field

```sh
NS=q101-32-json-patch-remove-env-var-by-index

# 1. spec.containers[*].env is immutable on a running pod - the API server
# rejects a JSON Patch remove aimed at the live object directly:
#   kubectl patch pod api-worker -n "$NS" --type=json \
#     -p='[{"op": "remove", "path": "/spec/containers/0/env/2"}]'
#   -> Forbidden: pod updates may not change fields other than ...
#
# So patch a local copy of the manifest instead, then delete+recreate.

kubectl get pod api-worker -n "$NS" -o yaml > /tmp/api-worker.yaml

# LEGACY_API_URL is index 2 in the env array (APP_ENV=0, LOG_LEVEL=1,
# LEGACY_API_URL=2, MAX_RETRIES=3, CACHE_TTL=4). A JSON Patch "remove" on
# that exact array index deletes only that element and shifts the rest up
# by one - the other four keep their order and values untouched, unlike
# hand-rewriting the whole env list where a copy/paste slip could reorder
# or drop one.
kubectl patch --local -f /tmp/api-worker.yaml --type=json \
  -p='[{"op": "remove", "path": "/spec/containers/0/env/2"}]' \
  -o yaml > /tmp/api-worker-patched.yaml

kubectl delete pod api-worker -n "$NS" --ignore-not-found --wait=true

kubectl apply -f /tmp/api-worker-patched.yaml -n "$NS"

kubectl wait --for=condition=Ready pod/api-worker -n "$NS" --timeout=60s

kubectl get pod api-worker -n "$NS" \
  -o jsonpath='{range .spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```
