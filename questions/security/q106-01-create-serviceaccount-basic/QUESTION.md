# q106-01: Create a dedicated ServiceAccount

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-01-create-serviceaccount-basic`

A new backup tool is being onboarded into the cluster and must not run under the namespace's
`default` ServiceAccount.

In namespace `q106-01-create-serviceaccount-basic`, create a ServiceAccount named `backup-agent`.

## Hint

Search kubernetes.io/docs for **"configure service account"** - the ServiceAccount concept page
shows the exact `kubectl create serviceaccount` form.
