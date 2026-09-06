# q106-33-podsecurity-baseline-hostpath-rejected: reference solution

Doc: https://kubernetes.io/docs/concepts/security/pod-security-admission/#pod-security-standards

```sh
kubectl apply -n q106-33-podsecurity-baseline-hostpath-rejected -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-relay
  labels:
    app: log-relay
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "echo hello-from-writer > /var/log/relay/relay.log && sleep 3600"]
      volumeMounts:
        - name: relay-log
          mountPath: /var/log/relay
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: relay-log
          mountPath: /var/log/relay
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: relay-log
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/log-relay -n q106-33-podsecurity-baseline-hostpath-rejected --timeout=60s
```
