# q108-40: Narrow a Service selector to exclude a canary Deployment

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-40-service-add-second-selector-key-fix`

Two Deployments already exist in namespace
`q108-40-service-add-second-selector-key-fix`, both carrying the label `app: payment-worker`:

- `payment-worker` (pod-template labels `app: payment-worker`, `tier: backend`) - the stable
  release this Service is meant to front
- `payment-worker-canary` (pod-template labels `app: payment-worker`, `tier: canary`) - a canary
  that must **not** receive traffic through this Service

The Service `payment-worker-svc` currently selects only on `app: payment-worker`, so it matches
pods from both Deployments.

Fix `payment-worker-svc`'s `spec.selector` so it also requires `tier: backend`. It must select
only `payment-worker`'s pods and exclude `payment-worker-canary`. Do not change either Deployment.

## Hint

Search kubernetes.io/docs for **"Service" "spec.selector"** - the Service concept page's
selectors section explains that a Service's `selector` may list multiple key-value pairs, and a
pod must satisfy every pair (they are ANDed) to be selected.
