# q105-04: Inject a single Secret key as one environment variable

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-04-secret-generic-env-var`

`setup.sh` already created a running pod named `billing-app` (image `nginx:1.25-alpine`) in
namespace `q105-04-secret-generic-env-var`.

Create a generic Secret named `billing-secret` with one key, `DB_PASSWORD`, set to the value
`s3cr3t-pass`.

Then edit the pod so its container gets **one environment variable**, `DATABASE_PASSWORD`,
whose value is sourced from that Secret's `DB_PASSWORD` key - the environment variable name and
the Secret key name are deliberately different, so a bulk `envFrom` import will not produce the
right variable name here. The pod will need to be recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"secretKeyRef"** - the Distribute Credentials Securely task shows
how to map one Secret key to a single named environment variable using `valueFrom.secretKeyRef`.
