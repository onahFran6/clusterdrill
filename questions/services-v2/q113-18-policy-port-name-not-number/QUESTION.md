# q113-18: The policy allows the wrong port

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-18-policy-port-name-not-number`

Team Orion's `client` pod calls `web-svc:8080`. A default-deny policy and an allow policy,
`allow-client`, already exist, and `client` still times out.

- Name `web`'s container port `http` (a pod-template change, so it needs a rollout).
- Fix `allow-client` to reference the port **by that name**, not by number, so a future
  container-port change won't break the policy again. Don't change the Service, the Deployment's
  image, or the default-deny policy.

This cluster's default CNI does not enforce NetworkPolicy, so the policy's own fields are
graded, not live traffic; the container port's name is a real, live field, graded directly.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "ports" "named port"** - the NetworkPolicy API
reference states a policy's port can be a name instead of a number, resolved against each
selected pod's own container ports. By the time a packet reaches the `web` pod, it's addressed to
the **container** port, never the Service port - that's the layer a NetworkPolicy's own `ports`
field is checked against.
