# q108-34-service-type-loadbalancer-basic: Expose a Deployment via a LoadBalancer Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-34-service-type-loadbalancer-basic`

`setup.sh` already created a Deployment named `webshop` (image `httpd:2.4-alpine`, 2 replicas,
container port `80`, pod-template label `app=webshop`) in namespace
`q108-34-service-type-loadbalancer-basic`.

Write a Service manifest named `webshop-svc` that:

- is of type `LoadBalancer`
- selects pods with label `app=webshop`
- listens on port `80` and forwards to the container's port `80`

Apply the manifest so the Service exists in the namespace. This lab cluster has no real cloud
load balancer, so the Service's external IP will stay `<pending>` forever - that is expected and
not graded; only the object's `spec` is.

## Hint

Search kubernetes.io/docs for **"type LoadBalancer"** - the Service concept page's LoadBalancer
section shows `spec.type: LoadBalancer` used alongside the same `selector`/`ports` fields as
ClusterIP and NodePort Services.
