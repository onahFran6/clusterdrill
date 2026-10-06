# q112-19: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/projected-volumes/

```sh
NS=q112-19-projected-volume-everything-in-one-directory

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: bundle
  labels:
    app: bundle
    clusterdrill-question: $NS
spec:
  volumes:
    - name: bundle
      projected:
        sources:
          - configMap:
              name: app-cfg
              items:
                - key: app.yaml
                  path: app.yaml
          - secret:
              name: app-sec
              items:
                - key: token
                  path: secret/token
          - downwardAPI:
              items:
                - path: meta/labels
                  fieldRef:
                    fieldPath: metadata.labels
          - serviceAccountToken:
              path: vault-token
              audience: vault
              expirationSeconds: 3600
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: bundle
          mountPath: /etc/bundle
          readOnly: true
EOF

kubectl wait --for=condition=Ready pod/bundle -n "$NS" --timeout=60s
kubectl exec bundle -n "$NS" -- ls -R /etc/bundle
```

A projected `serviceAccountToken` is short-lived and scoped to exactly one audience, and the
kubelet transparently refreshes it in place well before it expires - this is the same mechanism
behind the default token every Pod gets automounted, just configured explicitly here instead of
left at its defaults.
