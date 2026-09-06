# q107-09: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs

```sh
TOKEN_LINE=$(kubectl logs order-pipeline -c consumer -n q107-09-multicontainer-logs-dash-c | grep CONSUMER_TOKEN=)
TOKEN_VALUE=${TOKEN_LINE#CONSUMER_TOKEN=}

kubectl apply -n q107-09-multicontainer-logs-dash-c -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: found-token
  labels:
    clusterdrill-question: q107-09-multicontainer-logs-dash-c
data:
  token: "$TOKEN_VALUE"
EOF
```
