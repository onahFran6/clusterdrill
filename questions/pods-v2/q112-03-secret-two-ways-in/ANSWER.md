# q112-03: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#projection-of-secret-keys-to-specific-paths

```sh
NS=q112-03-secret-two-ways-in

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: db-client
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: creds
      secret:
        secretName: db-creds
        defaultMode: 0400
        items:
          - key: password
            path: pass.txt
  containers:
    - name: db-client
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: user
      volumeMounts:
        - name: creds
          mountPath: /etc/db
          readOnly: true
EOF

kubectl wait --for=condition=Ready pod/db-client -n "$NS" --timeout=60s
```

With a Secret volume's `items` list, keys you don't list never appear in the volume at all - that
is how `user` stays out of `/etc/db` while only `password` lands there. `secretKeyRef` under
`env` picks exactly one key for one env var; `envFrom`/`secretRef` would instead import every key
in the Secret, leaking `password` as an env var too.
