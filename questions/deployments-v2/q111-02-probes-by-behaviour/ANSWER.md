# q111-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl patch deployment catalog -n q111-02-probes-by-behaviour --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
      "httpGet": { "path": "/", "port": 80 },
      "initialDelaySeconds": 5,
      "periodSeconds": 5
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
      "tcpSocket": { "port": 80 },
      "periodSeconds": 10,
      "failureThreshold": 3
    }
  }
]'

kubectl rollout status deployment/catalog -n q111-02-probes-by-behaviour --timeout=60s
```

The readiness probe gates Service traffic: a pod that never turns Ready never receives requests
and (once this Deployment later rolls out again) stops the rollout while old pods keep serving.
The liveness probe gates container restarts: 3 failures x 10s period = ~30 seconds of a closed
port before kubelet kills and restarts the container. Adding either probe changes the pod
template, so both trigger one rolling update together.
