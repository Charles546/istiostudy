url="$(minikube service --url=true demo-site)"
exec siege "$@" "$url"
