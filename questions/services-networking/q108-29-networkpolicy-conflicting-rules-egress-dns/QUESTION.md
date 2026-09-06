# q108-29-networkpolicy-conflicting-rules-egress-dns: Fix a restrictive NetworkPolicy that blocks DNS and breaks egress despite an allow rule

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-29-networkpolicy-conflicting-rules-egress-dns`

`setup.sh` already created a Deployment `report-generator` (pod-template label
`app=report-generator`) and a Deployment `internal-api` (pod-template label `app=internal-api`,
container port `8080`) in namespace `q108-29-networkpolicy-conflicting-rules-egress-dns`, along
with a NetworkPolicy named `report-generator-egress` that:

- applies to pods matching `app=report-generator`
- sets `policyTypes: [Egress]`
- allows egress only to pods matching `app=internal-api` on TCP port `8080`

Because this policy defines an `egress` list with no catch-all entry, `report-generator` pods can
only ever reach exactly what an `egress` rule names. Reaching `internal-api` by its pod IP still
works, but every DNS lookup - including the ones a `curl` to a Service *name* has to do first -
is silently dropped, since nothing in this policy allows outbound traffic to the cluster's DNS
resolver. In this cluster, CoreDNS runs in the `kube-system` namespace and listens on both UDP and
TCP port `53`.

Fix the NetworkPolicy `report-generator-egress` so `report-generator` pods can resolve DNS names
again, without loosening or removing the existing rule to `internal-api`. Concretely:

- keep the existing egress rule that allows TCP port `8080` to pods matching `app=internal-api`
  exactly as it is
- add a second egress rule to the same NetworkPolicy that allows egress to every pod in the
  `kube-system` namespace (use a `namespaceSelector` matching the namespace's built-in
  `kubernetes.io/metadata.name: kube-system` label) restricted to port `53` on both `UDP` and
  `TCP`

Do not create a second NetworkPolicy - both rules must live in `report-generator-egress`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's example manifest
under "The following NetworkPolicy..." shows an `egress` list with more than one entry, and the
"DNS" note nearby covers why an egress-restricting policy must also allow port 53 to `kube-system`.
