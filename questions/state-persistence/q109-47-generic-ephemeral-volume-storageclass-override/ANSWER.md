# q109-47-generic-ephemeral-volume-storageclass-override: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes

```sh
kubectl apply -n q109-47-generic-ephemeral-volume-storageclass-override -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: benchmark-runner
spec:
  containers:
    - name: benchmark-runner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      ephemeral:
        volumeClaimTemplate:
          spec:
            accessModes:
              - ReadWriteOnce
            storageClassName: fast-scratch
            resources:
              requests:
                storage: 256Mi
EOF

kubectl wait --for=condition=Ready pod/benchmark-runner -n q109-47-generic-ephemeral-volume-storageclass-override --timeout=60s
```
