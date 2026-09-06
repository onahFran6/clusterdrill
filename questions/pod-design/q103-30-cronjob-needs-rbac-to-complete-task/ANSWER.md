# q103-30: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

```sh
NS="q103-30-cronjob-needs-rbac-to-complete-task"

kubectl create role status-recorder-patcher \
  --verb=get --verb=patch --verb=update \
  --resource=configmaps --resource-name=job-status \
  -n "$NS"

kubectl create rolebinding status-recorder-patcher-binding \
  --role=status-recorder-patcher \
  --serviceaccount="${NS}:status-recorder-sa" \
  -n "$NS"

kubectl create job status-recorder-manual --from=cronjob/status-recorder -n "$NS"

kubectl wait --for=condition=Complete job/status-recorder-manual -n "$NS" --timeout=60s

kubectl get configmap job-status -n "$NS" -o jsonpath='{.data.last_run_status}'
```
