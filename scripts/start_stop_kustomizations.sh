arg1=$1
for k in $(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A --no-headers | awk '{print $2":"$1}'); do
  name=${k%%:*}
  ns=${k##*:}
  if [[ "$name" != "rook-ceph" ]]; then
    flux $1 kustomization "$name" -n "$ns"
  fi
done