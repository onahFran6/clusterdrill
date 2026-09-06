# q110-23: reference solution

Doc: https://helm.sh/docs/helm/helm_lint/

```sh
CHART_DIR="questions/helm-crds/q110-23-helm-lint-fix-chart/chart"

# Fix 1: add the required `version:` field to Chart.yaml.
cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: checkup
description: A minimal chart for CKAD helm lint practice (intentionally broken)
version: 0.1.0
appVersion: "1.0"
EOF

# Fix 2: rename values.yaml's key from `img` to `image` so it matches what
# templates/deployment.yaml already references (.Values.image).
cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
EOF

# Confirm the chart now lints clean.
helm lint "$CHART_DIR"

# Install it into the question namespace as release 'fixed', using the
# chart's own defaults (no --set).
helm install fixed "$CHART_DIR" -n q110-23-helm-lint-fix-chart --wait
```
