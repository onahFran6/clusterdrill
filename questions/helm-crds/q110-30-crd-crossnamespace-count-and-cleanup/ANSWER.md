# q110-30-crd-crossnamespace-count-and-cleanup: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/

```sh
QUESTION_ID="q110-30-crd-crossnamespace-count-and-cleanup"
SECOND_NS="${QUESTION_ID}-b"

# List every EndpointProbe across both namespaces, print "<namespace> <name> <intervalSeconds>",
# and delete any whose intervalSeconds is below the CRD's enforced minimum of 5.
kubectl get endpointprobes.monitoring.clusterdrill.io -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.intervalSeconds}{"\n"}{end}' \
  | while read -r ns name interval; do
      if [ "$interval" -lt 5 ]; then
        kubectl delete endpointprobes.monitoring.clusterdrill.io "$name" -n "$ns"
      fi
    done
```
