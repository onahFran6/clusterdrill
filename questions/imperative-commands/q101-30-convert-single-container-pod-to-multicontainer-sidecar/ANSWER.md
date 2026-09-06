# q101-30-convert-single-container-pod-to-multicontainer-sidecar: reference solution

Doc: https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/

```sh
NS=q101-30-convert-single-container-pod-to-multicontainer-sidecar

# Export the live Pod spec as a starting point for the edit.
kubectl get pod web-writer -n "$NS" -o yaml > /tmp/web-writer.yaml

# Build the new manifest: same name/labels/volumes/'main' container, plus a
# new 'log-shipper' container tailing the shared log file. Writing a fresh
# manifest (rather than hand-editing the exported YAML) guarantees every
# server-owned field (status, uid, resourceVersion, creationTimestamp,
# managedFields, nodeName, serviceAccount defaults, etc.) is stripped.
cat > /tmp/web-writer.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-writer
  labels:
    app: web-writer
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /var/log/app; while true; do echo \"\$(date -u +%Y-%m-%dT%H:%M:%SZ) hello from main\" >> /var/log/app/output.log; sleep 2; done"]
      volumeMounts:
        - name: log-vol
          mountPath: /var/log/app
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: log-shipper
      image: busybox:1.36
      command: ["sh", "-c", "tail -n+1 -F /var/log/app/output.log"]
      volumeMounts:
        - name: log-vol
          mountPath: /var/log/app
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: log-vol
      emptyDir: {}
EOF

# A running Pod's spec.containers list is immutable in place - you cannot
# patch a new container into it. Delete the old Pod, then apply the edited
# manifest under the same name.
kubectl delete pod web-writer -n "$NS" --wait=true
kubectl apply -n "$NS" -f /tmp/web-writer.yaml

kubectl wait --for=condition=Ready pod/web-writer -n "$NS" --timeout=90s
kubectl logs web-writer -c log-shipper -n "$NS"
```
