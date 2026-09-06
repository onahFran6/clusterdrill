# q102-41-projected-volume-merge-missing-key: Projected volume's item list silently drops a Secret key

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-41-projected-volume-merge-missing-key`

A Pod named `combined-config-app` already exists in this namespace with two
containers, `app` and `sidecar-auditor` (both busybox:1.36), that both
mount the **same** `projected` volume named `combined` at `/etc/combined`
(read-only). That projected volume combines two sources:

- a ConfigMap `app-config` (key `app.conf`)
- a Secret `app-secret` (keys `api-key` and `db-pass`)

The projected volume's Secret source uses an explicit `items` list naming
only `api-key` - and once a source's `items` list is present, **only** the
keys named there are projected, not every key in the Secret automatically.
`db-pass` was left out of that list, so `/etc/combined/db-pass` never
exists in **either** container, even though the Secret itself really has
that key. `/etc/combined/app.conf` and `/etc/combined/api-key` both show up
fine. Nothing crashes - both containers idle and report `Running` the
whole time.

Fix the projected volume's Secret source so its `items` list also includes
`db-pass` (mapped to path `db-pass`), without removing the existing
`api-key` entry or changing the ConfigMap source. This field is immutable
on a running Pod - delete and recreate `combined-config-app` with the fix
applied, keeping every other field unchanged. Once fixed,
`/etc/combined/db-pass` must exist and contain exactly `dbp-9902` in both
containers, alongside the existing `app.conf` and `api-key` files.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Volumes concept
page's "projected" section shows how a single volume can combine ConfigMap
and Secret sources, and that each source's own `items` list (when present)
controls exactly which keys get projected.
