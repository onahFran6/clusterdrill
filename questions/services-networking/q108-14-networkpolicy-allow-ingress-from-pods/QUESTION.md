# q108-14: Allow ingress only from a specific pod label

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-14-networkpolicy-allow-ingress-from-pods`

`setup.sh` already created two Deployments in namespace
`q108-14-networkpolicy-allow-ingress-from-pods`:

- `payments-api` (pod-template label `app=payments-api`, container port `8080`) - the service to
  protect
- `web-frontend` (pod-template label `app=web-frontend`) - the only client that should be allowed
  to reach it

Create a NetworkPolicy named `payments-api-allow-frontend` in this namespace that:

- applies to pods matching `app=payments-api` (this is the policy's `podSelector`)
- allows **ingress** traffic only from pods matching `app=web-frontend`
- restricts the allowed traffic to TCP port `8080`

Traffic from any other pod (or from outside the allowed source) to `payments-api` should not match
this policy's ingress rule.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the NetworkPolicy concept page's
example manifest shows an `ingress[].from[].podSelector` combined with an `ingress[].ports` entry,
which together scope both *who* can connect and *which port* they can reach.
