# q105-05: Create a registry credential Secret and attach it to a pod

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-05-secret-docker-registry-imagepullsecret`

`setup.sh` already created a running pod named `private-app` (image `nginx:1.25-alpine`) in
namespace `q105-05-secret-docker-registry-imagepullsecret`.

Create a Secret named `regcred` of the Docker registry credential type, for a private registry
`registry.example.internal` with:

- username: `svc-deploy`
- password: `hunter2-registry`
- email: `svc-deploy@example.internal`

Then edit the pod so it references `regcred` as an image pull secret (`imagePullSecrets`), so a
future image pull from that private registry would authenticate correctly. The pod will need to
be recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"create secret docker-registry"** - the Pull an Image from a
Private Registry task covers creating the credential Secret and wiring it into a pod spec via
`imagePullSecrets`.
