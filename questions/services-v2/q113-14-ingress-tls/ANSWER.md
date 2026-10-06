# q113-14-ingress-tls: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

```sh
QUESTION_ID=q113-14-ingress-tls
HOST=secure.example.internal

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/q113-14-tls.key -out /tmp/q113-14-tls.crt -subj "/CN=$HOST"

kubectl create secret tls secure-tls -n "$QUESTION_ID" \
  --cert=/tmp/q113-14-tls.crt --key=/tmp/q113-14-tls.key

kubectl create ingress secure -n "$QUESTION_ID" --class=nginx \
  --rule="$HOST/*=secure-svc:80,tls=secure-tls"

rm -f /tmp/q113-14-tls.key /tmp/q113-14-tls.crt
```

`kubectl create secret tls` stores the certificate and key as real `tls.crt`/`tls.key` data -
real enough that `openssl x509 -noout -subject` decodes it and reports the CN you asked for,
regardless of whether any Ingress controller ever reads it. On the Ingress side, `tls=secure-tls`
in the `--rule` flag populates `spec.tls[0]` with that Secret name and the rule's own host. The
host never needs to resolve anywhere; it only has to match what the Secret's certificate was
issued for, which is what a real browser's SNI/certificate check would compare.
