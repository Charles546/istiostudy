#!/bin/bash

set -eo pipefail


VERSION=1.5.1
DOWNLOAD_URL="https://github.com/istio/istio/releases/download/${VERSION}/istio-${VERSION}-osx.tar.gz"

function get_namespace {
    kubectl get namespaces | awk '{print $1}' | grep -q istio-system
}

kubectl config use-context minikube

if ! get_namespace; then
    ISTIOCTL="$(which istioctl)"
    if [[ -z "$ISTIOCTL" ]]; then
      if ! curl -L "$DOWNLOAD_URL" | tar xz; then
          echo "Unable to download specified version of istio. Check releases"
          exit 1
      fi
      ISTIOCTL="${VERSION}/bin/istioctl"
    fi

    "$ISTIOCTL" manifest apply \
        --set values.pilot.enableProtocolSniffingForOutbound=false \
        --set profile=default \
        -f disable_ingress_gateway.yaml
else
    echo "Istio is installed. Skipping"
fi
