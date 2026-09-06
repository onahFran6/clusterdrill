# q102-14: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

```sh
kubectl apply -n q102-14-sidecar-distinct-resources -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: resource-aware-app
  labels:
    clusterdrill-question: q102-14-sidecar-distinct-resources
spec:
  containers:
    - name: main
      image: nginx:1.27-alpine
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 250m
          memory: 128Mi
    - name: metrics-sidecar
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
EOF
```
