# q111-20: Expose by named port

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-20-expose-by-named-port`

Team Sol's `beam` Deployment (seeded, 3 replicas) declares no container ports, and the team plans
to change the container's port number later without ever touching a Service.

- Declare container port **80** on `beam`, named `http`.
- Create ClusterIP Service `beam` on port **8080** that targets the container **by port name**,
  not by number.
- Confirm the Service's target port shows the name `http`, not a number.

## Hint

Search kubernetes.io/docs for **"kubectl expose"**. Check `kubectl expose -h`: does
`--target-port` accept a name as well as a number? A Service can only resolve a name once the
pods already declare it, so the Deployment change has to land first.
