# q111-10: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

```sh
NS=q111-10-three-faults-zero-pods

# Fault 1 (no pods at all - look at the ReplicaSet's own events):
# spec.template.spec.serviceAccountName references "reporter-sa", which
# doesn't exist yet, so the ReplicaSet can't create any pod.
kubectl create serviceaccount reporter-sa -n "$NS"

# Faults 2 and 3 show up on the pods themselves once they can be created:
# envFrom references ConfigMap "reports-config" (typo of report-config),
# and the TOKEN env var's secretKeyRef.key is "TOKEN" (the Secret's real
# key is lowercase "token"). A strategic merge patch on the container's
# envFrom/env fields replaces each list wholesale (no array index to get
# wrong), matched onto the right container by name.
kubectl patch deployment reporter -n "$NS" -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "reporter",
            "envFrom": [
              { "configMapRef": { "name": "report-config" } }
            ],
            "env": [
              {
                "name": "TOKEN",
                "valueFrom": {
                  "secretKeyRef": { "name": "report-secret", "key": "token" }
                }
              }
            ]
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment/reporter -n "$NS" --timeout=60s
```

Missing ServiceAccounts fail at pod **creation** (admission), so the only evidence is on the
ReplicaSet (`kubectl describe rs -l app=reporter`), never on a pod - there isn't one yet. Missing
ConfigMaps and wrong Secret keys fail at container **start**, so the evidence moves to the pod's
own status (`CreateContainerConfigError`) and events. Knowing which layer failed tells you
exactly where to look next.
