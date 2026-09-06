# q107-05: Add a TCP socket readiness probe for a non-HTTP TCP service

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-05-tcpsocket-readiness-probe`

`setup.sh` already created a pod named `cache-node` (image `redis:7-alpine`, listening on
container port `6379`) in namespace `q107-05-tcpsocket-readiness-probe`. Redis speaks its own
binary protocol, not HTTP, so an `httpGet` probe would never work here - readiness has to be
checked by testing whether the TCP port simply accepts connections.

Edit the pod so it has a `readinessProbe` that:

- uses `tcpSocket` against container port `6379`
- sets `initialDelaySeconds` to `5`
- sets `periodSeconds` to `10`

Keep the pod named `cache-node` and keep it running (you may delete and recreate it with the same
name to add the probe).

## Hint

Search kubernetes.io/docs for **"tcpSocket"** - the probes task page shows a TCP liveness example
that uses the identical `tcpSocket.port` field for a readiness probe.
