# q108-21-clusterip-to-nodeport-type-change: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

```sh
kubectl patch service catalog-api-svc -n q108-21-clusterip-to-nodeport-type-change -p '
{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "port": 5678,
        "targetPort": 5678,
        "nodePort": 30081
      }
    ]
  }
}'
```
