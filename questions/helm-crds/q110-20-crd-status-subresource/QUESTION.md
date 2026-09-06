# q110-20: Patch a CRD instance's status subresource independently of spec

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-20-crd-status-subresource`

`setup.sh` registered a CRD (kind `BackupJob`, plural `backupjobs`, group
`ops.clusterdrill.io/v1`) with the **status subresource enabled**
(`subresources: {status: {}}`) and a schema with `spec.targetPath` (string) and
`status.phase` (string). It created one instance, `nightly-backup`, in namespace
`q110-20-crd-status-subresource` with `spec.targetPath` set to `/data/backups` and
`status.phase` left unset.

Set `status.phase` to `Completed` on the `nightly-backup` BackupJob **using the status
subresource specifically** - for example:

```sh
kubectl patch backupjob nightly-backup -n q110-20-crd-status-subresource \
  --subresource=status --type=merge -p '{"status":{"phase":"Completed"}}'
```

Because the CRD enables a true status subresource, a normal `kubectl patch`/`kubectl edit`
against the main resource endpoint silently drops any `status` changes - the request must target
`/status` specifically (via `--subresource=status`, `kubectl replace --raw .../status`, or
equivalent). Do not modify `spec.targetPath` - it must remain `/data/backups`.

## Hint

Search kubernetes.io/docs for **"custom resource status subresource"** - the "Custom Resources"
concept page and the `kubectl patch --subresource` reference explain why status updates on a CRD
with `subresources: {status: {}}` enabled must go through the `/status` endpoint separately from
`spec`.
