# q105-32: Repair a broken private-registry pull Secret

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-32-secret-type-mismatch-imagepull-broken`

Namespace `q105-32-secret-type-mismatch-imagepull-broken` has a Deployment named `private-app`
whose pod template references a Secret named `registry-cred` under `imagePullSecrets`, meant to
authenticate pulls from a private registry. Image pulls using that Secret fail: the Secret is not
in a shape the kubelet can use for registry authentication (a real private registry would report
`ImagePullBackOff` / `ErrImagePull` for the same reason).

Delete `registry-cred` and recreate it as a Secret of type `kubernetes.io/dockerconfigjson` for
registry `registry.example.internal` with:

- username: `svc-deploy`
- password: `hunter2-registry`
- email: `svc-deploy@example.internal`

Do not change the Deployment's `imagePullSecrets` reference - it already points at `registry-cred`.

## Hint

Search kubernetes.io/docs for **"create secret docker-registry"** - the Pull an Image from a
Private Registry task shows the exact Secret type/key shape the kubelet expects for
`imagePullSecrets`, and how it differs from a generic Opaque Secret.
