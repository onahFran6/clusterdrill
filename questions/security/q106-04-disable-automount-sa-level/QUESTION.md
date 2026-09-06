# q106-04: Stop a ServiceAccount from automounting tokens by default

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-04-disable-automount-sa-level`

`setup.sh` already created a ServiceAccount named `metrics-reader` in namespace
`q106-04-disable-automount-sa-level`. None of the pods that will use it call the Kubernetes API,
so the team wants the safe default to live on the ServiceAccount itself rather than relying on
every pod author to remember to opt out individually.

Edit the `metrics-reader` ServiceAccount so that pods using it do not automount a ServiceAccount
API token unless a pod explicitly opts back in.

## Hint

Search kubernetes.io/docs for **"automountServiceAccountToken"** - the ServiceAccount concept
page explains how this field behaves when set on the ServiceAccount versus on the pod.
