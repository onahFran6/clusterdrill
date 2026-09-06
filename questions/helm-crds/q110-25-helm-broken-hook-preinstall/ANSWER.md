# q110-25: reference solution

Doc: https://helm.sh/docs/topics/charts_hooks/

```sh
CHART_DIR="questions/helm-crds/q110-25-helm-broken-hook-preinstall/chart"

# Fix the pre-install hook Job's command so it exits 0 instead of 1, while
# keeping the pre-install hook annotations intact.
cat > "$CHART_DIR/templates/pre-install-job.yaml" <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-gatekeeper-pre-install
  labels:
    app: gatekeeper
    clusterdrill-question: q110-25-helm-broken-hook-preinstall
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: gatekeeper
        clusterdrill-question: q110-25-helm-broken-hook-preinstall
    spec:
      restartPolicy: Never
      containers:
        - name: pre-install-check
          image: busybox:1.36
          command: ["sh", "-c", "echo ready && exit 0"]
EOF

helm install gate "$CHART_DIR" \
  -n q110-25-helm-broken-hook-preinstall --wait
```
