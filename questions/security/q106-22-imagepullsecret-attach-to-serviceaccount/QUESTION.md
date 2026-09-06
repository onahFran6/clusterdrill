# q106-22-imagepullsecret-attach-to-serviceaccount: Attach an existing imagePullSecret to a ServiceAccount

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-22-imagepullsecret-attach-to-serviceaccount`

The namespace `q106-22-imagepullsecret-attach-to-serviceaccount` already has a Secret named
`registry-creds` (type `kubernetes.io/dockerconfigjson`) holding credentials for a private image
registry, and a ServiceAccount named `builder` that pods use to pull and build images. The
ServiceAccount was created without being wired up to that Secret, so pods running as `builder`
still cannot pull from the private registry.

Update the `builder` ServiceAccount so its `imagePullSecrets` list includes `registry-creds`, without
deleting or recreating the `registry-creds` Secret.

## Hint

Search kubernetes.io/docs for **"add ImagePullSecrets to a service account"** - the container
images task page shows the exact patch to add an imagePullSecret to an existing ServiceAccount.
