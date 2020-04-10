set -eo pipefail

function finish_rollout() {
  name="$1"
  pod_count="$2"
  kubectl rollout status deployment "$name"

  while [[ "$pod_count" -ne "$(kubectl get pod --selector=app="$name" -o name | wc -w)" ]]; do
    sleep 1
  done
}


cd $(dirname "$0")

# init data
yamlfile="$1"
deployment="$(yq r "$yamlfile" -d 0 metadata.name)"
container="$(yq r "$yamlfile" -d 0 'spec.template.spec.containers[0].name')"
count="$(yq r "$yamlfile" -d 0 'spec.replicas')"
service="$(yq r "$yamlfile" -d 1 metadata.name)"

# prepare
kubectl config use-context minikube
kubectl delete deployment "$deployment" 2>/dev/null || true
kubectl apply -f "$yamlfile" && finish_rollout "$deployment" "$count"

# start the siege
url="$(minikube service --url=true "$service")"
siege "$url" >/dev/null &
SIEGE_PID="$!"

# update deployment
yq w "$yamlfile" -d 0 spec.template.spec.containers[0].name "${container}-updated" |
kubectl apply -f - && finish_rollout "$deployment" "$count"

# stop siege
kill "$SIEGE_PID"
wait
