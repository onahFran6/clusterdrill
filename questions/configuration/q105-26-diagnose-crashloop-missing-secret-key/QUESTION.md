# q105-26-diagnose-crashloop-missing-secret-key: Diagnose a CrashLoopBackOff caused by a renamed Secret key

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-26-diagnose-crashloop-missing-secret-key`

`setup.sh` already created, in namespace `q105-26-diagnose-crashloop-missing-secret-key`, a
Secret named `api-secret` with a single key `API_TOKEN`, and a Deployment named `gateway` (1
replica) whose container sources an environment variable `API_TOKEN` from that Secret via
`secretKeyRef`. The Deployment's pod never becomes ready.

Investigate why the `gateway` Deployment is stuck (`kubectl describe pod` and its Events are a
good place to start), identify the root cause, and fix it so that:

- Secret `api-secret` still has exactly one key, `API_TOKEN`, with its original value unchanged
  (do not rename or duplicate the key inside the Secret).
- Deployment `gateway` reaches `1/1` ready replicas.
- Inside the running pod, the container's environment variable equals the exact value stored in
  `api-secret`'s `API_TOKEN` key.

Fix this by editing the Deployment's container `env` entry so its `secretKeyRef.key` points at
the Secret's real key name.

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError"** and separately for **"define
container environment variables using secret data"** - the Debug Pods page explains how to read
Pod Events for a config error, and the Secrets task page shows the exact `secretKeyRef` shape a
container's `env` entry needs.
