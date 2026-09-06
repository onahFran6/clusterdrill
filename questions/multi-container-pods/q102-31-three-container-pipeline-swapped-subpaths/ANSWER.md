# q102-31: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath

```sh
kubectl delete pod pipeline-stages -n q102-31-three-container-pipeline-swapped-subpaths --ignore-not-found --wait=true

kubectl apply -n q102-31-three-container-pipeline-swapped-subpaths -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pipeline-stages
  labels:
    clusterdrill-question: q102-31-three-container-pipeline-swapped-subpaths
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command: ["sh", "-c", "echo batch-payload-4471 > /data/payload.txt; while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /data
          subPath: stage1
    - name: transformer
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while [ \$i -lt 60 ]; do if [ -f /in/payload.txt ] && [ ! -f /out/payload.txt ]; then printf 'TRANSFORMED:' > /out/payload.txt; cat /in/payload.txt >> /out/payload.txt; fi; i=\$((i+1)); sleep 3; done; while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /in
          subPath: stage1
        - name: pipeline-data
          mountPath: /out
          subPath: stage2
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /final
          subPath: stage2
  volumes:
    - name: pipeline-data
      emptyDir: {}
EOF
```
