# q102-23-adapter-container-wrong-command-format: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod legacy-bridge -n q102-23-adapter-container-wrong-command-format --ignore-not-found --wait=true

kubectl apply -n q102-23-adapter-container-wrong-command-format -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: legacy-bridge
  labels:
    clusterdrill-question: q102-23-adapter-container-wrong-command-format
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command:
        - "sh"
        - "-c"
        - |
          i=0
          while true; do
            i=\$((i + 1))
            echo "user\$i|200|/api" >> /data/raw.log
            sleep 5
          done
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
    - name: json-adapter
      image: busybox:1.36
      command:
        - "sh"
        - "-c"
        - |
          touch /data/raw.log
          while true; do
            LINE=\$(tail -n 1 /data/raw.log)
            USERF=\$(echo "\$LINE" | cut -d'|' -f1)
            STATUSF=\$(echo "\$LINE" | cut -d'|' -f2)
            PATHF=\$(echo "\$LINE" | cut -d'|' -f3)
            if [ -n "\$USERF" ]; then
              echo "{\"user\":\"\$USERF\",\"status\":\$STATUSF,\"path\":\"\$PATHF\"}" >> /data/out.json
            fi
            sleep 5
          done
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
  volumes:
    - name: shared-data
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/legacy-bridge -n q102-23-adapter-container-wrong-command-format --timeout=60s
sleep 6
```
