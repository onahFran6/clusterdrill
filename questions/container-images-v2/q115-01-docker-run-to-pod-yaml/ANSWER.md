# q115-01: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
and https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

```sh
NS=q115-01-docker-run-to-pod-yaml

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: cache
  labels:
    clusterdrill-question: $NS
spec:
  restartPolicy: Always                        # --restart unless-stopped
  securityContext:
    runAsUser: 101                              # --user 101
  volumes:
    - name: cache-data
      emptyDir: {}                              # -v cache-data:/data (pod-lifetime storage)
  containers:
    - name: cache
      image: nginxinc/nginx-unprivileged:1.27-alpine
      env:                                      # -e
        - name: MODE
          value: fast
        - name: MAX_ITEMS
          value: "64"
      ports:
        - containerPort: 8080                   # the container side of -p 9090:8080
      resources:
        limits:
          cpu: 500m                             # --cpus 0.5
          memory: 128Mi                          # --memory 128m
      volumeMounts:
        - name: cache-data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/cache -n "$NS" --timeout=60s
kubectl exec cache -n "$NS" -- sh -c 'id; printenv MODE MAX_ITEMS'

# (ungraded) reach it from your own machine without a Service:
kubectl port-forward pod/cache 9090:8080 -n "$NS" >/dev/null 2>&1 &
sleep 2; curl -s localhost:9090 >/dev/null; kill %1
```

Env values must be strings, so `"64"` needs quotes - an unquoted `64` fails Pod schema
validation. `docker run -p` publishes on the host; in Kubernetes `containerPort` is purely
informational and exposure is a Service's job, which is why reaching the Pod from outside needs
`kubectl port-forward` instead. A named Docker volume persists across container recreation; the
closest Pod-native equivalent that still dies with the Pod is `emptyDir`, which is what "pod-lifetime
storage" means here.
