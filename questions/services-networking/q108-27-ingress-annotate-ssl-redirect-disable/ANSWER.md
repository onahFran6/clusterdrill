# q108-27-ingress-annotate-ssl-redirect-disable: reference solution

Doc: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#server-side-https-enforcement-through-redirect

```sh
kubectl annotate ingress docs-ingress -n q108-27-ingress-annotate-ssl-redirect-disable \
  nginx.ingress.kubernetes.io/force-ssl-redirect="false" --overwrite
```
