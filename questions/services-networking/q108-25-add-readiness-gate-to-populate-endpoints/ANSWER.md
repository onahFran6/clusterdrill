# q108-25-add-readiness-gate-to-populate-endpoints: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes

```sh
kubectl patch deployment search-index -n q108-25-add-readiness-gate-to-populate-endpoints -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "search-index",
            "readinessProbe": {
              "httpGet": {
                "path": "/",
                "port": 80
              }
            }
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment/search-index -n q108-25-add-readiness-gate-to-populate-endpoints --timeout=60s

kubectl wait --for=jsonpath='{.subsets[0].addresses[1].ip}' \
  endpoints/search-index-svc -n q108-25-add-readiness-gate-to-populate-endpoints --timeout=60s
```
