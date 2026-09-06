# q105-06: Mount a TLS Secret's certificate and key into a container

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-06-secret-tls-volume-mount`

`setup.sh` already generated a self-signed certificate/key pair at
`$HOME/practice-work/q105-06-secret-tls-volume-mount/q105-06-tls.crt` and `q105-06-tls.key`
(this question's terminal working directory - shown above the terminal panel), and created a
running pod named `edge-proxy` (image `nginx:1.25-alpine`) in namespace
`q105-06-secret-tls-volume-mount`.

Create a Secret named `edge-tls` of the TLS credential type from that certificate/key pair.

Then edit the pod so its container mounts `edge-tls` as a **read-only** volume at
`/etc/nginx/tls`, so the certificate and key appear inside the container as
`/etc/nginx/tls/tls.crt` and `/etc/nginx/tls/tls.key`. The pod will need to be recreated for the
mount to take effect.

## Hint

Search kubernetes.io/docs for **"create secret tls"** - the TLS Secrets concept page covers
creating a TLS-type Secret from a cert/key pair and mounting it into a pod as a volume.
