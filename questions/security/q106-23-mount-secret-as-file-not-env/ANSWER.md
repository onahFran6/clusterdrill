# q106-23-mount-secret-as-file-not-env: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

```sh
kubectl apply -n q106-23-mount-secret-as-file-not-env -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cert-reader
  labels:
    clusterdrill-question: q106-23-mount-secret-as-file-not-env
spec:
  containers:
    - name: cert-reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: tls-vol
          mountPath: /etc/tls
          readOnly: true
  volumes:
    - name: tls-vol
      secret:
        secretName: tls-cert
EOF
