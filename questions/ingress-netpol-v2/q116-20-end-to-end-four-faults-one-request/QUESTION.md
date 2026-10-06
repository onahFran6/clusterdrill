# q116-20: End to end, four faults, one request

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-20-end-to-end-four-faults-one-request`
(plus a second namespace, `q116-20-end-to-end-four-faults-one-request-data`, belonging to another
team - never edit its NetworkPolicy)

Pod `web` (label `app: web`, listening on container port `8080`) and Service `web-svc` (port
`80` → target port `8080`) are published at `carina.local` through Ingress `carina`. `web` also
calls `quotes-svc` in the other namespace. Neither path works yet.

- Make `carina.local` return the app's response, and make `web` able to reach
  `quotes-svc.q116-20-end-to-end-four-faults-one-request-data`. You may change anything in this
  namespace, including its own labels. **Never edit** the other namespace's NetworkPolicy,
  `quotes-from-carina`.
- (ungraded, Task narrative only) Write down each fault, with the symptom it caused, in the order
  you found it.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** and **"Ingress"** - fix one path at a time and
read each symptom: a `503` and a `504` from the controller point to different layers. For the
outbound call, a resolver failure and a connection timeout point to different missing allowances.
Read the other namespace's policy (without editing it) to see what it actually expects from
*your* namespace.
