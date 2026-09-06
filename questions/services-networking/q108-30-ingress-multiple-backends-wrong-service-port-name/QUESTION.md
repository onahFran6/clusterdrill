# q108-30-ingress-multiple-backends-wrong-service-port-name: Diagnose an Ingress 502 caused by a mismatched named service port reference

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-30-ingress-multiple-backends-wrong-service-port-name`

`setup.sh` already created a working Deployment `payments-app`, a Service `payments-svc` that
selects it (single port entry named `http-api`, `port: 80`, `targetPort: 8080`), and an Ingress
named `payments-ingress` (IngressClass `nginx`) with a rule for path `/pay` (`pathType: Prefix`).

Requests to `/pay` through the ingress currently fail (502/503): the Ingress backend for `/pay`
references `service.port.name: http` instead of `http-api`, and `payments-svc` has no port
actually named `http` - so the ingress controller cannot resolve which backend port to send
traffic to.

Fix the Ingress so `/pay` routes correctly:

- Edit the `/pay` backend in `payments-ingress` so it references a port that actually exists on
  `payments-svc` - either correct the name to `service.port.name: http-api`, or switch to
  `service.port.number: 80`. Either is acceptable.
- Do **not** rename or otherwise modify the port on `payments-svc` - fix the Ingress, not the
  Service.

## Hint

Search kubernetes.io/docs for **"Ingress backend service port name number"** - the Ingress
concept page's "Resource backends" / backend section shows that a backend's
`service.port.name` must exactly match a `name` defined under the Service's `spec.ports`, or you
must use `service.port.number` instead.
