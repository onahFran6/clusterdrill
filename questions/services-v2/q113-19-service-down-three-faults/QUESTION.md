# q113-19: "The Service is down" - three faults

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-19-service-down-three-faults`

Team Draco's `client` pod can't reach `orders-svc`. The `orders` Deployment's own pods are
Running, and the team insists both `client` and the Deployment are correct.

- Change only the Service and the NetworkPolicies until `client` can reach `orders-svc` and get
  the nginx page back.
- (ungraded, Task narrative only) Walk the path in order on each attempt: DNS, then endpoints
  (does the selector match anything?), then the port (does anything listen on `targetPort`?),
  then policy. A refused connection and a timeout mean different things.

This cluster's default CNI does not enforce NetworkPolicy, so the NetworkPolicy fault is graded
on the object's fields only; the Service fixes are graded live, since plain Service routing works
regardless of whether NetworkPolicy is enforced.

## Hint

Search kubernetes.io/docs for **"Debug Services"** - the Services debugging guide walks exactly
this order: does the Service have endpoints, does the selector match the pods' real labels, is
the target port the one the container actually listens on. A NetworkPolicy fault only shows up
once the first two layers are already fixed, since traffic never reached a pod before that.
