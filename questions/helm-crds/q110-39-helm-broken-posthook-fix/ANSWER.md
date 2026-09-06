# q110-39-helm-broken-posthook-fix: reference solution

Doc: https://helm.sh/docs/topics/charts_hooks/

```sh
NS=q110-39-helm-broken-posthook-fix
CHART=questions/helm-crds/q110-39-helm-broken-posthook-fix/chart

cat > "$CHART/templates/posthook.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-notifier-posthook
  labels:
    app: notifier
    clusterdrill-question: $NS
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: notifier
        clusterdrill-question: $NS
    spec:
      restartPolicy: Never
      containers:
        - name: post-install-notify
          image: busybox:1.36
          command: ["sh", "-c", "exit 0"]
EOF

# post-install hooks only run on `helm install`, never on `helm upgrade` -
# the failed release must be uninstalled and reinstalled fresh.
helm uninstall demo -n "$NS"
helm install demo "$CHART" -n "$NS" --timeout 30s
```
