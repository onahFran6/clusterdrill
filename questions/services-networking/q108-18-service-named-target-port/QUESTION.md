# q108-18: Target a container's named port from a Service

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-18-service-named-target-port`

`setup.sh` already created a Deployment named `image-resizer` (image `httpd:2.4-alpine`, 2
replicas, pod-template label `app=image-resizer`) whose container declares its port with a name
instead of a bare number: `containerPort: 8081` named `worker-port`.

Write a Service manifest named `image-resizer-svc` of type `ClusterIP` that selects
`app=image-resizer`, listens on Service port `80`, and forwards to the container by **port name**
(`targetPort: worker-port`) rather than by repeating the numeric value `8081`. Referencing pods by
named port means the Service keeps working even if the Deployment later changes which number that
name maps to.

## Hint

Search kubernetes.io/docs for **"defining a service"** - the Service concept page shows that
`targetPort` can be either a number or the string name of a `ports[].name` declared on the
container, and that using the name is the more resilient choice when it might change.
