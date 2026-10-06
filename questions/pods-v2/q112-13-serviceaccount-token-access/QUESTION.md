# q112-13: One Pod with API access, one without

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-13-serviceaccount-token-access`

Two utility Pods are needed in this namespace. One must never hold Kubernetes credentials. The
other needs to list Pods in its own namespace.

- Create ServiceAccount `scanner` and Pod `scanner` (`busybox:1.36`, `sleep 3600`) using it, with
  **no API token mounted at all**.
- Create ServiceAccount `lister`, a Role granting only `get`/`list` on `pods` in this namespace, a
  RoleBinding tying them together, and Pod `lister` (`curlimages/curl:8.10.1`, `sleep 3600`) using
  that ServiceAccount.
- From inside `lister`, call the API server directly using its own mounted token to list Pods in
  this namespace, and confirm it succeeds.

## Hint

Search kubernetes.io/docs for **"Managing Service Accounts"** and
**"configure-service-account#opt-out-of-api-credential-automounting"**. The field that controls
token mounting exists on both the ServiceAccount and the Pod, and the Pod's own value wins.
Inside a Pod, the API server is reachable at `https://kubernetes.default.svc`, and the token plus
CA cert sit together under `/var/run/secrets/kubernetes.io/serviceaccount`.
