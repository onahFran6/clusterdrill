# q116-09: A 503 with two causes

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-09-a-503-with-two-causes`
(plus a second namespace, `q116-09-a-503-with-two-causes-wrong`)

This namespace runs the real app: Deployment `web` (label `app: web`) and Service `web-svc`
(port `80`). Ingress `eclipse` (host `eclipse.local`), routing to `web-svc`, was mistakenly
created in the other namespace, `q116-09-a-503-with-two-causes-wrong`, instead of here.
Requests through `eclipse.local` return `503`.

- Make the app reachable through `eclipse.local`. Don't change Deployment `web`. You may move or
  recreate the Ingress, and fix whatever else is wrong.
- (ungraded, Task narrative only) Write down each cause you find, in the order you find it.

## Hint

Search kubernetes.io/docs for **"Ingress"** and **"Service"** - an Ingress backend has no
namespace field, so it can only route to Services in its own namespace. `kubectl describe
ingress` shows each backend with its live endpoint count or an error. If moving the Ingress alone
still doesn't fix it, look one level down: does the Service actually have endpoints?
