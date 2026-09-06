# q105-32-secret-type-mismatch-imagepull-broken: Diagnose an imagePullSecret created with the wrong Secret type

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-32-secret-type-mismatch-imagepull-broken`

Namespace `q105-32-secret-type-mismatch-imagepull-broken` has a Deployment named `private-app`
whose pod template references a Secret named `registry-cred` under `imagePullSecrets`, meant to
authenticate pulls from a private registry.

Someone created `registry-cred` as a plain generic Secret holding a raw dockerconfig-shaped string
under an arbitrary key called `creds`, instead of the proper Docker registry credential type and
key that the kubelet actually knows how to parse for image pulls (a real private registry would
report `ImagePullBackOff`/`ErrImagePull` for exactly this reason, even with otherwise-correct
credentials). Inspect the Secret to confirm this is a Secret shape problem, not simply wrong
credentials.

Delete `registry-cred` and recreate it as a Secret of type `kubernetes.io/dockerconfigjson` for
registry `registry.example.internal` with:

- username: `svc-deploy`
- password: `hunter2-registry`
- email: `svc-deploy@example.internal`

Do not change the Deployment's `imagePullSecrets` reference - it already points at the name
`registry-cred`, so recreating the Secret correctly under the same name is enough to let the
kubelet parse it.

## Hint

Search kubernetes.io/docs for **"create secret docker-registry"** - the Pull an Image from a
Private Registry task shows the exact Secret type/key shape the kubelet expects for
`imagePullSecrets`, and how it differs from a generic Opaque Secret.
