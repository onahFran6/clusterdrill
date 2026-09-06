# q101-49-rollout-restart-stale-secret-values: Fix a Deployment still running on a rotated Secret's old value

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-49-rollout-restart-stale-secret-values`

`setup.sh` already created a Deployment named `billing-sync` (image `busybox:1.36`) whose container
sets environment variable `API_TOKEN` from Secret `billing-creds`'s key `API_TOKEN` via
`valueFrom.secretKeyRef`. After the pod started, the Secret's value was rotated to a new token -
but the already-running pod's `API_TOKEN` environment variable still shows the old one, because an
env var sourced from a Secret is only read once, at container start.

Confirm this yourself (compare `kubectl exec` into the running pod and echoing `$API_TOKEN` against
the Secret's current, base64-decoded value), then fix it with a single imperative
`kubectl rollout restart deployment` command - no manifest edit, no Secret change - so that a new
pod starts and resolves the Secret's current value.

## Hint

Search kubernetes.io/docs for **"kubectl rollout restart"** - the kubectl reference documents
`kubectl rollout restart deployment/<name>`, the standard way to force new pods (and therefore a
fresh read of any Secret/ConfigMap env vars) without changing the Deployment's spec.
