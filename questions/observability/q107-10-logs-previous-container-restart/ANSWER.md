# q107-10: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs

```sh
CODE_LINE=$(kubectl logs flaky-init -n q107-10-logs-previous-container-restart --previous | grep INIT_FAILURE_CODE=)
CODE_VALUE=${CODE_LINE#INIT_FAILURE_CODE=}

kubectl apply -n q107-10-logs-previous-container-restart -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: recovered-log
  labels:
    clusterdrill-question: q107-10-logs-previous-container-restart
data:
  code: "$CODE_VALUE"
EOF
```
