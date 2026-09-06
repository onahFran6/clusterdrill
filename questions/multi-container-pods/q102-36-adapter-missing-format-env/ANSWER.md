# q102-36: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

```sh
kubectl delete pod format-adapter -n q102-36-adapter-missing-format-env --ignore-not-found --wait=true

kubectl apply -n q102-36-adapter-missing-format-env -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: format-adapter
  labels:
    clusterdrill-question: q102-36-adapter-missing-format-env
spec:
  containers:
    - name: source
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; echo 'sensor-7,42.5' > /data/raw.csv; while true; do sleep 3600; done"]
      volumeMounts:
        - name: shared
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: adapter
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          i=0
          while [ $i -lt 60 ]; do
            if [ -f /data/raw.csv ]; then
              line="$(cat /data/raw.csv)"
              if [ "$SOURCE_FORMAT" = "csv" ]; then
                name="${line%%,*}"
                value="${line##*,}"
                printf '{"name":"%s","value":%s}\n' "$name" "$value" > /data/out.json
              else
                echo "$line" > /data/out.json
              fi
            fi
            i=$((i+1))
            sleep 3
          done
          while true; do sleep 3600; done
      env:
        - name: SOURCE_FORMAT
          value: csv
      volumeMounts:
        - name: shared
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: shared
      emptyDir: {}
EOF
```
