#!/usr/bin/env sh
set -eu

KUBE_DIR="${HOME}/.kube"
KUBECONFIG_PATH="${KUBE_DIR}/config"
mkdir -p "$KUBE_DIR" "${HOME}/.clusterdrill/kubeconfigs" "${HOME}/practice-work"

cat >"$KUBECONFIG_PATH" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: in-cluster
  cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    server: https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}
contexts:
- name: in-cluster
  context:
    cluster: in-cluster
    user: clusterdrill
current-context: in-cluster
users:
- name: clusterdrill
  user:
    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
EOF
chmod 0600 "$KUBECONFIG_PATH"
export KUBECONFIG="$KUBECONFIG_PATH"

cd /opt/clusterdrill/web
exec uvicorn app:app --host 0.0.0.0 --port 8000
