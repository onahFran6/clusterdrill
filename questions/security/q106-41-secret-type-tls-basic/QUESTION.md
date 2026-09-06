# q106-41: Create a TLS Secret from a self-signed certificate

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-41-secret-type-tls-basic`

Generate a self-signed TLS certificate and private key, then create a Secret named `site-tls` in
this namespace of type `kubernetes.io/tls` from that certificate/key pair.

## Hint

Search kubernetes.io/docs for **"TLS secrets"** - the Secrets concept page shows the
`kubectl create secret tls` command, which takes `--cert` and `--key` file paths and sets the
Secret's type automatically.
