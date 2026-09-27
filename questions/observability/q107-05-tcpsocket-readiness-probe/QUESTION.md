# q107-05: Add a TCP socket readiness probe for a non-HTTP TCP service

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-05-tcpsocket-readiness-probe`

A pod named `cache-node` (image `redis:7-alpine`, listening on container port `6379`) already
exists in namespace `q107-05-tcpsocket-readiness-probe`.

Edit the pod so it has a `readinessProbe` that:

- uses `tcpSocket` against container port `6379`
- sets `initialDelaySeconds` to `5`
- sets `periodSeconds` to `10`

Keep the pod named `cache-node` and keep it running (you may delete and recreate it with the same
name to add the probe).

## Hint

Search kubernetes.io/docs for **"tcpSocket"** - the probes task page shows a TCP liveness example
that uses the identical `tcpSocket.port` field for a readiness probe. Redis speaks its own binary
protocol, not HTTP, so an `httpGet` probe cannot succeed here. A TCP probe only tests whether the
port accepts a connection.
