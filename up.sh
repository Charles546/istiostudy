#!/usr/bin/env bash

cd "$(dirname "$0")"

minikube start
./install_istio.sh
