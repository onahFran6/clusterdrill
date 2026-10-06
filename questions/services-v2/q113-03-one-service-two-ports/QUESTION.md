# q113-03: One Service, two ports

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-03-one-service-two-ports`

Team Rigel's `shop` pods serve the site on container port 80 (named `http`) and metrics on
container port 8080 (named `metrics`).

- Create ClusterIP Service `shop-svc` with port **80** for the site and port **9100** for
  metrics. Each Service port must target the matching container port **by name**, not number.

## Hint

Search kubernetes.io/docs for **"Service" "multi-port services"** - the Service concept page's
multi-port example shows each `ports[]` entry needs its own `name`, and `targetPort` may be a
string naming a container port instead of a number. Apply a Service with two unnamed ports first
and read the admission error: what does a Service need once it has more than one port?
