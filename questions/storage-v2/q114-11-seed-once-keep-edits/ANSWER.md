# q114-11: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#using-configmaps

```sh
NS=q114-11-seed-once-keep-edits

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: site-content
  labels:
    clusterdrill-question: $NS
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: site
  labels:
    clusterdrill-question: $NS
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: site
  template:
    metadata:
      labels:
        app: site
        clusterdrill-question: $NS
    spec:
      volumes:
        - name: content
          persistentVolumeClaim:
            claimName: site-content
        - name: seed
          configMap:
            name: site-seed
      initContainers:
        - name: seed
          image: busybox:1.36
          command: ["sh", "-c", "[ -f /content/index.html ] || cp /seed/index.html /content/index.html"]
          volumeMounts:
            - { name: content, mountPath: /content }
            - { name: seed, mountPath: /seed, readOnly: true }
      containers:
        - name: nginx
          image: nginx:1.27
          volumeMounts:
            - { name: content, mountPath: /usr/share/nginx/html }
EOF

kubectl rollout status deployment/site -n "$NS" --timeout=60s
kubectl exec deploy/site -n "$NS" -- curl -s localhost   # seeded from configmap (not graded)

kubectl exec deploy/site -n "$NS" -- sh -c 'echo -n "edited by hand" > /usr/share/nginx/html/index.html'
kubectl delete pod -n "$NS" -l app=site
kubectl rollout status deployment/site -n "$NS" --timeout=60s
sleep 2
kubectl exec deploy/site -n "$NS" -- curl -s localhost   # edited by hand
```

A ConfigMap volume is read-only and rebuilt straight from the API, so edits made from inside the
Pod are impossible there. Copying it into a claim once gives editors something persistent they
can actually change. `Recreate` avoids two pods racing for the same `ReadWriteOnce` claim on a
multi-node cluster.
