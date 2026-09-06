# q108-17: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl patch networkpolicy admin-panel-ingress -n q108-17-networkpolicy-restrict-port --type json -p '
[
  {
    "op": "add",
    "path": "/spec/ingress/0/ports",
    "value": [
      { "protocol": "TCP", "port": 8443 }
    ]
  }
]'
```
