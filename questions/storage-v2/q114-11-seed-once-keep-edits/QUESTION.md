# q114-11: Seed once from a ConfigMap, then keep edits

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-11-seed-once-keep-edits`

Editors change the live site's `index.html` by hand, and those edits must survive Pod restarts.
The starting page lives in ConfigMap `site-seed` (key `index.html`).

- Create PVC `site-content` (100Mi, default StorageClass) and Deployment `site` (1 replica,
  `nginx:1.27`, strategy `Recreate`) serving `/usr/share/nginx/html` from that claim.
- Add an init container `seed` that copies the ConfigMap's `index.html` into the claim **only if
  it isn't there yet**.
- `(ungraded)` Note what the site serves right after it first comes up. Then overwrite the file on
  the claim by hand with `edited by hand`, delete the pod, and confirm the replacement serves your
  hand-edited content instead.

## Hint

Search kubernetes.io/docs for **"init containers"** and **"ConfigMaps"** - a ConfigMap volume is
read-only and rebuilt from the API on every mount, so editing it in place from inside the Pod is
never an option. The init container mounts both volumes, the ConfigMap read-only and the claim. A
shell test like `[ -f file ] || cp ...` gives you "only if missing."
