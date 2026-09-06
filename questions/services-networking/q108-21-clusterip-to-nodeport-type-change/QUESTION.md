# q108-21-clusterip-to-nodeport-type-change: Convert a ClusterIP Service to NodePort with a fixed port

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-21-clusterip-to-nodeport-type-change`

`setup.sh` already created a Deployment named `catalog-api` (image `hashicorp/http-echo`, 2
replicas, container port `5678`) and a Service named `catalog-api-svc` of type `ClusterIP`
targeting port `5678`, in namespace `q108-21-clusterip-to-nodeport-type-change`.

Without deleting or recreating `catalog-api-svc`, change it so that:

- `spec.type` is `NodePort`
- `spec.ports[0].nodePort` is pinned to exactly `30081`

The Service must keep routing to the same pods (do not change its selector), and its endpoints
must continue to list the `catalog-api` Deployment's running pods.

## Hint

Search kubernetes.io/docs for **"NodePort type"** - the Service concept page's NodePort section
shows that an existing Service's `type` and `nodePort` fields can be updated in place with
`kubectl edit` or `kubectl patch`, without deleting the Service.
