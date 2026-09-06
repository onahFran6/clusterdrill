# q106-27-diagnose-conflicting-podsecurity-and-networkpolicy: reference solution

Doc: https://kubernetes.io/docs/concepts/security/pod-security-admission/

```sh
kubectl apply -n q106-27-diagnose-conflicting-podsecurity-and-networkpolicy -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: worker
      image: nginxinc/nginx-unprivileged:1.25-alpine
      ports:
        - containerPort: 8080
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
EOF

kubectl wait --for=condition=Ready pod/worker -n q106-27-diagnose-conflicting-podsecurity-and-networkpolicy --timeout=60s

kubectl apply -n q106-27-diagnose-conflicting-podsecurity-and-networkpolicy -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: worker-allow-client-ingress
spec:
  podSelector:
    matchLabels:
      app: worker
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: client
      ports:
        - protocol: TCP
          port: 8080
EOF
```
