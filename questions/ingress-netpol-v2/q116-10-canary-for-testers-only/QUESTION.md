# q116-10: Canary for testers only

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-10-canary-for-testers-only`

Ingress `comet` (host `comet.local`) already routes to `stable-svc`. Services `stable-svc` and
`canary-svc` (both port `80`, with their matching Deployments) already exist. QA wants to reach
the new version, `canary-svc`, on demand, while normal users never see it.

- Create Ingress `comet-canary`, same host and path as `comet`, so that requests carrying header
  `X-Canary: always` go to `canary-svc`, and every other request - including `X-Canary: never` -
  keeps going to stable. Use the ingress-nginx annotations `canary=true` and
  `canary-by-header=X-Canary`.
- (ungraded, Task narrative only) Predict, then record, the responses for no header,
  `X-Canary: always`, and `X-Canary: never`.

## Hint

Search kubernetes.io/docs for **"ingress-nginx annotations canary"** on the ingress-nginx
project's own docs site - a canary needs a *second* Ingress sharing the first one's host and
path, marked with `canary: "true"`. Besides `canary-weight`, there's a header-based annotation -
which values does it treat specially?
