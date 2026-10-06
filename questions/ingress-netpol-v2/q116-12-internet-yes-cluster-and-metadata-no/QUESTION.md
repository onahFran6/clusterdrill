# q116-12: Internet yes, cluster and metadata no

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-12-internet-yes-cluster-and-metadata-no`

Pod `fetcher` (label `app: fetcher`) downloads public feeds. Service `inside-svc` (port `80`,
with its matching Deployment) also runs here. Security wants `fetcher` unable to reach anything
inside the cluster's private address ranges or the cloud metadata address, while still reaching
the public internet and resolving names.

- Create NetworkPolicy `fetcher-egress`: `fetcher` may send to any address **except**
  `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, and `169.254.169.254/32`, plus DNS to the
  cluster's DNS pods.
- (ungraded, Task narrative only) Record the results of reaching the public internet versus
  reaching `inside-svc`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "ipBlock"** - an `ipBlock` peer takes a `cidr` and
an `except` list. The cluster's own DNS pods live inside one of the excluded ranges, so DNS needs
its own separate rule - which kind of selector reaches pods instead of an external address range?
