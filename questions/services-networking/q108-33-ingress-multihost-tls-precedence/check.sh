#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-33-ingress-multihost-tls-precedence${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# --- Criterion 1: declarative spec.tls mapping ------------------------------
# setup.sh's bug is that spec.tls's second entry (api.shop.example.local)
# still names shop-web-tls, copy-pasted from the first entry. This is FALSE
# on the unsolved state and only becomes TRUE once the candidate repoints it
# at shop-api-tls (without touching the already-correct first entry or
# spec.rules, which this check never asserts on since setup.sh never breaks
# them).
check_criterion "Ingress 'shop-ingress' spec.tls maps shop.example.local->shop-web-tls and api.shop.example.local->shop-api-tls" \
  bash -c "
    tls_map=\$(kubectl get ingress shop-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.tls[*]}{.hosts[0]}:{.secretName}{\"\n\"}{end}' 2>/dev/null)
    echo \"\$tls_map\" | grep -qx 'shop.example.local:shop-web-tls' && \
    echo \"\$tls_map\" | grep -qx 'api.shop.example.local:shop-api-tls'
  "

# --- Criterion 2: functional - actual TLS handshake + backend response -----
# Proves the fix is real, not just a field edit: a curl pod inside the
# cluster hits the ingress-nginx controller Service directly (ClusterIP,
# --resolve for SNI, matching this bank's other in-cluster-curl functional
# checks) for both hosts over HTTPS, and requires BOTH the served
# certificate's subject to match that host AND the response body to come
# from the correct backend. Bundled as one AND across both hosts so this is
# FALSE on the unsolved state (api.shop.example.local gets ingress-nginx's
# fallback default cert, not shop-api-tls) and only becomes TRUE once both
# hosts serve their own matching certificate. Retries internally since an
# Ingress/Secret change needs a few seconds to reach ingress-nginx's config.
check_criterion "Both hosts serve their own matching TLS certificate and route to their correct backend" \
  bash -c "
    INGRESS_IP=\$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    if [ -z \"\$INGRESS_IP\" ]; then
      INGRESS_IP=\$(kubectl get svc -A -l app.kubernetes.io/component=controller,app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null)
    fi
    [ -n \"\$INGRESS_IP\" ] || exit 1

    pod=\"tls-precedence-check-$\$\"
    kubectl run \"\$pod\" --image=curlimages/curl:8.10.1 --restart=Never \
      -n '$QUESTION_ID' --labels='clusterdrill-question=$QUESTION_ID' \
      --env=\"INGRESS_IP=\$INGRESS_IP\" --command --quiet -- sh -c '
        i=0
        success=0
        while [ \$i -lt 15 ]; do
          api_out=\$(curl -sk -v --resolve api.shop.example.local:443:\$INGRESS_IP https://api.shop.example.local/ -o /tmp/api_body 2>&1)
          web_out=\$(curl -sk -v --resolve shop.example.local:443:\$INGRESS_IP https://shop.example.local/ -o /tmp/web_body 2>&1)
          api_body=\$(cat /tmp/api_body 2>/dev/null)
          web_body=\$(cat /tmp/web_body 2>/dev/null)
          if echo \"\$api_out\" | grep -q \"subject:.*CN=api.shop.example.local\" \\
             && ! echo \"\$api_out\" | grep -q \"Fake Certificate\" \\
             && [ \"\$api_body\" = \"shop-api-ok\" ] \\
             && echo \"\$web_out\" | grep -q \"subject:.*CN=shop.example.local\" \\
             && [ \"\$web_body\" = \"shop-web-ok\" ]; then
            success=1
            break
          fi
          i=\$((i+1))
          sleep 2
        done
        echo \"RESULT:\$success\"
      ' >/dev/null 2>&1

    kubectl wait --for=jsonpath='{.status.phase}'=Succeeded \"pod/\$pod\" -n '$QUESTION_ID' --timeout=90s >/dev/null 2>&1
    result=\$(kubectl logs \"pod/\$pod\" -n '$QUESTION_ID' 2>/dev/null | grep -o 'RESULT:[01]')
    kubectl delete pod \"\$pod\" -n '$QUESTION_ID' --ignore-not-found --wait=false >/dev/null 2>&1

    [ \"\$result\" = 'RESULT:1' ]
  "

print_score
