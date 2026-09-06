# q101-36-create-secret-tls-imperative: Create a TLS Secret from a cert/key pair

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-36-create-secret-tls-imperative`

`setup.sh` already generated a self-signed certificate and private key at
`~/practice-work/q101-36-create-secret-tls-imperative/tls.crt` and `tls.key`.

In namespace `q101-36-create-secret-tls-imperative`, create a Secret named `web-tls` of type
`kubernetes.io/tls` from that certificate and key, using a single imperative
`kubectl create secret tls` command (no manifest authored by hand).

## Hint

Search kubernetes.io/docs for **"create secret tls"** - the Secrets concept page's TLS Secrets
section shows the `kubectl create secret tls --cert --key` form.
