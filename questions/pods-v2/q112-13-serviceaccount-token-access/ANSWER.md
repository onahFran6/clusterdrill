# q112-13: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting

```sh
NS=q112-13-serviceaccount-token-access

kubectl create sa scanner -n "$NS"
kubectl create sa lister -n "$NS"
kubectl create role pod-reader --verb=get,list --resource=pods -n "$NS"
kubectl create rolebinding lister-rb --role=pod-reader --serviceaccount="$NS":lister -n "$NS"

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: scanner
  labels:
    clusterdrill-question: $NS
spec:
  serviceAccountName: scanner
  automountServiceAccountToken: false
  containers:
    - name: scanner
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: lister
  labels:
    clusterdrill-question: $NS
spec:
  serviceAccountName: lister
  containers:
    - name: lister
      image: curlimages/curl:8.10.1
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/scanner pod/lister -n "$NS" --timeout=60s

kubectl exec scanner -n "$NS" -- ls /var/run/secrets/kubernetes.io/serviceaccount || true

kubectl exec lister -n "$NS" -- sh -c '
  D=/var/run/secrets/kubernetes.io/serviceaccount
  curl -s -o /dev/null -w "%{http_code}\n" --cacert "$D/ca.crt" \
    -H "Authorization: Bearer $(cat "$D/token")" \
    "https://kubernetes.default.svc/api/v1/namespaces/'"$NS"'/pods"
'

kubectl auth can-i delete pods --as="system:serviceaccount:$NS:lister" -n "$NS" || true
```

Every Pod gets a ServiceAccount - `default` if you name none - and its token is mounted
automatically unless something opts out. `automountServiceAccountToken: false` on the Pod wins
over whatever the ServiceAccount itself says, which is why `scanner` ends up with no
`/var/run/secrets/kubernetes.io/serviceaccount` directory at all. The last command is pure
explanatory prose: it proves the Role is namespaced and least-privilege, since `lister` can list
Pods but not delete them, without being separately graded.
