# q116-04: Strip the prefix

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-04-strip-the-prefix`

A stock `nginx:1.27` Deployment `legacy`, exposed by Service `legacy-svc` port `80`, only knows
paths starting at `/`. It must be published under `quasar.local/legacy/`.

- (ungraded, Task narrative only) First try a plain `Prefix` rule for `/legacy` with no rewrite,
  and note that the app itself answers with its own 404 - routing worked, the app just has no
  `/legacy/` page.
- Create Ingress `legacy` (class `nginx`) so that `/legacy/` reaches the app's `/`, and
  `/legacy/index.html` reaches `/index.html`. Use the annotations
  `nginx.ingress.kubernetes.io/use-regex: "true"` and
  `nginx.ingress.kubernetes.io/rewrite-target: /$2`, with path `/legacy(/|$)(.*)`.

## Hint

Search kubernetes.io/docs for **"Ingress annotations"** on the ingress-nginx project's own docs
site for "Rewrite" - rewriting isn't part of the core Ingress spec, it's a controller-specific
annotation that uses regex capture groups from the path, which is why the path itself has to
become a regex and `pathType` has to allow that.
