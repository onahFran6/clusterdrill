# q108-29: Allow DNS egress without loosening an existing NetworkPolicy rule

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-29-networkpolicy-conflicting-rules-egress-dns`

A Deployment `report-generator` (pod-template label
`app=report-generator`) and a Deployment `internal-api` (pod-template label `app=internal-api`,
container port `8080`) already exist in namespace
`q108-29-networkpolicy-conflicting-rules-egress-dns`, along with a NetworkPolicy named
`report-generator-egress` that:

- applies to pods matching `app=report-generator`
- sets `policyTypes: [Egress]`
- allows egress only to pods matching `app=internal-api` on TCP port `8080`

`report-generator` can reach `internal-api` by pod IP, but name lookups fail, so a client that
calls the Service by name cannot connect.

Fix `report-generator-egress` so `report-generator` pods can resolve DNS names again, without
loosening or removing the existing rule to `internal-api`:

- keep the existing egress rule that allows TCP port `8080` to pods matching `app=internal-api`
- add a second egress rule that allows egress to every pod in the `kube-system` namespace
  (`namespaceSelector` matching `kubernetes.io/metadata.name: kube-system`) restricted to port
  `53` on both `UDP` and `TCP`

Do not create a second NetworkPolicy. Both rules must live in `report-generator-egress`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's example manifest
shows an `egress` list with more than one entry. Once an egress policy is in effect, traffic it
does not name is dropped, including DNS. In this cluster CoreDNS runs in `kube-system` and
listens on UDP and TCP port `53`.
