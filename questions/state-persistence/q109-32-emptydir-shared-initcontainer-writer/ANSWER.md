# q109-32-emptydir-shared-initcontainer-writer: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#detailed-behavior

```sh
kubectl apply -n q109-32-emptydir-shared-initcontainer-writer -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: config-fetcher
spec:
  initContainers:
    - name: fetch-config
      image: busybox:1.36
      command: ["sh", "-c", "echo ready > /work/config.txt"]
      volumeMounts:
        - name: work
          mountPath: /work
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: work
          mountPath: /work
  volumes:
    - name: work
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/config-fetcher -n q109-32-emptydir-shared-initcontainer-writer --timeout=60s
```
