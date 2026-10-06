# q111-08: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
# 1. Pin the Service to blue BEFORE green exists, so a Ready green pod can
# never be picked up by the broad app=portal selector.
kubectl set selector svc portal -n q111-08-bluegreen-cutover 'app=portal,color=blue'

# 2. Create green from blue's shape: rename, color=green in both the
# selector and the template, new image.
cat <<'EOF' | kubectl apply -n q111-08-bluegreen-cutover -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal-green
  labels:
    clusterdrill-question: q111-08-bluegreen-cutover
spec:
  replicas: 3
  selector:
    matchLabels:
      app: portal
      color: green
  template:
    metadata:
      labels:
        app: portal
        color: green
        clusterdrill-question: q111-08-bluegreen-cutover
    spec:
      containers:
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
EOF
kubectl rollout status deployment/portal-green -n q111-08-bluegreen-cutover --timeout=60s

# 3. Cut over, then retire blue.
kubectl set selector svc portal -n q111-08-bluegreen-cutover 'app=portal,color=green'
kubectl scale deployment portal-blue -n q111-08-bluegreen-cutover --replicas=0
```

The trap is step 1: with the Service's original `app=portal` selector, green pods would start
receiving traffic the moment they turned Ready, turning the blue/green switch into an accidental
50/50 canary. Pinning the selector to `color=blue` first closes that gap before green ever
exists, so green is fully Ready and checked before a single request can reach it. This grader
checks the final state only; rollback, if ever needed, is scale blue back to 3 then flip the
selector back to `color=blue`.
