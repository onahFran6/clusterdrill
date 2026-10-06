#!/usr/bin/env bash
# Spec-only checks, same rationale as every other Ingress question in this
# bank: this cluster has no Ingress controller installed, so only the final
# object's fields are asserted, never a live HTTP response through one.
set -uo pipefail

QUESTION_ID="q113-12-bluegreen-ingress-preview-host${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'procyon' exists, class nginx, exactly 2 host rules, default backend fallback-svc:80" \
  bash -c "kubectl get ingress procyon -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath='{.spec.ingressClassName}')\" = 'nginx' ] && \
    [ \"\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath='{.spec.rules[*].host}' | wc -w | tr -d ' ')\" = '2' ] && \
    [ \"\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath='{.spec.defaultBackend.service.name}:{.spec.defaultBackend.service.port.number}')\" = 'fallback-svc:80' ]"

check_criterion "the preview.<host> rule still backs onto green-svc:80 (unchanged)" \
  bash -c "
    for i in 0 1; do
      host=\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[\$i].host}\" 2>/dev/null)
      case \"\$host\" in
        preview.*)
          svc=\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[\$i].http.paths[0].backend.service.name}:{.spec.rules[\$i].http.paths[0].backend.service.port.number}\" 2>/dev/null)
          [ \"\$svc\" = 'green-svc:80' ] && exit 0
          ;;
      esac
    done
    exit 1
  "

check_criterion "the main host (whose preview.<host> sibling exists) was cut over to green-svc:80" \
  bash -c "
    h0=\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
    h1=\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath='{.spec.rules[1].host}' 2>/dev/null)
    case \"\$h0\" in preview.*) main_idx=1; main_host=\$h1; preview_host=\$h0 ;; *) main_idx=0; main_host=\$h0; preview_host=\$h1 ;; esac
    [ \"\$preview_host\" = \"preview.\$main_host\" ] || exit 1
    svc=\$(kubectl get ingress procyon -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[\$main_idx].http.paths[0].backend.service.name}:{.spec.rules[\$main_idx].http.paths[0].backend.service.port.number}\" 2>/dev/null)
    [ \"\$svc\" = 'green-svc:80' ]
  "

print_score
