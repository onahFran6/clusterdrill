# q106-27-diagnose-conflicting-podsecurity-and-networkpolicy: Diagnose a pod stuck Pending due to conflicting SecurityContext and namespace PodSecurity label, then fix connectivity

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-27-diagnose-conflicting-podsecurity-and-networkpolicy`

In namespace `q106-27-diagnose-conflicting-podsecurity-and-networkpolicy`, pod `worker` is not
present, and Service `worker-svc` has no endpoints. The namespace enforces the `restricted` Pod
Security Standard, and a default-deny NetworkPolicy is already in place.

Recreate a pod named `worker` that:

- is labeled `app: worker`
- runs container `worker` on image `nginxinc/nginx-unprivileged:1.25-alpine`, listening on
  container port `8080`
- complies with `restricted`: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
  capabilities `drop: ["ALL"]`, and `seccompProfile.type: RuntimeDefault`
- reaches the `Running` phase

Service `worker-svc` already selects `app=worker` on port `8080`. Once the pod is Running with
that label, its endpoints should populate on their own.

Also allow ingress to `worker` on TCP port `8080` from pods labeled `role: client`. Do not open
ingress to anything else. You may add a new NetworkPolicy or edit the existing one.

## Hint

Search kubernetes.io/docs for **"enforce Pod Security Standards with namespace labels"** and
separately for **"network policy allow traffic from pods in another namespace"**. Pod `worker`
was never admitted, which is different from an existing pod that is unhealthy. The Pod Security
Admission page lists the `securityContext` fields `restricted` requires. The NetworkPolicy
concept page shows allowing ingress from pods that match a label selector.
