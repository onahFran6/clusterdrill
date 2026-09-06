# q102-44: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#secret-files-permissions

```sh
kubectl delete pod cert-staging-app -n q102-44-init-container-secret-defaultmode-too-restrictive --ignore-not-found --wait=true

kubectl apply -n q102-44-init-container-secret-defaultmode-too-restrictive -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cert-staging-app
  labels:
    clusterdrill-question: q102-44-init-container-secret-defaultmode-too-restrictive
spec:
  initContainers:
    - name: cert-loader
      image: busybox:1.36
      securityContext:
        runAsUser: 1000
      command: ["sh", "-c", "cp /secret-in/tls.key /handoff/tls.key 2>/dev/null; echo staged"]
      volumeMounts:
        - name: cert
          mountPath: /secret-in
          readOnly: true
        - name: handoff
          mountPath: /handoff
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: handoff
          mountPath: /handoff
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: cert
      secret:
        secretName: tls-cert
        defaultMode: 0444
    - name: handoff
      emptyDir: {}
EOF
```
