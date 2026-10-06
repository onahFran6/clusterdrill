# q111-17: Annotations, labels and an immutable selector

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-17-immutable-selector-replace`

Team Fortuna's `wallet` Deployment (seeded, 2 replicas) must meet two new platform rules.

- The Deployment must carry annotation `owner=payments`. Adding it must not restart any pods.
- Every `wallet` pod must carry label `team: fortuna`, and the Deployment's **selector** must
  also match on it. Keep 2 pods running after.
- Confirm the final selector, and that the delete+recreate reset the revision history back to 1.

## Hint

Search kubernetes.io/docs for **"Deployment selector"** - the "Selector" section of the
Deployment concept page says `spec.selector` is immutable once created. Which part of a
Deployment can change without ever touching the pod template? Try changing the selector through
a normal edit and read the error - which single kubectl verb deletes an object and recreates it
from a full manifest in one step?
