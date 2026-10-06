# q115-02: Credentials for a private registry

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q115-02-pull-secrets-via-serviceaccount`

Team Miranda's images live at `registry.example.com` under user `ci-bot` with password
`S3cret!pw`. ServiceAccount `builder` already exists in this namespace. Every **new** Pod run by
`builder` must be able to pull from that registry, without each Pod spec naming the credentials
itself.

- Create registry Secret `regcred` (server `registry.example.com`, username `ci-bot`, password
  `S3cret!pw`). Attach it to ServiceAccount `builder` so any new Pod using that account inherits
  the credential automatically.
- Create Pod `app` using ServiceAccount `builder`, image `registry.example.com/team/app:1.0`.
  `(ungraded, Task narrative only)` this registry does not exist, so the Pod never starts - that
  is expected.

## Hint

Search kubernetes.io/docs for **"Pull an Image from a Private Registry"** and
**"add-imagepullsecrets-to-service-account"**. `kubectl create secret docker-registry` has a type
specifically for registries. A ServiceAccount has a field that is copied into every Pod using it,
but only at that Pod's own creation time - order matters.
