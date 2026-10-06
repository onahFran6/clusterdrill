# q116-08-two-hosts-two-certificates: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

```sh
QUESTION_ID="q116-08-two-hosts-two-certificates"

for pair in "alpha a.orbit.local" "beta b.orbit.local"; do
  set -- $pair
  name="$1" host="$2"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "/tmp/q116-08-$name.key" -out "/tmp/q116-08-$name.crt" -subj "/CN=$host"
  kubectl create secret tls "$name-tls" -n "$QUESTION_ID" \
    --cert="/tmp/q116-08-$name.crt" --key="/tmp/q116-08-$name.key"
  rm -f "/tmp/q116-08-$name.key" "/tmp/q116-08-$name.crt"
done

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: orbit
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["a.orbit.local"]
      secretName: alpha-tls
    - hosts: ["b.orbit.local"]
      secretName: beta-tls
  rules:
    - host: a.orbit.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: alpha-svc
                port:
                  number: 80
    - host: b.orbit.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: beta-svc
                port:
                  number: 80
EOF
```
