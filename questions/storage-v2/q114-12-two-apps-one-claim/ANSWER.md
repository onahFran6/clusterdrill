# q114-12: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath

```sh
NS=q114-12-two-apps-one-claim

deploy() {
  local name="$1"
  cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  labels:
    clusterdrill-question: $NS
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
        clusterdrill-question: $NS
    spec:
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared
      containers:
        - name: $name
          image: busybox:1.36
          command: ["sh", "-c", "echo -n $name > /data/owner; sleep 3600"]
          volumeMounts:
            - name: shared
              mountPath: /data
              subPath: $name
EOF
}

deploy api
deploy worker
kubectl rollout status deployment/api -n "$NS" --timeout=60s
kubectl rollout status deployment/worker -n "$NS" --timeout=60s

kubectl run inspect -n "$NS" --image=busybox:1.36 --restart=Never --rm -i \
  --overrides='{"spec":{"volumes":[{"name":"s","persistentVolumeClaim":{"claimName":"shared"}}],"containers":[{"name":"i","image":"busybox:1.36","command":["ls","/all"],"volumeMounts":[{"name":"s","mountPath":"/all"}]}]}}' \
  -- true
```

The kubelet creates a missing `subPath` directory on demand. This is isolation by convention, not
security - any Pod mounting the claim's root (like the `inspect` probe above) sees everything.
Sharing a claim across multiple nodes instead of folders on one node would need a
`ReadWriteMany`-capable class such as NFS.
