#!/usr/bin/env bash
# Genuinely reproduces a wedged pending-upgrade release (not a hand-forged
# release Secret): starts a real `helm upgrade` against a chart whose
# slowStart flag injects a long-sleeping initContainer, backgrounds it,
# then kills the helm client mid-wait once the pending-upgrade revision has
# actually been written - the same shape as a CI runner losing its network
# connection mid-upgrade. slowStart only applies to that one triggered
# revision (via --set), so any later, ordinary upgrade against this chart
# is not artificially slow.

set -euo pipefail

QUESTION_ID="q110-55-helm-recover-stuck-pending-upgrade${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CHART_DIR="$SCRIPT_DIR/chart"
rm -rf "$CHART_DIR"
mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<'EOF'
apiVersion: v2
name: stuckapp
description: A minimal chart for CKAD helm pending-upgrade recovery practice
version: 1.0.0
appVersion: "1.0"
EOF

cat > "$CHART_DIR/values.yaml" <<'EOF'
image: nginx:1.25-alpine
slowStart: false
EOF

cat > "$CHART_DIR/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-stuckapp
  labels:
    app: stuckapp
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stuckapp
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: stuckapp
        release: {{ .Release.Name }}
        clusterdrill-question: $QUESTION_ID
    spec:
      {{- if .Values.slowStart }}
      initContainers:
        - name: delay
          image: busybox:1.36
          command: ["sh", "-c", "sleep 300"]
      {{- end }}
      containers:
        - name: stuckapp
          image: "{{ .Values.image }}"
EOF

# Revision 1: install cleanly, wait for it to be healthy.
helm install stuck "$CHART_DIR" -n "$QUESTION_ID" --wait --timeout 60s >/dev/null

# Revision 2: trigger a real upgrade that will hang (slowStart injects a
# 5-minute initContainer sleep), run it in the background, then kill the
# client as soon as Helm has actually written the pending-upgrade release
# record - simulating a dropped connection mid-upgrade rather than faking
# the release Secret by hand.
helm upgrade stuck "$CHART_DIR" -n "$QUESTION_ID" \
  --set image=nginx:1.26-alpine --set slowStart=true \
  --wait --timeout 120s >/dev/null 2>&1 &
UPGRADE_PID=$!

for _ in $(seq 1 50); do
  REV_COUNT="$(helm history stuck -n "$QUESTION_ID" -o json 2>/dev/null | grep -c '"revision":' || true)"
  if [ "${REV_COUNT:-0}" -ge 2 ]; then
    break
  fi
  sleep 0.2
done

kill -9 "$UPGRADE_PID" >/dev/null 2>&1 || true
wait "$UPGRADE_PID" >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready (release 'stuck' wedged in pending-upgrade at revision 2)"
