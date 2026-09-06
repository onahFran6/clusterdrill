# q106-27-diagnose-conflicting-podsecurity-and-networkpolicy: Diagnose a pod stuck Pending due to conflicting SecurityContext and namespace PodSecurity label, then fix connectivity

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-27-diagnose-conflicting-podsecurity-and-networkpolicy`

A teammate says pod `worker` in namespace `q106-27-diagnose-conflicting-podsecurity-and-networkpolicy`
"never comes up" and that the Service in front of it has no endpoints. There is also a
default-deny NetworkPolicy in the namespace that legitimate traffic needs to get through.

Investigate and fix this:

1. Figure out why pod `worker` does not exist at all (not just unhealthy - check whether it was
   ever admitted). The namespace enforces the `restricted` Pod Security Standard.
2. Recreate a pod named `worker` in this namespace that:
   - is labeled `app: worker`
   - runs container `worker` on image `nginxinc/nginx-unprivileged:1.25-alpine` (an image built
     to run as a non-root user), listening on container port `8080`
   - fully complies with the `restricted` Pod Security Standard: `runAsNonRoot: true`,
     `allowPrivilegeEscalation: false`, capabilities `drop: ["ALL"]`, and
     `seccompProfile.type: RuntimeDefault`
   - reaches the `Running` phase
3. Service `worker-svc` already selects `app=worker` on port `8080` - once the pod exists with
   the right label and is Running, its endpoints should populate on their own.
4. There is an existing default-deny-ingress NetworkPolicy in the namespace. Add a rule (a new
   NetworkPolicy or an edit to the existing one) that allows ingress to `worker` on TCP port
   `8080` from pods labeled `role: client`, without opening ingress to anything else.

## Hint

Search kubernetes.io/docs for **"enforce Pod Security Standards with namespace labels"** and
separately for **"network policy allow traffic from pods in another namespace"** - the Pod
Security Admission page lists exactly which securityContext fields `restricted` requires, and
the NetworkPolicy concept page has a copy-paste example for allowing ingress from pods matching
a label selector.
