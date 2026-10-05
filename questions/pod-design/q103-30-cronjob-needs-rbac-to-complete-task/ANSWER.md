# q103-30: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

**Approach A - Fastest (exam default).**

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

**Approach B - Alternative.** A YAML manifest instead of the generators - prefer this if you don't
remember `--resource-name`, or want to see the exact rule before applying it:

```text
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: status-recorder-patcher
  namespace: q103-30-cronjob-needs-rbac-to-complete-task
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["job-status"]
    verbs: ["get", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: status-recorder-patcher-binding
  namespace: q103-30-cronjob-needs-rbac-to-complete-task
subjects:
  - kind: ServiceAccount
    name: status-recorder-sa
    namespace: q103-30-cronjob-needs-rbac-to-complete-task
roleRef:
  kind: Role
  name: status-recorder-patcher
  apiGroup: rbac.authorization.k8s.io
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - `kubectl create role`/`rolebinding` generators | low | low (flags are explicit) | high - fastest RBAC reflex |
| B - YAML manifest | higher | medium (must get `resourceNames`/`apiGroups` array syntax right from memory) | medium - fallback when you forget generator flags |
