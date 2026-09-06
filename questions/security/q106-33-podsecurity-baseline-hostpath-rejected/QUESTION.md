# q106-33: Diagnose an admission-rejected hostPath pod under a baseline-enforced namespace, then fix it without loosening the policy

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-33-podsecurity-baseline-hostpath-rejected`

A deploy script tried to create pod `log-relay` in namespace
`q106-33-podsecurity-baseline-hostpath-rejected` and reported success, but nobody can find the
pod. `kubectl get pods` in this namespace shows nothing at all - not `CrashLoopBackOff`, not
`Pending`, nothing. The namespace enforces the `baseline` Pod Security Standard
(`pod-security.kubernetes.io/enforce: baseline`).

Investigate and fix this:

1. Figure out why pod `log-relay` does not exist at all. This is different from a pod that
   exists but is unhealthy - determine whether it was ever admitted by the API server in the
   first place, and if not, why the `baseline` Pod Security Standard rejected it.
2. Recreate a pod named `log-relay` in this namespace that:
   - is labeled `app: log-relay`
   - runs two containers sharing one volume mounted at `/var/log/relay` in both containers:
     - container `writer`, image `busybox:1.36`, which writes the exact line
       `hello-from-writer` to `/var/log/relay/relay.log` and then keeps running
     - container `reader`, image `busybox:1.36`, which keeps running so it can be inspected
       (its own command does not need to read the file itself - grading reads the file directly)
   - uses a volume type that complies with the `baseline` Pod Security Standard (the rejected
     attempt used a volume type `baseline` forbids)
   - reaches `Running` with both containers Ready, and `/var/log/relay/relay.log` inside
     container `reader` contains exactly `hello-from-writer`
3. Do **not** change the namespace's `pod-security.kubernetes.io/enforce` label to admit the
   original pod as-is. The namespace must remain enforcing `baseline` when you're done - fix the
   pod's volume, not the namespace's policy.

## Hint

Search kubernetes.io/docs for **"Pod Security Standards baseline restricted policies"** - the
Pod Security Admission page's baseline policy table lists exactly which volume types are
disallowed, and the Volumes concept page has a copy-paste example of the compliant alternative
for sharing files between containers in one pod.
