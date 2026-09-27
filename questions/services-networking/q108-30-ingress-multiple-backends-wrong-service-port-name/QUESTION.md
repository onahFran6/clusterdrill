# q108-30: Fix an Ingress backend that names a Service port which does not exist

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-30-ingress-multiple-backends-wrong-service-port-name`

A working Deployment `payments-app`, a Service `payments-svc` that
selects it (single port entry named `http-api`, `port: 80`, `targetPort: 8080`), and an Ingress
named `payments-ingress` (IngressClass `nginx`) already exist. The Ingress has a rule for path
`/pay` (`pathType: Prefix`).

Requests to `/pay` through the ingress fail (502/503). The Ingress backend's port reference does
not match the port that actually exists on `payments-svc`.

Fix the Ingress so `/pay` routes correctly:

- Point the `/pay` backend in `payments-ingress` at a port that exists on `payments-svc`: either
  `service.port.name: http-api` or `service.port.number: 80`. Either is acceptable.
- Do **not** rename or otherwise modify the port on `payments-svc`.

## Hint

Search kubernetes.io/docs for **"Ingress backend service port name number"** - the Ingress
concept page shows that `service.port.name` must exactly match a `name` under the Service's
`spec.ports`, or you must use `service.port.number` instead. Compare the name the Ingress
currently references with the name on `payments-svc`.
