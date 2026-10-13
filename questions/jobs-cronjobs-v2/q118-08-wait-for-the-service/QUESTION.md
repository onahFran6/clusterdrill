# q118-08: Wait for the database Service

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-08-wait-for-the-service`

Team Pluto needs *Job* `seed` with init container `wait-db` (`busybox:1.36`) to wait until Service `db` in this namespace resolves through cluster DNS.
Its main container `seed`, also using `busybox:1.36`, must then print `seeding db`.
Observe the waiting Pod status before the Service exists (practice observation, ungraded), then create ClusterIP *Service* `db` with TCP port and target port **5432**.
Confirm the Job completes.

## Hint

Search kubernetes.io/docs for "init containers waiting for a Service" and check the namespace in the DNS name.
