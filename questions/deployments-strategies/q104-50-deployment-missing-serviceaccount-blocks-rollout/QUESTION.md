# q104-50: Fix a Deployment blocked on its ServiceAccount

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-50-deployment-missing-serviceaccount-blocks-rollout`

A ServiceAccount named `payments-runner` and a Deployment named `payments-worker` already exist
in namespace `q104-50-deployment-missing-serviceaccount-blocks-rollout`. The Deployment wants 2
replicas but has never been Ready - its ReplicaSet cannot create pods.

Inspect the Deployment and the namespace's ServiceAccounts (`kubectl get serviceaccount -n
q104-50-deployment-missing-serviceaccount-blocks-rollout`), set
`spec.template.spec.serviceAccountName` to the existing `payments-runner`, and confirm both
replicas reach Ready.

## Hint

Search kubernetes.io/docs for **"configure service account pod"** - the Configure Service Accounts
task shows `spec.serviceAccountName`. A pod that references a ServiceAccount name that does not
exist in its namespace fails admission before the pod object is created - compare the template
field to `kubectl get serviceaccount` and correct any mismatch.
