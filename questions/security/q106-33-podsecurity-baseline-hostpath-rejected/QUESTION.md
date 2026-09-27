# q106-33: Diagnose an admission-rejected hostPath pod under a baseline-enforced namespace, then fix it without loosening the policy

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-33-podsecurity-baseline-hostpath-rejected`

A deploy script reported that it created pod `log-relay` in namespace
`q106-33-podsecurity-baseline-hostpath-rejected`, but the namespace has no pods. The namespace
enforces the `baseline` Pod Security Standard
(`pod-security.kubernetes.io/enforce: baseline`).

Recreate a pod named `log-relay` that:

- is labeled `app: log-relay`
- runs two containers that share one volume mounted at `/var/log/relay` in both:
  - container `writer`, image `busybox:1.36`, which writes the exact line
    `hello-from-writer` to `/var/log/relay/relay.log` and then keeps running
  - container `reader`, image `busybox:1.36`, which keeps running so it can be inspected
- uses a volume type the `baseline` standard allows
- reaches `Running` with both containers Ready, and `/var/log/relay/relay.log` inside container
  `reader` contains exactly `hello-from-writer`

Do not change the namespace's `pod-security.kubernetes.io/enforce` label. It must still be
`baseline`.

## Hint

Search kubernetes.io/docs for **"Pod Security Standards baseline restricted policies"** - the
baseline policy table lists which volume types are disallowed. The rejected pod was never
admitted (it is not simply unhealthy). The Volumes concept page shows a volume type that can
share a file between containers in one pod. `kubectl get pods` in this namespace stays empty
until a compliant pod is accepted.
