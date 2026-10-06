# q111-10: Deployment with no running pods

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-10-three-faults-zero-pods`

Team Vulcan applied Deployment `reporter` (seeded) an hour ago and it still has zero Ready pods.
ConfigMap `report-config` and Secret `report-secret` (both seeded) are correct and must not be
renamed or changed. The ServiceAccount name the Deployment references is the one the platform
team expects and must not change either.

- Fix whatever is needed so `reporter` runs **2** Ready pods.
- Be ready to explain the three distinct root causes you found and fixed, one at a time.

## Hint

Search kubernetes.io/docs for **"Debug Running Pods"**. There are three faults, and each one
hides the next. Zero pods at all means look one level up, at the ReplicaSet's own events. Once
pods exist, their own status and events name the next problem. Compare every name the Deployment
references against `kubectl get cm,secret,sa` character by character, including case.
