# q113-20: LoadBalancer pending, port-forward instead

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-20-loadbalancer-pending-port-forward`

Team Vela asked for Service `gate` to be a cloud load balancer, but this cluster has no
load-balancer provider. They still need to test the app from the terminal. Deployment `gate`
(`nginx:1.27`, 2 replicas) and Service `gate` (ClusterIP, port 80) already exist.

- Change `gate` to type LoadBalancer.
- (ungraded, Task narrative only) Without creating any other Service, run `kubectl port-forward`
  from local port 8080 to `gate`'s port 80, and confirm the page loads through `localhost:8080`
  yourself. This step isn't graded - the forwarded process is your own terminal's backgrounded
  job, and it won't still be running by the time grading runs - but it's worth doing to see the
  three Service layers (ClusterIP under NodePort under LoadBalancer) in action.

## Hint

Search kubernetes.io/docs for **"Service" "type LoadBalancer"** - the Service concept page
states that a LoadBalancer Service is built on top of a NodePort Service, which is built on a
ClusterIP Service. What does each layer still give you when the top one can never actually be
provisioned on this cluster? `kubectl port-forward` blocks the terminal in the foreground, so run
it in the background and stop it when you're done.
