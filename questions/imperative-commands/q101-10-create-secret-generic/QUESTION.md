# q101-10: Create a generic Secret from literal values

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-10-create-secret-generic`

In namespace `q101-10-create-secret-generic`, create a generic Secret named `db-creds` using an
imperative `kubectl` command with these two keys:

- `username=admin`
- `password=S3cr3t!`

No YAML file authored by hand, and don't base64-encode the values yourself - let `kubectl` do it.

## Hint

Search kubernetes.io/docs for **"kubectl create secret generic from-literal"** - the Secrets
concept page and the `kubectl create secret generic` reference both show this pattern.
