# q112-09: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#pod-update-and-replacement

```sh
NS=q112-09-add-sidecars-to-running-pod

kubectl replace --force -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: legacy
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: logs
      emptyDir: {}
  containers:
    - name: app
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          mkdir -p /var/log/legacy
          i=0
          while true; do
            i=\$((i+1))
            echo "GET /item/\$i 200" >> /var/log/legacy/access.log
            [ \$((i % 3)) -eq 0 ] && echo "ERR timeout on item \$i" >> /var/log/legacy/error.log
            sleep 2
          done
      volumeMounts:
        - name: logs
          mountPath: /var/log/legacy
    - name: access-tail
      image: busybox:1.36
      command: ["sh", "-c", "tail -F /var/log/legacy/access.log"]
      volumeMounts:
        - name: logs
          mountPath: /var/log/legacy
    - name: error-tail
      image: busybox:1.36
      command: ["sh", "-c", "tail -F /var/log/legacy/error.log"]
      volumeMounts:
        - name: logs
          mountPath: /var/log/legacy
EOF

kubectl wait --for=condition=Ready pod/legacy -n "$NS" --timeout=60s
sleep 10
kubectl logs legacy -c error-tail -n "$NS" --tail=2
```

Containers and volumes cannot be added to a live Pod - `kubectl edit` on an in-place field other
than `spec.containers[*].image` (and a short allowlist of others) fails with
`pod updates may not change fields other than ...`. `kubectl replace --force` deletes and
recreates the Pod under the same name instead, which is why the full spec - including the parts
that did not change - has to be written out in one shot here rather than patched in piece by
piece.
