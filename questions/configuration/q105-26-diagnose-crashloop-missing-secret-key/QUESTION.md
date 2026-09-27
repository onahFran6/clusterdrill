# q105-26: Diagnose a CrashLoopBackOff caused by a Secret key mismatch

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-26-diagnose-crashloop-missing-secret-key`

In namespace `q105-26-diagnose-crashloop-missing-secret-key` you'll find a Secret named
`api-secret` with a single key `API_TOKEN`, and a Deployment named `gateway` (1 replica) whose
container is supposed to get an environment variable `API_TOKEN` from that Secret. The
Deployment's pod never becomes ready.

Investigate why `gateway` is stuck (`kubectl describe pod` and its Events are a good place to
start), then fix it so that:

- Secret `api-secret` still has exactly one key, `API_TOKEN`, with its original value unchanged
  (do not rename or duplicate the key inside the Secret).
- Deployment `gateway` reaches `1/1` ready replicas.
- Inside the running pod, the container's `API_TOKEN` environment variable equals the exact value
  stored in `api-secret`'s `API_TOKEN` key.

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError"** and separately for **"define
container environment variables using secret data"** - the Debug Pods page explains how to read
Pod Events for a config error, and the Secrets task page shows the exact `secretKeyRef` shape a
container's `env` entry needs.
