# q108-40-service-add-second-selector-key-fix: Narrow a Service selector to exclude a canary Deployment

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-40-service-add-second-selector-key-fix`

`setup.sh` already created two Deployments in namespace
`q108-40-service-add-second-selector-key-fix`, both carrying the label `app: payment-worker`:

- `payment-worker` (pod-template labels `app: payment-worker`, `tier: backend`) - the stable
  release this Service is meant to front
- `payment-worker-canary` (pod-template labels `app: payment-worker`, `tier: canary`) - an
  in-progress canary rollout that must **not** receive traffic through this Service

The Service `payment-worker-svc` currently selects only on `app: payment-worker`, so it is
matching pods from **both** Deployments - the canary pods are getting production traffic they
should not.

Fix the Service's `spec.selector` by adding the missing `tier: backend` requirement (a Service
selector's keys are ANDed together), so it selects only `payment-worker`'s pods and excludes
`payment-worker-canary`'s. Do not change either Deployment.

## Hint

Search kubernetes.io/docs for **"Service" "spec.selector"** - the Service concept page's
selectors section explains that a Service's `selector` may list multiple key-value pairs, all of
which a pod's labels must satisfy to be selected.
