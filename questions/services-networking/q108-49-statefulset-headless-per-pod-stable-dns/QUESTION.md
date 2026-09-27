# q108-49: Fix a StatefulSet's broken per-pod DNS

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-49-statefulset-headless-per-pod-stable-dns`

Namespace `q108-49-statefulset-headless-per-pod-stable-dns` already has:

- a headless Service named `db-cluster` (`spec.clusterIP: None`, selecting `app: db-cluster`)
- a StatefulSet named `db-cluster` (2 replicas, pod-template label `app: db-cluster`) whose
  `spec.serviceName` does not name that Service

The pods (`db-cluster-0`, `db-cluster-1`) run, but
`db-cluster-0.db-cluster.q108-49-statefulset-headless-per-pod-stable-dns.svc.cluster.local`
does not resolve.

Set the StatefulSet's `spec.serviceName` to `db-cluster`. `serviceName` is immutable, so replace
the StatefulSet (which recreates its pods) rather than patching that field in place.

Once the pods are back up, resolve
`db-cluster-0.db-cluster.q108-49-statefulset-headless-per-pod-stable-dns.svc.cluster.local`
from any Pod in this namespace and store the resolved IP in a ConfigMap named `dns-check-result`,
under the key `resolved-ip`.

## Hint

Search kubernetes.io/docs for **"StatefulSet" "serviceName"** - the StatefulSet Basics concept
page's Stable Network ID section explains that `spec.serviceName` must reference an existing
headless Service for `<pod-name>.<service-name>.<namespace>.svc.cluster.local` to resolve to that
pod's IP, and that `serviceName` cannot be changed on an existing StatefulSet. `kubectl replace
--force`, or a delete followed by apply, is how you set a new value.
