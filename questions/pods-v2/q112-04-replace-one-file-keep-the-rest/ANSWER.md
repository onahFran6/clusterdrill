# q112-04: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath

```sh
NS=q112-04-replace-one-file-keep-the-rest

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: site
      configMap:
        name: site
  containers:
    - name: web
      image: nginx:1.27
      volumeMounts:
        - name: site
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        - name: site
          mountPath: /usr/share/nginx/html/healthz
          subPath: health.html
EOF

kubectl wait --for=condition=Ready pod/web -n "$NS" --timeout=60s
```

Mounting the whole `site` volume straight onto `/usr/share/nginx/html` would hide every file the
nginx image already has there, including `50x.html`. Two `subPath` mounts, one per file, replace
only the two named files and leave the rest of the directory untouched. The trade-off: a
`subPath` mount never picks up later ConfigMap updates - a whole-directory mount would, after a
short delay, at the cost of hiding the directory's other files.
