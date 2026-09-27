# q106-04: Stop a ServiceAccount from automounting tokens by default

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-04-disable-automount-sa-level`

A ServiceAccount named `metrics-reader` already exists in namespace
`q106-04-disable-automount-sa-level`. Pods that will use it do not call the Kubernetes API.

Edit the `metrics-reader` ServiceAccount so that pods using it do not automount a ServiceAccount
API token unless a pod explicitly opts back in.

## Hint

Search kubernetes.io/docs for **"automountServiceAccountToken"** - the ServiceAccount concept
page explains how this field behaves when set on the ServiceAccount versus on the pod. Setting
it on the ServiceAccount covers every pod that uses it, so each pod does not have to opt out
on its own.
