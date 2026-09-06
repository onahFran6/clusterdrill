# q101-37-create-secret-docker-registry-imperative: Create a docker-registry image pull Secret

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-37-create-secret-docker-registry-imperative`

In namespace `q101-37-create-secret-docker-registry-imperative`, create a Secret named
`registry-cred` that a pod could use as an `imagePullSecrets` entry to authenticate against a
private registry `registry.example.com`, for user `svc-deploy` with password `sup3r-secret!` and
email `svc-deploy@example.com`. Use a single imperative `kubectl create secret docker-registry`
command (no manifest authored by hand).

## Hint

Search kubernetes.io/docs for **"create secret docker-registry"** - the "Pull an Image from a
Private Registry" task page shows the `kubectl create secret docker-registry` form and its
`--docker-server`/`--docker-username`/`--docker-password`/`--docker-email` flags.
