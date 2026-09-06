# q108-49-statefulset-headless-per-pod-stable-dns: Fix a StatefulSet's broken per-pod DNS

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-49-statefulset-headless-per-pod-stable-dns`

`setup.sh` already created, in namespace `q108-49-statefulset-headless-per-pod-stable-dns`:

- a headless Service named `db-cluster` (`spec.clusterIP: None`, selecting `app: db-cluster`)
- a StatefulSet named `db-cluster` (2 replicas, pod-template label `app: db-cluster`) whose
  `spec.serviceName` is set to `db-cluster-svc` - a Service that does not exist. A StatefulSet's
  `serviceName` must name a real headless Service in the same namespace for its pods to get the
  stable, individually-addressable DNS records (`<pod-name>.<service-name>.<namespace>.svc.cluster.local`)
  that make a StatefulSet useful in the first place. With the wrong name, the pods (`db-cluster-0`,
  `db-cluster-1`) still come up and run fine, but `db-cluster-0.db-cluster.<namespace>.svc.cluster.local`
  does not resolve to anything.

Fix the StatefulSet's `spec.serviceName` to `db-cluster` (the headless Service that actually
exists). Because `serviceName` is immutable on an existing StatefulSet, you cannot patch it in
place - `kubectl replace --force` it, or `delete` and re-`apply` it, redeploying its pods.

Once fixed and the pods are back up, verify per-pod DNS actually resolves: from any Pod in this
namespace, resolve `db-cluster-0.db-cluster.q108-49-statefulset-headless-per-pod-stable-dns.svc.cluster.local`
and store the resolved IP address in a ConfigMap named `dns-check-result` in this namespace, under
the key `resolved-ip`.

## Hint

Search kubernetes.io/docs for **"StatefulSet" "serviceName"** - the StatefulSet Basics concept
page's Stable Network ID section explains that `spec.serviceName` must reference an existing
headless Service for `<pod-name>.<service-name>.<namespace>.svc.cluster.local` to resolve to that
specific pod's IP, and that `serviceName` cannot be changed on an existing StatefulSet.
