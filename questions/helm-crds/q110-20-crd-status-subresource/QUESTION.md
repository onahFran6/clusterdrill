# q110-20: Set a BackupJob's status.phase to Completed

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-20-crd-status-subresource`

A CRD (kind `BackupJob`, plural `backupjobs`, group `ops.clusterdrill.io/v1`) is already
registered with a status subresource enabled and a schema that includes `spec.targetPath`
(string) and `status.phase` (string). One instance, `nightly-backup`, already exists in
namespace `q110-20-crd-status-subresource` with `spec.targetPath` set to `/data/backups` and
`status.phase` left unset.

Set `status.phase` to `Completed` on the `nightly-backup` BackupJob using the status
subresource (not a normal patch or edit of the main resource). Do not modify
`spec.targetPath` - it must remain `/data/backups`.

## Hint

Search kubernetes.io/docs for **"custom resource status subresource"** - the "Custom Resources"
concept page and the `kubectl patch --subresource` reference explain why status updates on a
CRD with `subresources: {status: {}}` enabled must go through the `/status` endpoint separately
from `spec`. A normal `kubectl patch`/`kubectl edit` against the main resource silently drops
`status` changes. Example:

```sh
kubectl patch backupjob nightly-backup -n q110-20-crd-status-subresource \
  --subresource=status --type=merge -p '{"status":{"phase":"Completed"}}'
```
