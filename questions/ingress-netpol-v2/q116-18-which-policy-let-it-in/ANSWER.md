# q116-18-which-policy-let-it-in: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-two-sorts-of-pod-isolation

```sh
QUESTION_ID="q116-18-which-policy-let-it-in"

kubectl describe networkpolicy db-debug -n "$QUESTION_ID"
# "Allowing ingress traffic: To Port: <any> From: <any source>" - a single
# empty rule under `ingress: [{}]` means allow everything, unlike
# `ingress: []` or no `ingress` key at all, which means allow nothing.

kubectl delete networkpolicy db-debug -n "$QUESTION_ID"
```
