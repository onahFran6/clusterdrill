# q111-18: Working inside a LimitRange

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-18-limitrange-largest-allowed`

This namespace has a LimitRange set by the platform team (seeded, `max.memory: 512Mi`,
`default.memory: 256Mi`, `defaultRequest.memory: 128Mi`), which you must not change. Deployment
`oven` (seeded) has zero running pods. Deployment `bread` (seeded, no resources specified at
all) already has running pods.

- Work out why `oven` had zero pods in the first place - check the ReplicaSet's own events.
- Make `oven` run **3** pods at the **largest memory request and limit** the namespace allows.
- Compare `bread`'s actual running pod resources against its Deployment spec - notice they
  differ, and figure out who filled them in.

## Hint

Search kubernetes.io/docs for **"Resource Quality of Service"** and
**"LimitRange"**. Zero pods at all means look one level up, at the ReplicaSet's own events -
what do they say about `oven`'s current memory request? For comparison, look at one of `bread`'s
actual running pods, not its Deployment spec - who filled in values the Deployment manifest never
had?
