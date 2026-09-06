# q109-35-pod-mounts-pvc-and-emptydir-together: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/

```sh
kubectl apply -n q109-35-pod-mounts-pvc-and-emptydir-together -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-builder
spec:
  containers:
    - name: report-builder
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data-claim
    - name: scratch
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/report-builder -n q109-35-pod-mounts-pvc-and-emptydir-together --timeout=60s
```
