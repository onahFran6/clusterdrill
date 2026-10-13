# q118-16: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#referring-to-resources)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-16-rbac-scoped-scale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: night-scaler
  namespace: $NS
  labels:
    clusterdrill-question: $NS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: night-scaler
  namespace: $NS
  labels:
    clusterdrill-question: $NS
rules:
- apiGroups:
  - apps
  resources:
  - deployments/scale
  verbs:
  - get
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: night-scaler
  namespace: $NS
  labels:
    clusterdrill-question: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: night-scaler
subjects:
- kind: ServiceAccount
  name: night-scaler
  namespace: $NS
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: night-scale
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: 0 22 * * *
  timeZone: Africa/Lagos
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: Never
          serviceAccountName: night-scaler
          containers:
          - name: scale
            image: curlimages/curl:8.10.1
            command:
            - sh
            - -c
            - 'D=/var/run/secrets/kubernetes.io/serviceaccount

              curl --fail-with-body -sS -o /dev/null -w "scale patch: %{http_code}\n" -X PATCH --cacert "\$D/ca.crt" -H "Authorization: Bearer \$(cat "\$D/token")" -H "Content-Type: application/merge-patch+json" --data ''{"spec":{"replicas":1}}'' https://kubernetes.default.svc/apis/apps/v1/namespaces/$NS/deployments/web/scale'
YAML
kubectl create job night-scale-now -n "$NS" --from=cronjob/night-scale
kubectl wait -n "$NS" --for=condition=complete job/night-scale-now --timeout=120s
kubectl logs job/night-scale-now -n "$NS"
```
